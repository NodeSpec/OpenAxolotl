#!/usr/bin/env python3
"""Performance targets evidence (REQ-027 AC-1).

AC-1 demands a documented baseline specification and THREE numbers: the
frame-rate target, the maximum permitted frame-time spike, and the world
load-time budget. The numbers live twice by design -- prose in
docs/performance.md, machine-readable in
contracts/performance_targets.v1.json (which the perf gate loads) -- and
this suite is the reason the duplication is safe: it fails the moment the
two disagree, exactly like the commands.md / pr.yml parity suite.
"""

from __future__ import annotations

import json
import os
import re
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGETS_JSON = os.path.join(REPO, "contracts", "performance_targets.v1.json")
DOC = os.path.join(REPO, "docs", "performance.md")


def load_targets() -> dict:
    with open(TARGETS_JSON, encoding="utf-8") as handle:
        return json.load(handle)


def load_doc() -> str:
    with open(DOC, encoding="utf-8") as handle:
        return handle.read()


class TargetsAreNumbers(unittest.TestCase):
    """The machine-readable half: three positive numbers, sane protocol."""

    def test_req_027_all_three_targets_are_positive_numbers(self):
        targets = load_targets()
        for key in ("frameRateTargetFps", "maxFrameTimeSpikeMs",
                    "worldLoadTimeBudgetMs"):
            self.assertIn(key, targets)
            self.assertIsInstance(targets[key], (int, float))
            self.assertGreater(targets[key], 0, key)

    def test_req_027_headless_protocol_is_declared(self):
        # The gate's measurement rules are targets too: an undeclared
        # tolerance would let the gate quietly loosen itself.
        protocol = load_targets().get("headlessProtocol", {})
        self.assertGreater(protocol.get("sustainedRateTolerance", 0), 0)
        self.assertLessEqual(protocol.get("sustainedRateTolerance", 2), 1)
        self.assertGreaterEqual(protocol.get("discardLargestSpikes", -1), 0)


class DocMatchesJson(unittest.TestCase):
    """The prose half: the doc states the SAME numbers, and a baseline."""

    def test_req_027_doc_states_each_number(self):
        targets = load_targets()
        doc = load_doc()
        expectations = (
            ("frameRateTargetFps", "%d FPS", "**%d FPS**"),
            ("maxFrameTimeSpikeMs", "%d ms", "**%d ms**"),
            ("worldLoadTimeBudgetMs", "%d ms", "**%d ms**"),
        )
        for key, _, marked in expectations:
            value = int(targets[key])
            self.assertIn(
                marked % value, doc,
                f"docs/performance.md must state {key} as '{marked % value}' "
                "-- the doc and the JSON have drifted apart")

    def test_req_027_the_numbers_are_distinct_enough_to_bind(self):
        # Anti-vacuity for the containment check above: if two targets ever
        # carried the same number, a doc stating only one would still pass.
        targets = load_targets()
        values = [int(targets[k]) for k in
                  ("frameRateTargetFps", "maxFrameTimeSpikeMs",
                   "worldLoadTimeBudgetMs")]
        self.assertEqual(len(set(values)), 3,
                         "targets must be pairwise distinct or the doc "
                         "parity check cannot bind each one")

    def test_req_027_doc_documents_a_baseline_specification(self):
        doc = load_doc()
        self.assertIn("## The baseline specification", doc)
        for component in ("CPU", "RAM", "GPU", "Storage"):
            self.assertRegex(
                doc, rf"(?m)^\|\s*{component}\s*\|",
                f"the baseline table must state a {component} row")

    def test_req_027_doc_names_the_gate_and_its_limits(self):
        # The doc must say what the headless gate can NOT claim -- the
        # baseline frame-rate criterion stays open rather than being
        # green-lit by proxy.
        doc = load_doc()
        self.assertIn("test/perf/run_perf_gate.gd", doc)
        self.assertIn("not the baseline machine", doc)


class GateReadsTheJson(unittest.TestCase):
    """The gate loads the JSON, not private constants."""

    def test_req_027_gate_probe_points_at_the_targets_file(self):
        probe = os.path.join(REPO, "test", "perf", "perf_gate_probe.gd")
        with open(probe, encoding="utf-8") as handle:
            source = handle.read()
        self.assertIn("performance_targets.v1.json", source)
        # No hardcoded fallback numbers for the three targets: a missing or
        # malformed targets file must FAIL the gate, never default it.
        self.assertNotIn("frameRateTargetFps\", 60", source)
        self.assertTrue(
            re.search(r"must carry a positive number", source),
            "the probe must refuse to run without parseable targets")


if __name__ == "__main__":
    unittest.main(verbosity=2)
