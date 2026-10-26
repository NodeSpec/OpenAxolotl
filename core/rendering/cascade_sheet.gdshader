shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}
float water_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash21(cell),hash21(cell+vec2(1,0)),f.x),
               mix(hash21(cell+vec2(0,1)),hash21(cell+vec2(1,1)),f.x),f.y);
}
void fragment() {
    vec2 flow = vec2(UV.x*9.0,UV.y*3.5-TIME*1.7);
    float broad = water_noise(flow);
    float detail = water_noise(flow*2.3+vec2(11.2,-TIME*0.8));
    float veil = smoothstep(0.18,0.86,broad*0.65+detail*0.35);
    float foam = smoothstep(0.48,0.82,water_noise(vec2(UV.x*24.0,UV.y*11.0-TIME*4.2)));
    float bend = (broad-0.5)*0.10;
    float side = smoothstep(0.0,0.20,UV.x+bend)*smoothstep(0.0,0.20,1.0-UV.x-bend);
    float ends = smoothstep(0.0,0.045,UV.y)*smoothstep(0.0,0.13,1.0-UV.y);
    ALBEDO = mix(vec3(0.22,0.54,0.60),vec3(0.85,0.96,0.98),veil*0.75+foam*0.20);
    EMISSION = vec3(0.045,0.085,0.10)*(veil+foam*0.3);
    ROUGHNESS = 0.28;
    ALPHA = side*ends*(0.32+veil*0.45+foam*0.14);
}
