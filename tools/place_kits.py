#!/usr/bin/env python3
"""Place the uploaded Meshy environment kits into Coral Cove.

canopy_grove, canopy_grove_tall and sand_shelf_set shipped into assets/ but
nothing referenced them, so the level never showed them. This puts them where
they actually work.

SCALE IS THE WHOLE PROBLEM, and it is not obvious from the files. Meshy
normalises its exports to roughly unit size: the groves arrive 1.90 m across
and 1.23 m tall. The forest they have to sit in is built from a generated tree
whose own provenance says it rises 14-18 m. Dropped in at native scale a grove
would be a shrub at the foot of a wall. Everything here is scaled about
eleven-fold to stand in the same forest.

WHY THESE ARE HAND-PLACED AND FEW. Each grove is 19,998 triangles against a
400,000-triangle whole-scene budget, so they are landmarks rather than
filler -- six of them, on the gorge rim at the eye-catch point of six
different acts. Density still comes from the 400-triangle generated tree in
the ScatterFields, which is what that asset is for.

THEY ARE KITS, NOT SINGLE OBJECTS. Each file holds several detached pieces in
one mesh -- six trees, five trees, four rock shelves -- so each places whole
and cannot be scattered. That is why the shelf set becomes a pair of estuary
islets rather than platform art: as one mesh it cannot be cut into the four
separate platforms the level would want.
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_gorge import lerp_profile  # noqa: E402

SCENE = "worlds/coral_cove/world.tscn"

KITS = {
    "canopy_grove": ("kit_canopy_grove",
                     "res://assets/environment/canopy_grove/canopy_grove.glb"),
    "canopy_grove_tall": ("kit_canopy_grove_tall",
                          "res://assets/environment/canopy_grove_tall/"
                          "canopy_grove_tall.glb"),
    "sand_shelf_set": ("kit_sand_shelf_set",
                       "res://assets/environment/sand_shelf_set/"
                       "sand_shelf_set.glb"),
}

# (name, kit, z, side, scale, yaw) -- one per act's eye-catch point. Sides
# alternate so the rim never reads as an avenue.
GROVES = [
    ("RimGroveOpening",   "canopy_grove",      -6.0,   -1.0, 12.0, 0.4),
    ("RimGroveNarrows",   "canopy_grove_tall", -56.0,   1.0, 11.0, -1.1),
    ("RimGroveGorge",     "canopy_grove",      -104.0, -1.0, 12.5, 2.2),
    ("RimGroveRace",      "canopy_grove_tall", -166.0,  1.0, 11.5, 0.9),
    ("RimGroveShelf",     "canopy_grove",      -214.0, -1.0, 13.0, -0.5),
    ("RimGroveShelfWall", "canopy_grove_tall", -254.0,  1.0, 11.0, 1.7),
]

# Estuary islets, well clear of the boss arena (the route reaches |x| <= 10.5
# and z = -307; these sit past x = 26).
ISLETS = [
    ("EstuaryIsletWest", "sand_shelf_set", -282.0, -30.0, 3.0, 10.0, 0.6),
    ("EstuaryIsletEast", "sand_shelf_set", -318.0,  34.0, 3.0, 11.0, -1.3),
]


def basis(theta, k):
    c, s = math.cos(theta), math.sin(theta)
    return (c * k, 0.0, -s * k, 0.0, k, 0.0, s * k, 0.0, c * k)


def xform(theta, k, origin):
    return ", ".join("%.4g" % v for v in (*basis(theta, k), *origin))


def main():
    src = open(SCENE, encoding="utf-8").read()
    if "MeshyKits" in src:
        sys.exit("error: the scene already carries MeshyKits; remove it first")
    if 'name="Gorge"' not in src:
        sys.exit("error: run build_gorge.py first -- kits sit on the gorge rim")

    ext = []
    for _key, (rid, path) in KITS.items():
        if 'id="%s"' % rid not in src:
            ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]'
                       % (path, rid))

    nodes = ['[node name="MeshyKits" type="Node3D" parent="."]\n']

    for name, kit, z, side, scale, theta in GROVES:
        inner, top = lerp_profile(z)
        # On the rim shelf, just outside the wall's outer face. The rim box is
        # 6 tall centred at top-3, so its walkable-looking surface IS `top`.
        x = side * (inner + 15.0)
        nodes.append(
            '[node name="%s" parent="MeshyKits" instance=ExtResource("%s")]\n'
            'transform = Transform3D(%s)\n'
            % (name, KITS[kit][0], xform(theta, scale, (x, top, z))))

    for name, kit, z, x, y, scale, theta in ISLETS:
        nodes.append(
            '[node name="%s" parent="MeshyKits" instance=ExtResource("%s")]\n'
            'transform = Transform3D(%s)\n'
            % (name, KITS[kit][0], xform(theta, scale, (x, y, z))))

    first_node = src.index("\n[node ")
    head, body = src[:first_node], src[first_node:]
    steps = re.search(r"load_steps=(\d+)", head)
    head = head.replace("load_steps=%s" % steps.group(1),
                        "load_steps=%d" % (int(steps.group(1)) + len(ext)), 1)
    if ext:
        # AFTER THE LAST ext_resource, not at the end of the header. A .tscn
        # requires every ext_resource to precede every sub_resource, and the
        # gorge pass leaves 219 sub_resources sitting between them; appending
        # to the header put these on the wrong side of that block and Godot
        # refused the file outright with "Unknown tag in file: ext_resource".
        last = None
        for m in re.finditer(r"^\[ext_resource[^\]]*\]$", head, re.M):
            last = m
        if last is None:
            sys.exit("error: no ext_resource block to insert after")
        head = (head[:last.end()] + "\n" + "\n".join(ext) + head[last.end():])

    banner = ("\n; === MESHY KITS — uploaded groves and shelf set "
              "(generated by tools/place_kits.py) ===\n")
    open(SCENE, "w", encoding="utf-8").write(
        head.rstrip("\n") + "\n" + body.rstrip("\n") + "\n" + banner + "\n"
        + "\n".join(nodes))

    print("placed %d rim groves and %d estuary islets" % (len(GROVES), len(ISLETS)))
    print("ext_resources added: %d" % len(ext))
    print("triangles added: %d" % (len(GROVES) * 19998 + len(ISLETS) * 19998))


if __name__ == "__main__":
    main()
