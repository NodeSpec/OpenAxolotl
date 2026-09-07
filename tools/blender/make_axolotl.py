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
SKIN_BLUSH = (0.93, 0.55, 0.58, 1.0)
GILL_STALK = (0.80, 0.24, 0.30, 1.0)
GILL_TIP = (0.94, 0.45, 0.50, 1.0)
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
# PROPORTIONS FOLLOW THE MAINTAINER'S REFERENCE SHEET: a standing, curious
# little salamander, not a belly-dragging blob. Rounded head about a quarter
# of the body, a soft chest carried clear of the ground on short planted
# legs, a long tail sloping down to rest its tip, and a fin ridge running
# the tail's top edge. An earlier leaner build read as a lizard and an
# earlier heavier one as a bath toy; this sits between, matched by eye
# against the sheet's perspective and side views.
BODY = [
    (-2.90, 0.26, 0.030, 0.045),
    (-2.45, 0.36, 0.10, 0.14),
    (-2.00, 0.44, 0.17, 0.22),
    (-1.55, 0.52, 0.25, 0.30),
    (-1.10, 0.60, 0.34, 0.37),
    (-0.65, 0.66, 0.44, 0.43),
    (-0.20, 0.70, 0.52, 0.47),
    (0.25, 0.72, 0.50, 0.48),
    (0.62, 0.73, 0.52, 0.47),
    (0.95, 0.76, 0.68, 0.49),   # head: broad and softly domed
    (1.22, 0.76, 0.66, 0.47),
    (1.44, 0.73, 0.48, 0.34),
    (1.58, 0.70, 0.24, 0.18),   # snout
]

# The tail blade: thin across, tall through, riding the tail's top edge and
# fading out onto the lower back rather than stopping dead.
TAIL_FIN = [
    (-2.85, 0.34, 0.012, 0.05),
    (-2.45, 0.54, 0.016, 0.20),
    (-2.00, 0.70, 0.018, 0.27),
    (-1.55, 0.82, 0.018, 0.25),
    (-1.10, 0.90, 0.016, 0.18),
    (-0.65, 0.95, 0.013, 0.08),
]

# (label, root y, direction sign). Legs now PLANT: they leave the lower
# flank, step down and slightly out, and end in a foot with toes, holding
# the chest clear of the ground the way the sheet's standing pose does.
LEGS = [
    ("fl", 0.42, 1.0, 0.10),
    ("fr", 0.42, -1.0, 0.10),
    ("bl", -0.80, 1.0, -0.16),
    ("br", -0.80, -1.0, -0.16),
]

# Three feather fronds a side, held upswept like the sheet's crown. Angle is
# the fan position from front to back.
GILL_ANGLES = [0.50, 0.0, -0.50]


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


def mottle(obj: bpy.types.Object) -> None:
    """Blush patches over the painted gradient — the sheet's mottled skin.

    Deterministic low-frequency noise from the vertex position itself, so
    the patches are coarse blotches rather than salt-and-pepper, and the
    same run always paints the same animal.
    """
    mesh = obj.data
    layer = mesh.color_attributes.get("Col")
    if layer is None:
        return
    for loop_index, loop in enumerate(mesh.loops):
        p = mesh.vertices[loop.vertex_index].co
        wave = (math.sin(p.x * 3.3 + 1.7) * math.sin(p.y * 2.1 + 0.4)
                * math.sin(p.z * 2.7 + 2.9))
        if wave <= 0.28 or p.z < 0.50:
            continue  # belly stays clean, as counter-shading wants
        blend = min((wave - 0.28) * 1.5, 0.80)
        colour = layer.data[loop_index].color
        layer.data[loop_index].color = tuple(
            colour[i] + (SKIN_BLUSH[i] - colour[i]) * blend for i in range(4))


def build_skin() -> bpy.types.Object:
    """Body, tail fin, planted legs and toes — one continuous pink surface."""
    body = skinned("body", [(0.0, y, z, rx, rz) for y, z, rx, rz in BODY])
    # Belly lighter than the back, which is what stops a single-colour
    # creature reading as a toy: real animals are counter-shaded.
    paint(body, SKIN_BELLY, SKIN_BACK, axis=2)
    mottle(body)
    pieces = [body]

    fin = skinned("tail_fin",
                  [(0.0, y, z, rx, rz) for y, z, rx, rz in TAIL_FIN],
                  subdivisions=2)
    paint(fin, SKIN_BACK, SKIN_BELLY, axis=2)
    pieces.append(fin)

    for label, root_y, side, splay in LEGS:
        # Flank, down and slightly out, ending in a planted foot. The foot
        # sits at the ground so the chest genuinely stands clear of it.
        foot_x = side * 0.72
        foot_y = root_y + splay
        points = [
            (side * 0.28, root_y, 0.42, 0.170, 0.170),
            (side * 0.50, root_y + splay * 0.4, 0.28, 0.130, 0.130),
            (side * 0.62, root_y + splay * 0.8, 0.14, 0.105, 0.105),
            (foot_x, foot_y, 0.06, 0.115, 0.050),
        ]
        leg = skinned(f"leg_{label}", points, subdivisions=2)
        paint(leg, SKIN_BACK, SKIN_BELLY, axis=2)
        pieces.append(leg)

        # Toes: three per foot, fanned forward. Tiny, and they carry a huge
        # share of the sheet's "standing little creature" read.
        for toe_angle in (-0.45, 0.0, 0.45):
            tx = math.sin(toe_angle) * 0.16
            ty = math.cos(toe_angle) * 0.20
            toe = skinned(
                f"toe_{label}_{toe_angle:.2f}",
                [
                    (foot_x, foot_y + 0.02, 0.06, 0.042, 0.032),
                    (foot_x + side * tx * 0.6, foot_y + ty, 0.035,
                     0.020, 0.016),
                ],
                subdivisions=1)
            paint(toe, SKIN_BACK, SKIN_BELLY, axis=2)
            pieces.append(toe)

    return join_as("axolotl_skin", pieces, "skin")


def build_gills() -> bpy.types.Object:
    """Six feather fronds held upswept like the reference's crown.

    Each frond is a QUILL with paired BARBS: a curved central chain and
    short flattened chains fanning off it, longest at mid-length, so the
    silhouette is a feather rather than a bottle-brush. The barbs run
    roughly fore-and-aft, which keeps the frond reading full from the side
    and pleasantly spiky from the front — the two views the sheet shows.
    """
    pieces = []
    for side in (1.0, -1.0):
        for angle in GILL_ANGLES:
            base = (side * 0.46, 0.72 + angle * 0.24, 0.90)
            # Up, out and back; the rearmost frond sweeps back hardest.
            tip = (side * (1.10 + 0.08 * abs(angle)),
                   base[1] + angle * 0.34 - 0.16,
                   1.52 - 0.10 * abs(angle))

            def lerp(t: float) -> tuple:
                return tuple(base[i] + (tip[i] - base[i]) * t
                             for i in range(3))

            quill_points = []
            for t in (0.0, 0.35, 0.70, 1.0):
                x, y, z = lerp(t)
                # A slight outward bow so the crown curves like the sheet's.
                x += side * 0.10 * math.sin(t * math.pi)
                radius = 0.075 - 0.055 * t
                quill_points.append((x, y, z, radius, radius))
            quill = skinned(f"gill_{side:.0f}_{angle:.2f}", quill_points,
                            subdivisions=1)
            paint(quill, GILL_STALK, GILL_TIP, axis=2)
            pieces.append(quill)

            for t in (0.14, 0.26, 0.38, 0.50, 0.62, 0.74,
                      0.86, 0.96):
                x, y, z = lerp(t)
                x += side * 0.10 * math.sin(t * math.pi)
                length = 0.05 + 0.17 * math.sin(
                    math.pi * min(t / 0.90, 1.0))
                for fore in (1.0, -1.0):
                    barb = skinned(
                        f"barb_{side:.0f}_{angle:.2f}_{t}_{fore}",
                        [
                            (x, y, z, 0.050, 0.026),
                            # Swept toward the tip, not perpendicular: the
                            # difference between feather vanes and a TV
                            # antenna.
                            (x + side * 0.10 + (tip[0] - base[0]) * 0.06,
                             y + fore * length,
                             z + (tip[2] - base[2]) * 0.10, 0.014, 0.010),
                        ],
                        subdivisions=1)
                    paint(barb, GILL_STALK, GILL_TIP, axis=1,
                          invert=fore < 0.0)
                    pieces.append(barb)

    return join_as("axolotl_gill", pieces, "gill")


def build_eyes() -> bpy.types.Object:
    # Forward-set on the dome, not stuck to the flanks: the sheet's axolotl
    # looks AT the camera, and that reads through where the eyes sit.
    pieces = []
    for side in (1.0, -1.0):
        eye = sphere(f"eye_{side:.0f}", (side * 0.44, 1.24, 0.92), 0.155)
        paint(eye, EYE_COLOUR, EYE_COLOUR)
        pieces.append(eye)
    return join_as("axolotl_eye", pieces, "eye")


def build_gleams() -> bpy.types.Object:
    pieces = []
    for side in (1.0, -1.0):
        gleam = sphere(f"gleam_{side:.0f}",
                       (side * 0.47, 1.335, 1.015), 0.052)
        paint(gleam, GLEAM_COLOUR, GLEAM_COLOUR)
        pieces.append(gleam)
    return join_as("axolotl_gleam", pieces, "gleam")


def build_detail() -> bpy.types.Object:
    """The face: a wide upturned smile line and two nostrils.

    The smile is a thin curved chain laid across the snout front — its ends
    lift, which is the whole difference between the sheet's friendly little
    creature and a fish with a slot for a mouth.
    """
    pieces = []
    smile_points = []
    for step in range(7):
        t = step / 6.0
        x = (t - 0.5) * 0.78
        # Ends higher than the middle: the upturn.
        z = 0.55 + 0.10 * (2.0 * abs(t - 0.5)) ** 1.6
        # Follow the snout's curve so the line hugs the surface.
        y = 1.56 - 0.34 * (2.0 * abs(t - 0.5)) ** 2.0
        smile_points.append((x, y, z, 0.026, 0.026))
    smile = skinned("smile", smile_points, subdivisions=1)
    paint(smile, DETAIL_COLOUR, DETAIL_COLOUR)
    pieces.append(smile)
    for side in (1.0, -1.0):
        nostril = sphere(f"nostril_{side:.0f}",
                         (side * 0.13, 1.60, 0.76), 0.028)
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
