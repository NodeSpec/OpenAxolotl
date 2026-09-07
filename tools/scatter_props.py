#!/usr/bin/env python3
"""Collapse a world's individually-instanced dressing into ScatterField nodes.

    oax-scatter --target worlds/coral_cove [--dry-run] [--format json]

WHY THIS EXISTS. A dressed world placed every prop as its own scene instance:
Coral Cove carried 183 of them, which is 183 draw calls spent on the fact that
there are many plants rather than on there being much plant. One
MultiMeshInstance3D per prop TYPE draws all of them in a single call, costs
less than the individual instances did, and leaves room to go to hundreds.

WHAT IT PRESERVES, EXACTLY. Every instance keeps its transform to the float.
This is a rendering change, not a dressing change: the same props stand in the
same places afterwards, so a before/after capture should differ only in that
the plants now move. That property is what makes the conversion safe to run on
a world whose route has already been proven flyable.

WHAT IT LEAVES ALONE. Only nodes under the `Dressing` parent that instance a
kit ExtResource are touched. Collision bodies, markers, water volumes, enemies
and the level's own geometry are never rewritten — a scatter field has no
collision, so anything the player can stand on or bump into has to stay a real
node. The kit's props are scenery and carry no colliders, which is what makes
them eligible in the first place.

Exit codes are the contract with CI and with agents:
    0  converted (or, with --dry-run, would convert cleanly)
    1  the world does not conform well enough to convert safely
    2  invocation error -- bad arguments, unreadable target
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

TOOL_NAME = "prop-scatterer"
EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

## Props that must NOT sway. A swaying boulder is worse than a still one, so
## these scatter without the wind material and keep the mesh's own.
RIGID_PROPS = ("river_boulder", "rock_cluster", "fallen_log")

VEGETATION_MATERIAL = "res://core/rendering/materials/forest_canopy.tres"
SCATTER_SCRIPT = "res://core/rendering/scatter_field.gd"

## `[node name="Prop12" parent="Dressing" instance=ExtResource("13_kit_canopy_tree")]`
NODE_RE = re.compile(
    r'^\[node name="(?P<name>[^"]+)" parent="(?P<parent>[^"]+)" '
    r'instance=ExtResource\("(?P<res>[^"]+)"\)\]$')
TRANSFORM_RE = re.compile(r"^transform = Transform3D\((?P<values>[^)]*)\)$")
EXT_RE = re.compile(
    r'^\[ext_resource type="PackedScene" (?:uid="[^"]*" )?'
    r'path="(?P<path>[^"]+)" id="(?P<id>[^"]+)"\]$')


class Finding:
    def __init__(self, rule: str, message: str) -> None:
        self.rule = rule
        self.message = message

    def as_dict(self) -> dict:
        return {"rule": self.rule, "message": self.message, "severity": "error"}


def parse_scene(text: str) -> tuple[dict, list]:
    """External PackedScene resources by id, and every prop instance found."""
    resources: dict = {}
    props: list = []
    lines = text.split("\n")
    for index, line in enumerate(lines):
        ext = EXT_RE.match(line)
        if ext is not None:
            resources[ext.group("id")] = ext.group("path")
            continue
        node = NODE_RE.match(line)
        if node is None:
            continue
        # The transform is the line after the header, when there is one; a
        # prop without one sits at the origin, which is legal.
        transform = None
        if index + 1 < len(lines):
            matched = TRANSFORM_RE.match(lines[index + 1])
            if matched is not None:
                transform = [float(v) for v in matched.group("values").split(",")]
        props.append({
            "line": index,
            "name": node.group("name"),
            "parent": node.group("parent"),
            "resource": node.group("res"),
            "transform": transform or [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
        })
    return resources, props


def prop_key(path: str) -> str:
    """`res://assets/environment/canopy_tree/canopy_tree.glb` -> canopy_tree."""
    return os.path.splitext(os.path.basename(path))[0]


def convert(text: str) -> tuple[str, dict, list]:
    resources, props = parse_scene(text)
    findings: list = []

    dressing = [p for p in props if p["parent"] == "Dressing"]
    if not dressing:
        findings.append(Finding(
            "scatter.no_dressing",
            "no prop instances found under a 'Dressing' parent; nothing to "
            "convert (this tool only rewrites scenery, never level geometry)"))
        return text, {}, findings

    # Group by the resource each instance points at: one field per prop type.
    groups: dict = {}
    for prop in dressing:
        path = resources.get(prop["resource"])
        if path is None:
            findings.append(Finding(
                "scatter.unknown_resource",
                "%s instances ExtResource(%s), which no ext_resource line "
                "declares" % (prop["name"], prop["resource"])))
            continue
        groups.setdefault(prop["resource"], {"path": path, "props": []})
        groups[prop["resource"]]["props"].append(prop)
    if findings:
        return text, {}, findings

    lines = text.split("\n")
    drop: set = set()
    for prop in dressing:
        drop.add(prop["line"])
        if TRANSFORM_RE.match(lines[prop["line"] + 1] or ""):
            drop.add(prop["line"] + 1)

    # Where the Dressing node's own header sits, so the fields replace its
    # children in place rather than being appended to the end of the file.
    insert_at = None
    for index, line in enumerate(lines):
        if line.startswith('[node name="Dressing"'):
            insert_at = index + 1
            break
    if insert_at is None:
        findings.append(Finding(
            "scatter.no_dressing_node",
            "found props parented to 'Dressing' but no Dressing node header"))
        return text, {}, findings

    blocks: list = []
    summary: dict = {}
    for resource, group in sorted(groups.items(), key=lambda kv: kv[1]["path"]):
        name = prop_key(group["path"])
        flat: list = []
        for prop in group["props"]:
            flat.extend(prop["transform"])
        rigid = name in RIGID_PROPS
        block = [
            '',
            '[node name="%s" type="Node3D" parent="Dressing"]'
            % _field_name(name),
            'script = ExtResource("%s")' % SCATTER_SCRIPT_ID,
            'prop_scene = ExtResource("%s")' % resource,
            'transforms = PackedFloat32Array(%s)'
            % ", ".join(_fmt(v) for v in flat),
        ]
        if not rigid:
            block.append('surface_material = ExtResource("%s")'
                         % VEGETATION_MATERIAL_ID)
        blocks.extend(block)
        summary[name] = {
            "instances": len(group["props"]),
            "sways": not rigid,
        }

    out: list = []
    for index, line in enumerate(lines):
        if index in drop:
            continue
        out.append(line)
        if index == insert_at - 1:
            out.extend(blocks)

    text = "\n".join(out)
    text = _ensure_ext_resources(text)
    text = _bump_load_steps(text)
    return text, summary, findings


SCATTER_SCRIPT_ID = "scatter_field_script"
VEGETATION_MATERIAL_ID = "forest_canopy_material"


def _field_name(prop_name: str) -> str:
    return "".join(part.capitalize() for part in prop_name.split("_")) + "Field"


def _fmt(value: float) -> str:
    """Match Godot's own float formatting so a re-save produces no diff."""
    if value == int(value):
        return str(int(value))
    return repr(round(value, 6))


def _ensure_ext_resources(text: str) -> str:
    """Declare the script and material the fields reference, once."""
    additions: list = []
    if SCATTER_SCRIPT_ID not in text.split("[node")[0]:
        additions.append('[ext_resource type="Script" path="%s" id="%s"]'
                         % (SCATTER_SCRIPT, SCATTER_SCRIPT_ID))
    if VEGETATION_MATERIAL_ID not in text.split("[node")[0]:
        additions.append('[ext_resource type="Material" path="%s" id="%s"]'
                         % (VEGETATION_MATERIAL, VEGETATION_MATERIAL_ID))
    if not additions:
        return text
    lines = text.split("\n")
    # After the last existing ext_resource, so the header block stays together.
    last = 0
    for index, line in enumerate(lines):
        if line.startswith("[ext_resource"):
            last = index
    return "\n".join(lines[:last + 1] + additions + lines[last + 1:])


def _bump_load_steps(text: str) -> str:
    """A .tscn declaring too few load_steps loads with missing resources."""
    steps = text.count("[ext_resource") + text.count("[sub_resource") + 1
    return re.sub(r"load_steps=\d+", "load_steps=%d" % steps, text, count=1)


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(prog="oax-scatter")
    parser.add_argument("--target", required=True,
                        help="world directory containing world.tscn")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv)

    scene_path = os.path.join(args.target, "world.tscn")
    if not os.path.isfile(scene_path):
        print("%s: no world.tscn under %s" % (TOOL_NAME, args.target),
              file=sys.stderr)
        return EXIT_INVOCATION

    with open(scene_path, encoding="utf-8") as handle:
        original = handle.read()

    converted, summary, findings = convert(original)
    report = {
        "tool": TOOL_NAME,
        "schemaVersion": "1.0",
        "target": args.target,
        "passed": not findings,
        "fields": summary,
        "instancesScattered": sum(f["instances"] for f in summary.values()),
        "drawCallsBefore": sum(f["instances"] for f in summary.values()),
        "drawCallsAfter": len(summary),
        "violations": [f.as_dict() for f in findings],
    }

    if not findings and not args.dry_run:
        with open(scene_path, "w", encoding="utf-8") as handle:
            handle.write(converted)

    if args.format == "json":
        print(json.dumps(report, indent=2))
    else:
        print("%s v1.0 — target: %s" % (TOOL_NAME, args.target))
        for name, field in sorted(summary.items()):
            print("  %-20s %3d instances  %s" % (
                name, field["instances"],
                "sways" if field["sways"] else "rigid"))
        if findings:
            for finding in findings:
                print("  ERROR %s: %s" % (finding.rule, finding.message))
            print("FAIL — %d violation(s)" % len(findings))
        else:
            print("%s %d instances -> %d draw calls (was %d)" % (
                "would scatter" if args.dry_run else "scattered",
                report["instancesScattered"], report["drawCallsAfter"],
                report["drawCallsBefore"]))
    return EXIT_VIOLATIONS if findings else EXIT_OK


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
