"""Tests for the terrain sheller — REQ-039, REQ-034, REQ-027.

Test names carry the requirement id they prove (REQ-026 AC-6).

The sheller wraps a greybox collision proxy in organic geometry. What it must
never do is decide anything about the game, and what it must never lose is the
ability to run it again:

  * THE COLLIDER IS UNTOUCHED. The box the player stands on stays exactly the
    box it was; only the BoxMesh showing it is hidden.
  * MANUFACTURED THINGS STAY GEOMETRIC. A mod gate reads as a rule precisely
    because it is a clean slab among organic rock.
  * THE MATERIAL COMES FROM THE BODY'S OWN NAME, including the hub's Ground,
    which is shore rather than woodland — reading it as woodland once painted
    the whole hub near-black.
  * SEEDS ARE STABLE ACROSS PROCESSES. Python salts hash() per process, so a
    seed derived from it would reshuffle every silhouette on every run and
    produce a diff for no reason. That one is checked in a SUBPROCESS,
    because checking it in this one cannot fail.
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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gameplay_snapshot  # noqa: E402
import scene_fixtures  # noqa: E402
import shell_terrain  # noqa: E402

TOOLS = os.path.dirname(os.path.abspath(__file__))


def run(argv: list) -> tuple:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = shell_terrain.main(argv)
    return code, out.getvalue(), err.getvalue()


def shell(scene: str, extra: list | None = None) -> tuple:
    code, out, err = run(["--target", scene, "--format", "json"]
                         + (extra or []))
    report = json.loads(out) if out.strip() else {}
    return code, report.get("scenes", {}).get(scene, {}), err


def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def snapshot_of(scene: str) -> dict:
    return {"scenes": {"world.tscn": gameplay_snapshot.snapshot(read(scene))}}


class ShellingTests(unittest.TestCase):

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.scene = scene_fixtures.write_world(self.tmp.name)

    def test_req_039_a_boxy_proxy_gets_a_shell_and_keeps_its_collider(self):
        code, row, err = shell(self.scene)
        self.assertEqual(code, shell_terrain.EXIT_OK, err)
        self.assertEqual(row["shelled"],
                         ["./GroundSlab", "./Ledge", "./PebbleStep"])

        text = read(self.scene)
        for platform in scene_fixtures.DEFAULT_PLATFORMS:
            self.assertIn('[node name="Shell" type="Node3D" parent="%s"]'
                          % platform["name"], text)
        self.assertEqual(text.count('type="CollisionShape3D"'),
                         len(scene_fixtures.DEFAULT_PLATFORMS) + 1,
                         "the colliders are the game and must be untouched")

    def test_req_039_the_proxy_mesh_is_hidden_rather_than_deleted(self):
        # A hidden proxy is one line to flip back on while art is in flight,
        # and keeps the .tscn honest about what the shape actually is.
        code, _row, err = shell(self.scene)
        self.assertEqual(code, shell_terrain.EXIT_OK, err)
        text = read(self.scene)
        self.assertEqual(text.count("visible = false"),
                         len(scene_fixtures.DEFAULT_PLATFORMS))
        self.assertEqual(text.count('type="MeshInstance3D"'),
                         len(scene_fixtures.DEFAULT_PLATFORMS) + 1)

    def test_req_039_a_manufactured_body_stays_geometric(self):
        # A bevelled organic rock where a gate should be would lie about
        # what the object is.
        code, row, err = shell(self.scene)
        self.assertEqual(code, shell_terrain.EXIT_OK, err)
        self.assertIn({"body": "./ModGate",
                       "why": "manufactured: deliberately geometric"},
                      row["skipped"])
        self.assertNotIn('parent="ModGate"]\nscript', read(self.scene))
        self.assertNotIn("./ModGate", row["shelled"])

    def test_req_039_the_material_comes_from_the_body_s_own_name(self):
        # The level already names its bodies for what they are, so the name
        # is the honest signal rather than a table maintained in parallel.
        self.assertEqual(shell_terrain.material_for("StartLedge"),
                         "mossy_stone")
        self.assertEqual(shell_terrain.material_for("CliffWall"),
                         "river_stone")
        self.assertEqual(shell_terrain.material_for("Unnamed42"),
                         shell_terrain.DEFAULT_MATERIAL)
        # The one that was got wrong: the hub's Ground is the Open Lagoon
        # SHORE. Read as woodland it wore forest_earth, whose low tint is
        # nearly black, and rendered the whole hub as a dark slab.
        self.assertEqual(shell_terrain.material_for("Ground"), "river_sand")
        self.assertEqual(shell_terrain.material_for("ValleyFloor"),
                         "forest_earth")


class RerunTests(unittest.TestCase):

    def test_req_027_a_body_that_already_has_a_shell_is_skipped(self):
        """The regression: shelling was additive.

        Nothing in the scan looked for a Shell that was already there, so a
        second run added a second one to every body and a second
        `visible = false` to every proxy — thirty-two shells became
        sixty-four, doubling the shell geometry in the scene while the report
        said it had shelled thirty-two.
        """
        with tempfile.TemporaryDirectory() as tmp:
            scene = scene_fixtures.write_world(tmp)
            code, first, err = shell(scene)
            self.assertEqual(code, shell_terrain.EXIT_OK, err)
            self.assertEqual(len(first["shelled"]),
                             len(scene_fixtures.DEFAULT_PLATFORMS))
            once = read(scene)

            code, again, err = shell(scene)
            self.assertEqual(code, shell_terrain.EXIT_OK, err)
            self.assertEqual(again["shelled"], [],
                             "a second run has nothing left to shell")
            self.assertIn({"body": "./GroundSlab", "why": "already shelled"},
                          again["skipped"])
            self.assertEqual(read(scene), once,
                             "and must not have written anything")

    def test_req_039_the_shell_seed_is_stable_across_processes(self):
        """Python salts hash() per process; this seed must not.

        Run in a SUBPROCESS with a different PYTHONHASHSEED, because a check
        inside this process would agree with itself no matter how the seed
        was derived and prove nothing at all.
        """
        mine = shell_terrain._stable_seed("./GroundSlab")
        script = ("import sys; sys.path.insert(0, %r); import shell_terrain; "
                  "print(shell_terrain._stable_seed('./GroundSlab'))" % TOOLS)
        for salt in ("0", "1", "12345"):
            environment = dict(os.environ, PYTHONHASHSEED=salt)
            result = subprocess.run([sys.executable, "-c", script],
                                    capture_output=True, text=True,
                                    env=environment, check=True)
            self.assertEqual(int(result.stdout.strip()), mine,
                             "PYTHONHASHSEED=%s changed the seed" % salt)


class GameplayTests(unittest.TestCase):

    def test_req_034_shelling_moves_nothing_gameplay_bearing(self):
        with tempfile.TemporaryDirectory() as tmp:
            scene = scene_fixtures.write_world(tmp)
            before = snapshot_of(scene)
            code, _row, err = shell(scene)
            self.assertEqual(code, shell_terrain.EXIT_OK, err)
            findings = gameplay_snapshot.compare(snapshot_of(scene), before)
            self.assertEqual(findings, [],
                             "the shell pass changed the GAME:\n%s"
                             % "\n".join(findings))

    def test_req_039_a_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            scene = scene_fixtures.write_world(tmp)
            before = read(scene)
            code, row, err = shell(scene, ["--dry-run"])
            self.assertEqual(code, shell_terrain.EXIT_OK, err)
            self.assertTrue(row["shelled"])
            self.assertEqual(read(scene), before)

    def test_req_039_a_missing_target_is_an_invocation_error(self):
        code, _out, err = run(["--target", "/nowhere/at/all"])
        self.assertEqual(code, shell_terrain.EXIT_INVOCATION)
        self.assertIn("no scenes", err)


if __name__ == "__main__":
    unittest.main()
