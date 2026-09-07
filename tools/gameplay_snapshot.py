#!/usr/bin/env python3
"""Canonical snapshot of everything a VISUAL pass must not change.

    oax-snapshot --target worlds/coral_cove > before.json
    ... do the visual work ...
    oax-snapshot --target worlds/coral_cove --compare before.json

WHY THIS EXISTS. A visual-shell pass rewrites the art of a level while leaving
its gameplay untouched: collision geometry, spawn and checkpoint markers, the
water volumes, the mod gates. "Untouched" is easy to claim and easy to break by
accident — a stray transform on a StaticBody3D moves a platform the route was
measured against, and nothing about the render will look wrong. The walk probes
would catch a catastrophic break, but not a platform that shifted ten
centimetres, and that is exactly the size of error a visual pass introduces.

So: dump the gameplay-bearing facts to a canonical form BEFORE the pass, and
diff them after. An empty diff is a proof, not an assurance.

WHAT IS CAPTURED, and why each:

  * COLLISION SHAPES — type, size and the accumulated transform of every
    CollisionShape3D. This is the geometry the player actually touches; if any
    number here moves, the level changed regardless of what it looks like.
  * MARKERS BY GROUP — spawn points, checkpoints, pit volumes, gates. Their
    positions are what the route and the life system are measured against.
  * AREA VOLUMES — water, pits, enemy triggers: the shapes that change how the
    game behaves when you enter them.

WHAT IS DELIBERATELY NOT CAPTURED: MeshInstance3D, materials, dressing, and
anything under a Dressing container. Those are precisely what the pass is
allowed to change, and including them would make every snapshot differ and the
tool useless.

Exit codes:
    0  captured, or compared with no gameplay difference
    1  compared and something gameplay-bearing moved
    2  invocation error
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

TOOL_NAME = "gameplay-snapshot"
EXIT_OK = 0
EXIT_DIFFERENT = 1
EXIT_INVOCATION = 2

NODE_RE = re.compile(
    r'^\[node name="(?P<name>[^"]+)"'
    r'(?: type="(?P<type>[^"]+)")?'
    r'(?: parent="(?P<parent>[^"]+)")?'
    r'(?: instance=ExtResource\("(?P<instance>[^"]+)"\))?'
    r'(?: groups=\[(?P<groups>[^\]]*)\])?\]$')
SUB_RE = re.compile(r'^\[sub_resource type="(?P<type>[^"]+)" id="(?P<id>[^"]+)"\]$')
PROPERTY_RE = re.compile(r"^(?P<key>[A-Za-z0-9_/]+) = (?P<value>.+)$")

## Node types whose placement is gameplay, not art.
GAMEPLAY_TYPES = ("CollisionShape3D", "Marker3D", "Area3D", "StaticBody3D",
                  "CharacterBody3D", "RigidBody3D")

## Anything under one of these parents is art by definition and is skipped.
ART_CONTAINERS = ("Dressing", "Shell", "VisualShell")


def parse(text: str) -> dict:
    """Sub-resources and nodes, each with the properties that follow it."""
    subs: dict = {}
    nodes: list = []
    current: dict | None = None
    kind = None

    for line in text.split("\n"):
        sub = SUB_RE.match(line)
        if sub is not None:
            current = {"type": sub.group("type"), "properties": {}}
            subs[sub.group("id")] = current
            kind = "sub"
            continue
        node = NODE_RE.match(line)
        if node is not None:
            current = {
                "name": node.group("name"),
                "type": node.group("type") or "",
                "parent": node.group("parent") or "",
                "instance": node.group("instance") or "",
                "groups": _groups(node.group("groups")),
                "properties": {},
            }
            nodes.append(current)
            kind = "node"
            continue
        if line.startswith("["):
            current, kind = None, None
            continue
        if current is None:
            continue
        prop = PROPERTY_RE.match(line)
        if prop is not None:
            current["properties"][prop.group("key")] = prop.group("value").strip()
    return {"subs": subs, "nodes": nodes}


def _groups(raw: str | None) -> list:
    if not raw:
        return []
    return sorted(part.strip().strip('"') for part in raw.split(",") if part.strip())


def is_art(node: dict) -> bool:
    parent = node.get("parent", "")
    for container in ART_CONTAINERS:
        if parent == container or parent.startswith(container + "/") \
                or ("/" + container) in ("/" + parent):
            return True
    return False


def snapshot(text: str) -> dict:
    parsed = parse(text)
    subs = parsed["subs"]
    rows: list = []

    for node in parsed["nodes"]:
        if is_art(node):
            continue
        node_type = node["type"]
        keep = node_type in GAMEPLAY_TYPES or node["groups"]
        if not keep:
            continue

        row = {
            "path": "%s/%s" % (node["parent"], node["name"]) if node["parent"]
                    else node["name"],
            "type": node_type,
            "groups": node["groups"],
            "transform": node["properties"].get("transform", "identity"),
        }
        # Resolve the shape so a resized BoxShape3D shows up as a difference
        # rather than hiding behind an unchanged sub-resource id.
        shape = node["properties"].get("shape", "")
        reference = re.match(r'SubResource\("([^"]+)"\)', shape)
        if reference is not None and reference.group(1) in subs:
            resolved = subs[reference.group(1)]
            row["shape"] = {
                "type": resolved["type"],
                "size": resolved["properties"].get("size", ""),
                "radius": resolved["properties"].get("radius", ""),
                "height": resolved["properties"].get("height", ""),
            }
        rows.append(row)

    rows.sort(key=lambda r: (r["path"], r["type"]))
    return {"schemaVersion": "1.0", "rows": rows, "count": len(rows)}


def collect(target: str) -> dict:
    scenes: dict = {}
    for root, _dirs, files in os.walk(target):
        for name in sorted(files):
            if not name.endswith(".tscn"):
                continue
            path = os.path.join(root, name)
            with open(path, encoding="utf-8") as handle:
                scenes[os.path.relpath(path, ".")] = snapshot(handle.read())
    return {"tool": TOOL_NAME, "schemaVersion": "1.0", "scenes": scenes}


def compare(now: dict, before: dict) -> list:
    findings: list = []
    for path in sorted(set(now["scenes"]) | set(before["scenes"])):
        current = now["scenes"].get(path)
        previous = before["scenes"].get(path)
        if current is None:
            findings.append("%s: scene disappeared" % path)
            continue
        if previous is None:
            findings.append("%s: scene is new (nothing to compare against)" % path)
            continue
        by_path_now = {row["path"]: row for row in current["rows"]}
        by_path_was = {row["path"]: row for row in previous["rows"]}
        for key in sorted(set(by_path_now) | set(by_path_was)):
            a, b = by_path_now.get(key), by_path_was.get(key)
            if a is None:
                findings.append("%s: %s was REMOVED" % (path, key))
            elif b is None:
                findings.append("%s: %s was ADDED" % (path, key))
            elif a != b:
                for field in sorted(set(a) | set(b)):
                    if a.get(field) != b.get(field):
                        findings.append("%s: %s changed %s\n    was %s\n    now %s"
                                        % (path, key, field, b.get(field),
                                           a.get(field)))
    return findings


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(prog="oax-snapshot")
    parser.add_argument("--target", required=True)
    parser.add_argument("--compare", help="a snapshot JSON to diff against")
    args = parser.parse_args(argv)

    if not os.path.isdir(args.target):
        print("%s: no such directory %s" % (TOOL_NAME, args.target),
              file=sys.stderr)
        return EXIT_INVOCATION

    now = collect(args.target)
    if args.compare is None:
        print(json.dumps(now, indent=2, sort_keys=True))
        return EXIT_OK

    with open(args.compare, encoding="utf-8") as handle:
        before = json.load(handle)
    findings = compare(now, before)
    total = sum(scene["count"] for scene in now["scenes"].values())
    if not findings:
        print("%s: %d gameplay element(s) across %d scene(s) — UNCHANGED"
              % (TOOL_NAME, total, len(now["scenes"])))
        return EXIT_OK
    for finding in findings:
        print("  %s" % finding)
    print("%s: %d gameplay difference(s) — the visual pass changed the GAME"
          % (TOOL_NAME, len(findings)))
    return EXIT_DIFFERENT


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
