# Source assets

Original models awaiting optimization and rigging belong here. `.gdignore`
keeps them out of Godot imports, and the export preset excludes this folder.
The runtime asset validator validates `assets/`, not these source files.

`axolotl/pink_axolotl_2_0.glb` is the unchanged file originally committed as
`assets/character/axolotl/Pink_axolotl_2.0.glb`. It has embedded textures,
1,933,518 triangles and no skin or animation. Preserve this original while
producing an optimized, rigged derivative for `assets/character/`.
Record the generator, source reference and applicable redistribution terms
in the derivative's provenance before runtime integration.
