"""Generate the forest kit — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/make_forest_kit.py -- \
        --output-root assets/environment [--seed 11]

The aquatic kit dresses the seabed. This one dresses everything ABOVE and
AROUND it: Coral Cove sits in a forested river valley, and without trees a
platforming route over open water reads as platforms floating in nothing.
Filling that space is not decoration — it is what tells a player how high up
they are, which is the single most important thing a jump needs to
communicate.

Five props, chosen for what each one does to the frame rather than for
variety's sake:

    canopy_tree     the vertical measure. A trunk tall enough to rise past
                    the route and a crown wide enough to close overhead, so
                    the player reads a ceiling of leaves rather than sky.
    understory_fern the floor scale. Small, dense, and placed far below —
                    a fall reads as a fall into a forest, not into a void.
    fallen_log      horizontal relief on the forest floor, which is
                    otherwise a flat plane seen from thirty metres up.
    river_reed      the waterline. Reeds mark where a river channel begins
                    and ends, which is a gameplay fact and not just a look:
                    a gap with reeds is survivable, one without is not.
    river_boulder   breaks the river's straight edges and gives the eye
                    something at the surface to judge depth against.

Built procedurally and deterministic under --seed, exactly like the aquatic
kit: the whole kit can be regenerated, re-palettes from a constant table,
and never depends on a binary nobody can rebuild. Colour is vertex colour;
the client's materials read it as albedo under the shared lighting rig.

One glb per asset directory, Asset Contract layout:

    assets/environment/<name>/<name>.glb

provenance.json sidecars are written by the CALLER (they are licensing
records, not geometry).
"""

from __future__ import annotations

import argparse
import math
import os
import random
import sys

import bpy  # type: ignore
import bmesh  # type: ignore

# The forest palette. The aquatic kit's rule holds and is why these are
# darker than they look on paper: under the rig's sky ambient a mid-tone prop
# washes out toward white, and the hero must stay the brightest thing on
# screen. Greens are deliberately blue-shifted so they sit beside the teal
# water rather than fighting it.
BARK_DARK = (0.16, 0.12, 0.10, 1.0)
BARK_LIGHT = (0.34, 0.27, 0.21, 1.0)
LEAF_DEEP = (0.06, 0.20, 0.13, 1.0)
LEAF_LIGHT = (0.22, 0.44, 0.24, 1.0)
FERN_DEEP = (0.08, 0.24, 0.16, 1.0)
FERN_TIP = (0.30, 0.52, 0.28, 1.0)
MOSS_DARK = (0.14, 0.22, 0.14, 1.0)
MOSS_LIGHT = (0.28, 0.38, 0.22, 1.0)
REED_DEEP = (0.16, 0.32, 0.18, 1.0)
REED_TIP = (0.48, 0.52, 0.26, 1.0)
STONE_DARK = (0.22, 0.24, 0.23, 1.0)
STONE_LIGHT = (0.42, 0.44, 0.40, 1.0)


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def kit_material() -> bpy.types.Material:
    """One shared material whose base colour is the mesh's vertex colour.

    Exported WITH the glb so Godot's importer sees a material next to a
    COLOR_0 attribute and enables vertex-colour albedo — a glb with no
    material at all imports as plain white and the whole palette is lost.
    """
    material = bpy.data.materials.get("forest_kit")
    if material is not None:
        return material
    material = bpy.data.materials.new("forest_kit")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Roughness"].default_value = 0.82
        attribute = material.node_tree.nodes.new("ShaderNodeVertexColor")
        material.node_tree.links.new(
            attribute.outputs["Color"], principled.inputs["Base Color"])
    return material


def paint(obj: bpy.types.Object, low, high, axis: int = 2) -> None:
    """Vertex-colour a mesh as a gradient from `low` at its bottom to `high`
    at its top (or along another axis), in corner domain so the exporter
    keeps it."""
    mesh = obj.data
    values = [v.co[axis] for v in mesh.vertices]
    lo, hi = min(values), max(values)
    span = (hi - lo) or 1.0
    layer = mesh.color_attributes.new(name="Col", type="BYTE_COLOR",
                                      domain="CORNER")
    for loop_index, loop in enumerate(mesh.loops):
        t = (mesh.vertices[loop.vertex_index].co[axis] - lo) / span
        layer.data[loop_index].color = tuple(
            low[i] + (high[i] - low[i]) * t for i in range(4))


def paint_flat(obj: bpy.types.Object, colour) -> None:
    """One colour over the whole mesh, for a piece whose gradient would read
    as a lighting error rather than as shape."""
    mesh = obj.data
    layer = mesh.color_attributes.new(name="Col", type="BYTE_COLOR",
                                      domain="CORNER")
    for loop_index in range(len(mesh.loops)):
        layer.data[loop_index].color = colour


def smooth(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()


def join_as(pieces, name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    return obj


def jitter(obj: bpy.types.Object, rng: random.Random, amount: float) -> None:
    """Nudges every vertex, which is what stops a generated prop reading as a
    primitive. Applied AFTER any transform, so the amount is in metres."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for vert in bm.verts:
        vert.co.x += (rng.random() - 0.5) * amount
        vert.co.y += (rng.random() - 0.5) * amount
        vert.co.z += (rng.random() - 0.5) * amount * 0.6
    bm.to_mesh(mesh)
    bm.free()


# --- The props ---------------------------------------------------------------

def make_canopy_tree(rng: random.Random) -> bpy.types.Object:
    """A tall trunk with a layered crown.

    Sized for the JOB rather than for botany: 14 m to the first leaves, so a
    tree planted on the forest floor still rises past a route eight metres
    up, and a crown wide enough that a handful of them close overhead.
    """
    pieces = []

    height = 14.0 + rng.random() * 4.0
    segments = 5
    lean_x = (rng.random() - 0.5) * 0.5
    lean_y = (rng.random() - 0.5) * 0.5
    for i in range(segments):
        t0 = i / segments
        t1 = (i + 1) / segments
        z0, z1 = height * t0, height * t1
        radius = 0.62 * (1.0 - t0 * 0.72)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=9, radius=radius, depth=(z1 - z0),
            location=(lean_x * z0 * 0.5, lean_y * z0 * 0.5, (z0 + z1) / 2))
        pieces.append(bpy.context.active_object)

    # Three crown lobes rather than one ball: a single sphere reads as a
    # lollipop from every angle, and the route is seen from every angle.
    for i in range(3):
        angle = rng.random() * math.tau
        spread = 1.1 + rng.random() * 1.5
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2, radius=2.6 + rng.random() * 1.1,
            location=(lean_x * height * 0.5 + math.cos(angle) * spread,
                      lean_y * height * 0.5 + math.sin(angle) * spread,
                      height + 0.6 + i * 1.15))
        lobe = bpy.context.active_object
        lobe.scale = (1.25, 1.25, 0.72)
        bpy.ops.object.transform_apply(scale=True)
        pieces.append(lobe)

    trunk = join_as(pieces[:segments], "trunk")
    jitter(trunk, rng, 0.10)
    paint(trunk, BARK_DARK, BARK_LIGHT)

    crown = join_as(pieces[segments:], "crown")
    jitter(crown, rng, 0.35)
    paint(crown, LEAF_DEEP, LEAF_LIGHT)
    smooth(crown)

    obj = join_as([trunk, crown], "canopy_tree")
    return obj


def make_understory_fern(rng: random.Random) -> bpy.types.Object:
    """A low rosette of fronds. Read at distance and in quantity, so what
    matters is the silhouette's raggedness, not the leaf shape."""
    pieces = []
    for i in range(7):
        angle = (i / 7.0) * math.tau + rng.random() * 0.4
        length = 0.75 + rng.random() * 0.55
        bpy.ops.mesh.primitive_cone_add(
            vertices=5, radius1=0.14, radius2=0.02, depth=length,
            location=(math.cos(angle) * length * 0.32,
                      math.sin(angle) * length * 0.32, length * 0.42))
        frond = bpy.context.active_object
        frond.rotation_euler = (math.radians(52.0 + rng.random() * 20.0),
                                0.0, angle + math.pi / 2)
        bpy.ops.object.transform_apply(rotation=True)
        pieces.append(frond)
    obj = join_as(pieces, "understory_fern")
    jitter(obj, rng, 0.05)
    paint(obj, FERN_DEEP, FERN_TIP)
    return obj


def make_fallen_log(rng: random.Random) -> bpy.types.Object:
    """A mossy trunk lying on the floor, with a broken stub at one end."""
    length = 4.4 + rng.random() * 2.0
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=11, radius=0.52, depth=length, location=(0.0, 0.0, 0.52))
    log = bpy.context.active_object
    log.rotation_euler = (0.0, math.radians(90.0), rng.random() * 0.3)
    bpy.ops.object.transform_apply(rotation=True)
    jitter(log, rng, 0.09)
    paint(log, BARK_DARK, BARK_LIGHT, axis=0)

    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=2, radius=0.42,
        location=(length * 0.5 - 0.15, 0.0, 0.62))
    stub = bpy.context.active_object
    stub.scale = (0.6, 1.0, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    jitter(stub, rng, 0.10)
    paint_flat(stub, MOSS_DARK)

    # A moss cap along the top, which is what separates a fallen log from a
    # pipe: the eye reads the two-material split as age.
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=11, radius=0.53, depth=length * 0.86,
        location=(0.0, 0.0, 0.60))
    cap = bpy.context.active_object
    cap.rotation_euler = (0.0, math.radians(90.0), 0.0)
    bpy.ops.object.transform_apply(rotation=True)
    cap.scale = (1.0, 1.0, 0.42)
    bpy.ops.object.transform_apply(scale=True)
    jitter(cap, rng, 0.06)
    paint(cap, MOSS_DARK, MOSS_LIGHT)

    return join_as([log, stub, cap], "fallen_log")


def make_river_reed(rng: random.Random) -> bpy.types.Object:
    """A clump of tall blades. Placed at a river's edge, so it reads as the
    waterline from above — which is the difference between a gap the player
    can survive and one they cannot."""
    pieces = []
    for _ in range(9):
        angle = rng.random() * math.tau
        height = 1.5 + rng.random() * 1.1
        lean = 0.12 + rng.random() * 0.3
        bpy.ops.mesh.primitive_cone_add(
            vertices=4, radius1=0.055, radius2=0.008, depth=height,
            location=(math.cos(angle) * 0.28, math.sin(angle) * 0.28,
                      height * 0.5))
        blade = bpy.context.active_object
        blade.rotation_euler = (lean, 0.0, angle)
        bpy.ops.object.transform_apply(rotation=True)
        pieces.append(blade)
    obj = join_as(pieces, "river_reed")
    jitter(obj, rng, 0.03)
    paint(obj, REED_DEEP, REED_TIP)
    return obj


def make_river_boulder(rng: random.Random) -> bpy.types.Object:
    """A wet stone that breaks a river's straight edge. Flatter than the
    aquatic kit's boulder, because it sits AT the surface and a round one
    reads as floating."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0)
    obj = bpy.context.active_object
    obj.scale = (1.45, 1.15, 0.52)
    bpy.ops.object.transform_apply(scale=True)
    jitter(obj, rng, 0.22)
    paint(obj, STONE_DARK, STONE_LIGHT)
    smooth(obj)
    obj.name = "river_boulder"
    return obj


BUILDERS = {
    "canopy_tree": make_canopy_tree,
    "understory_fern": make_understory_fern,
    "fallen_log": make_fallen_log,
    "river_reed": make_river_reed,
    "river_boulder": make_river_boulder,
}


def triangle_count(obj: bpy.types.Object) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def export(obj: bpy.types.Object, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True, export_colors=True)


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", default="assets/environment")
    parser.add_argument("--seed", type=int, default=11)
    parser.add_argument("--only", default="",
                        help="comma-separated prop names, for iterating on one")
    args = parser.parse_args(argv)

    wanted = [n.strip() for n in args.only.split(",") if n.strip()] \
        or list(BUILDERS)

    total = 0
    for name in wanted:
        if name not in BUILDERS:
            print("forest-kit: unknown prop '%s'" % name, file=sys.stderr)
            return 1
        clear_scene()
        rng = random.Random(args.seed + sum(ord(c) for c in name))
        obj = BUILDERS[name](rng)
        obj.data.materials.append(kit_material())
        # Every prop sits with its base at the origin, so a placement
        # transform in a world scene is the position it is planted at and
        # not a position plus a half-height nobody can see in the diff.
        low = min((obj.matrix_world @ v.co).z for v in obj.data.vertices)
        obj.location.z -= low
        bpy.ops.object.transform_apply(location=True)

        count = triangle_count(obj)
        total += count
        path = os.path.join(args.output_root, name, "%s.glb" % name)
        export(obj, path)
        print("forest-kit: %-16s %6d tris -> %s" % (name, count, path))

    print("forest-kit: %d triangles across %d props" % (total, len(wanted)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
