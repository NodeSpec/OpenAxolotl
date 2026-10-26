# Crayfish groove and the Living Cascade soundscape

Collect five glowing crayfish to unlock a reusable shore dance. Press G or gamepad D-pad Down while standing still on a flat, clear bank. Movement, another movement action, water, damage, capture, or a checkpoint return stops the routine. The dance lasts 32 beats at 112 BPM (17.142857 seconds); it does not consume the collected creatures or make the hero invulnerable.

## Assets and placement

- `assets/creature/glowing_crayfish/glowing_crayfish.glb`: refined 8,032-triangle crayfish, with 23 bones in one skinned mesh and three material surfaces. Articulated pincers, eight walking legs, eye stalks, antennae and six tail plates support natural movement. Blue vertex colors, cyan emissive markings, and a subtle procedural shell material preserve the pickup identity.
- Keep its `.glb.import` alongside it: `core/rendering/crayfish_import.gd` enables vertex colors on every imported shell material.
- `tools/source_art/glowing_crayfish.blend`: editable source; `.gdignore` prevents an unwanted Blender import dependency.
- `tools/blender/make_glow_crayfish.py`: regenerate the mesh with Blender. The asset import hook remains installed separately.
- Thirteen new dance pickups: six in S03's submerged root route, three in S06's chute, three on the arrival/exit banks, and one on the S04 entry bank. Shore positions were raycast onto the actual terrain. All use unique `glow_crayfish_*` discovery IDs.
- The existing Lantern Shrimp grotto discovery also uses this mesh but keeps its existing ID and discovery role. Gold restoration seeds and the Tide Pearl retain their roles.
- Placement is saved in the production scene `worlds/coral_cove/world.tscn` and declared in its manifest. Rebuilding that scene from an older terrain/blockout generator will need these authored additions reapplied, just like later terrain work.

## Audio and animation

`assets/audio/cascade/` contains 29 original synthesized WAVs: a 40-second 96 BPM exploration loop, a 17.14-second 112 BPM dance cue, five ambience beds, and 22 gameplay cues. Movement, dive, hop, landing, tail strike, spin, slide, pickup, unlock, checkpoint, capability/Gill Mod, and capture feedback now have audio. `tools/make_cascade_audio.py` regenerates the audio with NumPy; no third-party recordings or samples are used. The dance cue has short onset/end fades. Music and effects use separate existing audio buses.

`core/audio/game_soundscape.gd` is attached to the real hero. It loops exploration music, switches land/water ambience, ducks exploration during the dance, and restores it on completion/interruption. Bank-backed events remain in the existing AudioSystem/GodotAudioSink path. Music restarts if the hero itself is recreated.

`core/rendering/hero_dance_clips.gd` adds a dance to the existing rig without replacing the source hero GLB. The upper body rises through the waist while the pelvis stays over the hind feet. Heel taps, side shifts, paw waves, head motion, and tail sway follow the beat. Locomotion/action clips explicitly restore root translation afterward. The collision body remains in place throughout the dance.

## Progress and controls

WorldSystems counts unique `glow_crayfish_*` discovery IDs, and saves the unlock count through SaveSystem's `crayfish_dance` settings section. Normal world discovery persistence removes collected creatures on re-entry. GameSession restores the global unlock when starting a session. The current threshold is `AxolotlBody.DANCE_UNLOCK_COUNT = 5`. The HUD shows the unlock meter and the active device's default dance button.

## Verification

Run with Godot from the project:

```
godot --headless --path . --script res://tools/verify_crayfish_dance.gd
godot --headless --path . --script res://tools/verify_crayfish_world.gd
godot --headless --path . --script res://tools/run_dance_regression.gd
```

- 126 dance/audio/pose checks passed, including sampled support-foot height, input, threshold, interrupts, body stability, audio transitions, and root-pose cleanup.
- 17 production-world checks passed, including actual Area3D contact on all four shore pickups and one underwater pickup, a real bank dance, checkpoint interruption, disk round-trip through a dedicated test profile, and removal of the five pickups after re-entry. The user's normal profile was not modified.
- 133 existing input, audio, collectible, hero, combat, and world-system regressions passed.
- Static gate and level contracts passed. The two new asset directories are separately validated.
- Godot frames were visually checked for blue material import, shore positions, underwater appearance, and the standing dance. Audio waveforms were checked for clipping, duration, and boundaries; the review supplies audio players for listening and mix feedback.
- The older broad regression runner still reports ObjectDB/resource cleanup warnings at shutdown. The broad asset validator also reports pre-existing naming/provenance issues in older backpack/enemy assets. These are separate from the new assets and were not expanded into this feature change.

Review: `outputs/crayfish-groove-review.html` in the Codex workspace includes the dance frame player, original music, sample effects, and actual level screenshots.

## Habitat refinement — September 19, 2026

`core/rendering/crayfish_motion.gd` now moves the parent pickup Area3D rather than bobbing the mesh away from its trigger. It detects the authored water volumes and chooses short, random local paths. Each creature has deterministic variation in timing and route, seeded from its home and phase.

Shore animals follow terrain normals, crawl at about 0.17 m/s, and pause for 1–3 seconds to forage. Four ground-support checks reject ledges; steep slopes and water crossings are rejected. Swimmers paddle at about 0.27 m/s, vary depth by under 0.26 m, and can flick backward briefly when approached, with a seven-second cooldown. All wander within a 1.15 m home radius. Swept sphere queries stop wall crossings, including thin barriers. The animal pauses within 0.95 m of the player so collecting it does not become a prolonged chase.

Shell, claw, leg, eye, antenna and tail geometry is original procedural Blender work. The editable source and generator remain in `tools/source_art/` and `tools/blender/`. `core/rendering/crayfish_shell.gdshader` adds small-scale color and roughness variation with distance attenuation for fine detail. Keep the `.glb.import` hook; it installs that material on the shell.

The original exit marker at (8,-0.2,-56) lay on the edge of two water volumes. Its same-ID pickup is now at (7,-1.25,-57), inside the root swim corridor. Other authored pickup positions and all collection IDs remain unchanged. Runtime initialization discards the old saved visual bob offsets and settles shore creatures onto the floor.

Validation: `tools/verify_crayfish_habitat.gd` passed 78 checks after simulating all 14 creatures for 45 seconds against the production world. `tools/verify_crayfish_world.gd` passed its 17 physical pickup, unlock and save/re-entry checks with motion active. The refined GLB passes the creature asset contract. Actual Godot captures cover arrival shore, underwater roots and the terrace bank; the Codex workspace review is `outputs/crayfish-refinement-review.html`. Existing test-runner shutdown resource warnings remain separate from the passing assertions.
