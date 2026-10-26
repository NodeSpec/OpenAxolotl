"""Original articulated crayfish. Run with Blender --background --python this_file."""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
PROJECT=Path(__file__).resolve().parents[2]
OUT=PROJECT/'assets/creature/glowing_crayfish'; OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
groups={}; joints={}
def joint(name,point,parent='Body'):
    groups[name]=[];joints[name]=(point,parent)
joint('Body',(0,0,.14),None)
shell=bpy.data.materials.new('CrayfishShell');shell.use_nodes=True
bs=shell.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.34;bs.inputs['Metallic'].default_value=.045
vc=shell.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='ShellColor';shell.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
glow=shell.copy();glow.name='CrayfishGlow';bs=glow.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(.02,.62,.95,1);bs.inputs['Emission Strength'].default_value=.65
eye=shell.copy();eye.name='CrayfishEyes';eye.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.12
BLUE=(.025,.18,.38,1); TEAL=(.025,.42,.55,1); EDGE=(.16,.67,.72,1); PALE=(.38,.83,.84,1); DARK=(.005,.018,.032,1)
def finish(o,group,col,mat=shell):
    o.data.materials.append(mat)
    attr=o.data.color_attributes.new(name='ShellColor',type='FLOAT_COLOR',domain='CORNER')
    for face in o.data.polygons:
        face.use_smooth=True
        for i in face.loop_indices:
            p=o.data.vertices[o.data.loops[i].vertex_index].co
            variation=1+.075*math.sin(p.x*37+p.y*23)+.045*math.sin(p.z*63-p.y*19)
            attr.data[i].color=tuple(min(1,c*variation) for c in col[:3])+(1,)
    vg=o.vertex_groups.new(name=group);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');groups[group].append(o)
    return o
def oval(name,p,size,col=BLUE,g='Body',seg=20,rings=10,mat=shell):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=p)
    o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,g,col,mat)
def tube(name,points,radii,col=TEAL,g='Body',sides=7,mat=shell):
    verts=[];faces=[]
    for i,p in enumerate(points):
        axis=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)]);axis.normalize()
        n=axis.cross(Vector((0,0,1)))
        if n.length<.01:n=axis.cross(Vector((1,0,0)))
        n.normalize();b=axis.cross(n)
        verts.extend(Vector(p)+(n*math.cos(j*math.tau/sides)+b*math.sin(j*math.tau/sides))*radii[i] for j in range(sides))
    for i in range(len(points)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    faces += [tuple(range(sides-1,-1,-1)),tuple((len(points)-1)*sides+j for j in range(sides))]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    return finish(o,g,col,mat)
# Long overlapping carapace, distinct cheeks, rostrum and rolled shell margins.
oval('Carapace',(0,.00,.155),(.128,.238,.117),seg=32,rings=16)
oval('Cephalon',(0,.18,.155),(.098,.112,.086),TEAL,seg=24,rings=12)
tube('Rostrum',[(0,.225,.18),(0,.303,.193),(0,.35,.177)],[.031,.021,.002],EDGE,sides=9)
for side in [-1,1]:
    tube('ShellRim',[(side*.06,-.2,.135),(side*.12,-.10,.13),(side*.129,.035,.13),(side*.10,.155,.14)],[.007]*4,EDGE)
    tube('HeadRidge',[(side*.075,.13,.21),(side*.060,.22,.222),(side*.029,.278,.203)],[.006,.005,.002],PALE)
    for i in range(3):
        y=.25+i*.023;tube('RostrumTooth',[(side*.019,y,.19),(side*(.04-i*.008),y-.004,.195)],[.009,.001],EDGE,sides=5)
    for i in range(6):
        y=-.13+i*.053;oval('ShellFreckle',(side*.091,y,.234),(.009,.012,.004),EDGE,seg=8,rings=4)
    for i in range(3):
        oval('BiolumePearl',(side*.08,-.07+i*.065,.247),(.007,.012,.004),PALE,seg=8,rings=4,mat=glow)
# Six plates have separate bones so tail flicks curl rather than rotate a rigid tail.
for i in range(6):
    name='Tail%d'%i; y=-.18-i*.063; joint(name,(0,y+.037,.12-i*.008),'Body' if i==0 else 'Tail%d'%(i-1))
    r=.116-i*.012; z=.125-i*.008
    oval('Abdomen%d'%i,(0,y,z),(r,.053,.063-i*.004),TEAL if i%2==0 else BLUE,name,seg=20,rings=8)
    pts=[(r*math.cos(a),y-.023,z+(r*.48)*math.sin(a)) for a in [0,math.pi/4,math.pi/2,3*math.pi/4,math.pi]]
    tube('PlateLip',pts,[.004]*5,EDGE,name,sides=6)
    tube('GlowStitch',[(-r*.52,y-.027,z+.045),(0,y-.029,z+.054),(r*.52,y-.027,z+.045)],[.003]*3,PALE,name,sides=5,mat=glow)
for i in [-2,-1,0,1,2]:
    o=oval('TailFan',(i*.028,-.58+abs(i)*.007,.063),(.040,.089,.016),TEAL,'Tail5',seg=16,rings=6);o.rotation_euler.z=i*.20
    tube('FanRib',[(i*.018,-.52,.077),(i*.030,-.58,.084),(i*.043,-.65,.072)],[.0025,.003,.001],PALE,'Tail5',sides=5)
for side,label in [(-1,'L'),(1,'R')]:
    claw='Claw'+label;joint(claw,(side*.093,.12,.14))
    tube('ClawArm',[(side*.093,.12,.14),(side*.19,.17,.125),(side*.24,.28,.155)],[.032,.027,.025],BLUE,claw,sides=10)
    oval('Elbow',(side*.19,.17,.125),(.035,.038,.032),EDGE,claw,seg=12,rings=6)
    oval('ClawPalm',(side*.27,.348,.16),(.077,.109,.049),TEAL,claw,seg=24,rings=12)
    tube('OuterFinger',[(side*.307,.37,.162),(side*.336,.45,.169),(side*.323,.516,.172),(side*.279,.554,.17)],[.043,.035,.021,.003],TEAL,claw,sides=10)
    tube('ClawRidge',[(side*.29,.29,.194),(side*.31,.37,.206),(side*.325,.44,.199),(side*.316,.49,.188)],[.004]*4,EDGE,claw,sides=6)
    for i in range(3):tube('OuterTooth',[(side*.32,.44+i*.025,.166),(side*.293,.447+i*.024,.166)],[.008,.001],PALE,claw,sides=5)
    thumb='Pincer'+label;joint(thumb,(side*.228,.392,.16),claw)
    tube('Thumb',[(side*.228,.392,.16),(side*.222,.459,.162),(side*.253,.517,.169),(side*.276,.54,.17)],[.029,.025,.014,.002],EDGE,thumb,sides=10)
    for i in range(2):tube('ThumbTooth',[(side*.233,.45+i*.03,.165),(side*.253,.448+i*.03,.165)],[.007,.001],PALE,thumb,sides=5)
    oval('ClawGlow',(side*.277,.344,.209),(.019,.031,.004),PALE,claw,seg=12,rings=5,mat=glow)
    # Eight articulated walking legs, each with a defined knee and pointed foot.
    for i in range(4):
        y=.092-i*.081; leg='Leg%s%d'%(label,i); joint(leg,(side*.084,y,.125))
        tube('Leg',[(side*.084,y,.125),(side*(.175-i*.007),y+.015,.09),(side*(.224-i*.012),y-.024,.03),(side*(.249-i*.011),y-.057,.018)],[.017,.015,.009,.002],TEAL,leg,sides=7)
        oval('Knee',(side*(.175-i*.007),y+.015,.09),(.020,.021,.019),EDGE,leg,seg=10,rings=5)
    stalk='Eye'+label;joint(stalk,(side*.060,.234,.182))
    tube('EyeStalk',[(side*.060,.234,.182),(side*.086,.267,.248)],[.014,.012],TEAL,stalk,sides=8)
    oval('Eye',(side*.086,.267,.254),(.027,.031,.030),DARK,stalk,seg=20,rings=10,mat=eye)
    oval('EyeLight',(side*.083,.287,.271),(.006,.005,.007),PALE,stalk,seg=8,rings=4,mat=eye)
    antenna='Antenna'+label;joint(antenna,(side*.036,.265,.184))
    pts=[(side*(.036+.21*t),.265+.40*t,.184+.12*math.sin(t*2)) for t in [j/8 for j in range(9)]]
    tube('Antenna',pts,[.0065*(1-j/9) for j in range(9)],EDGE,antenna,sides=7)
    tube('ShortFeeler',[(side*.026,.267,.16),(side*.040,.33,.169),(side*.072,.391,.163)],[.004,.003,.001],PALE,antenna,sides=6)
# A single skinned mesh keeps the articulated creature inexpensive to draw.
bpy.ops.object.select_all(action='DESELECT')
objects=[o for group in groups.values() for o in group]
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name='CrayfishShellMesh'
bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
# Preserve smooth contours; budget mostly goes to silhouette and anatomical details.
mod=mesh.modifiers.new('DetailBudget','DECIMATE');mod.ratio=.79;bpy.ops.object.modifier_apply(modifier=mod.name)
triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons)
bpy.ops.object.select_all(action='DESELECT');arm=bpy.data.armatures.new('CrayfishSkeleton');rig=bpy.data.objects.new('CrayfishRig',arm);bpy.context.collection.objects.link(rig);rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for name,(point,parent) in joints.items():
    bone=arm.edit_bones.new(name);bone.head=point;bone.tail=Vector(point)+Vector((0,.06,0))
    if parent:bone.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');mesh.parent=rig;modifier=mesh.modifiers.new('CrayfishSkin','ARMATURE');modifier.object=rig
bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT/'tools/source_art/glowing_crayfish.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'glowing_crayfish.glb'),export_format='GLB',export_yup=True,export_animations=False,export_skins=True)
(PROJECT/'tools/source_art/crayfish_build_details.json').write_text(json.dumps({'triangles':triangles,'bones':len(joints),'materials':3,'description':'Refined carapace, serrated articulated pincers, six articulated tail plates, five-part fan, eight walking legs, swivelling eyes and feelers. Original procedural geometry and colors.'},indent=2),encoding='utf-8')
print('REFINED CRAYFISH',triangles,'triangles',len(joints),'bones')
