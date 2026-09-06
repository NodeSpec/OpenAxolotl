#!/usr/bin/env python3
"""Refine a character model through headless Blender, as ONE Validator-shaped
CLI (REQ-032).

    oax-refine --input assets/character/axolotl/axolotl.glb \
               --output assets/character/axolotl/axolotl.glb [--format json]

Blender is the one external tool this project leans on for geometry a game
engine cannot produce for itself — merging loose parts, smooth normals, and
later rigging and animation. It never runs interactively here: this command
builds the documented headless invocation of tools/blender/refine_model.py,
runs it, and checks what comes back against the Asset Contract's triangle
budget for the asset's category, so an agent can refine a model and prove
the result without opening a window.

Blender resolution order: $OAX_BLENDER, then `blender` on PATH. No Blender is
an INVOCATION error (exit 2), never a silent pass — the same rule oax-test
applies to a missing Godot.

Exit codes are the contract with CI and with agents:
    0  refined, and the output passes the header checks
    1  Blender ran but failed, or the output breaches its budget
    2  invocation error — bad arguments, unreadable input, no Blender
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from asset_contract_validator import (  # noqa: E402
    DEFAULT_SCHEMA, HeaderError, glb_header)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_CONTRACT = os.path.join(REPO, DEFAULT_SCHEMA)


def load_contract(path: str) -> dict:
    with open(path, encoding="utf-8") as handle:
        loaded = json.load(handle)
    return loaded if isinstance(loaded, dict) else {}

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

TOOL_NAME = "model-refiner"
REFINER_VERSION = "1.0"

BLENDER_SCRIPT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "blender", "refine_model.py")

# How many trailing lines of Blender's output travel in a failure message.
TAIL_LINES = 25


def find_blender() -> str | None:
    override = os.environ.get("OAX_BLENDER", "")
    if override and os.access(override, os.X_OK):
        return override
    return shutil.which("blender")


def build_argv(blender: str, input_path: str, output_path: str,
               smooth_angle: float) -> list[str]:
    """The documented headless invocation, in one place."""
    # --python-exit-code makes a Python exception inside the script a non-zero
    # exit; without it Blender reports success over a traceback.
    return [
        blender, "--background", "--python-exit-code", "1",
        "--python", BLENDER_SCRIPT, "--",
        "--input", input_path,
        "--output", output_path,
        "--smooth-angle", str(smooth_angle),
    ]


def category_for(path: str) -> str | None:
    """`assets/<category>/<name>/x.glb` -> category, else None."""
    parts = os.path.normpath(os.path.abspath(path)).split(os.sep)
    if "assets" in parts:
        index = parts.index("assets")
        if index + 1 < len(parts) - 1:
            return parts[index + 1]
    return None


def triangle_budget(category: str | None, contract_path: str) -> int | None:
    if category is None:
        return None
    contract = load_contract(contract_path)
    rules = contract.get("categories", {}).get(category, {})
    budget = rules.get("maxTriangles")
    return int(budget) if isinstance(budget, int) else None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="oax-refine",
        description="Refine a character glb through headless Blender.")
    parser.add_argument("--input", required=True, help="source .glb")
    parser.add_argument("--output", required=True,
                        help="destination .glb (may equal --input)")
    parser.add_argument("--smooth-angle", type=float, default=60.0,
                        help="auto-smooth angle in degrees (default 60)")
    parser.add_argument("--contract", default=DEFAULT_CONTRACT,
                        help="asset contract for the triangle budget")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--dry-run", action="store_true",
                        help="print the Blender command line and exit 0")
    args = parser.parse_args(argv)

    if not os.path.isfile(args.input):
        print(f"error: input {args.input!r} is not a file", file=sys.stderr)
        return EXIT_INVOCATION
    if not args.input.lower().endswith(".glb"):
        print("error: input must be a binary glTF (.glb)", file=sys.stderr)
        return EXIT_INVOCATION

    blender = find_blender()
    if blender is None:
        print("error: no Blender binary found -- set $OAX_BLENDER or put "
              "`blender` on PATH (Blender 4.0 or newer)", file=sys.stderr)
        return EXIT_INVOCATION

    command = build_argv(blender, os.path.abspath(args.input),
                         os.path.abspath(args.output), args.smooth_angle)
    if args.dry_run:
        print(" ".join(command))
        return EXIT_OK

    try:
        triangles_before, _, _ = glb_header(args.input)
    except HeaderError as problem:
        print(f"error: input is not a readable glb: {problem}",
              file=sys.stderr)
        return EXIT_INVOCATION

    completed = subprocess.run(command, capture_output=True, text=True)
    output = (completed.stdout or "") + (completed.stderr or "")
    violations: list[dict] = []
    summary: dict = {}
    for line in output.splitlines():
        if line.startswith("REFINE "):
            try:
                summary = json.loads(line[len("REFINE "):])
            except json.JSONDecodeError:
                summary = {}

    if completed.returncode != 0 or not os.path.isfile(args.output):
        tail = "\n".join(output.strip().splitlines()[-TAIL_LINES:])
        violations.append({
            "rule": f"{TOOL_NAME}.blender_failed",
            "severity": "error",
            "file": args.input,
            "message": f"Blender exited {completed.returncode}\n{tail}",
            "remediation": "run the printed command by hand and read "
                           "Blender's own error",
        })
    else:
        try:
            triangles_after, meshes_after, _ = glb_header(args.output)
        except HeaderError as problem:
            violations.append({
                "rule": f"{TOOL_NAME}.output_unreadable",
                "severity": "error",
                "file": args.output,
                "message": str(problem),
                "remediation": "the exporter wrote something that is not a "
                               "glb; check Blender's version",
            })
            triangles_after, meshes_after = 0, 0
        else:
            summary.setdefault("trianglesIn", triangles_before)
            summary["trianglesOut"] = triangles_after
            summary["meshesOut"] = meshes_after
            if triangles_after != triangles_before:
                violations.append({
                    "rule": f"{TOOL_NAME}.geometry_changed",
                    "severity": "error",
                    "file": args.output,
                    "message": f"triangles changed {triangles_before} -> "
                               f"{triangles_after}; refinement must "
                               "preserve geometry",
                    "remediation": "the provenance describes the geometry; "
                                   "a step that changes it needs its own "
                                   "review",
                })
            category = category_for(args.output)
            budget = triangle_budget(category, args.contract)
            if budget is not None and triangles_after > budget:
                violations.append({
                    "rule": f"{TOOL_NAME}.triangle_budget",
                    "severity": "error",
                    "file": args.output,
                    "message": f"{triangles_after} triangles exceed the "
                               f"{category} budget of {budget}",
                    "remediation": "decimate before refining, or move the "
                                   "asset to a category with a larger budget",
                })

    passed = not violations
    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME,
            "schemaVersion": REFINER_VERSION,
            "target": args.input,
            "passed": passed,
            "output": args.output,
            "summary": summary,
            "violations": violations,
        }, indent=2))
    else:
        print(f"{TOOL_NAME} v{REFINER_VERSION} — {args.input} -> {args.output}")
        for key, value in summary.items():
            print(f"  {key}: {value}")
        for v in violations:
            print(f"\n[{v['rule']}]\n{v['message']}")
        print("\n" + ("PASS — refined" if passed
                      else f"FAIL — {len(violations)} problem(s)"))
    return EXIT_OK if passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
