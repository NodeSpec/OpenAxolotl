#!/usr/bin/env python3
"""Tests for the Level Contract compliance checker (REQ-007).

    python -m unittest discover -s tools -p 'test_*.py' -v

Standard library only, matching the checker itself: a contributor or an agent
must be able to run these without installing anything.

Test names carry the requirement id they prove, so a failure names the rule that
broke -- the same convention the GDScript suite uses.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import level_contract_checker as checker  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCHEMA = os.path.join(REPO, "contracts", "level_contract.v1.json")
FIXTURES = os.path.join(REPO, "fixtures", "worlds")
CHECKER = os.path.join(REPO, "tools", "level_contract_checker.py")
CONTRACT_DOC = os.path.join(REPO, "docs", "level-contract.md")


def fixture(name: str) -> str:
    return os.path.join(FIXTURES, name)


def run_cli(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, CHECKER, *args],
                          capture_output=True, text=True, cwd=REPO)


class SchemaIsTheSourceOfTruth(unittest.TestCase):
    """AC-1 and AC-8: the rules live in data, not in this tool."""

    def test_req_007_the_checker_names_no_contract_element(self):
        # THE structural claim. If the checker mentioned an element by name it
        # would be a second source of truth, and AC-8 would be false however
        # the code happened to behave today.
        with open(CHECKER, "r", encoding="utf-8") as handle:
            source = handle.read()
        # Strip comments and docstrings: the file explains itself at length, and
        # prose about spawn points is not a hardcoded rule about spawn points.
        source = re.sub(r'\"\"\".*?\"\"\"', "", source, flags=re.S)
        source = re.sub(r"^\s*#.*$", "", source, flags=re.M)

        with open(SCHEMA, "r", encoding="utf-8") as handle:
            schema = json.load(handle)
        elements = set(schema["required"]) | set(schema["optional"])

        # What this forbids is element-specific LOGIC. Reading the schema
        # document's own top-level metadata is not that, and one metadata field
        # ("contractVersion") happens to share a name with an element. So a
        # mention is only allowed on a line that reads it straight off the
        # schema -- `schema.get(...)`. Anything else, including any branch on an
        # element name, still fails.
        leaked = []
        for line in source.splitlines():
            for element in elements:
                if element not in line:
                    continue
                if "schema.get(" in line:
                    continue
                leaked.append(f"{element}: {line.strip()}")

        self.assertEqual(
            leaked, [],
            f"REQ-007 AC-1: the checker contains element-specific logic:\n  "
            + "\n  ".join(leaked)
            + "\nConformance rules must come from the schema, never from this file")

    def test_req_007_the_leak_check_catches_element_specific_logic(self):
        # Anti-vacuity: a structural scan that never fires proves nothing.
        # Prove it rejects the exact shape it exists to forbid.
        with open(SCHEMA, "r", encoding="utf-8") as handle:
            elements = set(json.load(handle)["required"])
        smuggled = '    if element == "spawnPoint":\n        return []\n'

        leaked = [e for line in smuggled.splitlines() for e in elements
                  if e in line and "schema.get(" not in line]
        self.assertEqual(leaked, ["spawnPoint"],
                         "the leak check must catch a branch on an element name")

    def test_req_007_every_schema_rule_kind_is_implemented(self):
        with open(SCHEMA, "r", encoding="utf-8") as handle:
            schema = json.load(handle)
        engine = checker.RuleEngine(
            target=fixture("conforming_world"), schema_path=SCHEMA,
            manifest={}, manifest_name="world.json", manifest_text="",
            scene_groups={}, scene_name="world.tscn")

        missing = sorted(set(schema["ruleKinds"]) - engine.supported_kinds())
        self.assertEqual(missing, [],
                         f"the schema declares rule kinds the checker cannot run: {missing}")

    def test_req_007_adding_a_rule_to_the_schema_changes_behaviour(self):
        # AC-8, demonstrated rather than asserted: a NEW rule, of an existing
        # kind, added to a copy of the schema, with not one line of this tool
        # changed. The conforming fixture passes the shipped schema and must
        # fail the extended one.
        self.assertTrue(checker.check_world(fixture("conforming_world"), SCHEMA).conforming)

        with open(SCHEMA, "r", encoding="utf-8") as handle:
            schema = json.load(handle)
        schema["required"]["ceremonialGreeting"] = {
            "manifestField": "ceremonialGreeting",
            "description": "Invented by this test. No checker knows it exists.",
            "rules": [{"kind": "manifest_field_present", "field": "ceremonialGreeting"}],
        }

        # Beside the real schema, so the tuning reference still resolves.
        extended = os.path.join(os.path.dirname(SCHEMA), "_extended_test.json")
        try:
            with open(extended, "w", encoding="utf-8") as handle:
                json.dump(schema, handle)
            report = checker.check_world(fixture("conforming_world"), extended)
        finally:
            if os.path.exists(extended):
                os.remove(extended)

        self.assertFalse(report.conforming,
                         "REQ-007 AC-8: a rule added to the schema must change "
                         "what the checker enforces, with no code change")
        self.assertEqual([v.element for v in report.violations], ["ceremonialGreeting"])

    def test_req_007_an_unknown_rule_kind_is_an_invocation_error(self):
        # The honest failure mode: a schema asking for a check this build cannot
        # perform must not silently pass the world.
        with open(SCHEMA, "r", encoding="utf-8") as handle:
            schema = json.load(handle)
        schema["required"]["worldId"]["rules"].append(
            {"kind": "consult_the_oracle", "field": "worldId"})

        extended = os.path.join(os.path.dirname(SCHEMA), "_unknown_kind_test.json")
        try:
            with open(extended, "w", encoding="utf-8") as handle:
                json.dump(schema, handle)
            with self.assertRaises(checker.UnknownRuleKind):
                checker.check_world(fixture("conforming_world"), extended)
        finally:
            if os.path.exists(extended):
                os.remove(extended)


class RequiredElements(unittest.TestCase):
    """AC-1's other half: presence and well-formedness of what the schema declares."""

    def test_req_007_a_conforming_world_passes(self):
        report = checker.check_world(fixture("conforming_world"), SCHEMA)
        self.assertTrue(report.conforming,
                        f"the conforming fixture should pass: "
                        f"{[v.to_text() for v in report.violations]}")

    def test_req_007_a_missing_required_element_is_caught(self):
        report = checker.check_world(fixture("missing_checkpoint"), SCHEMA)
        self.assertFalse(report.conforming)
        self.assertEqual([(v.element, v.rule) for v in report.violations],
                         [("checkpoints", "scene_group_count")])

    def test_req_007_an_element_bounded_at_one_rejects_two(self):
        report = checker.check_world(fixture("two_spawn_points"), SCHEMA)
        self.assertEqual([(v.element, v.rule) for v in report.violations],
                         [("spawnPoint", "scene_group_count")])

    def test_req_007_a_malformed_manifest_is_reported_not_crashed(self):
        report = checker.check_world(fixture("malformed_manifest"), SCHEMA)
        self.assertFalse(report.conforming)
        self.assertIn("manifest_parse", [v.rule for v in report.violations])

    def test_req_007_an_override_outside_the_sanctioned_set_is_refused(self):
        # The cross-file citation resolving: the contract names the tuning
        # surface's own list rather than keeping a copy.
        report = checker.check_world(fixture("unsanctioned_tuning"), SCHEMA)
        self.assertEqual([(v.element, v.rule) for v in report.violations],
                         [("tuningOverrides", "manifest_keys_subset_of")])


class ContractVersion(unittest.TestCase):
    """AC-2."""

    def test_req_007_a_world_targeting_an_unsupported_version_is_rejected(self):
        report = checker.check_world(fixture("unsupported_version"), SCHEMA)
        self.assertEqual([(v.element, v.rule) for v in report.violations],
                         [("contractVersion", "manifest_field_in_set")])
        self.assertIn("9.9", report.violations[0].message)


class ModuleLayout(unittest.TestCase):
    """AC-3."""

    def test_req_007_a_world_id_breaking_the_convention_is_rejected(self):
        report = checker.check_world(fixture("bad_world_id"), SCHEMA)
        rules = sorted(v.rule for v in report.violations)
        self.assertEqual(rules, ["manifest_field_equals_directory_name",
                                 "manifest_field_matches"])

    def test_req_007_a_world_may_not_carry_project_wide_configuration(self):
        report = checker.check_world(fixture("stray_project_file"), SCHEMA)
        self.assertEqual([(v.element, v.rule) for v in report.violations],
                         [("moduleLayout", "file_absent")])

    def test_req_007_a_module_missing_its_required_files_is_rejected(self):
        with tempfile.TemporaryDirectory() as empty:
            report = checker.check_world(empty, SCHEMA)
            missing = [v.file for v in report.violations if v.rule == "file_present"]
            self.assertEqual(sorted(missing), ["world.json", "world.tscn"])


class StructuredOutput(unittest.TestCase):
    """AC-4: an agent must be able to parse and self-correct against this."""

    def test_req_007_json_output_locates_every_violation(self):
        result = run_cli("--target", "fixtures/worlds/missing_checkpoint",
                         "--format", "json")
        payload = json.loads(result.stdout)

        self.assertFalse(payload["conforming"])
        for violation in payload["violations"]:
            for key in ("element", "rule", "file", "line", "message"):
                self.assertIn(key, violation)
            self.assertTrue(violation["element"])
            self.assertTrue(violation["rule"])
            self.assertTrue(violation["file"])

    def test_req_007_a_manifest_violation_carries_a_line_number(self):
        # "Its file location" in AC-4 means a place to look, not just a filename.
        result = run_cli("--target", "fixtures/worlds/unsupported_version",
                         "--format", "json")
        violation = json.loads(result.stdout)["violations"][0]
        self.assertEqual(violation["file"], "world.json")
        self.assertIsInstance(violation["line"], int)
        self.assertGreater(violation["line"], 0)

    def test_req_007_text_output_is_for_humans_and_json_for_machines(self):
        human = run_cli("--target", "fixtures/worlds/missing_checkpoint")
        self.assertIn("FAIL", human.stdout)
        with self.assertRaises(json.JSONDecodeError):
            json.loads(human.stdout)


class ExitCodes(unittest.TestCase):
    """AC-5, and the contract with CI."""

    def test_req_007_zero_on_success_and_one_on_violation(self):
        self.assertEqual(run_cli("--target", "fixtures/worlds/conforming_world").returncode, 0)
        self.assertEqual(run_cli("--target", "fixtures/worlds/missing_checkpoint").returncode, 1)

    def test_req_007_two_on_an_invocation_error(self):
        # Distinct from a violation on purpose: "your world is wrong" and "you
        # called me wrong" need different answers from a CI job and an agent.
        self.assertEqual(run_cli("--target", "fixtures/worlds/does_not_exist").returncode, 2)
        self.assertEqual(run_cli("--target", "fixtures/worlds/conforming_world",
                                 "--schema", "contracts/nope.json").returncode, 2)


class DocumentedCommand(unittest.TestCase):
    """AC-6, and the anti-drift rule REQ-017 AC-2 asks for."""

    def test_req_007_the_command_in_the_docs_actually_runs(self):
        # Documentation drift should fail a test, not mislead a contributor.
        with open(CONTRACT_DOC, "r", encoding="utf-8") as handle:
            doc = handle.read()

        commands = [line.strip() for line in doc.splitlines()
                    if line.strip().startswith("python tools/level_contract_checker.py")]
        self.assertTrue(commands,
                        "docs/level-contract.md must document how to run the checker")

        for command in commands:
            parts = command.split()[1:]  # drop the leading "python"
            parts = [p.replace("worlds/<your_world>",
                               "fixtures/worlds/conforming_world") for p in parts]
            result = subprocess.run([sys.executable, *parts],
                                    capture_output=True, text=True, cwd=REPO)
            self.assertEqual(
                result.returncode, 0,
                f"the documented command failed:\n  {command}\n{result.stderr}")


class OfficialWorlds(unittest.TestCase):
    """AC-7's second half, which cannot be proven yet."""

    def test_req_007_every_installed_world_passes(self):
        worlds_dir = os.path.join(REPO, "worlds")
        if not os.path.isdir(worlds_dir):
            self.skipTest("no worlds/ directory: REQ-011 and REQ-028 are unbuilt, "
                          "so 'each official MVP world passes' has no subject yet")
        modules = [d for d in sorted(os.listdir(worlds_dir))
                   if os.path.isdir(os.path.join(worlds_dir, d))]
        self.assertTrue(modules, "worlds/ exists but holds no modules")
        for module in modules:
            report = checker.check_world(os.path.join(worlds_dir, module), SCHEMA)
            self.assertTrue(report.conforming,
                            f"official world {module} fails: "
                            f"{[v.to_text() for v in report.violations]}")


if __name__ == "__main__":
    unittest.main(verbosity=2)
