shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D stone_top : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_face : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 placed;
varying vec3 facing;
void vertex() {
    placed = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    facing = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    // Sample the rock's interior, not its silhouette. Mirrored tiling keeps
    // neighbouring samples continuous without painting fake boulders on floors.
    vec2 rock_uv = abs(fract(placed.xz * 0.10) * 2.0 - 1.0) * 0.42 + 0.29;
    vec4 top = texture(stone_top, rock_uv);
    vec4 side_x = texture(cliff_face, vec2(placed.z * 0.12, -placed.y * 0.12));
    vec4 side_z = texture(cliff_face, vec2(placed.x * 0.12, -placed.y * 0.12));
    float side_weight = abs(facing.x) / max(abs(facing.x) + abs(facing.z), 0.001);
    vec4 side = mix(side_z, side_x, side_weight);
    vec3 stone = mix(vec3(0.30,0.34,0.25), top.rgb, top.a);
    vec3 cliff = mix(vec3(0.28,0.31,0.24), side.rgb, side.a);
    ALBEDO = mix(cliff, stone, smoothstep(0.3,0.75,facing.y));
    ROUGHNESS = 0.91;
    SPECULAR = 0.16;
}
