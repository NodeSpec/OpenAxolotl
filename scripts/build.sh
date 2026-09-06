#!/usr/bin/env bash
# THE single documented build command (REQ-018 AC-1).
#
#     ./scripts/build.sh
#
# From a clean checkout this fetches the pinned toolchain, imports the
# project, and exports the Linux build to build/linux/ -- the executable plus
# its .pck, packaging the core game and every world module installed under
# worlds/ (their manifests included; the hub discovers worlds at runtime, so
# packaging is the ONLY per-world step and there is no world list here to
# maintain). CI runs this exact script; so does a human. That identity is the
# point -- a build that only works in CI, or only on one laptop, is a build
# nobody can trust.

set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/setup.sh --godot-only
GODOT=.toolchain/godot

# Two passes on purpose. A clean checkout has no .godot/ import cache and no
# class-name registry; exporting against a cold cache produces a pck whose
# scripts cannot find each other. --import warms both, then the export packs.
"${GODOT}" --headless --audio-driver Dummy --path . --import

mkdir -p build/linux
"${GODOT}" --headless --audio-driver Dummy --path . \
    --export-release "Linux" build/linux/OpenAxolotl.x86_64

echo "build: build/linux/OpenAxolotl.x86_64 (+ OpenAxolotl.pck)"
