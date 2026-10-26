# Explorer backpack — flatter fitted revision

The user's requested refinement reduces the canvas bag's local depth by 60% while maintaining its footprint. The bag, flap, closure straps and side pocket now curve across the actual torso envelope. A 0.024-authoring-unit pad replaces the tall saddle volume; the connectors are shortened to meet it. The hero scene scales these authoring dimensions by 0.5.

The 60% figure describes local bag thickness, not the full accessory bounding-box height: the curved profile, scroll and compass also contribute to those bounds. Original main-body authoring Z bounds were 0.6645–1.0695; the revised body's bounds are approximately 0.5599–0.8518 because its edges now wrap down around the back.

Hardware and scroll components are repositioned without flattening their individual shapes. Canvas/flap meshes receive just enough extra cross-sections to describe the bend, and their normals are recalculated. Flexible harness weights are transferred again after fitting. The existing rig, runtime attachment code, texture maps and physics capsule are unchanged.

The accessory now has 19,918 triangles, still below its existing 20,000 test ceiling. The equipped Cascade scene contains 2,978,940 triangles against the unchanged 3,000,000 ceiling. The original character GLB SHA-256 remains unchanged.

Validation rerun for this revision:

- 42 focused regressions passed with no errors, including skin/rest bindings, material maps, character animation and the scene budget.
- 13 real-input gameplay checks passed across the starting lagoon and Living Cascade.
- Five static review views and six samples each of walk, swim, roll, spin and tail attack were rendered again. The side, close-up and movement views were visually inspected.
- Static accessory captures have no warnings or errors. The full-level capture retains the seven-texture RID warning at Godot shutdown recorded in the first iteration; no script errors were emitted.

No runtime GDScript behavior changed, so the earlier static/contract checks remain the code validation record; those gates were not rerun for this geometry-only revision. The editor's closing-brace whitespace in `project.godot` is restored for the existing Python checker without changing any values.

Updated files: the accessory GLB/provenance and `tools/blender/build_explorer_backpack.py`. Editable source: task workspace `work/explorer_backpack/explorer_backpack.blend`. First-iteration GLB, Blender source, generator and report are backed up under `work/backpack-before-flat`; matching baseline images are retained in the review outputs.

No Git commit was created.
