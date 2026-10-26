shader_type spatial;
uniform vec4 tint : source_color = vec4(0.68, 0.49, 0.27, 1.0);
varying vec3 world_pos;
float hash(vec3 p) { p=fract(p*0.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float grain=noise(world_pos*8.0), patch=noise(world_pos*1.5);
 float strata=pow(abs(sin(world_pos.y*12.0+noise(world_pos*2.2)*4.0)),16.0);
 ALBEDO=tint.rgb * (0.79 + patch*0.33 + grain*0.12 - strata*0.055);
 ROUGHNESS=0.83;
}
