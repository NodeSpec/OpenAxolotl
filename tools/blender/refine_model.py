"""Refine a many-part character export into a game-ready glb — RUNS INSIDE
BLENDER (bpy), never as a plain Python script:

    blender --background --python tools/blender/refine_model.py -- \
        --input assets/character/axolotl/axolotl.glb \
        --output /tmp/axolotl.refined.glb [--smooth-angle 60]

tools/refine_model.py is the documented way to invoke this; it finds Blender,
builds exactly this command line, and validates what comes back.

What "refine" means here, and why each step:

  * MERGE BY ROLE. A generator that builds a creature from primitives leaves
    dozens of loose objects (the raw axolotl had 85). Each part is classified
    by its mean vertex colour against the hero palette — the SAME thresholds
    core/rendering/hero_skin.gd uses in the game — and every part of a role
    is joined into one mesh, so the file carries one object per role instead
    of one per sphere.
  * NAMED MATERIALS. Each role's mesh gets a material called `axolotl_<role>`.
    That name is the contract with the game client: HeroSkin dresses a
    surface by material name first and only falls back to vertex colours for
    a raw file that names nothing.
  * SMOOTH NORMALS. The raw export shipped no normals at all. Shade smooth
    with an auto-smooth angle keeps rounded parts rounded and hard edges
    hard, and the exporter writes the result so the engine never has to
    guess.
  * VERTEX COLOURS KEPT. The palette travels with the mesh; the client's
    materials read it as albedo.

Nothing here sculpts, decimates or subdivides: triangle count is preserved
exactly, so a model that met its category budget still meets it, and the
provenance sidecar's description of the geometry stays true.
"""

from __future__ import annotations

import argparse
import json
import math
import sys

import bpy  # type: ignore  # only importable inside Blender

# Palette thresholds — keep identical to core/rendering/hero_skin.gd.
EYE_MAX_LUMINANCE = 0.15
DETAIL_MAX_LUMINANCE = 0.4
GLEAM_MIN_CHANNEL = 0.97
GILL_MAX_GREEN = 0.5

ROLES = ("skin", "eye", "gleam", "gill", "detail")

# Base colour the material carries for viewers that ignore vertex colours,
# and the roughness the engine's own material will override anyway.
ROLE_BASE = {
    "skin": ((0.96, 0.75, 0.75, 1.0), 0.4),
    "eye": ((0.04, 0.05, 0.08, 1.0), 0.05),
    "gleam": ((1.0, 1.0, 1.0, 1.0), 1.0),
    "gill": ((0.90, 0.43, 0.53, 1.0), 0.5),
    "detail": ((0.37, 0.21, 0.28, 1.0), 0.85),
}


def luminance(r: float, g: float, b: float) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def classify(r: float, g: float, b: float) -> str:
    lum = luminance(r, g, b)
    if lum < EYE_MAX_LUMINANCE:
        return "eye"
    if r >= GLEAM_MIN_CHANNEL and g >= GLEAM_MIN_CHANNEL and b >= GLEAM_MIN_CHANNEL:
        return "gleam"
    if lum < DETAIL_MAX_LUMINANCE:
        return "detail"
    if g < GILL_MAX_GREEN:
        return "gill"
    return "skin"


def mean_color(mesh: bpy.types.Mesh) -> tuple[float, float, float] | None:
    attributes = mesh.color_attributes
    if len(attributes) == 0:
        return None
    layer = attributes.active_color or attributes[0]
    count = len(layer.data)
    if count == 0:
        return None
    total = [0.0, 0.0, 0.0]
    for item in layer.data:
        color = item.color
        total[0] += color[0]
        total[1] += color[1]
        total[2] += color[2]
    return (total[0] / count, total[1] / count, total[2] / count)


def role_material(role: str) -> bpy.types.Material:
    name = f"axolotl_{role}"
    material = bpy.data.materials.get(name)
    if material is not None:
        return material
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    base, roughness = ROLE_BASE[role]
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Base Color"].default_value = base
        principled.inputs["Roughness"].default_value = roughness
        # Vertex colours drive the base colour inside Blender too, so a
        # preview render matches what the engine will show.
        attribute = material.node_tree.nodes.new("ShaderNodeVertexColor")
        material.node_tree.links.new(
            attribute.outputs["Color"], principled.inputs["Base Color"])
    return material


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="refine_model (bpy)")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--smooth-angle", type=float, default=60.0,
                        help="auto-smooth angle in degrees (default 60)")
    return parser.parse_args(argv)


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.input)

    parts = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if not parts:
        print("REFINE " + json.dumps({"error": "no mesh objects in input"}))
        return 1

    by_role: dict[str, list[bpy.types.Object]] = {role: [] for role in ROLES}
    for obj in parts:
        color = mean_color(obj.data)
        role = "skin" if color is None else classify(*color)
        by_role[role].append(obj)

    bpy.ops.object.select_all(action="DESELECT")
    merged: dict[str, int] = {}
    for role, objects in by_role.items():
        if not objects:
            continue
        for obj in objects:
            obj.data.materials.clear()
            obj.data.materials.append(role_material(role))
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        joined = bpy.context.view_layer.objects.active
        joined.name = f"axolotl_{role}"
        joined.data.name = f"axolotl_{role}"
        bpy.ops.object.shade_smooth(
            use_auto_smooth=True,
            auto_smooth_angle=math.radians(args.smooth_angle))
        merged[role] = len(objects)

    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.export_scene.gltf(
        filepath=args.output,
        export_format="GLB",
        export_apply=True,
        export_normals=True,
        export_colors=True,
        export_materials="EXPORT",
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_yup=True,
    )

    triangles = sum(len(obj.data.polygons) for obj in bpy.data.objects
                    if obj.type == "MESH")
    print("REFINE " + json.dumps({
        "input": args.input,
        "output": args.output,
        "partsIn": len(parts),
        "meshesOut": len(merged),
        "mergedByRole": merged,
        "polygons": triangles,
        "smoothAngleDeg": args.smooth_angle,
        "blender": bpy.app.version_string,
    }))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
