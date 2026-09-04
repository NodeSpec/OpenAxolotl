#!/usr/bin/env python3
"""Tests for the Asset Contract and its validator (REQ-015, REQ-016).

    python -m unittest discover -s tools -p 'test_*.py' -v

Standard library only, like the validator. The fixture corpus is GENERATED
fresh into a temp directory each run by tools/asset_fixtures.py -- no binary
blob in the repository, and every fixture exists to demonstrate exactly one
violation, which is what lets these tests bind rule ids to causes.
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

import asset_contract_validator as validator  # noqa: E402
import asset_fixtures  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT = os.path.join(REPO, "contracts", "asset_contract.v1.json")
PROVENANCE_SCHEMA = os.path.join(REPO, "contracts", "provenance.schema.json")
VALIDATOR = os.path.join(REPO, "tools", "asset_contract_validator.py")
CONTRACT_DOC = os.path.join(REPO, "docs", "asset-contract.md")


def load(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def run_cli(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, VALIDATOR, *args],
                          capture_output=True, text=True, cwd=REPO)


class Corpus(unittest.TestCase):
    """Shared generated corpus, one per test class run."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.tmp = tempfile.TemporaryDirectory()
        cls.conforming, cls.nonconforming, cls.expected = \
            asset_fixtures.write_corpus(cls.tmp.name)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.tmp.cleanup()

    def report_for(self, target: str) -> dict:
        result = run_cli("--target", target, "--format", "json")
        payload = json.loads(result.stdout)
        payload["_returncode"] = result.returncode
        return payload


class ContractDeclares(unittest.TestCase):
    """REQ-015 AC-1/AC-2: the contract file carries the whole specification."""

    def setUp(self) -> None:
        self.contract = load(CONTRACT)

    def test_req_015_every_category_declares_file_types_and_constraints(self):
        categories = self.contract["categories"]
        self.assertGreaterEqual(len(categories), 5)
        for name, rules in categories.items():
            self.assertTrue(rules.get("fileTypes"),
                            f"category '{name}' declares no file types")
            image_like = ".png" in rules["fileTypes"]
            if image_like:
                # Resolution bounds and an explicit alpha policy, per category.
                self.assertIn("minSize", rules, name)
                self.assertIn("maxSize", rules, name)
                self.assertIn(rules.get("alpha"),
                              ("required", "forbidden", "allowed"), name)
            else:
                # Audio: format constraints instead.
                self.assertIn("maxChannels", rules, name)
                self.assertTrue(rules.get("sampleRates"), name)

    def test_req_015_layout_and_naming_convention_are_specified(self):
        layout = self.contract["layout"]
        self.assertEqual(layout["pattern"], "assets/<category>/<name>/")
        # The pattern must be a compilable regex that accepts the convention
        # and rejects its violations -- checked here so a contract edit that
        # breaks the pattern fails before the validator ever runs.
        pattern = re.compile(layout["namePattern"])
        self.assertIsNotNone(pattern.fullmatch("axo_scout"))
        self.assertIsNone(pattern.fullmatch("BigFish"))
        self.assertIsNone(pattern.fullmatch("2fast"))

    def test_req_015_provenance_schema_defines_the_conditional(self):
        # AC-5's structural half: the schema file exists, distinguishes the
        # two generation methods, and carries the if/then that conditionally
        # requires tool and prompt. The BEHAVIOUR is proven in ProvenanceRules.
        schema = load(PROVENANCE_SCHEMA)
        self.assertEqual(
            sorted(schema["properties"]["generationMethod"]["enum"]),
            ["ai-generated", "hand-authored"])
        for always in ("author", "generationMethod", "licenseTerms"):
            self.assertIn(always, schema["required"])
        self.assertEqual(
            schema["if"]["properties"]["generationMethod"]["const"],
            "ai-generated")
        self.assertEqual(sorted(schema["then"]["required"]), ["prompt", "tool"])
        # tool/prompt must NOT be unconditionally required.
        self.assertNotIn("tool", schema["required"])
        self.assertNotIn("prompt", schema["required"])


class ProvenanceRules(Corpus):
    """REQ-015 AC-3/AC-4/AC-5 and REQ-016 AC-3, proven by behaviour."""

    def violations_for(self, path_fragment: str) -> list[dict]:
        report = self.report_for(self.nonconforming)
        return [v for v in report["violations"] if path_fragment in v["file"]]

    def test_req_015_a_missing_provenance_fails_with_its_own_rule(self):
        rules = [v["rule"] for v in self.violations_for("mud_worm")]
        self.assertEqual(rules, ["provenance.missing"])

    def test_req_015_a_malformed_provenance_is_invalid_not_missing(self):
        rules = [v["rule"] for v in self.violations_for("silt_eel")]
        self.assertEqual(rules, ["provenance.invalid"])

    def test_req_015_ai_generated_without_tool_and_prompt_is_rejected(self):
        # The conditional, exercised end to end: gold_hook declares
        # ai-generated and omits both fields; each missing field is named.
        violations = self.violations_for("gold_hook")
        self.assertEqual([v["rule"] for v in violations],
                         ["provenance.invalid", "provenance.invalid"])
        messages = " ".join(v["message"] for v in violations)
        self.assertIn("tool", messages)
        self.assertIn("prompt", messages)

    def test_req_015_hand_authored_needs_no_tool_or_prompt(self):
        # The conforming corpus's splash_soft is hand-authored with neither
        # field, and the whole tree passes -- the other branch of the if/then.
        report = self.report_for(self.conforming)
        self.assertTrue(report["passed"], report["violations"])

    def test_req_015_every_base_field_is_enforced(self):
        # author, generationMethod, licenseTerms: drop each in isolation.
        schema = load(PROVENANCE_SCHEMA)
        base = {"author": "a", "generationMethod": "hand-authored",
                "licenseTerms": "CC0-1.0"}
        self.assertEqual(validator.evaluate_schema(schema, base), [])
        for field_name in ("author", "generationMethod", "licenseTerms"):
            broken = {k: v for k, v in base.items() if k != field_name}
            errors = validator.evaluate_schema(schema, broken)
            self.assertTrue(any(field_name in e for e in errors),
                            f"dropping {field_name} was not caught: {errors}")

    def test_req_015_unknown_fields_and_bad_method_are_rejected(self):
        schema = load(PROVENANCE_SCHEMA)
        self.assertTrue(validator.evaluate_schema(schema, {
            "author": "a", "generationMethod": "dreamed-up",
            "licenseTerms": "x"}))
        self.assertTrue(validator.evaluate_schema(schema, {
            "author": "a", "generationMethod": "hand-authored",
            "licenseTerms": "x", "mood": "cheerful"}))


class CategoryConformance(Corpus):
    """REQ-016 AC-1: file type, resolution, format, alpha -- per category."""

    def rules_for(self, path_fragment: str) -> list[str]:
        report = self.report_for(self.nonconforming)
        return [v["rule"] for v in report["violations"]
                if path_fragment in v["file"]]

    def test_req_016_wrong_file_type_is_caught(self):
        self.assertEqual(self.rules_for("net_ghost.jpg"),
                         ["character.file_type"])

    def test_req_016_resolution_bounds_are_enforced(self):
        self.assertEqual(self.rules_for("tiny_spark.png"),
                         ["character.resolution"])

    def test_req_016_missing_required_alpha_is_caught(self):
        self.assertEqual(self.rules_for("flat_crab.png"),
                         ["character.alpha_channel"])

    def test_req_016_opaque_is_legitimate_where_alpha_is_allowed(self):
        # The conforming reef_wall is an opaque environment texture; the
        # category's 'allowed' policy must not flag it. Guards against the
        # false-rejection failure mode the node explicitly warns about.
        report = self.report_for(self.conforming)
        self.assertTrue(report["passed"])

    def test_req_016_a_file_lying_about_its_format_is_caught(self):
        self.assertEqual(self.rules_for("broken_shell.png"),
                         ["prop.image_format"])

    def test_req_016_audio_constraints_are_enforced(self):
        self.assertEqual(self.rules_for("deep_hum.wav"),
                         ["audio.audio_format"])

    def test_req_016_ogg_headers_are_readable(self):
        # The header readers are the validator's eyes; prove them directly on
        # crafted bytes (Vorbis id, and garbage).
        with tempfile.TemporaryDirectory() as work:
            ogg = os.path.join(work, "hum.ogg")
            with open(ogg, "wb") as handle:
                handle.write(asset_fixtures.vorbis_ogg_bytes(
                    channels=2, rate=48000))
            self.assertEqual(validator.ogg_header(ogg), (2, 48000))

            junk = os.path.join(work, "junk.ogg")
            with open(junk, "wb") as handle:
                handle.write(b"definitely not ogg")
            with self.assertRaises(validator.HeaderError):
                validator.ogg_header(junk)

    def test_req_016_forbidden_alpha_policy_is_implemented(self):
        # No shipped category forbids alpha today, but the KIND must work the
        # day one does -- the engine is generic over the policy value.
        with tempfile.TemporaryDirectory() as work:
            png = os.path.join(work, "flat.png")
            asset_fixtures.write_png(png, 64, 64, alpha=True)
            checker = validator.AssetValidator(load(CONTRACT),
                                               load(PROVENANCE_SCHEMA))
            found = checker._check_image(
                "environment", {"alpha": "forbidden"}, png, "flat.png")
            self.assertEqual([v.rule for v in found],
                             ["environment.alpha_channel"])


class LayoutRules(Corpus):
    """REQ-016 AC-2: placement and naming."""

    def test_req_016_layout_violations_each_carry_their_rule(self):
        report = self.report_for(self.nonconforming)
        by_file = {v["file"]: v["rule"] for v in report["violations"]
                   if v["rule"].startswith("layout.")}
        self.assertEqual(by_file, {
            os.path.join("assets", "character", "BigFish"):
                "layout.name_convention",
            os.path.join("assets", "environment", "spare.png"):
                "layout.stray_file",
            os.path.join("assets", "prop", "empty_pearl"):
                "layout.empty_asset",
            os.path.join("assets", "vehicles"):
                "layout.unknown_category",
        })


class StructuredOutput(Corpus):
    """REQ-016 AC-4 and the shared Validator CLI envelope."""

    def test_req_016_every_failure_names_the_asset_and_the_rule(self):
        report = self.report_for(self.nonconforming)
        self.assertEqual(report["tool"], "asset-contract-validator")
        self.assertIn("schemaVersion", report)
        self.assertFalse(report["passed"])
        for violation in report["violations"]:
            for key in ("rule", "severity", "file", "message"):
                self.assertIn(key, violation)
            # The file is a specific path into the corpus, never a summary.
            self.assertTrue(violation["file"].startswith("assets" + os.sep),
                            violation["file"])
            self.assertRegex(violation["rule"], r"^[a-z_]+\.[a-z_]+$")

    def test_req_016_every_planted_fixture_is_caught_and_nothing_else(self):
        # The corpus's own expectation table IS the assertion: each planted
        # (path -> rule) pair appears, and no violation lands on a file the
        # corpus did not deliberately break.
        report = self.report_for(self.nonconforming)
        found = {(v["file"], v["rule"]) for v in report["violations"]}
        for rel, rule in self.expected.items():
            self.assertIn((os.path.join(*rel.split("/")), rule), found,
                          f"planted fixture not caught: {rel} -> {rule}")
        planted = {os.path.join(*rel.split("/"))
                   for rel in self.expected}
        for file_path, rule in found:
            self.assertIn(file_path, planted,
                          f"unexpected violation on an unplanted file: "
                          f"{file_path} [{rule}]")

    def test_req_016_text_output_is_a_rendering_of_the_same_object(self):
        json_run = run_cli("--target", self.nonconforming, "--format", "json")
        text_run = run_cli("--target", self.nonconforming)
        payload = json.loads(json_run.stdout)
        for violation in payload["violations"]:
            self.assertIn(violation["rule"], text_run.stdout)
            self.assertIn(violation["file"], text_run.stdout)


class ExitCodesAndCommand(Corpus):
    """REQ-016 AC-5's exit-code half, AC-6, and AC-7."""

    def test_req_016_exit_codes_follow_the_validator_contract(self):
        self.assertEqual(
            run_cli("--target", self.conforming).returncode, 0)
        self.assertEqual(
            run_cli("--target", self.nonconforming).returncode, 1)
        self.assertEqual(
            run_cli("--target", "no/such/directory").returncode, 2)
        self.assertEqual(
            run_cli("--target", self.conforming,
                    "--schema", "contracts/nope.json").returncode, 2)

    def test_req_016_fail_fast_stops_at_the_first_error(self):
        result = run_cli("--target", self.nonconforming,
                         "--format", "json", "--fail-fast")
        self.assertEqual(result.returncode, 1)
        payload = json.loads(result.stdout)
        errors = [v for v in payload["violations"]
                  if v["severity"] == "error"]
        self.assertEqual(len(errors), 1)

    def test_req_016_the_documented_command_actually_runs(self):
        # AC-6 via the project's anti-drift convention: the command the doc
        # gives a contributor is executed, not trusted.
        with open(CONTRACT_DOC, "r", encoding="utf-8") as handle:
            doc = handle.read()
        commands = [line.strip() for line in doc.splitlines()
                    if line.strip().startswith(
                        "python tools/asset_contract_validator.py")]
        self.assertTrue(commands,
                        "docs/asset-contract.md must document the command")
        for command in commands:
            parts = command.split()[1:]
            result = subprocess.run([sys.executable, *parts],
                                    capture_output=True, text=True, cwd=REPO)
            self.assertEqual(result.returncode, 0,
                             f"documented command failed: {command}\n"
                             f"{result.stderr}")

    def test_req_016_nonconforming_fixtures_fail_and_conforming_pass(self):
        # AC-7's fixture half, both directions.
        self.assertFalse(self.report_for(self.nonconforming)["passed"])
        self.assertTrue(self.report_for(self.conforming)["passed"])

    def test_req_016_every_official_asset_passes(self):
        # AC-7's other half. Enumerated from the repository, never listed
        # here, so this test starts biting the day official art lands.
        assets_root = os.path.join(REPO, "assets")
        if not os.path.isdir(assets_root):
            self.skipTest("no assets/ directory: no official assets exist "
                          "yet, so 'conforming official assets pass' has no "
                          "subject")
        report = self.report_for(REPO)
        self.assertTrue(report["passed"],
                        [v for v in report["violations"]])


if __name__ == "__main__":
    unittest.main(verbosity=2)
