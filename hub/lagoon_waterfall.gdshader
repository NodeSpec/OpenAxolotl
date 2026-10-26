shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform sampler2D color_map : source_color;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D roughness_map;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
    vec3 color = texture(color_map,UV).rgb;
    float water = smoothstep(0.06,0.20,color.b-color.r)*smoothstep(0.03,0.16,color.g-color.r);
    water *= 1.0-smoothstep(0.5,0.7,local_point.y);
    float streak = pow(0.5+0.5*sin(local_point.z*48.0-TIME*7.0+sin(local_point.x*31.0)),9.0);
    ALBEDO = mix(color,mix(color,vec3(0.83,0.96,1.0),streak*0.38),water);
    NORMAL_MAP = texture(normal_map,UV).rgb;
    ROUGHNESS = mix(texture(roughness_map,UV).g,0.10,water);
    METALLIC = 0.0;
    SPECULAR = 0.5;
}
