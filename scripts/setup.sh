#!/usr/bin/env bash
# Toolchain bootstrap (REQ-018): the pinned Godot engine, its export
# templates, and the validator CLIs. Idempotent -- everything is cached, so
# running it twice costs a stat, not a download.
#
#     ./scripts/setup.sh               # engine + templates + validator CLIs
#     ./scripts/setup.sh --godot-only  # engine + templates (what build.sh needs)
#
# THE PIN. One version, stated once, used for the binary, the templates and
# the cache keys. 4.3-stable is the version the whole test evidence base was
# produced with; the project targets Godot 4.7 (see project.godot
# config/features), and the pin advances DELIBERATELY -- rerun the full suite
# on the new engine, then change this line -- never implicitly. An unpinned
# engine turns a green PR red on an unrelated day, and this repo's
# contributors include AI agents that will misread toolchain drift as a defect
# in their own world module.
#
# $OAX_GODOT / $OAX_TEMPLATES inject already-downloaded copies (CI caches,
# air-gapped machines, the test harness). They change where the bytes come
# from, never what runs.

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT_VERSION="4.3-stable"
GODOT_TEMPLATES_DIRNAME="4.3.stable"
GODOT_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}"
TEMPLATES_TPZ="Godot_v${GODOT_VERSION}_export_templates.tpz"
TEMPLATES_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${TEMPLATES_TPZ}"
TEMPLATES_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_TEMPLATES_DIRNAME}"

mode="${1:-all}"

# --- Engine binary -> .toolchain/godot -------------------------------------
mkdir -p .toolchain
if [ ! -x .toolchain/godot ]; then
    if [ -n "${OAX_GODOT:-}" ] && [ -x "${OAX_GODOT}" ]; then
        cp "${OAX_GODOT}" .toolchain/godot
    else
        curl -fSL -o ".toolchain/${GODOT_ZIP}" "${GODOT_URL}"
        unzip -q -o ".toolchain/${GODOT_ZIP}" -d .toolchain
        mv ".toolchain/Godot_v${GODOT_VERSION}_linux.x86_64" .toolchain/godot
        rm -f ".toolchain/${GODOT_ZIP}"
    fi
    chmod +x .toolchain/godot
fi

# --- Export templates -> the engine's own templates directory ---------------
if [ ! -f "${TEMPLATES_DIR}/linux_release.x86_64" ]; then
    scratch="$(mktemp -d)"
    trap 'rm -rf "${scratch}"' EXIT
    if [ -n "${OAX_TEMPLATES:-}" ] && [ -f "${OAX_TEMPLATES}" ]; then
        tpz="${OAX_TEMPLATES}"
    else
        curl -fSL -o "${scratch}/${TEMPLATES_TPZ}" "${TEMPLATES_URL}"
        tpz="${scratch}/${TEMPLATES_TPZ}"
    fi
    unzip -q -o "${tpz}" -d "${scratch}/extract"
    mkdir -p "$(dirname "${TEMPLATES_DIR}")"
    rm -rf "${TEMPLATES_DIR}"
    mv "${scratch}/extract/templates" "${TEMPLATES_DIR}"
fi

# --- Validator CLIs (oax-level-check, oax-static-gate, oax-test) ------------
if [ "${mode}" != "--godot-only" ]; then
    python3 -m pip install --quiet -e .
fi

echo "setup: $(.toolchain/godot --version)"
