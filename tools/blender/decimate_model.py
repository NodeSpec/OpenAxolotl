"""Reduce a dense authored model to a triangle budget without losing its look —
RUNS INSIDE BLENDER (bpy), never as a plain Python script:

    blender --background --python tools/blender/decimate_model.py -- \
        --input reference/hero/pink_axolotl_2.glb \
        --output assets/character/axolotl/axolotl.glb \
        --max-triangles 55000 --max-texture 2048

tools/decimate_model.py is the documented way to invoke this; it finds Blender,
builds exactly this command line, and validates what comes back.

WHY THIS EXISTS. The asset pipeline now starts outside this repository: a
concept image goes to Meshy, and Meshy returns a photogrammetry-shaped export —
a uniform remesh at whatever density its solver settled on, with the detail
baked into 4K textures. The hero arrived at 1,933,518 triangles across 1.75
square metres of surface, which is a triangle every 1.4 millimetres. That is
thirty-two times the Asset Contract's character budget and, more to the point,
it is geometry the game will never see: at gameplay camera distance those
triangles are far below one pixel each.

WHY DECIMATION IS SAFE HERE, SPECIFICALLY. Reducing polygons destroys a model
whose detail IS its geometry — a sculpt with no maps, where the wrinkles are
vertices. This model is the opposite: it carries a base-colour map, a normal
map and a metallic-roughness map over a UV layout, so the wrinkles are pixels.
Collapse decimation interpolates UVs along the edges it collapses, which means
the maps keep landing where they landed and the surface keeps shading the way
it shaded. What is actually at risk is the SILHOUETTE — the outline of a gill
filament or a toe, which no normal map can restore — and that is what this
tool measures rather than assumes.

HOW THE MEASUREMENT WORKS. Deviation is sampled in both directions, because
the two failures look nothing alike:

  * DECIMATED -> ORIGINAL catches invention: new surface where the model had
    none, the bulge of a collapsed concavity.
  * ORIGINAL -> DECIMATED catches loss, and this is the one that matters for
    a creature with thin parts. When a gill filament dissolves entirely, every
    point that was on it is now far from any remaining surface. A one-way
    measurement would report this model as near-perfect while the gills were
    gone, because everything left behind still sits on the original.

Both are reported in model units and as a fraction of the bounding-box
diagonal, with the position of the worst point, so a regression names a place
on the creature rather than a number.

AND WHY THE MEASUREMENT IS NOT ENOUGH ON ITS OWN. The hero passed both
directions at a thousandth of its diagonal and still rendered with hairline
black cracks down its flanks and tail, because the failure was not distance:
the export is not one watertight surface. It arrives SPLIT along its UV
seams — 1,009,622 vertices for 966,739 distinct positions, and 84,666 edges
with only one face on them. In the source those two lips sit on top of each
other and nothing shows. Decimate them and each lip collapses on its own, the
pair drifts a fraction of a millimetre apart, and the surface opens. Every
sample point is still within a thousandth of the original, and the model
looks broken.

So this welds coincident vertices before it decimates anything, which turns
those 84,666 open edges into ordinary interior ones and makes the two lips of
a seam collapse together. It is safe for the textures: Blender keeps UVs per
face corner, so welding the geometry leaves the seam's two different UVs
exactly where they were. The count of open edges before and after is in the
report, because that number — not the deviation — is what predicts cracks.

Nothing here re-topologises, re-projects or re-bakes. It welds, collapses
edges, scales images, and reports what that cost.
"""

from __future__ import annotations

import argparse
import json
import math
import sys

import bmesh  # type: ignore  # only importable inside Blender
import bpy  # type: ignore  # only importable inside Blender
import numpy as np  # type: ignore  # Blender ships its own
from mathutils import Vector  # type: ignore
from mathutils.bvhtree import BVHTree  # type: ignore

## Points sampled per direction when measuring deviation. Twenty thousand puts
## roughly one sample per three decimated triangles on a hero-sized budget,
## which is dense enough that a lost filament cannot fall between samples.
DEFAULT_SAMPLES = 20000

## Deviation sampling is seeded so two runs of the same input report the same
## numbers. A measurement that drifts run to run cannot be regressed against.
SAMPLE_SEED = 20260907

## Vertices closer together than this fraction of the bounding-box diagonal
## are the same vertex. See weld() for why it is a fraction and not a distance.
DEFAULT_WELD = 1e-5


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="decimate_model (bpy)")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--max-triangles", type=int, required=True)
    parser.add_argument("--max-texture", type=int, default=0,
                        help="downscale any image whose longest side exceeds "
                             "this; 0 leaves images alone")
    parser.add_argument("--samples", type=int, default=DEFAULT_SAMPLES)
    parser.add_argument("--smooth-angle", type=float, default=60.0)
    parser.add_argument("--weld", type=float, default=DEFAULT_WELD,
                        help="merge vertices closer than this, as a fraction "
                             "of the bounding-box diagonal; 0 disables the "
                             "weld and lets seams crack open")
    return parser.parse_args(argv)


def open_edges(obj) -> int:
    """Edges with one face on them: the seams a decimation can pull apart."""
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    count = sum(1 for edge in mesh.edges if len(edge.link_faces) == 1)
    mesh.free()
    return count


def weld(objects: list, distance: float) -> dict:
    """Merge coincident vertices so the surface is one shell before it moves.

    THE DISTANCE IS A FRACTION OF THE MODEL, not an absolute. These exports
    arrive at whatever scale the generator felt like — this hero is two units
    long, an environment kit might be forty — and a fixed tolerance would be
    a no-op on one and a destructive merge on the other. A hundred-thousandth
    of the diagonal is far below any real feature and far above the float
    noise that separates two lips of the same seam.
    """
    report = {"distance": distance, "merged": 0,
              "openEdgesBefore": 0, "openEdgesAfter": 0}
    if distance <= 0.0:
        return report
    for obj in objects:
        report["openEdgesBefore"] += open_edges(obj)
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        before = len(mesh.verts)
        bmesh.ops.remove_doubles(mesh, verts=mesh.verts[:], dist=distance)
        report["merged"] += before - len(mesh.verts)
        mesh.to_mesh(obj.data)
        mesh.free()
        obj.data.update()
        report["openEdgesAfter"] += open_edges(obj)
    return report


def mesh_objects() -> list:
    return [obj for obj in bpy.data.objects if obj.type == "MESH"]


def triangle_count(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def triangle_arrays(obj) -> tuple:
    """(vertices Nx3 in world space, triangles Mx3, per-triangle area).

    Pulled through foreach_get rather than a Python loop: the source mesh has
    close to two million triangles, and iterating those as Python objects costs
    more than every other step in this tool put together.
    """
    mesh = obj.data
    mesh.calc_loop_triangles()

    count = len(mesh.vertices)
    coordinates = np.empty(count * 3, dtype=np.float64)
    mesh.vertices.foreach_get("co", coordinates)
    coordinates = coordinates.reshape(count, 3)

    matrix = np.array(obj.matrix_world.to_4x4(), dtype=np.float64)
    world = coordinates @ matrix[:3, :3].T + matrix[:3, 3]

    faces = len(mesh.loop_triangles)
    indices = np.empty(faces * 3, dtype=np.int32)
    mesh.loop_triangles.foreach_get("vertices", indices)
    indices = indices.reshape(faces, 3)

    areas = np.empty(faces, dtype=np.float64)
    mesh.loop_triangles.foreach_get("area", areas)
    # Areas come from local space; a non-uniform world scale would make them a
    # lie. Rescale by the world-space area of each triangle instead of trusting
    # the local number.
    edge_a = world[indices[:, 1]] - world[indices[:, 0]]
    edge_b = world[indices[:, 2]] - world[indices[:, 0]]
    areas = 0.5 * np.linalg.norm(np.cross(edge_a, edge_b), axis=1)
    return world, indices, areas


def sample_surface(vertices, indices, areas, count: int, rng) -> np.ndarray:
    """`count` points spread over the surface, weighted by triangle area.

    Area weighting is the whole point: a decimated mesh has triangles that
    differ in size by orders of magnitude, and sampling triangles uniformly
    would put as many probes on a hand-sized face as on a millimetre one,
    which measures the tessellation rather than the shape.
    """
    if len(indices) == 0 or areas.sum() <= 0.0:
        return np.zeros((0, 3), dtype=np.float64)
    cumulative = np.cumsum(areas)
    picks = np.searchsorted(cumulative, rng.random(count) * cumulative[-1])
    picks = np.clip(picks, 0, len(indices) - 1)

    corner_a = vertices[indices[picks, 0]]
    corner_b = vertices[indices[picks, 1]]
    corner_c = vertices[indices[picks, 2]]
    # Uniform barycentric coordinates: two uniforms folded across the diagonal
    # so the pair lands evenly inside the triangle rather than in the square.
    first = rng.random(count)
    second = rng.random(count)
    folded = first + second > 1.0
    first[folded] = 1.0 - first[folded]
    second[folded] = 1.0 - second[folded]
    weight = (1.0 - first - second)[:, None]
    return corner_a * weight + corner_b * first[:, None] + corner_c * second[:, None]


def distances_to(tree: BVHTree, points: np.ndarray) -> np.ndarray:
    out = np.empty(len(points), dtype=np.float64)
    for index in range(len(points)):
        location, _normal, _face, distance = tree.find_nearest(
            Vector(points[index]))
        out[index] = math.inf if location is None else distance
    return out


def deviation(tree: BVHTree, points: np.ndarray, label: str) -> dict:
    if len(points) == 0:
        return {"direction": label, "samples": 0}
    found = distances_to(tree, points)
    worst = int(np.argmax(found))
    return {
        "direction": label,
        "samples": len(points),
        "mean": float(found.mean()),
        "p95": float(np.percentile(found, 95.0)),
        "max": float(found[worst]),
        "worstAt": [round(float(value), 4) for value in points[worst]],
    }


def scene_bvh(objects: list) -> BVHTree:
    """One BVH over every mesh in `objects`, in world space."""
    vertices: list = []
    polygons: list = []
    for obj in objects:
        world, indices, _areas = triangle_arrays(obj)
        base = len(vertices)
        vertices.extend(tuple(point) for point in world)
        polygons.extend((int(a) + base, int(b) + base, int(c) + base)
                        for a, b, c in indices)
    return BVHTree.FromPolygons(vertices, polygons, all_triangles=True)


def diagonal(objects: list) -> float:
    low = Vector((math.inf, math.inf, math.inf))
    high = Vector((-math.inf, -math.inf, -math.inf))
    for obj in objects:
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            low = Vector((min(low[i], point[i]) for i in range(3)))
            high = Vector((max(high[i], point[i]) for i in range(3)))
    return (high - low).length


def stash(objects: list) -> list:
    """Copies of every mesh, kept so the original survives the decimation.

    The measurement needs both shapes at once, and the modifier rewrites the
    object in place. Copying the mesh datablock — not the object — keeps the
    transform shared and the copy out of the export.
    """
    copies = []
    for obj in objects:
        clone = bpy.data.objects.new(obj.name + "__original", obj.data.copy())
        clone.matrix_world = obj.matrix_world.copy()
        copies.append(clone)
    return copies


def decimate(objects: list, budget: int) -> dict:
    """Collapse every mesh by the one ratio that lands the scene on `budget`.

    ONE ratio across all meshes rather than a per-mesh allocation. A per-mesh
    budget would even out the density between a large object and a small one,
    which sounds fair and is wrong: it thins the part that has the most shape
    to lose and wastes triangles on the part that has none. A shared ratio
    preserves the relative density the author chose.
    """
    before = sum(triangle_count(obj) for obj in objects)
    if before <= budget:
        return {"ratio": 1.0, "trianglesBefore": before,
                "trianglesAfter": before, "skipped": True}

    ratio = float(budget) / float(before)
    for obj in objects:
        modifier = obj.modifiers.new("oax_decimate", "DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = ratio
        # Collapse can leave a face with a flipped normal where it folds a
        # thin part; symmetry off, and the exporter recomputes normals from
        # the result rather than carrying the source's.
        modifier.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="oax_decimate")

    after = sum(triangle_count(obj) for obj in objects)
    return {"ratio": ratio, "trianglesBefore": before,
            "trianglesAfter": after, "skipped": False}


def downscale_images(limit: int) -> list:
    """Halve oversized maps until they fit, and report what moved.

    Powers of two by repeated halving rather than a direct scale to `limit`:
    the maps are 4096 and the budget is 2048, so one exact halving is a box
    filter over four pixels, which is the cleanest reduction available and
    keeps the normal map's vectors from drifting the way a resample to a
    non-integer factor would.
    """
    changed = []
    if limit <= 0:
        return changed
    for image in bpy.data.images:
        width, height = image.size
        if width <= 0 or height <= 0:
            continue
        new_width, new_height = width, height
        while max(new_width, new_height) > limit and new_width > 1 and new_height > 1:
            new_width = max(1, new_width // 2)
            new_height = max(1, new_height // 2)
        if (new_width, new_height) == (width, height):
            continue
        image.scale(new_width, new_height)
        changed.append({"image": image.name,
                        "from": [width, height],
                        "to": [new_width, new_height]})
    return changed


## Which Principled BSDF input an image reaches, and what the contract calls
## the map that feeds it. Ordered: the first role an image satisfies wins, so a
## single ORM map wired to both Metallic and Roughness gets one name.
IMAGE_ROLES = (
    ("Base Color", "base_color"),
    ("Normal", "normal"),
    ("Metallic", "metallic_roughness"),
    ("Roughness", "metallic_roughness"),
)


def _image_behind(socket, depth: int = 0):
    """The image datablock feeding a shader socket, through whatever sits
    between it and the surface — a Normal Map node, a channel separator, a
    colour-space conversion. Bounded so a cyclic node group cannot hang us."""
    if depth > 8 or not socket.is_linked:
        return None
    node = socket.links[0].from_node
    if node.type == "TEX_IMAGE":
        return node.image
    for candidate in node.inputs:
        found = _image_behind(candidate, depth + 1)
        if found is not None:
            return found
    return None


def rename_images_by_role() -> list:
    """Give every map the name the Asset Contract expects, and report it.

    NOT COSMETIC. Godot extracts an embedded-texture .glb's images on import
    and names each file `<glb stem>_<image name>`, so the exporter's own name
    for a map becomes a real file in `assets/`. Meshy calls them `Image_0`,
    `Image_1`, `Image_2` — which produce `dredger_Image_0.jpg`, a filename the
    contract's lower_snake_case rule rejects and the repository's ignore rules
    (written for `_base_color`, `_normal`, `_metallic_roughness`) do not cover,
    so the derived files show up untracked and the asset fails validation
    through no fault of its geometry. The same three maps out of an older
    Meshy export already arrive named for their role and extract cleanly; this
    just stops the pipeline depending on which side of that change a model
    came from.

    Naming by ROLE rather than by index also makes the ignore rules honest: a
    map is ignored because it is a regenerable base-colour bake, not because
    some exporter happened to number it first.
    """
    renamed = []
    claimed: dict = {}
    for material in bpy.data.materials:
        if material.node_tree is None:
            continue
        for node in material.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            for socket_name, role in IMAGE_ROLES:
                socket = node.inputs.get(socket_name)
                if socket is None:
                    continue
                image = _image_behind(socket)
                if image is None or image in claimed:
                    continue
                claimed[image] = role
    for image, role in claimed.items():
        # The ROLE alone: Godot prefixes the .glb's own stem when it extracts,
        # so `base_color` becomes `dredger_base_color.jpg` on import — which is
        # both conforming and already ignored. Prefixing here would produce
        # `dredger_dredger_base_color.jpg`.
        wanted = role
        if image.name == wanted:
            continue
        was = image.name
        image.name = wanted
        # Blender disambiguates a clash with a `.001` suffix, which would put
        # the dot back into a filename the contract will not take. Say so
        # rather than shipping it.
        renamed.append({"image": was, "to": image.name, "role": role})
    return renamed


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.input)

    live = mesh_objects()
    if not live:
        print("DECIMATE " + json.dumps({"error": "no mesh objects in input"}))
        return 1

    span = diagonal(live)

    # The originals are COPIED here and MEASURED after the export, and the
    # split matters. Copying has to happen before the weld, or deviation would
    # be measured against our own first edit of the file rather than against
    # the file as it arrived. Measuring has to happen after the write, because
    # building a BVH over two million triangles materialises about four
    # million Python tuples, and an exporter asked to serialise a mesh while
    # that is resident comes up short: "Array length mismatch (got 599997,
    # expected more)", then a node with no mesh attached, then a 176-byte file
    # every other gate in this tool called a pass. Four of the six models this
    # pipeline was first pointed at failed exactly that way, and the two that
    # survived were simply the smallest.
    originals = stash(live)
    rng = np.random.default_rng(SAMPLE_SEED)
    welding = weld(live, span * args.weld)

    bpy.ops.object.select_all(action="DESELECT")
    reduction = decimate(live, args.max_triangles)
    welding["openEdgesAfterDecimation"] = sum(
        open_edges(obj) for obj in live)

    for obj in live:
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.shade_smooth(
            use_auto_smooth=True,
            auto_smooth_angle=math.radians(args.smooth_angle))

    # REPAIRED BEFORE ANYTHING READS IT. Welding coincident vertices and then
    # collapsing two million triangles by a factor of ten can leave topology
    # Blender itself calls invalid — duplicate loops, faces referencing a
    # vertex twice — and the exporter's own warning says so out loud before it
    # gives up: "Mesh is not valid, and may be exported wrongly", then "Array
    # length mismatch (got 599997, expected more)", then a node with no mesh
    # attached and a 176-byte file it reports as a success.
    #
    # validate() drops exactly those elements and is the remedy that warning
    # is asking for. It is cheap, it is idempotent, and four of the six models
    # this pipeline was first pointed at needed it.
    repairs = 0
    for obj in live:
        # Round-tripped through bmesh first, which rebuilds the datablock and
        # drops every derived cache on it — loop triangles, split normals, the
        # lot. The caches are what the exporter trips over: it reads one that
        # disagrees with the polygon count and gives up mid-write.
        rebuilt = bmesh.new()
        rebuilt.from_mesh(obj.data)
        rebuilt.to_mesh(obj.data)
        rebuilt.free()
        obj.data.update()
        if obj.data.validate(verbose=False):
            repairs += 1
    if repairs:
        print("DECIMATE_REPAIR " + json.dumps({"meshesRepaired": repairs}))

    images = downscale_images(args.max_texture)
    renamed = rename_images_by_role()

    # EXPORTED BEFORE THE SHAPE IS MEASURED, and the order is load-bearing.
    #
    # Measuring calls mesh.calc_loop_triangles() to pull the surface out
    # through foreach_get. That fills a cache, and on a mesh carrying even one
    # degenerate face the cache holds FEWER triangles than the mesh has
    # polygons — a collapse to 200,000 polygons left 199,999 triangles here.
    # The glTF exporter reads that cache, finds the array a triangle short,
    # and fails with "Array length mismatch (got 599997, expected more)" —
    # then writes a node with no mesh attached and returns success. Four of
    # the six models this pipeline was first pointed at came out as 176-byte
    # files that every other gate called a pass.
    #
    # Measuring after the write costs nothing: the deviation figures still
    # gate the result, and the file on disk is the geometry they describe.
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.export_scene.gltf(
        filepath=args.output,
        export_format="GLB",
        export_apply=True,
        export_normals=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_jpeg_quality=92,
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_yup=True,
    )

    original_tree = scene_bvh(originals)
    original_points = np.concatenate([
        sample_surface(*triangle_arrays(obj), args.samples // len(originals), rng)
        for obj in originals])
    decimated_tree = scene_bvh(live)
    decimated_points = np.concatenate([
        sample_surface(*triangle_arrays(obj), args.samples // len(live), rng)
        for obj in live])

    measurements = [
        deviation(original_tree, decimated_points, "decimated_to_original"),
        deviation(decimated_tree, original_points, "original_to_decimated"),
    ]
    for entry in measurements:
        if "max" in entry and span > 0.0:
            entry["maxAsFractionOfDiagonal"] = entry["max"] / span
            entry["p95AsFractionOfDiagonal"] = entry["p95"] / span

    print("DECIMATE " + json.dumps({
        "input": args.input,
        "output": args.output,
        "budget": args.max_triangles,
        "meshes": len(live),
        "diagonal": span,
        "weld": welding,
        "reduction": reduction,
        "deviation": measurements,
        "images": images,
        "imagesRenamed": renamed,
        "blender": bpy.app.version_string,
    }))
    return 0


if __name__ == "__main__":
    code = main()
    if code != 0:
        sys.exit(code)
