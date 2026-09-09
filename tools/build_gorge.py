#!/usr/bin/env python3
"""Generate the Coral Cove gorge: walls, valley bed and water channel lips.

Emits named nodes into worlds/coral_cove/world.tscn under a single `Gorge`
parent, so the enclosure reads in a diff the way the hand-authored landmarks
do rather than arriving as an opaque cloud.

WHY THE LEVEL NEEDED THIS. The scenery was three boxes: a 420x420 slab at
y=-24 and two 44x40 walls parked at x=+/-96. From inside the level that reads
as a ribbon of platforms floating over an empty green plane -- the water is an
unbounded translucent slab you can walk out of, and the "canyon" is a distant
backdrop with 80 units of nothing between it and the play space. It also
stopped at z=-270, so the Flagship arena at z=-290 had no scenery at all.

THE ENVELOPE THAT MAKES THIS SAFE. The route never exceeds |x| = 10.5 and the
widest water volume reaches |x| = 13, so an inner wall face at |x| >= 14
cannot touch gameplay. That is the whole reason this can be generated rather
than hand-fitted around the route.
"""
import math
import random
import re
import sys

SCENE = "worlds/coral_cove/world.tscn"

MOSSY = "4_surface_mossy_stone"
RIVER_STONE = "5_surface_river_stone"
SAND = "6_surface_river_sand"
EARTH = "7_surface_forest_earth"
WATER_MAT = "3_watermat"

## Rim and backdrop stop here: past it the valley opens into the estuary and
## the sea plane takes over the horizon. Carrying a green shelf out over open
## water was the other half of why the Flagship read as a sand bar.
Z_RIM_END = -268.0

# Z from the opening lip to past the Flagship finish (route ends at z=-307).
Z_START, Z_END = 20.0, -326.0

# The gorge profile: (z, inner face |x|, wall top y). Linearly interpolated
# between control points, so the valley narrows through the platforming acts
# and opens out at the river mouth where the Flagship sits in open sea.
PROFILE = [
    (20.0, 20.0, 20.0),    # opening: wide and low, you can see in
    (-10.0, 16.0, 26.0),   # act 1-2: closes in
    (-60.0, 14.5, 32.0),   # act 3-4: tightest, most vertical
    (-110.0, 15.0, 34.0),  # gorge river
    (-160.0, 16.0, 30.0),  # tide race
    (-200.0, 18.0, 28.0),  # coral shelf
    (-250.0, 22.0, 24.0),  # shelf wall, starting to open
    (-275.0, 28.0, 18.0),  # river mouth
    (-300.0, 34.0, 14.0),  # open sea: headlands only
    (-326.0, 38.0, 12.0),
]

BED_Y_TOP = -13.5    # just under the deepest water volume
BED_Y_BOTTOM = -30.0
WALL_Y_BOTTOM = -30.0
SEGMENT_Z = 14.0     # nominal segment length before jitter

# Water volumes: (name, centre z, half-depth z, half-width x, waterline y).
WATER = [
    ("Waterway", -21.75, 28.75, 13.0, 4.0),
    ("GorgeRiver", -103.0, 5.1, 11.0, 7.6),
    ("RaceChannel", -172.0, 15.0, 13.0, 2.6),
    ("OpenSea", -292.0, 23.0, 6.5, 3.3),
]


def lerp_profile(z):
    """Inner wall face and wall top height at a given z."""
    pts = PROFILE
    if z >= pts[0][0]:
        return pts[0][1], pts[0][2]
    for (z0, x0, y0), (z1, x1, y1) in zip(pts, pts[1:]):
        if z1 <= z <= z0:
            t = (z0 - z) / (z0 - z1)
            return x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
    return pts[-1][1], pts[-1][2]


def yaw(theta):
    """Transform3D basis for a yaw about Y, in .tscn serialisation order."""
    c, s = math.cos(theta), math.sin(theta)
    return (c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c)


def xform(theta, origin):
    b = yaw(theta)
    return ", ".join("%.4g" % v for v in (*b, *origin))


class Emitter:
    def __init__(self):
        self.subs = []
        self.nodes = []
        self.n = 0

    def box(self, kind, size):
        """A BoxMesh or BoxShape3D sub-resource; returns its id."""
        self.n += 1
        sid = "%s_gorge%d" % (kind, self.n)
        self.subs.append(
            '[sub_resource type="%s" id="%s"]\nsize = Vector3(%.4g, %.4g, %.4g)\n'
            % (kind, sid, *size))
        return sid

    def solid(self, name, parent, size, origin, theta, material, collide):
        mesh = self.box("BoxMesh", size)
        node_type = "StaticBody3D" if collide else "MeshInstance3D"
        head = '[node name="%s" type="%s" parent="%s"]\ntransform = Transform3D(%s)\n' % (
            name, node_type, parent, xform(theta, origin))
        if collide:
            shape = self.box("BoxShape3D", size)
            head += (
                '\n[node name="Mesh" type="MeshInstance3D" parent="%s/%s"]\n'
                'mesh = SubResource("%s")\n'
                'surface_material_override/0 = ExtResource("%s")\n'
                '\n[node name="Collision" type="CollisionShape3D" parent="%s/%s"]\n'
                'shape = SubResource("%s")\n' % (
                    parent, name, mesh, material, parent, name, shape))
        else:
            head += ('mesh = SubResource("%s")\n'
                     'surface_material_override/0 = ExtResource("%s")\n'
                     % (mesh, material))
        self.nodes.append(head)


def build():
    rng = random.Random(20260909)
    e = Emitter()
    e.nodes.append('[node name="Gorge" type="Node3D" parent="."]\n')

    # ---- Walls -----------------------------------------------------------
    # Each side is a run of segments whose inner face, height and yaw all
    # wander around the profile. The variation is the whole point: one long
    # box at a constant inset is exactly what the old ridges were, and it read
    # as a painted backdrop rather than as rock the level is cut into.
    z = Z_START
    index = 0
    while z > Z_END:
        length = SEGMENT_Z + rng.uniform(-3.0, 4.0)
        z_mid = z - length / 2.0
        inner, top = lerp_profile(z_mid)
        for side, sign in (("West", -1.0), ("East", 1.0)):
            index_name = "GorgeWall%s%02d" % (side, index)
            jitter = rng.uniform(-0.6, 2.8)      # only ever pushes OUTWARD
            face = inner + jitter
            height = top + rng.uniform(-3.0, 3.0) - WALL_Y_BOTTOM
            thickness = 10.0 + rng.uniform(0.0, 6.0)
            cx = sign * (face + thickness / 2.0)
            cy = WALL_Y_BOTTOM + height / 2.0
            e.solid(index_name, "Gorge",
                    (thickness, height, length + 1.5),
                    (cx, cy, z_mid),
                    rng.uniform(-0.06, 0.06),
                    MOSSY, collide=True)
        z -= length
        index += 1
    walls = index * 2

    # ---- Valley bed ------------------------------------------------------
    # Fills the trough between the walls beneath the play space so the level
    # never shows its underside. Scenery only: the gameplay floors (RiverBed,
    # LagoonFloor, the shelves) already own every surface a player can reach.
    z = Z_START
    beds = 0
    while z > Z_END:
        length = 26.0
        z_mid = z - length / 2.0
        inner, _ = lerp_profile(z_mid)
        e.solid("ValleyBed%02d" % beds, "Gorge",
                ((inner + 12.0) * 2.0, BED_Y_TOP - BED_Y_BOTTOM, length + 1.0),
                (0.0, (BED_Y_TOP + BED_Y_BOTTOM) / 2.0, z_mid),
                0.0, EARTH, collide=False)
        z -= length
        beds += 1

    # ---- Channel lips ----------------------------------------------------
    # A rock kerb along both sides of every water volume, sitting at the
    # waterline. This is the piece that makes water read as CONTAINED: without
    # it the surface simply stops at a straight edge in mid-air.
    lips = 0
    for name, cz, half_z, half_x, water_y in WATER:
        steps = max(3, int(half_z * 2 / 9.0))
        for i in range(steps):
            t = (i + 0.5) / steps
            z_mid = cz + half_z - t * half_z * 2
            length = (half_z * 2 / steps) + 1.0
            for side, sign in (("West", -1.0), ("East", 1.0)):
                out = rng.uniform(0.4, 1.6)
                lip_h = 2.2 + rng.uniform(0.0, 1.6)
                e.solid("Lip%s%s%02d" % (name, side, i), "Gorge",
                        (2.6 + out, lip_h, length),
                        (sign * (half_x + 1.0 + out / 2.0),
                         water_y - lip_h / 2.0 + 0.55, z_mid),
                        rng.uniform(-0.10, 0.10),
                        RIVER_STONE, collide=False)
                lips += 1

    # ---- Rim plateau -----------------------------------------------------
    # Ground ABOVE the gorge, level with each wall top and running outward.
    # Without it the walls are a fence: you see over them straight into empty
    # sky and the old 420x420 floor slab far below, which is exactly what made
    # the level read as a diorama on a table. With it, the top of the wall is
    # where the forest starts.
    z = Z_START
    rims = 0
    while z > Z_RIM_END:
        length = 22.0
        z_mid = z - length / 2.0
        inner, top = lerp_profile(z_mid)
        for side, sign in (("West", -1.0), ("East", 1.0)):
            width = 90.0
            # Tucked UNDER the thinnest wall (outer face can be as close as
            # inner + 9.4), or a slot of void shows between rim and wall.
            foot = inner + 8.0
            e.solid("Rim%s%02d" % (side, rims), "Gorge",
                    (width, 6.0, length + 1.0),
                    (sign * (foot + width / 2.0), top - 3.0 + rng.uniform(-1.2, 1.2),
                     z_mid),
                    0.0, EARTH, collide=False)
            rims += 1
        z -= length

    # ---- Open sea --------------------------------------------------------
    # The Flagship fights at a river MOUTH, and the level has to say so. The
    # arena's own OpenSea volume is 13 units wide; past its edge there was
    # nothing but the horizon join, so the climax read as a sand bar rather
    # than as water without a far side. This plane sits a fraction under the
    # volume's waterline so the volume's own animated surface still wins where
    # the two overlap, and runs out past the fog.
    e.solid("OpenSeaPlane", "Gorge",
            (760.0, 0.4, 360.0), (0.0, 3.1, -430.0), 0.0, WATER_MAT,
            collide=False)

    # Headlands: the far side of the estuary, framing the Flagship silhouette
    # instead of letting it sit against empty sky.
    for side, sign in (("West", -1.0), ("East", 1.0)):
        for i, (dx, dz, w, h, d) in enumerate((
                (58.0, -300.0, 40.0, 26.0, 64.0),
                (96.0, -352.0, 56.0, 34.0, 80.0),
                (150.0, -404.0, 74.0, 44.0, 96.0))):
            e.solid("Headland%s%02d" % (side, i), "Gorge",
                    (w, h, d), (sign * dx, 3.0 + h / 2.0 - 7.0, dz),
                    rng.uniform(-0.15, 0.15), MOSSY, collide=False)

    # ---- Backdrop ridges -------------------------------------------------
    # Two far walls closing the horizon above the rim, so the skyline is
    # forested hillside rather than the flat join between fog and sky.
    for side, sign in (("West", -1.0), ("East", 1.0)):
        for i in range(9):
            length = (Z_START - Z_RIM_END) / 9.0
            z_mid = Z_START - (i + 0.5) * length
            height = 46.0 + rng.uniform(-8.0, 10.0)
            e.solid("Backdrop%s%02d" % (side, i), "Gorge",
                    (34.0, height, length + 4.0),
                    (sign * 118.0, 10.0 + height / 2.0 - 20.0, z_mid),
                    rng.uniform(-0.05, 0.05), EARTH, collide=False)

    # ---- Shore shelves ---------------------------------------------------
    # A sand bench between each channel lip and the wall foot, so the eye has
    # somewhere for the water to have come from.
    shores = 0
    for name, cz, half_z, half_x, water_y in WATER:
        steps = max(2, int(half_z * 2 / 16.0))
        for i in range(steps):
            t = (i + 0.5) / steps
            z_mid = cz + half_z - t * half_z * 2
            length = (half_z * 2 / steps) + 1.0
            inner, _ = lerp_profile(z_mid)
            # CAPPED. Filling the whole gap to the wall works in the gorge,
            # where it is a couple of metres, but at the river mouth the walls
            # stand off 34 units and an uncapped bench turned the Flagship's
            # open sea into a sand plain with a hard edge.
            width = min(6.0, max(1.5, inner - half_x - 2.0))
            for side, sign in (("West", -1.0), ("East", 1.0)):
                e.solid("Shore%s%s%02d" % (name, side, i), "Gorge",
                        (width, 2.4, length),
                        (sign * (half_x + 2.2 + width / 2.0),
                         water_y - 1.5, z_mid),
                        0.0, SAND, collide=False)
                shores += 1

    return e, walls, beds, lips, shores


## The three scenery boxes the gorge replaces. Removed rather than left
## hidden: they are what the player was actually seeing past the play space,
## and a 420x420 slab at y=-24 under an enclosed valley is geometry that can
## only ever be looked at by mistake.
SUPERSEDED = ("ForestFloor", "RidgeWest", "RidgeEast")


def strip_superseded(src):
    removed = []
    for name in SUPERSEDED:
        pattern = r'\[node name="%s" type="MeshInstance3D" parent="Scenery"\]\n(?:[^\[\n][^\n]*\n|\n(?!\[))*' % name
        new = re.sub(pattern, "", src, count=1)
        if new != src:
            removed.append(name)
            src = new
    return src, removed


def main():
    src = open(SCENE, encoding="utf-8").read()
    if 'name="Gorge"' in src:
        sys.exit("error: the scene already carries a Gorge; remove it first")

    src, removed = strip_superseded(src)
    print("superseded scenery removed: %s" % (", ".join(removed) or "none"))

    e, walls, beds, lips, shores = build()

    first_node = src.index("\n[node ")
    head, body = src[:first_node], src[first_node:]

    steps = re.search(r"load_steps=(\d+)", head)
    head = head.replace("load_steps=%s" % steps.group(1),
                        "load_steps=%d" % (int(steps.group(1)) + len(e.subs)), 1)

    banner = ("\n; === GORGE — the enclosure (generated by "
              "tools/build_gorge.py) ===\n")
    out = head.rstrip("\n") + "\n\n" + "\n".join(e.subs) + body.rstrip("\n") \
        + "\n" + banner + "\n" + "\n".join(e.nodes)
    open(SCENE, "w", encoding="utf-8").write(out)

    print("gorge written: %d wall segments, %d bed slabs, %d channel lips, "
          "%d shore benches" % (walls, beds, lips, shores))
    print("sub-resources added: %d" % len(e.subs))
    print("triangles added (boxes, 12 tris each): %d"
          % ((walls + beds + lips + shores) * 12))


if __name__ == "__main__":
    main()
