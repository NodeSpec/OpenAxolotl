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
// THE SURFACE NOW ACTUALLY MOVES. Everything above was true of a shader that
// animated a tint across a geometrically flat slab, and from the shore that
// is what it looked like: a painted plane. The vertex stage lifts the top
// face along the same wave field the fragment stage shades with, so the
// silhouette of the water against the far bank rises and falls, and the
// sparkle sits on a surface that is really where the highlight says it is.
// Water meshes must be SUBDIVIDED for this to show — a bare BoxMesh has four
// corners on its top face and nothing to bend.
//
// AND IT BREAKS AT THE SHORE. Displacement is damped to nothing at the
// volume's own rim, which does three jobs at once: a wave flattening as it
// reaches shallow water is what water does; the top face stays welded to the
// side faces, which a wave carried to the edge would tear open; and the same
// falloff drives a band of surf where the water meets the land, which is the
// single strongest cue that a body of water has an edge rather than being a
// blue box someone placed.
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

// HOW FAR THE SURFACE ACTUALLY LIFTS, in metres, peak to trough.
//
// Deliberately small, and the reason is gameplay rather than taste: the
// movement grammar switches at the COLLISION box, and this displaces only the
// visual. Every centimetre here is a centimetre where the water looks like it
// is in a slightly different place from where swimming starts, and
// test_water_boundary_alignment exists because that mismatch reads as broken
// physics. Two tenths of a metre is visible from the shore and invisible at
// the waterline, which is the trade this number is making.
uniform float wave_height: hint_range(0.0, 1.0) = 0.2;

// How much of the water's own half-width the wave takes to flatten into, and
// how strong the surf there is.
//
// A FRACTION RATHER THAN METRES, and that is a decision rather than a
// shortcut. Metres would need each volume to publish its own size, and the
// only per-instance channel for that — an instance uniform — is silently
// dropped by the headless renderer, so the value would be right in the game
// and untestable in CI, which is the worst of both. The face-local
// coordinate below needs nothing published and is exact. It also reads
// better: a wide lagoon showing a broader band of surf than a narrow channel
// is what a wide lagoon should do, where a fixed 2.4 m band would have turned
// the gorge river almost entirely to foam.
uniform float shore_band_share: hint_range(0.01, 0.9) = 0.16;
uniform float shore_foam: hint_range(0.0, 1.0) = 0.6;

// WHERE THE WATER ACTUALLY MEETS THE LAND, and this is the one place the
// no-screen-textures rule bends.
//
// The rim falloff above knows where the VOLUME ends. It does not know where
// the water ends, and in a real level those are nowhere near each other: the
// Coral Cove waterway is a twenty-six by fifty-seven metre box whose sides are
// buried in cliff, and the waterline a player actually looks at is a sand
// shelf somewhere in the middle of it. Rim foam therefore drew a bright band
// around four edges nobody can see and nothing at all along the shore, which
// is worse than no foam: it spends the effect where it cannot be read.
//
// Comparing this fragment's own depth against the depth already in the buffer
// gives the thickness of water at this pixel, which is exactly "how close is
// the bottom" — and a band of surf wherever that goes to nothing follows every
// shore, every rock and every step the level has, for one texture read. No
// refraction pass, no screen colour, no normal map: the doctrine at the top of
// this file is about not needing the EXPENSIVE parts of a water stack, and a
// depth compare is the cheap one.
uniform sampler2D depth_buffer: hint_depth_texture, filter_linear_mipmap;
uniform float shallows_depth_m: hint_range(0.05, 8.0) = 0.28;
uniform float shallows_foam: hint_range(0.0, 1.0) = 0.42;

// Where the top face sits in Godot's BoxMesh UV atlas. The layout is a fixed
// three-by-two grid — MEASURED across four wildly different box proportions,
// identical every time, and mapping to the face exactly linearly — so this is
// a constant rather than something a volume has to tell the shader. A test
// holds Godot to it, because it is the one assumption here that a future
// engine release could take away.
const vec2 TOP_FACE_UV_ORIGIN = vec2(1.0 / 3.0, 0.5);
const vec2 TOP_FACE_UV_SPAN = vec2(3.0, 2.0);

varying vec3 world_position;
varying vec3 world_normal;

// How far this fragment is from the volume's rim: 0 on the bank, 1 once it is
// shore_band_share of the way into open water.
varying float shore;

// Whether this fragment belongs to the top face, computed once in the vertex
// stage from the undisplaced normal.
varying float top_face;


// The broad wave field, shared by both stages so the geometry and the shading
// cannot drift apart. Returns roughly -3..3.
float wave_field(vec2 p, float t) {
	float a = p.x * 1.70 + t * 1.35;
	float b = p.y * 2.30 - t * 1.10;
	float c = (p.x + p.y) * 1.10 + t * 0.70;
	return sin(a) + sin(b) + sin(c);
}


void vertex() {
	// Face-local coordinates, 0..1 across the top face whatever the volume's
	// size or proportions. `rim` is how far in from the nearest of the four
	// edges this vertex is, as a share of the half-width, so 0 sits on the
	// bank and 1 is open water.
	vec2 face = (UV - TOP_FACE_UV_ORIGIN) * TOP_FACE_UV_SPAN;
	vec2 inset = 0.5 - abs(face - 0.5);
	float rim = min(inset.x, inset.y) * 2.0;
	shore = clamp(rim / max(shore_band_share, 0.001), 0.0, 1.0);
	top_face = smoothstep(0.65, 0.95, NORMAL.y);

	// Lift from the world position, so two volumes meeting at a seam agree
	// about where the crests are instead of each running its own wave from
	// its own origin.
	vec3 placed = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float lift = wave_field(placed.xz * ripple_scale, TIME * ripple_speed) / 3.0;
	VERTEX.y += top_face * shore * wave_height * lift;

	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

	// How much water stands between this pixel and whatever is behind it.
	float behind = texture(depth_buffer, SCREEN_UV).r;
	vec4 behind_view = INV_PROJECTION_MATRIX * vec4(
		SCREEN_UV * 2.0 - 1.0, behind, 1.0);
	float thickness = (behind_view.z / behind_view.w) - VERTEX.z;
	float shallows = 1.0 - smoothstep(0.0, shallows_depth_m, thickness);
	shallows *= shallows;

	// SURF, on the top face only, and breathing with the same wave field the
	// surface is riding so it reads as water arriving somewhere rather than as
	// a painted line. Two sources, and they answer different questions: the
	// shallows band follows the real waterline against every shore and rock,
	// the rim band catches the case where a volume simply stops in mid-air.
	float surge = 0.5 + 0.5 * sin(combined * 1.4 + TIME * 1.7);
	float breath = 0.55 + 0.45 * surge;
	float surf = max(shallows * shallows_foam,
		smoothstep(0.9, 0.05, shore) * shore_foam) * top_face * breath;
	tint = mix(tint, foam_tint, clamp(surf, 0.0, 1.0));

	// And deeper water is darker water — the same thickness, spent again.
	tint = mix(tint * 0.78, tint,
		clamp(smoothstep(0.0, shallows_depth_m * 8.0, thickness), 0.4, 1.0));

	ALBEDO = tint;
	ALPHA = clamp(
		mix(alpha_facing, alpha_grazing, fresnel)
		+ foam * 0.035 * horizontal_face
		+ glint * 0.10 * horizontal_face
		+ surf * 0.18,
		0.0, 0.78);
}
