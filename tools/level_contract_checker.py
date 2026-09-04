#!/usr/bin/env python3
"""Validate a world module against the Level Contract (REQ-007).

    python tools/level_contract_checker.py --target worlds/coral_cove
    python tools/level_contract_checker.py --target worlds/coral_cove --format json

THE CENTRAL RULE OF THIS FILE: it knows about RULE KINDS, never about elements.
Nothing here mentions a spawn point, a checkpoint or a finish condition. Those
live in contracts/level_contract.v1.json, and adding a rule of an existing kind
changes what this tool enforces with no edit here (REQ-007 AC-8). A new KIND is
the one case that needs code, which is why the kinds are few and general.

That constraint is enforced rather than hoped for: the test suite greps this
file for element names and fails if one appears.

Standard library only, deliberately. A contributor checking their own world
before submitting should not need to install anything, and neither should an AI
coding agent running this as a self-check.

Exit codes are the contract with CI (AC-5):
    0  conforming
    1  one or more violations
    2  invocation error -- bad arguments, unreadable target, missing schema
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, asdict, field
from typing import Any

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

DEFAULT_SCHEMA = os.path.join("contracts", "level_contract.v1.json")


# --------------------------------------------------------------------------
# Findings
# --------------------------------------------------------------------------

@dataclass
class Violation:
    """One conformance failure.

    Shaped for AC-4: the specific element, where it went wrong, and the rule
    that was broken -- as data an agent can parse and act on, not prose it has
    to interpret. `rule` is the kind, so a consumer can group by class of
    failure without string-matching messages.
    """

    element: str
    rule: str
    file: str
    line: int | None
    message: str

    def to_text(self) -> str:
        where = self.file if self.line is None else f"{self.file}:{self.line}"
        return f"{where}: [{self.element}/{self.rule}] {self.message}"


@dataclass
class Report:
    target: str
    schema: str
    contract_version: str
    conforming: bool
    violations: list[Violation] = field(default_factory=list)

    def to_json(self) -> str:
        payload = asdict(self)
        payload["violations"] = [asdict(v) for v in self.violations]
        return json.dumps(payload, indent=2)

    def to_text(self) -> str:
        if self.conforming:
            return f"PASS  {self.target} conforms to Level Contract v{self.contract_version}"
        lines = [
            f"FAIL  {self.target} -- {len(self.violations)} violation(s) "
            f"against Level Contract v{self.contract_version}",
            "",
        ]
        lines.extend(f"  {v.to_text()}" for v in self.violations)
        return "\n".join(lines)


# --------------------------------------------------------------------------
# The scene, just enough of it
# --------------------------------------------------------------------------

_NODE_LINE = re.compile(r"^\[node\s+(?P<attrs>.*)\]\s*$")
_GROUPS = re.compile(r'groups\s*=\s*\[(?P<body>[^\]]*)\]')
_QUOTED = re.compile(r'"([^"]*)"')


def scan_scene_groups(scene_path: str) -> dict[str, list[int]]:
    """Group name -> line numbers of the nodes belonging to it.

    A deliberately small reader rather than a .tscn parser. The contract only
    ever asks how many nodes are in a group, and group membership is the ONLY
    tag the contract recognises -- never a node name, never a type. That is what
    lets a contributor rename or re-type a node without silently breaking
    conformance, and it keeps this function to a dozen lines instead of being a
    second implementation of Godot's scene format.
    """
    found: dict[str, list[int]] = {}
    if not os.path.isfile(scene_path):
        return found

    with open(scene_path, "r", encoding="utf-8") as handle:
        for number, line in enumerate(handle, start=1):
            match = _NODE_LINE.match(line.strip())
            if match is None:
                continue
            groups = _GROUPS.search(match.group("attrs"))
            if groups is None:
                continue
            for name in _QUOTED.findall(groups.group("body")):
                found.setdefault(name, []).append(number)
    return found


# --------------------------------------------------------------------------
# Manifest field access
# --------------------------------------------------------------------------

_MISSING = object()


def read_path(data: Any, dotted: str) -> Any:
    """Resolve a dotted field path, or _MISSING.

    Distinguishes absent from null on purpose: the contract treats declaring
    nothing and omitting the declaration as different states, so a rule that
    checks presence must be able to tell them apart.
    """
    current = data
    for part in dotted.split("."):
        if not isinstance(current, dict) or part not in current:
            return _MISSING
        current = current[part]
    return current


def json_type_name(value: Any) -> str:
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int) or isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    if value is None:
        return "null"
    return "unknown"


def manifest_line(manifest_text: str, dotted: str) -> int | None:
    """Best-effort line of a field, for AC-4's file location.

    Matches the LAST path segment as a JSON key. Approximate by design: a
    precise answer needs a position-preserving parser, and the value here is
    pointing a contributor at roughly the right line, not at a column.
    """
    leaf = dotted.split(".")[-1]
    pattern = re.compile(r'^\s*"' + re.escape(leaf) + r'"\s*:')
    for number, line in enumerate(manifest_text.splitlines(), start=1):
        if pattern.match(line):
            return number
    return None


# --------------------------------------------------------------------------
# The rule engine
# --------------------------------------------------------------------------

class RuleEngine:
    """Executes contract rules. Knows kinds; knows no element names."""

    def __init__(self, target: str, schema_path: str, manifest: dict,
                 manifest_name: str, manifest_text: str,
                 scene_groups: dict[str, list[int]], scene_name: str) -> None:
        self.target = target
        self.schema_dir = os.path.dirname(os.path.abspath(schema_path)) or "."
        self.repo_root = os.path.dirname(self.schema_dir) or "."
        self.manifest = manifest
        self.manifest_name = manifest_name
        self.manifest_text = manifest_text
        self.scene_groups = scene_groups
        self.scene_name = scene_name

    # -- helpers ---------------------------------------------------------

    def _manifest_violation(self, element: str, kind: str, dotted: str,
                            message: str) -> Violation:
        return Violation(element=element, rule=kind, file=self.manifest_name,
                         line=manifest_line(self.manifest_text, dotted),
                         message=message)

    def supported_kinds(self) -> set[str]:
        return {name[6:] for name in dir(self) if name.startswith("_rule_")}

    def run(self, element: str, rule: dict) -> list[Violation]:
        kind = rule.get("kind", "")
        handler = getattr(self, f"_rule_{kind}", None)
        if handler is None:
            # An unknown kind is an INVOCATION problem, not a world's fault:
            # the schema is asking for a check this build cannot perform, and
            # silently passing would be the worst of the three options.
            raise UnknownRuleKind(kind, element)
        return handler(element, rule)

    # -- manifest kinds --------------------------------------------------

    def _rule_manifest_field_present(self, element: str, rule: dict) -> list[Violation]:
        dotted = rule["field"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING or value is None:
            return [self._manifest_violation(
                element, "manifest_field_present", dotted,
                f"required field '{dotted}' is missing")]
        return []

    def _rule_manifest_field_type(self, element: str, rule: dict) -> list[Violation]:
        dotted, expected = rule["field"], rule["type"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING:
            return []  # presence is a separate rule; don't report it twice
        actual = json_type_name(value)
        if actual != expected:
            return [self._manifest_violation(
                element, "manifest_field_type", dotted,
                f"'{dotted}' should be {expected}, found {actual}")]
        return []

    def _rule_manifest_field_matches(self, element: str, rule: dict) -> list[Violation]:
        dotted, pattern = rule["field"], rule["pattern"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING:
            return []
        if not isinstance(value, str) or re.fullmatch(pattern, value) is None:
            return [self._manifest_violation(
                element, "manifest_field_matches", dotted,
                f"'{dotted}' is {value!r}, which does not match {pattern}")]
        return []

    def _rule_manifest_field_in_set(self, element: str, rule: dict) -> list[Violation]:
        dotted, allowed = rule["field"], rule["values"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING:
            return []
        if value not in allowed:
            return [self._manifest_violation(
                element, "manifest_field_in_set", dotted,
                f"'{dotted}' is {value!r}; permitted values are "
                f"{', '.join(repr(a) for a in allowed)}")]
        return []

    def _rule_manifest_array_min_length(self, element: str, rule: dict) -> list[Violation]:
        dotted, minimum = rule["field"], rule["min"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING or not isinstance(value, list):
            return []
        if len(value) < minimum:
            return [self._manifest_violation(
                element, "manifest_array_min_length", dotted,
                f"'{dotted}' holds {len(value)} entries, at least {minimum} required")]
        return []

    def _rule_manifest_keys_subset_of(self, element: str, rule: dict) -> list[Violation]:
        dotted, reference = rule["field"], rule["allowedFrom"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING or not isinstance(value, dict):
            return []

        allowed = self._resolve_reference(reference)
        offenders = [key for key in value if key not in allowed]
        if offenders:
            return [self._manifest_violation(
                element, "manifest_keys_subset_of", dotted,
                f"'{dotted}' names {', '.join(sorted(offenders))}, which "
                f"{reference} does not permit")]
        return []

    def _rule_manifest_field_equals_directory_name(self, element: str,
                                                   rule: dict) -> list[Violation]:
        dotted = rule["field"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING:
            return []
        expected = os.path.basename(os.path.normpath(self.target))
        if value != expected:
            return [self._manifest_violation(
                element, "manifest_field_equals_directory_name", dotted,
                f"'{dotted}' is {value!r} but the module directory is "
                f"{expected!r}; they must match or the save namespace and the "
                f"folder disagree")]
        return []

    def _rule_manifest_array_items_prefixed_by(self, element: str,
                                               rule: dict) -> list[Violation]:
        dotted, prefix_field = rule["field"], rule["prefixFrom"]
        value = read_path(self.manifest, dotted)
        if value is _MISSING or not isinstance(value, list):
            return []

        prefix_value = read_path(self.manifest, prefix_field)
        if prefix_value is _MISSING or not isinstance(prefix_value, str):
            return []

        prefix = f"{prefix_value}."
        offenders = [item for item in value
                     if not (isinstance(item, str) and item.startswith(prefix))]
        if offenders:
            return [self._manifest_violation(
                element, "manifest_array_items_prefixed_by", dotted,
                f"{', '.join(repr(o) for o in offenders)} in '{dotted}' must "
                f"begin with {prefix!r} so two worlds cannot collide")]
        return []

    # -- scene kinds -----------------------------------------------------

    def _rule_scene_group_count(self, element: str, rule: dict) -> list[Violation]:
        group = rule["group"]
        minimum = rule.get("min", 0)
        maximum = rule.get("max")

        lines = self.scene_groups.get(group, [])
        count = len(lines)

        if count < minimum:
            return [Violation(
                element=element, rule="scene_group_count",
                file=self.scene_name, line=None,
                message=(f"found {count} node(s) in group '{group}', at least "
                         f"{minimum} required"))]
        if maximum is not None and count > maximum:
            return [Violation(
                element=element, rule="scene_group_count",
                file=self.scene_name, line=lines[maximum] if len(lines) > maximum else None,
                message=(f"found {count} node(s) in group '{group}', at most "
                         f"{maximum} permitted"))]
        return []

    # -- file kinds ------------------------------------------------------

    def _rule_file_present(self, element: str, rule: dict) -> list[Violation]:
        relative = rule["path"]
        if not os.path.isfile(os.path.join(self.target, relative)):
            return [Violation(element=element, rule="file_present",
                              file=relative, line=None,
                              message=f"required file '{relative}' is missing")]
        return []

    def _rule_file_absent(self, element: str, rule: dict) -> list[Violation]:
        relative = rule["path"]
        if os.path.exists(os.path.join(self.target, relative)):
            return [Violation(element=element, rule="file_absent",
                              file=relative, line=None,
                              message=(f"'{relative}' must not appear in a world "
                                       f"module; it would override project-wide policy"))]
        return []

    # -- references ------------------------------------------------------

    def _resolve_reference(self, reference: str) -> list:
        """Resolve `relative/path.json#key` into the list it names.

        Referencing rather than copying is what stops the contract and the
        thing it cites from drifting apart -- the sanctioned tuning overrides
        live in the tuning surface, and this reads them from there.
        """
        if "#" not in reference:
            raise SchemaProblem(f"reference {reference!r} has no '#key' part")
        path, key = reference.split("#", 1)
        absolute = os.path.join(self.repo_root, path)
        if not os.path.isfile(absolute):
            raise SchemaProblem(
                f"reference {reference!r} points at {absolute}, which does not exist")
        with open(absolute, "r", encoding="utf-8") as handle:
            document = json.load(handle)
        value = read_path(document, key)
        if value is _MISSING or not isinstance(value, list):
            raise SchemaProblem(
                f"reference {reference!r} does not resolve to a list")
        return value


class UnknownRuleKind(Exception):
    def __init__(self, kind: str, element: str) -> None:
        super().__init__(
            f"the contract asks for rule kind '{kind}' (on '{element}'), which "
            f"this build of the checker does not implement. Adding a rule of an "
            f"existing kind needs no code change; a new KIND does.")
        self.kind = kind


class SchemaProblem(Exception):
    pass


# --------------------------------------------------------------------------
# Driving the schema
# --------------------------------------------------------------------------

def collect_rules(schema: dict) -> list[tuple[str, dict]]:
    """(element, rule) for every rule the contract declares, in a stable order.

    Walks the schema generically. A new element with rules is picked up here
    with no edit, which is half of what AC-8 asks for; the other half is that
    the engine above dispatches on kind rather than on element.
    """
    pairs: list[tuple[str, dict]] = []

    layout = schema.get("moduleLayout", {})
    for rule in layout.get("rules", []):
        pairs.append(("moduleLayout", rule))

    for section in ("required", "optional"):
        for element, body in sorted(schema.get(section, {}).items()):
            if not isinstance(body, dict):
                continue
            for rule in body.get("rules", []):
                pairs.append((element, rule))

    return pairs


def check_world(target: str, schema_path: str) -> Report:
    with open(schema_path, "r", encoding="utf-8") as handle:
        schema = json.load(handle)

    layout = schema.get("moduleLayout", {})
    files = layout.get("files", {})
    manifest_name = files.get("manifest", {}).get("name", "world.json")
    scene_name = files.get("scene", {}).get("name", "world.tscn")

    report = Report(target=target, schema=schema_path,
                    contract_version=str(schema.get("contractVersion", "?")),
                    conforming=True)

    manifest: dict = {}
    manifest_text = ""
    manifest_path = os.path.join(target, manifest_name)
    if os.path.isfile(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as handle:
            manifest_text = handle.read()
        try:
            parsed = json.loads(manifest_text)
            manifest = parsed if isinstance(parsed, dict) else {}
            if not isinstance(parsed, dict):
                report.violations.append(Violation(
                    element="moduleLayout", rule="manifest_parse",
                    file=manifest_name, line=1,
                    message="the manifest must be a JSON object"))
        except json.JSONDecodeError as error:
            report.violations.append(Violation(
                element="moduleLayout", rule="manifest_parse",
                file=manifest_name, line=error.lineno,
                message=f"the manifest is not valid JSON: {error.msg}"))

    engine = RuleEngine(
        target=target, schema_path=schema_path, manifest=manifest,
        manifest_name=manifest_name, manifest_text=manifest_text,
        scene_groups=scan_scene_groups(os.path.join(target, scene_name)),
        scene_name=scene_name)

    for element, rule in collect_rules(schema):
        report.violations.extend(engine.run(element, rule))

    report.conforming = not report.violations
    return report


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="level_contract_checker",
        description="Validate a world module against the Level Contract.")
    parser.add_argument("--target", required=True,
                        help="path to the world module directory")
    parser.add_argument("--schema", default=DEFAULT_SCHEMA,
                        help=f"contract schema (default: {DEFAULT_SCHEMA})")
    parser.add_argument("--format", choices=("text", "json"), default="text",
                        help="text for humans, json for CI and agents")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not os.path.isdir(args.target):
        print(f"error: target {args.target!r} is not a directory", file=sys.stderr)
        return EXIT_INVOCATION
    if not os.path.isfile(args.schema):
        print(f"error: schema {args.schema!r} not found", file=sys.stderr)
        return EXIT_INVOCATION

    try:
        report = check_world(args.target, args.schema)
    except (UnknownRuleKind, SchemaProblem) as problem:
        print(f"error: {problem}", file=sys.stderr)
        return EXIT_INVOCATION
    except json.JSONDecodeError as problem:
        print(f"error: schema is not valid JSON: {problem}", file=sys.stderr)
        return EXIT_INVOCATION

    print(report.to_json() if args.format == "json" else report.to_text())
    return EXIT_OK if report.conforming else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
