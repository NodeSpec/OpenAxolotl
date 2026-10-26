# Explorer backpack — implementation and verification

The accessory is installed on the existing main character and uses the four user-supplied September 15 hero images as its design reference. The rear image guides pack construction; side/top/front views guide thickness, footprint and clearances. Minor differences between the reference views are resolved as one consistent design fitted to the actual slimmer axolotl. The hero itself was not regenerated or retextured.

## Asset and integration

- `assets/character/explorer_backpack/explorer_backpack.glb`: separate skinned asset, 19,918 triangles and seven material surfaces. Canvas and leather use six baked 1024px maps (colour, tangent normal and roughness), with high-quality VRAM compression and mipmaps in Godot. Other surfaces are brass, dark buckle metal, parchment, thread and map ink.
- `core/rendering/hero_backpack.gd`: instantiate the imported accessory, reuse the existing named skin bindings, then discard its source rig. The firm bag follows the spine; flexible harness and saddle weights are transferred from the nearest underlying hero vertices. The imported character retains its 12-bone skeleton.
- `core/controller/axolotl_body.gd`: one attachment call after the existing skin setup, before animator/secondary-motion binding. Existing wetness treatment also reaches the accessory. No movement, collision or level logic changes.
- `test/core/rendering/test_hero_backpack.gd`: verifies one shared rig, valid rest binds, normalized skin weights, detail maps, unchanged capsule and independent per-character materials.
- `test/core/rendering/test_hero_surface.gd`: includes the separate equipment GLB in the existing scene triangle count. The three-million ceiling is unchanged. Total scene content including the equipped hero: 2,978,940 triangles.
- `project.godot`: two dictionary closing-brace indents were restored after the editor rewrote them; values and rendering settings are unchanged. The existing Python static checker requires that whitespace to read the shader-global entries.
- `tools/blender/build_explorer_backpack.py`: portable Blender generator. Run with `--project PROJECT_DIRECTORY --output OUTPUT_DIRECTORY` after Blender's `--` separator. Output must be outside the game asset folder so the editable Blender fitting scene is not automatically imported as another runtime asset.

The pack includes rounded canvas geometry, a folded flap, leather reinforcement, a contoured underside, fitted harness, modeled stitches, buckles, rivets, handle, side pouch, open-ended parchment roll and raised compass rose. The compass is decorative and follows the pack; no separate swinging simulation, inventory interaction or compass gameplay was added.

The editable source is in the task workspace at `work/explorer_backpack/explorer_backpack.blend`. It contains the original hero as a fitting reference. The runtime GLB exports only the accessory and its skin reference, not another character mesh. Materials were baked procedurally in Blender; no external textures were downloaded. Reference originals remain untouched.

## Validation

42 focused tests passed with no errors in the final test log: backpack skin bindings/materials, hero motion, animator, squash, combat verbs and surface budgets. The original hero GLB hash matches the pre-change file; the controller diff is exactly one visual attachment call. Static analysis and level contract checks passed.

The actual game ran 13 checks successfully: equipment presence and shared skeleton, land contact, real keyboard walking and rolling, entering Living Cascade, swimming, spin start/end, wetness and equipment retention through the transition. Five static views and sampled walk/swim/roll/spin/tail-attack poses were rendered in Godot. The initial harness clipping was corrected by transferring the underlying torso weights; the contoured underside and stitches were refined after close-up inspection. This is a check of these sampled poses, not exhaustive collision certification for every possible animation blend.

Full-level capture shutdown diagnostics:

```text
WARNING: 7 RIDs of type "Texture" were leaked.
   at: finalize (servers/rendering/rendering_device.cpp:8900)
```

These diagnostics, if present, occur at capture shutdown after the successful gameplay checks. No production workaround was added to hide renderer warnings. The review harness waits for transient splash timers before freeing their scene.

The full game unit suite, complete level route and physical mobile-device profiling were not rerun for this accessory. The focused tests and movement checks above are the validation for this change. No Git commit was created.


## Flatter fit follow-up

The canvas depth is reduced by 60%, with a curved bag and thinner fitted pad. The 42 focused tests and 13 gameplay checks were rerun. See [fit notes](hero-backpack-flat-notes.md) for dimensions and before/after evidence.
