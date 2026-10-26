shader_type spatial;
render_mode cull_disabled;

uniform vec3 shallow_color : source_color = vec3(0.045, 0.68, 0.65);
uniform vec3 deep_color : source_color = vec3(0.008, 0.27, 0.39);
uniform bool cascade = false;
varying vec3 world_pos;

float hash(vec2 p) { vec3 q=fract(vec3(p.xyx)*0.1031); q+=dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    if (!cascade) VERTEX.y += 0.017 * sin(world_pos.x * 3.5 + TIME * 1.2) * cos(world_pos.z * 3.0 - TIME);
}
void fragment() {
    vec2 p = world_pos.xz;
    float t = TIME;
    float depth = smoothstep(8.0, 0.0, length((p - vec2(0.0,-2.0)) * vec2(0.65,0.85)));
    vec2 cell_p=p*2.2+vec2(sin(p.y*2.7+t*0.45),cos(p.x*2.5-t*0.4))*0.6;
    vec2 cell=floor(cell_p), local=fract(cell_p);
    float nearest=8.0, second=8.0;
    for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
        vec2 offset=vec2(float(x),float(y));
        vec2 point=vec2(hash(cell+offset),hash(cell+offset+19.0));
        point=0.5+0.4*sin(point*6.283+t*0.45);
        float d=length(offset+point-local);
        if(d<nearest) { second=nearest; nearest=d; } else { second=min(second,d); }
    }
    float caustic=1.0-smoothstep(0.015,0.065,second-nearest);
    vec3 col = mix(shallow_color, deep_color, depth * 0.8);
    col += vec3(0.08,0.16,0.13) * caustic * (1.0-depth*0.94) * smoothstep(0.22,0.6,noise(p*1.3));
    float foam = 0.0;
    if (cascade) {
        vec2 q = UV * vec2(48.0, 4.0) + vec2(0.0, -t * 3.8);
        float streak = noise(vec2(q.x, q.y * 0.24)) * noise(q * 1.5);
        foam = smoothstep(0.16, 0.48, streak) + pow(UV.y, 4.0) * 0.6;
        col = mix(vec3(0.01,0.27,0.4), vec3(0.85,0.97,1.0), clamp(foam,0.0,1.0));
    }
    ALBEDO = col;
    ROUGHNESS = cascade ? 0.26 : 0.19;
    METALLIC = 0.05;
    SPECULAR = 0.85;
    if (!cascade) {
        vec3 normal=normalize(vec3(0.1*sin(p.x*5.0+p.y*9.0+t*1.2),1.0,0.18*cos(p.y*14.0+sin(p.x*5.0)-t*1.4)));
        NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.0)).xyz);
    }
    EMISSION = col * (cascade ? 0.14 : 0.035);
}
