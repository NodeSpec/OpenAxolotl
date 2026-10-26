"""Open the supplied arch for downstream traversal; retain the original derivative."""
import bpy
import bmesh
from pathlib import Path

directory = Path(__file__).resolve().parents[2] / "assets/environment/lagoon_meshy"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(directory / "waterfall_arch.glb"))
obj = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bm = bmesh.new()
bm.from_mesh(obj.data)
# The mesh's central painted stream and dark end cap are not walkable geometry.
remove = [face for face in bm.faces
          if abs(face.calc_center_median().x) < 0.43 and face.calc_center_median().z < 0.85]
bmesh.ops.delete(bm, geom=remove, context="FACES")
bm.to_mesh(obj.data)
bm.free()
obj.name = "open_arch"
obj.data.name = "open_arch"
bpy.ops.export_scene.gltf(filepath=str(directory / "open_arch.glb"), export_format="GLB",
                          export_animations=False, export_tangents=True)
print("OPEN ARCH",len(obj.data.polygons),"triangles",flush=True)
