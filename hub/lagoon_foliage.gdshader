shader_type spatial;
render_mode cull_disabled;
varying vec4 leaf_color;
void vertex() {
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x += sin(TIME*1.35+p.x*0.8+p.z*0.7)*0.045*UV.y;
 VERTEX.z += cos(TIME*1.1+p.z)*0.025*UV.y;
 leaf_color=COLOR;
}
void fragment() {
 float vein=exp(-abs(UV.x-0.5)*95.0);
 float ribs=pow(abs(sin(UV.y*48.0+abs(UV.x-0.5)*13.0)),14.0)*0.06;
 ALBEDO=leaf_color.rgb*(0.82+0.18*sin(UV.x*3.14159))+vec3(0.10,0.12,0.025)*vein-ribs;
 ROUGHNESS=0.46;
 SPECULAR=0.32;
 BACKLIGHT=leaf_color.rgb*0.3;
}
