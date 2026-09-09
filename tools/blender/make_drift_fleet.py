"""Generate the Drift Fleet prop set — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/make_drift_fleet.py -- \
        --output-root assets/prop [--seed 11]

The antagonists' bodies, one per roster unit in core/enemies/roster, named
to match so a placed node and its declaration are obviously the same thing.

THE DESIGN RULE IS THE VISION'S, NOT AN AESTHETIC WHIM: the Drift Fleet is
"faceless industrial extraction machinery, deliberately never human
characters ... nets, hooks, dredges and pollution, with no gore and no
humanized violence". So every unit here is built from machine primitives —
boxes, drums, masts, nozzles — and NONE of them has a face, an eye, a limb
or anything that could read as a creature in pain. A child should see a
digger, not a monster.

TWO THINGS SEPARATE THEM FROM THE REEF, both deliberate:

  * PALETTE. Cold oxidised iron against the environment kit's warm coral
    and sea-green, with a single amber warning accent. Machine signage, not
    decoration: it is the only saturated colour on the units, so the eye
    reads "hazard" before it reads the silhouette.
  * SHADING. The reef kit is shade-smooth throughout because it is grown.
    These are left FLAT-shaded, so every facet catches the light as a hard
    plane. Manufactured things have edges; that contrast does more work
    than any amount of extra geometry.

Same contract as the environment kit: one glb per asset directory, vertex
colour carries the palette, provenance sidecars are the caller's to write,
and the whole set is a few thousand triangles because these are seen many
at a time.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import random
import sys

import bpy  # type: ignore

# Cold machine palette. Deliberately desaturated and DARKER than both the
# reef and the hero: the axolotl must stay the brightest thing on screen.
HULL_DEEP = (0.13, 0.15, 0.18, 1.0)
HULL_LIGHT = (0.34, 0.37, 0.41, 1.0)
RUST_DARK = (0.26, 0.15, 0.10, 1.0)
RUST_LIGHT = (0.46, 0.26, 0.15, 1.0)
# The one saturated colour on any unit. Signage, used sparingly.
WARNING = (0.86, 0.55, 0.10, 1.0)


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def fleet_material() -> bpy.types.Material:
    """One shared material whose base colour is the mesh's vertex colour.

    Exported WITH the glb so Godot's importer sees a material next to a
    COLOR_0 attribute and enables vertex-colour albedo — a glb with no
    material at all imports as plain white and the whole palette is lost.
    Rougher than the reef kit: worked metal, not wet stone.
    """
    material = bpy.data.materials.get("drift_fleet")
    if material is not None:
        return material
    material = bpy.data.materials.new("drift_fleet")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Roughness"].default_value = 0.85
        principled.inputs["Metallic"].default_value = 0.4
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
    """One colour over the whole mesh — the accent parts."""
    paint(obj, colour, colour)


def join(pieces: list) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(rotation=True, location=True, scale=True)
    return obj


def box(location, scale) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.active_object
    obj.scale = scale
    return obj


def drum(location, radius: float, depth: float,
         rotation=(0.0, 0.0, 0.0), vertices: int = 12) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location,
        rotation=rotation)
    return bpy.context.active_object


def make_dredger(rng: random.Random) -> bpy.types.Object:
    """The heavy one: a barge hull over a toothed cutting drum.

    This is the unit that flattens restored reef, so it reads as earth-moving
    machinery — the silhouette is all hull and drum, no reaching parts.
    """
    hull = box((0.0, 0.0, 0.62), (1.5, 0.95, 0.45))
    paint(hull, HULL_DEEP, HULL_LIGHT)
    pieces = [hull]

    cab = box((0.42, 0.0, 0.98), (0.45, 0.5, 0.3))
    paint(cab, HULL_LIGHT, HULL_LIGHT)
    pieces.append(cab)

    cutter = drum((-0.78, 0.0, 0.34), 0.34, 0.9,
                  rotation=(0.0, math.pi / 2, 0.0))
    paint(cutter, RUST_DARK, RUST_LIGHT, axis=0)
    pieces.append(cutter)

    # Teeth around the drum: the working edge, and the only aggressive read
    # the unit gets.
    for index in range(8):
        angle = index * math.tau / 8 + rng.uniform(-0.05, 0.05)
        tooth = box(
            (-0.78 + math.cos(angle) * 0.36, 0.0,
             0.34 + math.sin(angle) * 0.36),
            (0.1, 0.82, 0.16))
        tooth.rotation_euler = (0.0, -angle, 0.0)
        paint_flat(tooth, RUST_LIGHT)
        pieces.append(tooth)

    stripe = box((0.42, 0.0, 1.16), (0.46, 0.52, 0.06))
    paint_flat(stripe, WARNING)
    pieces.append(stripe)

    obj = join(pieces)
    obj.name = "dredger"
    return obj


def make_netbot(rng: random.Random) -> bpy.types.Object:
    """The entangler: a squat body with four splayed casting arms."""
    body = box((0.0, 0.0, 0.5), (0.62, 0.62, 0.5))
    paint(body, HULL_DEEP, HULL_LIGHT)
    pieces = [body]

    for index in range(4):
        angle = index * math.tau / 4 + math.pi / 4
        reach = 0.62 + rng.uniform(0.0, 0.08)
        arm = box(
            (math.cos(angle) * reach, math.sin(angle) * reach, 0.66),
            (0.62, 0.09, 0.09))
        arm.rotation_euler = (0.0, -0.32, angle)
        paint(arm, HULL_LIGHT, RUST_DARK, axis=0)
        pieces.append(arm)

    # The net itself, as a thin plate slung under the arms: readable from
    # above, and cheap.
    net = box((0.0, 0.0, 0.2), (1.5, 1.5, 0.03))
    paint_flat(net, RUST_DARK)
    pieces.append(net)

    lamp = box((0.0, 0.0, 1.06), (0.2, 0.2, 0.1))
    paint_flat(lamp, WARNING)
    pieces.append(lamp)

    obj = join(pieces)
    obj.name = "netbot"
    return obj


def make_hookline_rig(rng: random.Random) -> bpy.types.Object:
    """The snagger: a mast and crossbar with hooks hanging on a line.

    Tall and thin on purpose — the Glow affordance reveals the LINE before
    it triggers, so the silhouette has to be legible at distance.
    """
    base = box((0.0, 0.0, 0.14), (0.7, 0.7, 0.28))
    paint(base, HULL_DEEP, HULL_LIGHT)
    pieces = [base]

    mast = drum((0.0, 0.0, 1.15), 0.09, 2.0)
    paint(mast, HULL_LIGHT, HULL_DEEP)
    pieces.append(mast)

    arm = box((0.0, 0.0, 2.05), (1.7, 0.12, 0.12))
    paint(arm, HULL_LIGHT, HULL_LIGHT)
    pieces.append(arm)

    for index in range(3):
        x = -0.62 + index * 0.62
        drop = 0.5 + rng.uniform(0.0, 0.3)
        line = drum((x, 0.0, 2.05 - drop / 2), 0.02, drop)
        paint_flat(line, HULL_DEEP)
        pieces.append(line)
        # The barb: a short angled bar, never a point aimed at the player.
        hook = box((x, 0.0, 2.05 - drop), (0.1, 0.28, 0.06))
        hook.rotation_euler = (0.6, 0.0, 0.0)
        paint_flat(hook, RUST_LIGHT)
        pieces.append(hook)

    beacon = box((0.0, 0.0, 2.2), (0.16, 0.16, 0.14))
    paint_flat(beacon, WARNING)
    pieces.append(beacon)

    obj = join(pieces)
    obj.name = "hookline_rig"
    return obj


def make_runoff_drone(rng: random.Random) -> bpy.types.Object:
    """The polluter: a pressurised canister venting through nozzles.

    Its effect is a VOLUME the player swims through, so the body sits high
    and the nozzles point down and outward — the shape suggests the aura's
    extent before the player learns it.
    """
    tank = drum((0.0, 0.0, 0.85), 0.38, 0.9, vertices=10)
    paint(tank, HULL_DEEP, HULL_LIGHT)
    pieces = [tank]

    collar = drum((0.0, 0.0, 1.32), 0.44, 0.12, vertices=10)
    paint_flat(collar, RUST_DARK)
    pieces.append(collar)

    for index in range(5):
        angle = index * math.tau / 5 + rng.uniform(-0.08, 0.08)
        nozzle = drum(
            (math.cos(angle) * 0.44, math.sin(angle) * 0.44, 0.5),
            0.09, 0.42, rotation=(0.55, 0.0, angle), vertices=6)
        paint(nozzle, RUST_DARK, RUST_LIGHT)
        pieces.append(nozzle)

    band = drum((0.0, 0.0, 0.62), 0.4, 0.1, vertices=10)
    paint_flat(band, WARNING)
    pieces.append(band)

    obj = join(pieces)
    obj.name = "runoff_drone"
    return obj

def make_flagship(rng: random.Random) -> bpy.types.Object:
    """The Flagship: the source vessel the whole fleet is launched from.

    THE ONLY UNIT BUILT TO BE STOOD ON. Every other machine here is an
    obstacle a metre or two across; this one is a place — the player swims
    under its intakes, climbs onto its deck, and fights across it. So it is
    modelled at LEVEL scale rather than prop scale (about twenty-two metres
    long) and its deck is a real flat surface at a known height, because
    collision geometry in the scene has to agree with it.

    THREE READS, ONE PER PHASE, so the fight is legible before it is
    explained. Below the waterline, four intake mouths — the part you breach.
    Above it, a long open deck with derrick masts — the part you assault. At
    the stern, a raised core housing behind shutters — the part you purge.
    A player who has never seen this should be able to point at where the
    fight is going next.

    STILL FACELESS. Bigger is the temptation to add a bridge, windows, a
    crew. There are none: no glass, no cabin you could imagine someone
    inside, nothing that reads as occupied. It is a machine that arrived on
    its own and it is emptier than the small ones, not more populated.
    """
    pieces = []

    # The hull: a long barge, widest amidships. Built as three blocks rather
    # than one so the silhouette has a bow and a stern from a distance.
    for offset, half_len, half_wide, half_tall in (
            (-8.4, 2.6, 2.4, 1.5), (0.0, 6.2, 3.4, 1.8), (7.8, 3.0, 2.8, 1.6)):
        block = box((offset, 0.0, half_tall), (half_len * 2, half_wide * 2,
                                               half_tall * 2))
        paint(block, HULL_DEEP, HULL_LIGHT)
        pieces.append(block)

    # PHASE ONE, below the waterline: four intake mouths along the port and
    # starboard flanks. Drums on their sides, so they read as openings that
    # draw water in rather than as decoration bolted on.
    for side in (-1, 1):
        for along in (-3.4, 2.2):
            mouth = drum((along, side * 3.3, 0.7), 0.85, 0.7,
                         rotation=(math.pi / 2, 0.0, 0.0))
            paint(mouth, RUST_DARK, RUST_LIGHT, axis=1)
            pieces.append(mouth)
            rim = drum((along, side * 3.62, 0.7), 0.95, 0.14,
                       rotation=(math.pi / 2, 0.0, 0.0))
            paint_flat(rim, WARNING)
            pieces.append(rim)

    # PHASE TWO, the deck: flat, open, and long enough to fight across. Kept
    # deliberately clear of clutter — the fight needs the floor.
    deck = box((0.0, 0.0, 3.72), (17.5, 6.4, 0.24))
    paint(deck, HULL_LIGHT, HULL_LIGHT)
    pieces.append(deck)

    for along in (-6.0, -1.0, 4.0):
        for side in (-1, 1):
            rail = box((along, side * 3.1, 4.12), (1.4, 0.18, 0.8))
            paint_flat(rail, HULL_DEEP)
            pieces.append(rail)

    # Derricks: the fleet's launch gantries, and the reason the deck reads as
    # industrial rather than as a raft. Leaned slightly outboard, which is
    # what stops three identical masts looking like a fence.
    for index, along in enumerate((-5.2, 0.6, 5.4)):
        lean = rng.uniform(-0.09, 0.09)
        mast = box((along, 0.0, 5.6), (0.5, 0.5, 3.6))
        mast.rotation_euler = (lean, 0.0, 0.0)
        paint(mast, HULL_DEEP, HULL_LIGHT)
        pieces.append(mast)
        arm = box((along, 1.9 * (1 if index % 2 == 0 else -1), 7.1),
                  (0.34, 3.4, 0.34))
        paint_flat(arm, RUST_LIGHT)
        pieces.append(arm)

    # PHASE THREE, the stern: the core housing, shuttered. The shutters are
    # the affordance gate's read — they are what the Bubble platform opens.
    housing = drum((8.6, 0.0, 5.0), 2.1, 2.6)
    paint(housing, HULL_DEEP, HULL_LIGHT)
    pieces.append(housing)
    for index in range(6):
        angle = index * math.tau / 6
        shutter = box((8.6 + math.cos(angle) * 2.0,
                       math.sin(angle) * 2.0, 5.0), (0.5, 0.5, 2.2))
        shutter.rotation_euler = (0.0, 0.0, -angle)
        paint_flat(shutter, RUST_DARK)
        pieces.append(shutter)
    lamp = drum((8.6, 0.0, 6.5), 1.5, 0.4)
    paint_flat(lamp, WARNING)
    pieces.append(lamp)

    obj = join(pieces)
    obj.name = "flagship"
    return obj



# Keyed by ROSTER ID (core/enemies/roster/<id>.json) so a scene node's
# enemy_id and its mesh are the same word.
BUILDERS = {
    "dredger": make_dredger,
    "netbot": make_netbot,
    "hookline_rig": make_hookline_rig,
    "runoff_drone": make_runoff_drone,
    # NOT a roster unit: the Flagship is an ENCOUNTER (REQ-013), declared by a
    # world's `boss` element rather than by an enemy declaration. It lives in
    # this generator anyway because it is the same faction built from the same
    # palette and the same primitives, and splitting it into its own file
    # would let the two drift apart.
    "flagship": make_flagship,
}


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(prog="make_drift_fleet (bpy)")
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--seed", type=int, default=11)
    args = parser.parse_args(argv)

    report = {}
    for name, builder in BUILDERS.items():
        clear_scene()
        rng = random.Random(args.seed)
        obj = builder(rng)
        obj.data.materials.clear()
        obj.data.materials.append(fleet_material())
        # NOT shade_smooth, unlike the reef kit: flat faces are what make
        # these read as manufactured rather than grown.
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
    print("FLEET " + json.dumps({"seed": args.seed, "assets": report,
                                 "blender": bpy.app.version_string}))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
