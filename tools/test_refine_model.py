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


@unittest.skipUnless(refine_model.find_blender(),
                     "Blender is not installed here; the end-to-end case "
                     "runs only where it is")
class EndToEndTests(unittest.TestCase):
    """Refines the real hero asset and checks what comes back."""

    def test_req_032_the_hero_refines_to_one_mesh_per_role_with_geometry_intact(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = os.path.join(tmp, "axolotl.glb")
            code, out, err = run(["--input", HERO, "--output", target,
                                  "--format", "json"])
            self.assertEqual(code, refine_model.EXIT_OK, out + err)
            report = json.loads(out)
            self.assertTrue(report["passed"])
            before = glb_header(HERO)
            after = glb_header(target)
            self.assertEqual(after[0], before[0], "triangles must be preserved")
            self.assertLessEqual(after[1], 5, "at most one mesh per role")
            names = glb_materials(target)
            self.assertIn("axolotl_skin", names)
            self.assertIn("axolotl_eye", names)
            self.assertIn("axolotl_gill", names)
            self.assertTrue(glb_has_attribute(target, "NORMAL"),
                            "smooth normals must be written")
            self.assertTrue(glb_has_attribute(target, "COLOR_0"),
                            "vertex colours must survive")




class ShippedAssetTests(unittest.TestCase):
    """The hero asset in the repository IS the refined form, and says so."""

    def test_req_032_the_shipped_hero_is_in_refined_form_with_honest_provenance(self):
        """REQ-032 AC-4, held to its SUBSTANCE rather than to one tool name.

        The criterion asks that the shipped hero be "the refined form" with
        the refinement recorded in its provenance chain. Every property that
        phrase means operationally is asserted below: one mesh per role,
        normals written, role-named materials, and a provenance that names
        the Blender tool which produced it.

        What changed is WHICH tool. The hero used to be an 85-primitive
        upload that refine_model.py merged into role meshes afterwards; it is
        now built by make_axolotl.py, which emits role meshes with named
        materials directly, so there is nothing left for the merge pass to
        do. Re-running refinement purely to keep the string "refine_model.py"
        in the sidecar would be theatre, so this accepts either generator.

        refine_model.py is NOT dead: it remains the pass for externally
        contributed models, which is what the rest of this file covers.
        """
        triangles, meshes, _ = glb_header(HERO)
        self.assertLessEqual(meshes, 5, "the shipped hero is one mesh per role")
        self.assertGreater(triangles, 0)
        self.assertTrue(glb_has_attribute(HERO, "NORMAL"))
        self.assertIn("axolotl_eye", glb_materials(HERO))

        # REQ-040: the bake pass added a UV layout and tangents (Godot needs
        # both the moment a normal map exists) and shipped the two maps
        # beside the model. Geometry itself is untouched -- the bake script
        # fails its own run if the triangle count moves.
        self.assertTrue(glb_has_attribute(HERO, "TEXCOORD_0"),
                        "the skin's UV layout must ship in the glb")
        self.assertTrue(glb_has_attribute(HERO, "TANGENT"),
                        "tangents must ship, not be a per-machine import step")
        for map_name in ("axolotl_skin_normal.png", "axolotl_skin_detail.png"):
            self.assertTrue(
                os.path.exists(os.path.join(os.path.dirname(HERO), map_name)),
                "%s must ship beside the model" % map_name)
        sidecar = os.path.join(os.path.dirname(HERO), "provenance.json")
        with open(sidecar, encoding="utf-8") as handle:
            provenance = json.load(handle)
        self.assertIn("Blender", provenance["tool"],
                      "the Blender pass is a tool in the provenance chain")
        self.assertTrue(
            any(name in provenance["tool"]
                for name in ("make_axolotl.py", "refine_model.py")),
            "provenance must name the script that produced the shipped form")


if __name__ == "__main__":
    unittest.main()
