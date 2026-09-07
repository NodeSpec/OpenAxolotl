"""Tests for the decimation stage of the Blender pipeline — REQ-032, REQ-015.

Test names carry the requirement id they prove (REQ-026 AC-6).

Decimation is the one pipeline stage that can pass every machine check and
still have ruined the asset: the triangle count goes green, the file shrinks,
and a gill filament is gone. So these tests are not mostly about the CLI's
argument handling. The two that matter run Blender for real and hold the
deviation gate to BOTH halves of its job — it must let a faithful reduction
through, and it must stop one that lost shape. A gate proven only on the
passing case is a gate that has never been shown to do anything.

The Blender cases are skipped, never faked, where Blender is not installed.
"""

from __future__ import annotations

import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import decimate_model  # noqa: E402
from asset_contract_validator import glb_header  # noqa: E402
from asset_fixtures import write_glb  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HERO = os.path.join(REPO, "assets", "character", "axolotl", "axolotl.glb")
BLENDER_SCRIPT = os.path.join(REPO, "tools", "blender", "decimate_model.py")


def run(argv: list[str]) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = decimate_model.main(argv)
    return code, out.getvalue(), err.getvalue()


class CommandLineTests(unittest.TestCase):
    """The documented invocation, and the rules around it."""

    def test_req_032_the_documented_command_line_is_the_one_built(self):
        argv = decimate_model.build_argv(
            "/opt/blender", "/in.glb", "/out.glb", 55000, 2048, 20000)
        self.assertEqual(argv[:6], ["/opt/blender", "--background",
                                    "--python-exit-code", "1",
                                    "--python", BLENDER_SCRIPT])
        self.assertEqual(argv[6], "--")
        self.assertEqual(argv[argv.index("--max-triangles") + 1], "55000")
        self.assertEqual(argv[argv.index("--max-texture") + 1], "2048")

    def test_req_032_dry_run_prints_the_command_and_touches_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            target = os.path.join(tmp, "out.glb")
            with mock.patch.object(decimate_model, "find_blender",
                                   return_value="/opt/blender"):
                code, out, err = run(["--input", source, "--output", target,
                                      "--max-triangles", "100", "--dry-run"])
            self.assertEqual(code, decimate_model.EXIT_OK, err)
            self.assertIn("--background", out)
            self.assertFalse(os.path.exists(target))

    def test_req_032_no_blender_is_an_invocation_error_never_a_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            with mock.patch.dict(os.environ, {"OAX_BLENDER": "", "PATH": tmp}):
                code, _, err = run(["--input", source, "--max-triangles", "10",
                                    "--output", os.path.join(tmp, "o.glb")])
            self.assertEqual(code, decimate_model.EXIT_INVOCATION)
            self.assertIn("Blender", err)

    def test_req_032_writing_over_the_dense_source_is_refused(self):
        # Decimation cannot be undone, and the dense original is the only
        # thing a second attempt at a different ratio can start from. Losing
        # it to a typo would cost a trip back to the generator.
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            with mock.patch.object(decimate_model, "find_blender",
                                   return_value="/opt/blender"):
                code, _, err = run(["--input", source, "--output", source,
                                    "--max-triangles", "100"])
            self.assertEqual(code, decimate_model.EXIT_INVOCATION)
            self.assertIn("differ", err)

    def test_req_015_the_budget_and_texture_ceiling_come_from_the_contract(self):
        # Neither number is restated in an agent's command line, so neither
        # can drift from the contract that CI enforces.
        contract = decimate_model.DEFAULT_CONTRACT
        character = os.path.join(REPO, "assets", "character", "x", "x.glb")
        self.assertEqual(decimate_model.category_for(character), "character")
        self.assertEqual(
            decimate_model.triangle_budget("character", contract), 60000)
        self.assertEqual(
            decimate_model.texture_ceiling("character", contract), 2048)
        self.assertEqual(
            decimate_model.texture_ceiling("environment", contract), 4096)

    def test_req_015_a_loose_output_path_with_no_budget_is_an_invocation_error(self):
        # Outside assets/<category>/ there is no contract budget to read, and
        # guessing one would let an over-budget asset through unnoticed.
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "thing.glb")
            write_glb(source)
            with mock.patch.object(decimate_model, "find_blender",
                                   return_value="/opt/blender"):
                code, _, err = run(["--input", source,
                                    "--output", os.path.join(tmp, "o.glb")])
            self.assertEqual(code, decimate_model.EXIT_INVOCATION)
            self.assertIn("max-triangles", err)


class DeviationReadingTests(unittest.TestCase):
    """The worst reading across both directions is the one that gates."""

    def test_req_032_the_gate_reads_the_worse_of_the_two_directions(self):
        # Loss and invention are different failures and are measured
        # separately; taking the max is what stops a good forward number from
        # covering for a mesh that dropped a limb.
        summary = {"deviation": [
            {"direction": "decimated_to_original",
             "maxAsFractionOfDiagonal": 0.001, "worstAt": [0, 0, 0]},
            {"direction": "original_to_decimated",
             "maxAsFractionOfDiagonal": 0.049, "worstAt": [1, 2, 3]},
        ]}
        worst, entry = decimate_model.worst_deviation(summary)
        self.assertAlmostEqual(worst, 0.049)
        self.assertEqual(entry["direction"], "original_to_decimated")
        self.assertEqual(decimate_model.worst_deviation({"deviation": []}),
                         (0.0, None))


## Builds the end-to-end fixtures. A purpose-made sphere rather than a
## shipped asset, because NOTHING in assets/ can serve as a fixture here:
## every model in the repository is procedurally generated at the density it
## needs, so halving any of them genuinely loses shape and there is no
## "faithful reduction" to demonstrate. A subdivided sphere has exactly the
## property the Meshy exports have — far more triangles than its shape needs
## — which is the situation this tool exists for.
FIXTURE_SCRIPT = '''
import sys
import bmesh
import bpy

path, seam = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=6, radius=1.0)

if seam == "split":
    # Sever every edge that crosses the equator. The two halves keep their
    # coincident vertices and sit exactly where they did, so the sphere still
    # LOOKS closed -- which is precisely how the Meshy hero arrived, and
    # precisely what a decimation pulls apart.
    mesh = bmesh.new()
    mesh.from_mesh(bpy.context.object.data)
    crossing = [edge for edge in mesh.edges
                if edge.verts[0].co.z * edge.verts[1].co.z < 0.0]
    bmesh.ops.split_edges(mesh, edges=crossing)
    mesh.to_mesh(bpy.context.object.data)
    mesh.free()

bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                          export_materials="NONE")
'''


def build_fixture(directory: str, seam: str) -> str:
    """A dense sphere glb, optionally split along its equator."""
    script = os.path.join(directory, "fixture.py")
    with open(script, "w", encoding="utf-8") as handle:
        handle.write(FIXTURE_SCRIPT)
    path = os.path.join(directory, "fixture_%s.glb" % seam)
    subprocess.run([decimate_model.find_blender(), "--background",
                    "--python-exit-code", "1", "--python", script, "--",
                    path, seam], check=True, capture_output=True, text=True)
    return path


@unittest.skipUnless(decimate_model.find_blender(),
                     "Blender is not installed here; the end-to-end cases "
                     "run only where it is")
class EndToEndTests(unittest.TestCase):
    """Real Blender, and every gate held to both of its answers."""

    def _decimate(self, tmp: str, source: str, budget: int,
                  extra: list[str] | None = None) -> tuple[int, dict, str]:
        target = os.path.join(tmp, "assets", "character", "x")
        os.makedirs(target, exist_ok=True)
        out_path = os.path.join(target, "x.glb")
        code, out, err = run(["--input", source, "--output", out_path,
                              "--max-triangles", str(budget),
                              "--samples", "4000", "--format", "json"]
                             + (extra or []))
        return code, json.loads(out), out_path

    def test_req_032_a_faithful_reduction_passes_and_reports_what_it_cost(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = build_fixture(tmp, "closed")
            triangles_before, _, _ = glb_header(source)
            budget = triangles_before // 10
            code, report, out_path = self._decimate(tmp, source, budget)
            self.assertEqual(code, decimate_model.EXIT_OK, json.dumps(report))
            self.assertTrue(report["passed"])

            triangles_after, _, _ = glb_header(out_path)
            self.assertLessEqual(triangles_after, budget)
            self.assertGreater(triangles_after, budget * 0.9,
                               "the reduction must reach its target, not "
                               "undershoot it and waste the budget")

            # The evidence, not just the verdict: both directions measured,
            # and each one saying where its worst point was.
            directions = {entry["direction"]
                          for entry in report["summary"]["deviation"]}
            self.assertEqual(directions, {"decimated_to_original",
                                          "original_to_decimated"})
            for entry in report["summary"]["deviation"]:
                self.assertEqual(len(entry["worstAt"]), 3, entry["direction"])
                self.assertGreater(entry["samples"], 0)

    def test_req_032_a_reduction_that_loses_shape_fails_the_gate(self):
        """The deviation gate has teeth — proven, not asserted.

        The passing case above says only that the tool runs. This one drives
        the same sphere down to a coarse hull, where the surface demonstrably
        moves, and requires the command to FAIL on DEVIATION rather than on
        the triangle budget it would happily meet.
        """
        with tempfile.TemporaryDirectory() as tmp:
            source = build_fixture(tmp, "closed")
            code, report, _ = self._decimate(tmp, source, 120)
            self.assertEqual(code, decimate_model.EXIT_VIOLATIONS,
                             json.dumps(report))
            rules = [entry["rule"] for entry in report["violations"]]
            self.assertIn("model-decimator.shape_deviation", rules,
                          "a sphere reduced to a coarse hull must be caught "
                          "by the SHAPE gate, not merely by the budget")

    def test_req_032_a_seam_split_surface_is_welded_before_it_is_collapsed(self):
        """The failure the deviation measurement CANNOT see.

        A mesh split along a seam has both lips sitting on the original
        surface no matter how far they drift apart, so every distance sample
        stays green while the model renders with black hairline cracks. This
        is how the hero arrived: 84,666 edges with one face on them.

        Both halves are asserted. Welded (the default), the seam closes and
        the reduction passes. With --weld 0, the same reduction tears the
        surface open and must be REFUSED — if it were not, this test would
        pass on a tool that did no welding at all.
        """
        with tempfile.TemporaryDirectory() as tmp:
            source = build_fixture(tmp, "split")
            triangles_before, _, _ = glb_header(source)
            budget = triangles_before // 10

            code, report, _ = self._decimate(tmp, source, budget)
            self.assertEqual(code, decimate_model.EXIT_OK, json.dumps(report))
            welding = report["summary"]["weld"]
            self.assertGreater(welding["openEdgesBefore"], 0,
                               "the fixture must actually arrive split, or "
                               "this test proves nothing")
            self.assertEqual(welding["openEdgesAfter"], 0,
                             "the weld must close every seam")
            self.assertEqual(welding["openEdgesAfterDecimation"], 0,
                             "and the collapse must not reopen them")

            code, report, _ = self._decimate(tmp, source, budget,
                                             ["--weld", "0"])
            self.assertEqual(code, decimate_model.EXIT_VIOLATIONS,
                             json.dumps(report))
            rules = [entry["rule"] for entry in report["violations"]]
            self.assertIn("model-decimator.open_seams", rules,
                          "collapsing an unwelded split surface tears it, and "
                          "that must be an error rather than a clean pass")


if __name__ == "__main__":
    unittest.main()
