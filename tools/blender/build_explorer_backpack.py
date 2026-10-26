"""Rebuild a separate, skinned accessory against the unchanged shipped hero.
Run with Blender 4.5: blender --background --python-exit-code 1 --python this.py
All outputs remain in the workspace until the explicit install step.
"""
import bpy, bmesh, math, json, hashlib, os
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
import argparse, sys
parser=argparse.ArgumentParser()
parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[2])
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
PROJECT=args.project.resolve()
DEST=args.output.resolve();DEST.mkdir(parents=True,exist_ok=True)
TAU=math.tau
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.bake.margin=8

def tile(name, color, canvas=False):
    paths=[DEST/(name+'_'+suffix+'.png') for suffix in ['color','normal','roughness']]
    if not all(p.exists() for p in paths):
        bpy.ops.mesh.primitive_plane_add(size=2)
        plane=bpy.context.object
        mat=bpy.data.materials.new(name+'_bake');mat.use_nodes=True
        plane.data.materials.append(mat)
        nodes,links=mat.node_tree.nodes,mat.node_tree.links
        bs=nodes.get('Principled BSDF')
        coord=nodes.new('ShaderNodeTexCoord')
        noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=110 if canvas else 170
        noise.inputs['Detail'].default_value=3;noise.inputs['Roughness'].default_value=.72
        links.new(coord.outputs['UV'],noise.inputs['Vector'])
        if canvas:
            waves=[]
            for axis in ['X','Y']:
                w=nodes.new('ShaderNodeTexWave');w.bands_direction=axis;w.inputs['Scale'].default_value=48
                links.new(coord.outputs['UV'],w.inputs['Vector']);waves.append(w)
            mult=nodes.new('ShaderNodeMath');mult.operation='MULTIPLY'
            links.new(waves[0].outputs['Color'],mult.inputs[0]);links.new(waves[1].outputs['Color'],mult.inputs[1])
            mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[0].default_value=.18
            links.new(mult.outputs[0],mix.inputs[1]);links.new(noise.outputs['Fac'],mix.inputs[2]);height=mix.outputs[0]
        else:
            vor=nodes.new('ShaderNodeTexVoronoi');vor.feature='DISTANCE_TO_EDGE';vor.inputs['Scale'].default_value=150
            links.new(coord.outputs['UV'],vor.inputs['Vector'])
            mix=nodes.new('ShaderNodeMixRGB');mix.inputs[0].default_value=.6
            links.new(vor.outputs['Distance'],mix.inputs[1]);links.new(noise.outputs['Fac'],mix.inputs[2]);height=mix.outputs[0]
        ramp=nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].color=tuple(c*.66 for c in color)+(1,)
        ramp.color_ramp.elements[1].color=tuple(c*1.18 for c in color)+(1,)
        links.new(height,ramp.inputs[0]);links.new(ramp.outputs[0],bs.inputs['Base Color'])
        bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.35;bump.inputs['Distance'].default_value=.003
        links.new(height,bump.inputs['Height']);links.new(bump.outputs['Normal'],bs.inputs['Normal'])
        rough=nodes.new('ShaderNodeMapRange');rough.inputs['To Min'].default_value=.66 if canvas else .42;rough.inputs['To Max'].default_value=.95 if canvas else .7
        links.new(noise.outputs['Fac'],rough.inputs['Value']);links.new(rough.outputs['Result'],bs.inputs['Roughness'])
        for path,mode in zip(paths,['DIFFUSE','NORMAL','ROUGHNESS']):
            img=bpy.data.images.new(path.stem,1024,1024,alpha=False)
            if mode!='DIFFUSE':img.colorspace_settings.name='Non-Color'
            target=nodes.new('ShaderNodeTexImage');target.image=img;nodes.active=target
            scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True
            bpy.ops.object.bake(type=mode)
            img.filepath_raw=str(path);img.file_format='PNG';img.save()
            nodes.remove(target)
        bpy.data.objects.remove(plane,do_unlink=True)
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF')
    for path,input_name in zip(paths,['Base Color','Normal','Roughness']):
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True)
        if input_name=='Normal':
            normal=mat.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.7
            mat.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);mat.node_tree.links.new(normal.outputs[0],bs.inputs[input_name])
        else:mat.node_tree.links.new(tex.outputs['Color'],bs.inputs[input_name])
    return mat

canvas=tile('Canvas_olive',(.20,.205,.105),True)
leather=tile('Leather_saddle',(.30,.105,.035))
def solid(name,color,metallic=0,rough=.5):
    m=bpy.data.materials.new(name);m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Metallic'].default_value=metallic;b.inputs['Roughness'].default_value=rough
    return m
brass=solid('Brass_aged',(.46,.265,.075),.78,.30)
iron=solid('Buckles_gunmetal',(.16,.19,.20),.8,.28)
thread=solid('Stitch_waxed',(.62,.38,.14),0,.92)
paper=solid('Parchment',(.72,.53,.29),0,.91)
ink=solid('Map_ink',(.20,.070,.02),0,.9)

bpy.ops.import_scene.gltf(filepath=str(PROJECT/'assets/character/axolotl/axolotl.glb'))
rig=next(o for o in scene.objects if o.type=='ARMATURE')
hero=[o for o in scene.objects if o.type=='MESH']
for o in hero:
    if o.name=='Icosphere':o.hide_render=True
body=next(o for o in hero if o.name=='mesh_node')
body_points=np.array([list(body.matrix_world@v.co) for v in body.data.vertices])
parts=[]

def finish(o,name,mat,group='spine'):
    o.name=name
    o.data.materials.clear();o.data.materials.append(mat)
    for poly in o.data.polygons:poly.use_smooth=True
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if not o.data.uv_layers:
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
    vg=o.vertex_groups.new(name=group);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    parts.append(o);return o

def mesh_obj(name,verts,faces,mat,group='spine'):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);scene.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
    return finish(o,name,mat,group)

def box(name,loc,size,mat,bevel=.03,segments=3):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=o.modifiers.new('Rounded sewn edges','BEVEL');mod.width=bevel;mod.segments=segments
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL');mod.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,mat)

def tube(name,points,radius,mat,sides=6,closed=False):
    # Parallel transported frames keep the stitched piping smooth around corners.
    p=[Vector(v) for v in points];verts=[]
    for i,v in enumerate(p):
        tangent=(p[(i+1)%len(p)]-p[(i-1)%len(p)]) if closed else (p[min(i+1,len(p)-1)]-p[max(0,i-1)])
        tangent.normalize();ref=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((0,1,0))
        a=tangent.cross(ref).normalized();b=tangent.cross(a).normalized()
        for j in range(sides):verts.append(tuple(v+radius*(a*math.cos(TAU*j/sides)+b*math.sin(TAU*j/sides))))
    faces=[]
    for i in range(len(p) if closed else len(p)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,((i+1)%len(p))*sides+(j+1)%sides,((i+1)%len(p))*sides+j))
    if not closed:faces += [tuple(reversed(range(sides))),tuple((len(p)-1)*sides+j for j in range(sides))]
    return mesh_obj(name,verts,faces,mat)

def ribbon(name,profile,x,width,mat,thick=.012):
    verts=[];columns=9 if width>.3 else 2
    for y,z in profile:
        verts.extend([(x-width/2+width*j/(columns-1),y,z) for j in range(columns)])
    faces=[((i+1)*columns+j,(i+1)*columns+j+1,i*columns+j+1,i*columns+j) for i in range(len(profile)-1) for j in range(columns-1)]
    o=mesh_obj(name,verts,faces,mat)
    mod=o.modifiers.new('Leather thickness','SOLIDIFY');mod.thickness=thick
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=o.modifiers.new('Soft edges','BEVEL');mod.width=.004;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def buckle(name,center,width,height,plane='XZ'):
    c=Vector(center);pts=[]
    # Four rounded corners in the visible strap plane.
    r=.014
    for cx,cy,start in [(width/2-r,height/2-r,0),(-width/2+r,height/2-r,90),(-width/2+r,-height/2+r,180),(width/2-r,-height/2+r,270)]:
        for k in range(5):
            angle=math.radians(start+22.5*k)
            u=cx+r*math.cos(angle);v=cy+r*math.sin(angle)
            pts.append(tuple(c+(Vector((u,0,v)) if plane=='XZ' else Vector((0,u,v)))))
    tube(name,pts,.009,iron,7,True)
    axis=Vector((width/2,0,0)) if plane=='XZ' else Vector((0,width/2,0))
    tube(name+'_bar',[c-axis,c+axis],.006,iron)
    direction=Vector((0,0,height*.38))
    tube(name+'_tongue',[c,c+direction],.005,iron)

def sphere(name,loc,size,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,radius=1,location=loc)
    o=bpy.context.object;o.scale=size;return finish(o,name,mat)

box('Canvas_main_body',(0,.03,.867),(.68,.79,.405),canvas,.085,5)
box('Leather_base',(0,.03,.692),(.685,.76,.065),leather,.032,3)
# A concave padded saddle closes the gap between a flat pack and a round back.
verts=[];faces=[];nx,ny=20,24
for layer in range(2):
    for iy in range(ny+1):
        y=-.335+iy*.73/ny
        for ix in range(nx+1):
            x=-.315+ix*.63/nx
            # A smooth padded surface follows the torso envelope; the skinning
            # transfer below handles the body's changing pose.
            bottom=.36+(.286+.024*(y+.335)/.73)*math.sqrt(max(.05,1-(x/.390)**2))+.018
            verts.append((x,y,.697 if layer else min(.694,bottom)))
stride=(nx+1)*(ny+1)
for iy in range(ny):
    for ix in range(nx):
        k=iy*(nx+1)+ix
        faces.extend([(k,k+nx+1,k+nx+2,k+1),(k+stride,k+stride+1,k+stride+nx+2,k+stride+nx+1)])
outline=list(range(nx+1))+[j*(nx+1)+nx for j in range(1,ny+1)]+[ny*(nx+1)+i for i in range(nx-1,-1,-1)]+[j*(nx+1) for j in range(ny-1,0,-1)]
for i,k in enumerate(outline):
    k2=outline[(i+1)%len(outline)];faces.append((k,k2,k2+stride,k+stride))
mesh_obj('Contoured_leather_saddle',verts,faces,leather)
# A continuous canvas flap bends over the top and closes toward the tail.
profile=[(.407,.955),(.408,1.015),(.382,1.070),(.334,1.102),(.24,1.111),(.1,1.114),(-.06,1.114),(-.22,1.111),(-.306,1.092),(-.365,1.050),(-.397,.996),(-.403,.945),(-.400,.913)]
ribbon('Canvas_folded_flap',profile,0,.665,canvas,.018)
for x in [-.329,.329]:tube('Flap_leather_piping',[(x,y,z+.009) for y,z in profile],.010,leather,7)
tube('Flap_hem',[(-.329,-.404,.913),(-.2,-.408,.905),(0,-.410,.902),(.2,-.408,.905),(.329,-.404,.913)],.011,leather,7)
# Leather closure straps follow the real curved flap rather than float above it.
strap_profile=[(.425,.73),(.428,.92),(.427,1.02),(.387,1.092),(.32,1.128),(.16,1.137),(-.05,1.137),(-.24,1.132),(-.335,1.100),(-.400,1.040),(-.430,.97),(-.430,.85),(-.422,.758)]
for x in [-.205,.205]:
    ribbon('Closure_strap',strap_profile,x,.067,leather,.013)
    buckle('Closure_buckle',(x,-.449,.94),.087,.109)
    for z in [.786,.813,.840]:sphere('Punched_hole',(x,-.435,z),(.0037,.002,.0037),ink)
    sphere('Closure_rivet',(x,-.440,1.009),(.007,.003,.007),iron)
    # Stitch dashes follow both edges over the roof and down the rear face.
    for a,b in zip(strap_profile,strap_profile[1:]):
        av,bv=Vector(a),Vector(b);distance=(bv-av).length
        steps=max(1,int(distance/.026))
        for j in range(steps):
            p=av.lerp(bv,(j+.12)/steps);q=av.lerp(bv,(j+.57)/steps)
            for edge in [-.025,.025]:tube('Closure_stitch',[(x+edge,p.x-.003,p.y+.009),(x+edge,q.x-.003,q.y+.009)],.0018,thread,4)
# Side pouch, with a distinct flap and seam.
box('Side_canvas_pocket',(-.369,.06,.85),(.104,.32,.22),canvas,.037,4)
box('Side_leather_flap',(-.419,.06,.935),(.032,.30,.078),leather,.024,3)
buckle('Side_pocket_buckle',(-.442,.06,.891),.065,.075,'YZ')
# A raised, flattened leather handle on top.
handle=[]
for t in np.linspace(0,math.pi,17):handle.append((.135*math.cos(t),.025,1.13+.093*math.sin(t)))
tube('Carry_handle',handle,.021,leather,8)
for x in [-.14,.14]:sphere('Handle_rivet',(x,.025,1.142),(.009,.009,.004),brass)

# Fit harness loops to the actual torso cross-section, leaving limbs free.
def body_ring(y,angle):
    # measured radial envelope, excluding the four leg groups
    near=body_points[abs(body_points[:,1]-y)<.035]
    centre=.37;dx=np.cos(angle);dz=np.sin(angle)
    candidates=near[(near[:,2]>.07)&(abs(near[:,0])<.46)]
    da=np.arctan2(candidates[:,2]-centre,candidates[:,0])
    delta=np.abs(np.arctan2(np.sin(da-angle),np.cos(da-angle)))
    sector=candidates[delta<.10]
    if len(sector):radius=np.max(np.sqrt(sector[:,0]**2+(sector[:,2]-centre)**2))+.017
    else:radius=1/math.sqrt((dx/.362)**2+(dz/.303)**2)+.017
    return Vector((radius*dx,y,centre+radius*dz))

for y in [-.285,.35]:
    n=96;verts=[]
    ring=[body_ring(y,TAU*i/n) for i in range(n)]
    ring=[sum((ring[(i+j)%n]*math.exp(-j*j/8) for j in range(-6,7)),Vector())/sum(math.exp(-j*j/8) for j in range(-6,7)) for i in range(n)]
    for i in range(n):
        p=ring[i]
        verts.extend([tuple(p+Vector((0,-.036,0))),tuple(p+Vector((0,.036,0)))])
    o=mesh_obj('Fitted_torso_harness',verts,[(2*i,2*i+1,2*((i+1)%n)+1,2*((i+1)%n)) for i in range(n)],leather)
    # Blend into the root like the underlying torso as the character curls.
    root_group=o.vertex_groups.new(name='root')
    weight=.19 if y<0 else .035
    o.vertex_groups['spine'].add(list(range(len(o.data.vertices))),1-weight,'REPLACE');root_group.add(list(range(len(o.data.vertices))),weight,'REPLACE')
    mod=o.modifiers.new('Harness thickness','SOLIDIFY');mod.thickness=.009
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    for i in range(0,n,3):
        for edge in [-.026,.026]:
            p=ring[i].copy();q=ring[(i+1)%n].copy()
            for v in [p,q]:
                outward=Vector((v.x,0,v.z-.37)).normalized()*.007
                v+=outward;v.y+=edge
            tube('Harness_stitch',[p,q],.0019,thread,4)
    for sign in [-1,1]:
        buckle('Harness_adjuster',(ring[0 if sign>0 else n//2].x+sign*.008,y,.365),.092,.108,'YZ')
        # Visible connector tabs run from the pack to the harness shoulder.
        path=[(sign*.27,.719),(sign*.31,.676),(sign*.348,.615),(sign*.37,.54),(sign*.38,.47)]
        vv=[]
        for x,z in path:vv.extend([(x,y-.031,z),(x,y+.031,z)])
        anchor=mesh_obj('Harness_anchor',vv,[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(path)-1)],leather)
        mod=anchor.modifiers.new('Leather tab thickness','SOLIDIFY');mod.thickness=.012
        bpy.context.view_layer.objects.active=anchor;bpy.ops.object.modifier_apply(modifier=mod.name)

# Parchment tube: open end and a visible spiral, not capped solid cylinders.
verts=[];faces=[];steps=40;xs=.467;zs=1.031
for radius,y in [(.069,-.13),(.069,.25),(.052,-.13),(.052,.25)]:
    for i in range(steps):
        a=TAU*i/steps;verts.append((xs+radius*math.cos(a),y,zs+radius*math.sin(a)))
for i in range(steps):
    j=(i+1)%steps
    faces += [(i,j,steps+j,steps+i),(2*steps+i,3*steps+i,3*steps+j,2*steps+j),(i,2*steps+i,2*steps+j,j),(steps+i,steps+j,3*steps+j,3*steps+i)]
mesh_obj('Rolled_parchment',verts,faces,paper)
for y in [-.131,.251]:
    points=[]
    for a in np.linspace(0,TAU*1.7,75):
        r=.020+.047*a/(TAU*1.7);points.append((xs+r*math.cos(a),y,zs+r*math.sin(a)))
    tube('Parchment_spiral',points,.003,paper,5)
for y in [-.025,.14]:
    ring=[(xs+.075*math.cos(a),y,zs+.075*math.sin(a)) for a in np.linspace(0,TAU,40,endpoint=False)]
    tube('Scroll_binding',ring,.012,leather,7,True)
for offset in [0,.09,.18]:
    route=[]
    for t in np.linspace(0,1,12):
        a=.45+.45*math.sin(t*6+offset*8);route.append((xs+.0705*math.cos(a),-.1+offset+t*.12,zs+.0705*math.sin(a)))
    tube('Map_route_ink',route,.0019,ink,4)
# Compass hangs behind the scroll where it reads from the gameplay camera.
cx,cy,cz=.461,-.218,.839
for i in range(3):
    pts=[(cx+.016*math.cos(a),cy+(0 if i%2==0 else .006*math.sin(a)),.963-i*.027+.021*math.sin(a)) for a in np.linspace(0,TAU,16,endpoint=False)]
    tube('Compass_link',pts,.0045,brass,5,True)
def disk(name,radius,depth,loc,mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=depth,location=loc,rotation=(math.pi/2,0,0))
    return finish(bpy.context.object,name,mat)
disk('Compass_case',.102,.021,(cx,cy,cz),brass)
disk('Compass_recess',.086,.023,(cx,cy-.001,cz),leather)
tube('Compass_rim',[(cx+.095*math.cos(a),cy-.016,cz+.095*math.sin(a)) for a in np.linspace(0,TAU,48,endpoint=False)],.005,brass,6,True)
for i in range(8):
    a=TAU*i/8;r=.077 if i%2==0 else .058
    tip=Vector((cx+r*math.sin(a),cy-.029,cz+r*math.cos(a)))
    centre=Vector((cx,cy-.039,cz));left=Vector((cx+.016*math.sin(a-.9),cy-.018,cz+.016*math.cos(a-.9)));right=Vector((cx+.016*math.sin(a+.9),cy-.018,cz+.016*math.cos(a+.9)))
    mesh_obj('Compass_rose',[tuple(centre),tuple(tip),tuple(left),tuple(right)],[(0,2,1),(0,1,3)],brass)
sphere('Compass_pin',(cx,cy-.042,cz),(.007,.004,.007),brass)

# Low-profile revision: retain the footprint but wrap the bag over the torso.
# Hardware is translated as a rigid component so buckles, scroll and compass
# keep their original proportions instead of being squashed with the canvas.
def back_surface(x,y):
    t=max(0,min(1,(y+.335)/.73))
    return .36+(.286+.024*t)*math.sqrt(max(.05,1-(min(abs(x),.335)/.390)**2))+.018
def fitted_height(x,y,z):
    return back_surface(x,y)+.024+(z-.697)*.40
old_heights={}
bag_before=[];bag_after=[]
for o in parts:
    if o.name.startswith(('Canvas_main_body','Leather_base','Side_canvas_pocket','Side_leather_flap')):
        # Add only the broad-face spans needed to describe the new curvature.
        bm=bmesh.new();bm.from_mesh(o.data)
        long_edges=[e for e in bm.edges if e.calc_length()>.16]
        bmesh.ops.subdivide_edges(bm,edges=long_edges,cuts=2,use_grid_fill=True)
        bm.to_mesh(o.data);bm.free()
    old_heights[o.name]=[v.co.z for v in o.data.vertices]
    if o.name.startswith(('Fitted_torso_harness','Harness_stitch','Harness_adjuster')):
        continue
    rigid=o.name.startswith(('Closure_buckle','Closure_rivet','Punched_hole','Side_pocket_buckle','Rolled_parchment','Parchment_spiral','Scroll_binding','Map_route_ink','Compass_'))
    if rigid:
        # All compass parts share one pivot; all scroll parts share another.
        if o.name.startswith('Compass_') and not o.name.startswith('Compass_link'):
            centre=Vector((cx,cy,cz))
        elif o.name.startswith(('Rolled_parchment','Parchment_spiral','Scroll_binding','Map_route_ink')):
            centre=Vector((xs,.06,zs))
        elif o.name.startswith('Compass_link'):
            # Shorten the small attachment chain with the surrounding pack.
            rigid=False
        else:centre=sum((v.co for v in o.data.vertices),Vector())/len(o.data.vertices)
        if rigid:
            offset=fitted_height(*centre)-centre.z
            for v in o.data.vertices:v.co.z+=offset
    if not rigid:
        for v in o.data.vertices:
            x,y,z=v.co
            if o.name.startswith('Contoured_leather_saddle'):
                bottom=.36+(.286+.024*(y+.335)/.73)*math.sqrt(max(.05,1-(x/.390)**2))+.018
                blend=max(0,min(1,(z-bottom)/max(.001,.697-bottom)))
                v.co.z=back_surface(x,y)+.024*blend
            elif o.name.startswith('Harness_anchor'):
                blend=max(0,min(1,(z-.47)/(.719-.47)))
                v.co.z=z+(fitted_height(x,y,.719)-.719)*blend
            else:v.co.z=fitted_height(x,y,z)
    if o.name.startswith('Canvas_main_body'):
        bag_before=old_heights[o.name];bag_after=[v.co.z for v in o.data.vertices]
    o.data.update()
    # Recompute normals for the curved canvas instead of retaining box normals.
    o.data.normals_split_custom_set_from_vertices([tuple(v.normal) for v in o.data.vertices])

# Transfer the underlying skin to flexible harness parts. Constant weights were
# insufficient around a bending torso and let the rear strap disappear in skin.
tree=KDTree(len(body.data.vertices))
for v in body.data.vertices:tree.insert(body.matrix_world@v.co,v.index)
tree.balance()
body_groups={g.index:g.name for g in body.vertex_groups}
for o in parts:
    if not o.name.startswith(('Fitted_torso_harness','Harness_stitch','Harness_adjuster','Harness_anchor','Contoured_leather_saddle')):continue
    for v in o.data.vertices:
        weights={}
        neighbours=tree.find_n(v.co,3)
        norm=sum(1/max(d,.002)**2 for _,_,d in neighbours)
        for _,index,d in neighbours:
            fraction=(1/max(d,.002)**2)/norm
            for g in body.data.vertices[index].groups:
                name=body_groups[g.group];weights[name]=weights.get(name,0)+g.weight*fraction
        blend=1
        if o.name.startswith('Contoured_leather_saddle'):
            blend=0 if old_heights[o.name][v.index]>.696 else 1
        elif o.name.startswith('Harness_anchor'):
            blend=max(0,min(1,(.719-old_heights[o.name][v.index])/.15))
        weights={k:w*blend for k,w in weights.items()}
        weights['spine']=weights.get('spine',0)+(1-blend)
        weights=sorted(weights.items(),key=lambda row:row[1],reverse=True)[:4]
        total=sum(w for _,w in weights)
        for group in o.vertex_groups:group.remove([v.index])
        for name,weight in weights:
            group=o.vertex_groups.get(name) or o.vertex_groups.new(name=name)
            group.add([v.index],weight/total,'REPLACE')
# Join all pieces; material groups remain separate surfaces, one shared skin.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join();pack=bpy.context.object;pack.name='ExplorerBackpack'
mod=pack.modifiers.new('Existing hero skeleton','ARMATURE');mod.object=rig
pack.parent=rig
pack.data.validate();pack.data.update()
# Remove empty duplicate material slots and assign consistent texture filtering on import.
bpy.ops.object.material_slot_remove_unused()
pack.data.calc_loop_triangles()
stats={'triangles':len(pack.data.loop_triangles),'vertices':len(pack.data.vertices),'materials':len(pack.data.materials),'bone_names':[g.name for g in pack.vertex_groups], 'hero_sha256':hashlib.sha256((PROJECT/'assets/character/axolotl/axolotl.glb').read_bytes()).hexdigest()}
stats['profile_revision']={'canvas_depth_scale':.40,'depth_reduction_percent':60,'saddle_pad_thickness':.024,'original_body_z_bounds':[min(bag_before),max(bag_before)],'fitted_body_z_bounds':[min(bag_after),max(bag_after)],'footprint_changed':False,'hardware_proportions_preserved':True}
assert stats['triangles']<20000,stats
for o in hero:o.hide_set(True)
bpy.ops.object.select_all(action='DESELECT');pack.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=pack
bpy.ops.export_scene.gltf(filepath=str(DEST/'explorer_backpack.glb'),export_format='GLB',use_selection=True,export_animations=False,export_apply=False,export_skins=True,export_yup=True,export_materials='EXPORT',export_image_format='AUTO')
(DEST/'build_report.json').write_text(json.dumps(stats,indent=2))
for o in hero:
    if o.name!='Icosphere':o.hide_set(False)
# Save an editable source with the actual hero as a fitting reference only.
bpy.ops.wm.save_as_mainfile(filepath=str(DEST/'explorer_backpack.blend'))
print('BACKPACK BUILD',json.dumps(stats))
