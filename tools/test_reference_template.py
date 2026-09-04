"""Tests for the Reference Template world — REQ-029.

Test names carry the requirement id they prove so a failure reports it as the
failing rule (REQ-026 AC-6).

The template's value is in what it does NOT contain, so most of these assert an
absence. The load-bearing one is
`test_req_029_a_contract_change_that_breaks_the_template_fails_loudly`: the
template only works as a tripwire if a tightened contract actually rejects it,
and every other test here would keep passing if it had quietly stopped doing so.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from level_contract_checker import (  # noqa: E402
    EXIT_OK,
    EXIT_VIOLATIONS,
    check_world,
    scan_scene_groups,
)
from static_gate import run_gate  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(REPO, "worlds", "reference_template")
CONTRACT = os.path.join(REPO, "contracts", "level_contract.v1.json")
POLICY = os.path.join(REPO, "contracts", "engine_feature_policy.v1.json")
SANCTIONED = os.path.join(REPO, "contracts", "sanctioned_api.v1.json")

MANIFEST = os.path.join(TEMPLATE, "world.json")
SCENE = os.path.join(TEMPLATE, "world.tscn")


def manifest() -> dict:
    with open(MANIFEST, encoding="utf-8") as handle:
        return json.load(handle)


def contract() -> dict:
    with open(CONTRACT, encoding="utf-8") as handle:
        return json.load(handle)


class RequiredElementsTests(unittest.TestCase):
    """AC-1 — all five required elements, present and findable."""

    def test_req_029_the_manifest_declares_every_required_manifest_field(self):
        data = manifest()
        for field in ("contractVersion", "worldId", "controllerCompatibility",
                      "finishCondition", "saveIntegration"):
            self.assertIn(field, data, f"required element '{field}' is missing")

    def test_req_029_the_world_id_matches_the_directory_name(self):
        # The id IS the directory, the save-key namespace and the portal id.
        self.assertEqual(manifest()["worldId"], os.path.basename(TEMPLATE))

    def test_req_029_save_keys_are_namespaced_to_the_world(self):
        world_id = manifest()["worldId"]
        keys = manifest()["saveIntegration"]["keys"]
        self.assertTrue(keys, "the template declares a key so the element is exercised")
        for key in keys:
            self.assertTrue(
                key.startswith(world_id + "."),
                f"'{key}' must begin with the world id so two worlds cannot collide",
            )

    def test_req_029_the_scene_carries_the_required_groups(self):
        # The hub finds these by GROUP, never by node name.
        groups = scan_scene_groups(SCENE)
        self.assertEqual(
            len(groups.get("spawn_point", [])), 1,
            "exactly one spawn point; two is ambiguous, not richer",
        )
        self.assertGreaterEqual(
            len(groups.get("checkpoint", [])), 1,
            "checkpoints are required, not optional",
        )

    def test_req_029_the_finish_condition_has_the_volume_it_names(self):
        # finishCondition 'reach_volume' is a promise about the scene; a world
        # declaring it without a finish_volume would be unwinnable.
        self.assertEqual(manifest()["finishCondition"]["kind"], "reach_volume")
        self.assertGreaterEqual(
            len(scan_scene_groups(SCENE).get("finish_volume", [])), 1)


class MinimalityTests(unittest.TestCase):
    """AC-2 — no optional element, so every absent-default path stays exercised."""

    def test_req_029_the_template_declares_no_optional_element(self):
        # Recomputed from the contract rather than hardcoded, so an optional
        # element added later is covered without editing this test.
        optional = set(contract().get("optional", {}).keys())
        self.assertTrue(optional, "an empty optional set would pass vacuously")

        declared = set(manifest().keys())
        leaked = declared & optional
        self.assertEqual(
            leaked, set(),
            "REQ-029 AC-2: the template must declare NO optional element; a "
            f"template carrying extras stops being a tripwire. Found: {leaked}",
        )

    def test_req_029_the_template_ships_no_script_at_all(self):
        # A world is data and a scene. This is also why AC-4 holds trivially.
        scripts = [
            name for _root, _dirs, files in os.walk(TEMPLATE)
            for name in files if name.endswith(".gd")
        ]
        self.assertEqual(scripts, [], f"the template must ship no script: {scripts}")

    def test_req_029_the_template_carries_no_project_file(self):
        # A module carrying these is trying to be a game rather than part of one.
        for forbidden in ("project.godot", "export_presets.cfg"):
            self.assertFalse(
                os.path.exists(os.path.join(TEMPLATE, forbidden)),
                f"a world must never contain {forbidden}",
            )


class ValidationTests(unittest.TestCase):
    """AC-3 and AC-4 — the template passes both gates like any other world."""

    def test_req_029_the_template_passes_the_compliance_checker(self):
        report = check_world(TEMPLATE, CONTRACT)
        self.assertTrue(
            report.conforming,
            "the template must conform; violations: "
            + "; ".join(v.to_text() for v in report.violations),
        )

    def test_req_029_the_template_passes_the_static_analysis_gate(self):
        # Scanned from the repo root, because the world-only rule set keys off a
        # path starting with worlds/ — targeting the directory alone would test
        # the wrong rule set.
        report = run_gate(REPO, POLICY, SANCTIONED)
        offenders = [
            v.to_dict() for v in report.violations
            if v.file.startswith("worlds/reference_template/")
        ]
        self.assertEqual(offenders, [], f"template violations: {offenders}")

    def test_req_029_the_gate_actually_scanned_the_template(self):
        # Anti-vacuity for the test above: "no violations" is meaningless if the
        # walker never opened the files.
        import static_gate

        report = run_gate(REPO, POLICY, SANCTIONED)
        with open(POLICY, encoding="utf-8") as handle:
            policy = json.load(handle)
        scanned = list(static_gate.iter_target_files(REPO, policy))
        template_files = [f for f in scanned if f.startswith("worlds/reference_template/")]
        self.assertTrue(
            template_files,
            "the gate must actually walk the template, or its pass is vacuous",
        )
        self.assertGreater(report.files_scanned, 0)


class TripwireTests(unittest.TestCase):
    """AC-7 — a contract change that breaks the template must fail loudly."""

    def test_req_029_a_contract_change_that_breaks_the_template_fails_loudly(self):
        # The template's whole job as a tripwire: tighten the contract with a
        # new required manifest field and the template must be REJECTED, not
        # quietly accepted. Every other test in this file would keep passing if
        # this property had silently stopped holding.
        with tempfile.TemporaryDirectory() as scratch:
            tightened_path = os.path.join(scratch, "tightened.json")
            schema = contract()
            schema.setdefault("required", {})["newlyRequiredElement"] = {
                "manifestField": "newlyRequiredElement",
                "description": "A field added by a hypothetical contract bump.",
                "rules": [{
                    "kind": "manifest_field_present",
                    "field": "newlyRequiredElement",
                }],
            }
            with open(tightened_path, "w", encoding="utf-8") as handle:
                json.dump(schema, handle)

            report = check_world(TEMPLATE, tightened_path)

        self.assertFalse(
            report.conforming,
            "REQ-029 AC-7: a contract change the template cannot satisfy must "
            "fail rather than pass silently",
        )
        self.assertTrue(
            any("newlyRequiredElement" in v.to_text()
                for v in report.violations),
            "the failure must name the element that broke it",
        )

    def test_req_029_the_tripwire_control_passes_against_the_real_contract(self):
        # Proves the test above fails for the RIGHT reason: the same template,
        # checked against the unmodified contract, conforms.
        self.assertTrue(check_world(TEMPLATE, CONTRACT).conforming)

    def test_req_029_the_checker_reports_the_documented_exit_codes(self):
        for target, expected in ((TEMPLATE, EXIT_OK),
                                 (os.path.join(REPO, "fixtures", "worlds",
                                               "missing_checkpoint"),
                                  EXIT_VIOLATIONS)):
            proc = subprocess.run(
                [sys.executable,
                 os.path.join(REPO, "tools", "level_contract_checker.py"),
                 "--target", target, "--format", "json", "--schema", CONTRACT],
                capture_output=True, text=True,
            )
            self.assertEqual(
                proc.returncode, expected,
                f"{target} should exit {expected}; stderr={proc.stderr}",
            )


class CopyabilityTests(unittest.TestCase):
    """The template is the thing a contributor or agent copies."""

    def test_req_029_a_copied_and_renamed_template_still_conforms(self):
        # This is the actual contributor workflow from the README, executed.
        # If copying and renaming did not produce a conforming world, the
        # template would be teaching a pattern that does not work.
        with tempfile.TemporaryDirectory() as scratch:
            new_id = "my_world"
            destination = os.path.join(scratch, new_id)
            shutil.copytree(TEMPLATE, destination)

            manifest_path = os.path.join(destination, "world.json")
            with open(manifest_path, encoding="utf-8") as handle:
                data = json.load(handle)
            data["worldId"] = new_id
            data["displayName"] = "My World"
            data["saveIntegration"]["keys"] = [f"{new_id}.completed"]
            with open(manifest_path, "w", encoding="utf-8") as handle:
                json.dump(data, handle, indent=2)

            report = check_world(destination, CONTRACT)

        self.assertTrue(
            report.conforming,
            "copy + rename must yield a conforming world; violations: "
            + "; ".join(v.to_text() for v in report.violations),
        )

    def test_req_029_a_copy_that_forgets_to_renamespace_is_rejected(self):
        # The one mistake the README warns about, proven to be caught: renaming
        # the directory and worldId but leaving the old save keys behind.
        with tempfile.TemporaryDirectory() as scratch:
            new_id = "my_world"
            destination = os.path.join(scratch, new_id)
            shutil.copytree(TEMPLATE, destination)

            manifest_path = os.path.join(destination, "world.json")
            with open(manifest_path, encoding="utf-8") as handle:
                data = json.load(handle)
            data["worldId"] = new_id  # keys deliberately left un-namespaced
            with open(manifest_path, "w", encoding="utf-8") as handle:
                json.dump(data, handle, indent=2)

            report = check_world(destination, CONTRACT)

        self.assertFalse(
            report.conforming,
            "a save key still namespaced to the template must be rejected",
        )


if __name__ == "__main__":
    unittest.main()
