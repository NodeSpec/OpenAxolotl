# Living Cascade surface textures

Five CC0 material families from Poly Haven. Each includes 2048 × 2048 colour, OpenGL normal and packed ARM maps (ambient occlusion, roughness, metalness). Terrain uses the AO/roughness channels and remains nonmetallic.

Import settings: VRAM compression, high quality, mipmaps enabled, 2048 size limit; normal maps explicitly use Normal Map import mode. The shader requests repeating anisotropic mipmapped filtering. Keep these `.import` configuration files with the sources; Godot regenerates `.godot/imported` on another computer.

`sources.json` records exact download URLs, credits and SHA-256 hashes. Its catalog dimensions are source metadata, not raster size. All 15 image files were independently verified as 2048 × 2048.

Material selection is in `dev/living_cascade/cascade_surface_library.gd`. The generator packs those materials into `worlds/coral_cove/world.tscn`.

License: https://polyhaven.com/license (CC0).

- [rock_face_03](https://polyhaven.com/a/rock_face_03) — Dario Barresi, Rico Cilliers.
- [mossy_rock](https://polyhaven.com/a/mossy_rock) — Rob Tuytel.
- [sand_01](https://polyhaven.com/a/sand_01) — Rob Tuytel.
- [leafy_grass](https://polyhaven.com/a/leafy_grass) — Charlotte Baglioni.
- [dry_river_pebbles](https://polyhaven.com/a/dry_river_pebbles) — Amal Kumar.
