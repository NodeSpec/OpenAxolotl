shader_type spatial;
render_mode diffuse_burley;
uniform vec4 rock_tint: source_color = vec4(0.65,0.61,0.50,1.0);
uniform vec4 grass_tint: source_color = vec4(0.30,0.49,0.21,1.0);
uniform vec4 sand_tint: source_color = vec4(0.87,0.80,0.62,1.0);
uniform float surface_kind = 1.0;
uniform float water_level = 0.0;
varying vec3 terrain_position;
varying vec3 terrain_normal;
float hash(vec3 p){ p=fract(p*0.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z); }
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){terrain_position=VERTEX;terrain_normal=NORMAL;}
void fragment(){
 float macro=noise(terrain_position*0.21);
 float detail=noise(terrain_position*6.5);
 float up=smoothstep(0.62,0.94,terrain_normal.y);
 float moss=smoothstep(0.29,0.64,macro+noise(terrain_position*1.1)*0.17);
 float weather=noise(terrain_position*1.25);
 float flecks=noise(terrain_position*18.0);
 vec3 stone=rock_tint.rgb*(0.66+macro*0.43+weather*0.18+detail*0.13);
 float band=sin(terrain_position.y*2.2+noise(terrain_position*0.65)*4.0);
 stone*=1.0-smoothstep(0.90,1.0,band)*0.13;
 stone*=0.95+flecks*0.1;
 float lichen=smoothstep(0.58,0.77,macro+weather*0.16)*(1.0-up)*0.28;
 stone=mix(stone,grass_tint.rgb*0.68,lichen);
 vec3 sand=sand_tint.rgb*(0.92+macro*0.11+detail*0.045);
 vec3 turf=grass_tint.rgb*(0.88+macro*0.22+detail*0.07);
 vec3 ground=stone;
 if(surface_kind<0.5){ground=sand;}
 else if(surface_kind<1.5){ground=mix(stone,mix(sand,turf,moss),up);}
 else {ground=mix(stone,turf,up*moss*0.55);}
 float wet=(1.0-smoothstep(water_level-0.1,water_level+0.24,terrain_position.y))*0.19;
 ALBEDO=ground*(1.0-wet);
 ROUGHNESS=0.87-wet*1.7;
 SPECULAR=0.18;
}
