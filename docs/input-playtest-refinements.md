# Stable controls and idle camera refinement

Based on `codex-branch` at `b243aa5f90abdba034ec95b35ba3e07ae455d0c8`.
The open NodeSpec design-push PR is unchanged. This pass preserves level layout,
art, controller tuning and the existing semantic input interface.

## Changes

- Idle stick noise and release events from the previous device no longer steal
  control or erase held movement on the current device.
- Switching devices clears actions queued by the previous device.
- Repeated pressed samples produce one action per physical press, including
  remapped analog actions and ability requests. Release rearms the action.
- Losing application focus clears held movement and queued actions, preventing
  a key released in another application from remaining held in the game.
- Steering deadzone boundaries account for input-event float32 rounding.

- Camera assistance no longer rotates the view during sustained movement or
  while steering into a wall. It remembers the last travel direction and only
  recenters after the configured idle delay; manual look restarts that delay.
  Explicit camera resets, checkpoint recovery and hub transfers discard the old heading. Delay-boundary turns are
  consistent across different step sizes.

## Evidence

A bounded headless Godot 4.3 run in a cloud workspace, without loading the game
scene, ran the existing input suite and six new regressions:

- Original production code plus the new tests: 39 passed, 6 failed.
- Updated production code plus the same tests: 45 passed, 0 failed.
- Final combined input, camera-look, camera-rig and idle-assist pass: **96 passed,
  0 failed**, with no script errors in its log.
- Lightweight static-gate and level-checker fixture tests: **46 passed**. The
  expensive whole-repository static test was excluded from this focused run.
- Static gate over the six changed gameplay scripts: passed.
- Level-contract checker: passed.
- `git diff --check`: passed.

The focus-loss test checks the production notification wiring as source and
executes the real `InputSystem.clear()` behavior. It does not simulate an OS
focus transition or instantiate the rendered hero. Those remain playtest items.
The camera integration has a source-wiring assertion; the helper's behavior is
executed directly. Rendered camera and OS focus behavior remain manual checks.
The focused run is not a full game, performance, export or art-import pass.

The broad Python suite was attempted and interrupted after preliminary failures
and errors; it did not complete and is not green. The full repository static scan
was also interrupted rather than consume unbounded time scanning the large scene.
This cloud checkout deliberately omits most art and has unavailable LFS assets;
full imports, full-suite results, exports, traversal probes and performance gates
remain unverified. These limits must not be interpreted as full acceptance of the
NodeSpec camera or input requirements.

On an already imported checkout, repeat the lightweight input pass with:

```sh
godot --headless --audio-driver Dummy --path . --script test/run_input_checks.gd
```

The normal full test runner also discovers all these tests. The focused runner
reuses it instead of maintaining a second assertion implementation.

## Next targeted playtest (about ten minutes)

1. In Open Lagoon, hold left/right strafe and then backward for several seconds
   without touching look. The camera should hold its yaw rather than gradually
   turn your route into a circle. Stop: after the normal idle delay it should
   ease behind your last travel direction. Touch look to restart the delay.
2. Repeat a short terrace approach and the root-dive passage in Living Cascade.
   Check that you can line up a hop, swim straight and reverse without the
   camera steering for you. Press into a wall: assistance should remain idle.
3. With a controller connected but untouched, move around Open Lagoon on the
   keyboard. Movement and keyboard prompts should remain stable.
4. While holding forward, intentionally move the left stick, then release the
   keyboard key. Gamepad steering should continue without a prompt flip or stop.
   Switch back with a deliberate keyboard press.
5. Hop or attack once, hold the button, release it and press again. Each new
   press should trigger once. Check dance toggling with D-pad Down as well.
6. Hold forward, switch to another application, release the key there, and
   return. The axolotl must not continue steering from the stale key. A fresh
   press should work. This change does not pause simulation or erase momentum.
7. Recover at a checkpoint and return to the hub after moving sideways. The
   camera should not recenter toward the direction traveled before teleporting.
8. Swim and return to land while holding forward. The existing continuous
   movement across the land/water seam must remain intact.

Report any repeated action, prompt flicker, stuck movement or unexpected action
on device handoff, and which device was active. This is a control-stability
checkpoint, not approval of the entire first adventure or its visual polish.
