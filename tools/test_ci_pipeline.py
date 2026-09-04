#!/usr/bin/env python3
"""CI Pipeline evidence (REQ-018).

Three claims are proven here, each the way it will actually be relied on:

1. PARITY (AC-3): docs/commands.md and .github/workflows/pr.yml carry
   character-identical validator commands, the workflow triggers on every
   pull request, and each validator really runs and emits the shared
   Validator CLI Invocation envelope. What CANNOT be proven from inside this
   repo -- GitHub executing the workflow, branch protection refusing a merge --
   is deliberately not asserted here; those criteria stay unflipped until a
   live pull request can be observed.

2. THE BUILD (AC-1, AC-2, AC-5): the documented clean-clone sequence is
   EXECUTED, not read -- a fresh `git clone`, the single build command, and a
   headless boot of the artifact it produced. The packaging assertion reads
   the produced .pck, because "the worlds are in the build" is a property of
   the bytes shipped, not of the export config that was supposed to put them
   there.

3. NO YAML-ONLY CHECKS: every check CI runs is a command a contributor can
   run locally. The parity test is two-directional for exactly this reason.

Heavy tests skip with a NAMED reason when nested under oax-test (the harness
already runs everything they would re-run) or when no Godot binary is
available -- never silently.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import oax_test  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMMANDS_DOC = os.path.join(REPO, "docs", "commands.md")
WORKFLOW = os.path.join(REPO, ".github", "workflows", "pr.yml")
PROTECTION_DOC = os.path.join(REPO, "docs", "branch-protection.md")

VALIDATOR_JOBS = ("level-contract", "asset-contract", "static-gate",
                  "test-harness", "build")

# The Validator CLI Invocation result envelope, as the contract publishes it.
ENVELOPE_KEYS = ("tool", "schemaVersion", "target", "passed", "violations")
VIOLATION_KEYS = ("rule", "severity", "file", "message")
TOOL_ENUM = ("level-contract-checker", "asset-contract-validator",
             "world-static-analysis", "test-harness")


def _read(path: str) -> str:
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def fenced_block(doc: str, marker: str) -> list[str]:
    """Commands inside the ```sh fence directly under an HTML marker."""
    pattern = re.compile(
        re.escape(f"<!-- {marker} -->") + r"\s*```sh\n(.*?)```", re.DOTALL)
    match = pattern.search(doc)
    if match is None:
        return []
    return [line.strip() for line in match.group(1).splitlines()
            if line.strip()]


def workflow_run_lines(text: str) -> list[str]:
    return [m.group(1).strip()
            for m in re.finditer(r"^\s*-\s+run:\s+(.+)$", text, re.MULTILINE)]


def nested_under_harness() -> bool:
    return os.environ.get(oax_test.NESTED_ENV) == "1"


class CommandParity(unittest.TestCase):
    """AC-3: the doc and the workflow may never drift apart."""

    def setUp(self) -> None:
        self.doc_commands = fenced_block(_read(COMMANDS_DOC), "ci-commands")
        self.workflow_text = _read(WORKFLOW)
        self.run_lines = workflow_run_lines(self.workflow_text)

    def test_req_018_extractor_actually_reads_commands(self) -> None:
        # Anti-vacuity: an extractor returning [] would green-light the two
        # containment tests below. Pin what the doc must currently carry.
        self.assertIn("oax-level-check --target . --format json",
                      self.doc_commands)
        self.assertIn("./scripts/build.sh", self.doc_commands)
        self.assertGreaterEqual(len(self.doc_commands), 4)

    def test_req_018_every_documented_command_is_run_by_ci_verbatim(self) -> None:
        for command in self.doc_commands:
            matches = [line for line in self.run_lines
                       if line == command
                       or line.startswith(command + " | tee ")]
            self.assertTrue(
                matches,
                f"documented command not run character-identically by CI:\n"
                f"  {command}")

    def test_req_018_ci_runs_no_validator_that_is_not_documented(self) -> None:
        # The other direction: a check that exists only in YAML cannot be run
        # locally, which the invocation contract forbids.
        for line in self.run_lines:
            if line.startswith("oax-") or line == "./scripts/build.sh":
                bare = line.split(" | tee ")[0].strip()
                self.assertIn(
                    bare, self.doc_commands,
                    f"CI runs an undocumented validator command: {line}")

    def test_req_018_workflow_triggers_on_every_pull_request(self) -> None:
        self.assertRegex(self.workflow_text, r"(?m)^on:\s*\n\s+pull_request:")

    def test_req_018_all_four_jobs_exist(self) -> None:
        for job in VALIDATOR_JOBS:
            self.assertRegex(
                self.workflow_text, rf"(?m)^  {re.escape(job)}:\s*$",
                f"pr.yml must define job '{job}'")

    def test_req_018_every_action_is_pinned_to_a_full_sha(self) -> None:
        uses = re.findall(r"uses:\s*(\S+)", self.workflow_text)
        self.assertTrue(uses)
        for ref in uses:
            self.assertRegex(
                ref, r"@[0-9a-f]{40}$",
                f"action not pinned to a 40-hex commit SHA: {ref}")

    def test_req_018_branch_protection_doc_names_every_required_job(self) -> None:
        # AC-4's deliverable half: the setting itself lives in repo settings
        # (and stays UNVERIFIED until applied); the doc must at least demand
        # exactly the jobs the workflow defines.
        doc = _read(PROTECTION_DOC)
        for job in VALIDATOR_JOBS:
            self.assertIn(f"`{job}`", doc)


class ValidatorEnvelopes(unittest.TestCase):
    """AC-3: the commands CI runs exist, run, and speak one JSON shape."""

    def assert_envelope(self, payload: dict, tool: str) -> None:
        for key in ENVELOPE_KEYS:
            self.assertIn(key, payload)
        self.assertEqual(payload["tool"], tool)
        self.assertIn(payload["tool"], TOOL_ENUM)
        self.assertIsInstance(payload["passed"], bool)
        for violation in payload["violations"]:
            for key in VIOLATION_KEYS:
                self.assertIn(key, violation)
            self.assertIn(violation["severity"], ("error", "warning"))

    def run_tool(self, script: str, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, os.path.join("tools", script), *args],
            capture_output=True, text=True, cwd=REPO)

    def test_req_018_entry_points_resolve_to_real_callables(self) -> None:
        # CI invokes the console names; each must map to an importable main.
        import importlib
        with open(os.path.join(REPO, "pyproject.toml"), encoding="utf-8") as f:
            scripts = re.findall(r'^(oax-[\w-]+)\s*=\s*"([\w.]+):(\w+)"',
                                 f.read(), re.MULTILINE)
        self.assertEqual(
            sorted(name for name, _, _ in scripts),
            ["oax-asset-check", "oax-level-check", "oax-static-gate",
             "oax-test"])
        for _, module_name, attr in scripts:
            module = importlib.import_module(module_name)
            self.assertTrue(callable(getattr(module, attr)))

    def test_req_018_level_checker_emits_the_shared_envelope(self) -> None:
        clean = self.run_tool("level_contract_checker.py",
                              "--target", ".", "--format", "json")
        self.assertEqual(clean.returncode, 0, clean.stderr)
        self.assert_envelope(json.loads(clean.stdout), "level-contract-checker")

        failing = self.run_tool("level_contract_checker.py",
                                "--target", "fixtures", "--format", "json")
        self.assertEqual(failing.returncode, 1)
        payload = json.loads(failing.stdout)
        self.assert_envelope(payload, "level-contract-checker")
        self.assertFalse(payload["passed"])
        self.assertTrue(payload["violations"])

    def test_req_018_asset_validator_emits_the_shared_envelope(self) -> None:
        result = self.run_tool("asset_contract_validator.py",
                               "--target", ".", "--format", "json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_envelope(json.loads(result.stdout),
                             "asset-contract-validator")

    def test_req_018_static_gate_emits_the_shared_envelope(self) -> None:
        result = self.run_tool("static_gate.py",
                               "--target", ".", "--format", "json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_envelope(json.loads(result.stdout), "world-static-analysis")

    def test_req_018_test_harness_emits_the_shared_envelope(self) -> None:
        if nested_under_harness():
            self.skipTest("running under oax-test already; a nested full "
                          "suite would recurse")
        if oax_test.find_godot() is None:
            self.skipTest("no Godot binary: set $OAX_GODOT or run "
                          "scripts/setup.sh")
        result = self.run_tool("oax_test.py", "--target", ".",
                               "--format", "json")
        self.assertEqual(result.returncode, 0,
                         result.stdout[-2000:] + result.stderr[-2000:])
        payload = json.loads(result.stdout)
        self.assert_envelope(payload, "test-harness")
        self.assertEqual(
            payload["suitesRun"],
            ["python-unit", "gdunit", "smoke-greybox", "template-walk",
             "hub-walk"])

    def test_req_018_harness_refuses_rather_than_skipping_godot(self) -> None:
        # No engine must be exit 2 (invocation error), never a hollow pass.
        # Run from a bare fake project so neither $OAX_GODOT, a .toolchain/,
        # nor PATH can supply an engine.
        env = {k: v for k, v in os.environ.items()}
        env["OAX_GODOT"] = ""
        env["PATH"] = "/nonexistent"
        with tempfile.TemporaryDirectory() as bare:
            with open(os.path.join(bare, "project.godot"), "w",
                      encoding="utf-8") as handle:
                handle.write("config_version=5\n")
            result = subprocess.run(
                [sys.executable,
                 os.path.join(REPO, "tools", "oax_test.py"), "--target", "."],
                capture_output=True, text=True, cwd=bare, env=env)
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("no Godot binary", result.stderr)


class CleanCloneBuild(unittest.TestCase):
    """AC-1, AC-2, AC-5 -- proven by EXECUTING the documented sequence.

    One fresh `git clone` of this repository's HEAD, driven exactly as
    docs/commands.md dictates. The only substitutions: the clone URL becomes
    the local repository (the bytes under test are the ones about to be
    pushed, and the network is not what is being tested), and the final run
    command gains headless flags plus a frame budget so a windowless machine
    can observe "a running game" as a clean boot-and-exit. $OAX_GODOT injects
    the cached engine binary -- a documented cache path of setup.sh that
    changes where bytes come from, never which command runs.
    """

    sequence: list[str] = []
    clone_dir: str = ""
    boot: subprocess.CompletedProcess | None = None
    artifact_missing_before_build = False
    build_command = ""

    @classmethod
    def setUpClass(cls) -> None:
        if nested_under_harness():
            raise unittest.SkipTest(
                "running under oax-test already; CI's build job performs "
                "this end to end")
        godot = oax_test.find_godot()
        if godot is None:
            raise unittest.SkipTest(
                "no Godot binary: set $OAX_GODOT or run scripts/setup.sh")

        cls.sequence = fenced_block(_read(COMMANDS_DOC),
                                    "clean-clone-sequence")
        if not cls.sequence:
            return  # the sequence test below will fail loudly

        cls.tmp = tempfile.TemporaryDirectory()
        cwd = cls.tmp.name
        env = dict(os.environ)
        env["OAX_GODOT"] = os.path.abspath(godot)

        for command in cls.sequence:
            if command.startswith("git clone "):
                command = re.sub(r"https://\S+", REPO, command)
            if command.startswith("cd "):
                cwd = os.path.join(cwd, command[3:].strip())
                cls.clone_dir = cwd
                continue
            if command == "./scripts/build.sh":
                cls.build_command = command
                cls.artifact_missing_before_build = not os.path.exists(
                    os.path.join(cwd, "build", "linux", "OpenAxolotl.x86_64"))
            if command.startswith("./build/"):
                command += " --headless --audio-driver Dummy --quit-after 120"
                cls.boot = subprocess.run(
                    command, shell=True, cwd=cwd, env=env,
                    capture_output=True, text=True, timeout=300)
                continue
            step = subprocess.run(command, shell=True, cwd=cwd, env=env,
                                  capture_output=True, text=True, timeout=900)
            if step.returncode != 0:
                raise AssertionError(
                    f"documented command failed:\n  {command}\n"
                    f"{step.stdout[-3000:]}\n{step.stderr[-3000:]}")

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "tmp"):
            cls.tmp.cleanup()

    def pck_paths(self) -> list[str]:
        """The .pck's file index, parsed from the bytes actually shipped.

        Byte-searching the whole pack is not good enough: the packed
        global_script_class_cache.cfg CONTAINS test-script paths as text, so
        only the index says what files are truly in the artifact. GDPC v2
        layout: magic, format version, engine version triple, pack flags,
        file base, 16 reserved words, file count, then per file a
        length-prefixed padded path + offset/size/md5/flags.
        """
        import struct
        path = os.path.join(self.clone_dir, "build", "linux",
                            "OpenAxolotl.pck")
        self.assertTrue(os.path.isfile(path), "the build produced no .pck")
        with open(path, "rb") as handle:
            data = handle.read()
        self.assertEqual(data[:4], b"GDPC", "not a Godot pack file")
        version = struct.unpack_from("<I", data, 4)[0]
        self.assertEqual(version, 2, f"unexpected pack format v{version}")
        cursor = 4 + 4 * 5 + 8 + 4 * 16  # magic..file_base + reserved
        (count,) = struct.unpack_from("<I", data, cursor)
        cursor += 4
        paths: list[str] = []
        for _ in range(count):
            (path_len,) = struct.unpack_from("<I", data, cursor)
            cursor += 4
            raw = data[cursor:cursor + path_len]
            paths.append(raw.rstrip(b"\x00").decode("utf-8"))
            cursor += path_len + 8 + 8 + 16 + 4  # offset, size, md5, flags
        return paths

    def test_req_018_sequence_is_at_most_five_commands(self) -> None:
        self.assertTrue(self.sequence,
                        "docs/commands.md must carry the clean-clone sequence")
        self.assertLessEqual(len(self.sequence), 5)

    def test_req_018_build_came_from_the_single_documented_command(self) -> None:
        self.assertEqual(self.build_command, "./scripts/build.sh")
        self.assertTrue(self.artifact_missing_before_build,
                        "the artifact predated the build command -- the "
                        "sequence did not produce it")
        self.assertTrue(os.path.isfile(os.path.join(
            self.clone_dir, "build", "linux", "OpenAxolotl.x86_64")))

    def test_req_018_following_the_sequence_boots_the_game(self) -> None:
        self.assertIsNotNone(self.boot, "the sequence never ran the game")
        assert self.boot is not None
        self.assertEqual(
            self.boot.returncode, 0,
            f"the built game did not boot cleanly:\n"
            f"{self.boot.stdout[-2000:]}\n{self.boot.stderr[-2000:]}")

    def test_req_018_artifact_packages_core_hub_and_every_world(self) -> None:
        # The pack INDEX is the packaging claim. Every module installed under
        # worlds/ must ship -- enumerated from the filesystem, never from a
        # list in this test.
        paths = self.pck_paths()
        self.assertTrue(any(p.startswith("res://hub/open_lagoon.tscn")
                            for p in paths))
        self.assertTrue(any(p.startswith("res://core/") for p in paths))
        self.assertIn("res://contracts/level_contract.v1.json", paths)

        worlds_root = os.path.join(self.clone_dir, "worlds")
        modules = [entry for entry in sorted(os.listdir(worlds_root))
                   if os.path.isfile(os.path.join(
                       worlds_root, entry, "world.json"))]
        self.assertTrue(modules, "the clone carries no world modules at all")
        for module in modules:
            self.assertIn(f"res://worlds/{module}/world.json", paths)
            self.assertTrue(
                any(p.startswith(f"res://worlds/{module}/world.tscn")
                    for p in paths),
                f"module scene missing from the artifact: {module}")

    def test_req_018_artifact_ships_no_tests_or_fixtures(self) -> None:
        shipped = [p for p in self.pck_paths()
                   if p.startswith(("res://test/", "res://fixtures/",
                                    "res://dev/", "res://tools/"))]
        self.assertEqual(shipped, [])


if __name__ == "__main__":
    unittest.main()
