# First two Drift Fleet animation assets

Netbot and Hookline Rig now have reusable visual scenes in this directory. Their original GLBs are unchanged. These scenes own presentation only; `../fleet_encounter.gd` now supplies production awareness, movement, hit detection and breakup, with six placements in `../cascade_population.tscn`. WorldSystems now starts a timed capture challenge when a declared Netbot contact catches the real player.

## Preview

Open `fleet_animation_preview.tscn` and press F6. The buttons play the same clips used by the reusable scenes. Disabled holds until Reset. Attack automatically enters Recover, which returns to Idle. Notice and Warn hold their final poses until an encounter controller advances them.

Use `netbot_visual.tscn` or `hookline_rig_visual.tscn` beneath a future gameplay actor. Both face local -Z. Their origins retain source model centres: place the Netbot origin 0.53 m above the floor; give the suspended Hookline at least 1.2 m floor clearance at source scale. Scale the complete actor, not separate animated parts. Neither animation moves the gameplay root.

## Clips and timing

| Clip | Netbot | Hookline | Behaviour |
|---|---:|---:|---|
| idle | 2.0 s | 3.0 s | Seamless loop; restrained net mechanism / buoyant rig and hook swivel |
| notice | 0.45 s | 0.45 s | Small mechanism lift and warning light |
| warn | 0.90 s | 1.00 s | Raised capture assembly / initial cable lowering and backswing |
| attack | 0.55 s | 0.85 s | Forward basket snap / 2.72 m forward hook throw |
| recover | 1.35 s | 3.00 s | Exposed lowered net / reeling hooks back in |
| stagger | 0.70 s | 0.70 s | Mechanical recoil, then idle |
| disabled | 0.85 s | 1.00 s | Mechanism droop, settled chassis and warning light off; held |
| reset | 0.18 s | 0.18 s | Canonical rest pose, then idle |

`play_state(StringName)` returns false for an unknown clip or a non-reset request while disabled. Interruptions immediately close `attack_active`. Playback emits `attack_window_changed`, `state_finished` and `cue` signals. Cues identify notice, warn, release, stagger and disabled; no audio assets are bundled in this pass. Netbot's active interval is 0.12–0.34 s within Attack; Hookline's is 0.22–0.66 s. These are future hit-test timing markers, not working hitboxes. A future controller must validate targeting/line of sight before advancing Warn to Attack, and must never infer contact just from the animation marker.

Each mechanism includes an AttackSocket. Netbot uses a front basket sweep, not a detached projectile. Netbot’s basket is now 85% longer along its reach axis. Hookline throws its intact hooks forward on extending cables and slowly retracts them over three seconds. Call lock_attack_target(world_position) before Attack to commit to the observed player position; calls during Attack/Recover are refused, so retraction never homes toward the player. Their sockets can drive subsequent gameplay volumes/VFX. Bind future fleet stagger/defeat/reset signals to these states; do not additionally run the old whole-node defeat tilt on the visual.

## Netbot capture challenge

A successful Netbot contact holds the axolotl in place on land or underwater. Three distinct tail whacks strictly before two seconds tear the net. Escape swings count toward the net rather than defeating the nearby bot. During capture, normal tail-whack bindings are available underwater, with 0.38 seconds between swings, so three swings fit comfortably inside the deadline. A held button does not repeatedly swing. A visible countdown shows remaining time and whacks.

Failure returns the player to the last activated checkpoint (or spawn), clearing motion and the net slow. No additional life penalty was requested. Escape/reset grants one second of recapture grace. World exit, external defeat, and checkpoint return release capture locks. Existing Jet Gills protection can prevent initial contact; activating abilities while caught does not bypass the three-whack challenge. Run tools/verify_net_capture.gd for input-to-world integration tests. The production Cascade still has no placed enemies: the capture behavior is wired to the world contact seam for the next encounter-placement pass.

## Geometry and limitations

Netbot: 10,000 triangles, partitioned into chassis, paired capture arms, and basket. Hookline: 9,940 retained source triangles plus 32 cable triangles = 9,972. Original UVs and maps are preserved. The machines are rigid mechanical assemblies; they do not need creature skeletons or humanoid retargeting. There are no locomotion clips yet because patrol paths and water/shore movement remain the next integration step.

The source is a decimated fused sculpt. Parts are separated at mechanical joins, not re-topologized into manufactured CAD joints. Reviewed front and three-quarter animation poses; additional close-up joint refinement may be useful if a later camera gets much closer than gameplay. Existing painted lamp highlights remain in the original base-colour textures, even when the added warning light is off.

## Rebuild and verification

Run Blender with `--background --python-exit-code 1 --python tools/blender/prepare_enemy_animation_parts.py -- --project-root <project> --output <staging-folder>`. Copy each staged `<kind>_parts.glb` to `assets/prop/<kind>_animated/<kind>_animated.glb`, then import with Godot `--headless --editor --quit`. Run `godot --headless --path . --script tools/build_enemy_animation_scenes.gd` to bake the AnimationPlayer resources. Edit the authored pose arrays in that generator for reproducible changes.

Run `godot --headless --path . --script tools/verify_fleet_animations.gd` for live checks of clip bindings, geometry budgets, active intervals, cancellation, reset, instance independence, and root stability. Source hashes and derivation information are stored in each derived asset's provenance.json. Source licences remain unchanged.

## Production population — 20 September 2026

See `docs/enemy-population.md`. The previous preview-only and future-controller notes above describe the original animation pass. The production controller now drives these markers, performs swept socket contact tests, and replaces the held disabled pose with actual mesh fragments.
