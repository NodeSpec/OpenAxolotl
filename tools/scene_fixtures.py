#!/usr/bin/env python3
"""Generate .tscn fixtures for the world-authoring tools (Shared Test Fixtures).

    python tools/scene_fixtures.py <directory>

The four tools that rewrite a level -- shell_terrain, scatter_props,
fill_dressing and gameplay_snapshot -- all read the same thing: Godot's text
scene format. So they share one fixture rather than four, and that is not only
economy. The properties most worth testing are ACROSS tools: filler must avoid
the landmarks the scatterer left standing, and none of the three passes may
move anything the snapshot calls gameplay. A shared fixture is what lets a
test say that in one place.

The scene is described, not transcribed: a test that needs a platform
somewhere else asks for one rather than hand-editing scene text and hoping
four sets of regexes still match it. What the default carries is one of each
thing the tools have to tell apart --

  * a big platform and a small one, either side of the area at which dressing
    a surface is worth the triangles;
  * markers in gameplay groups, which filler has to keep clear of;
  * a Dressing container with authored landmark INSTANCES, which are the
    thing REQ-011 wants kept legible;
  * a manufactured body (a mod gate), which the visual pass must leave
    geometric on purpose.

Standard library only, deterministic output. The __main__ form exists so a
human can materialise the fixture and open it in Godot.
"""

from __future__ import annotations

import os
import sys

## Where the fixture's props come from. These are real repository paths: a
## fixture that referenced invented assets would parse identically and then
## measure nothing when a tool reads a prop's triangle count off its glb.
KITS = (
    ("1_kit_canopy_tree", "res://assets/environment/canopy_tree/canopy_tree.glb"),
    ("2_kit_river_boulder",
     "res://assets/environment/river_boulder/river_boulder.glb"),
)

SURFACE = ("3_surface", "res://core/rendering/terrain/mossy_stone.tres")
SCATTER_SCRIPT = ("scatter_field_script", "res://core/rendering/scatter_field.gd")
SHELL_SCRIPT = ("terrain_shell_script", "res://core/rendering/terrain_shell.gd")
CANOPY_MATERIAL = ("forest_canopy_material",
                   "res://core/rendering/materials/forest_canopy.tres")

## A slab worth dressing, a ledge worth dressing, and a step that is not:
## 2x2 metres is below fill_dressing's MIN_PLATFORM_AREA, so a test can hold
## the tool to leaving it alone without hard-coding the threshold.
DEFAULT_PLATFORMS = (
    {"name": "GroundSlab", "position": (0, 0, 0), "size": (40, 2, 40)},
    {"name": "Ledge", "position": (30, 6, 0), "size": (8, 1, 8)},
    {"name": "PebbleStep", "position": (-30, 2, 0), "size": (2, 1, 2)},
)

DEFAULT_GAMEPLAY = (
    {"name": "Spawn", "type": "Marker3D", "groups": ["spawn_point"],
     "position": (0, 1.2, 0)},
    {"name": "Checkpoint1", "type": "Marker3D", "groups": ["checkpoint"],
     "position": (30, 7, 0)},
    {"name": "Seed1", "type": "Marker3D", "groups": ["collectible"],
     "position": (5, 1.2, 5)},
)

## Named clusters, one per traversal beat: the composition REQ-011 asks a
## contributor to be able to read out of the scene file.
DEFAULT_LANDMARKS = (
    {"name": "OpeningTreeLeft", "kit": "1_kit_canopy_tree",
     "position": (-8, 1, -8)},
    {"name": "OpeningTreeRight", "kit": "1_kit_canopy_tree",
     "position": (-8, 1, 8)},
    {"name": "BeatBoulder", "kit": "2_kit_river_boulder",
     "position": (8, 1, 8)},
)

## Manufactured, and deliberately so: a bevelled organic rock where a mod gate
## should be would lie about what the object is.
DEFAULT_GEOMETRIC = {"name": "ModGate", "position": (12, 1, -12),
                     "size": (3, 4, 1)}


def _number(value: float) -> str:
    """Godot's own float formatting, so a fixture round-trips unchanged."""
    return str(int(value)) if float(value) == int(value) else repr(value)


def _triple(values: tuple) -> str:
    return ", ".join(_number(value) for value in values)


def _transform(position: tuple) -> str:
    return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)" % _triple(position)


def _body(name: str, position: tuple, index: int, *, shelled: bool = False,
          surface: bool = True) -> list:
    """A StaticBody3D with the pair the visual pass looks for: a BoxShape3D
    collider to keep and a BoxMesh proxy to replace."""
    lines = [
        '[node name="%s" type="StaticBody3D" parent="."]' % name,
        "transform = %s" % _transform(position),
        "",
        '[node name="Mesh" type="MeshInstance3D" parent="%s"]' % name,
        'mesh = SubResource("BoxMesh_%d")' % index,
    ]
    if surface:
        lines.append('surface_material_override/0 = ExtResource("%s")'
                     % SURFACE[0])
    lines += [
        "",
        '[node name="Collision" type="CollisionShape3D" parent="%s"]' % name,
        'shape = SubResource("BoxShape3D_%d")' % index,
        "",
    ]
    if shelled:
        lines += [
            '[node name="Shell" type="Node3D" parent="%s"]' % name,
            'script = ExtResource("%s")' % SHELL_SCRIPT[0],
            "shell_seed = 17",
            "",
        ]
    return lines


def world_text(*, platforms: tuple = DEFAULT_PLATFORMS,
               gameplay: tuple = DEFAULT_GAMEPLAY,
               landmarks: tuple = DEFAULT_LANDMARKS,
               geometric: dict | None = DEFAULT_GEOMETRIC,
               fields: bool = False, shelled: bool = False) -> str:
    """A world scene, as Godot writes them.

    fields  -- also carry a ScatterField, i.e. a world that has already had a
               dressing pass. Several rules only exist for that state.
    shelled -- give every platform body a Shell child, i.e. a world that has
               already been through the terrain pass.
    """
    resources = [SURFACE, *KITS]
    if fields:
        resources += [SCATTER_SCRIPT, CANOPY_MATERIAL]
    if shelled:
        resources.append(SHELL_SCRIPT)

    header = []
    for resource_id, path in resources:
        kind = "Script" if path.endswith(".gd") else (
            "Material" if path.endswith(".tres") else "PackedScene")
        header.append('[ext_resource type="%s" path="%s" id="%s"]'
                      % (kind, path, resource_id))

    subs = []
    for index, platform in enumerate(platforms):
        subs += ['[sub_resource type="BoxShape3D" id="BoxShape3D_%d"]' % index,
                 "size = Vector3(%s)" % _triple(platform["size"]), ""]
        subs += ['[sub_resource type="BoxMesh" id="BoxMesh_%d"]' % index,
                 "size = Vector3(%s)" % _triple(platform["size"]), ""]
    gate_index = len(platforms)
    if geometric is not None:
        subs += ['[sub_resource type="BoxShape3D" id="BoxShape3D_%d"]'
                 % gate_index,
                 "size = Vector3(%s)" % _triple(geometric["size"]), ""]
        subs += ['[sub_resource type="BoxMesh" id="BoxMesh_%d"]' % gate_index,
                 "size = Vector3(%s)" % _triple(geometric["size"]), ""]

    nodes = ['[node name="World" type="Node3D"]', ""]
    for index, platform in enumerate(platforms):
        nodes += _body(platform["name"], platform["position"], index,
                       shelled=shelled)
    if geometric is not None:
        nodes += _body(geometric["name"], geometric["position"], gate_index,
                       surface=False)

    for marker in gameplay:
        nodes += ['[node name="%s" type="%s" parent="." groups=[%s]]'
                  % (marker["name"], marker["type"],
                     ", ".join('"%s"' % g for g in marker["groups"])),
                  "transform = %s" % _transform(marker["position"]), ""]

    nodes.append('[node name="Dressing" type="Node3D" parent="."]')
    if fields:
        nodes += ["",
                  '[node name="CanopyTreeField" type="Node3D" parent="Dressing"]',
                  'script = ExtResource("%s")' % SCATTER_SCRIPT[0],
                  'prop_scene = ExtResource("%s")' % KITS[0][0],
                  "transforms = PackedFloat32Array(1, 0, 0, 0, 1, 0, 0, 0, 1, "
                  "-14, 1, -14)",
                  'surface_material = ExtResource("%s")' % CANOPY_MATERIAL[0]]
    for landmark in landmarks:
        nodes += ["",
                  '[node name="%s" parent="Dressing" instance=ExtResource("%s")]'
                  % (landmark["name"], landmark["kit"]),
                  "transform = %s" % _transform(landmark["position"])]
    nodes.append("")

    steps = len(header) + sum(1 for line in subs if line.startswith("[")) + 1
    return "\n".join(["[gd_scene load_steps=%d format=3]" % steps, ""]
                     + header + [""] + subs + nodes)


def write_world(directory: str, name: str = "world.tscn", **kwargs) -> str:
    """Materialise a fixture world and return its path."""
    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, name)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(world_text(**kwargs))
    return path


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    print(write_world(target))
