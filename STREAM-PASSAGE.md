# Continuous Middle Passage

## Play

Open `Play Lagoon.cmd` and enter the middle arch. Its current carries the
axolotl down the winding passage into Coral Cove. Steering remains available
throughout. The launcher uses the same Direct3D 12 Forward+ configuration used
for the graphical review on this machine.

Use `Open Lagoon Editor.cmd` for the editor. The connected level is assembled
at runtime; press Play to inspect the complete lagoon-to-level connection.

## This Iteration

- A roughly 44-metre rock passage descends approximately 6.2 metres from the
  existing middle entrance, with a gentle sideways bend and return.
- The supplied boulder's derived `bank_rock` mesh is instanced around the
  channel. It retains its texture coordinates, color, normal, and roughness
  maps. Sparse procedural moss adds soft green emission and local lighting.
- A lightweight fitted cave collision shell blocks the player and camera.
  The decorative rocks do not each require their own dense triangle collider.
- Water follows the channel geometry and its local direction. The current
  strengthens after entry, guides a passive swimmer around the bend, then
  tapers out inside the receiving waterway. The open lagoon has no new current.
- Cave lighting fades in and out spatially. The camera keeps the swimmer in
  view above the descending water, without resetting at level activation.
- Swimming wakes use velocity relative to the water. Floating with a current
  no longer produces the same repeated splash rings as active swimming.

## Continuous Entry

`OpenLagoon` discovers the middle module through the existing registry. A world
with one `stream_entry` marker is placed against the passage outlet before
play. Coral Cove's marker sits on the upstream edge of its original waterway.

Near the far end, the already-present scene receives its gameplay systems,
HUD, save integration, and finish condition. Entry does not instantiate a new
player, replace the camera, teleport, clear water contacts, hide the lagoon,
or switch the daylight environment. The player simply crosses into the level.

This is preloaded, physically continuous geometry, not background asset
streaming. The side portals and direct `enter_world()` API keep their existing
behavior. Finishing a level still uses the existing return-to-hub flow.

## Editing Points

- `hub/lagoon_stream_path.gd`: shared channel curve and spatial lighting fade.
- `hub/lagoon_stream.gd`: rock placement, water strip, collision, local current,
  camera hint, lights, and reflection probes.
- `hub/lagoon_stream_rock.gdshader`: wet stone and luminous moss.
- `worlds/coral_cove/world.tscn`: `StreamEntry` connection landmark. The original
  level's gameplay route and platforms are otherwise unchanged.

## Verification

`test/hub/run_continuous_stream.gd` exercises the actual controller and physics:
middle-arch entry, passive downstream travel, player and camera continuity,
movement at activation, water handoff, downstream steering, completion,
side-world entry, and registry refresh. Pass `-- --capture` to save gameplay
screenshots at the entrance, bend, downstream section, and first-level outlet.

The review images and logs are in `review/stream_*.png` and
`review/stream-*.log`. These are Godot gameplay renders, not concept images.

Verified in Godot 4.7.2:

| Check | Result |
| --- | --- |
| Continuous stream physics, water winding, and lifecycle | 31 checks passed |
| Graphical swim-through and screenshot checks | 34 checks passed |
| Lagoon swimming and all three entrances | 21 checks passed |
| Lagoon art integration | 33 checks passed |
| Imported dressing and collisions | 502 checks passed |
| Complete Coral Cove route | 29 checks passed |
| Complete Bubble Bay route | 22 checks passed |
| Unit suite | 618 passed, 1 existing failure |
| Headless import and bounded D3D12 editor startup | Exit code 0 |
| Play launcher smoke test | Exit code 0 |

The existing unit failure is
`test_world_dressing::test_every_kit_prop_loads_with_meshes_and_vertex_colour_albedo`:
four older environment-kit materials lack their expected vertex-color flag.
Those unrelated assets were not changed. Godot also reports shutdown
resource/instance leak diagnostics in the logs; clean resource teardown is
not claimed by these smoke tests.

The route probes now scope spawn placement and checkpoints to the active
world. A preloaded neighboring scene must not contribute landmarks to the
route being tested.

The tunnel is the scope of this iteration. Coral Cove beyond the outlet still
uses its existing art and layout; this does not claim final Astro Bot-level
asset quality or a complete first-level art pass.
