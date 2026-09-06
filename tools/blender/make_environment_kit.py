"""Generate the aquatic environment kit — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/make_environment_kit.py -- \
        --output-root assets/environment [--seed 7]

The kit is the modular dressing every scene shares: rocks, coral, kelp and
seagrass, in the palette the art direction names (teals, sea-greens, warm
coral accents). Each prop is BUILT here procedurally — deterministic under
--seed — so the whole kit can be regenerated, re-palettes with a constant
table, and never depends on a binary nobody can rebuild. Colour is vertex
colour, exactly like the hero: the client's materials read it as albedo
under the shared lighting rig.

One glb per asset directory, Asset Contract layout:

    assets/environment/<name>/<name>.glb

provenance.json sidecars are written by the CALLER (they are licensing
records, not geometry), and triangle counts stay far under the environment
budget of 200k: the whole kit is a few thousand triangles, because these
props are seen dozens at a time.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import random
import sys

import bpy  # type: ignore
import bmesh  # type: ignore

# The aquatic palette (docs/asset-contract.md): value contrast against the
# seabed, no colour louder than the hero.
ROCK_DARK = (0.36, 0.42, 0.44, 1.0)
ROCK_LIGHT = (0.55, 0.62, 0.6, 1.0)
CORAL_WARM = (0.93, 0.5, 0.38, 1.0)
CORAL_TIP = (0.98, 0.72, 0.55, 1.0)
KELP_DEEP = (0.13, 0.42, 0.3, 1.0)
KELP_BRIGHT = (0.3, 0.68, 0.42, 1.0)
GRASS_DEEP = (0.2, 0.55, 0.4, 1.0)
GRASS_TIP = (0.55, 0.8, 0.5, 1.0)


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def kit_material() -> bpy.types.Material:
    """One shared material whose base colour is the mesh's vertex colour.

    Exported WITH the glb so Godot's importer sees a material next to a
    COLOR_0 attribute and enables vertex-colour albedo — a glb with no
    material at all imports as plain white and the whole palette is lost.
    """
    material = bpy.data.materials.get("environment_kit")
    if material is not None:
        return material
    material = bpy.data.materials.new("environment_kit")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Roughness"].default_value = 0.75
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


def smooth(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()


def make_rock(rng: random.Random) -> bpy.types.Object:
    """A rounded boulder: displaced icosphere, squashed, gradient grey-teal."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0)
    obj = bpy.context.active_object
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for vert in bm.verts:
        bump = 1.0 + 0.22 * (rng.random() - 0.5) \
            + 0.1 * math.sin(vert.co.x * 3.1) * math.cos(vert.co.y * 2.7)
        vert.co *= bump
    bm.to_mesh(mesh)
    bm.free()
    obj.scale = (1.25, 1.0, 0.72)
    bpy.ops.object.transform_apply(scale=True)
    paint(obj, ROCK_DARK, ROCK_LIGHT)
    smooth(obj)
    obj.name = "rock_cluster"
    return obj


def make_coral(rng: random.Random) -> bpy.types.Object:
    """A branching coral: a trunk and two levels of child cylinders."""
    pieces = []

    def branch(base, direction, length, radius, depth):
        top = tuple(base[i] + direction[i] * length for i in range(3))
        mid = tuple((base[i] + top[i]) / 2 for i in range(3))
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10, radius=radius, depth=length, location=mid)
        piece = bpy.context.active_object
        axis = bpy.context.active_object.rotation_euler
        # Point the cylinder along `direction`.
        dx, dy, dz = direction
        axis[1] = math.acos(max(-1.0, min(1.0, dz)))
        axis[2] = math.atan2(dy, dx)
        pieces.append(piece)
        if depth <= 0:
            return
        for _ in range(2):
            tilt = rng.uniform(0.35, 0.8)
            spin = rng.uniform(0.0, math.tau)
            child = (
                math.sin(tilt) * math.cos(spin),
                math.sin(tilt) * math.sin(spin),
                math.cos(tilt),
            )
            branch(top, child, length * 0.62, radius * 0.62, depth - 1)

    branch((0.0, 0.0, 0.0), (0.0, 0.0, 1.0), 0.7, 0.11, 2)
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(rotation=True, location=True)
    paint(obj, CORAL_WARM, CORAL_TIP)
    smooth(obj)
    obj.name = "coral_branch"
    return obj


def make_kelp(rng: random.Random) -> bpy.types.Object:
    """A swaying kelp strand: a chain of squashed spheres leaning sideways."""
    pieces = []
    x = 0.0
    for step in range(7):
        z = 0.18 + step * 0.34
        x += math.sin(step * 1.1) * 0.09 + rng.uniform(-0.02, 0.02)
        size = 0.16 * (1.0 - step * 0.09)
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=6, radius=1.0, location=(x, 0.0, z))
        piece = bpy.context.active_object
        piece.scale = (size, size * 0.6, 0.24)
        pieces.append(piece)
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(scale=True, location=True)
    paint(obj, KELP_DEEP, KELP_BRIGHT)
    smooth(obj)
    obj.name = "kelp_strand"
    return obj


def make_seagrass(rng: random.Random) -> bpy.types.Object:
    """A tuft of thin cones fanning out of one root."""
    pieces = []
    for blade in range(6):
        spin = blade * math.tau / 6 + rng.uniform(-0.2, 0.2)
        lean = rng.uniform(0.12, 0.3)
        height = rng.uniform(0.5, 0.85)
        bpy.ops.mesh.primitive_cone_add(
            vertices=6, radius1=0.05, radius2=0.008, depth=height,
            location=(math.cos(spin) * 0.07, math.sin(spin) * 0.07,
                      height / 2))
        piece = bpy.context.active_object
        piece.rotation_euler = (lean * math.cos(spin),
                                lean * math.sin(spin), 0.0)
        pieces.append(piece)
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(rotation=True, location=True)
    paint(obj, GRASS_DEEP, GRASS_TIP)
    smooth(obj)
    obj.name = "seagrass_tuft"
    return obj


BUILDERS = {
    "rock_cluster": make_rock,
    "coral_branch": make_coral,
    "kelp_strand": make_kelp,
    "seagrass_tuft": make_seagrass,
}


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(prog="make_environment_kit (bpy)")
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args(argv)

    report = {}
    for name, builder in BUILDERS.items():
        clear_scene()
        rng = random.Random(args.seed)
        obj = builder(rng)
        obj.data.materials.clear()
        obj.data.materials.append(kit_material())
        directory = os.path.join(args.output_root, name)
        os.makedirs(directory, exist_ok=True)
        target = os.path.join(directory, f"{name}.glb")
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.export_scene.gltf(
            filepath=target, export_format="GLB", export_apply=True,
            export_normals=True, export_colors=True,
            export_materials="EXPORT", export_animations=False,
            export_skins=False, export_morph=False, export_yup=True)
        report[name] = {"polygons": sum(
            len(o.data.polygons) for o in bpy.data.objects
            if o.type == "MESH")}
    print("KIT " + json.dumps({"seed": args.seed, "assets": report,
                               "blender": bpy.app.version_string}))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
