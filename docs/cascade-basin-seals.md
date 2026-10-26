# Living Cascade: entrance and basin containment

The pool shells and recovery foundation were insufficient to contain the player
at the intended terrain surface. Player-capsule sweeps found openings at the
garden approach/far shore, underwater exit, and elevated pool boundaries.
The connected lagoon inlet also had unsupported strips beside its narrower cave.

Changes are baked into worlds/coral_cove/world.tscn through
dev/living_cascade/cascade_basin_seals.gd. The asset-dressing builder invokes the
same pass so a subsequent art build retains the fixes.

- Add a textured floor overlap and tapering rock sides at the lagoon connection.
  Keep the central passage open in both directions.
- Complete the garden's near and far shores and the underwater exit side walls.
- Close exposed raised-pool edges and connect the B recovery basin to its side
  pool. Keep space around the stepping stones and the existing return ramps.
- Fill the empty interiors beneath 76 sculpted banks/beds with inset convex
  collision cores. These do not replace the detailed surface collision.
- Use the existing section terrain materials for the visible additions.

The water surface and matching volume of PoolBCatch widen together. The scripted
route, player abilities, enemies, pickups, soundtrack, checkpoint rules and
nonlethal recovery fallback remain intact. No whirlpool hazard is added.

Validation uses the actual connected hub transform and the shipped player-sized
capsule, not only floor rays. The basin sweep starts from all free sampled cells
at two depths per non-chute water volume and checks for reachable unsupported or
recovery-floor cells. One lower-depth side-pool case is fully occupied by the
existing exit ramp; 25 reachable depth cases are checked. This is a sampled
regression, not a proof of every possible player trajectory.

Additional checks cover the full translated production route, entry/return
through the lagoon tunnel, 66 real-input arch/stone traversals, and the existing
3,581 containment checks including the secret grotto and restoration gate.

Original production scene and asset-dressing source are backed up in the
authoring workspace's work/basin-seal-backup directory.
