shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform float age = 0.0;
uniform float toes = 4.0;
void fragment() {
    vec2 p=UV*2.0-1.0;
    float pad=1.0-smoothstep(0.5,0.8,length((p-vec2(0,0.15))*vec2(1.7,1.2)));
    float digits=0.0;
    for(int i=0;i<5;i++) {
        if(float(i)<toes) {
            float x=(float(i)/(toes-1.0)-0.5)*1.25;
            digits=max(digits,1.0-smoothstep(0.10,0.23,length(p-vec2(x,-0.46+abs(x)*0.25))));
        }
    }
    ALBEDO=vec3(0.22,0.15,0.085);
    ROUGHNESS=1.0;
    ALPHA=max(pad,digits)*0.20*(1.0-smoothstep(0.4,1.0,age));
}
