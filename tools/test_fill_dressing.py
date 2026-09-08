"""Tests for the filler dressing pass — REQ-034, REQ-011, REQ-027.

Test names carry the requirement id they prove (REQ-026 AC-6).

WHAT IS ACTUALLY AT RISK HERE, because it is not the argument parsing. This
tool writes hundreds of instances into a level that a route probe has already
been flown through, and every way it can go wrong is silent:

  * a fern on top of a seed the player then cannot see;
  * filler crowding out an authored landmark, which is REQ-011's composition
    beat quietly deleted;
  * a plant hanging over a ledge, telling the player the edge is somewhere it
    is not, in a game about reading edges;
  * more triangles than the frame can afford, which no test that only reads
    the scene would notice;
  * a second run doubling everything the first run wrote.

Every one of those is a property of the SCENE THAT SHIPS, so these read the
written .tscn back and measure it, rather than trusting the tool's own report
of what it did.
"""

from __future__ import annotations

import contextlib
import io
import json
import os
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import fill_dressing  # noqa: E402
import gameplay_snapshot  # noqa: E402
import scene_fixtures  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FIELD_RE = re.compile(
    r'^\[node name="(Filler[A-Za-z0-9]+Field)" type="Node3D" '
    r'parent="Dressing"\]$')
TRANSFORMS_RE = re.compile(r"^transforms = PackedFloat32Array\((.*)\)$")


@contextlib.contextmanager
def in_repo():
    """The tool reads each prop's triangle count off its glb by repository
    path, so the budget only means anything from the repository root."""
    previous = os.getcwd()
    os.chdir(REPO)
    try:
        yield
    finally:
        os.chdir(previous)


def run(argv: list) -> tuple:
    out, err = io.StringIO(), io.StringIO()
    with in_repo(), redirect_stdout(out), redirect_stderr(err):
        code = fill_dressing.main(argv)
    return code, out.getvalue(), err.getvalue()


def fill(target: str, extra: list | None = None) -> tuple:
    code, out, err = run(["--target", target, "--format", "json"]
                         + (extra or []))
    return code, json.loads(out) if out.strip() else {}, err


def placed(path: str) -> dict:
    """Every filler instance's world position, read back out of the scene.

    The tool's JSON says how many it wrote; this says WHERE, which is the
    half that can be wrong without anything looking wrong.
    """
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().split("\n")
    fields: dict = {}
    current = None
    for line in lines:
        header = FIELD_RE.match(line)
        if header is not None:
            current = header.group(1)
            fields[current] = []
            continue
        matched = TRANSFORMS_RE.match(line)
        if matched is None or current is None:
            continue
        values = [float(v) for v in matched.group(1).split(",")]
        # Twelve floats per instance: three basis rows, then the origin.
        for start in range(0, len(values), 12):
            row = values[start:start + 12]
            fields[current].append((row[9], row[10], row[11]))
    return fields


def every_spot(path: str) -> list:
    return [spot for spots in placed(path).values() for spot in spots]


def flat(scene: str) -> dict:
    """A one-scene snapshot in the shape gameplay_snapshot.compare wants."""
    with open(scene, encoding="utf-8") as handle:
        return {"scenes": {"world.tscn": gameplay_snapshot.snapshot(
            handle.read())}}


class ClearanceTests(unittest.TestCase):
    """Where filler is allowed to be, held to the written scene."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.scene = scene_fixtures.write_world(self.tmp.name)

    def test_req_011_no_filler_lands_within_clearance_of_gameplay(self):
        # Dressing that hides a collectible is worse than no dressing.
        code, report, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        self.assertGreater(report["instances"], 0,
                           "a fixture that places nothing proves nothing")

        gameplay = [marker["position"]
                    for marker in scene_fixtures.DEFAULT_GAMEPLAY]
        for spot in every_spot(self.scene):
            for point in gameplay:
                distance = ((spot[0] - point[0]) ** 2
                            + (spot[2] - point[2]) ** 2) ** 0.5
                self.assertGreaterEqual(
                    distance, fill_dressing.GAMEPLAY_CLEARANCE,
                    "filler at %s sits %.2f m from gameplay at %s"
                    % (spot, distance, point))

    def test_req_011_no_filler_crowds_an_authored_landmark(self):
        # The landmarks are the composition. Filler that closes in on them
        # takes away the silhouette they were placed for.
        code, _report, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        for spot in every_spot(self.scene):
            for landmark in scene_fixtures.DEFAULT_LANDMARKS:
                point = landmark["position"]
                distance = ((spot[0] - point[0]) ** 2
                            + (spot[2] - point[2]) ** 2) ** 0.5
                self.assertGreaterEqual(
                    distance, fill_dressing.LANDMARK_CLEARANCE,
                    "filler at %s sits %.2f m from landmark %s"
                    % (spot, distance, landmark["name"]))

    def test_req_034_filler_stands_on_platform_tops_inside_the_edge_inset(self):
        # A plant over a ledge misreports where the ledge is.
        code, _report, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        tops = {}
        for platform in scene_fixtures.DEFAULT_PLATFORMS:
            centre, size = platform["position"], platform["size"]
            tops[centre[1] + size[1] * 0.5] = (centre, size)

        for spot in every_spot(self.scene):
            self.assertIn(round(spot[1], 4), [round(t, 4) for t in tops],
                          "filler at %s is not standing on any platform top"
                          % (spot,))
            centre, size = tops[spot[1]]
            inset = fill_dressing.EDGE_INSET
            self.assertLessEqual(abs(spot[0] - centre[0]),
                                 size[0] * 0.5 - inset + 1e-6,
                                 "filler at %s overhangs in x" % (spot,))
            self.assertLessEqual(abs(spot[2] - centre[2]),
                                 size[2] * 0.5 - inset + 1e-6,
                                 "filler at %s overhangs in z" % (spot,))

    def test_req_034_a_platform_too_small_to_dress_gets_nothing(self):
        # PebbleStep is 2x2: inset it and there is no surface left. A prop
        # there would be bigger than the thing it stands on.
        code, report, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        self.assertEqual(report["platforms"], 2,
                         "the 2x2 step is below MIN_PLATFORM_AREA and must "
                         "not be offered as a platform at all")
        for spot in every_spot(self.scene):
            self.assertGreater(abs(spot[0] - (-30)), 1.0,
                               "filler at %s is on the pebble step" % (spot,))


class BudgetTests(unittest.TestCase):
    """REQ-027: the densities are a shape, the budget is the constraint."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.scene = scene_fixtures.write_world(self.tmp.name)

    def test_req_027_the_written_fill_never_exceeds_the_triangle_budget(self):
        """Both halves: under the ceiling it is left alone, over it is cut.

        This is the case that had teeth and used them. Thinning kept a floor
        of four instances per prop, which was applied AFTER the proportional
        cut and could put the result back over the ceiling on its own: asked
        for 3,000 triangles the tool returned 4,560 and reported success.
        A budget that is not met is not a budget, so every ceiling here is
        asserted against what was actually written.
        """
        for budget in (18000, 6000, 3000, 1200):
            with self.subTest(budget=budget):
                scene_fixtures.write_world(self.tmp.name)
                code, report, err = fill(
                    self.tmp.name, ["--triangle-budget", str(budget)])
                self.assertEqual(code, fill_dressing.EXIT_OK, err)
                self.assertLessEqual(
                    report["trianglesKept"], budget,
                    "asked for %d triangles, wrote %d"
                    % (budget, report["trianglesKept"]))
                if report["trianglesWanted"] > budget:
                    self.assertLess(report["trianglesKept"],
                                    report["trianglesWanted"],
                                    "an over-budget fill must actually thin")

    def test_req_027_thinning_keeps_the_mix_rather_than_dropping_a_prop(self):
        # Sparser, not patchier: a valley that loses every fern but keeps
        # every boulder stops reading as a valley.
        scene_fixtures.write_world(self.tmp.name)
        _code, full, _err = fill(self.tmp.name, ["--triangle-budget", "18000"])
        scene_fixtures.write_world(self.tmp.name)
        _code, thin, _err = fill(self.tmp.name, ["--triangle-budget", "6000"])
        self.assertLess(thin["instances"], full["instances"])
        self.assertEqual(sorted(thin["fields"]), sorted(full["fields"]),
                         "a proportional thin keeps every prop in the mix")


class RerunTests(unittest.TestCase):
    """Running the pass again is a no-op, not a second pass."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def test_req_034_running_the_pass_twice_produces_the_same_scene(self):
        """The regression this suite was written for.

        Filling is not additive, but it was: the second run appended a second
        set of fields under the same names, so Coral Cove went from six
        filler fields to twelve to eighteen, doubling and tripling the filler
        while every report said it had written 112 instances. Bytes are the
        only assertion that catches it.
        """
        scene = scene_fixtures.write_world(self.tmp.name)
        code, first, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        with open(scene, encoding="utf-8") as handle:
            once = handle.read()

        code, again, err = fill(self.tmp.name)
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        with open(scene, encoding="utf-8") as handle:
            twice = handle.read()

        self.assertEqual(once, twice, "a second run must change nothing")
        self.assertEqual(first["instances"], again["instances"])
        self.assertEqual(once.count('type="Node3D" parent="Dressing"'),
                         len(first["fields"]),
                         "one field per prop, however many times it is run")

    def test_req_011_the_tools_own_fields_are_not_read_back_as_landmarks(self):
        """A scatter field is not a landmark, and reading it as one hurt.

        Every child of Dressing used to count as an authored landmark, which
        swept up the MultiMesh fields — nodes with no transform of their own,
        so they read as a landmark AT THE ORIGIN and punched a clearance hole
        in the filler there. The count grew every run, so the level a second
        run produced depended on how many times the tool had been run.
        """
        with_fields = scene_fixtures.write_world(self.tmp.name, fields=True)
        _code, report, err = fill(self.tmp.name)
        self.assertEqual(_code, fill_dressing.EXIT_OK, err)
        self.assertEqual(report["landmarksAvoided"],
                         len(scene_fixtures.DEFAULT_LANDMARKS),
                         "only the instanced props are landmarks")
        with open(with_fields, encoding="utf-8") as handle:
            self.assertIn(
                "CanopyTreeField", handle.read(),
                "and the field a previous pass wrote is left standing")

    def test_req_034_a_dry_run_writes_nothing(self):
        scene = scene_fixtures.write_world(self.tmp.name)
        with open(scene, encoding="utf-8") as handle:
            before = handle.read()
        code, report, err = fill(self.tmp.name, ["--dry-run"])
        self.assertEqual(code, fill_dressing.EXIT_OK, err)
        self.assertTrue(report["dryRun"])
        self.assertGreater(report["instances"], 0)
        with open(scene, encoding="utf-8") as handle:
            self.assertEqual(handle.read(), before)


class GameplayTests(unittest.TestCase):
    """A visual pass that changes the game is not a visual pass."""

    def test_req_034_the_fill_moves_nothing_gameplay_bearing(self):
        with tempfile.TemporaryDirectory() as tmp:
            scene = scene_fixtures.write_world(tmp)
            before = flat(scene)
            code, _report, err = fill(tmp)
            self.assertEqual(code, fill_dressing.EXIT_OK, err)
            findings = gameplay_snapshot.compare(flat(scene), before)
            self.assertEqual(findings, [],
                             "the filler pass changed the GAME:\n%s"
                             % "\n".join(findings))


class EmptyTests(unittest.TestCase):
    """Nothing to dress is reported, never silently succeeded."""

    def test_req_034_a_world_with_no_dressable_platform_exits_empty(self):
        with tempfile.TemporaryDirectory() as tmp:
            scene_fixtures.write_world(
                tmp, platforms=(scene_fixtures.DEFAULT_PLATFORMS[2],),
                landmarks=(), geometric=None)
            code, out, err = run(["--target", tmp])
            self.assertEqual(code, fill_dressing.EXIT_EMPTY, out)
            self.assertIn("nothing to scatter", err)

    def test_req_034_a_target_with_no_scene_is_an_invocation_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, _out, err = run(["--target", tmp])
            self.assertEqual(code, fill_dressing.EXIT_INVOCATION)
            self.assertIn("no scene", err)


if __name__ == "__main__":
    unittest.main()
