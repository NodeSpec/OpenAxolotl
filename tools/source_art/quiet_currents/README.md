# Quiet Currents — bright pop groove

Original instrumental arrangement for OpenAxolotl. 48 bars, 4/4, 104 BPM,
D major, 1:50.769. A punchier pop/hip-hop pulse uses 52% eighth-note swing,
recorded drums with short releases, and a layered snare on beats two and four.
Plucked octave bass supports crisp piano triads and a repeating upper-register
piano/marimba hook. The hook appears immediately, with alternating full and
lighter phrases; a sparse bridge gives breathing room. Less reverb and less
high-frequency filtering make this revision drier and brighter. No flute or vocals.

The runtime Ogg is about 1.3 MB. The 24-bit WAV master stays in the authoring
workspace. Existing playback gains remain -10 dB on land and -13 dB underwater.
Startup, shore transitions, user Music settings and dance ducking are unchanged.
The shuffle song is separate and unchanged. Tails wrap over the 48-bar loop.

## Recorded instrument sources

VSCO 2 Community Edition: https://github.com/sgossner/VSCO-2-CE
VCSL percussion: https://github.com/sgossner/VCSL
Both libraries use CC0-1.0. Pinned revisions, individual recording URLs and hashes
are in samples-manifest.json and drum-manifest.json. The complete source licenses
are instrument_sample_license.txt and drum_sample_license.txt. Source recordings
are not bundled into the runtime asset tree. This is a sampled arrangement, not
a newly recorded live ensemble performance.

## Rebuild

In an authoring folder containing these files, install numpy, scipy and soundfile
with pip --target deps. Run download_samples.py and download_drums.py, then
compose_exploration.py. The output is in render/. The fixed seed and saved event
score make phrasing reproducible; different codec versions may alter file hashes.
No additional runtime dependencies are needed by Godot.

## Validation

The renderer verifies duration after Ogg decoding, finite samples, headroom and
absence of flute events. analysis.json includes the measured boundary delta and
all instruments. The Godot integration check covers loading, real loop playback,
quiet gains, transitions, dance recovery and unchanged user bus volumes. The
audio preview is provided for listening judgement; automated checks do not
establish musical taste or final balance on every speaker system.
