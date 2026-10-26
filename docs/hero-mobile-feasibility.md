# OpenAxolotl — mobile/tablet feasibility

## Assessment

A mobile/tablet version is technically feasible in principle. The genre and number of level sections do not inherently require a console or high-end desktop. The current project is nevertheless a desktop build, not a validated mobile release.

The repository documents PC-only scope and currently supplies a Linux desktop export preset. `project.godot` identifies Forward+ rendering. Its Low/Medium/High graphics settings provide a useful starting point, but desktop Low is not a tested mobile preset. No platform policies or export settings were changed in this backpack task.

The documented desktop target is a 2020-class family PC with four cores/eight threads, 8 GB RAM and GTX 1650 / RX 570-class graphics at 1080p/60 FPS. This is a target, not a certified minimum: recent rendered measurements were performed on an RTX 5090 Laptop GPU, and physical baseline-machine validation remains open.

The equipped Cascade scene contains 2,978,940 triangles in the project's existing content counter; the new backpack contributes 19,918. Total scene triangles are not the same as visible triangles per frame. Draw calls, shadow passes, water transparency, terrain shader sampling, memory and thermal limits also determine mobile performance.

## Proposed mobile feasibility pass — not executed

1. Agree on an explicit device floor and select representative physical Android phone/tablet hardware. Start with a provisional 30 FPS sustained target; decide whether a higher tier should offer 60 FPS after measurements.
2. Build one demanding playable slice: starting lagoon, the continuous tunnel and heavy Living Cascade views. Use Godot's Mobile renderer, audit unsupported effects and shaders, and compare art against desktop.
3. Introduce platform-specific lighting, water and terrain settings. Reduce expensive transparency/refraction and shadow work; use simpler lighting where appropriate. Preserve the hero and nearby surfaces first.
4. Profile visible geometry/draw calls and add suitable distance detail reduction, foliage density controls, shadow proxies and texture budgets. Atlas accessory surfaces and bake tiny stitch geometry if actual mobile measurements justify it.
5. Audit package contents: source/reference/dev/review artifacts should not inflate a release export. Measure actual export size, peak memory and load time; use appropriate Android/iOS texture formats.
6. Design touch movement, camera, swimming depth and action controls plus readable HUD sizing and safe areas. Retain gamepad support.
7. Run sustained sessions on physical devices, covering restoration, streaming, combat effects and underwater sections. Record frame pacing, heat throttling, memory, battery impact, suspend/resume and touch usability.
8. Set a supported-device floor from evidence, then build the iOS version using the required Apple tooling. Store packaging, signing and submission are separate release work.

Changing the platform target would be a deliberate scope expansion from the existing PC-only specification. It is a practical option, not a promise that the current desktop export runs well on every phone or tablet.

## Official documentation consulted

- [Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html): Forward+ targets desktop; Mobile and Compatibility cover different mobile hardware/features.
- [Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
- [iOS export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html).

Assessment date: 2026-09-19. No mobile build, store submission or platform migration was performed.
