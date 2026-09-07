"""Bake the hero's surface maps — RUNS INSIDE BLENDER (bpy):

    blender --background --python-exit-code 1 \
        --python tools/blender/bake_hero_maps.py -- \
        [--model assets/character/axolotl/axolotl.glb] [--size 1024]

THE CHARACTER IS THE ONE ASSET THAT EARNS TEXTURES (REQ-040). The Asset
Contract's surface doctrine keeps image maps as the last resort, paid for
only where a pattern must be AUTHORED rather than DESCRIBED — and the hero's
skin is that case: mottling that follows the body, pore-scale relief, the
close-up read of a well-made vinyl toy. Everything else in the game stays
procedural or vertex-coloured; this file is the exception being paid for
properly.

WHAT IT DOES, in one reproducible pass over the SHIPPED model:

  1. UV-unwraps the skin mesh (Smart Project). The generated hero has no UV
     layout — it never needed one until now — and the unwrap must live in
     the shipped glb so the maps and the mesh can never disagree.
  2. COMPUTES two maps from a procedural height field, rasterised over the
     UV layout with Blender's own Mikktspace tangents — regenerated rather
     than painted, and renderer-free on purpose: Cycles' tangent-space bake
     zeroed the frame on this mesh while every input checked out, and a map
     pipeline resting on a renderer quirk is not reproducible. What ships:
       * axolotl_skin_normal.png — tangent-space relief: pore-scale noise
         over larger mottle bumps. This is what reads as SKIN in a close-up
         and disappears politely into the silhouette at gameplay distance.
       * axolotl_skin_detail.png — a NEUTRAL grey mottle multiplied over the
         vertex colour by the client's skin material. Neutral on purpose:
         the palette keeps living in the model's vertex colours, so a
         re-palette of the hero never invalidates the bake.
  3. Re-exports the glb in place with the new UVs and tangents. Geometry,
     skeleton, weights, vertex colours and all six clips must survive; the
     script FAILS if the triangle count or the clip list changes, because a
     bake that edits geometry is not a bake.

The five role meshes and their material names (the pipeline's contract with
hero_skin.gd) pass through untouched — nothing here assigns, renames or
removes a material.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

import bpy  # type: ignore

ROLE_MESHES = {"axolotl_skin", "axolotl_eye", "axolotl_gleam",
               "axolotl_gill", "axolotl_detail"}


def fail(message: str) -> None:
    print("bake-hero-maps: %s" % message, file=sys.stderr)
    raise SystemExit(1)


def glb_facts(path: str) -> tuple[int, list[str]]:
    """Triangles and clip names straight from the glb header, the same facts
    tools/refine_model.py reads, so this script and the test suite cannot
    disagree about what changed."""
    import struct
    with open(path, "rb") as handle:
        magic, _version, _length = struct.unpack("<III", handle.read(12))
        if magic != 0x46546C67:
            fail("'%s' is not a glb" % path)
        chunk_length, chunk_type = struct.unpack("<II", handle.read(8))
        if chunk_type != 0x4E4F534A:
            fail("'%s' has no JSON chunk first" % path)
        header = json.loads(handle.read(chunk_length))
    triangles = 0
    accessors = header.get("accessors", [])
    for mesh in header.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            index = primitive.get("indices")
            if index is not None:
                triangles += accessors[index]["count"] // 3
    clips = sorted(a.get("name", "") for a in header.get("animations", []))
    return triangles, clips


def value_noise(p, seed=0):
    """Deterministic 3D value noise over numpy arrays of positions (N,3).

    The same character as a Cycles noise texture, implemented here because
    the maps are COMPUTED rather than baked: Cycles' tangent-space bake
    produced a zeroed frame on this mesh (valid tangents, valid normals,
    valid UVs — the object-space bake worked and the tangent one wrote
    grey), and a map pipeline that depends on a renderer quirk is not
    reproducible. This depends on arithmetic only.
    """
    import numpy as np

    def hash3(ip):
        h = (ip[:, 0] * 374761393 + ip[:, 1] * 668265263
             + ip[:, 2] * 2147483647 + seed * 144665) & 0x7FFFFFFF
        h = (h ^ (h >> 13)) * 1274126177 & 0x7FFFFFFF
        return ((h ^ (h >> 16)) % 65536).astype(np.float64) / 65536.0

    ip = np.floor(p).astype(np.int64)
    fp = p - ip
    fp = fp * fp * (3.0 - 2.0 * fp)
    out = np.zeros(len(p))
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                corner = hash3(ip + np.array([dx, dy, dz]))
                weight = (
                    (fp[:, 0] if dx else 1.0 - fp[:, 0])
                    * (fp[:, 1] if dy else 1.0 - fp[:, 1])
                    * (fp[:, 2] if dz else 1.0 - fp[:, 2]))
                out += corner * weight
    return out


def fbm(p, scale, seed=0):
    return (value_noise(p * scale, seed) * 0.6
            + value_noise(p * scale * 2.17, seed + 1) * 0.4)


def height_field(p):
    """The skin's relief IN METRES: pore-scale grain over larger mottle
    bumps. Real units matter, because the normal is the field's slope and a
    slope only means something when rise and run share a unit: 0.8 mm of
    pore relief over a ~4.5 mm wavelength tilts about 20 degrees, which is
    texture; a unitless field made it +-80 degrees, which was confetti."""
    return fbm(p, 220.0, seed=7) * 0.0008 + fbm(p, 22.0, seed=3) * 0.0035


def mottle_field(p):
    """The neutral tonal mottle, 0..1, mapped to grey by the caller."""
    return fbm(p, 22.0, seed=3)


def compute_maps(skin, size):
    """Rasterises the skin's UV layout and computes both maps texel by texel.

    For every texel of every UV triangle: interpolate the object-space
    position and the tangent frame (from Blender's own calc_tangents, the
    same Mikktspace frame Godot renders with), evaluate the height field,
    take its gradient along the tangent and bitangent by finite differences,
    and tilt the normal. Object-space sampling is what makes the UV island
    seams invisible: the pattern is continuous across every island by
    construction, so where the islands meet on the body the values agree.
    """
    import numpy as np

    mesh = skin.data
    mesh.calc_loop_triangles()
    mesh.calc_tangents()
    uv_layer = mesh.uv_layers.active.data

    normal_img = np.zeros((size, size, 3), dtype=np.float64)
    normal_img[:, :] = (0.5, 0.5, 1.0)
    detail_img = np.ones((size, size, 3), dtype=np.float64)
    covered = np.zeros((size, size), dtype=bool)

    # The step must sit BELOW the finest wavelength in the height field
    # (1/220 m), or the finite difference samples across whole noise cells
    # and returns aliasing noise instead of a slope.
    EPS = 0.0012

    for tri in mesh.loop_triangles:
        loops = tri.loops
        uvs = np.array([uv_layer[i].uv[:] for i in loops]) * size
        lo = np.maximum(np.floor(uvs.min(axis=0)).astype(int), 0)
        hi = np.minimum(np.ceil(uvs.max(axis=0)).astype(int) + 1, size)
        if (hi <= lo).any():
            continue
        xs, ys = np.meshgrid(np.arange(lo[0], hi[0]),
                             np.arange(lo[1], hi[1]))
        pts = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], axis=1)

        a, b, c = uvs
        v0, v1 = b - a, c - a
        den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-9:
            continue
        v2 = pts - a
        wb = (v2[:, 0] * v1[1] - v1[0] * v2[:, 1]) / den
        wc = (v0[0] * v2[:, 1] - v2[:, 0] * v0[1]) / den
        wa = 1.0 - wb - wc
        pad = 1.0 / size
        inside = (wa >= -pad) & (wb >= -pad) & (wc >= -pad)
        if not inside.any():
            continue
        w = np.stack([wa[inside], wb[inside], wc[inside]], axis=1)
        px = pts[inside].astype(int)

        verts = np.array([mesh.vertices[mesh.loops[i].vertex_index].co[:]
                          for i in loops])
        norms = np.array([mesh.loops[i].normal[:] for i in loops])
        tans = np.array([mesh.loops[i].tangent[:] for i in loops])
        sign = mesh.loops[loops[0]].bitangent_sign

        P = w @ verts
        N = w @ norms
        N /= np.linalg.norm(N, axis=1, keepdims=True) + 1e-12
        T = w @ tans
        T /= np.linalg.norm(T, axis=1, keepdims=True) + 1e-12
        B = np.cross(N, T) * sign

        h0 = height_field(P)
        dt = (height_field(P + T * EPS) - h0) / EPS
        db = (height_field(P + B * EPS) - h0) / EPS
        n = np.stack([-dt, -db, np.ones(len(h0))], axis=1)
        n /= np.linalg.norm(n, axis=1, keepdims=True)

        tone = 0.88 + 0.12 * np.clip((mottle_field(P) - 0.35) / 0.4, 0, 1)

        normal_img[px[:, 1], px[:, 0]] = n * 0.5 + 0.5
        detail_img[px[:, 1], px[:, 0], 0] = tone * 1.0
        detail_img[px[:, 1], px[:, 0], 1] = tone * 0.98
        detail_img[px[:, 1], px[:, 0], 2] = tone * 0.99
        covered[px[:, 1], px[:, 0]] = True

    # A hand-rolled margin: dilate island borders outward so bilinear
    # filtering at the seams never samples the neutral background.
    for _ in range(4):
        grown = covered.copy()
        for shift, axis in (((1, 0), 0), ((-1, 0), 0), ((1, 0), 1), ((-1, 0), 1)):
            rolled = np.roll(covered, shift[0], axis=axis)
            rolled_n = np.roll(normal_img, shift[0], axis=axis)
            rolled_d = np.roll(detail_img, shift[0], axis=axis)
            fill = rolled & ~grown
            normal_img[fill] = rolled_n[fill]
            detail_img[fill] = rolled_d[fill]
            grown |= rolled
        covered = grown

    return normal_img, detail_img


def save_png(array, path, size):
    import numpy as np
    # alpha=True and a solid alpha of 1.0: the Asset Contract requires an
    # alpha channel on every character image, and the validator refuses an
    # RGB png. The rule is the contract's to keep; this writer complies.
    image = bpy.data.images.new(os.path.basename(path), size, size,
                                alpha=True, float_buffer=False)
    image.colorspace_settings.name = "Non-Color"
    rgba = np.ones((size, size, 4), dtype=np.float64)
    # Blender images are bottom-up and so is the V axis the rasteriser
    # indexed rows by, so the array lands correctly as-is.
    rgba[:, :, :3] = array
    image.pixels = rgba.ravel().tolist()
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default="assets/character/axolotl/axolotl.glb")
    parser.add_argument("--size", type=int, default=1024)
    args = parser.parse_args(argv)

    before_triangles, before_clips = glb_facts(args.model)
    print("bake-hero-maps: in  %d triangles, clips %s"
          % (before_triangles, before_clips))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.model)

    # The importer conjures helper objects (bone shapes and the like) that
    # were never in the file; anything that is not a role mesh or the rig is
    # dropped so it cannot be exported INTO the file.
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and obj.name.split(".")[0] not in ROLE_MESHES:
            print("bake-hero-maps: dropping import artifact '%s'" % obj.name)
            bpy.data.objects.remove(obj, do_unlink=True)

    skin = next((o for o in bpy.data.objects
                 if o.type == "MESH" and o.name.startswith("axolotl_skin")), None)
    if skin is None:
        fail("no axolotl_skin mesh in %s" % args.model)

    # 1. The unwrap — EVERY role mesh, not just the skin. Only the skin's
    # layout is sampled today, but a glb where some primitives carry UVs and
    # tangents and some do not is a file whose invariants depend on which
    # part you ask; the test suite holds "all primitives" and it is right
    # to. Smart Project throughout: the parts are merged organic shells no
    # seam-based unwrap was ever authored for, and the visual cost of island
    # seams is erased by computing maps from OBJECT-space procedurals, which
    # are continuous across every island by construction.
    for mesh_obj in [o for o in bpy.data.objects if o.type == "MESH"]:
        bpy.ops.object.select_all(action="DESELECT")
        mesh_obj.select_set(True)
        bpy.context.view_layer.objects.active = mesh_obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=1.15192, island_margin=0.015)
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    skin.select_set(True)
    bpy.context.view_layer.objects.active = skin

    # 2. The maps, computed rather than baked (see compute_maps).
    out_dir = os.path.dirname(args.model)
    normal_img, detail_img = compute_maps(skin, args.size)
    save_png(normal_img, os.path.join(out_dir, "axolotl_skin_normal.png"),
             args.size)
    save_png(detail_img, os.path.join(out_dir, "axolotl_skin_detail.png"),
             args.size)
    print("bake-hero-maps: computed normal + detail at %d px" % args.size)

    # 3. Re-export in place. Tangents ship too: Godot needs them the moment a
    # normal map exists, and generating them at import is a per-machine step
    # this file should not depend on.
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=args.model, export_format="GLB", use_selection=True,
        export_yup=True, export_colors=True, export_tangents=True,
        export_animations=True, export_skins=True, export_apply=False)

    after_triangles, after_clips = glb_facts(args.model)
    print("bake-hero-maps: out %d triangles, clips %s"
          % (after_triangles, after_clips))
    if after_triangles != before_triangles:
        fail("the bake changed geometry: %d -> %d triangles"
             % (before_triangles, after_triangles))
    if after_clips != before_clips:
        fail("the bake changed the clip list: %s -> %s"
             % (before_clips, after_clips))
    print("bake-hero-maps: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
