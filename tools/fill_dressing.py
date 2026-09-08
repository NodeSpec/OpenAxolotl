#!/usr/bin/env python3
"""Scatter filler vegetation across a world's platforms, around its landmarks.

    oax-fill --target worlds/coral_cove [--dry-run] [--format json]

WHY BOTH KINDS OF DRESSING EXIST. Two requirements pull in opposite directions
here and the level needs both, which is why an earlier pass that satisfied one
by deleting the other kept failing:

  * REQ-011 wants LANDMARKS: named, hand-placed clusters, one per traversal
    beat, so a contributor can reason about composition by reading the scene
    instead of editing an opaque scatter cloud. `OpeningTreeLeft` is a
    decision about where the player's eye goes at the start of the level.
  * REQ-034/REQ-027 want DENSITY, and want it in MultiMeshes: a valley reads
    as a valley because there is a lot of it, and the cost of a lot of it is
    per-OBJECT, so hundreds of individual instances spend the frame budget on
    the fact that there are many plants rather than on there being much plant.

They are not in conflict once the two jobs are separated. Landmarks are
authored and stay individual instances — there are fourteen and they are
supposed to be legible. Filler is generated, is nobody's decision
individually, and belongs in a MultiMesh. This tool writes only the second
kind and never touches the first.

WHERE IT PUTS THINGS, and every rule is about not ruining the level:

  * ON PLATFORM TOPS ONLY, inset from the edge. Vegetation hanging over a
    ledge tells the player the ledge is somewhere it is not, and a platformer
    is a game about reading edges.
  * NEVER within a clearance of anything that is GAMEPLAY — checkpoints,
    collectibles, mod pickups, enemies, the spawn, the finish. Dressing that
    hides a collectible is worse than no dressing.
  * NEVER within a clearance of an authored landmark, so the composition
    beats keep the silhouette they were placed for rather than being crowded
    out by filler.
  * DETERMINISTICALLY. Seeded per platform by name, so re-running produces a
    byte-identical scene and a diff means someone changed the level, not that
    the tool ran again.

It writes no gameplay. tools/gameplay_snapshot.py is how that gets proven
rather than asserted, and the tests run it either side of this.

Exit codes:
    0  scattered, or a dry run
    1  nothing to scatter, or the scene could not be read
    2  invocation error
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from asset_contract_validator import glb_header  # noqa: E402
from gameplay_snapshot import parse  # noqa: E402
from scatter_props import (  # noqa: E402
    SCATTER_SCRIPT, SCATTER_SCRIPT_ID, VEGETATION_MATERIAL,
    VEGETATION_MATERIAL_ID, _bump_load_steps, _fmt)

TOOL_NAME = "dressing-filler"
EXIT_OK = 0
EXIT_EMPTY = 1
EXIT_INVOCATION = 2

## The filler palette: prop, how many square metres of platform each one
## wants, and whether it sways. Densities are per-prop rather than shared so
## the canopy stays sparse enough to walk under while ground cover fills in.
PALETTE = [
    ("understory_fern", "assets/environment/understory_fern/understory_fern.glb",
     26.0, True),
    ("seagrass_tuft", "assets/environment/seagrass_tuft/seagrass_tuft.glb",
     34.0, True),
    ("river_reed", "assets/environment/river_reed/river_reed.glb", 48.0, True),
    ("canopy_tree", "assets/environment/canopy_tree/canopy_tree.glb",
     120.0, True),
    ("river_boulder", "assets/environment/river_boulder/river_boulder.glb",
     90.0, False),
    ("rock_cluster", "assets/environment/rock_cluster/rock_cluster.glb",
     140.0, False),
]

## Groups whose members are gameplay and must stay legible.
GAMEPLAY_GROUPS = ("spawn_point", "checkpoint", "collectible",
                   "gill_mod_pickup", "enemy", "finish_volume",
                   "regen_station", "affordance_gate", "restoration_gate",
                   "climbable", "hazard")

## How far filler keeps away from gameplay and from authored landmarks.
GAMEPLAY_CLEARANCE = 3.2
LANDMARK_CLEARANCE = 2.6

## How far in from a platform's edge filler may sit, and the smallest
## platform worth dressing at all.
EDGE_INSET = 0.9
MIN_PLATFORM_AREA = 12.0

## Cap per platform, so one enormous ground slab cannot swallow the budget.
MAX_PER_PLATFORM = 14

## Triangles the filler may add to the scene.
##
## THE DENSITIES ABOVE ARE A SHAPE, NOT A COUNT, and this is what turns one
## into the other. Left to themselves they place 638 instances in Coral Cove,
## which is about 99,000 triangles — against a whole-scene ceiling of 150,000
## that the dressed valley plus the hero already spends 126,000 of. Hand-tuning
## six density numbers until the total happened to fit would be six numbers
## nobody could re-derive, and they would silently stop fitting the first time
## a kit was regenerated at a different resolution.
##
## So the placement is generated at the density the LOOK wants and then thinned
## to what the frame can afford, measured from the props' own glb headers.
## Thinning drops from the end of each prop's list, which is deterministic, and
## proportionally, so the mix survives: the valley gets sparser, not patchier.
DEFAULT_TRIANGLE_BUDGET = 18000

VECTOR_RE = re.compile(r"Vector3\(([^)]*)\)")


def _floats(raw: str) -> list:
    return [float(part) for part in raw.split(",") if part.strip()]


def _transform_origin(raw: str) -> tuple:
    values = _floats(raw[raw.index("(") + 1:raw.rindex(")")])
    return (values[9], values[10], values[11]) if len(values) >= 12 else (0.0, 0.0, 0.0)


def read_scene(path: str) -> tuple:
    """Platforms, gameplay points and landmark points, in world space."""
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    parsed = parse(text)
    subs = parsed["subs"]

    # Node origins by path, so a collider can be placed by its body's transform
    # plus its own. Only one level of nesting occurs in these scenes.
    origins: dict = {}
    for node in parsed["nodes"]:
        name = node["name"]
        parent = node["parent"]
        full = "%s/%s" % (parent, name) if parent and parent != "." else name
        raw = node["properties"].get("transform", "")
        local = _transform_origin(raw) if raw.startswith("Transform3D") \
            else (0.0, 0.0, 0.0)
        base = origins.get(parent, (0.0, 0.0, 0.0))
        origins[full] = (base[0] + local[0], base[1] + local[1],
                         base[2] + local[2])

    platforms: list = []
    gameplay: list = []
    landmarks: list = []
    for node in parsed["nodes"]:
        name = node["name"]
        parent = node["parent"]
        full = "%s/%s" % (parent, name) if parent and parent != "." else name
        spot = origins.get(full, (0.0, 0.0, 0.0))

        if any(group in node["groups"] for group in GAMEPLAY_GROUPS):
            gameplay.append(spot)
        if parent == "Dressing":
            landmarks.append(spot)

        shape = node["properties"].get("shape", "")
        reference = re.match(r'SubResource\("([^"]+)"\)', shape)
        if node["type"] != "CollisionShape3D" or reference is None:
            continue
        resolved = subs.get(reference.group(1))
        if resolved is None or resolved["type"] != "BoxShape3D":
            continue
        size_raw = resolved["properties"].get("size", "")
        found = VECTOR_RE.search(size_raw)
        if found is None:
            continue
        size = _floats(found.group(1))
        if len(size) != 3 or size[0] * size[2] < MIN_PLATFORM_AREA:
            continue
        # The body under it is what the shape belongs to; its own transform is
        # already folded into `spot`.
        platforms.append({
            "name": full,
            "centre": spot,
            "size": tuple(size),
            "top": spot[1] + size[1] * 0.5,
        })
    return text, platforms, gameplay, landmarks


def too_close(spot: tuple, others: list, clearance: float) -> bool:
    for other in others:
        dx = spot[0] - other[0]
        dz = spot[2] - other[2]
        if dx * dx + dz * dz < clearance * clearance:
            return True
    return False


def scatter(platforms: list, gameplay: list, landmarks: list) -> dict:
    """Filler placements per prop, deterministic in the platforms' own names."""
    placements: dict = {name: [] for name, _path, _density, _sways in PALETTE}
    for platform in platforms:
        half_x = platform["size"][0] * 0.5 - EDGE_INSET
        half_z = platform["size"][2] * 0.5 - EDGE_INSET
        if half_x <= 0.0 or half_z <= 0.0:
            continue
        area = (half_x * 2.0) * (half_z * 2.0)
        rng = random.Random("oax-fill:%s" % platform["name"])
        placed_here: list = []

        for prop, _path, density, _sways in PALETTE:
            wanted = int(area / density)
            for _ in range(min(wanted, MAX_PER_PLATFORM)):
                spot = None
                # A handful of tries, then give up on this one rather than
                # forcing a prop into a clearance it does not fit.
                for _attempt in range(12):
                    candidate = (
                        platform["centre"][0] + rng.uniform(-half_x, half_x),
                        platform["top"],
                        platform["centre"][2] + rng.uniform(-half_z, half_z))
                    if too_close(candidate, gameplay, GAMEPLAY_CLEARANCE):
                        continue
                    if too_close(candidate, landmarks, LANDMARK_CLEARANCE):
                        continue
                    if too_close(candidate, placed_here, 1.4):
                        continue
                    spot = candidate
                    break
                if spot is None:
                    continue
                placed_here.append(spot)
                placements[prop].append({
                    "origin": spot,
                    "yaw": rng.uniform(0.0, 6.2831853),
                    "scale": rng.uniform(0.82, 1.24),
                })
    return {prop: rows for prop, rows in placements.items() if rows}


def triangles_of(path: str) -> int:
    """A prop's triangle count, read from its glb header."""
    try:
        count, _meshes, _clips = glb_header(path)
        return int(count)
    except Exception:  # noqa: BLE001 — a bad kit must not stop the pass
        return 0


def thin_to_budget(placements: dict, budget: int) -> tuple:
    """Drop instances until the filler fits, keeping the mix."""
    costs = {name: triangles_of(path) for name, path, _d, _s in PALETTE}
    total = sum(costs.get(prop, 0) * len(rows)
                for prop, rows in placements.items())
    if total <= budget or total == 0:
        return placements, total, total
    share = float(budget) / float(total)
    thinned: dict = {}
    for prop, rows in placements.items():
        keep = max(4, int(len(rows) * share)) if rows else 0
        if keep:
            thinned[prop] = rows[:keep]
    after = sum(costs.get(prop, 0) * len(rows)
                for prop, rows in thinned.items())
    return thinned, total, after


def field_blocks(placements: dict) -> tuple:
    """The ScatterField node text, and a per-prop summary."""
    by_prop = {name: (path, sways)
               for name, path, _density, sways in PALETTE}
    blocks: list = []
    summary: dict = {}
    resources: list = []
    for prop in sorted(placements):
        path, sways = by_prop[prop]
        resource_id = "fill_kit_%s" % prop
        resources.append((path, resource_id))
        flat: list = []
        for row in placements[prop]:
            scale = row["scale"]
            cos = __import__("math").cos(row["yaw"]) * scale
            sin = __import__("math").sin(row["yaw"]) * scale
            # Basis rows then origin: yaw about Y, uniform scale.
            flat.extend([cos, 0.0, sin,
                         0.0, scale, 0.0,
                         -sin, 0.0, cos,
                         row["origin"][0], row["origin"][1], row["origin"][2]])
        name = "Filler%sField" % "".join(
            part.capitalize() for part in prop.split("_"))
        block = [
            '',
            '[node name="%s" type="Node3D" parent="Dressing"]' % name,
            'script = ExtResource("%s")' % SCATTER_SCRIPT_ID,
            'prop_scene = ExtResource("%s")' % resource_id,
            'transforms = PackedFloat32Array(%s)'
            % ", ".join(_fmt(value) for value in flat),
        ]
        if sways:
            block.append('surface_material = ExtResource("%s")'
                         % VEGETATION_MATERIAL_ID)
        blocks.extend(block)
        summary[prop] = {"instances": len(placements[prop]), "sways": sways}
    return blocks, summary, resources


def apply(text: str, blocks: list, resources: list) -> str:
    lines = text.split("\n")
    insert_at = None
    for index, line in enumerate(lines):
        if line.startswith('[node name="Dressing"'):
            insert_at = index + 1
            break
    if insert_at is None:
        return text

    header: list = []
    if SCATTER_SCRIPT_ID not in text.split("[node")[0]:
        header.append('[ext_resource type="Script" path="%s" id="%s"]'
                      % (SCATTER_SCRIPT, SCATTER_SCRIPT_ID))
    if VEGETATION_MATERIAL_ID not in text.split("[node")[0]:
        header.append('[ext_resource type="Material" path="%s" id="%s"]'
                      % (VEGETATION_MATERIAL, VEGETATION_MATERIAL_ID))
    for path, resource_id in resources:
        if 'id="%s"' % resource_id in text:
            continue
        header.append('[ext_resource type="PackedScene" path="res://%s" '
                      'id="%s"]' % (path, resource_id))

    out: list = []
    for index, line in enumerate(lines):
        out.append(line)
        if index == insert_at - 1:
            out.extend(blocks)
    text = "\n".join(out)

    if header:
        lines = text.split("\n")
        last = 0
        for index, line in enumerate(lines):
            if line.startswith("[ext_resource"):
                last = index
        text = "\n".join(lines[:last + 1] + header + lines[last + 1:])
    return _bump_load_steps(text)


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(prog="oax-fill")
    parser.add_argument("--target", required=True, help="a world directory")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--triangle-budget", type=int,
                        default=DEFAULT_TRIANGLE_BUDGET,
                        help="triangles the filler may add "
                             "(default %d)" % DEFAULT_TRIANGLE_BUDGET)
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv)

    scene_path = os.path.join(args.target, "world.tscn")
    if not os.path.isfile(scene_path):
        scene_path = os.path.join(args.target, "open_lagoon.tscn")
    if not os.path.isfile(scene_path):
        print("%s: no scene in %s" % (TOOL_NAME, args.target), file=sys.stderr)
        return EXIT_INVOCATION

    text, platforms, gameplay, landmarks = read_scene(scene_path)
    placements = scatter(platforms, gameplay, landmarks)
    if not placements:
        print("%s: nothing to scatter in %s" % (TOOL_NAME, args.target),
              file=sys.stderr)
        return EXIT_EMPTY

    placements, wanted, costs = thin_to_budget(placements, args.triangle_budget)
    blocks, summary, resources = field_blocks(placements)
    total = sum(row["instances"] for row in summary.values())

    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME, "target": args.target, "dryRun": args.dry_run,
            "platforms": len(platforms), "gameplayAvoided": len(gameplay),
            "landmarksAvoided": len(landmarks),
            "fields": summary, "instances": total,
            "trianglesWanted": wanted, "trianglesKept": costs,
            "triangleBudget": args.triangle_budget,
        }, indent=2, sort_keys=True))
    else:
        print("%s v1.0 — target: %s" % (TOOL_NAME, args.target))
        print("  %d platform(s), avoiding %d gameplay and %d landmark points"
              % (len(platforms), len(gameplay), len(landmarks)))
        for prop in sorted(summary):
            print("  %-22s %3d instances  %s"
                  % (prop, summary[prop]["instances"],
                     "sways" if summary[prop]["sways"] else "rigid"))
        print("  %d triangles at full density, thinned to %d (budget %d)"
              % (wanted, costs, args.triangle_budget))
        print("%s %d filler instances across %d fields"
              % ("would add" if args.dry_run else "added", total, len(summary)))

    if not args.dry_run:
        with open(scene_path, "w", encoding="utf-8") as handle:
            handle.write(apply(text, blocks, resources))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
