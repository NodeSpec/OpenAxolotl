shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D rock_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D turf_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D turf_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D turf_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 rock_tint : source_color = vec4(1.0);
uniform vec4 grass_tint : source_color = vec4(0.65,0.90,0.48,1.0);
uniform vec4 sand_tint : source_color = vec4(1.0,0.97,0.85,1.0);
uniform float surface_kind = 1.0;
uniform float water_level = 0.0;
uniform float gravel_share = 0.32;
uniform float rock_scale = 0.20;
uniform bool depth_blend_enabled = false;
varying vec3 p;
varying vec3 n;
varying vec4 mask;
varying vec3 view_x;
varying vec3 view_y;
varying vec3 view_z;
float hash(vec3 q){q=fract(q*0.1031);q+=dot(q,q.yzx+33.33);return fract((q.x+q.y)*q.z);}
float noise(vec3 q){vec3 i=floor(q),f=fract(q);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
vec3 tri(sampler2D tex,vec3 q,vec3 w,vec3 s){return texture(tex,q.zy*vec2(-s.x,1)).rgb*w.x+texture(tex,q.xz*vec2(1,-s.y)).rgb*w.y+texture(tex,q.xy*vec2(s.z,1)).rgb*w.z;}
vec3 rock_bump(vec3 q,vec3 w,vec3 s,vec3 base){
 vec3 x=texture(rock_normal,q.zy*vec2(-s.x,1)).xyz*2.0-1.0;
 vec3 y=texture(rock_normal,q.xz*vec2(1,-s.y)).xyz*2.0-1.0;
 vec3 z=texture(rock_normal,q.xy*vec2(s.z,1)).xyz*2.0-1.0;
 return normalize(base+(vec3(0,x.y,-x.x*s.x)*w.x+vec3(y.x,0,-y.y*s.y)*w.y+vec3(z.x*s.z,z.y,0)*w.z)*0.80);
}
vec3 top_bump(sampler2D tex,vec2 uv,vec3 base,float strength){vec3 t=texture(tex,uv).xyz*2.0-1.0;return normalize(base+vec3(t.x,0,-t.y)*strength);}
void vertex(){
 p=VERTEX; n=NORMAL; mask=COLOR;
 view_x=(MODELVIEW_MATRIX*vec4(1,0,0,0)).xyz;
 view_y=(MODELVIEW_MATRIX*vec4(0,1,0,0)).xyz;
 view_z=(MODELVIEW_MATRIX*vec4(0,0,1,0)).xyz;
}
void fragment(){
 vec3 base=normalize(n),s=sign(base+vec3(0.00001));
 vec3 w=pow(abs(base),vec3(5));w/=max(dot(w,vec3(1)),0.00001);
 float macro=noise(p*0.16),patch=noise(p*0.54);
 float up=smoothstep(0.48,0.93,base.y);
 float wet=1.0-smoothstep(water_level-0.10,water_level+0.30,p.y);
 // Green stores signed local water depth (-4..4 m); blue stores coverage.
 // They are baked from actual pool planes and the shared sloping chute profile.
 float bed_depth=depth_blend_enabled?max(mask.g*8.0-4.0,0.0):0.0;
 float immersed=depth_blend_enabled?clamp(mask.b,0.0,1.0)*smoothstep(0.025,0.22,bed_depth):0.0;
 float depth_mix=smoothstep(0.20,3.20,bed_depth);
 vec3 color,normal=base;float rough=0.88,ao=1.0;
 if(surface_kind>0.5){
   vec3 q=p*rock_scale;
   vec3 raw=tri(rock_color,q,w,s);
   vec3 arm=tri(rock_arm,q,w,s);
   float luma=dot(raw,vec3(0.2126,0.7152,0.0722));
   color=mix(raw,vec3(luma)*vec3(1.03,1.02,0.96),0.28)*rock_tint.rgb*1.30;
   color*=0.92+macro*0.16;
   normal=rock_bump(q,w,s,base);
   rough=clamp(arm.g,0.65,0.96);ao=mix(1.0,arm.r,0.36);
 }else{color=vec3(0);}
 if(surface_kind<1.5 || up>0.02){
   vec2 uv=p.xz*0.58;
   vec3 sand=texture(sand_color,uv).rgb*sand_tint.rgb*1.18;
   vec3 sand_data=texture(sand_arm,uv).rgb;
   vec3 sand_n=top_bump(sand_normal,uv,base,0.34);
   float gravel=max(wet,immersed)*mix(gravel_share,0.88,depth_mix*immersed)*smoothstep(0.29,0.72,patch);
   vec2 guv=p.xz*0.72;
   sand=mix(sand,texture(gravel_color,guv).rgb*1.30,gravel);
   sand_n=normalize(mix(sand_n,top_bump(gravel_normal,guv,base,0.62),gravel));
   sand_data=mix(sand_data,texture(gravel_arm,guv).rgb,gravel);
   float value=dot(sand,vec3(0.2126,0.7152,0.0722));
   vec3 shallow=sand*vec3(1.05,1.07,1.09);
   vec3 middle=sand*vec3(0.65,0.85,0.96);
   vec3 deep=value*vec3(0.23,0.40,0.53);
   vec3 sediment=mix(shallow,middle,smoothstep(0.15,1.75,bed_depth));
   sediment=mix(sediment,deep,smoothstep(1.10,3.20,bed_depth));
   sand=mix(sand,sediment,immersed);
   if(surface_kind<0.5){color=sand;normal=sand_n;rough=sand_data.g;ao=mix(1.0,sand_data.r,0.26);}
   else{
     float grass=mask.r*(1.0-max(wet,immersed))*smoothstep(0.25,0.52,patch+macro*0.25);
     if(surface_kind>1.5)grass=mask.r*0.72;
     vec2 tuv=p.xz*0.48;
     vec3 turf=texture(turf_color,tuv).rgb;
     float lum=dot(turf,vec3(0.2126,0.7152,0.0722));
     turf=mix(turf,vec3(lum),0.20)*grass_tint.rgb*vec3(1.20,1.65,0.92)*1.10;
     vec3 ground=mix(sand,turf,grass);
     vec3 tn=normalize(mix(sand_n,top_bump(turf_normal,tuv,base,0.40),grass));
     float blend=surface_kind<1.5?up:up*0.70;
     color=mix(color,ground,blend);
     normal=normalize(mix(normal,tn,blend));
     rough=mix(rough,mix(sand_data.g,texture(turf_arm,tuv).g,grass),blend);
   }
 }
 ALBEDO=color*(1.0-wet*0.24);
 NORMAL=normalize(view_x*normal.x+view_y*normal.y+view_z*normal.z);
 ROUGHNESS=clamp(rough-wet*0.20,0.42,0.96);
 AO=ao;AO_LIGHT_AFFECT=0.10;SPECULAR=0.20;
}
