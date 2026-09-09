"""Tests for the prop scatterer — REQ-027, REQ-011, REQ-034.

Test names carry the requirement id they prove (REQ-026 AC-6).

This tool trades draw calls for legibility, and both sides of that trade are
tested here because both can be lost silently:

  * THE SAVING is only real if the props end up in ONE MultiMesh per type. A
    conversion that emitted a field per instance would report the same
    numbers and cost the same frame.
  * THE PLACES have to survive it exactly. Every instance keeps its transform
    to the float, or the level's composition has been edited by a rendering
    change nobody reviewed.

And the rule that came out of using it: a world that already carries fields
must not be run through again. The instances still under Dressing at that
point are the landmarks somebody kept, and collapsing them is how twenty-four
named clusters in Coral Cove became eight anonymous fields with an exit code
of zero.
"""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gameplay_snapshot  # noqa: E402
import scatter_props  # noqa: E402
import scene_fixtures  # noqa: E402


def run(argv: list) -> tuple:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = scatter_props.main(argv)
    return code, out.getvalue(), err.getvalue()


def scatter(target: str, extra: list | None = None) -> tuple:
    code, out, err = run(["--target", target, "--format", "json"]
                         + (extra or []))
    return code, json.loads(out) if out.strip() else {}, err


def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def snapshot_of(scene: str) -> dict:
    return {"scenes": {"world.tscn": gameplay_snapshot.snapshot(read(scene))}}


class ConversionTests(unittest.TestCase):

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.scene = scene_fixtures.write_world(self.tmp.name)

    def test_req_027_every_instance_becomes_one_field_per_prop_type(self):
        code, report, err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        # Three landmark instances, two kits: three draw calls become two.
        self.assertEqual(report["instancesScattered"],
                         len(scene_fixtures.DEFAULT_LANDMARKS))
        self.assertEqual(report["drawCallsAfter"], len(report["fields"]))
        self.assertLess(report["drawCallsAfter"], report["drawCallsBefore"])
        self.assertEqual(sorted(report["fields"]),
                         ["canopy_tree", "river_boulder"])

    def test_req_011_each_prop_keeps_its_transform_to_the_float(self):
        # The composition is the transforms. A rendering change that moves
        # them has edited the level.
        code, _report, err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        text = read(self.scene)
        for landmark in scene_fixtures.DEFAULT_LANDMARKS:
            origin = ", ".join(str(int(v)) for v in landmark["position"])
            self.assertIn(origin, text,
                          "%s moved: %s is not in any field"
                          % (landmark["name"], origin))

    def test_req_034_a_rigid_prop_is_not_given_the_wind_material(self):
        # A swaying boulder is worse than a still one.
        code, report, err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        self.assertTrue(report["fields"]["canopy_tree"]["sways"])
        self.assertFalse(report["fields"]["river_boulder"]["sways"])

        text = read(self.scene)
        boulder = text.split('[node name="RiverBoulderField"')[1].split(
            "\n\n")[0]
        self.assertNotIn(scatter_props.VEGETATION_MATERIAL_ID, boulder)

    def test_req_027_the_scene_declares_the_resources_it_now_loads(self):
        # A .tscn with too few load_steps loads with missing resources, and
        # the failure looks like a missing prop rather than a bad header.
        code, _report, err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        text = read(self.scene)
        declared = int(text.split("load_steps=")[1].split()[0])
        self.assertEqual(declared,
                         text.count("[ext_resource") + text.count("[sub_resource") + 1)
        self.assertIn(scatter_props.SCATTER_SCRIPT, text)
        self.assertIn(scatter_props.VEGETATION_MATERIAL, text)

    def test_req_027_a_dry_run_reports_the_saving_and_writes_nothing(self):
        before = read(self.scene)
        code, report, err = scatter(self.tmp.name, ["--dry-run"])
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        self.assertGreater(report["instancesScattered"], 0)
        self.assertEqual(read(self.scene), before)


class LandmarkTests(unittest.TestCase):
    """The rule that keeps a composed level composed."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def test_req_011_a_world_that_already_has_fields_refuses_to_collapse(self):
        """Run twice, and the second run ate the landmarks.

        Nothing distinguishes a kept landmark from an unconverted prop by
        looking at the node alone — both are a single instance under
        Dressing. What distinguishes them is the state of the world around
        them: once fields exist, a dressing pass has already happened and
        what is left standing was left standing on purpose.
        """
        scene = scene_fixtures.write_world(self.tmp.name, fields=True)
        before = read(scene)
        code, report, err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_VIOLATIONS, err)
        self.assertFalse(report["passed"])
        self.assertEqual([v["rule"] for v in report["violations"]],
                         ["scatter.landmarks_kept"])
        self.assertEqual(read(scene), before,
                         "a refused conversion must not have written")

    def test_req_011_collapsing_landmarks_is_possible_but_has_to_be_asked_for(self):
        # The escape hatch is real — the guard is against doing it by
        # accident, not against ever doing it.
        scene = scene_fixtures.write_world(self.tmp.name, fields=True)
        code, report, err = scatter(self.tmp.name, ["--collapse-landmarks"])
        self.assertEqual(code, scatter_props.EXIT_OK, err)
        self.assertTrue(report["passed"])
        self.assertEqual(report["instancesScattered"],
                         len(scene_fixtures.DEFAULT_LANDMARKS))
        self.assertNotIn('parent="Dressing" instance=', read(scene))

    def test_req_027_a_world_with_nothing_under_dressing_says_so(self):
        scene_fixtures.write_world(self.tmp.name, landmarks=())
        code, report, _err = scatter(self.tmp.name)
        self.assertEqual(code, scatter_props.EXIT_VIOLATIONS)
        self.assertEqual([v["rule"] for v in report["violations"]],
                         ["scatter.no_dressing"])

    def test_req_027_a_target_with_no_world_scene_is_an_invocation_error(self):
        with tempfile.TemporaryDirectory() as empty:
            code, _out, err = run(["--target", empty])
            self.assertEqual(code, scatter_props.EXIT_INVOCATION)
            self.assertIn("no world.tscn", err)


class GameplayTests(unittest.TestCase):

    def test_req_027_scattering_moves_nothing_gameplay_bearing(self):
        # A scatter field has no collision, so everything the player can
        # touch has to stay a real node — asserted, not assumed.
        with tempfile.TemporaryDirectory() as tmp:
            scene = scene_fixtures.write_world(tmp)
            before = snapshot_of(scene)
            code, _report, err = scatter(tmp)
            self.assertEqual(code, scatter_props.EXIT_OK, err)
            findings = gameplay_snapshot.compare(snapshot_of(scene), before)
            self.assertEqual(findings, [],
                             "the scatter changed the GAME:\n%s"
                             % "\n".join(findings))


if __name__ == "__main__":
    unittest.main()
