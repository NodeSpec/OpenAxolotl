"""Generate the hero axolotl — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/make_axolotl.py -- \
        --output assets/character/axolotl/axolotl.glb

WHY THIS EXISTS. The shipped hero was a glb uploaded from a trimesh script
that was never committed: 85 primitives welded together, which is why it
read as a balloon animal rather than an animal. Worse, it could not be
REGENERATED — no proportion, no palette and no topology decision could be
revisited without hand-editing a binary. This is the generator that file
never had, built the same way the environment kit is: deterministic, in the
repo, and re-runnable.

HOW THE ANATOMY IS BUILT, and why not primitives. Every organic part is a
SKIN MODIFIER over an edge skeleton: a chain of vertices, each carrying a
radius, that Blender inflates into a continuous tube and then Subdivision
smooths. That gives real anatomy — a body that swells at the chest and
tapers into the tail, a head that is genuinely wider than it is tall, gill
fronds that branch — as ONE unbroken surface with no seams to hide, because
there are no separate pieces to seam. Welded spheres cannot do that at any
triangle count; the joins always read.

Two details that matter more than they look:

  * SKIN RADII ARE ELLIPTICAL (x, z). An axolotl's head is broad and flat
    and its tail is a vertical blade, and both fall straight out of asking
    for a wider radius on one axis than the other. A round tube cannot be
    either.
  * THE TAIL FIN is its own skeleton run alongside the tail with a very
    thin x radius and a tall z one, so it reads as a fin rather than as a
    thicker tail.

ROLES ARE BUILT IN, not classified afterwards. Each part is its own object
named `axolotl_<role>` carrying a material of the same name, which is the
contract the game client dresses by (core/rendering/hero_skin.gd) and the
names the rigger binds the eye and its highlight rigidly by. Vertex colours
still follow the palette thresholds both sides share, so the colour-only
fallback keeps working for a model that names nothing.

Head points +Y in Blender space, which the glTF exporter's Y-up conversion
turns into the -Z the game expects.
"""

from __future__ import annotations

import argparse
import json
import math
import sys

import bpy  # type: ignore

# --- Palette ----------------------------------------------------------------
# Kept inside the thresholds tools/blender/refine_model.py and hero_skin.gd
# both classify by, so a model that lost its material names still resolves.
SKIN_BACK = (0.93, 0.72, 0.74, 1.0)
SKIN_BELLY = (0.99, 0.88, 0.87, 1.0)
GILL_STALK = (0.88, 0.40, 0.48, 1.0)
GILL_TIP = (0.97, 0.55, 0.62, 1.0)
EYE_COLOUR = (0.03, 0.03, 0.05, 1.0)
GLEAM_COLOUR = (1.0, 1.0, 1.0, 1.0)
DETAIL_COLOUR = (0.34, 0.19, 0.25, 1.0)

# Material base colours, matching refine_model.ROLE_BASE.
ROLE_BASE = {
    "skin": ((0.96, 0.75, 0.75, 1.0), 0.4),
    "eye": ((0.04, 0.05, 0.08, 1.0), 0.05),
    "gleam": ((1.0, 1.0, 1.0, 1.0), 1.0),
    "gill": ((0.90, 0.43, 0.53, 1.0), 0.5),
    "detail": ((0.37, 0.21, 0.28, 1.0), 0.85),
}

# --- Proportions ------------------------------------------------------------
# (y, z, radius_x, radius_z) from tail tip to snout. The body is ONE chain:
# the taper from tail to chest and back down to the snout is the silhouette,
# so it lives in one table rather than being assembled from parts.
#
# PROPORTIONS ARE CHUNKY ON PURPOSE. A leaner, more anatomically faithful
# salamander was tried first and rendered as a lizard: correct, and wrong for
# this game. The hero of a family platformer needs an oversized head, a heavy
# middle and stubby limbs, because that silhouette stays readable when the
# axolotl is small on screen and is what makes it look like a character
# rather than a reference photo. Organic FORM, cartoon PROPORTION.
BODY = [
    (-2.90, 0.60, 0.05, 0.07),
    (-2.45, 0.60, 0.13, 0.18),
    (-2.00, 0.60, 0.21, 0.27),
    (-1.55, 0.60, 0.30, 0.34),
    (-1.10, 0.60, 0.40, 0.42),
    (-0.65, 0.60, 0.52, 0.47),
    (-0.20, 0.60, 0.62, 0.51),
    (0.25, 0.60, 0.68, 0.53),
    (0.62, 0.60, 0.70, 0.53),
    (0.95, 0.62, 0.86, 0.52),   # head: broad and flat, as an axolotl's is
    (1.22, 0.62, 0.84, 0.50),
    (1.42, 0.60, 0.60, 0.40),
    (1.54, 0.58, 0.28, 0.22),   # snout
]

# The tail blade: thin across, tall through, riding just above the tail.
TAIL_FIN = [
    (-2.86, 0.64, 0.015, 0.14),
    (-2.45, 0.70, 0.018, 0.32),
    (-2.00, 0.74, 0.020, 0.42),
    (-1.55, 0.74, 0.020, 0.40),
    (-1.10, 0.70, 0.019, 0.31),
    (-0.70, 0.66, 0.017, 0.18),
]

# (label, root y, root z, direction). Short and splayed: an axolotl's legs
# carry almost none of its weight, and stubby ones keep the body reading as
# the silhouette.
LEGS = [
    ("fl", 0.45, 0.34, (1.0, 0.12, -0.62)),
    ("fr", 0.45, 0.34, (-1.0, 0.12, -0.62)),
    ("bl", -0.70, 0.34, (1.0, -0.22, -0.66)),
    ("br", -0.70, 0.34, (-1.0, -0.22, -0.66)),
]

# Three fronds a side, sweeping back and out from behind the head. These are
# the axolotl's single most recognisable feature, so they are built big.
GILL_ANGLES = [0.55, 0.10, -0.35]


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def role_material(role: str) -> bpy.types.Material:
    """A material named for its role — the contract with the game client."""
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
        # Vertex colour drives albedo in engine; the base colour above is
        # only for viewers that ignore COLOR_0.
        attribute = material.node_tree.nodes.new("ShaderNodeVertexColor")
        material.node_tree.links.new(
            attribute.outputs["Color"], principled.inputs["Base Color"])
    return material


def skinned(name: str, points: list, subdivisions: int = 2,
            chains: list | None = None) -> bpy.types.Object:
    """Inflate an edge skeleton into a smooth organic tube.

    `points` are (x, y, z, radius_x, radius_z). `chains` lists the edges;
    omitted, the points form one open chain. This is the whole reason the
    model reads as an animal: one continuous surface, no welded joins.
    """
    verts = [(p[0], p[1], p[2]) for p in points]
    edges = chains if chains is not None else [
        (i, i + 1) for i in range(len(points) - 1)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, edges, [])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj

    skin = obj.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = True
    layer = obj.data.skin_vertices[0].data
    for index, point in enumerate(points):
        layer[index].radius = (point[3], point[4])
    layer[0].use_root = True

    subsurf = obj.modifiers.new("Subsurf", "SUBSURF")
    subsurf.levels = subdivisions
    subsurf.render_levels = subdivisions

    bpy.ops.object.modifier_apply(modifier="Skin")
    bpy.ops.object.modifier_apply(modifier="Subsurf")
    return obj


def sphere(name: str, location, radius: float,
           scale=(1.0, 1.0, 1.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=20, ring_count=12, radius=radius, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    bpy.ops.object.shade_smooth()
    return obj


def paint(obj: bpy.types.Object, low, high, axis: int = 2,
          invert: bool = False) -> None:
    """Gradient vertex colour in corner domain so the exporter keeps it."""
    mesh = obj.data
    values = [v.co[axis] for v in mesh.vertices]
    lo, hi = min(values), max(values)
    span = (hi - lo) or 1.0
    layer = mesh.color_attributes.get("Col") or mesh.color_attributes.new(
        name="Col", type="BYTE_COLOR", domain="CORNER")
    for loop_index, loop in enumerate(mesh.loops):
        t = (mesh.vertices[loop.vertex_index].co[axis] - lo) / span
        if invert:
            t = 1.0 - t
        layer.data[loop_index].color = tuple(
            low[i] + (high[i] - low[i]) * t for i in range(4))


def join_as(name: str, pieces: list, role: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    if len(pieces) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    obj.data.materials.clear()
    obj.data.materials.append(role_material(role))
    return obj


def build_skin() -> bpy.types.Object:
    """Body, tail fin and legs — the one continuous pink surface."""
    body = skinned("body", [(0.0, y, z, rx, rz) for y, z, rx, rz in BODY])
    # Belly lighter than the back, which is what stops a single-colour
    # creature reading as a toy: real animals are counter-shaded.
    paint(body, SKIN_BELLY, SKIN_BACK, axis=2)
    pieces = [body]

    fin = skinned("tail_fin",
                  [(0.0, y, z, rx, rz) for y, z, rx, rz in TAIL_FIN],
                  subdivisions=2)
    paint(fin, SKIN_BACK, SKIN_BELLY, axis=2)
    pieces.append(fin)

    for label, root_y, root_z, direction in LEGS:
        dx, dy, dz = direction
        points = [
            (dx * 0.30, root_y + dy * 0.06, root_z, 0.150, 0.150),
            (dx * 0.52, root_y + dy * 0.16, root_z + dz * 0.20, 0.120, 0.120),
            (dx * 0.70, root_y + dy * 0.26, root_z + dz * 0.40, 0.095, 0.095),
            (dx * 0.95, root_y + dy * 0.34, root_z + dz * 0.52, 0.125, 0.050),
        ]
        leg = skinned(f"leg_{label}", points, subdivisions=2)
        paint(leg, SKIN_BACK, SKIN_BELLY, axis=2)
        pieces.append(leg)

    return join_as("axolotl_skin", pieces, "skin")


def build_gills() -> bpy.types.Object:
    """Six fronds: a stalk that branches into three filaments each."""
    pieces = []
    for side in (1.0, -1.0):
        for angle in GILL_ANGLES:
            base_x = side * 0.52
            base_y = 0.72
            base_z = 0.66
            out = side * math.cos(angle)
            back = math.sin(angle)
            reach_x, reach_y, reach_z = 1.05, 0.52, 0.06
            stalk = skinned(
                f"gill_{side:.0f}_{angle:.2f}",
                [
                    (base_x, base_y, base_z, 0.100, 0.100),
                    (base_x + out * reach_x * 0.34,
                     base_y + back * reach_y * 0.34,
                     base_z + reach_z * 0.40, 0.085, 0.085),
                    (base_x + out * reach_x * 0.68,
                     base_y + back * reach_y * 0.68,
                     base_z + reach_z * 0.75, 0.062, 0.062),
                    (base_x + out * reach_x, base_y + back * reach_y,
                     base_z + reach_z, 0.032, 0.032),
                ],
                subdivisions=1)
            paint(stalk, GILL_STALK, GILL_TIP, axis=0,
                  invert=side < 0.0)
            pieces.append(stalk)

            # Filaments: what makes a frond read as feathery rather than as
            # a rod. Fanned off the stalk's outer two thirds.
            for step in (0.30, 0.50, 0.70, 0.88):
                fx = base_x + out * reach_x * step
                fy = base_y + back * reach_y * step
                fz = base_z + reach_z * step
                for lift, sweep in ((0.22, -0.10), (0.00, -0.21),
                                    (-0.22, -0.10)):
                    filament = skinned(
                        f"fil_{side:.0f}_{angle:.2f}_{step}_{lift}",
                        [
                            (fx, fy, fz, 0.042, 0.042),
                            (fx + out * 0.20, fy + sweep,
                             fz + lift, 0.016, 0.016),
                        ],
                        subdivisions=1)
                    paint(filament, GILL_STALK, GILL_TIP, axis=2)
                    pieces.append(filament)

    return join_as("axolotl_gill", pieces, "gill")


def build_eyes() -> bpy.types.Object:
    pieces = []
    for side in (1.0, -1.0):
        eye = sphere(f"eye_{side:.0f}", (side * 0.60, 1.16, 0.74), 0.135)
        paint(eye, EYE_COLOUR, EYE_COLOUR)
        pieces.append(eye)
    return join_as("axolotl_eye", pieces, "eye")


def build_gleams() -> bpy.types.Object:
    pieces = []
    for side in (1.0, -1.0):
        gleam = sphere(f"gleam_{side:.0f}",
                       (side * 0.645, 1.225, 0.800), 0.048)
        paint(gleam, GLEAM_COLOUR, GLEAM_COLOUR)
        pieces.append(gleam)
    return join_as("axolotl_gleam", pieces, "gleam")


def build_detail() -> bpy.types.Object:
    """Mouth line and nostrils. Tiny, and the only thing suggesting a face."""
    pieces = []
    mouth = sphere("mouth", (0.0, 1.47, 0.50), 0.12,
                   scale=(1.6, 0.5, 0.22))
    paint(mouth, DETAIL_COLOUR, DETAIL_COLOUR)
    pieces.append(mouth)
    for side in (1.0, -1.0):
        nostril = sphere(f"nostril_{side:.0f}",
                         (side * 0.10, 1.53, 0.61), 0.028)
        paint(nostril, DETAIL_COLOUR, DETAIL_COLOUR)
        pieces.append(nostril)
    return join_as("axolotl_detail", pieces, "detail")


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(prog="make_axolotl (bpy)")
    parser.add_argument("--output", required=True)
    args = parser.parse_args(argv)

    clear_scene()
    built = {
        "skin": build_skin(),
        "gill": build_gills(),
        "eye": build_eyes(),
        "gleam": build_gleams(),
        "detail": build_detail(),
    }

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=args.output, export_format="GLB", export_apply=True,
        export_normals=True, export_colors=True, export_materials="EXPORT",
        export_animations=False, export_skins=False, export_morph=False,
        export_yup=True)

    triangles = 0
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        for polygon in obj.data.polygons:
            triangles += max(len(polygon.vertices) - 2, 1)
    print("AXOLOTL " + json.dumps({
        "output": args.output,
        "meshes": {role: obj.name for role, obj in built.items()},
        "triangles": triangles,
        "blender": bpy.app.version_string,
    }))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
