#!/usr/bin/env python3
"""Rig a character model through headless Blender, as ONE Validator-shaped
CLI (REQ-035).

    oax-rig --input assets/character/axolotl/axolotl.glb \
            --output assets/character/axolotl/axolotl.glb [--format json]

The second half of the Blender lane. Refinement (tools/refine_model.py) gives
a model clean geometry; rigging gives it a skeleton and the animation clips
the game plays. Both run only in --background mode, both are validated on the
way out, and both refuse to pass silently when Blender is missing.

What this checks about what comes back, beyond "Blender exited 0":

  * GEOMETRY IS PRESERVED. Rigging poses vertices at runtime; it must never
    add or drop a triangle, so the Asset Contract budget the model already
    met still holds and its provenance stays true.
  * THE CLIP SET IS COMPLETE. The game client plays clips BY NAME
    (core/rendering/hero_animator.gd); a rig that silently exported five of
    six clips would leave one state frozen at runtime, which is exactly the
    kind of failure a headless pipeline must catch rather than ship.
  * THE MODEL IS ACTUALLY SKINNED. A glb can carry animations that drive
    nothing; the skin is what makes them move the mesh.

Exit codes are the contract with CI and with agents:
    0  rigged, and the output passes every header check
    1  Blender ran but failed, or the output is missing clips, skins, or
       changed geometry
    2  invocation error — bad arguments, unreadable input, no Blender
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from asset_contract_validator import HeaderError, glb_header  # noqa: E402
from refine_model import (  # noqa: E402
    DEFAULT_CONTRACT, EXIT_INVOCATION, EXIT_OK, EXIT_VIOLATIONS, TAIL_LINES,
    category_for, find_blender, triangle_budget)

TOOL_NAME = "model-rigger"
RIGGER_VERSION = "1.0"

BLENDER_SCRIPT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "blender", "rig_model.py")

## The clip names the game client plays. Kept here rather than imported from
## the bpy script because THIS file is the one CI can import: the bpy script
## cannot even be loaded outside Blender.
REQUIRED_CLIPS = ("idle", "waddle", "swim", "hop", "fall", "hurt")


def build_argv(blender: str, input_path: str, output_path: str) -> list[str]:
    """The documented headless invocation, in one place."""
    return [
        blender, "--background", "--python-exit-code", "1",
        "--python", BLENDER_SCRIPT, "--",
        "--input", input_path,
        "--output", output_path,
    ]


def glb_is_skinned(path: str) -> bool:
    """True when the glb carries at least one skin bound to a node.

    Read from the JSON chunk like every other header check: an animation
    without a skin animates nothing the player can see.
    """
    import struct
    with open(path, "rb") as handle:
        handle.read(12)
        length, _ = struct.unpack("<II", handle.read(8))
        document = json.loads(handle.read(length))
    skins = document.get("skins", [])
    skinned_nodes = [node for node in document.get("nodes", [])
                     if "skin" in node]
    return bool(skins) and bool(skinned_nodes)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="oax-rig",
        description="Rig a character glb through headless Blender.")
    parser.add_argument("--input", required=True, help="source .glb")
    parser.add_argument("--output", required=True,
                        help="destination .glb (may equal --input)")
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
                         os.path.abspath(args.output))
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
        if line.startswith("RIG "):
            try:
                summary = json.loads(line[len("RIG "):])
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
            triangles_after, _, animations = glb_header(args.output)
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
            summary["animationsOut"] = animations
            summary["skinned"] = glb_is_skinned(args.output)

            if triangles_after != triangles_before:
                violations.append({
                    "rule": f"{TOOL_NAME}.geometry_changed",
                    "severity": "error",
                    "file": args.output,
                    "message": f"triangles changed {triangles_before} -> "
                               f"{triangles_after}; rigging poses geometry, "
                               "it never rebuilds it",
                    "remediation": "the provenance describes the geometry; a "
                                   "step that changes it needs its own review",
                })

            missing = [clip for clip in REQUIRED_CLIPS
                       if clip not in animations]
            if missing:
                violations.append({
                    "rule": f"{TOOL_NAME}.missing_clips",
                    "severity": "error",
                    "file": args.output,
                    "message": f"the rig is missing clip(s) {missing}; the "
                               "client plays clips by name, so a missing one "
                               "freezes that state at runtime",
                    "remediation": "check the CLIPS table in "
                                   "tools/blender/rig_model.py",
                })

            if not summary["skinned"]:
                violations.append({
                    "rule": f"{TOOL_NAME}.not_skinned",
                    "severity": "error",
                    "file": args.output,
                    "message": "the output carries no skin; its animations "
                               "would move a skeleton nothing is bound to",
                    "remediation": "check that every mesh got an Armature "
                                   "modifier and vertex groups",
                })

            budget = triangle_budget(category_for(args.output), args.contract)
            if budget is not None and triangles_after > budget:
                violations.append({
                    "rule": f"{TOOL_NAME}.triangle_budget",
                    "severity": "error",
                    "file": args.output,
                    "message": f"{triangles_after} triangles exceed the "
                               f"budget of {budget}",
                    "remediation": "decimate before rigging",
                })

    passed = not violations
    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME,
            "schemaVersion": RIGGER_VERSION,
            "target": args.input,
            "passed": passed,
            "output": args.output,
            "summary": summary,
            "violations": violations,
        }, indent=2))
    else:
        print(f"{TOOL_NAME} v{RIGGER_VERSION} — {args.input} -> {args.output}")
        for key, value in summary.items():
            print(f"  {key}: {value}")
        for v in violations:
            print(f"\n[{v['rule']}]\n{v['message']}")
        print("\n" + ("PASS — rigged" if passed
                      else f"FAIL — {len(violations)} problem(s)"))
    return EXIT_OK if passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
