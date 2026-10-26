# Cascade collision polish

The visible model meshes, material treatment and authored route are retained. Collision on 26 supplied asset instances now follows smooth structural forms instead of every moss, leaf, coral and root triangle.

- Seventeen mossy stones use a solid beveled hull. The ten stepping platforms retain their authored landing heights and climb/collision roles.
- Six submerged reef arches use compound convex piers and curved vault segments, preserving open tunnels. Mouths are beveled for diagonal approaches. Collision depth tapers inward with height to fit the visible arch rather than projecting a flat wall in front of it.
- Two root bridges and the crown arch retain four separate feet and side openings.
- Swimming uses CharacterBody3D floating motion and unrestricted wall sliding. Ground movement keeps grounded motion. Player capsule size, movement tuning, jumps and combat reach are unchanged.
- Existing terrain, floor backstops, perimeter walls, closed restoration gate, enemy placements and crayfish are retained.

Authoring source: `dev/living_cascade/cascade_collision_polish.gd`. The asset dressing builder calls this pass after terrain construction. It also has been applied to the existing production scene without rebuilding gameplay content.

## Verification

`tools/verify_cascade_collision_polish.gd` drives the real input pipeline through 36 tunnel crossings (three lanes, both directions, six arches) and 30 platform crossings. The grotto is a pocket chamber: endpoints deliberately stop before its solid back wall.

The complete translated production route and 3,581 containment/landing/gate checks run with enemy attack processing disabled in the navigation fixture only. Production enemy AI remains active. Separate tests cover 83 encounter checks and seven actual keyboard combat checks. Crayfish habitat, starting lagoon movement and existing asset/combat suites are also checked.

Some older test harnesses report ObjectDB/resource cleanup warnings when exiting; these are separate from assertion results. No claim is made that an automated route samples every possible player approach in the level. The focused movement test is installed so further reported locations can be added as regressions.
