"""Tests for the hero rig extender — REQ-002 (AC-9), REQ-015.

Test names carry the requirement id they prove (REQ-026 AC-6).

The extender rewrites the one thing in a character file that nothing else in
the pipeline can see afterwards: which bone each vertex follows. A wrong
weight does not fail an import, change a triangle count or move a bounding
box; it shows up weeks later as a foot that swings when the head turns. So
these tests hold the tool to what it PROMISES rather than to how it runs:

  * every sole ends up on its own foot bone, including one that started on a
    bone that was never a leg;
  * the body is left with no leg weight at all;
  * the original bones, the geometry and the animation survive untouched;
  * a second run changes nothing, and the shipped hero IS a first run's
    output.

Most of it runs on a small synthetic animal built here, so the gates are
proven on both sides — a creature with feet passes, one without is refused —
without depending on the shipped asset. One test then pins the shipped asset
itself to the tool.
"""

from __future__ import annotations

import io
import json
import math
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import extend_hero_rig as rig_tool  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HERO = os.path.join(REPO, "assets", "character", "axolotl", "axolotl.glb")

ORIGINAL_BONES = ("root", "body", "leg_fl", "leg_fr", "leg_bl", "leg_br")

## Where each synthetic leg stands: left is +X and the head is toward -Z, as
## on the hero.
STANCE = {"leg_fl": (0.5, -0.7), "leg_fr": (-0.5, -0.7),
          "leg_bl": (0.5, 0.7), "leg_br": (-0.5, 0.7)}

SEGMENTS = 12

## One leg as a surface of revolution, bottom to top: a foot pad, a thin shaft,
## a flare, and a wide cap standing in for the body it grows out of. Rings sit
## close enough together that every joint lands on real surface.
RING_STEP = 0.015
SHAFT_RADIUS = 0.07
BODY_RADIUS = 0.46


def leg_profile() -> list[tuple[float, float]]:
    """(height, radius) for each ring of one leg."""
    rings = [(step * RING_STEP, 0.10) for step in range(3)]
    while rings[-1][0] < 0.30:
        rings.append((rings[-1][0] + RING_STEP, SHAFT_RADIUS))
    radius = SHAFT_RADIUS
    while radius < BODY_RADIUS:
        radius = min(BODY_RADIUS, radius + 0.03)
        rings.append((rings[-1][0] + RING_STEP, radius))
    for _ in range(10):
        rings.append((rings[-1][0] + RING_STEP, BODY_RADIUS))
    return rings


LEG_PROFILE = leg_profile()
BODY_FROM = LEG_PROFILE[-1][0] - 0.06

## The same thing with no limb under it: a body and no feet.
STUMP_PROFILE = [(0.30 + step * RING_STEP, BODY_RADIUS) for step in range(12)]


def run(argv: list[str]) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = rig_tool.main(argv)
    return code, out.getvalue(), err.getvalue()


def build_animal(path: str, profile=None, stray_sole: bool = True) -> None:
    """Write a four-legged skinned glb with one bone per leg.

    Every leg is weighted the way the shipped hero was: mostly to its own leg
    bone, with the front-left SOLE handed to `body` instead (the hero's was on
    its head) and a little leg weight smeared over the body cap.
    """
    profile = profile or LEG_PROFILE
    positions, joints, weights, indices = [], [], [], []
    names = list(ORIGINAL_BONES)
    for leg, (centre_x, centre_z) in STANCE.items():
        base = len(positions)
        leg_index = names.index(leg)
        body_index = names.index("body")
        positions.append((centre_x, profile[0][0], centre_z))
        rows = [0]
        for height, radius in profile:
            rows.append(len(positions) - base)
            for step in range(SEGMENTS):
                angle = math.tau * step / SEGMENTS
                positions.append((centre_x + radius * math.cos(angle), height,
                                  centre_z + radius * math.sin(angle)))
        for vertex in positions[base:]:
            on_sole = vertex[1] < 0.05
            on_body = vertex[1] > profile[-1][0] - 0.12
            if on_sole and stray_sole and leg == "leg_fl":
                joints.append((body_index, leg_index, 0, 0))
                weights.append((0.72, 0.28, 0.0, 0.0))
            elif on_body:
                joints.append((body_index, leg_index, 0, 0))
                weights.append((0.8, 0.2, 0.0, 0.0))
            else:
                joints.append((leg_index, 0, 0, 0))
                weights.append((1.0, 0.0, 0.0, 0.0))
        first = base + rows[1]
        for step in range(SEGMENTS):
            indices += [base, first + (step + 1) % SEGMENTS, first + step]
        for ring in range(1, len(profile)):
            lower, upper = base + rows[ring], base + rows[ring + 1]
            for step in range(SEGMENTS):
                following = (step + 1) % SEGMENTS
                indices += [lower + step, lower + following, upper + step,
                            lower + following, upper + following,
                            upper + step]

    bones = {"root": (0.0, 0.5, 0.0), "body": (0.0, 0.0, 0.0)}
    for leg, (centre_x, centre_z) in STANCE.items():
        # The pivot sits inside the body and well inboard of the limb, the way
        # a mirrored fit leaves it.
        bones[leg] = (centre_x * 0.4, -0.1, centre_z * 0.9)
    document = {
        "asset": {"version": "2.0"}, "scene": 0,
        "scenes": [{"nodes": [0, len(names)]}],
        "nodes": [], "meshes": [], "skins": [], "accessors": [],
        "bufferViews": [], "buffers": [{"byteLength": 0}],
    }
    for name in names:
        node = {"name": name, "translation": list(bones[name])}
        if name == "root":
            node["children"] = list(range(1, len(names)))
        document["nodes"].append(node)
    binary = bytearray()
    world = {"root": bones["root"]}
    for name in names[1:]:
        world[name] = tuple(a + b for a, b in zip(bones["root"], bones[name]))
    inverse_binds = []
    for name in names:
        matrix = rig_tool.identity()
        for axis in range(3):
            matrix[axis][3] = -world[name][axis]
        inverse_binds.append(tuple(rig_tool.to_gltf(matrix)))

    position = rig_tool.append_accessor(document, binary, positions, 5126,
                                        "VEC3")
    joint = rig_tool.append_accessor(document, binary, joints, 5121, "VEC4")
    weight = rig_tool.append_accessor(document, binary, weights, 5126, "VEC4")
    index = rig_tool.append_accessor(document, binary,
                                     [(value,) for value in indices], 5125,
                                     "SCALAR")
    binds = rig_tool.append_accessor(document, binary, inverse_binds, 5126,
                                     "MAT4")
    times = rig_tool.append_accessor(document, binary, [(0.0,), (1.0,)], 5126,
                                     "SCALAR")
    turns = rig_tool.append_accessor(
        document, binary, [(0.0, 0.0, 0.0, 1.0), (0.0, 0.3, 0.0, 0.954)],
        5126, "VEC4")
    document["meshes"].append({"primitives": [{
        "attributes": {"POSITION": position, "JOINTS_0": joint,
                       "WEIGHTS_0": weight},
        "indices": index}]})
    document["skins"].append({"joints": list(range(len(names))),
                              "inverseBindMatrices": binds})
    document["nodes"].append({"name": "Mesh", "mesh": 0, "skin": 0})
    document["animations"] = [{
        "name": "waddle",
        "samplers": [{"input": times, "output": turns}],
        "channels": [{"sampler": 0,
                      "target": {"node": names.index("leg_fl"),
                                 "path": "rotation"}}]}]
    rig_tool.write_glb(path, document, binary)


def bytes_of(document: dict, binary: bytearray, accessor: int) -> bytes:
    _pattern, base, stride, count, _width = rig_tool._layout(document,
                                                             accessor)
    return bytes(binary[base: base + stride * count])


class SurfaceTests(unittest.TestCase):
    """The measurements the fit is built on."""

    def test_req_002_chain_weights_always_share_out_exactly_one(self):
        # A limb weighted with anything else tears or doubles at a joint.
        for step in range(0, 80):
            travelled = step * 0.005
            upper, shin, foot = rig_tool.chain_weights(travelled, 0.07, 0.20)
            self.assertAlmostEqual(upper + shin + foot, 1.0, places=9)
            self.assertGreaterEqual(min(upper, shin, foot), 0.0)
        self.assertEqual(rig_tool.chain_weights(0.0, 0.07, 0.20),
                         (0.0, 0.0, 1.0))
        self.assertEqual(rig_tool.chain_weights(0.4, 0.07, 0.20),
                         (1.0, 0.0, 0.0))

    def test_req_002_distance_is_measured_along_the_skin_not_through_air(self):
        # Two strips a hair apart in space, joined only at their far end: the
        # head beside a front foot. Straight-line they are neighbours; along
        # the surface they are the whole length of both strips apart, and that
        # difference is what keeps a foot off the head bone.
        points = [(step * 0.1, 0.0, 0.0) for step in range(11)] \
            + [(step * 0.1, 0.0, 0.01) for step in range(11)]
        graph = [dict() for _ in points]

        def join(a: int, b: int) -> None:
            length = math.dist(points[a], points[b])
            graph[a][b] = length
            graph[b][a] = length

        for step in range(10):
            join(step, step + 1)
            join(11 + step, 12 + step)
        join(10, 21)
        distance = rig_tool.surface_distance(graph, [0], 5.0)
        self.assertAlmostEqual(math.dist(points[0], points[11]), 0.01)
        self.assertAlmostEqual(distance[11], 2.01, places=6)

    def test_req_002_a_limb_ends_where_it_widens_and_only_there(self):
        shaft = [(step * 0.02, 12, (0.0, 0.0, 0.0), 0.07)
                 for step in range(15)]
        flare = [(0.30, 12, (0.0, 0.0, 0.0), 0.20)]
        self.assertAlmostEqual(rig_tool.limb_end(shaft + flare), 0.30)
        # A tube that never meets a body has no end to find, and saying so is
        # the correct answer: a guessed shoulder is how a rig gets mirrored
        # onto anatomy it does not fit.
        self.assertIsNone(rig_tool.limb_end(shaft))

    def test_req_002_welding_closes_the_seams_a_uv_split_opens(self):
        mapping, welded = rig_tool.weld([(0.0, 0.0, 0.0), (1.0, 0.0, 0.0),
                                         (0.0, 0.0, 0.00001)])
        self.assertEqual(mapping, [0, 1, 0])
        self.assertEqual(len(welded), 2)


class ExtendTests(unittest.TestCase):
    """The whole tool, on an animal built for the purpose."""

    def setUp(self) -> None:
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.source = os.path.join(self.folder.name, "animal.glb")
        self.output = os.path.join(self.folder.name, "extended.glb")
        build_animal(self.source)

    def extend(self) -> dict:
        code, out, err = run(["--input", self.source, "--output",
                              self.output, "--format", "json"])
        self.assertEqual(code, rig_tool.EXIT_OK, out + err)
        return json.loads(out)

    def test_req_002_every_leg_gains_a_chain_from_shoulder_to_toe(self):
        self.extend()
        document, _binary = rig_tool.read_glb(self.output)
        names = [node.get("name") for node in document["nodes"]]
        parents = {child: index for index, node in enumerate(
            document["nodes"]) for child in node.get("children", [])}
        for leg in rig_tool.LEGS:
            chain = (leg,) + rig_tool.chain_names(leg)
            for parent, child in zip(chain, chain[1:]):
                self.assertIn(child, names)
                self.assertEqual(names[parents[names.index(child)]], parent,
                                 "%s must hang from %s" % (child, parent))
        self.assertEqual(len(document["skins"][0]["joints"]),
                         len(ORIGINAL_BONES) + 16)

    def test_req_002_every_sole_ends_up_on_its_own_foot(self):
        report = self.extend()
        legs = report["summary"]["legs"]
        # The front-left sole began on the body bone. That is the defect.
        self.assertLess(legs["leg_fl"]["soleOwnedByOwnLegBefore"], 0.35)
        for leg in rig_tool.LEGS:
            self.assertGreaterEqual(legs[leg]["soleOwnedByFootAfter"], 0.99,
                                    leg)

    def test_req_002_the_body_keeps_no_leg_weight(self):
        report = self.extend()
        document, binary = rig_tool.read_glb(self.output)
        rig = rig_tool.Rig(document, binary)
        names = rig.names()
        limb = {name for leg in rig_tool.LEGS
                for name in (leg,) + rig_tool.chain_names(leg)}
        for position, joints, weights in zip(rig.positions, rig.joints,
                                             rig.weights):
            self.assertAlmostEqual(sum(weights), 1.0, places=5)
            if position[1] > BODY_FROM:
                for joint, weight in zip(joints, weights):
                    if weight > 0.0:
                        self.assertNotIn(names[joint], limb)
        self.assertGreater(report["summary"]["bodyVerticesFreedOfLegWeight"],
                           0)

    def test_req_002_original_bones_geometry_and_clips_are_untouched(self):
        before, before_binary = rig_tool.read_glb(self.source)
        self.extend()
        after, after_binary = rig_tool.read_glb(self.output)

        for index in range(len(ORIGINAL_BONES)):
            was, now = before["nodes"][index], after["nodes"][index]
            self.assertEqual(was["name"], now["name"])
            self.assertEqual(was["translation"], now["translation"])
        was_binds = rig_tool.read_accessor(
            before, before_binary, before["skins"][0]["inverseBindMatrices"])
        now_binds = rig_tool.read_accessor(
            after, after_binary, after["skins"][0]["inverseBindMatrices"])
        self.assertEqual(was_binds, now_binds[:len(was_binds)])

        was_mesh = before["meshes"][0]["primitives"][0]
        now_mesh = after["meshes"][0]["primitives"][0]
        for what in ("POSITION",):
            self.assertEqual(
                bytes_of(before, before_binary, was_mesh["attributes"][what]),
                bytes_of(after, after_binary, now_mesh["attributes"][what]))
        self.assertEqual(bytes_of(before, before_binary, was_mesh["indices"]),
                         bytes_of(after, after_binary, now_mesh["indices"]))

        # No clip gained a channel: the new bones are the engine's to bend.
        self.assertEqual(before["animations"], after["animations"])
        for sampler in before["animations"][0]["samplers"]:
            for end in ("input", "output"):
                self.assertEqual(
                    bytes_of(before, before_binary, sampler[end]),
                    bytes_of(after, after_binary, sampler[end]))

    def test_req_002_a_second_run_changes_nothing(self):
        self.extend()
        again = os.path.join(self.folder.name, "again.glb")
        code, out, err = run(["--input", self.output, "--output", again,
                              "--format", "json"])
        self.assertEqual(code, rig_tool.EXIT_OK, out + err)
        report = json.loads(out)
        self.assertTrue(report["summary"]["alreadyExtended"])
        self.assertEqual(report["summary"]["verticesReweighted"], 0)
        first, first_binary = rig_tool.read_glb(self.output)
        second, second_binary = rig_tool.read_glb(again)
        self.assertEqual(len(first["nodes"]), len(second["nodes"]))
        self.assertEqual(rig_tool.Rig(first, first_binary).weights,
                         rig_tool.Rig(second, second_binary).weights)

    def test_req_002_check_tells_an_extended_rig_from_one_that_is_not(self):
        code, out, _err = run(["--input", self.source, "--check"])
        self.assertEqual(code, rig_tool.EXIT_VIOLATIONS)
        self.assertIn("not_conforming", out)
        self.assertFalse(os.path.exists(self.output))
        self.extend()
        code, _out, _err = run(["--input", self.output, "--check"])
        self.assertEqual(code, rig_tool.EXIT_OK)


class GateTests(unittest.TestCase):
    """What the tool refuses, and that refusing writes nothing."""

    def test_req_002_an_animal_with_no_feet_is_refused_not_guessed_at(self):
        with tempfile.TemporaryDirectory() as folder:
            source = os.path.join(folder, "stumps.glb")
            output = os.path.join(folder, "out.glb")
            build_animal(source, profile=STUMP_PROFILE)
            code, out, _err = run(["--input", source, "--output", output,
                                   "--format", "json"])
            self.assertEqual(code, rig_tool.EXIT_VIOLATIONS)
            report = json.loads(out)
            self.assertFalse(report["passed"])
            self.assertTrue(report["violations"])
            self.assertFalse(os.path.exists(output))

    def test_req_015_invocation_errors_are_exit_code_two(self):
        code, _out, err = run(["--input", "/nowhere/missing.glb", "--output",
                               "/nowhere/out.glb"])
        self.assertEqual(code, rig_tool.EXIT_INVOCATION)
        self.assertIn("not a file", err)
        with tempfile.TemporaryDirectory() as folder:
            source = os.path.join(folder, "animal.glb")
            build_animal(source)
            code, _out, err = run(["--input", source])
            self.assertEqual(code, rig_tool.EXIT_INVOCATION)
            self.assertIn("--output", err)


class ShippedHeroTests(unittest.TestCase):
    """The asset in the repository is this tool's output, and stays so."""

    def test_req_002_the_shipped_hero_is_what_the_extender_produces(self):
        # If someone re-rigs or re-exports the hero without running the
        # extender, this is where it shows: not as a foot on the wrong bone in
        # a play session, but as a red test naming the tool to run.
        code, out, err = run(["--input", HERO, "--check", "--format", "json"])
        self.assertEqual(code, rig_tool.EXIT_OK, out + err)
        report = json.loads(out)
        self.assertEqual(report["summary"]["bones"], 28)
        for leg in rig_tool.LEGS:
            entry = report["summary"]["legs"][leg]
            self.assertGreaterEqual(entry["soleOwnedByFootAfter"], 0.99, leg)
            # Two bones of comparable length fold; one long and one short do
            # not, which is what solving from the buried pivot produced.
            ratio = entry["upperLength"] / entry["lowerLength"]
            self.assertTrue(0.6 <= ratio <= 1.6,
                            "%s: upper/lower is %.2f" % (leg, ratio))


if __name__ == "__main__":
    unittest.main()
