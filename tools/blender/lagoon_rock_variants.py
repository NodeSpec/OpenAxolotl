"""Reshape the supplied boulder into UV-preserving rock variants, using Blender."""
import bpy
from mathutils import Vector
from pathlib import Path
import math

root = Path(__file__).resolve().parents[2]
directory = root / "assets/environment/lagoon_meshy"
for name, budget, style in [("shore_rock", 3200, 0), ("bank_rock", 4800, 1), ("cliff_rock", 6400, 2)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(directory / "boulder_cluster.glb"))
    obj = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    points = [v.co.copy() for v in obj.data.vertices]
    low = Vector(tuple(min(v[i] for v in points) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in points) for i in range(3)))
    for vertex in obj.data.vertices:
        p = (vertex.co - low)
        x, y, z = (p[i] / (high[i] - low[i]) for i in range(3))
        x, y = x * 2 - 1, y * 2 - 1
        # Gentle asymmetric bulges avoid repeating the original circular top.
        if style == 0:
            x *= 1 + 0.08 * math.sin(y * 3)
            z *= 0.92 + 0.08 * math.cos(y * 2)
        elif style == 1:
            x = x * (0.94 + 0.08 * math.sin(z * 4)) + 0.13 * z
            y *= 0.95 + 0.08 * math.cos(x * 4)
        else:
            x = x * (0.93 + 0.09 * math.cos(z * 5)) - 0.18 * z
            y += 0.07 * math.sin(z * 6 + x)
            z *= 0.95 + 0.05 * math.cos(x * 3)
        vertex.co = Vector((x, y, (z - 0.5) * 1.7))
    modifier = obj.modifiers.new("RuntimeDensity", "DECIMATE")
    modifier.ratio = budget / len(obj.data.polygons)
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.name = name
    obj.data.name = name
    bpy.ops.export_scene.gltf(filepath=str(directory / (name + ".glb")), export_format="GLB",
                              export_animations=False, export_tangents=True)
    print("ROCK VARIANT", name, len(obj.data.polygons), flush=True)
