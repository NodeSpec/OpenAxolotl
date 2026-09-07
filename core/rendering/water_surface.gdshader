// THE SHARED WATER SURFACE (core/rendering/water_surface.tres wears this).
//
// Water is intentionally texture-free and MEDIUM-safe: no screen texture,
// refraction pass or binary normal map is required to make the default build
// read well. Instead, two analytic wave bands create three layers of detail:
//
//   * broad crossed ripples establish direction and motion;
//   * a finer counter-flow breaks the repeating sine pattern at gameplay
//     distance;
//   * the same functions provide an analytic surface normal, so Fresnel and
//     sparkle react to the apparent ripple slope instead of to a perfectly
//     flat plane.
//
// The shader stays UNSHADED. Water is a transparent gameplay volume that the
// camera regularly looks through; lighting both faces of that slab makes the
// colour stack with camera angle and hides the axolotl. The shared world rig
// supplies the environment look around it while this surface supplies motion,
// readability and depth cues.

shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec3 deep_tint: source_color = vec3(0.19, 0.49, 0.66);
uniform vec3 shallow_tint: source_color = vec3(0.35, 0.72, 0.78);
uniform vec3 foam_tint: source_color = vec3(0.76, 0.94, 0.94);
uniform vec3 sparkle_tint: source_color = vec3(0.94, 0.99, 1.0);

// Kept deliberately translucent for narrow rivers as well as wide lagoons.
uniform float alpha_facing: hint_range(0.0, 1.0) = 0.18;
uniform float alpha_grazing: hint_range(0.0, 1.0) = 0.34;

uniform float ripple_scale: hint_range(0.05, 4.0) = 0.55;
uniform float ripple_speed: hint_range(0.0, 4.0) = 0.8;
uniform float micro_ripple_scale: hint_range(0.1, 12.0) = 2.65;
uniform float micro_ripple_strength: hint_range(0.0, 1.0) = 0.24;
uniform float normal_strength: hint_range(0.0, 1.0) = 0.22;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// WaterVolume meshes are axis-aligned boxes in the shipped worlds. This
	// gives us enough information to perturb only the horizontal surface and
	// leave the transparent side walls visually quiet.
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 flow = world_position.xz * ripple_scale;
	float t = TIME * ripple_speed;

	float a = flow.x * 1.70 + t * 1.35;
	float b = flow.y * 2.30 - t * 1.10;
	float c = (flow.x + flow.y) * 1.10 + t * 0.70;
	float broad = sin(a) + sin(b) + sin(c);

	// A higher-frequency counter-flow is intentionally low amplitude. Its job
	// is not to make busy water; it keeps the broad bands from reading like a
	// moving procedural texture when the camera follows parallel to one axis.
	vec2 micro_flow = world_position.xz * micro_ripple_scale;
	float ma = micro_flow.x * 1.35 - t * 1.85;
	float mb = micro_flow.y * 1.75 + t * 1.55;
	float micro = (sin(ma) + sin(mb)) * 0.5;

	float combined = broad + micro * micro_ripple_strength;
	float crest = smoothstep(0.35, 2.35, combined);
	float foam = smoothstep(1.95, 2.75, combined) * (0.45 + 0.55 * max(micro, 0.0));
	float glint = smoothstep(2.42, 2.92, broad) * smoothstep(0.05, 0.85, micro);

	// Analytic slope of the same waves. This costs a few cosines but avoids a
	// normal texture and, more importantly, makes the Fresnel move WITH the
	// ripples. Only the top/bottom faces use it; volume side walls keep their
	// authored normal so a river does not shimmer like a glass box.
	float dx = ripple_scale * (
		1.70 * cos(a) + 1.10 * cos(c));
	float dz = ripple_scale * (
		2.30 * cos(b) + 1.10 * cos(c));
	dx += micro_ripple_strength * micro_ripple_scale * 0.675 * cos(ma);
	dz += micro_ripple_strength * micro_ripple_scale * 0.875 * cos(mb);

	float horizontal_face = smoothstep(0.65, 0.92, abs(world_normal.y));
	vec3 ripple_world_normal = normalize(vec3(
		-dx * normal_strength, sign(world_normal.y), -dz * normal_strength));
	vec3 display_world_normal = normalize(mix(world_normal, ripple_world_normal,
		horizontal_face));
	vec3 display_view_normal = normalize((VIEW_MATRIX * vec4(display_world_normal, 0.0)).xyz);

	float facing = clamp(dot(display_view_normal, normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 2.15);

	vec3 tint = mix(deep_tint, shallow_tint,
		clamp(crest * 0.55 + fresnel * 0.28, 0.0, 1.0));
	// Foam here is CREST foam, not shoreline foam: it supplies small bright
	// breakup without pretending we know scene depth in the MEDIUM renderer.
	tint = mix(tint, foam_tint, foam * 0.22 * horizontal_face);
	tint = mix(tint, sparkle_tint, glint * 0.58 * horizontal_face);

	ALBEDO = tint;
	ALPHA = clamp(
		mix(alpha_facing, alpha_grazing, fresnel)
		+ foam * 0.035 * horizontal_face
		+ glint * 0.10 * horizontal_face,
		0.0, 0.62);
}
