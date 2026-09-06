#!/usr/bin/env python3
"""Validate assets against the Asset Contract (REQ-016).

    python tools/asset_contract_validator.py --target .
    oax-asset-check --target . --format json

The art-side sibling of the Level Contract checker, and the automated half of
the two-stage art gate: structural conformance is machine-checked here so a
human maintainer spends review time on style and art direction only. The same
design law as the sibling: this file knows CONSTRAINT KINDS -- file types,
size bounds, alpha policy, audio format, naming, provenance -- and the
categories with their limits live in contracts/asset_contract.v1.json. Adding
a category, or tightening a bound, is a data edit; only a brand-new kind of
constraint needs code.

The provenance conditional (AI-generated assets must record tool and prompt)
is expressed in contracts/provenance.schema.json as JSON Schema if/then and
EVALUATED here generically -- a deliberately small evaluator for exactly the
subset that schema uses. The rule stays visible in the contract a contributor
reads; nothing about generation methods is hardcoded in this file.

Media files are read by HEADER only -- PNG IHDR + chunk walk, WAV fmt chunk,
OGG id packet, the JSON chunk of a binary glTF -- never decoded, because this
runs over every asset on every pull request that touches art. Standard library only, like every validator in
this repo: a contributor (or an agent self-checking its own art) installs
nothing.

Exit codes are the Validator CLI contract:
    0  conforming
    1  one or more error-severity violations
    2  invocation error -- bad arguments, unreadable target, missing schema
"""

from __future__ import annotations

import argparse
import json
import os
import re
import struct
import sys
from dataclasses import dataclass, field
from typing import Any

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

TOOL_NAME = "asset-contract-validator"

DEFAULT_SCHEMA = os.path.join("contracts", "asset_contract.v1.json")

# Godot writes `<file>.import` beside every imported asset. The suffix is
# gitignored, but it exists in any working tree that has run the engine, so
# the validator must know it is engine bookkeeping and never a source file.
IMPORT_SIDECAR_SUFFIX = ".import"


# --------------------------------------------------------------------------
# Findings -- the shared Validator CLI envelope
# --------------------------------------------------------------------------

@dataclass
class Violation:
    rule: str
    file: str
    message: str
    severity: str = "error"
    remediation: str | None = None

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "rule": self.rule,
            "severity": self.severity,
            "file": self.file,
            "message": self.message,
        }
        if self.remediation is not None:
            payload["remediation"] = self.remediation
        return payload

    def to_text(self) -> str:
        return f"{self.file}: [{self.rule}] {self.message}"


@dataclass
class Report:
    target: str
    schema_version: str
    assets_checked: int = 0
    violations: list[Violation] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not any(v.severity == "error" for v in self.violations)

    def to_json(self) -> str:
        return json.dumps({
            "tool": TOOL_NAME,
            "schemaVersion": self.schema_version,
            "target": self.target,
            "passed": self.passed,
            "assetsChecked": self.assets_checked,
            "violations": [v.to_dict() for v in self.violations],
        }, indent=2)

    def to_text(self) -> str:
        # A rendering of the SAME object json emits, never a second code path.
        lines = [
            f"{TOOL_NAME} v{self.schema_version} — target: {self.target}",
            f"checked {self.assets_checked} asset(s)",
        ]
        if not self.violations:
            lines.append("PASS — no violations")
            return "\n".join(lines)
        for violation in self.violations:
            lines.append(f"  {violation.severity.upper()} {violation.to_text()}")
        verdict = "PASS" if self.passed else "FAIL"
        lines.append(f"{verdict} — {len(self.violations)} violation(s)")
        return "\n".join(lines)


# --------------------------------------------------------------------------
# Media headers, and only the headers
# --------------------------------------------------------------------------

class HeaderError(Exception):
    """The file does not carry a readable header of its claimed type."""


def png_header(path: str) -> tuple[int, int, bool]:
    """(width, height, has_alpha) from the IHDR and a bounded chunk walk.

    Alpha is color type 4 or 6, or an indexed image carrying a tRNS chunk.
    The walk stops at the first IDAT: everything that describes an image
    precedes its pixel data by specification.
    """
    with open(path, "rb") as handle:
        data = handle.read(64 * 1024)
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise HeaderError("not a PNG file (bad signature)")
    width, height = struct.unpack_from(">II", data, 16)
    color_type = data[25]
    has_alpha = color_type in (4, 6)

    cursor = 8
    while not has_alpha and cursor + 8 <= len(data):
        (length,) = struct.unpack_from(">I", data, cursor)
        kind = data[cursor + 4:cursor + 8]
        if kind == b"tRNS" and color_type == 3:
            has_alpha = True
        if kind in (b"IDAT", b"IEND"):
            break
        cursor += 8 + length + 4
    return width, height, has_alpha


def wav_header(path: str) -> tuple[int, int]:
    """(channels, sample_rate) from the fmt chunk."""
    with open(path, "rb") as handle:
        data = handle.read(4 * 1024)
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise HeaderError("not a WAV file (bad RIFF header)")
    cursor = 12
    while cursor + 8 <= len(data):
        kind = data[cursor:cursor + 4]
        (length,) = struct.unpack_from("<I", data, cursor + 4)
        if kind == b"fmt ":
            channels, rate = struct.unpack_from("<HI", data, cursor + 10)
            return channels, rate
        cursor += 8 + length + (length % 2)
    raise HeaderError("WAV file has no fmt chunk")


def ogg_header(path: str) -> tuple[int, int]:
    """(channels, sample_rate) from the first packet's Vorbis or Opus id."""
    with open(path, "rb") as handle:
        data = handle.read(4 * 1024)
    if data[:4] != b"OggS":
        raise HeaderError("not an OGG file (bad capture pattern)")
    segments = data[26]
    body = 27 + segments
    packet = data[body:]
    if packet.startswith(b"\x01vorbis"):
        channels = packet[11]
        (rate,) = struct.unpack_from("<I", packet, 12)
        return channels, rate
    if packet.startswith(b"OpusHead"):
        channels = packet[9]
        (rate,) = struct.unpack_from("<I", packet, 12)
        return channels, rate
    raise HeaderError("OGG file carries neither a Vorbis nor an Opus id header")


GLB_MAGIC = 0x46546C67       # "glTF"
GLB_JSON_CHUNK = 0x4E4F534A  # "JSON"
GLTF_TRIANGLES = 4
GLTF_TRIANGLE_STRIP = 5
GLTF_TRIANGLE_FAN = 6


def glb_header(path: str) -> tuple[int, int, list[str]]:
    """(triangles, mesh_count, animation_names) from a binary glTF 2.0.

    Only the leading JSON chunk is read -- it IS the model's header, and it
    precedes the binary payload by specification. The triangle count comes
    from the index accessors' declared counts (vertex counts for unindexed
    primitives), numbers the header already carries: no geometry is decoded.
    """
    with open(path, "rb") as handle:
        head = handle.read(20)
        if len(head) < 20 or struct.unpack_from("<I", head, 0)[0] != GLB_MAGIC:
            raise HeaderError("not a GLB file (bad magic)")
        version = struct.unpack_from("<I", head, 4)[0]
        if version != 2:
            raise HeaderError(f"GLB container version {version}; "
                              f"only glTF 2.0 is supported")
        chunk_length, chunk_type = struct.unpack_from("<II", head, 12)
        if chunk_type != GLB_JSON_CHUNK:
            raise HeaderError("GLB does not start with a JSON chunk")
        body = handle.read(chunk_length)
    try:
        document = json.loads(body)
    except (json.JSONDecodeError, UnicodeDecodeError) as problem:
        raise HeaderError(f"GLB JSON chunk is not valid JSON: {problem}")
    if not isinstance(document, dict):
        raise HeaderError("GLB JSON chunk is not an object")

    accessors = document.get("accessors", [])
    triangles = 0
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            mode = primitive.get("mode", GLTF_TRIANGLES)
            if "indices" in primitive:
                count = accessors[primitive["indices"]].get("count", 0)
            else:
                position = primitive.get("attributes", {}).get("POSITION")
                count = 0 if position is None \
                    else accessors[position].get("count", 0)
            if mode == GLTF_TRIANGLES:
                triangles += count // 3
            elif mode in (GLTF_TRIANGLE_STRIP, GLTF_TRIANGLE_FAN):
                triangles += max(count - 2, 0)
    animations = [str(clip.get("name", f"animation_{index}"))
                  for index, clip in enumerate(document.get("animations", []))]
    return triangles, len(document.get("meshes", [])), animations


# --------------------------------------------------------------------------
# A JSON Schema evaluator, exactly as large as the provenance schema needs
# --------------------------------------------------------------------------

def evaluate_schema(schema: dict, value: Any, where: str = "") -> list[str]:
    """Errors from evaluating [value] against the JSON Schema subset the
    provenance schema uses: type, required, properties, enum, const,
    minLength, if/then/else, additionalProperties. Generic on purpose -- the
    conditional rule lives in the schema file, and this function has never
    heard of a generation method.
    """
    errors: list[str] = []
    prefix = f"{where}: " if where else ""

    expected = schema.get("type")
    if expected == "object" and not isinstance(value, dict):
        return [f"{prefix}must be an object"]
    if expected == "string" and not isinstance(value, str):
        return [f"{prefix}must be a string"]

    if "const" in schema and value != schema["const"]:
        errors.append(f"{prefix}must be {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(
            f"{prefix}must be one of {', '.join(map(repr, schema['enum']))}")
    if "minLength" in schema and isinstance(value, str) \
            and len(value) < schema["minLength"]:
        errors.append(f"{prefix}must not be empty")

    if isinstance(value, dict):
        for name in schema.get("required", []):
            if name not in value:
                errors.append(f"required field '{name}' is missing")
        properties = schema.get("properties", {})
        for name, sub_schema in properties.items():
            if name in value:
                errors.extend(evaluate_schema(sub_schema, value[name], name))
        if schema.get("additionalProperties") is False:
            for name in value:
                if name not in properties:
                    errors.append(f"unknown field '{name}'")
        if "if" in schema:
            if not evaluate_schema(schema["if"], value, where):
                branch = schema.get("then")
            else:
                branch = schema.get("else")
            if branch is not None:
                errors.extend(evaluate_schema(branch, value, where))

    return errors


# --------------------------------------------------------------------------
# The validator
# --------------------------------------------------------------------------

class AssetValidator:
    def __init__(self, contract: dict, provenance_schema: dict) -> None:
        self.contract = contract
        self.provenance_schema = provenance_schema
        self.categories: dict = contract.get("categories", {})
        self.name_pattern = re.compile(
            contract.get("layout", {}).get("namePattern", "^.+$"))
        self.provenance_file = contract.get("provenance", {}) \
            .get("file", "provenance.json")

    # -- one asset directory ---------------------------------------------

    def check_asset(self, category: str, asset_dir: str,
                    rel: str) -> list[Violation]:
        violations: list[Violation] = []
        rules: dict = self.categories[category]
        name = os.path.basename(os.path.normpath(asset_dir))

        if self.name_pattern.fullmatch(name) is None:
            violations.append(Violation(
                rule="layout.name_convention", file=rel,
                message=f"asset directory '{name}' does not match "
                        f"{self.name_pattern.pattern}",
                remediation="rename to lower_snake_case starting with a letter"))

        entries = sorted(os.listdir(asset_dir))
        sources = [e for e in entries
                   if e != self.provenance_file
                   and not e.endswith(IMPORT_SIDECAR_SUFFIX)
                   and os.path.isfile(os.path.join(asset_dir, e))]

        if not sources:
            violations.append(Violation(
                rule="layout.empty_asset", file=rel,
                message="the asset directory holds no source files"))

        for entry in sources:
            violations.extend(self._check_source(
                category, rules, os.path.join(asset_dir, entry),
                os.path.join(rel, entry)))

        violations.extend(self._check_provenance(asset_dir, rel))
        return violations

    def _check_source(self, category: str, rules: dict, path: str,
                      rel: str) -> list[Violation]:
        stem, extension = os.path.splitext(os.path.basename(path))
        extension = extension.lower()

        if self.name_pattern.fullmatch(stem) is None:
            return [Violation(
                rule="layout.name_convention", file=rel,
                message=f"file stem '{stem}' does not match "
                        f"{self.name_pattern.pattern}")]

        allowed = rules.get("fileTypes", [])
        if extension not in allowed:
            return [Violation(
                rule=f"{category}.file_type", file=rel,
                message=f"'{extension}' is not a permitted file type for "
                        f"{category} assets ({', '.join(allowed)})")]

        if extension == ".png":
            return self._check_image(category, rules, path, rel)
        if extension in (".wav", ".ogg"):
            return self._check_audio(category, rules, path, rel, extension)
        if extension == ".glb":
            return self._check_model(category, rules, path, rel)
        return []

    def _check_model(self, category: str, rules: dict, path: str,
                     rel: str) -> list[Violation]:
        try:
            triangles, meshes, _animations = glb_header(path)
        except (HeaderError, IndexError, KeyError, TypeError,
                struct.error) as problem:
            return [Violation(
                rule=f"{category}.model_format", file=rel,
                message=f"unreadable GLB header: {problem}")]

        violations: list[Violation] = []
        if meshes == 0:
            violations.append(Violation(
                rule=f"{category}.model_format", file=rel,
                message="the GLB declares no meshes"))
        budget = rules.get("maxTriangles")
        if budget is not None and triangles > budget:
            violations.append(Violation(
                rule=f"{category}.triangle_budget", file=rel,
                message=f"{triangles} triangles exceeds the {category} "
                        f"budget of {budget}",
                remediation="decimate the mesh, or split it into several "
                            "assets"))
        return violations

    def _check_image(self, category: str, rules: dict, path: str,
                     rel: str) -> list[Violation]:
        try:
            width, height, has_alpha = png_header(path)
        except (HeaderError, IndexError, struct.error) as problem:
            return [Violation(
                rule=f"{category}.image_format", file=rel,
                message=f"unreadable image header: {problem}")]

        violations: list[Violation] = []
        minimum = rules.get("minSize")
        maximum = rules.get("maxSize")
        if minimum and (width < minimum[0] or height < minimum[1]):
            violations.append(Violation(
                rule=f"{category}.resolution", file=rel,
                message=f"{width}x{height} is below the minimum "
                        f"{minimum[0]}x{minimum[1]} for {category} assets"))
        if maximum and (width > maximum[0] or height > maximum[1]):
            violations.append(Violation(
                rule=f"{category}.resolution", file=rel,
                message=f"{width}x{height} exceeds the maximum "
                        f"{maximum[0]}x{maximum[1]} for {category} assets"))

        alpha_policy = rules.get("alpha", "allowed")
        if alpha_policy == "required" and not has_alpha:
            violations.append(Violation(
                rule=f"{category}.alpha_channel", file=rel,
                message=f"{category} assets require an alpha channel and "
                        f"this image has none",
                remediation="re-export as RGBA"))
        if alpha_policy == "forbidden" and has_alpha:
            violations.append(Violation(
                rule=f"{category}.alpha_channel", file=rel,
                message=f"{category} assets must not carry an alpha channel"))
        return violations

    def _check_audio(self, category: str, rules: dict, path: str,
                     rel: str, extension: str) -> list[Violation]:
        try:
            reader = wav_header if extension == ".wav" else ogg_header
            channels, rate = reader(path)
        except (HeaderError, IndexError, struct.error) as problem:
            return [Violation(
                rule=f"{category}.audio_format", file=rel,
                message=f"unreadable audio header: {problem}")]

        violations: list[Violation] = []
        max_channels = rules.get("maxChannels")
        if max_channels is not None and channels > max_channels:
            violations.append(Violation(
                rule=f"{category}.audio_format", file=rel,
                message=f"{channels} channels exceeds the maximum of "
                        f"{max_channels}"))
        rates = rules.get("sampleRates")
        if rates and rate not in rates:
            violations.append(Violation(
                rule=f"{category}.audio_format", file=rel,
                message=f"sample rate {rate} is not one of "
                        f"{', '.join(map(str, rates))}"))
        return violations

    def _check_provenance(self, asset_dir: str, rel: str) -> list[Violation]:
        # Missing and malformed are DISTINCT rule ids because the remediation
        # differs: one asks for a file, the other for a fix inside it.
        path = os.path.join(asset_dir, self.provenance_file)
        rel_file = os.path.join(rel, self.provenance_file)
        if not os.path.isfile(path):
            return [Violation(
                rule="provenance.missing", file=rel_file,
                message="every asset requires a provenance.json recording "
                        "author, generation method and license terms",
                remediation="add provenance.json conforming to "
                            "contracts/provenance.schema.json")]
        try:
            with open(path, "r", encoding="utf-8") as handle:
                parsed = json.load(handle)
        except (json.JSONDecodeError, UnicodeDecodeError) as problem:
            return [Violation(
                rule="provenance.invalid", file=rel_file,
                message=f"provenance.json is not valid JSON: {problem}")]

        errors = evaluate_schema(self.provenance_schema, parsed)
        return [Violation(rule="provenance.invalid", file=rel_file,
                          message=error) for error in errors]

    # -- the tree --------------------------------------------------------

    def check_assets_root(self, assets_root: str,
                          rel_root: str) -> tuple[int, list[Violation]]:
        checked = 0
        violations: list[Violation] = []

        for entry in sorted(os.listdir(assets_root)):
            entry_path = os.path.join(assets_root, entry)
            entry_rel = os.path.join(rel_root, entry)
            if os.path.isfile(entry_path):
                violations.append(Violation(
                    rule="layout.stray_file", file=entry_rel,
                    message="files may not sit directly in the assets root; "
                            "the layout is assets/<category>/<name>/"))
                continue
            if entry not in self.categories:
                violations.append(Violation(
                    rule="layout.unknown_category", file=entry_rel,
                    message=f"'{entry}' is not a contract category "
                            f"({', '.join(sorted(self.categories))})"))
                continue
            for name in sorted(os.listdir(entry_path)):
                asset_path = os.path.join(entry_path, name)
                asset_rel = os.path.join(entry_rel, name)
                if os.path.isfile(asset_path):
                    violations.append(Violation(
                        rule="layout.stray_file", file=asset_rel,
                        message="files may not sit directly in a category "
                                "directory; each asset gets its own folder"))
                    continue
                checked += 1
                violations.extend(self.check_asset(entry, asset_path, asset_rel))

        return checked, violations


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def load_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="oax-asset-check",
        description="Validate assets against the Asset Contract.")
    parser.add_argument("--target", default=".",
                        help="a repository root, an assets directory, or a "
                             "single asset directory (default: .)")
    parser.add_argument("--schema", default=DEFAULT_SCHEMA,
                        help=f"asset contract (default: {DEFAULT_SCHEMA})")
    parser.add_argument("--format", choices=("text", "json"), default="text",
                        help="text for humans, json for CI and agents")
    parser.add_argument("--fail-fast", action="store_true",
                        help="stop at the first error-severity violation")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not os.path.isdir(args.target):
        print(f"error: target {args.target!r} is not a directory",
              file=sys.stderr)
        return EXIT_INVOCATION
    if not os.path.isfile(args.schema):
        print(f"error: schema {args.schema!r} not found", file=sys.stderr)
        return EXIT_INVOCATION

    try:
        contract = load_json(args.schema)
        schema_dir = os.path.dirname(os.path.abspath(args.schema)) or "."
        repo_of_schema = os.path.dirname(schema_dir) or "."
        provenance_ref = contract.get("provenance", {}).get(
            "schema", "contracts/provenance.schema.json")
        provenance_schema = load_json(os.path.join(repo_of_schema,
                                                   provenance_ref))
    except (json.JSONDecodeError, OSError) as problem:
        print(f"error: cannot load contract: {problem}", file=sys.stderr)
        return EXIT_INVOCATION

    validator = AssetValidator(contract, provenance_schema)
    assets_root_name = contract.get("assetsRoot", "assets")

    target = os.path.normpath(args.target)
    parent_of_target = os.path.basename(os.path.dirname(os.path.abspath(target)))

    report = Report(target=args.target,
                    schema_version=str(contract.get("contractVersion", "?")))

    if os.path.basename(target) == assets_root_name:
        # The assets tree itself.
        report.assets_checked, report.violations = \
            validator.check_assets_root(target, assets_root_name)
    elif parent_of_target in validator.categories:
        # One asset directory: assets/<category>/<name>.
        report.assets_checked = 1
        report.violations = validator.check_asset(
            parent_of_target, target,
            os.path.join(assets_root_name, parent_of_target,
                         os.path.basename(target)))
    else:
        # A repository root. No assets directory conforms vacuously -- a fork
        # stripped of official art is not in violation of an art contract.
        assets_root = os.path.join(target, assets_root_name)
        if os.path.isdir(assets_root):
            report.assets_checked, report.violations = \
                validator.check_assets_root(assets_root, assets_root_name)

    if args.fail_fast:
        for index, violation in enumerate(report.violations):
            if violation.severity == "error":
                report.violations = report.violations[:index + 1]
                break

    print(report.to_json() if args.format == "json" else report.to_text())
    return EXIT_OK if report.passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
