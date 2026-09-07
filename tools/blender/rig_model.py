"""Rig the hero and give it an animation set — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/rig_model.py -- \
        --input assets/character/axolotl/axolotl.glb \
        --output assets/character/axolotl/axolotl.glb

tools/rig_model.py is the documented way to invoke this; it finds Blender,
builds exactly this command line, and validates what comes back.

WHY A RIG, and why this one. A model that slides is the single largest gap
between "a toy on screen" and "a character": the axolotl already faces its
travel and squashes on landing, but nothing about it MOVES. This adds the
smallest skeleton that can carry the four things the movement grammars ask
for — a body that leans, a tail that waves, legs that alternate, gills that
flutter — and one animation clip per state the controller already knows.

THE SKELETON (Blender space, after glTF Y-up import: +Y is the axolotl's
forward/head, -Y its tail, +Z up):

    root          the whole body, at the hips
     spine        hips forward to the shoulders
      head        shoulders to the snout
       gill_l/r   the frond stalks, one bone each side
      leg_fl/fr   front legs
      leg_bl/br   back legs
     tail_1/2/3   three segments down the tail

Twelve bones. Enough for a wave down the tail and a walk cycle; few enough
that a headless script can weight them without a rigging artist.

WEIGHTS ARE COMPUTED, NOT HEAT-DIFFUSED. Blender's automatic weights need
manifold geometry, and this model is a merged pile of primitives, so bone
heat can fail outright and would fail DIFFERENTLY per Blender build. Instead
each vertex takes the two nearest bone segments by inverse-square distance,
normalised — deterministic, never fails, and smooth enough for a toy.

The eye and its highlight are the exception: they are bound WHOLE to the
head. They sit a few centimetres from where the gill bones start, so the
nearest-two rule splits them between head and gill with slightly different
ratios — and the highlight then slides off the pupil every time the fronds
swing. A rigid eye cannot come apart.

CLIPS are pose-keyed on the armature only; geometry is untouched, so the
triangle count the Asset Contract budgets is preserved exactly.
"""

from __future__ import annotations

import argparse
import json
import math
import sys

import bpy  # type: ignore
from mathutils import Vector  # type: ignore

# (name, parent, head, tail) in Blender space, EVERY COORDINATE READ OFF
# tools/blender/make_axolotl.py's own tables rather than guessed: each spine
# and tail joint sits on the BODY row's centreline at that station, each limb
# bone runs from the row LEGS branches at to the foot that chain ends on, and
# each gill bone follows the middle ramus GILL_RAMI builds.
#
# THESE MUST TRACK THE MESH. An earlier layout put tail_1's head at Y -0.2,
# which sat INSIDE the torso once the body was rebuilt thicker — the tail
# chain then owned a third of the belly and the hurt clip folded the whole
# rear of the animal through itself. The rebuild that gave the animal real
# anatomy moved the spine down by about 0.16 (the old table floated above a
# fatter body) and swung the gills from a near-vertical crown to a swept
# plume, so every row here moved with it. Bones belong where the mass
# actually is, and since both the mesh and this table are generated from the
# repo, they can be kept in step. The gill bones moved furthest when the
# plumes were rebuilt to the maintainer's reference sheet: they had run
# outward and BACKWARD along a swept plume, and the reference holds the
# fronds up and clear of the head, so they now run up and out along the
# middle ramus GILL_RAMI builds.
BONES = [
    ("root", None, (0.0, -1.05, 0.460), (0.0, -0.45, 0.518)),
    ("spine", "root", (0.0, -0.45, 0.518), (0.0, 0.62, 0.575)),
    ("head", "spine", (0.0, 0.62, 0.578), (0.0, 1.66, 0.556)),
    ("gill_l", "head", (0.32, 1.04, 0.630), (0.80, 1.08, 1.270)),
    ("gill_r", "head", (-0.32, 1.04, 0.630), (-0.80, 1.08, 1.270)),
    ("leg_fl", "spine", (0.30, 0.27, 0.440), (0.74, 0.37, 0.060)),
    ("leg_fr", "spine", (-0.30, 0.27, 0.440), (-0.74, 0.37, 0.060)),
    ("leg_bl", "root", (0.30, -0.58, 0.440), (0.74, -0.73, 0.060)),
    ("leg_br", "root", (-0.30, -0.58, 0.440), (-0.74, -0.73, 0.060)),
    ("tail_1", "root", (0.0, -1.05, 0.460), (0.0, -1.70, 0.395)),
    ("tail_2", "tail_1", (0.0, -1.70, 0.395), (0.0, -2.30, 0.339)),
    ("tail_3", "tail_2", (0.0, -2.30, 0.339), (0.0, -2.92, 0.302)),
]

# Bones a walk/swim cycle drives, and the axis each swings on.
TAIL = ["tail_1", "tail_2", "tail_3"]
LEGS = ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
GILLS = ["gill_l", "gill_r"]

# Meshes bound whole to one bone instead of blended (see the module notes).
# Keyed by the object names tools/blender/refine_model.py merges the model
# into, one per role.
RIGID_TO_BONE = {"axolotl_eye": "head", "axolotl_gleam": "head"}


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build_armature() -> bpy.types.Object:
    armature_data = bpy.data.armatures.new("axolotl_rig")
    armature = bpy.data.objects.new("axolotl_rig", armature_data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    created: dict = {}
    for name, parent, head, tail in BONES:
        bone = armature_data.edit_bones.new(name)
        bone.head = Vector(head)
        bone.tail = Vector(tail)
        if parent is not None:
            bone.parent = created[parent]
        created[name] = bone
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def segment_distance(point: Vector, head: Vector, tail: Vector) -> float:
    span = tail - head
    length_squared = span.length_squared or 1e-9
    t = max(0.0, min(1.0, (point - head).dot(span) / length_squared))
    return (point - (head + span * t)).length


def weight_mesh(mesh_object: bpy.types.Object,
                armature: bpy.types.Object) -> None:
    """Two nearest bones per vertex, inverse-square, normalised — except the
    rigid head features, which go to one bone whole."""
    segments = [(name, Vector(head), Vector(tail))
                for name, _, head, tail in BONES]
    groups = {name: mesh_object.vertex_groups.new(name=name)
              for name, _, _, _ in BONES}
    rigid = RIGID_TO_BONE.get(mesh_object.name)
    if rigid is not None:
        groups[rigid].add([vertex.index
                           for vertex in mesh_object.data.vertices],
                          1.0, "REPLACE")
    else:
        matrix = mesh_object.matrix_world
        for vertex in mesh_object.data.vertices:
            point = matrix @ vertex.co
            ranked = sorted(
                ((segment_distance(point, head, tail), name)
                 for name, head, tail in segments))[:2]
            weights = [(name, 1.0 / (distance * distance + 1e-4))
                       for distance, name in ranked]
            total = sum(weight for _, weight in weights) or 1.0
            for name, weight in weights:
                groups[name].add([vertex.index], weight / total, "REPLACE")
    modifier = mesh_object.modifiers.new("Armature", "ARMATURE")
    modifier.object = armature
    mesh_object.parent = armature


def new_action(armature: bpy.types.Object, name: str) -> bpy.types.Action:
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    armature.animation_data.action = action
    return action


def key_rotation(bone: bpy.types.PoseBone, frame: int,
                 euler: tuple[float, float, float]) -> None:
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = euler
    bone.keyframe_insert("rotation_euler", frame=frame)


def rest_pose(armature: bpy.types.Object) -> None:
    for bone in armature.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0.0, 0.0, 0.0)
        bone.location = (0.0, 0.0, 0.0)


def clip_idle(armature: bpy.types.Object, length: int) -> None:
    """Breathing: a slow rise through the spine, gills fanning, tail adrift."""
    pose = armature.pose.bones
    for step in range(5):
        frame = 1 + step * (length // 4)
        phase = math.sin(step / 4.0 * math.tau)
        key_rotation(pose["spine"], frame, (phase * 0.045, 0.0, 0.0))
        key_rotation(pose["head"], frame, (-phase * 0.05, 0.0, 0.0))
        for index, name in enumerate(GILLS):
            side = 1.0 if index == 0 else -1.0
            key_rotation(pose[name], frame,
                         (0.0, 0.0, side * phase * 0.22))
        for index, name in enumerate(TAIL):
            key_rotation(pose[name], frame,
                         (0.0, 0.0, phase * 0.06 * (index + 1)))


def clip_waddle(armature: bpy.types.Object, length: int) -> None:
    """A four-legged trudge: diagonal pairs alternate, hips roll with them."""
    pose = armature.pose.bones
    for step in range(5):
        frame = 1 + step * (length // 4)
        phase = math.sin(step / 4.0 * math.tau)
        key_rotation(pose["root"], frame, (0.0, phase * 0.09, 0.0))
        key_rotation(pose["spine"], frame, (0.0, 0.0, -phase * 0.12))
        key_rotation(pose["head"], frame, (0.0, 0.0, phase * 0.07))
        # Diagonal gait: front-left with back-right.
        for name, sign in (("leg_fl", 1.0), ("leg_br", 1.0),
                           ("leg_fr", -1.0), ("leg_bl", -1.0)):
            key_rotation(pose[name], frame, (sign * phase * 0.5, 0.0, 0.0))
        for index, name in enumerate(TAIL):
            key_rotation(pose[name], frame,
                         (0.0, 0.0, -phase * 0.1 * (index + 1)))


def clip_swim(armature: bpy.types.Object, length: int) -> None:
    """A wave travelling down the tail, legs tucked back against the body."""
    pose = armature.pose.bones
    for step in range(5):
        frame = 1 + step * (length // 4)
        base = step / 4.0 * math.tau
        for index, name in enumerate(TAIL):
            # Each segment lags the one before it: that lag IS the wave.
            key_rotation(pose[name], frame,
                         (0.0, 0.0, math.sin(base - index * 0.9) * 0.3))
        key_rotation(pose["spine"], frame,
                     (0.0, 0.0, math.sin(base + 0.9) * 0.1))
        for name in LEGS:
            key_rotation(pose[name], frame, (-0.55, 0.0, 0.0))
        for index, name in enumerate(GILLS):
            side = 1.0 if index == 0 else -1.0
            key_rotation(pose[name], frame,
                         (0.0, 0.0, side * (0.25 + math.sin(base) * 0.15)))


def clip_hop(armature: bpy.types.Object, length: int) -> None:
    """The rise: body stretched, legs trailing, tail streaming behind."""
    pose = armature.pose.bones
    key_rotation(pose["spine"], 1, (0.0, 0.0, 0.0))
    key_rotation(pose["spine"], length, (-0.18, 0.0, 0.0))
    key_rotation(pose["head"], 1, (0.0, 0.0, 0.0))
    key_rotation(pose["head"], length, (-0.14, 0.0, 0.0))
    for name in LEGS:
        key_rotation(pose[name], 1, (0.0, 0.0, 0.0))
        key_rotation(pose[name], length, (0.6, 0.0, 0.0))
    for index, name in enumerate(TAIL):
        key_rotation(pose[name], 1, (0.0, 0.0, 0.0))
        key_rotation(pose[name], length, (0.16 * (index + 1), 0.0, 0.0))


def clip_fall(armature: bpy.types.Object, length: int) -> None:
    """The descent: legs spread to brace, tail up, head tipped down."""
    pose = armature.pose.bones
    for step in range(3):
        frame = 1 + step * (length // 2)
        phase = math.sin(step / 2.0 * math.tau) * 0.12
        key_rotation(pose["spine"], frame, (0.12, 0.0, 0.0))
        key_rotation(pose["head"], frame, (0.2 + phase, 0.0, 0.0))
        for index, name in enumerate(LEGS):
            side = 1.0 if index % 2 == 0 else -1.0
            key_rotation(pose[name], frame, (-0.35, 0.0, side * 0.4))
        for index, name in enumerate(TAIL):
            key_rotation(pose[name], frame,
                         (-0.2 * (index + 1) + phase, 0.0, 0.0))


def clip_hurt(armature: bpy.types.Object, length: int) -> None:
    """The flinch: a fast recoil that settles back — comedic, never limp.

    THE TORSO BARELY MOVES. The readable part of a flinch is the head
    snapping back and the gills flaring, and those are cheap; bending the
    spine hard adds nothing a viewer can name. It also cannot be afforded:
    at the amplitudes this clip first used, the rebuilt body — far thicker
    than the one they were tuned against — folded through itself. The head
    and gills carry the beat, the trunk only leans into it.
    """
    pose = armature.pose.bones
    beats = [(1, 0.0), (max(2, length // 5), 1.0),
             (max(3, length // 2), -0.35), (length, 0.0)]
    for frame, amount in beats:
        key_rotation(pose["root"], frame, (-amount * 0.16, 0.0, 0.0))
        key_rotation(pose["spine"], frame, (amount * 0.20, 0.0, amount * 0.12))
        key_rotation(pose["head"], frame, (amount * 0.42, 0.0, 0.0))
        for index, name in enumerate(GILLS):
            side = 1.0 if index == 0 else -1.0
            key_rotation(pose[name], frame, (0.0, 0.0, side * amount * 0.7))
        for index, name in enumerate(TAIL):
            key_rotation(pose[name], frame,
                         (0.0, 0.0, amount * 0.15 * (index + 1)))


# (clip name, frame length, builder). Names are the CONTRACT with the game
# client: core/rendering/hero_animator.gd plays them by these names.
CLIPS = [
    ("idle", 96, clip_idle),
    ("waddle", 32, clip_waddle),
    ("swim", 48, clip_swim),
    ("hop", 16, clip_hop),
    ("fall", 24, clip_fall),
    ("hurt", 20, clip_hurt),
]


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(prog="rig_model (bpy)")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args(argv)

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=args.input)
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if not meshes:
        print("RIG " + json.dumps({"error": "no mesh objects in input"}))
        return 1

    armature = build_armature()
    for mesh_object in meshes:
        weight_mesh(mesh_object, armature)

    bpy.context.view_layer.objects.active = armature
    armature.animation_data_create()
    for name, length, builder in CLIPS:
        rest_pose(armature)
        new_action(armature, name)
        builder(armature, length)
    armature.animation_data.action = None

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=args.output, export_format="GLB", export_apply=False,
        export_normals=True, export_colors=True, export_materials="EXPORT",
        export_animations=True, export_skins=True, export_morph=False,
        export_yup=True, export_animation_mode="ACTIONS",
        export_bake_animation=True, export_optimize_animation_size=False)

    print("RIG " + json.dumps({
        "input": args.input,
        "output": args.output,
        "bones": len(BONES),
        "meshesSkinned": len(meshes),
        "clips": [name for name, _, _ in CLIPS],
        "polygons": sum(len(obj.data.polygons) for obj in bpy.data.objects
                        if obj.type == "MESH"),
        "blender": bpy.app.version_string,
    }))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
