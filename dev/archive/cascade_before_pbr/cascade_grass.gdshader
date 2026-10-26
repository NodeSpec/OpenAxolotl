shader_type spatial;
render_mode cull_disabled,diffuse_burley;
varying vec4 variation;
void vertex(){
 variation=vec4(vec3(mix(0.8,1.15,INSTANCE_CUSTOM.y)),1.0);
 vec3 root=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float wind=sin(TIME*1.5+root.x*0.48+root.z*0.31)*0.045;
 VERTEX.x+=wind*UV.y*UV.y;
 VERTEX.z+=wind*0.65*UV.y*UV.y;
}
void fragment(){
 ALBEDO=mix(vec3(0.15,0.32,0.085),vec3(0.40,0.61,0.17),UV.y)*variation.rgb;
 ROUGHNESS=0.92;
 BACKLIGHT=vec3(0.12,0.20,0.055);
}
