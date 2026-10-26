"""Derive rigid mechanical parts; source GLBs are never modified. Run in Blender."""
import bpy, bmesh, json, hashlib, sys, argparse
from pathlib import Path
from mathutils import Vector

parser=argparse.ArgumentParser()
parser.add_argument('--project-root',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ROOT=args.project_root
OUT=args.output
OUT.mkdir(parents=True,exist_ok=True)
report={}
for name in ['netbot','hookline_rig']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source=ROOT/'assets/prop'/name/(name+'.glb')
    bpy.ops.import_scene.gltf(filepath=str(source))
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if name=='netbot':
        pivots={'Chassis':(0,0,0),'CaptureArm':(-.23,0,-.015),'NetBasket':(-.60,0,.02)}
        def classify(v):
            return 'NetBasket' if v.x<-.60 else ('CaptureArm' if v.x<-.24 else 'Chassis')
    else:
        pivots={'Chassis':(0,0,0),'HookLeft':(-.69,0,.04),'HookRight':(.69,0,.04)}
        def classify(v):
            if abs(v.x)>.50 and v.z<.04:return 'HookLeft' if v.x<0 else 'HookRight'
            if abs(v.x)>.55 and .04<=v.z<.09:return 'REMOVE'
            return 'Chassis'
    assignments=[classify(p.center) for p in obj.data.polygons]
    counts={}
    for part,pivot in pivots.items():
        mesh=obj.data.copy()
        bm=bmesh.new();bm.from_mesh(mesh);bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if assignments[f.index]!=part],context='FACES')
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
        bm.to_mesh(mesh);bm.free()
        for v in mesh.vertices:v.co-=Vector(pivot)
        mesh.update()
        node=bpy.data.objects.new(part,mesh);bpy.context.collection.objects.link(node);node.location=pivot
        counts[part]=len(mesh.polygons)
    bpy.data.objects.remove(obj,do_unlink=True)
    # Remove original empty import parents; all derived parts are in world coordinates.
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'_parts.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'_parts.glb')),export_format='GLB',export_animations=False,export_yup=True)
    report[name]={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'parts':counts,'pivots_blender':pivots,'triangles':sum(counts.values()),'removed_connector_triangles':assignments.count('REMOVE')}
(OUT/'preparation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))

