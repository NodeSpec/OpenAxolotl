#!/usr/bin/env python3
"""Wrap greybox collision proxies in visual shells.

    oax-shell --target hub [--dry-run] [--only StartLedge,ShelfStep1]

WHAT IT DOES, per StaticBody3D that carries BOTH a BoxShape3D collider and a
BoxMesh visual: hides the BoxMesh and adds a TerrainShell child pointed at the
body. The collider, the body's transform, the markers and every group are left
exactly as they are — this tool is not allowed to touch gameplay, and
tools/gameplay_snapshot.py is how that gets proven rather than asserted.

WHY HIDE RATHER THAN DELETE the BoxMesh. A hidden proxy mesh is still there to
be switched back on, which is what you want while art is in flight: `visible =
false` is one line to flip when someone needs to see the true collision volume
again, and it keeps the .tscn honest about what the shape actually is. Deleting
it would also silently change the scene triangle count in a way that hides
whether the shell is paying for itself.

WHAT IT SKIPS, and why each:

  * Bodies that already carry a Shell child. This is what makes the tool
    RE-RUNNABLE, and it is not a nicety: without it a second run added a
    second Shell to every body and a second `visible = false` to every proxy
    mesh — thirty-two shells became sixty-four, doubling the shell geometry in
    the scene while the report cheerfully said it had shelled thirty-two.
  * Bodies with no BoxMesh — already invisible, nothing to shell.
  * Bodies flagged MANUFACTURED (a name in --geometric). Mod gates, pedestals
    and machinery are DELIBERATELY geometric: a bevelled organic rock where a
    gate should be would lie about what the object is. The visual pass leaves
    them alone on purpose.
  * Anything under a Dressing container — that is scatter, not terrain.

Exit codes:
    0  shelled (or, with --dry-run, would shell cleanly)
    1  the scene does not conform well enough to convert safely
    2  invocation error
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

TOOL_NAME = "terrain-sheller"
EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

SHELL_SCRIPT = "res://core/rendering/terrain_shell.gd"
SHELL_SCRIPT_ID = "terrain_shell_script"

## Which terrain material a shell wears, chosen from the proxy's own name.
## A shore should not be the same rock as a cliff, and the level already names
## its bodies for what they are — so the name is the honest signal rather than
## a table someone has to maintain in parallel.
MATERIAL_BY_HINT = (
    ("shore", "river_sand"),
    ("sand", "river_sand"),
    ("beach", "river_sand"),
    # The hub's Ground is the Open Lagoon shore, not woodland: forest_earth's
    # low tint is (0.14, 0.12, 0.09), which is nearly black and rendered the
    # whole hub as a dark slab. A valley FLOOR under a canopy is a different
    # thing and keeps the dark earth.
    ("ground", "river_sand"),
    ("floor", "forest_earth"),
    ("bed", "river_sand"),
    ("terrace", "mossy_stone"),
    ("landing", "mossy_stone"),
    ("ledge", "mossy_stone"),
    ("step", "mossy_stone"),
    ("wall", "river_stone"),
    ("pillar", "coral_shelf_stone"),
    ("lip", "coral_shelf_stone"),
)
DEFAULT_MATERIAL = "river_stone"
MATERIAL_DIR = "res://core/rendering/terrain/"


def material_for(name: str) -> str:
    lowered = name.lower()
    for hint, material in MATERIAL_BY_HINT:
        if hint in lowered:
            return material
    return DEFAULT_MATERIAL

## Objects that are MANUFACTURED and must stay geometric. A mod gate reads as a
## rule precisely because it is a clean slab among organic rock; wrapping it in
## a boulder would make it look like scenery the player can ignore.
DEFAULT_GEOMETRIC = ("Gate", "Pedestal", "Portal", "Platformer", "Flagship",
                     "Dredger", "Netbot", "Hookline", "Runoff")

NODE_RE = re.compile(
    r'^\[node name="(?P<name>[^"]+)"'
    r'(?: type="(?P<type>[^"]+)")?'
    r'(?: parent="(?P<parent>[^"]+)")?'
    r'(?: instance=ExtResource\("(?P<inst>[^"]+)"\))?'
    r'(?: groups=\[(?P<groups>[^\]]*)\])?\]$')


class Body:
    def __init__(self, name: str, parent: str, line: int) -> None:
        self.name = name
        self.parent = parent
        self.line = line
        self.mesh_line = -1
        self.mesh_name = ""
        self.has_box_shape = False
        self.shelled = False
        self.child_lines: list = []


def scan(text: str, geometric: tuple) -> tuple:
    """Bodies eligible for a shell, and the ones deliberately skipped."""
    lines = text.split("\n")
    bodies: dict = {}
    skipped: list = []
    subs_box_shape: set = set()
    subs_box_mesh: set = set()

    for index, line in enumerate(lines):
        if line.startswith('[sub_resource type="BoxShape3D"'):
            subs_box_shape.add(re.search(r'id="([^"]+)"', line).group(1))
        elif line.startswith('[sub_resource type="BoxMesh"'):
            subs_box_mesh.add(re.search(r'id="([^"]+)"', line).group(1))

    current: Body | None = None
    for index, line in enumerate(lines):
        node = NODE_RE.match(line)
        if node is None:
            if current is not None and current.child_lines:
                # Attach shape/mesh references to whichever child we are in.
                reference = re.match(r'^(shape|mesh) = SubResource\("([^"]+)"\)$',
                                     line)
                if reference is not None:
                    kind, sub = reference.group(1), reference.group(2)
                    if kind == "shape" and sub in subs_box_shape:
                        current.has_box_shape = True
                    elif kind == "mesh" and sub in subs_box_mesh:
                        current.mesh_line = current.child_lines[-1]
            continue

        name, node_type = node.group("name"), node.group("type") or ""
        parent = node.group("parent") or ""

        if node_type == "StaticBody3D":
            key = "%s/%s" % (parent, name)
            if any(flag.lower() in name.lower() for flag in geometric):
                skipped.append((key, "manufactured: deliberately geometric"))
                current = None
                continue
            if "Dressing" in parent:
                skipped.append((key, "dressing, not terrain"))
                current = None
                continue
            current = Body(name, parent, index)
            bodies[key] = current
            continue

        if current is not None and parent.endswith(current.name):
            current.child_lines.append(index)
            if node_type == "MeshInstance3D":
                current.mesh_name = name
            elif name == "Shell":
                current.shelled = True
        elif node_type in ("StaticBody3D", "Node3D", "Area3D", "Marker3D"):
            current = None

    eligible = {}
    for key, body in bodies.items():
        if body.shelled:
            skipped.append((key, "already shelled"))
        elif not body.has_box_shape:
            skipped.append((key, "no BoxShape3D collider to wrap"))
        elif body.mesh_line < 0:
            skipped.append((key, "no BoxMesh visual to replace"))
        else:
            eligible[key] = body
    return eligible, skipped


def convert(text: str, geometric: tuple) -> tuple:
    eligible, skipped = scan(text, geometric)
    if not eligible:
        return text, {}, skipped

    lines = text.split("\n")
    additions: dict = {}
    materials: set = set()
    for key, body in eligible.items():
        # Hide the proxy mesh rather than delete it (see the header).
        additions.setdefault(body.mesh_line, []).append("visible = false")
        # The shell goes after the body's last child block.
        anchor = max(body.child_lines) if body.child_lines else body.line
        # A child of the scene root is written `parent="Ledge"`, not
        # `parent="./Ledge"` — Godot resolves both, but only one of them is
        # what Godot itself writes, and a scene that round-trips through the
        # editor should come back byte-identical. The seed keeps using the
        # unnormalised key so shells already in the repository keep the
        # silhouettes they were reviewed with.
        path = body.name if body.parent in ("", ".") \
            else "%s/%s" % (body.parent, body.name)
        material = material_for(body.name)
        materials.add(material)
        additions.setdefault(anchor, []).append(
            '\n[node name="Shell" type="Node3D" parent="%s"]\n'
            'script = ExtResource("%s")\n'
            'surface_material = ExtResource("%s")\n'
            'shell_seed = %d' % (path, SHELL_SCRIPT_ID, _material_id(material),
                                 _stable_seed(key)))

    out: list = []
    pending: dict = {}
    for index, line in enumerate(lines):
        out.append(line)
        if index in additions:
            for addition in additions[index]:
                if addition == "visible = false":
                    out.append(addition)
                else:
                    pending.setdefault(index, []).append(addition)
        # Shell blocks go after the body's whole child run, i.e. at the next
        # blank line following the anchor.
        for anchor in sorted(pending):
            if index >= anchor and line.strip() == "":
                for block in pending.pop(anchor):
                    out.append(block.lstrip("\n"))
                    out.append("")
                break
    for anchor in sorted(pending):
        for block in pending[anchor]:
            out.append(block.lstrip("\n"))

    text = "\n".join(out)
    text = _ensure_script(text)
    text = _ensure_materials(text, materials)
    text = _bump_load_steps(text)
    return text, eligible, skipped


def _material_id(material: str) -> str:
    return "terrain_%s" % material


def _stable_seed(key: str) -> int:
    """Python's hash() is salted per process, so a re-run would reshuffle every
    shell's silhouette and produce a diff for no reason. This is stable."""
    value = 0
    for char in key:
        value = (value * 131 + ord(char)) % 9973
    return value


def _ensure_materials(text: str, materials: set) -> str:
    header = text.split("[node")[0]
    lines = text.split("\n")
    last = max(i for i, line in enumerate(lines) if line.startswith("[ext_resource"))
    additions = []
    for material in sorted(materials):
        if _material_id(material) in header:
            continue
        additions.append('[ext_resource type="Material" path="%s%s.tres" id="%s"]'
                         % (MATERIAL_DIR, material, _material_id(material)))
    if not additions:
        return text
    return "\n".join(lines[:last + 1] + additions + lines[last + 1:])


def _ensure_script(text: str) -> str:
    if SHELL_SCRIPT_ID in text.split("[node")[0]:
        return text
    lines = text.split("\n")
    last = max(i for i, line in enumerate(lines) if line.startswith("[ext_resource"))
    lines.insert(last + 1, '[ext_resource type="Script" path="%s" id="%s"]'
                 % (SHELL_SCRIPT, SHELL_SCRIPT_ID))
    return "\n".join(lines)


def _bump_load_steps(text: str) -> str:
    steps = text.count("[ext_resource") + text.count("[sub_resource") + 1
    return re.sub(r"load_steps=\d+", "load_steps=%d" % steps, text, count=1)


def main(argv: list | None = None) -> int:
    parser = argparse.ArgumentParser(prog="oax-shell")
    parser.add_argument("--target", required=True,
                        help="a directory of .tscn files, or one .tscn")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--only", default="",
                        help="comma-separated body names to shell; default all")
    parser.add_argument("--geometric", default=",".join(DEFAULT_GEOMETRIC),
                        help="name fragments that stay deliberately geometric")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv)

    scenes: list = []
    if os.path.isfile(args.target) and args.target.endswith(".tscn"):
        scenes = [args.target]
    elif os.path.isdir(args.target):
        for root, _dirs, files in os.walk(args.target):
            scenes.extend(os.path.join(root, f) for f in sorted(files)
                          if f.endswith(".tscn"))
    else:
        print("%s: no scenes under %s" % (TOOL_NAME, args.target), file=sys.stderr)
        return EXIT_INVOCATION

    geometric = tuple(f for f in args.geometric.split(",") if f)
    only = tuple(f for f in args.only.split(",") if f)
    report: dict = {"tool": TOOL_NAME, "schemaVersion": "1.0", "scenes": {}}

    for scene in sorted(scenes):
        with open(scene, encoding="utf-8") as handle:
            original = handle.read()
        text, shelled, skipped = convert(original, geometric)
        if only:
            shelled = {k: v for k, v in shelled.items()
                       if any(name in k for name in only)}
            if not shelled:
                continue
            text, _all, skipped = convert(original, geometric)
        if shelled and not args.dry_run:
            with open(scene, "w", encoding="utf-8") as handle:
                handle.write(text)
        report["scenes"][scene] = {
            "shelled": sorted(shelled),
            "skipped": [{"body": b, "why": w} for b, w in sorted(skipped)],
        }

    if args.format == "json":
        print(json.dumps(report, indent=2))
    else:
        print("%s v1.0" % TOOL_NAME)
        for scene, row in sorted(report["scenes"].items()):
            if not row["shelled"] and not row["skipped"]:
                continue
            print("  %s" % scene)
            for body in row["shelled"]:
                print("     shell   %s" % body)
            for entry in row["skipped"]:
                print("     skip    %-34s %s" % (entry["body"], entry["why"]))
        total = sum(len(r["shelled"]) for r in report["scenes"].values())
        print("%s %d collision proxies" % (
            "would shell" if args.dry_run else "shelled", total))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
