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

HOW THE ANATOMY IS BUILT, and why not primitives. The body is a SKIN
MODIFIER over an edge skeleton: vertices carrying a radius, which Blender
inflates into a continuous surface and Subdivision smooths.

ONE SKELETON, NOT SEVERAL — and this is the correction that matters most.
The earlier build made each leg and toe its OWN skinned object and then
called join(), which merely merges mesh data: it neither welds nor blends.
Four leg tubes INTERSECTED the body tube, and that is exactly why the limbs
read as stuck on. Body, head, all four legs and every toe are now branches
of a SINGLE edge skeleton passed to a single skin modifier, which blends at
branch points into continuous flesh. A limb now grows out of the flank the
way a limb does.

Fins stay separate on purpose: a fin IS a distinct membrane rising off the
back, so an overlapping thin blade is anatomically right where an
overlapping leg was anatomically wrong.

Three details that matter more than they look:

  * SKIN RADII ARE ELLIPTICAL (x, z), and the ratio INVERTS along the
    animal. The tail is laterally compressed (rx < rz) because it is a
    swimming blade; the skull is broad and flat (rx roughly twice rz)
    because an axolotl's head is a wide wedge. One round tube can be
    neither, and getting the inversion right is most of the silhouette.
  * THE EYES ARE SMALL. They were radius 0.155 against a skull half-height
    of 0.49 — a third of the head, which is a cartoon eye and was the single
    loudest reason the face did not read as an animal. A real axolotl eye is
    tiny, lidless and set dorso-laterally, and it is sized that way here.
  * THE GILLS ARE PLUMES, and a plume is three-dimensional. Filaments grow
    RADIALLY around each ramus, over an arc turned away from the neck — two
    opposed rows put every thread in one plane, which is what made the first
    build read as a flat comb from above and a blade from the side no matter
    how fine the threads were. They are built directly in bmesh rather than
    as one skinned object each, because three hundred separate skin
    modifiers is slow and buys nothing.

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
import bmesh  # type: ignore

# --- Palette ----------------------------------------------------------------
# Kept inside the thresholds tools/blender/refine_model.py and hero_skin.gd
# both classify by, so a model that lost its material names still resolves.
# WARM. The shared lighting rig's sky ambient is blue, so a vertex colour
# whose blue channel matches its green renders lavender rather than the
# reference sheet's warm pink -- the palette has to lean against the cast it
# will be lit under, not look right in isolation.
SKIN_BACK = (0.96, 0.66, 0.60, 1.0)
SKIN_BELLY = (0.99, 0.85, 0.78, 1.0)
SKIN_BLUSH = (0.93, 0.46, 0.43, 1.0)
# The tail and dorsal membranes. They wear the GILL material rather than the
# skin's, because the reference sheet's fins are translucent with the light
# behind them and that is what the gill material already does (subsurface
# scattering at 0.7 plus a backlight). Kept inside the gill role's own colour
# range so the combined mean green stays under GILL_MAX_GREEN.
FIN_BASE = (0.90, 0.46, 0.44, 1.0)
FIN_EDGE = (0.98, 0.63, 0.61, 1.0)
# Coral rather than magenta. The gill material adds a strong backlight and
# rim on top of these, so a vertex colour saturated enough to look right in
# Blender renders hot in engine. The mean green over the mesh still has to
# stay under hero_skin.GILL_MAX_GREEN (0.5) for the colour-only fallback.
GILL_STALK = (0.84, 0.30, 0.31, 1.0)
GILL_TIP = (0.96, 0.47, 0.46, 1.0)
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
# Measured against a real axolotl rather than a mascot: total length about
# five head-lengths, the skull a broad flat wedge, the tail a laterally
# compressed blade, and limbs that are SLENDER. Rows are (y, z, rx, rz)
# running tail tip to snout; head points +Y in Blender space, which the
# exporter's Y-up conversion turns into the -Z the game expects.
BODY = [
    (-2.95, 0.30, 0.022, 0.040),   # tail tip
    (-2.55, 0.32, 0.055, 0.115),   # the blade: rx < rz, laterally squashed
    (-2.15, 0.35, 0.090, 0.175),
    (-1.75, 0.39, 0.130, 0.225),
    (-1.35, 0.43, 0.180, 0.265),
    (-0.95, 0.47, 0.245, 0.300),   # tail base thickening into the hips
    (-0.55, 0.51, 0.310, 0.330),   # hips
    (-0.15, 0.54, 0.348, 0.345),   # belly, widest of the trunk
    (0.25, 0.56, 0.362, 0.348),    # chest
    (0.60, 0.578, 0.352, 0.330),   # neck, where the gill arches sit
    (0.92, 0.588, 0.478, 0.348),   # skull: still wider than tall, but DOMED
    (1.24, 0.586, 0.505, 0.362),   # widest across the cheeks
    (1.52, 0.572, 0.432, 0.292),   # the width is HELD, not tapered away
    (1.66, 0.556, 0.300, 0.196),
    (1.74, 0.546, 0.120, 0.104),   # a short rounded cap, not a point
]

# Body row indices the limbs branch from, so the flare sits over the chest
# and the hips rather than halfway along a segment.
FRONT_ROOT = 8
BACK_ROOT = 6

# The dorsal blade and the tail's upper and lower membranes. Separate thin
# surfaces, because a fin is a membrane rather than part of the body tube.
# Each row's z is chosen so the blade's BOTTOM sits about 4 cm below the
# back line at that station -- buried in the flesh rather than hovering over
# it. The first attempt floated a sail above the spine, which is what a fin
# looks like when its height is authored before its attachment.
#
# The CREST IS OVER THE TAIL. Sinking each row far enough not to hover was
# not sufficient: holding the top edge at a near-constant 0.94 from the
# shoulder to mid-body, while the back line fell away beneath it, drew a
# dead-straight ridge that read as a plank stuck on the spine. What the
# animal has is a fin barely proud of the trunk that swells into a swimming
# crest over the tail, so the numbers below are chosen for how far each row
# stands ABOVE the back at its station: 1cm, 4, 11, 20, 22, 13, 3.
DORSAL_FIN = [
    (-0.30, 0.870, 0.014, 0.022),  # a ridge you can barely see, mid-back
    (-0.90, 0.800, 0.017, 0.070),
    (-1.50, 0.720, 0.018, 0.130),
    (-2.05, 0.635, 0.017, 0.145),  # the crest, over the tail
    (-2.55, 0.515, 0.013, 0.105),
    (-2.95, 0.368, 0.007, 0.036),
]
# The lower lobe. Every row is placed so the membrane's BOTTOM stays above
# Z 0.02: the feet plant at 0.03, and a tail fin that dips below them drags
# through the floor on every frame the animal is grounded.
VENTRAL_FIN = [
    (-1.15, 0.188, 0.014, 0.046),
    (-1.65, 0.150, 0.016, 0.080),
    (-2.15, 0.145, 0.016, 0.086),
    (-2.60, 0.200, 0.012, 0.070),
    (-2.93, 0.305, 0.007, 0.032),
]

# (label, root row, side, splay, toe count). Front feet carry four toes and
# hind feet five, which is what an axolotl has and what a viewer who has
# ever looked one up will notice missing.
LEGS = [
    ("fl", FRONT_ROOT, 1.0, 0.12, 4),
    ("fr", FRONT_ROOT, -1.0, 0.12, 4),
    ("bl", BACK_ROOT, 1.0, -0.18, 5),
    ("br", BACK_ROOT, -1.0, -0.18, 5),
]

# Three gill rami a side, as (fore/aft yaw, rise, length scale), following
# the maintainer's reference sheet (reference/hero/01_hero_perspective.png):
# LONG BARE STALKS carrying a feathered blade on
# their outer half only, held up and clear of the head. The fan splays
# forward, out and back, so the three blades face three different ways and
# the plume has volume even though each blade is itself a flat feather --
# which is exactly how the reference is built, and why massing filaments
# radially around every stalk (the previous build) reads as a bottlebrush
# next to it.
GILL_RAMI = [
    (0.42, 0.56, 0.94),
    (0.06, 0.92, 1.00),
    (-0.54, 0.56, 0.92),
]
GILL_BASE = (0.32, 1.04, 0.63)
GILL_SPAN = 0.80

# Where the feather starts along the stalk. The bare lower half is most of
# what makes the reference read as gills rather than as a brush.
GILL_FEATHER_START = 0.42
FILAMENTS_PER_ROW = 18


def body_at(y: float) -> tuple:
    """The body's (centre z, half-width, half-height) at station `y`.

    Linear between the BODY rows. Anything that has to sit ON the animal --
    the mouth seam most of all -- has to be placed against the surface rather
    than at coordinates typed by eye: the seam whose corners were authored at
    a flat z sank INSIDE the skull as soon as the skull was domed, and a
    mouth buried in the head renders as no mouth at all.
    """
    rows = sorted(BODY, key=lambda row: row[0])
    if y <= rows[0][0]:
        return rows[0][1], rows[0][2], rows[0][3]
    if y >= rows[-1][0]:
        return rows[-1][1], rows[-1][2], rows[-1][3]
    for lower, upper in zip(rows, rows[1:]):
        if lower[0] <= y <= upper[0]:
            span = (upper[0] - lower[0]) or 1.0
            t = (y - lower[0]) / span
            return tuple(lower[i] + (upper[i] - lower[i]) * t
                         for i in (1, 2, 3))
    return rows[-1][1], rows[-1][2], rows[-1][3]


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


class Skeleton:
    """An edge skeleton being assembled for ONE skin modifier.

    The whole point of this class is that limbs are BRANCHES rather than
    separate objects: `chain(rows, parent=index)` edges its first row to an
    existing vertex, and the skin modifier then blends the two into
    continuous flesh. Building each limb separately and joining afterwards
    is what made the old model read as tubes pushed into a body.
    """

    def __init__(self) -> None:
        self.points: list = []
        self.edges: list = []

    def chain(self, rows: list, parent: int | None = None) -> list:
        """Appends a run of (x, y, z, rx, rz), edged end to end, and edged to
        `parent` when given. Returns the new indices."""
        indices = []
        previous = parent
        for row in rows:
            index = len(self.points)
            self.points.append(row)
            if previous is not None:
                self.edges.append((previous, index))
            indices.append(index)
            previous = index
        return indices


def skinned_skeleton(name: str, skeleton: Skeleton,
                     subdivisions: int = 2) -> bpy.types.Object:
    """One skin modifier over a whole branching skeleton, then a relax pass.

    The Smooth modifier afterwards is not cosmetic: the skin modifier builds
    a hull at every branch, and those hulls pinch where a slender limb meets
    a broad flank. A few low-factor relax iterations settle the join into
    the shoulder it should be.
    """
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([(p[0], p[1], p[2]) for p in skeleton.points],
                     skeleton.edges, [])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj

    skin = obj.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = True
    layer = obj.data.skin_vertices[0].data
    for index, point in enumerate(skeleton.points):
        layer[index].radius = (point[3], point[4])
    layer[0].use_root = True

    subsurf = obj.modifiers.new("Subsurf", "SUBSURF")
    subsurf.levels = subdivisions
    subsurf.render_levels = subdivisions

    relax = obj.modifiers.new("Relax", "SMOOTH")
    relax.factor = 0.55
    relax.iterations = 4

    bpy.ops.object.modifier_apply(modifier="Skin")
    bpy.ops.object.modifier_apply(modifier="Subsurf")
    bpy.ops.object.modifier_apply(modifier="Relax")
    return obj


def tube(bm, points: list, radii: list, radial: int = 5) -> None:
    """A tapered tube through `points`, one radius per point, into `bm`.

    Built directly in bmesh because the gills need a hundred and thirty of
    these: a skin modifier per filament is correct and far too slow, and a
    filament needs no branching to justify one.

    The ring frame is derived from the local direction rather than a fixed
    axis, so a curved filament does not shear as it bends.
    """
    from mathutils import Vector

    rings = []
    for index, (point, radius) in enumerate(zip(points, radii)):
        here = Vector(point)
        if index == 0:
            direction = Vector(points[1]) - here
        elif index == len(points) - 1:
            direction = here - Vector(points[-2])
        else:
            direction = Vector(points[index + 1]) - Vector(points[index - 1])
        direction.normalize()
        # Any reference axis not parallel to the direction gives a stable
        # frame; the swap avoids the degenerate case near vertical.
        reference = Vector((0.0, 0.0, 1.0))
        if abs(direction.z) > 0.9:
            reference = Vector((1.0, 0.0, 0.0))
        across = direction.cross(reference)
        across.normalize()
        upward = across.cross(direction)
        upward.normalize()

        ring = []
        for step in range(radial):
            angle = math.tau * step / radial
            offset = across * (math.cos(angle) * radius) \
                + upward * (math.sin(angle) * radius)
            ring.append(bm.verts.new(here + offset))
        rings.append(ring)

    for index in range(len(rings) - 1):
        for step in range(radial):
            following = (step + 1) % radial
            bm.faces.new([rings[index][step], rings[index][following],
                          rings[index + 1][following], rings[index + 1][step]])
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])


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

    Deterministic noise from the vertex position itself, so the same run
    always paints the same animal. The reference sheet's marks are DISCRETE
    round blotches over the head and back rather than a soft wash, so the
    threshold is high and the ramp steep: a gentle blend spread the colour
    into a smear that just read as dirty skin.
    """
    mesh = obj.data
    layer = mesh.color_attributes.get("Col")
    if layer is None:
        return
    for loop_index, loop in enumerate(mesh.loops):
        p = mesh.vertices[loop.vertex_index].co
        wave = (math.sin(p.x * 5.1 + 1.7) * math.sin(p.y * 3.4 + 0.4)
                * math.sin(p.z * 4.3 + 2.9))
        if wave <= 0.22 or p.z < 0.54:
            continue  # belly stays clean, as counter-shading wants
        blend = min((wave - 0.22) * 2.6, 0.95)
        colour = layer.data[loop_index].color
        layer.data[loop_index].color = tuple(
            colour[i] + (SKIN_BLUSH[i] - colour[i]) * blend for i in range(4))


def build_skin() -> bpy.types.Object:
    """Body, head, four legs and every toe as ONE branching skeleton, plus
    the fin membranes as separate blades."""
    skeleton = Skeleton()
    body = skeleton.chain([(0.0, y, z, rx, rz) for y, z, rx, rz in BODY])

    for label, root_row, side, splay, toes in LEGS:
        root_y = BODY[root_row][0]
        # Slender: an axolotl's limbs are thin, and the old 0.170 shoulder
        # was a sausage. They branch FROM the body row, so the skin modifier
        # flares the join into a shoulder instead of intersecting the flank.
        foot_x = side * 0.74
        foot_y = root_y + splay
        leg = skeleton.chain([
            (side * 0.30, root_y + splay * 0.15, 0.44, 0.105, 0.105),
            (side * 0.52, root_y + splay * 0.55, 0.29, 0.078, 0.078),
            (side * 0.66, root_y + splay * 0.85, 0.14, 0.058, 0.058),
            (foot_x, foot_y, 0.052, 0.070, 0.034),
        ], parent=body[root_row])

        # Toes fan forward off the foot. Four in front, five behind.
        for toe in range(toes):
            spread = (toe / max(toes - 1, 1) - 0.5) * 1.05
            skeleton.chain([
                (foot_x + side * math.sin(spread) * 0.09,
                 foot_y + math.cos(spread) * 0.12,
                 0.044, 0.030, 0.022),
                (foot_x + side * math.sin(spread) * 0.17,
                 foot_y + math.cos(spread) * 0.23,
                 0.038, 0.016, 0.013),
            ], parent=leg[-1])

    obj = skinned_skeleton("body", skeleton)
    # Counter-shading: a pale belly under a deeper back is what stops any
    # single-colour creature reading as a toy.
    paint(obj, SKIN_BELLY, SKIN_BACK, axis=2)
    mottle(obj)
    return join_as("axolotl_skin", [obj], "skin")


def build_fins() -> list:
    """The dorsal and ventral tail membranes, as GILL-role pieces.

    They used to be joined into the skin, which made them opaque slabs the
    same colour as the back. The reference sheet's tail is a broad
    TRANSLUCENT fin with the light coming through it, and the gill material
    already does exactly that -- subsurface scattering at 0.7 plus a
    backlight -- so the membranes belong to that role rather than to skin.
    Their colours stay inside the gill range so the combined mean green of
    the gill object keeps classifying under GILL_MAX_GREEN for a model that
    ships without material names.
    """
    fins = []
    for name, rows in (("dorsal_fin", DORSAL_FIN), ("ventral_fin", VENTRAL_FIN)):
        fin = skinned(name, [(0.0, y, z, rx, rz) for y, z, rx, rz in rows],
                      subdivisions=2)
        # Deeper coral at the root, paler at the free edge, which is the way
        # a thin membrane actually thins out.
        paint(fin, FIN_BASE, FIN_EDGE, axis=2)
        fins.append(fin)
    return fins


def build_gills() -> bpy.types.Object:
    """Three feathered rami a side, plus the tail membranes.

    THE REFERENCE SHEET IS A FEATHER, NOT A BOTTLEBRUSH. Each ramus is a long
    bare stalk carrying filaments only on its outer half, and those filaments
    lie in ONE plane per ramus -- a feather. What gives the plume its volume
    is that the three stalks point three different ways: forward-and-up,
    out-and-up, back-and-up, so the three blades face three different
    directions. Massing filaments radially around every stalk (the build this
    supersedes) produces more geometry and reads as a brush beside it.

    The bare inner half matters as much as the feathered outer one: it is
    what holds the plume clear of the head instead of packing it against the
    neck, and it is the first thing the eye uses to read these as gills.

    Filaments are longest through the middle of the blade and shorten to both
    of its ends, and each sweeps toward the stalk's tip as it grows, so the
    blade has a leaf's outline rather than a rectangle's.
    """
    from mathutils import Vector

    bm = bmesh.new()
    for side in (1.0, -1.0):
        for yaw, rise, scale in GILL_RAMI:
            base = Vector((side * GILL_BASE[0], GILL_BASE[1], GILL_BASE[2]))
            direction = Vector((side * 0.70, yaw, rise))
            direction.normalize()
            span = GILL_SPAN * scale
            tip = base + direction * span

            # A frame perpendicular to the stalk. `outward` points away from
            # the body; `row_axis` is what the feather spreads along, and
            # because it is derived from the stalk's own direction it turns
            # with the fan -- which is the whole reason three flat blades
            # make a three-dimensional plume.
            lateral = Vector((side, 0.0, 0.0))
            outward = lateral - direction * lateral.dot(direction)
            if outward.length < 1e-4:
                outward = Vector((0.0, 0.0, 1.0))
            outward.normalize()
            row_axis = direction.cross(outward)
            row_axis.normalize()

            def along(t: float, _b=base, _t=tip, _o=outward,
                      _s=span) -> Vector:
                # A shallow bow, so the stalk arcs out of the neck rather
                # than leaving it as a straight spike.
                return _b.lerp(_t, t) + _o * (0.07 * _s * math.sin(t * math.pi))

            stalk = [along(t) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
            tube(bm, [tuple(p) for p in stalk],
                 [0.058, 0.050, 0.042, 0.030, 0.016], radial=6)

            for step in range(FILAMENTS_PER_ROW):
                blade = step / max(FILAMENTS_PER_ROW - 1, 1)
                t = GILL_FEATHER_START + (0.99 - GILL_FEATHER_START) * blade
                root = along(t)
                # Full through the middle of the blade and soft at both ends;
                # the fractional power keeps the outline a leaf rather than
                # the lens a plain sine would draw.
                profile = math.sin(math.pi * blade) ** 0.6
                # Deterministic in the index, so the animal is identical every
                # build while no two filaments match.
                wobble = 0.84 + 0.30 * (((step * 7 + 3) % 11) / 10.0)
                length = (0.044 + 0.132 * profile) * scale * wobble

                for row in (1.0, -1.0):
                    points, radii = [], []
                    for segment in range(4):
                        u = segment / 3.0
                        # Out along the blade, swept toward the stalk's tip,
                        # and lifted a little out of the feather's plane so
                        # the blade is a soft surface rather than a card.
                        offset = (row_axis * (row * length
                                              * math.sin(u * 1.50))
                                  + direction * (0.42 * length * u * u)
                                  + outward * (row * 0.16 * length * u * u))
                        points.append(tuple(root + offset))
                        radii.append(0.0130 * (1.0 - u) + 0.0030)
                    tube(bm, points, radii, radial=4)

    mesh = bpy.data.meshes.new("gill")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("gill", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()
    paint(obj, GILL_STALK, GILL_TIP, axis=2)
    return join_as("axolotl_gill", [obj] + build_fins(), "gill")


def build_eyes() -> bpy.types.Object:
    """Large, round and glossy -- the reference sheet's eye.

    The maintainer's reference (reference/hero/01_hero_perspective.png)
    carries a big dark eye with a bright catchlight,
    and it was chosen over the small lidless amphibian eye an earlier build
    used. Radius 0.135 against a 0.505 skull half-width, set forward on the
    dome where the reference puts it rather than back on the flank.
    """
    pieces = []
    for side in (1.0, -1.0):
        eye = sphere(f"eye_{side:.0f}", (side * 0.335, 1.340, 0.720), 0.135)
        paint(eye, EYE_COLOUR, EYE_COLOUR)
        pieces.append(eye)
    return join_as("axolotl_eye", pieces, "eye")


def build_gleams() -> bpy.types.Object:
    """A specular pinpoint, not a cartoon catchlight.

    Kept as geometry rather than left to the material because a highlight
    the environment happens not to supply is a dead eye. Sized to the eye it
    rides on -- 0.030 against a 0.135 pupil, the proportion the reference
    sheet's catchlight has.
    """
    pieces = []
    for side in (1.0, -1.0):
        gleam = sphere(f"gleam_{side:.0f}",
                       (side * 0.372, 1.398, 0.805), 0.030)
        paint(gleam, GLEAM_COLOUR, GLEAM_COLOUR)
        pieces.append(gleam)
    return join_as("axolotl_gleam", pieces, "gleam")


def build_detail() -> bpy.types.Object:
    """The mouth line and nostrils.

    A wide seam following the front of the skull, lifting at the corners
    into the soft smile the reference sheet has. Width still does most of the
    work -- a narrow mouth curved hard is a mascot's -- but the reference is
    plainly smiling, and a dead-straight seam under those eyes reads glum.
    """
    pieces = []
    seam = []
    for step in range(11):
        t = step / 10.0
        offset = 2.0 * abs(t - 0.5)
        # Each point is placed against the skull's OWN cross-section at its
        # station, on a latitude below the equator: that is what keeps the
        # seam on the surface as the head's proportions change.
        y = 1.700 - 0.42 * offset ** 1.6
        centre, half_width, half_height = body_at(y)
        # The corners ride higher than the middle, which is the reference's
        # soft smile once the line is wrapped around a muzzle.
        drop = 0.55 - 0.22 * offset ** 2
        z = centre - drop * half_height
        # Half-width of the cross-section AT that latitude, pushed a hair
        # proud so the seam reads as a groove rather than vanishing.
        lateral = half_width * math.sqrt(max(1.0 - drop * drop, 0.0))
        x = (1.0 if t > 0.5 else -1.0) * offset * lateral * 1.015
        seam.append((x, y, z, 0.024, 0.017))
    mouth = skinned("mouth", seam, subdivisions=1)
    paint(mouth, DETAIL_COLOUR, DETAIL_COLOUR)
    pieces.append(mouth)

    for side in (1.0, -1.0):
        nostril = sphere(f"nostril_{side:.0f}",
                         (side * 0.108, 1.700, 0.612), 0.018)
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
