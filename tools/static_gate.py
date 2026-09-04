"""The World Static Analysis Gate (REQ-020, REQ-030).

Answers one question: does this GDScript call anything it is not sanctioned to
call? Two requirements ride on it and both are load-bearing — the community
submission pipeline and the project-wide multiplayer ban. This is a family game
whose contribution pipeline explicitly welcomes AI agents; this gate plus
mandatory human review is what stands between that pipeline and arbitrary code
execution on a player's machine.

TWO RULE SETS, ONE WALKER, split by where a file sits:

  * The MULTIPLAYER rule set (Engine Feature Policy) scans core systems, the
    dev scene, the hub, official worlds, the reference template and community
    submissions. Scope is wider than world modules on purpose: a ban covering
    only contributed code would leave the engine's own multiplayer idiom free
    to walk in through core, which is exactly the risk, since ordinary Godot
    guidance — including the sample carried in this project's own node
    packets — is multiplayer-oriented.

  * The SANCTIONED-API rule set scans world modules ONLY, because core systems
    legitimately call engine APIs that a world may not.

Both rule sets are DATA, loaded from contracts/. Nothing forbidden is spelled
out in this file, so widening the ban is a contract edit rather than a code
change — and the multiplayer ban ends up enforced in three places that cannot
drift: the Engine Feature Policy for core, the Sanctioned World API Surface for
worlds, and project.godot's own settings.

This gate is a PRE-SCREEN, never a merge path. Branch protection requiring
maintainer approval belongs to the CI Pipeline node; a green gate never merges
anything on its own.

Standard library only — a contributor should never install anything to check
their own world.
"""

from __future__ import annotations

import argparse
import configparser
import json
import os
import re
import sys
from dataclasses import dataclass, field
from typing import Any, Iterator

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gdscript_scan import Name, iter_names, iter_scene_names  # noqa: E402

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

TOOL_NAME = "world-static-analysis"

DEFAULT_POLICY = os.path.join("contracts", "engine_feature_policy.v1.json")
DEFAULT_SANCTIONED = os.path.join("contracts", "sanctioned_api.v1.json")

SEVERITY_ERROR = "error"

# Where world modules live. The sanctioned-API rule set applies here and only
# here; everything else is core and is governed by the Engine Feature Policy.
WORLD_ROOT = "worlds"

# Synthetic home for project.godot keys that precede the first section header.
_PREAMBLE_SECTION = "__preamble__"


class GateProblem(Exception):
    """An invocation-level failure: bad target, unreadable or invalid contract."""


@dataclass
class Violation:
    file: str
    line: int
    rule: str
    symbol: str
    severity: str = SEVERITY_ERROR
    message: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "file": self.file,
            "line": self.line,
            "rule": self.rule,
            "symbol": self.symbol,
            "severity": self.severity,
            "message": self.message,
        }


@dataclass
class Report:
    """Exactly one result object per run.

    Text output is a RENDERING of this object, never a separate code path, so a
    message can never appear in one format and not the other.
    """

    target: str
    schema_version: str
    violations: list[Violation] = field(default_factory=list)
    files_scanned: int = 0

    @property
    def errors(self) -> list[Violation]:
        return [v for v in self.violations if v.severity == SEVERITY_ERROR]

    @property
    def passed(self) -> bool:
        return not self.errors

    def to_dict(self) -> dict[str, Any]:
        return {
            "tool": TOOL_NAME,
            "schemaVersion": self.schema_version,
            "target": self.target,
            "passed": self.passed,
            "filesScanned": self.files_scanned,
            "violations": [v.to_dict() for v in self.violations],
        }

    def render_text(self) -> str:
        lines = [
            f"{TOOL_NAME} v{self.schema_version} — target: {self.target}",
            f"scanned {self.files_scanned} file(s)",
        ]
        if not self.violations:
            lines.append("PASS — no violations")
            return "\n".join(lines)
        for v in self.violations:
            lines.append(
                f"  {v.severity.upper()} {v.file}:{v.line} [{v.rule}] "
                f"{v.symbol} — {v.message}"
            )
        verdict = "PASS" if self.passed else "FAIL"
        lines.append(f"{verdict} — {len(self.errors)} error(s), "
                     f"{len(self.violations) - len(self.errors)} warning(s)")
        return "\n".join(lines)

    # A violation exit code is driven by ERRORS alone; a warning is reported
    # but never blocks the merge gate, per the contract's severity rule.
    def exit_code(self) -> int:
        return EXIT_VIOLATIONS if self.errors else EXIT_OK


def _load_json(path: str, label: str) -> dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError as exc:
        raise GateProblem(f"{label} not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise GateProblem(f"{label} is not valid JSON: {path}: {exc}") from exc


def _glob_to_regex(pattern: str) -> re.Pattern[str]:
    """Translates a path glob supporting ** into a regex.

    fnmatch is not usable here: it treats '*' as crossing '/' boundaries, so
    `core/*.gd` would match `core/a/b.gd` and the scope split would be a lie.
    """
    out = ["^"]
    index = 0
    while index < len(pattern):
        if pattern.startswith("**/", index):
            out.append("(?:.*/)?")
            index += 3
        elif pattern.startswith("**", index):
            out.append(".*")
            index += 2
        elif pattern[index] == "*":
            out.append("[^/]*")
            index += 1
        else:
            out.append(re.escape(pattern[index]))
            index += 1
    out.append("$")
    return re.compile("".join(out))


def _matches_any(rel_path: str, patterns: list[str]) -> bool:
    return any(_glob_to_regex(p).match(rel_path) for p in patterns)


def iter_target_files(target: str, policy: dict[str, Any]) -> Iterator[str]:
    """Yields repo-relative paths inside target that the policy says to scan."""
    scope = policy.get("scanScope", {})
    includes: list[str] = list(scope.get("includeGlobs", []))
    excludes: list[str] = list(scope.get("excludeGlobs", []))

    for root, dirnames, filenames in os.walk(target):
        dirnames[:] = sorted(d for d in dirnames if d != ".git")
        for filename in sorted(filenames):
            full = os.path.join(root, filename)
            rel = os.path.relpath(full, target).replace(os.sep, "/")
            if _matches_any(rel, excludes):
                continue
            if includes and not _matches_any(rel, includes):
                continue
            yield rel


def _symbol_hits(name: Name, symbol: str) -> bool:
    """True when this identifier occurrence is the forbidden symbol.

    Dotted symbols (OS.execute) match the whole dotted name or its tail, so
    `OS.execute` is caught however it is reached. Bare symbols match a whole
    SEGMENT, never a substring — that is what stops `multiplayer` from also
    firing on `is_multiplayer_authority`, which has its own rule.
    """
    if "." in symbol:
        return name.text == symbol or name.text.endswith("." + symbol)
    if symbol.startswith("@"):
        return name.is_annotation and name.text == symbol
    return symbol in name.segments()


def _scan_names(
    names: Iterator[Name],
    classes: dict[str, Any],
    rel_path: str,
    rule_prefix: str,
    rationales: dict[str, str],
) -> Iterator[Violation]:
    for name in names:
        for class_name, symbols in classes.items():
            for symbol in symbols:
                if "*" in symbol or " " in symbol:
                    continue  # project-settings entries; handled separately
                if _symbol_hits(name, symbol):
                    yield Violation(
                        file=rel_path,
                        line=name.line,
                        rule=f"{rule_prefix}.{class_name}",
                        symbol=symbol,
                        message=rationales.get(
                            class_name, f"forbidden {class_name} symbol"
                        ),
                    )
                    break


def _flatten_symbol_classes(raw: dict[str, Any]) -> dict[str, list[str]]:
    """Normalizes a forbiddenSymbols / forbiddenCallClasses block to class -> symbols."""
    out: dict[str, list[str]] = {}
    for key, value in raw.items():
        if isinstance(value, list):
            out[key] = [str(v) for v in value]
        elif isinstance(value, dict):
            symbols = value.get("symbols")
            if isinstance(symbols, list):
                out[key] = [str(v) for v in symbols]
            elif isinstance(symbols, dict):
                # Nested by sub-class (the sanctioned multiplayer entry mirrors
                # the policy's own shape); flatten under the parent class.
                flat: list[str] = []
                for nested in symbols.values():
                    if isinstance(nested, list):
                        flat.extend(str(v) for v in nested)
                out[key] = flat
    return out


def _rationales(raw: dict[str, Any]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key, value in raw.items():
        if isinstance(value, dict) and isinstance(value.get("rationale"), str):
            out[key] = value["rationale"]
    return out


def check_project_godot(target: str, policy: dict[str, Any]) -> list[Violation]:
    """REQ-030 AC-5 — no networking or multiplayer settings in project.godot.

    Parsed as INI rather than pattern-matched, so a setting cannot hide behind
    whitespace or ordering.
    """
    settings = policy.get("projectSettingsPolicy", {})
    rel = policy.get("scanScope", {}).get("projectSettingsFile", "project.godot")
    path = os.path.join(target, rel)
    if not os.path.exists(path):
        return []

    parser = configparser.ConfigParser(strict=False)
    parser.optionxform = str  # keys are case-sensitive in project.godot
    try:
        with open(path, "r", encoding="utf-8") as handle:
            text = handle.read()
        # A real project.godot opens with `config_version=5` BEFORE any section
        # header, which configparser refuses outright. A synthetic preamble
        # section gives those keys a home without altering any real section, so
        # they are still inspected rather than skipped.
        parser.read_string(f"[{_PREAMBLE_SECTION}]\n{text}")
    except (OSError, configparser.Error) as exc:
        raise GateProblem(f"could not parse {rel}: {exc}") from exc

    lines = text.splitlines()

    def line_of(needle: str) -> int:
        for index, line in enumerate(lines, start=1):
            if needle in line:
                return index
        return 1

    prefixes = [p.lower() for p in settings.get("forbiddenSectionPrefixes", [])]
    substrings = [s.lower() for s in settings.get("forbiddenKeySubstrings", [])]

    found: list[Violation] = []
    for section in parser.sections():
        if any(section.lower().startswith(p) for p in prefixes):
            found.append(Violation(
                file=rel, line=line_of(f"[{section}]"),
                rule="multiplayer.projectSettings", symbol=f"[{section}]",
                message="project.godot declares a networking section",
            ))
            continue
        for key, value in parser.items(section):
            haystack = f"{key} {value}".lower()
            for needle in substrings:
                if needle in haystack:
                    found.append(Violation(
                        file=rel, line=line_of(key),
                        rule="multiplayer.projectSettings",
                        symbol=f"{section}/{key}",
                        message=(
                            "project.godot declares a multiplayer or peer "
                            f"setting matching '{needle}'"
                        ),
                    ))
                    break
    return found


def run_gate(
    target: str,
    policy_path: str = DEFAULT_POLICY,
    sanctioned_path: str = DEFAULT_SANCTIONED,
    fail_fast: bool = False,
) -> Report:
    if not os.path.isdir(target):
        raise GateProblem(f"target is not a directory: {target}")

    policy = _load_json(policy_path, "engine feature policy")
    sanctioned = _load_json(sanctioned_path, "sanctioned API surface")

    # schemaVersion comes from the file actually loaded, never hardcoded, so a
    # contract bump is visible in every result.
    version = str(policy.get("contractVersion", "unknown"))

    mp_classes = _flatten_symbol_classes(policy.get("forbiddenSymbols", {}))
    world_raw = sanctioned.get("forbiddenCallClasses", {})
    world_classes = _flatten_symbol_classes(world_raw)
    world_rationales = _rationales(world_raw)

    report = Report(target=target, schema_version=version)

    for rel in iter_target_files(target, policy):
        full = os.path.join(target, rel)
        try:
            with open(full, "r", encoding="utf-8") as handle:
                text = handle.read()
        except (OSError, UnicodeDecodeError):
            continue
        report.files_scanned += 1

        is_scene = rel.endswith(".tscn")
        names = list(iter_scene_names(text) if is_scene else iter_names(text))

        report.violations.extend(
            _scan_names(iter(names), mp_classes, rel, "multiplayer", {})
        )

        in_world = rel.split("/", 1)[0] == WORLD_ROOT
        if in_world:
            report.violations.extend(
                _scan_names(
                    iter(names), world_classes, rel, "sanctioned", world_rationales
                )
            )

        if fail_fast and report.errors:
            return report

    report.violations.extend(check_project_godot(target, policy))
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="static_gate",
        description="Reject forbidden engine and world APIs (REQ-020, REQ-030).",
    )
    parser.add_argument("--target", required=True,
                        help="repository root, or a subtree, to scan")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--policy", default=DEFAULT_POLICY)
    parser.add_argument("--sanctioned", default=DEFAULT_SANCTIONED)
    parser.add_argument("--fail-fast", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        report = run_gate(
            args.target, args.policy, args.sanctioned, args.fail_fast
        )
    except GateProblem as exc:
        print(f"{TOOL_NAME}: {exc}", file=sys.stderr)
        return EXIT_INVOCATION

    if args.format == "json":
        print(json.dumps(report.to_dict(), indent=2))
    else:
        print(report.render_text())
    return report.exit_code()


if __name__ == "__main__":
    raise SystemExit(main())
