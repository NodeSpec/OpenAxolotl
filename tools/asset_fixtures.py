#!/usr/bin/env python3
"""Generate the shared asset-fixture corpus (Shared Test Fixtures contract).

    python tools/asset_fixtures.py <directory>

Builds two asset trees for the Asset Contract validator's tests: a CONFORMING
one that must pass, and a NONCONFORMING one where every asset breaks exactly
one rule, so a test can bind each fixture to the violation it exists to
demonstrate. Everything is generated -- PNGs from raw scanlines, WAVs from
silence -- because a binary blob in git cannot explain itself, has no
provenance of its own, and cannot be reviewed; forty lines of generator can
be. Standard library only, deterministic output.

Tests call `write_corpus(tmpdir)` and get fresh trees per run; the __main__
form exists so a human can materialise the corpus and look at it.
"""

from __future__ import annotations

import json
import os
import struct
import sys
import wave
import zlib


# --------------------------------------------------------------------------
# Minimal writers
# --------------------------------------------------------------------------

def write_png(path: str, width: int, height: int, *, alpha: bool,
              rgb: tuple[int, int, int] = (240, 150, 180)) -> None:
    """A real, decodable PNG: single IDAT, filter 0, RGB or RGBA."""
    def chunk(kind: bytes, body: bytes) -> bytes:
        raw = kind + body
        return struct.pack(">I", len(body)) + raw \
            + struct.pack(">I", zlib.crc32(raw))

    color_type = 6 if alpha else 2
    pixel = bytes(rgb) + (b"\xff" if alpha else b"")
    scanline = b"\x00" + pixel * width
    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    idat = zlib.compress(scanline * height)

    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", ihdr))
        handle.write(chunk(b"IDAT", idat))
        handle.write(chunk(b"IEND", b""))


def write_wav(path: str, *, channels: int = 1, rate: int = 44100,
              frames: int = 441) -> None:
    with wave.open(path, "wb") as handle:
        handle.setnchannels(channels)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(b"\x00\x00" * channels * frames)


def vorbis_ogg_bytes(*, channels: int = 2, rate: int = 44100) -> bytes:
    """One OggS page carrying a Vorbis identification header -- enough for a
    header-only reader, which is all the validator is allowed to be."""
    packet = (b"\x01vorbis" + struct.pack("<IB", 0, channels)
              + struct.pack("<III", rate, 0, 0) + b"\x00\x01")
    header = (b"OggS" + b"\x00\x02" + b"\x00" * 8 + b"\x01\x00\x00\x00"
              + b"\x00\x00\x00\x00" + b"\x00\x00\x00\x00"
              + bytes([1, len(packet)]))
    return header + packet


def write_provenance(asset_dir: str, *, method: str,
                     author: str = "OpenAxolotl Fixtures",
                     license_terms: str = "CC0-1.0",
                     tool: str | None = None, prompt: str | None = None,
                     extra: dict | None = None,
                     raw: str | None = None) -> None:
    path = os.path.join(asset_dir, "provenance.json")
    if raw is not None:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(raw)
        return
    payload: dict = {
        "author": author,
        "generationMethod": method,
        "licenseTerms": license_terms,
    }
    if tool is not None:
        payload["tool"] = tool
    if prompt is not None:
        payload["prompt"] = prompt
    if extra:
        payload.update(extra)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)


# --------------------------------------------------------------------------
# The corpus
# --------------------------------------------------------------------------

def _asset(root: str, category: str, name: str) -> str:
    path = os.path.join(root, "assets", category, name)
    os.makedirs(path, exist_ok=True)
    return path


def write_conforming(root: str) -> str:
    """A tree the validator must PASS: an AI-generated character with full
    provenance, a hand-authored sound without tool/prompt, and an opaque
    environment texture (alpha 'allowed' means opaque is legitimate)."""
    scout = _asset(root, "character", "axo_scout")
    write_png(os.path.join(scout, "axo_scout.png"), 128, 128, alpha=True)
    write_provenance(scout, method="ai-generated",
                     tool="imagegen 3.1",
                     prompt="a small pink axolotl scout, side view, "
                            "flat-shaded, transparent background")

    splash = _asset(root, "audio", "splash_soft")
    write_wav(os.path.join(splash, "splash_soft.wav"))
    write_provenance(splash, method="hand-authored")

    reef = _asset(root, "environment", "reef_wall")
    write_png(os.path.join(reef, "reef_wall.png"), 256, 256, alpha=False,
              rgb=(90, 130, 150))
    write_provenance(reef, method="hand-authored")

    return os.path.join(root, "assets")


# Every entry: (expected dotted rule, builder). One violation per asset, so a
# failure names exactly the fixture built to cause it.
def write_nonconforming(root: str) -> dict[str, str]:
    expectations: dict[str, str] = {}

    def expect(rule: str, rel: str) -> None:
        expectations[rel] = rule

    bad_name = _asset(root, "character", "BigFish")
    write_png(os.path.join(bad_name, "big_fish.png"), 128, 128, alpha=True)
    write_provenance(bad_name, method="hand-authored")
    expect("layout.name_convention", "assets/character/BigFish")

    jpg = _asset(root, "character", "net_ghost")
    with open(os.path.join(jpg, "net_ghost.jpg"), "wb") as handle:
        handle.write(b"\xff\xd8\xff\xe0 not really a jpeg")
    write_provenance(jpg, method="hand-authored")
    expect("character.file_type", "assets/character/net_ghost/net_ghost.jpg")

    tiny = _asset(root, "character", "tiny_spark")
    write_png(os.path.join(tiny, "tiny_spark.png"), 16, 16, alpha=True)
    write_provenance(tiny, method="hand-authored")
    expect("character.resolution", "assets/character/tiny_spark/tiny_spark.png")

    flat = _asset(root, "character", "flat_crab")
    write_png(os.path.join(flat, "flat_crab.png"), 128, 128, alpha=False)
    write_provenance(flat, method="hand-authored")
    expect("character.alpha_channel", "assets/character/flat_crab/flat_crab.png")

    broken = _asset(root, "prop", "broken_shell")
    with open(os.path.join(broken, "broken_shell.png"), "wb") as handle:
        handle.write(b"this is prose wearing a .png extension")
    write_provenance(broken, method="hand-authored")
    expect("prop.image_format", "assets/prop/broken_shell/broken_shell.png")

    hum = _asset(root, "audio", "deep_hum")
    write_wav(os.path.join(hum, "deep_hum.wav"), rate=96000)
    write_provenance(hum, method="hand-authored")
    expect("audio.audio_format", "assets/audio/deep_hum/deep_hum.wav")

    worm = _asset(root, "creature", "mud_worm")
    write_png(os.path.join(worm, "mud_worm.png"), 128, 128, alpha=True)
    expect("provenance.missing", "assets/creature/mud_worm/provenance.json")

    eel = _asset(root, "creature", "silt_eel")
    write_png(os.path.join(eel, "silt_eel.png"), 128, 128, alpha=True)
    write_provenance(eel, method="hand-authored", raw="{ not json")
    expect("provenance.invalid", "assets/creature/silt_eel/provenance.json")

    hook = _asset(root, "prop", "gold_hook")
    write_png(os.path.join(hook, "gold_hook.png"), 64, 64, alpha=True)
    write_provenance(hook, method="ai-generated")  # no tool, no prompt
    expect("provenance.invalid", "assets/prop/gold_hook/provenance.json")

    pearl = _asset(root, "prop", "empty_pearl")
    write_provenance(pearl, method="hand-authored")
    expect("layout.empty_asset", "assets/prop/empty_pearl")

    sub = _asset(root, "vehicles", "submarine")
    write_png(os.path.join(sub, "submarine.png"), 128, 128, alpha=True)
    expect("layout.unknown_category", "assets/vehicles")

    stray = os.path.join(root, "assets", "environment")
    os.makedirs(stray, exist_ok=True)
    write_png(os.path.join(stray, "spare.png"), 128, 128, alpha=False)
    expect("layout.stray_file", "assets/environment/spare.png")

    return expectations


def write_corpus(root: str) -> tuple[str, str, dict[str, str]]:
    """(conforming_root, nonconforming_root, expected violations by path)."""
    conforming = os.path.join(root, "conforming")
    nonconforming = os.path.join(root, "nonconforming")
    write_conforming(conforming)
    expectations = write_nonconforming(nonconforming)
    return conforming, nonconforming, expectations


if __name__ == "__main__":
    destination = sys.argv[1] if len(sys.argv) > 1 else "fixtures/assets"
    write_corpus(destination)
    print(f"asset fixture corpus written to {destination}")
