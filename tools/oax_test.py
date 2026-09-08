#!/usr/bin/env python3
"""Run the whole automated test suite as ONE Validator CLI (REQ-018).

    oax-test --target . --format json

This is the Test Harness's face toward CI and toward agents self-verifying
before submission. It owns NO tests: every suite it runs is the exact command
a contributor runs by hand -- the Python unit tests, the GdUnit suite, and the
three headless playthrough probes -- and its whole job is to aggregate their
exit codes into the Validator CLI Invocation result shape the other three repo
validators already emit. A CI job and a laptop therefore run character-
identical checks, which is the binding constraint of REQ-018.

Godot resolution order: $OAX_GODOT, then the toolchain scripts/setup.sh
installs (.toolchain/godot), then `godot` on PATH. No Godot is an INVOCATION
error (exit 2), never a silent pass -- a harness that skips four fifths of the
suite because the engine was missing would be a green light with no bulb.

Exit codes are the contract with CI:
    0  every suite passed
    1  one or more suites failed
    2  invocation error -- bad arguments, unreadable target, no Godot binary
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

TOOL_NAME = "test-harness"
HARNESS_VERSION = "1.0"

# How many trailing lines of a failed suite's output travel in the violation
# message. Enough to see the failure list every runner prints last; not the
# whole transcript.
TAIL_LINES = 25

# Marks child processes so tests that would recurse into this harness know to
# stand down (tools/test_ci_pipeline.py exercises `oax-test` itself).
NESTED_ENV = "OAX_UNDER_TEST_HARNESS"

# (suite id, entry script, argv builder). Every suite is the DOCUMENTED local
# command -- adding a check that exists only here would break local/CI parity,
# so this table may only ever point at commands a contributor can run alone.
GODOT_FLAGS = ["--headless", "--audio-driver", "Dummy", "--path", "."]


def _suites(godot: str | None) -> list[dict]:
    return [
        {
            "id": "python-unit",
            "file": "tools",
            "argv": [sys.executable, "-m", "unittest", "discover",
                     "-s", "tools", "-p", "test_*.py"],
        },
        {
            "id": "gdunit",
            "file": "test/run_tests.gd",
            "argv": [godot, *GODOT_FLAGS, "--script", "test/run_tests.gd"],
        },
        {
            "id": "smoke-greybox",
            "file": "dev/run_smoke.gd",
            "argv": [godot, *GODOT_FLAGS, "--script", "dev/run_smoke.gd"],
        },
        {
            "id": "template-walk",
            "file": "test/worlds/run_template_walk.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/worlds/run_template_walk.gd"],
        },
        {
            "id": "hub-walk",
            "file": "test/hub/run_hub_walk.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/hub/run_hub_walk.gd"],
        },
        {
            # Falling out of the hub, proven by doing it. Written with the
            # fix and then left out of this table, so the one suite that
            # guards an unrecoverable soft-lock ran nowhere but by hand.
            "id": "hub-fall-recovery",
            "file": "test/hub/run_fall_recovery.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/hub/run_fall_recovery.gd"],
        },
        {
            "id": "coral-walk",
            "file": "test/worlds/run_coral_walk.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/worlds/run_coral_walk.gd"],
        },
        {
            "id": "bubble-walk",
            "file": "test/worlds/run_bubble_walk.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/worlds/run_bubble_walk.gd"],
        },
        {
            "id": "perf-gate",
            "file": "test/perf/run_perf_gate.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/perf/run_perf_gate.gd"],
        },
        {
            # The same gate pointed at the heaviest official scene. A perf
            # gate that never loads the heaviest world is a gate on the
            # wrong door; the probe reads OAX_PERF_WORLD.
            "id": "perf-gate-coral",
            "file": "test/perf/run_perf_gate.gd",
            "argv": [godot, *GODOT_FLAGS,
                     "--script", "test/perf/run_perf_gate.gd"],
            "env": {"OAX_PERF_WORLD": "coral_cove"},
        },
        *_gpu_suite(godot),
    ]


def _gpu_suite(godot: str | None) -> list[dict]:
    """The GPU gate, which is OPT-IN via OAX_GPU_GATE=1.

    NOTE THE ABSENT --headless: this one rasterises, which is the whole point.
    Both gates above run headless, which selects Godot's DUMMY rendering
    server -- they measure script and physics and never draw a pixel, so the
    entire GPU cost of the shared environment was invisible to CI until this
    existed.

    It is opt-in rather than default for two honest reasons, not to hide it:

      * IT NEEDS A DISPLAY. On a headless runner it has to be wrapped in
        xvfb-run, which not every environment has, and a suite that fails for
        want of an X server teaches contributors to ignore the harness.
      * IT IS SLOW. Three quality levels over the valley is minutes, not
        seconds, because SDFGI needs dozens of frames to settle before a
        sample means anything.

    The cheap half of the same contract IS in the default chain:
    test/core/rendering/test_render_quality.gd asserts the levels differ in
    the ways that make them cheaper. This suite is what proves they actually
    ARE cheaper, by measuring.
    """
    if os.environ.get("OAX_GPU_GATE", "") not in ("1", "true", "yes"):
        return []
    return [{
        "id": "gpu-gate",
        "file": "test/perf/run_gpu_gate.gd",
        "argv": [godot, "--audio-driver", "Dummy",
                 "--rendering-driver", "vulkan", "--resolution", "1280x720",
                 "--path", ".", "--script", "test/perf/run_gpu_gate.gd"],
    }]


def find_godot() -> str | None:
    override = os.environ.get("OAX_GODOT", "")
    if override and os.access(override, os.X_OK):
        return override
    toolchain = os.path.join(".toolchain", "godot")
    if os.access(toolchain, os.X_OK):
        return toolchain
    return shutil.which("godot")


def run_suite(suite: dict) -> tuple[int, str]:
    env = dict(os.environ)
    env[NESTED_ENV] = "1"
    env.update(suite.get("env", {}))
    completed = subprocess.run(
        suite["argv"], capture_output=True, text=True, env=env)
    output = (completed.stdout or "") + (completed.stderr or "")
    return completed.returncode, output


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="oax-test",
        description="Run the automated test suite as a repo validator.")
    parser.add_argument("--target", default=".",
                        help="repository root (default: .)")
    parser.add_argument("--format", choices=("text", "json"), default="text",
                        help="text for humans, json for CI and agents")
    parser.add_argument("--fail-fast", action="store_true",
                        help="stop after the first failing suite")
    args = parser.parse_args(argv)

    if not os.path.isdir(args.target):
        print(f"error: target {args.target!r} is not a directory",
              file=sys.stderr)
        return EXIT_INVOCATION
    if not os.path.isfile(os.path.join(args.target, "project.godot")):
        # The harness runs the game's own suites; pointing it anywhere else is
        # a call it cannot honour, and saying so beats pretending to test.
        print(f"error: target {args.target!r} has no project.godot; "
              "oax-test runs against a repository root", file=sys.stderr)
        return EXIT_INVOCATION

    godot = find_godot()
    if godot is None:
        print("error: no Godot binary found -- set $OAX_GODOT, run "
              "scripts/setup.sh, or put `godot` on PATH", file=sys.stderr)
        return EXIT_INVOCATION

    os.chdir(args.target)

    violations: list[dict] = []
    ran: list[str] = []

    # Warm the import cache first, exactly as scripts/build.sh does. A clean
    # checkout has no .godot/ directory: imported assets (the hero's .glb,
    # textures, audio) resolve only through it, and so does the class-name
    # registry the suites' scripts find each other by. Idempotent and quick
    # on a warm cache, so it runs unconditionally rather than guessing.
    warm = {
        "id": "import",
        "file": "project.godot",
        "argv": [godot, *GODOT_FLAGS, "--import"],
    }

    for suite in [warm, *_suites(godot)]:
        ran.append(suite["id"])
        code, output = run_suite(suite)
        if code != 0:
            tail = "\n".join(output.strip().splitlines()[-TAIL_LINES:])
            violations.append({
                "rule": f"{TOOL_NAME}.{suite['id']}",
                "severity": "error",
                "file": suite["file"],
                "message": f"suite exited {code}\n{tail}",
                "remediation": "run `%s` locally and fix the listed failures"
                               % " ".join(suite["argv"]),
            })
            if args.fail_fast:
                break

    passed = not violations
    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME,
            "schemaVersion": HARNESS_VERSION,
            "target": args.target,
            "passed": passed,
            "suitesRun": ran,
            "violations": violations,
        }, indent=2))
    else:
        print(f"{TOOL_NAME} v{HARNESS_VERSION} — target: {args.target}")
        for suite_id in ran:
            failed = any(v["rule"].endswith(suite_id) for v in violations)
            print(f"  {'FAIL' if failed else 'PASS'}  {suite_id}")
        for v in violations:
            print(f"\n[{v['rule']}]\n{v['message']}")
        print("\n" + ("PASS — all suites green" if passed
                      else f"FAIL — {len(violations)} suite(s) failed"))

    return EXIT_OK if passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
