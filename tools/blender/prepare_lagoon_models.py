"""Build game-sized derivatives of the three supplied Meshy GLBs in Blender."""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector


MODELS = [
    ("coral_rock", "Meshy_AI_coral_rock_decor_0909023358_image-to-3d-texture.glb", 64000),
    ("boulder_cluster", "Meshy_AI_boulder_rock_cluster_0909023324_image-to-3d-texture.glb", 28000),
    ("flower_cluster", "Meshy_AI_flower_cluster_0909023349_image-to-3d-texture.glb", 64000),
    ("waterfall_arch", "Meshy_AI_rock_arch_waterfall_0909023338_image-to-3d-texture.glb", 96000),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--only", choices=[item[0] for item in MODELS])
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output_dir.mkdir(parents=True, exist_ok=True)
    report_path = args.output_dir / "asset-build.json"
    report = json.loads(report_path.read_text(encoding="utf-8")) if args.only and report_path.exists() else []
    for name, filename, budget in MODELS:
        if args.only and args.only != name:
            continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        source = args.source_dir / filename
        with source.open("rb") as stream:
            source_hash = hashlib.file_digest(stream, "sha256").hexdigest()
        bpy.ops.import_scene.gltf(filepath=str(source))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        before = sum(len(obj.data.polygons) for obj in meshes)
        points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
        low = Vector(tuple(min(point[i] for point in points) for i in range(3)))
        high = Vector(tuple(max(point[i] for point in points) for i in range(3)))
        center = Vector(((low.x + high.x) * 0.5, (low.y + high.y) * 0.5, low.z))
        for obj in meshes:
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
            obj.location -= center
            modifier = obj.modifiers.new("GameMesh", "DECIMATE")
            modifier.ratio = min(1.0, budget / before)
            modifier.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            obj.name = name
            obj.data.name = name + "_mesh"
            obj.select_set(False)
        textures = []
        for image in bpy.data.images:
            if image.type != "IMAGE" or image.size[0] == 0:
                continue
            original = list(image.size)
            if max(original) > 2048:
                ratio = 2048 / max(original)
                image.scale(round(original[0] * ratio), round(original[1] * ratio))
            textures.append({"name": image.name, "source_size": original, "game_size": list(image.size)})
        after = sum(len(obj.data.polygons) for obj in meshes)
        destination = args.output_dir / (name + ".glb")
        bpy.ops.export_scene.gltf(filepath=str(destination), export_format="GLB",
                                  export_animations=False, export_cameras=False,
                                  export_lights=False, export_tangents=True)
        record = {"name": name, "source": filename, "source_sha256": source_hash,
                  "source_triangles": before, "game_triangles": after,
                  "source_bounds_blender": [list(low), list(high)], "textures": textures,
                  "game_file": destination.name, "game_bytes": destination.stat().st_size}
        report = [item for item in report if item["name"] != name]
        report.append(record)
        print("LAGOON ASSET " + json.dumps(record), flush=True)
    (args.output_dir / "asset-build.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
