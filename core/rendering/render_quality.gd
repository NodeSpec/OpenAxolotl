class_name RenderQuality
extends RefCounted

## Graphics quality levels (REQ-027) — the knob between "runs" and "looks best".
##
## WHY THIS EXISTS, stated plainly because the omission cost real play time:
## the shared environment was tuned for a screenshot and shipped as the only
## option. SDFGI at four cascades, volumetric fog with GI injection, SSAO, TAA
## layered over 2x MSAA, and a 4096 directional shadow at the highest soft
## filter quality is a stack that a mid-range desktop cannot hold at 60 fps —
## and because it is a GPU cost, the headless perf gate could not see any of
## it. `test/perf/run_gpu_gate.gd` closes that hole; this file gives the
## player somewhere to turn when the answer is still "too slow".
##
## THE EXPENSIVE THINGS, in the order they cost:
##
##   1. SDFGI. By a distance. It is a voxel cascade that RE-VOXELISES as the
##      camera travels, so a level like the coral valley — 128 metres end to
##      end — pays for it continuously rather than once. It is off below HIGH,
##      and the sky-lit ambient carries the bounce instead.
##   2. Volumetric fog, especially with gi_inject. Off below HIGH.
##   3. Soft shadows. A 4096 atlas at filter quality 3 with a 1.5-degree sun
##      is an area light; the cost is in the filter taps, not the resolution,
##      so the filter drops faster than the size does.
##   4. SSAO, then TAA, then glow.
##
## WHAT IS NEVER TOUCHED: the sky, the tonemap, exposure, fog colour and the
## sun's direction and energy. Those carry the look — "one world, one voice"
## (docs/asset-contract.md) — and a quality level that shifted them would make
## the game a different game on a slower machine rather than the same game
## rendered more cheaply. Every level below HIGH removes effects; none of them
## re-grades the picture.

enum Level {
	LOW,     ## integrated graphics; everything optional is gone
	MEDIUM,  ## the default: mid-range desktop at 60 fps
	HIGH,    ## the authored look, and what the captures are taken at
}

## The profile key the choice persists under, beside audio volumes and input
## remaps (core/save/save_system.gd's settings section).
const SETTINGS_KEY := "graphicsQuality"

## MEDIUM, not HIGH. A default that a mid-range desktop cannot hold means the
## first thing a new player experiences is stutter, and most will never find
## the setting that fixes it. HIGH is one menu entry away for anyone whose
## machine can drive it.
const DEFAULT := Level.MEDIUM

const LEVEL_NAMES := {
	Level.LOW: "low",
	Level.MEDIUM: "medium",
	Level.HIGH: "high",
}


static func level_name(level: Level) -> String:
	return LEVEL_NAMES.get(level, "medium")


static func level_from_name(name: String) -> Level:
	for level: Level in LEVEL_NAMES:
		if LEVEL_NAMES[level] == name.to_lower():
			return level
	return DEFAULT


## Apply `level` to everything that carries a per-frame GPU cost.
##
## `environment` and `sun` come from the shared rig (WorldLighting); `viewport`
## is the one the game renders into. All three are optional so a caller that
## only has some of them still applies what it can — the dev greybox and the
## test harness both instance partial scenes.
static func apply(level: Level, environment: Environment,
		sun: DirectionalLight3D, viewport: Viewport) -> void:
	_apply_environment(level, environment)
	_apply_sun(level, sun)
	_apply_viewport(level, viewport)
	_apply_shadow_server(level)


static func _apply_environment(level: Level, environment: Environment) -> void:
	if environment == null:
		return

	# THE BIG ONE. Half resolution rather than off would still pay the
	# re-voxelisation, which is the part that stutters, so it goes off whole.
	environment.sdfgi_enabled = level == Level.HIGH
	if environment.sdfgi_enabled:
		environment.sdfgi_cascades = 4

	environment.volumetric_fog_enabled = level == Level.HIGH

	# Distance fog is cheap (it is a per-pixel blend, not a froxel volume) and
	# it carries the aerial perspective the valley reads depth from, so it
	# survives at every level.
	environment.fog_enabled = true

	environment.ssao_enabled = level != Level.LOW
	if environment.ssao_enabled:
		# MEDIUM halves the radius and drops the detail pass; the contact
		# darkening under the axolotl survives, the wide-radius sampling does
		# not.
		environment.ssao_radius = 1.0 if level == Level.HIGH else 0.5
		environment.ssao_detail = 0.5 if level == Level.HIGH else 0.0

	environment.glow_enabled = level != Level.LOW


static func _apply_sun(level: Level, sun: DirectionalLight3D) -> void:
	if sun == null:
		return

	sun.shadow_enabled = true
	# A 1.5-degree angular size makes the sun an AREA light, and the softness
	# is paid for in filter taps at every shadowed pixel. Below HIGH it becomes
	# a point sun with a blur, which looks nearly the same at gameplay
	# distance and costs a fraction.
	sun.light_angular_distance = 1.5 if level == Level.HIGH else 0.0
	sun.shadow_blur = 1.5 if level == Level.HIGH else 1.0
	# Two cascades at HIGH and MEDIUM; LOW takes one, which halves the shadow
	# draw calls for the whole scene.
	sun.directional_shadow_mode = (
		DirectionalLight3D.SHADOW_ORTHOGONAL if level == Level.LOW
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS)
	# Shorter shadow distance on LOW: the far half of the valley loses its
	# shadows, which is invisible through the fog and saves the cascade.
	sun.directional_shadow_max_distance = 45.0 if level == Level.LOW else 80.0


static func _apply_viewport(level: Level, viewport: Viewport) -> void:
	if viewport == null:
		return

	# TAA and MSAA were both on. They solve different edges and stack their
	# costs; MSAA alone is the cheaper half and is what survives.
	viewport.use_taa = level == Level.HIGH
	viewport.msaa_3d = (
		Viewport.MSAA_DISABLED if level == Level.LOW else Viewport.MSAA_2X)
	# FXAA on LOW instead: nearly free, and without it a MSAA-less frame
	# crawls with specular aliasing on the water.
	viewport.screen_space_aa = (
		Viewport.SCREEN_SPACE_AA_FXAA if level == Level.LOW
		else Viewport.SCREEN_SPACE_AA_DISABLED)

	# LOW renders at 75% and upscales. This is the single largest lever on a
	# fill-rate-bound machine and the last one applied, because it is the one
	# a player will actually see.
	viewport.scaling_3d_scale = 0.75 if level == Level.LOW else 1.0


static func _apply_shadow_server(level: Level) -> void:
	# Server-wide, so these are set here rather than in project.godot: the
	# project settings only apply at startup and a quality menu has to take
	# effect when the player picks it.
	var filter := {
		Level.LOW: RenderingServer.SHADOW_QUALITY_HARD,
		Level.MEDIUM: RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		Level.HIGH: RenderingServer.SHADOW_QUALITY_SOFT_HIGH,
	}[level] as RenderingServer.ShadowQuality
	RenderingServer.directional_soft_shadow_filter_set_quality(filter)
	RenderingServer.positional_soft_shadow_filter_set_quality(filter)

	var size := {
		Level.LOW: 2048,
		Level.MEDIUM: 2048,
		Level.HIGH: 4096,
	}[level] as int
	RenderingServer.directional_shadow_atlas_set_size(size, level != Level.HIGH)
