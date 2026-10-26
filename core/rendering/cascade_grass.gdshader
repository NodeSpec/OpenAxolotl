shader_type spatial;
render_mode cull_disabled,diffuse_burley;
varying vec4 variation;
void vertex(){
 vec3 root=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 variation=vec4(vec3(0.84+fract(sin(dot(root.xz,vec2(0.71,0.93)))*4375.3)*0.24),1.0);
 float wind=sin(TIME*1.5+root.x*0.48+root.z*0.31)*0.045;
 VERTEX.x+=wind*UV.y*UV.y;
 VERTEX.z+=wind*0.65*UV.y*UV.y;
}
void fragment(){
 float ridge=exp(-abs(UV.x-0.5)*24.0)*0.06;
 ALBEDO=(mix(vec3(0.075,0.18,0.027),vec3(0.32,0.49,0.095),UV.y)+vec3(ridge*0.5,ridge,ridge*0.15))*variation.rgb;
 ROUGHNESS=0.92;
 BACKLIGHT=vec3(0.12,0.20,0.055);
}
