// THE SHARED WATER SURFACE (core/rendering/water_surface.tres wears this).
//
// Still UNSHADED, for the same reason the flat tint was: water here is a
// volume the player looks through, and a lit translucent slab changes colour
// with the sun's angle and stacks its shading across the two faces the
// trailing camera sees. What the shader adds over the flat tint is MOTION
// and DEPTH, both computed in world space so every WaterVolume in every
// world reads as the same body of water:
//
//   * a slow two-band shimmer (crossed sines over world x/z, scrolled by
//     TIME) whose crests brighten toward the shallow tint and occasionally
//     spark toward white — read as ripples and caustic glints;
//   * a fresnel-weighted alpha, so looking across the surface reads more
//     solid than looking straight down into it, which is what makes the
//     surface exist without hiding the axolotl beneath it.
//
// Tints stay in the teal family of the old flat tint and the depth fog, so
// nothing about the palette moved — only the stillness.

shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec3 deep_tint: source_color = vec3(0.19, 0.49, 0.66);
uniform vec3 shallow_tint: source_color = vec3(0.35, 0.72, 0.78);
uniform vec3 sparkle_tint: source_color = vec3(0.9, 0.98, 1.0);
// Both lowered when the gorge river went in. The fresnel term is what makes
// a surface exist when you look ACROSS it, and at the old grazing value a
// narrow channel seen from the bank was an opaque slab that hid the swim
// inside it. A wide lagoon looked fine at either value; the channel is what
// the numbers now have to satisfy.
uniform float alpha_facing: hint_range(0.0, 1.0) = 0.20;
uniform float alpha_grazing: hint_range(0.0, 1.0) = 0.33;
uniform float ripple_scale: hint_range(0.05, 4.0) = 0.55;
uniform float ripple_speed: hint_range(0.0, 4.0) = 0.8;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 flow = world_position.xz * ripple_scale;
	float t = TIME * ripple_speed;
	float band = sin(flow.x * 1.7 + t * 1.35)
		+ sin(flow.y * 2.3 - t * 1.1)
		+ sin((flow.x + flow.y) * 1.1 + t * 0.7);
	// band is in [-3, 3]; the top of the range becomes crests, the very
	// top becomes glints.
	float crest = smoothstep(0.4, 2.4, band);
	float glint = smoothstep(2.35, 2.9, band);

	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 2.0);

	vec3 tint = mix(deep_tint, shallow_tint, crest * 0.65 + fresnel * 0.25);
	ALBEDO = mix(tint, sparkle_tint, glint * 0.5);
	ALPHA = mix(alpha_facing, alpha_grazing, fresnel) + glint * 0.12;
}
