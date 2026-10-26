shader_type spatial;
render_mode cull_disabled;

uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 local_point;

float hash(vec3 p) {
    vec3 q=fract(p*0.1031);
    q+=dot(q,q.yzx+33.33);
    return fract((q.x+q.y)*q.z);
}
float noise(vec3 p) {
    vec3 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    float lower=mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y);
    float upper=mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y);
    return mix(lower,upper,f.z);
}
void vertex() { local_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec3 stone=texture(color_map,UV).rgb;
    vec3 p=local_point;
    float patches=smoothstep(0.64,0.80,noise(p*1.25+vec3(4.2,1.1,3.7)));
    float threads=smoothstep(0.63,0.80,noise(p*22.0));
    float moss=patches*smoothstep(0.30,0.65,noise(p*6.0));
    float damp=0.5+0.5*sin(local_point.z*0.7);
    ALBEDO=mix(stone*vec3(0.64,0.70,0.72),vec3(0.065,0.23,0.085),moss*0.82);
    NORMAL_MAP=texture(normal_map,UV).rgb;
    NORMAL_MAP_DEPTH=0.9;
    ROUGHNESS=mix(clamp(texture(roughness_map,UV).g,0.3,0.9),0.46,damp*0.3);
    SPECULAR=0.45;
    EMISSION=vec3(0.18,0.95,0.42)*moss*threads*1.1*(0.94+0.06*sin(TIME*0.65+local_point.z));
}
