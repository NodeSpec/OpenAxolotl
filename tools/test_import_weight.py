"""What the Godot editor is allowed to import — REQ-027, REQ-015.

Test names carry the requirement id they prove (REQ-026 AC-6).

WHY THIS FILE EXISTS, and it is not a hypothetical. `reference/hero/
pink_axolotl_2.glb` is a 73 MB Meshy export: 1,933,518 triangles and two
4096x4096 JPEGs. It is SOURCE MATERIAL — the thing the shipped hero is
matched against — and it must never reach the engine. What keeps it out is a
single empty file, `reference/.gdignore`, which tells Godot to skip that
directory in its filesystem scan.

That file arrived one commit AFTER the model did. In the window between, the
editor imported the whole thing: decoding two 4096 JPEGs is 134 MB of
uncompressed pixels before compression, on top of a two-million-triangle mesh
that needs tangents and index buffers generated. On a developer machine that
is a slow first open. On an eight-year-old laptop with a 2 GB mobile GPU it
is the editor dying on the progress bar before it ever reaches the workspace,
which is exactly what happened.

The failure mode is what makes it worth a test rather than a note:

  * IT IS SILENT. Deleting an empty file is not a diff anyone reads closely,
    there is no error, and nothing in the suite notices. The next person to
    open the project finds out instead.
  * IT IS INVISIBLE ON GOOD HARDWARE. A fast desktop imports the 73 MB model
    in a few seconds and never complains, so the person who breaks it is
    usually not the person who pays for it.
  * IT SCALES WITH THE PIPELINE. Every future Meshy asset lands in
    `reference/` at the same weight. This is the first of them, not the last.

So two things are held here. The directories that must stay out of the import
are checked for their marker, and — the general guard — nothing the editor
WOULD import is allowed to be huge. The second is the one that catches the
next mistake, because it does not need to know which directories exist.
"""

from __future__ import annotations

import os
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## Directories whose contents are deliberately outside the engine's reach.
## Each must carry a .gdignore, and each is here for its own reason:
##   reference/ — source material the look is matched against; nothing ships
##   tools/     — Python, which Godot would otherwise scan for scripts
##   fixtures/  — test data, some of it deliberately malformed
IGNORED_TREES = ("reference", "tools", "fixtures")

## The heaviest single file the editor may import, in bytes.
##
## SIXTEEN MEGABYTES, and the number comes from the gap rather than from
## taste. The largest file the game legitimately imports today is the shipped
## hero at 2.85 MB, and the largest texture is 1.03 MB; the file this test was
## written for is 73 MB. Anything between those is a judgement call nobody has
## had to make yet, so the ceiling sits far above real assets and far below
## the accident — high enough never to argue with normal work, low enough that
## a raw generator export cannot slip in unnoticed.
MAX_IMPORTED_BYTES = 16 * 1024 * 1024

## Extensions Godot imports rather than merely reads. A .md or .json costs
## nothing at import; a mesh or a texture is decoded, converted and cached.
IMPORTED_SUFFIXES = (".glb", ".gltf", ".png", ".jpg", ".jpeg", ".webp",
                     ".exr", ".hdr", ".svg", ".ogg", ".wav", ".mp3", ".ttf")

## Not part of the project's own tree.
SKIP_ALWAYS = (".git", ".godot", ".toolchain", "build", "__pycache__")


def importable_files() -> list:
    """Every file the editor would import, walked the way Godot walks.

    Godot skips a directory entirely when it contains a .gdignore, including
    everything beneath it, so this prunes the same way rather than listing
    paths and filtering afterwards — a filter would have to know the ignore
    rules, and then the test would be asserting its own copy of them.
    """
    found: list = []
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [name for name in dirs if name not in SKIP_ALWAYS]
        if ".gdignore" in files:
            dirs[:] = []
            continue
        for name in files:
            if name.lower().endswith(IMPORTED_SUFFIXES):
                path = os.path.join(root, name)
                found.append((os.path.relpath(path, REPO),
                              os.path.getsize(path)))
    return sorted(found)


class ImportWeightTests(unittest.TestCase):

    def test_req_027_directories_kept_out_of_the_engine_carry_their_marker(self):
        # The marker is an empty file, so it is deleted by accident far more
        # easily than it is deleted on purpose.
        for tree in IGNORED_TREES:
            directory = os.path.join(REPO, tree)
            if not os.path.isdir(directory):
                continue
            self.assertTrue(
                os.path.isfile(os.path.join(directory, ".gdignore")),
                "%s/.gdignore is missing: Godot will import everything under "
                "%s/ on the next project open, which for reference/ means a "
                "73 MB, 1.9-million-triangle model and two 4096 textures"
                % (tree, tree))

    def test_req_027_nothing_the_editor_imports_is_oversized(self):
        # The general guard. It does not know what reference/ is, which is the
        # point: it catches the next heavy export wherever it lands.
        oversized = [(path, size) for path, size in importable_files()
                     if size > MAX_IMPORTED_BYTES]
        self.assertEqual(
            oversized, [],
            "these files are inside the engine's import scan and over the "
            "%d MB ceiling:\n%s\nEither they belong under a .gdignore'd "
            "directory (source material, generator input), or they need "
            "reducing before they ship."
            % (MAX_IMPORTED_BYTES // (1024 * 1024),
               "\n".join("    %s — %.1f MB" % (path, size / 1024 / 1024)
                         for path, size in oversized)))

    def test_req_027_the_reference_hero_is_actually_out_of_reach(self):
        """The specific case, named, because it is the one that broke.

        A general ceiling would go quiet if someone moved the model somewhere
        the walk does not reach for an unrelated reason. This asserts the
        arrangement itself: the file is in the repository, and the walk that
        mirrors Godot's does not see it.
        """
        source = os.path.join(REPO, "reference", "hero", "pink_axolotl_2.glb")
        if not os.path.isfile(source):
            self.skipTest("the Meshy source export is not in this checkout")
        self.assertGreater(os.path.getsize(source), MAX_IMPORTED_BYTES,
                           "if the source export is no longer oversized this "
                           "test has stopped proving anything — check why")
        seen = [path for path, _size in importable_files()]
        self.assertNotIn(os.path.join("reference", "hero",
                                      "pink_axolotl_2.glb"), seen,
                         "the Meshy source export is visible to the import "
                         "scan; reference/.gdignore is missing or ineffective")


if __name__ == "__main__":
    unittest.main()
