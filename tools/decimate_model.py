#!/usr/bin/env python3
"""Bring an over-dense model inside its Asset Contract budget, and PROVE the
shape survived — one Validator-shaped CLI (REQ-032, REQ-015).

    oax-decimate --input reference/hero/pink_axolotl_2.glb \
                 --output assets/character/axolotl/axolotl.glb [--format json]

WHY THIS IS A TOOL AND NOT A ONE-OFF. The asset pipeline now begins outside
this repository: a concept image goes to Meshy, and what comes back is a dense
uniform remesh with its detail baked into 4K maps. The hero arrived at
1,933,518 triangles — thirty-two times the character budget — and every
environment kit that follows it will arrive the same way. Reducing a model by
hand once is a chore; reducing every model the same way, with the same
evidence attached each time, is a pipeline stage.

WHAT IT REFUSES TO DO SILENTLY. Decimation is the step where an asset gets
quietly ruined: the triangle count goes green, the file gets smaller, and a
gill filament or a toe is gone. So the budget is not the only gate. The
Blender side samples the surface in BOTH directions and reports how far the
new shape strays from the old one, and this command fails when that number
exceeds --max-deviation. A model can pass its triangle budget and still fail
here, which is the entire point.

The budget itself comes from the Asset Contract, resolved from the OUTPUT
path's category, so the number is never restated in an agent's command line
and cannot drift from the contract.

Blender resolution order: $OAX_BLENDER, then `blender` on PATH. No Blender is
an INVOCATION error (exit 2), never a silent pass — the same rule oax-test
applies to a missing Godot.

Exit codes are the contract with CI and with agents:
    0  decimated, inside budget, and the shape held
    1  Blender ran but failed, the output breaches its budget, or the shape
       moved further than allowed
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
from refine_model import (  # noqa: E402
    category_for, find_blender, triangle_budget)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_CONTRACT = os.path.join(REPO, DEFAULT_SCHEMA)

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

TOOL_NAME = "model-decimator"
DECIMATOR_VERSION = "1.0"

BLENDER_SCRIPT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "blender", "decimate_model.py")

TAIL_LINES = 25

## How far the decimated surface may stray from the original, as a fraction of
## the model's bounding-box diagonal.
##
## HALF A PERCENT, and the number is chosen from what the player can see rather
## than from what looks tidy. A hero two metres along its longest axis fills
## roughly a third of a 1080p frame at gameplay camera distance, so one screen
## pixel is about four millimetres of model — a fifth of a percent of the
## diagonal. Half a percent is therefore a couple of pixels of silhouette
## error at the very worst sampled point, which is invisible in motion and
## still tight enough that a dissolved gill filament (millimetres thick, but
## centimetres from anything that remains) blows straight through it.
DEFAULT_MAX_DEVIATION = 0.005

## Longest side any texture may keep. Zero leaves images alone.
DEFAULT_MAX_TEXTURE = 2048

## Vertices closer than this fraction of the bounding-box diagonal are merged
## before anything is collapsed. Kept in step with DEFAULT_WELD in the Blender
## script, which documents why the tolerance is relative rather than absolute.
DEFAULT_WELD = 1e-5


def texture_ceiling(category: str | None, contract_path: str) -> int:
    """The category's longest permitted texture side, or the default."""
    if category is None:
        return DEFAULT_MAX_TEXTURE
    try:
        with open(contract_path, encoding="utf-8") as handle:
            contract = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return DEFAULT_MAX_TEXTURE
    rules = contract.get("categories", {}).get(category, {})
    maximum = rules.get("maxSize")
    if isinstance(maximum, list) and len(maximum) == 2:
        return int(max(maximum))
    return DEFAULT_MAX_TEXTURE


def build_argv(blender: str, input_path: str, output_path: str,
               budget: int, max_texture: int, samples: int,
               weld: float = DEFAULT_WELD) -> list[str]:
    """The documented headless invocation, in one place."""
    return [
        blender, "--background", "--python-exit-code", "1",
        "--python", BLENDER_SCRIPT, "--",
        "--input", input_path,
        "--output", output_path,
        "--max-triangles", str(budget),
        "--max-texture", str(max_texture),
        "--samples", str(samples),
        "--weld", str(weld),
    ]


def worst_deviation(summary: dict) -> tuple[float, dict | None]:
    """The largest strayed distance across both sampling directions."""
    worst, entry = 0.0, None
    for measurement in summary.get("deviation", []):
        fraction = measurement.get("maxAsFractionOfDiagonal")
        if fraction is not None and fraction > worst:
            worst, entry = fraction, measurement
    return worst, entry


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="oax-decimate",
        description="Decimate a glb to its contract budget and prove the "
                    "shape survived.")
    parser.add_argument("--input", required=True, help="source .glb")
    parser.add_argument("--output", required=True,
                        help="destination .glb (must not equal --input)")
    parser.add_argument("--max-triangles", type=int, default=None,
                        help="triangle budget; defaults to the Asset "
                             "Contract budget for the output's category")
    parser.add_argument("--max-texture", type=int, default=None,
                        help="longest texture side to keep; defaults to the "
                             "category's maxSize")
    parser.add_argument("--max-deviation", type=float,
                        default=DEFAULT_MAX_DEVIATION,
                        help="permitted surface deviation as a fraction of "
                             "the bounding-box diagonal "
                             f"(default {DEFAULT_MAX_DEVIATION})")
    parser.add_argument("--samples", type=int, default=20000,
                        help="surface probes per direction")
    parser.add_argument("--weld", type=float, default=DEFAULT_WELD,
                        help="merge vertices closer than this fraction of the "
                             "bounding-box diagonal before collapsing; 0 "
                             f"disables the weld (default {DEFAULT_WELD})")
    parser.add_argument("--contract", default=DEFAULT_CONTRACT)
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
    if os.path.abspath(args.input) == os.path.abspath(args.output):
        # The original is the only copy of the dense geometry, and decimation
        # cannot be undone. Writing over it would make a bad ratio permanent.
        print("error: --output must differ from --input; the dense source is "
              "the only thing a second attempt can start from",
              file=sys.stderr)
        return EXIT_INVOCATION

    category = category_for(args.output)
    budget = args.max_triangles
    if budget is None:
        budget = triangle_budget(category, args.contract)
    if budget is None:
        print("error: no --max-triangles given and the output path is not "
              "inside an assets/<category>/ directory, so the contract "
              "cannot supply one", file=sys.stderr)
        return EXIT_INVOCATION

    max_texture = args.max_texture
    if max_texture is None:
        max_texture = texture_ceiling(category, args.contract)

    blender = find_blender()
    if blender is None:
        print("error: no Blender binary found -- set $OAX_BLENDER or put "
              "`blender` on PATH (Blender 4.0 or newer)", file=sys.stderr)
        return EXIT_INVOCATION

    command = build_argv(blender, os.path.abspath(args.input),
                         os.path.abspath(args.output), budget, max_texture,
                         args.samples, args.weld)
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
        if line.startswith("DECIMATE "):
            try:
                summary = json.loads(line[len("DECIMATE "):])
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
        else:
            summary.setdefault("trianglesIn", triangles_before)
            summary["trianglesOut"] = triangles_after
            summary["meshesOut"] = meshes_after
            summary["reductionFactor"] = (
                round(triangles_before / triangles_after, 1)
                if triangles_after else 0)
            if triangles_after > budget:
                violations.append({
                    "rule": f"{TOOL_NAME}.triangle_budget",
                    "severity": "error",
                    "file": args.output,
                    "message": f"{triangles_after} triangles still exceed "
                               f"the budget of {budget}",
                    "remediation": "the decimator could not reach the "
                                   "target; the mesh may have a modifier or "
                                   "shape key holding triangles in place",
                })

            # Cracks, which deviation cannot see. A seam that opens leaves
            # both lips within a fraction of a millimetre of the original
            # surface, so every distance sample stays green while the model
            # renders with black hairlines down it. Counting the edges that
            # have only one face on them is what actually catches it.
            welding = summary.get("weld", {})
            seams_allowed = welding.get("openEdgesAfter")
            seams_left = welding.get("openEdgesAfterDecimation")
            if seams_allowed is not None and seams_left is not None \
                    and seams_left > seams_allowed:
                violations.append({
                    "rule": f"{TOOL_NAME}.open_seams",
                    "severity": "error",
                    "file": args.output,
                    "message": f"the reduction left {seams_left} open edges "
                               f"where the welded source had "
                               f"{seams_allowed}; the surface tore, and it "
                               "will render as black hairline cracks",
                    "remediation": "raise --weld so coincident vertices merge "
                                   "before the collapse, or reduce less",
                })

            strayed, entry = worst_deviation(summary)
            summary["worstDeviationFraction"] = strayed
            if strayed > args.max_deviation:
                where = entry.get("worstAt") if entry else "unknown"
                direction = entry.get("direction") if entry else "unknown"
                violations.append({
                    "rule": f"{TOOL_NAME}.shape_deviation",
                    "severity": "error",
                    "file": args.output,
                    "message": f"the surface moved {strayed:.4%} of the "
                               f"bounding-box diagonal ({direction}) at "
                               f"{where}, over the {args.max_deviation:.4%} "
                               "allowed; the model lost shape, not just "
                               "triangles",
                    "remediation": "raise --max-triangles, or protect the "
                                   "thin parts before decimating",
                })

    passed = not violations
    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME,
            "schemaVersion": DECIMATOR_VERSION,
            "target": args.input,
            "passed": passed,
            "output": args.output,
            "budget": budget,
            "summary": summary,
            "violations": violations,
        }, indent=2))
    else:
        print(f"{TOOL_NAME} v{DECIMATOR_VERSION} — {args.input} -> "
              f"{args.output}")
        for key, value in summary.items():
            print(f"  {key}: {value}")
        for entry in violations:
            print(f"\n[{entry['rule']}]\n{entry['message']}")
        print("\n" + ("PASS — inside budget, shape held" if passed
                      else f"FAIL — {len(violations)} problem(s)"))
    return EXIT_OK if passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
