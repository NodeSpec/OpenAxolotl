"""Tests for the Blender refinement pipeline — REQ-032.

Test names carry the requirement id they prove (REQ-026 AC-6).

Most of these need no Blender: they hold the CLI's contract — the documented
command line, the invocation-error rules, the refusal to pass silently when
the tool is missing. The one end-to-end case runs only where Blender is
installed, on the real hero asset, and is skipped (never faked) elsewhere.
"""

from __future__ import annotations

import io
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import refine_model  # noqa: E402
from asset_contract_validator import glb_header  # noqa: E402
from asset_fixtures import write_glb  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HERO = os.path.join(REPO, "assets", "character", "axolotl", "axolotl.glb")
BLENDER_SCRIPT = os.path.join(REPO, "tools", "blender", "refine_model.py")

# The palette thresholds the Blender script must share with hero_skin.gd.
HERO_SKIN = os.path.join(REPO, "core", "rendering", "hero_skin.gd")


def run(argv: list[str]) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = refine_model.main(argv)
    return code, out.getvalue(), err.getvalue()


def glb_materials(path: str) -> list[str]:
    with open(path, "rb") as handle:
        handle.read(12)
        length, _ = struct.unpack("<II", handle.read(8))
        document = json.loads(handle.read(length))
    return [m.get("name", "") for m in document.get("materials", [])]


def glb_has_attribute(path: str, attribute: str) -> bool:
    with open(path, "rb") as handle:
        handle.read(12)
        length, _ = struct.unpack("<II", handle.read(8))
        document = json.loads(handle.read(length))
    return all(attribute in p["attributes"]
               for m in document.get("meshes", []) for p in m["primitives"])


class CommandLineTests(unittest.TestCase):
    """The documented invocation, and the rules around it."""

    def test_req_032_the_documented_command_line_is_the_one_built(self):
        argv = refine_model.build_argv("/opt/blender", "/in.glb", "/out.glb", 45.0)
        self.assertEqual(argv[:6], ["/opt/blender", "--background",
                                    "--python-exit-code", "1",
                                    "--python", BLENDER_SCRIPT])
        self.assertEqual(argv[6], "--")
        self.assertIn("--input", argv)
        self.assertIn("--output", argv)
        self.assertEqual(argv[argv.index("--smooth-angle") + 1], "45.0")

    def test_req_032_dry_run_prints_the_command_and_touches_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            target = os.path.join(tmp, "out.glb")
            with mock.patch.object(refine_model, "find_blender",
                                   return_value="/opt/blender"):
                code, out, _ = run(["--input", source, "--output", target,
                                    "--dry-run"])
            self.assertEqual(code, refine_model.EXIT_OK)
            self.assertIn("--background", out)
            self.assertFalse(os.path.exists(target))

    def test_req_032_no_blender_is_an_invocation_error_never_a_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            with mock.patch.dict(os.environ, {"OAX_BLENDER": "", "PATH": tmp}):
                code, _, err = run(["--input", source,
                                    "--output", os.path.join(tmp, "o.glb")])
            self.assertEqual(code, refine_model.EXIT_INVOCATION)
            self.assertIn("Blender", err)

    def test_req_032_a_missing_or_non_glb_input_is_an_invocation_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, _, _ = run(["--input", os.path.join(tmp, "absent.glb"),
                              "--output", os.path.join(tmp, "o.glb")])
            self.assertEqual(code, refine_model.EXIT_INVOCATION)
            text = os.path.join(tmp, "notes.txt")
            with open(text, "w", encoding="utf-8") as handle:
                handle.write("not a model")
            code, _, _ = run(["--input", text,
                              "--output", os.path.join(tmp, "o.glb")])
            self.assertEqual(code, refine_model.EXIT_INVOCATION)

    def test_req_032_the_category_budget_is_read_from_the_asset_path(self):
        self.assertEqual(refine_model.category_for(
            os.path.join(REPO, "assets", "creature", "whale", "whale.glb")),
            "creature")
        self.assertIsNone(refine_model.category_for("/tmp/loose.glb"))
        budget = refine_model.triangle_budget("creature",
                                              refine_model.DEFAULT_CONTRACT)
        self.assertEqual(budget, 30000)
        self.assertIsNone(refine_model.triangle_budget(
            None, refine_model.DEFAULT_CONTRACT))


class PaletteParityTests(unittest.TestCase):
    """The Blender script and the game classify by the SAME thresholds."""

    def test_req_032_palette_thresholds_match_hero_skin(self):
        with open(BLENDER_SCRIPT, encoding="utf-8") as handle:
            blender_side = handle.read()
        with open(HERO_SKIN, encoding="utf-8") as handle:
            game_side = handle.read()
        for name, value in (("EYE_MAX_LUMINANCE", "0.15"),
                            ("DETAIL_MAX_LUMINANCE", "0.4"),
                            ("GLEAM_MIN_CHANNEL", "0.97"),
                            ("GILL_MAX_GREEN", "0.5")):
            self.assertIn(f"{name} = {value}", blender_side, name)
            self.assertIn(f"const {name} := {value}", game_side, name)


## Builds the end-to-end fixture: two vertex-coloured meshes, one near-black
## (an eye) and one deep pink (a gill), which is the input shape refinement
## exists for.
##
## A FIXTURE RATHER THAN THE SHIPPED HERO, and the reason is the point of this
## file. This case used to refine assets/character/axolotl/axolotl.glb, which
## worked only while the hero happened to be the in-repo generator's
## vertex-coloured output. The shipped hero is now an externally authored,
## TEXTURED single surface: refinement would classify it as one role, clear
## the material carrying its maps, and the test would have been asserting
## that a destructive pass ran cleanly. Refinement is still the pass for
## contributed vertex-coloured models, so it is proven on one of those.
FIXTURE_SCRIPT = """
import sys
import bpy

path = sys.argv[sys.argv.index("--") + 1:][0]
bpy.ops.wm.read_factory_settings(use_empty=True)
for name, colour, offset in (("dark", (0.04, 0.05, 0.08, 1.0), 0.0),
                             ("pink", (0.90, 0.43, 0.53, 1.0), 3.0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(offset, 0, 0))
    obj = bpy.context.object
    obj.name = name
    layer = obj.data.color_attributes.new(
        name="Col", type="FLOAT_COLOR", domain="CORNER")
    for entry in layer.data:
        entry.color = colour
bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                          export_colors=True, export_materials="EXPORT")
"""


def build_fixture(directory: str) -> str:
    script = os.path.join(directory, "fixture.py")
    with open(script, "w", encoding="utf-8") as handle:
        handle.write(FIXTURE_SCRIPT)
    path = os.path.join(directory, "fixture.glb")
    subprocess.run([refine_model.find_blender(), "--background",
                    "--python-exit-code", "1", "--python", script, "--", path],
                   check=True, capture_output=True, text=True)
    return path


@unittest.skipUnless(refine_model.find_blender(),
                     "Blender is not installed here; the end-to-end case "
                     "runs only where it is")
class EndToEndTests(unittest.TestCase):
    """Refines a vertex-coloured model and checks what comes back."""

    def test_req_032_a_vertex_coloured_model_merges_into_role_meshes(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = build_fixture(tmp)
            target = os.path.join(tmp, "refined.glb")
            code, out, err = run(["--input", source, "--output", target,
                                  "--format", "json"])
            self.assertEqual(code, refine_model.EXIT_OK, out + err)
            self.assertTrue(json.loads(out)["passed"])

            before = glb_header(source)
            after = glb_header(target)
            self.assertEqual(after[0], before[0], "triangles must be preserved")

            names = glb_materials(target)
            self.assertIn("axolotl_eye", names,
                          "the near-black mesh must be classified as an eye")
            self.assertIn("axolotl_gill", names,
                          "the deep pink mesh must be classified as a gill")
            self.assertTrue(glb_has_attribute(target, "NORMAL"),
                            "smooth normals must be written")
            self.assertTrue(glb_has_attribute(target, "COLOR_0"),
                            "vertex colours must survive")


class ShippedAssetTests(unittest.TestCase):
    """The hero asset in the repository, held to what it now IS."""

    def test_req_032_the_shipped_hero_is_game_ready_with_honest_provenance(self):
        """REQ-032 AC-4, held to its SUBSTANCE rather than to one pipeline.

        The criterion asks that the shipped hero be a game-ready form with
        the passes that produced it recorded in its provenance chain. What
        "game-ready" means operationally has not changed -- skinned, normals,
        UVs, tangents, every animation clip the client plays, inside the
        category's triangle budget -- but WHICH pipeline produced it has
        changed twice now, and pinning the assertions to a script name would
        make this test about the tooling instead of the asset.

        It used to require one mesh per role with `axolotl_<role>` materials,
        because the in-repo generator emitted exactly that. The shipped hero
        is now an external Meshy export: a single textured surface whose face
        is painted rather than modelled, brought inside by decimate, fit and
        rig passes that ARE in this repository. Requiring role materials of
        it would mean either failing a perfectly good asset or splitting it
        pointlessly to satisfy a string.
        """
        triangles, meshes, animations = glb_header(HERO)
        self.assertGreater(triangles, 0)
        self.assertLessEqual(triangles, 60000,
                             "the hero must sit inside the character budget")
        self.assertGreaterEqual(meshes, 1)

        for clip in ("idle", "waddle", "swim", "hop", "fall", "hurt"):
            self.assertIn(clip, animations,
                          "the client plays %s, so the hero must carry it"
                          % clip)

        self.assertTrue(glb_has_attribute(HERO, "NORMAL"))
        self.assertTrue(glb_has_attribute(HERO, "TEXCOORD_0"),
                        "the UV layout must ship in the glb")
        self.assertTrue(glb_has_attribute(HERO, "TANGENT"),
                        "tangents must ship, not be a per-machine import step")
        self.assertTrue(glb_has_attribute(HERO, "JOINTS_0"),
                        "the hero must be skinned or the rig poses nothing")

        sidecar = os.path.join(os.path.dirname(HERO), "provenance.json")
        with open(sidecar, encoding="utf-8") as handle:
            provenance = json.load(handle)
        self.assertIn("Blender", provenance["tool"],
                      "the Blender passes are tools in the provenance chain")
        self.assertTrue(
            any(name in provenance["tool"]
                for name in ("make_axolotl.py", "refine_model.py",
                             "rig_model.py", "decimate_model.py")),
            "provenance must name the passes that produced the shipped form")
        self.assertIn("licenseTerms", provenance)


if __name__ == "__main__":
    unittest.main()
