"""Tests for the World Static Analysis Gate — REQ-020, REQ-030.

Test names carry the requirement id they prove so a failure reports it as the
failing rule (REQ-026 AC-6).

The load-bearing test in this file is
`test_req_030_forbidden_names_in_comments_and_strings_are_not_flagged`, paired
with `test_req_030_the_masking_control_proves_that_guard_bites`. A gate that
greps raw source passes every rejection test here and is still useless, because
this project's own contracts, docs and tests discuss the banned APIs
constantly — so the guard against false positives has to be proven to bite,
not just asserted.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gdscript_scan import iter_names, mask_source  # noqa: E402
from static_gate import (  # noqa: E402
    EXIT_INVOCATION,
    EXIT_OK,
    EXIT_VIOLATIONS,
    GateProblem,
    run_gate,
)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(REPO, "fixtures", "staticgate")

MULTIPLAYER_REPO = os.path.join(FIXTURES, "multiplayer_repo")
MALICIOUS_WORLD = os.path.join(FIXTURES, "malicious_world")
CLEAN_REPO = os.path.join(FIXTURES, "clean_repo")

POLICY = os.path.join(REPO, "contracts", "engine_feature_policy.v1.json")
SANCTIONED = os.path.join(REPO, "contracts", "sanctioned_api.v1.json")


def gate(target: str):
    return run_gate(target, POLICY, SANCTIONED)


def rules_in(report) -> set[str]:
    return {v.rule for v in report.violations}


class MaskingTests(unittest.TestCase):
    """The scanner reads CODE, never prose."""

    def test_req_030_forbidden_names_in_comments_and_strings_are_not_flagged(self):
        report = gate(CLEAN_REPO)
        self.assertTrue(
            report.passed,
            "the clean fixture mentions every banned API in comments and "
            "strings only; flagging it would make the gate unusable. Got: "
            + json.dumps([v.to_dict() for v in report.violations], indent=2),
        )
        self.assertEqual(report.exit_code(), EXIT_OK)

    def test_req_030_the_masking_control_proves_that_guard_bites(self):
        """Anti-vacuity: the clean fixture really does contain the banned text."""
        with open(
            os.path.join(CLEAN_REPO, "core", "clean.gd"), encoding="utf-8"
        ) as handle:
            source = handle.read()
        for banned in ("@rpc", "rpc_id", "MultiplayerAPI", "FileAccess", "Expression"):
            self.assertIn(
                banned, source,
                f"the control is vacuous if the fixture never mentions {banned}",
            )
            self.assertNotIn(
                banned, mask_source(source),
                f"masking must remove '{banned}' when it appears only in prose",
            )

    def test_req_030_an_escaped_quote_does_not_end_a_string_early(self):
        source = 'var a := "say \\"@rpc\\" here"\nvar b := 1\n'
        self.assertNotIn("@rpc", mask_source(source))

    def test_req_030_masking_preserves_line_numbers(self):
        source = '\n'.join([
            "var a := 1",
            'var doc := """',
            "rpc_id lives in here",
            "and here",
            '"""',
            "func rpc_id_call() -> void:",
            "\trpc_id(1)",
        ]) + "\n"
        hits = [n for n in iter_names(source) if "rpc_id" in n.segments()]
        self.assertEqual(
            [n.line for n in hits], [7],
            "the only real rpc_id call is on line 7; a triple-quoted block "
            "must not shift the count",
        )

    def test_req_030_a_bare_symbol_matches_a_whole_segment_never_a_substring(self):
        # `is_multiplayer_authority` has its own rule; it must not ALSO fire the
        # bare `multiplayer` API rule, or one mistake reports as two.
        report = gate(MULTIPLAYER_REPO)
        authority = [
            v for v in report.violations
            if v.symbol == "is_multiplayer_authority"
        ]
        self.assertTrue(authority)
        for violation in authority:
            self.assertEqual(violation.rule, "multiplayer.authority")


class MultiplayerGateTests(unittest.TestCase):
    """REQ-030 — the ban is machine-enforced, not merely stated."""

    def test_req_030_the_multiplayer_fixture_is_rejected(self):
        report = gate(MULTIPLAYER_REPO)
        self.assertFalse(report.passed)
        self.assertEqual(report.exit_code(), EXIT_VIOLATIONS)

    def test_req_030_every_forbidden_class_is_detected_separately(self):
        # AC-3: one assertion per class, so a gate that stopped detecting one
        # class cannot hide behind the others still firing.
        report = gate(MULTIPLAYER_REPO)
        found = rules_in(report)
        for klass in ("apis", "calls", "nodes", "peers", "authority",
                      "annotations", "projectSettings"):
            self.assertIn(
                f"multiplayer.{klass}", found,
                f"no violation raised for the '{klass}' class",
            )

    def test_req_030_output_names_the_specific_api_and_the_file(self):
        report = gate(MULTIPLAYER_REPO)
        for violation in report.violations:
            self.assertTrue(violation.symbol, "every violation names its symbol")
            self.assertTrue(violation.file, "every violation names its file")
            self.assertGreater(violation.line, 0)
        symbols = {v.symbol for v in report.violations}
        self.assertIn("@rpc", symbols)
        self.assertIn("ENetMultiplayerPeer", symbols)

    def test_req_030_scene_files_are_scanned_for_multiplayer_nodes(self):
        # A MultiplayerSpawner can be added in the editor with no script
        # mentioning it, so a .gd-only gate would miss it entirely.
        report = gate(MULTIPLAYER_REPO)
        scene_hits = [v for v in report.violations if v.file.endswith(".tscn")]
        self.assertTrue(scene_hits, "the scene file must be scanned")
        self.assertEqual({v.rule for v in scene_hits}, {"multiplayer.nodes"})
        self.assertIn("MultiplayerSpawner", {v.symbol for v in scene_hits})

        # Pinned to the LINES of the two [node] declarations. The fixture's
        # header comment also names both types, so asserting only on symbols
        # passes even when real scene scanning is broken and the comment is
        # what matched — this caught exactly that.
        self.assertEqual(
            sorted(v.line for v in scene_hits), [11, 14],
            "violations must come from the node declarations, not the "
            f"comment header; got {[(v.line, v.symbol) for v in scene_hits]}",
        )

    def test_req_030_a_scene_comment_naming_a_banned_node_is_not_a_violation(self):
        # `.tscn` comments with ';' rather than '#'. The fixture header explains
        # the ban and must not be reported as breaking it.
        report = gate(MULTIPLAYER_REPO)
        comment_lines = {3, 4, 5, 6, 7}
        offenders = [
            v for v in report.violations
            if v.file.endswith(".tscn") and v.line in comment_lines
        ]
        self.assertEqual(
            offenders, [],
            f"scene comments must not be scanned; got {offenders}",
        )

    def test_req_030_project_godot_networking_settings_are_rejected(self):
        # AC-5, parsed as INI rather than pattern-matched.
        report = gate(MULTIPLAYER_REPO)
        settings = [
            v for v in report.violations
            if v.rule == "multiplayer.projectSettings"
        ]
        self.assertTrue(settings)
        symbols = {v.symbol for v in settings}
        self.assertIn("[network]", symbols)
        self.assertTrue(
            any("MultiplayerLobby" in s for s in symbols),
            f"the multiplayer autoload must be caught; got {symbols}",
        )

    def test_req_030_a_clean_project_godot_keeps_its_autoloads(self):
        # The rule must inspect autoloads for what they are, not reject the
        # section wholesale — the project has legitimate autoloads.
        report = gate(CLEAN_REPO)
        self.assertEqual(
            [v for v in report.violations
             if v.rule == "multiplayer.projectSettings"],
            [],
        )

    def test_req_030_the_scan_covers_core_not_world_modules_alone(self):
        # AC-2. The fixture's violations live under core/, which is the point:
        # a ban covering only contributed code would leave the engine's own
        # idiom free to enter through core.
        report = gate(MULTIPLAYER_REPO)
        core_hits = [v for v in report.violations if v.file.startswith("core/")]
        self.assertTrue(
            core_hits, "core/ must be in scope, not world modules alone"
        )


class ArchitectureBanTests(unittest.TestCase):
    """REQ-030 beyond source code: the ban holds in the design and the contracts."""

    def test_req_030_no_architecture_node_is_a_game_server(self):
        # AC-6. A multiplayer ban enforced only in source would still be
        # defeated by someone adding a server node to the architecture.
        with open(os.path.join(REPO, ".nodespec", "model.json"),
                  encoding="utf-8") as handle:
            model = json.load(handle)

        nodes = model.get("nodes", [])
        self.assertGreater(len(nodes), 0, "an empty model would pass vacuously")

        banned_words = ("server", "multiplayer", "network", "socket", "peer",
                        "matchmaking", "lobby")
        for node in nodes:
            haystack = " ".join(
                str(node.get(key, "")) for key in ("label", "type", "technology")
            ).lower()
            for word in banned_words:
                self.assertNotIn(
                    word, haystack,
                    f"node '{node.get('label')}' ({node.get('technology')}) "
                    f"reads as a {word} in the architecture",
                )

    def test_req_030_the_sanctioned_surface_mirrors_the_engine_policy(self):
        # AC-7. The ban lives in two contracts — one for core, one for worlds.
        # If they drift, a world could legally call what core cannot. This
        # recomputes the comparison rather than trusting both were edited.
        with open(POLICY, encoding="utf-8") as handle:
            policy_symbols = {
                s for group in json.load(handle)["forbiddenSymbols"].values()
                for s in group
            }
        with open(SANCTIONED, encoding="utf-8") as handle:
            raw = json.load(handle)["forbiddenCallClasses"]["multiplayer"]["symbols"]
        world_symbols = {
            s for group in raw.values() for s in group
        } if isinstance(raw, dict) else set(raw)

        missing = {
            s for s in policy_symbols
            if s not in world_symbols and "*" not in s and " " not in s
        }
        self.assertEqual(
            missing, set(),
            "every symbol the Engine Feature Policy bans for core must also be "
            f"forbidden for world modules; missing from sanctioned_api: {missing}",
        )


class SanctionedApiGateTests(unittest.TestCase):
    """REQ-020 — the malicious-submission pre-screen."""

    def test_req_020_the_malicious_world_is_rejected(self):
        report = gate(MALICIOUS_WORLD)
        self.assertFalse(report.passed)
        self.assertEqual(report.exit_code(), EXIT_VIOLATIONS)

    def test_req_020_each_forbidden_call_class_is_detected_separately(self):
        # AC-3: assert per-class rejection with the specific rule id.
        report = gate(MALICIOUS_WORLD)
        found = rules_in(report)
        for klass in ("filesystem", "network", "osExecution",
                      "dynamicEvaluation", "rawInput", "multiplayer"):
            self.assertIn(
                f"sanctioned.{klass}", found,
                f"the malicious world's '{klass}' attempt was not rejected",
            )

    def test_req_020_violations_name_the_offending_symbol_and_line(self):
        report = gate(MALICIOUS_WORLD)
        os_symbols = {
            v.symbol for v in report.violations
            if v.rule == "sanctioned.osExecution"
        }
        self.assertIn("OS.execute", os_symbols)
        self.assertIn("OS.shell_open", os_symbols)
        for violation in report.violations:
            self.assertTrue(violation.file.startswith("worlds/rogue_world/"))
            self.assertGreater(violation.line, 0)

    def test_req_020_a_violation_carries_the_contracts_rationale(self):
        # The rationale travels with the violation so an agent self-correcting
        # against the output learns WHY, not just that it failed.
        report = gate(MALICIOUS_WORLD)
        dynamic = next(
            v for v in report.violations if v.rule == "sanctioned.dynamicEvaluation"
        )
        self.assertIn("static analysis", dynamic.message.lower())

    def test_req_020_core_is_not_held_to_the_world_only_rules(self):
        # Core systems legitimately call engine APIs a world may not; applying
        # the world allowlist to core would make the gate unusable on day one.
        report = gate(CLEAN_REPO)
        self.assertEqual(
            [v for v in report.violations if v.rule.startswith("sanctioned.")],
            [],
        )


class ResultContractTests(unittest.TestCase):
    """The result object and exit codes are themselves contract surface."""

    def test_req_020_the_result_object_matches_the_validator_contract(self):
        report = gate(MALICIOUS_WORLD)
        payload = report.to_dict()
        for key in ("tool", "schemaVersion", "target", "passed", "violations"):
            self.assertIn(key, payload)
        self.assertEqual(payload["tool"], "world-static-analysis")
        self.assertFalse(payload["passed"])

    def test_req_020_schema_version_is_read_from_the_loaded_contract(self):
        # Never hardcoded, so a contract bump is visible in every result.
        with open(POLICY, encoding="utf-8") as handle:
            expected = json.load(handle)["contractVersion"]
        self.assertEqual(gate(CLEAN_REPO).schema_version, expected)

    def test_req_020_text_output_is_a_rendering_of_the_same_object(self):
        report = gate(MALICIOUS_WORLD)
        text = report.render_text()
        for violation in report.violations:
            self.assertIn(violation.rule, text)
            self.assertIn(violation.file, text)

    def test_req_020_a_bad_invocation_exits_two_not_one(self):
        # Exit 1 means "your code is bad"; exit 2 means "you called me wrong".
        # Collapsing them would make CI report a broken gate as a clean repo.
        with self.assertRaises(GateProblem):
            run_gate(os.path.join(FIXTURES, "no_such_dir"), POLICY, SANCTIONED)
        with self.assertRaises(GateProblem):
            run_gate(CLEAN_REPO, os.path.join(FIXTURES, "missing.json"), SANCTIONED)

    def test_req_020_the_cli_reports_the_documented_exit_codes(self):
        for target, expected in (
            (CLEAN_REPO, EXIT_OK),
            (MALICIOUS_WORLD, EXIT_VIOLATIONS),
            (os.path.join(FIXTURES, "no_such_dir"), EXIT_INVOCATION),
        ):
            proc = subprocess.run(
                [sys.executable, os.path.join(REPO, "tools", "static_gate.py"),
                 "--target", target, "--format", "json",
                 "--policy", POLICY, "--sanctioned", SANCTIONED],
                capture_output=True, text=True,
            )
            self.assertEqual(
                proc.returncode, expected,
                f"{target} should exit {expected}; stderr={proc.stderr}",
            )


class RepositoryDogfoodTests(unittest.TestCase):
    """The gate must pass the repository it guards."""

    def test_req_030_this_repository_declares_no_multiplayer_api(self):
        report = gate(REPO)
        offenders = [v.to_dict() for v in report.violations]
        self.assertTrue(
            report.passed,
            "the real tree must pass its own gate; violations: "
            + json.dumps(offenders, indent=2),
        )
        self.assertGreater(
            report.files_scanned, 20,
            "a pass over an empty file set would be vacuous",
        )


if __name__ == "__main__":
    unittest.main()
