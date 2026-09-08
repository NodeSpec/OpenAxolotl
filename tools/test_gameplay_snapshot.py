"""Tests for the gameplay snapshot — REQ-038, REQ-011, REQ-034.

Test names carry the requirement id they prove (REQ-026 AC-6).

THIS TOOL IS THE INSTRUMENT THE OTHER THREE ARE MEASURED WITH. Every visual
pass in tools/ ends with "and it changed no gameplay", and this is what that
sentence is worth. So the tests it needs are not the ones that show it
producing output; they are the ones that show it CATCHING things — a snapshot
comparison that cannot fail is a green light with no bulb, and it would make
three other tools' proofs worthless at the same time.

Each case below therefore breaks the scene in one specific way a careless
visual pass really does break it, and requires the tool to name it. The one
case that runs the other way is just as load-bearing: dressing must be
INVISIBLE to it, because a tool that reports every changed prop is one that
gets ignored.
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
import scene_fixtures  # noqa: E402


def run(argv: list) -> tuple:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = gameplay_snapshot.main(argv)
    return code, out.getvalue(), err.getvalue()


def findings_after(edit) -> list:
    """Snapshot the fixture, apply `edit` to its text, and diff.

    The edit is required to have changed the scene. A case whose edit
    silently matched nothing would assert that the tool stayed quiet about a
    change that was never made, which is the failure mode this whole file
    exists to rule out.
    """
    original = scene_fixtures.world_text()
    edited = edit(original)
    if edited == original:
        raise AssertionError(
            "the edit changed no scene text, so this case proves nothing")
    before = {"scenes": {"world.tscn": gameplay_snapshot.snapshot(original)}}
    after = {"scenes": {"world.tscn": gameplay_snapshot.snapshot(edited)}}
    return gameplay_snapshot.compare(after, before)


class DetectionTests(unittest.TestCase):
    """What the tool has to see, or the other three prove nothing."""

    def test_req_038_a_platform_that_moves_ten_centimetres_is_reported(self):
        """The size of error a visual pass actually makes.

        A walk probe catches a platform that vanishes. It does not catch one
        that slid a tenth of a metre — and a tenth of a metre is the whole
        margin on a jump measured at 2.7 m against a 3.15 m envelope.
        """
        def nudge(text: str) -> str:
            return text.replace(
                "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 6, 0)",
                "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 6.1, 0)")

        findings = findings_after(nudge)
        self.assertTrue(any("Ledge" in finding for finding in findings),
                        "a moved platform went unreported: %s" % findings)

    def test_req_038_a_resized_collider_is_reported_though_its_id_is_not(self):
        """The one a diff of node lines cannot see.

        The shape is a sub-resource reference, so resizing the box changes
        nothing about the node that points at it. Snapshotting the reference
        instead of the resolved size would compare two identical strings and
        report a level whose collision had changed as unchanged.
        """
        def resize(text: str) -> str:
            return text.replace("size = Vector3(8, 1, 8)",
                                "size = Vector3(8, 1, 6)")

        findings = findings_after(resize)
        self.assertTrue(any("shape" in finding for finding in findings),
                        "a resized collider went unreported: %s" % findings)

    def test_req_003_a_removed_checkpoint_is_reported(self):
        def remove(text: str) -> str:
            block = ('[node name="Checkpoint1" type="Marker3D" parent="." '
                     'groups=["checkpoint"]]\n'
                     "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, "
                     "30, 7, 0)\n\n")
            self.assertIn(block, text)
            return text.replace(block, "")

        findings = findings_after(remove)
        self.assertTrue(any("REMOVED" in f and "Checkpoint1" in f
                            for f in findings),
                        "a deleted checkpoint went unreported: %s" % findings)

    def test_req_010_a_marker_that_loses_its_group_is_reported(self):
        # A collectible that is still in the scene but no longer in the
        # collectible group is gone as far as the game is concerned, and
        # nothing about the scene looks different.
        def ungroup(text: str) -> str:
            return text.replace(' groups=["collectible"]', "")

        findings = findings_after(ungroup)
        self.assertTrue(any("Seed1" in finding for finding in findings),
                        "a lost group went unreported: %s" % findings)

    def test_req_038_an_added_platform_is_reported(self):
        def add(text: str) -> str:
            return text + ('\n[node name="SecretLedge" type="StaticBody3D" '
                           'parent="."]\ntransform = Transform3D(1, 0, 0, 0, '
                           "1, 0, 0, 0, 1, 60, 9, 0)\n")

        findings = findings_after(add)
        self.assertTrue(any("ADDED" in f and "SecretLedge" in f
                            for f in findings),
                        "a new platform went unreported: %s" % findings)


class QuietTests(unittest.TestCase):
    """What the tool must stay silent about, or nobody will read it."""

    def test_req_034_dressing_is_not_gameplay(self):
        # Dressing is exactly what the visual passes are allowed to change.
        # Reporting it would make every snapshot differ and the tool useless.
        def redress(text: str) -> str:
            head, _dressing = text.split('[node name="Dressing"', 1)
            return head + ('[node name="Dressing" type="Node3D" parent="."]\n'
                           '\n[node name="NewTree" parent="Dressing" '
                           'instance=ExtResource("1_kit_canopy_tree")]\n'
                           "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, "
                           "1, 3, 1, 3)\n")

        self.assertEqual(findings_after(redress), [],
                         "every landmark was replaced and the snapshot must "
                         "not care: dressing is what a visual pass changes")

    def test_req_038_an_unchanged_scene_compares_clean(self):
        text = scene_fixtures.world_text()
        snapshot = {"scenes": {"world.tscn": gameplay_snapshot.snapshot(text)}}
        self.assertEqual(gameplay_snapshot.compare(snapshot, snapshot), [])


class CommandTests(unittest.TestCase):
    """The exit codes CI and the other tools' tests read."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.scene = scene_fixtures.write_world(self.tmp.name)
        self.before = os.path.join(self.tmp.name, "before.json")

    def _capture(self) -> None:
        code, out, err = run(["--target", self.tmp.name])
        self.assertEqual(code, gameplay_snapshot.EXIT_OK, err)
        with open(self.before, "w", encoding="utf-8") as handle:
            handle.write(out)

    def test_req_038_capture_then_compare_with_no_change_exits_zero(self):
        self._capture()
        code, out, err = run(["--target", self.tmp.name,
                              "--compare", self.before])
        self.assertEqual(code, gameplay_snapshot.EXIT_OK, err)
        self.assertIn("UNCHANGED", out)

    def test_req_038_compare_after_a_gameplay_change_exits_one(self):
        # The exit code is what makes this usable in a script, so it is
        # asserted in both directions rather than only on the happy path.
        self._capture()
        with open(self.scene, encoding="utf-8") as handle:
            text = handle.read()
        with open(self.scene, "w", encoding="utf-8") as handle:
            handle.write(text.replace(
                "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 6, 0)",
                "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 34, 6, 0)"))

        code, out, err = run(["--target", self.tmp.name,
                              "--compare", self.before])
        self.assertEqual(code, gameplay_snapshot.EXIT_DIFFERENT, err)
        self.assertIn("changed the GAME", out)
        self.assertIn("Ledge", out)

    def test_req_038_the_capture_is_canonical_and_repeatable(self):
        # Two captures of the same tree must be the same bytes, or a diff
        # means nothing.
        _code, first, _err = run(["--target", self.tmp.name])
        _code, second, _err = run(["--target", self.tmp.name])
        self.assertEqual(first, second)
        payload = json.loads(first)
        self.assertEqual(payload["tool"], gameplay_snapshot.TOOL_NAME)
        self.assertIn("world.tscn", "".join(payload["scenes"]))

    def test_req_038_a_missing_target_is_an_invocation_error(self):
        code, _out, err = run(["--target", "/nowhere/at/all"])
        self.assertEqual(code, gameplay_snapshot.EXIT_INVOCATION)
        self.assertIn("no such directory", err)


if __name__ == "__main__":
    unittest.main()
