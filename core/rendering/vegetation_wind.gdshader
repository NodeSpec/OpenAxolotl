shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// VEGETATION WIND — the cheapest large quality win available to this project.
//
// Every plant in the valley was FROZEN. Forty-eight identical canopy trees and
// fifty identical ferns, none of them moving, is most of why a forest full of
// geometry still read as a diorama: a still plant is indistinguishable from a
// prop, and the eye knows it. This costs no geometry, no textures and no draw
// calls — it is arithmetic in the vertex stage — and it is worth more than any
// amount of extra polygon detail on the same plants.
//
// THE SWAY IS A LEVER, NOT A TRANSLATION. Displacement scales with height
// above the plant's own base raised to `stiffness`, so the roots never move,
// the trunk bends a little and the canopy travels furthest. Translating the
// whole mesh would slide plants off their own ground, which reads instantly
// as wrong; shearing from a fixed floor is what a plant in wind actually does.
//
// PLANTS MUST NOT MOVE IN LOCKSTEP. The phase comes from the INSTANCE's world
// origin rather than from each vertex, which matters twice over: neighbouring
// plants are out of step with each other, and every vertex of one plant shares
// a phase so the plant sways as a single object instead of rippling internally.
//
// Works identically under MeshInstance3D and MultiMeshInstance3D, because
// MODEL_MATRIX carries the instance transform in both cases. Under MultiMesh,
// INSTANCE_CUSTOM adds a per-instance phase and tint so a scattered field of
// one mesh does not read as one mesh repeated.

// Albedo comes from COLOR_0: the whole environment kit is vertex-painted and
// ships no textures (docs/asset-contract.md's surface doctrine).
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform float specular_value : hint_range(0.0, 1.0) = 0.35;

// Wind direction on the ground plane. Normalised in the shader so a caller
// cannot accidentally scale the sway by feeding a non-unit vector.
uniform vec2 wind_direction = vec2(0.82, 0.57);

// Displacement at full height, as a FRACTION of the plant's own height.
//
// Not an absolute distance, because the kit's plants differ by a factor of
// thirty — a canopy tree is 21.9 model units tall and a fern is 0.74 — and one
// distance that suits a tree is invisible on a fern while one that suits a
// fern tears a tree apart. A fraction is the same LEAN ANGLE on both, which is
// what wind actually does to plants of different sizes.
uniform float sway_fraction : hint_range(0.0, 0.3) = 0.035;
uniform float sway_hz : hint_range(0.0, 4.0) = 0.30;

// A faster, smaller motion on top of the sway. Without it the movement reads
// as a single sine and the whole forest breathes in unison; with it, leaves
// have their own life at a different rate.
uniform float flutter_fraction : hint_range(0.0, 0.1) = 0.008;
uniform float flutter_hz : hint_range(0.0, 12.0) = 1.7;

// The plant's full height in MODEL space. SET PER FIELD from the mesh's own
// bounds (ScatterField does this), never left at the default: a shared value
// is wrong for every plant that is not exactly that tall, and being wrong
// upward is the worse direction — the lever saturates partway up the trunk and
// everything above it translates as a rigid block, which puts a visible kink
// in the tree instead of a bend.
uniform float model_height : hint_range(0.05, 60.0) = 2.2;

// Below this FRACTION of the plant's height nothing moves at all: roots, the
// trunk base, the part that is visibly in the ground. A fraction rather than a
// distance for the same reason the sway is.
uniform float anchor_fraction : hint_range(0.0, 0.5) = 0.06;

// Higher concentrates the motion in the top of the plant. 1.0 is a linear
// bend; above that the trunk stiffens and only the canopy really travels.
uniform float stiffness : hint_range(0.5, 4.0) = 1.6;

// How far a scattered instance may be tinted from the mesh's own colour, so a
// field of one mesh is not a field of one colour. Driven by INSTANCE_CUSTOM.y.
uniform vec3 tint_toward : source_color = vec3(0.72, 0.83, 0.55);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.35;

varying float instance_tint;


void vertex() {
	// The instance's own origin. Identical for every vertex of one plant,
	// which is exactly the property the phase needs.
	vec3 anchor = MODEL_MATRIX[3].xyz;

	// Two irrational-ish multipliers so a grid-aligned scatter does not land
	// neighbouring plants on the same phase.
	float phase = anchor.x * 0.73 + anchor.z * 0.94 + INSTANCE_CUSTOM.x * TAU;
	instance_tint = INSTANCE_CUSTOM.y;

	float anchor_height = anchor_fraction * model_height;
	float height = max(VERTEX.y - anchor_height, 0.0);
	float span = max(model_height - anchor_height, 0.0001);
	float lever = pow(clamp(height / span, 0.0, 1.0), stiffness);

	float sway = sin(TIME * sway_hz * TAU + phase);
	// The flutter is additionally offset along the mesh's own X so opposite
	// sides of a canopy are not in step, which is what stops a wide tree
	// looking like a rigid cutout rocking.
	float flutter = sin(TIME * flutter_hz * TAU + phase * 3.1 + VERTEX.x * 2.3);

	vec2 push = normalize(wind_direction) * lever * model_height
		* (sway * sway_fraction + flutter * flutter_fraction);
	VERTEX.xz += push;
}


void fragment() {
	ALBEDO = mix(COLOR.rgb, tint_toward, instance_tint * tint_amount);
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
	METALLIC = 0.0;
}
