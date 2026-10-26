# Editor Startup Workaround

Double-click `Open Lagoon Editor.cmd` in this folder. Close other editors for
this project before starting it. The initial import check may take a little time.

The launcher runs a headless import scan first, stops if that fails, then opens
the editor with Direct3D 12 and the existing Forward+ renderer. It requests a
1280x720 single window on the first display. It does not downgrade the project
to Compatibility rendering or change project.godot, gameplay, or asset files.
Godot may still restore some saved editor layout preferences.

Logs are written to `review/editor-import.log` and `review/editor-startup.log`.
`GODOT_BIN` can override the executable path. Arguments supplied to the launcher
are forwarded to the graphical editor, not to the import check.

## Diagnosis, September 10, 2026

Windows Application events recorded two editor crashes, at 11:39 and 11:42 local
time, in NVIDIA's `nvoglv64.dll` (driver 581.83 / 32.0.15.8183). The exceptions
were `0xc0000409` and `0xc0000005`. The GPU is a GeForce MX250 with 2 GB VRAM.
These records identify where the crashes occurred, not the precise trigger.

Subsequent checks succeeded without changing the lagoon scene or its assets:

- Headless import scan and reopening `hub/open_lagoon.tscn`: exit 0.
- Vulkan editor, requested single-window 1280x720 startup: exit 0.
- Vulkan editor, requested maximized second-display startup: exit 0.
- Direct3D 12 editor with the lagoon scene and tool scripts enabled: exit 0.
- Complete `Open Lagoon Editor.cmd --quit-after 120` import/editor sequence: exit 0.

The intermittent crash was not reproduced during those bounded tests. An asset
or shader could still expose a driver problem; successful cached imports do not
prove that every fresh-import condition is safe. The alternate launcher is a
workaround, not a verified permanent driver fix. Original crash evidence remains
in Windows Event Viewer. Diagnostic logs are in `review/import-diagnostic-*.log`.

If it happens again, retain the startup logs and note the import filename or
progress step shown immediately before the crash. Avoid deleting the project or
all import caches as a first step; those would discard useful diagnostic state.

The launch options are documented in the [Godot command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
