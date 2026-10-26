shader_type spatial;
render_mode diffuse_burley, cull_disabled;

uniform sampler2D atlas_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D atlas_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D atlas_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grain_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grain_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.45,0.66,0.81,1.0);
uniform vec4 algae_tint : source_color = vec4(0.24,0.63,0.65,1.0);
uniform float detail_scale = 0.60;
varying vec3 world_p;
varying vec3 world_n;
varying vec3 world_t;
varying vec3 world_b;
varying vec3 view_x;
varying vec3 view_y;
varying vec3 view_z;

float hash(vec3 p){p=fract(p*0.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}

vec3 triplanar(sampler2D tex,vec3 p,vec3 weights,vec3 signs){
 return texture(tex,p.zy*vec2(-signs.x,1)).rgb*weights.x
      + texture(tex,p.xz*vec2(1,-signs.y)).rgb*weights.y
      + texture(tex,p.xy*vec2(signs.z,1)).rgb*weights.z;
}
void vertex(){
 world_p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 world_n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 world_t=normalize(MODEL_NORMAL_MATRIX*TANGENT);
 world_b=normalize(MODEL_NORMAL_MATRIX*BINORMAL);
 view_x=(VIEW_MATRIX*vec4(1,0,0,0)).xyz;
 view_y=(VIEW_MATRIX*vec4(0,1,0,0)).xyz;
 view_z=(VIEW_MATRIX*vec4(0,0,1,0)).xyz;
}
void fragment(){
 vec3 original=texture(atlas_color,UV).rgb;
 // This particular atlas separates blue-grey stone from green leaves,
 // purple/orange coral and bright cyan accents. Classify in perceptual colour.
 vec3 hue=pow(max(original,vec3(0.00001)),vec3(1.0/2.2));
 float leaves=smoothstep(0.012,0.075,hue.g-max(hue.r,hue.b));
 float flowers=smoothstep(0.025,0.12,hue.r-hue.g);
 float cyan=smoothstep(0.15,0.45,min(hue.g,hue.b)-hue.r)*smoothstep(0.45,0.70,max(hue.g,hue.b));
 float accent=max(leaves,max(flowers,cyan));
 vec3 base=normalize(world_n)*(FRONT_FACING?1.0:-1.0);
 vec3 signs=sign(base+vec3(0.00001));
 vec3 weights=pow(abs(base),vec3(5));weights/=max(dot(weights,vec3(1)),0.00001);
 vec3 p=world_p*detail_scale;
 float moss=0.10+smoothstep(0.30,0.70,noise(world_p*0.55))*0.38+max(base.y,0.0)*0.10;
 vec3 mineral=triplanar(stone_color,p,weights,signs);
 vec3 algae=triplanar(moss_color,p*0.75,weights,signs);
 vec3 grain=triplanar(grain_color,p*2.2,weights,signs);
 // Preserve the blue reef identity while deriving surface detail from actual
 // tiled maps, independently of the enlarged model's crowded colour atlas.
 float mineral_value=dot(mineral,vec3(0.2126,0.7152,0.0722));
 float algae_value=dot(algae,vec3(0.2126,0.7152,0.0722));
 float grain_value=dot(grain,vec3(0.2126,0.7152,0.0722));
 float deposits=smoothstep(0.28,0.72,noise(world_p*0.85+vec3(19)))*(0.10+0.18*max(base.y,0.0));
 vec3 rock=mix(mineral_value*stone_tint.rgb*2.40,algae_value*algae_tint.rgb*2.40,moss);
 rock=mix(rock,grain_value*stone_tint.rgb*2.65,deposits);
 vec3 arm=triplanar(stone_arm,p,weights,signs);
 vec3 x=texture(stone_normal,p.zy*vec2(-signs.x,1)).xyz*2.0-1.0;
 vec3 y=texture(stone_normal,p.xz*vec2(1,-signs.y)).xyz*2.0-1.0;
 vec3 z=texture(stone_normal,p.xy*vec2(signs.z,1)).xyz*2.0-1.0;
 vec3 rock_n=normalize(base+(vec3(0,x.y,-x.x*signs.x)*weights.x+vec3(y.x,0,-y.y*signs.y)*weights.y+vec3(z.x*signs.z,z.y,0)*weights.z)*0.52);
 vec3 gx=texture(grain_normal,p.zy*2.2*vec2(-signs.x,1)).xyz*2.0-1.0;
 vec3 gy=texture(grain_normal,p.xz*2.2*vec2(1,-signs.y)).xyz*2.0-1.0;
 vec3 gz=texture(grain_normal,p.xy*2.2*vec2(signs.z,1)).xyz*2.0-1.0;
 rock_n=normalize(rock_n+(vec3(0,gx.y,-gx.x*signs.x)*weights.x+vec3(gy.x,0,-gy.y*signs.y)*weights.y+vec3(gz.x*signs.z,gz.y,0)*weights.z)*(0.12+deposits*0.35));
 vec3 plant_bump=texture(atlas_normal,UV).xyz*2.0-1.0;
 vec3 plant_n=normalize(base+(world_t*plant_bump.x+world_b*plant_bump.y)*0.22);
 vec3 normal=normalize(mix(rock_n,plant_n,accent));
 ALBEDO=mix(rock,original,accent);
 NORMAL=normalize(view_x*normal.x+view_y*normal.y+view_z*normal.z);
 ROUGHNESS=clamp(mix(arm.g-moss*0.10,texture(atlas_roughness,UV).g,accent),0.58,0.94);
 AO=mix(mix(1.0,arm.r,0.3),1.0,accent);
 AO_LIGHT_AFFECT=0.10;
 SPECULAR=0.18;
}
