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
SKIN_BACK = (0.93, 0.72, 0.74, 1.0)
SKIN_BELLY = (0.99, 0.88, 0.87, 1.0)
SKIN_BLUSH = (0.93, 0.55, 0.58, 1.0)
# Coral rather than magenta. The gill material adds a strong backlight and
# rim on top of these, so a vertex colour saturated enough to look right in
# Blender renders hot in engine. The mean green over the mesh still has to
# stay under hero_skin.GILL_MAX_GREEN (0.5) for the colour-only fallback.
GILL_STALK = (0.84, 0.32, 0.35, 1.0)
GILL_TIP = (0.96, 0.52, 0.54, 1.0)
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
    (0.60, 0.575, 0.352, 0.318),   # neck, where the gill arches sit
    (0.92, 0.572, 0.510, 0.278),   # skull: the ratio inverts, broad and flat
    (1.24, 0.566, 0.552, 0.256),   # widest across the cheeks
    (1.52, 0.556, 0.487, 0.218),   # the width is HELD, not tapered away
    (1.66, 0.545, 0.318, 0.168),
    (1.74, 0.540, 0.120, 0.095),   # a short rounded cap, not a point
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
    (0.00, 0.895, 0.016, 0.022),   # a ridge you can barely see, mid-back
    (-0.55, 0.845, 0.019, 0.040),
    (-1.10, 0.760, 0.022, 0.090),
    (-1.65, 0.700, 0.022, 0.140),  # the crest, over the tail base
    (-2.20, 0.610, 0.019, 0.135),
    (-2.65, 0.480, 0.014, 0.085),
    (-2.93, 0.345, 0.008, 0.026),
]
VENTRAL_FIN = [
    (-1.30, 0.153, 0.012, 0.055),
    (-1.75, 0.120, 0.013, 0.085),
    (-2.20, 0.132, 0.013, 0.085),
    (-2.60, 0.197, 0.011, 0.055),
    (-2.90, 0.258, 0.007, 0.022),
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

# Three gill rami a side, as (yaw, rise, length scale). The fan opens in
# ELEVATION as well as plan: one ramus sweeps up and back, one straight out
# and back, one down and back. Three rami separated only by yaw -- which is
# what the first build had -- lie in a single horizontal plane, and a plane
# of filaments is a comb.
GILL_RAMI = [
    (0.16, 0.86, 0.90),
    (0.00, 0.16, 1.00),
    (-0.14, -0.52, 0.92),
]

# Filament stations along a ramus, and how many grow radially at each. The
# product is the plume's density; the radial placement is its volume.
GILL_STATIONS = 12
FILAMENTS_PER_STATION = 6

# How wide an arc, in radians, the filaments at a station cover. Centred on
# the direction pointing away from the body, so a 264-degree fan leaves the
# medial quadrant empty and no thread grows back into the neck.
GILL_ARC = 2.30


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
    pieces = [obj]

    for name, rows in (("dorsal_fin", DORSAL_FIN), ("ventral_fin", VENTRAL_FIN)):
        fin = skinned("%s" % name,
                      [(0.0, y, z, rx, rz) for y, z, rx, rz in rows],
                      subdivisions=2)
        # Pale at the root, blushed at the free edge. Running it the other
        # way lit the fin's top edge brighter than the back it grows out of,
        # which is the opposite of a thin membrane and made the blade pop
        # off the animal instead of belonging to it.
        paint(fin, SKIN_BELLY, SKIN_BLUSH, axis=2)
        pieces.append(fin)

    return join_as("axolotl_skin", pieces, "skin")


def build_gills() -> bpy.types.Object:
    """Three rami a side, each wearing a radial sleeve of fine filaments.

    A PLUME HAS VOLUME. The previous build put two opposed rows of filaments
    on each ramus and fanned the three rami by yaw alone, which left every
    thread on the animal in one horizontal plane: from above it was a comb,
    from the side a blade, and no amount of finer threads fixes a shape that
    is flat. Here the fan opens in elevation too, and each station grows
    filaments around a 264-degree arc of the stalk, turned away from the
    neck so nothing grows back into the flesh.

    The rami are also SHORT -- half a unit against the old five-sixths, which
    reached past the shoulders. On the animal the stalk is barely longer than
    the head is wide; the mass is filaments, not stalk.

    Filaments are longest around the middle of a ramus and shorten toward
    both ends, and each curls back and down under its own weight, so the mass
    has a silhouette instead of a fringe.
    """
    from mathutils import Vector

    bm = bmesh.new()
    for side in (1.0, -1.0):
        for yaw, rise, scale in GILL_RAMI:
            # The rami leave the flank of the neck behind the jaw. Direction
            # carries the whole fan: outward always, back always, and up or
            # down by the ramus's rise.
            # Rooted right behind the skull and thrown OUT rather than back:
            # a 0.78-against-0.58 sweep laid the plumes along the shoulders
            # and over the front feet, which is where a gill never sits.
            base = Vector((side * 0.34, 0.84, 0.70))
            direction = Vector((side * 0.88, -0.50 + yaw, rise * 0.60))
            direction.normalize()
            span = 0.46 * scale
            tip = base + direction * span

            # A frame perpendicular to the ramus whose first axis points
            # away from the body. Centring the filament arc on it is what
            # keeps the medial quadrant clear.
            lateral = Vector((side, 0.0, 0.0))
            outward = lateral - direction * lateral.dot(direction)
            if outward.length < 1e-4:
                outward = Vector((0.0, 0.0, 1.0))
            outward.normalize()
            binormal = direction.cross(outward)
            binormal.normalize()

            def along(t: float, _b=base, _t=tip, _o=outward,
                      _s=span) -> Vector:
                # A shallow bow, so the stalk arcs out of the neck rather
                # than leaving it as a straight spike.
                return _b.lerp(_t, t) + _o * (0.09 * _s * math.sin(t * math.pi))

            stalk = [along(t) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
            tube(bm, [tuple(p) for p in stalk],
                 [0.052, 0.044, 0.034, 0.024, 0.012], radial=6)

            for station in range(GILL_STATIONS):
                t = 0.26 + 0.70 * station / max(GILL_STATIONS - 1, 1)
                root = along(t)
                # Longest around the middle, tapering to both ends.
                profile = math.sin(math.pi * min(max((t - 0.10) / 0.95, 0.0), 1.0))
                # Rolling each station's arc keeps consecutive rings from
                # lining up into ridges. Deterministic in the index, so the
                # animal is identical every build while no two threads match.
                phase = ((station * 5 + 2) % 7) / 7.0 - 0.5

                for slot in range(FILAMENTS_PER_STATION):
                    fraction = slot / max(FILAMENTS_PER_STATION - 1, 1) - 0.5
                    theta = fraction * GILL_ARC + phase * 0.44
                    wobble = 0.82 + 0.34 * (
                        ((station * 7 + slot * 3) % 11) / 10.0)
                    length = (0.085 + 0.140 * profile) * scale * wobble
                    grow = outward * math.cos(theta) + binormal * math.sin(theta)

                    points, radii = [], []
                    for segment in range(4):
                        u = segment / 3.0
                        # Three things a real filament does: reach out of its
                        # stalk, trail back along the animal, and droop under
                        # its own weight. The last two are quadratic in u, so
                        # the thread curls instead of kinking at the root.
                        offset = (grow * (length * math.sin(u * 1.45))
                                  + Vector((0.0, -0.62 * length * u * u,
                                            -0.46 * length * u * u)))
                        points.append(tuple(root + offset))
                        radii.append(0.0135 * (1.0 - u) + 0.0030)
                    tube(bm, points, radii, radial=4)

    mesh = bpy.data.meshes.new("gill")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("gill", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()
    paint(obj, GILL_STALK, GILL_TIP, axis=2)
    return join_as("axolotl_gill", [obj], "gill")


def build_eyes() -> bpy.types.Object:
    """Small, lidless and dorso-lateral -- an amphibian's eye.

    Radius 0.062 against a skull half-height of 0.256, set out at 0.355
    on a 0.552 half-width so it rides the upper edge of the wedge. The old 0.155 made
    the eye a third of the head, which is the single loudest reason the face
    read as a cartoon rather than an animal.
    """
    pieces = []
    for side in (1.0, -1.0):
        eye = sphere(f"eye_{side:.0f}", (side * 0.355, 1.215, 0.752), 0.062)
        paint(eye, EYE_COLOUR, EYE_COLOUR)
        pieces.append(eye)
    return join_as("axolotl_eye", pieces, "eye")


def build_gleams() -> bpy.types.Object:
    """A specular pinpoint, not a cartoon catchlight.

    Kept as geometry rather than left to the material because a highlight
    the environment happens not to supply is a dead eye; kept TINY (0.016
    against the old 0.052) because a wet eye glints, it does not wear a
    white dot.
    """
    pieces = []
    for side in (1.0, -1.0):
        gleam = sphere(f"gleam_{side:.0f}",
                       (side * 0.372, 1.236, 0.791), 0.016)
        paint(gleam, GLEAM_COLOUR, GLEAM_COLOUR)
        pieces.append(gleam)
    return join_as("axolotl_gleam", pieces, "gleam")


def build_detail() -> bpy.types.Object:
    """The mouth line and nostrils.

    A real axolotl's mouth is a WIDE, nearly straight seam that follows the
    front of the broad skull and lifts only slightly at its corners. The
    previous build lifted the ends hard and called it a smile, which is a
    mascot's mouth; the animal's read comes from width, not from curve.
    """
    pieces = []
    seam = []
    for step in range(9):
        t = step / 8.0
        offset = 2.0 * abs(t - 0.5)
        x = (t - 0.5) * 0.94
        # Only a slight corner lift: enough to look alive, far short of a grin.
        z = 0.462 + 0.032 * offset ** 1.8
        # Follows the wedge of the skull so the seam hugs the surface.
        y = 1.640 - 0.42 * offset ** 1.9
        seam.append((x, y, z, 0.019, 0.014))
    mouth = skinned("mouth", seam, subdivisions=1)
    paint(mouth, DETAIL_COLOUR, DETAIL_COLOUR)
    pieces.append(mouth)

    for side in (1.0, -1.0):
        nostril = sphere(f"nostril_{side:.0f}",
                         (side * 0.098, 1.690, 0.596), 0.016)
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
