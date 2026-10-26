shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform float age = 0.0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float edge = (1.0-smoothstep(0.55,1.0,abs(p.x))) * (1.0-smoothstep(0.55,1.0,abs(p.y)));
    float grooves = 0.40 + 0.60*pow(0.5+0.5*sin(p.x*29.0+sin(p.y*13.0)*0.4),3.0);
    ALBEDO = vec3(0.28,0.19,0.10);
    ROUGHNESS = 1.0;
    ALPHA = edge*grooves*0.25*(1.0-smoothstep(0.30,1.0,age));
}
