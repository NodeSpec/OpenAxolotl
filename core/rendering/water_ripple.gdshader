shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float age = 0.0;
void fragment() {
    vec2 p=UV*2.0-1.0;
    float radius=length(p);
    float ring=exp(-pow((radius-mix(0.08,0.95,age))*65.0,2.0));
    float broken=0.65+0.35*sin(atan(p.y,p.x)*11.0+age*3.0);
    ALBEDO=vec3(0.8,0.95,1.0);
    ALPHA=ring*broken*(1.0-age)*0.5;
}
