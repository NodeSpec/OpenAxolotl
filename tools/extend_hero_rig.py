#!/usr/bin/env python3
"""Give the hero's legs real joints, and bind each foot to its own leg.

    oax-extend-rig --input assets/character/axolotl/axolotl.glb \
                   --output assets/character/axolotl/axolotl.glb \
                   [--format json] [--check]

Pure standard-library Python on the GLB itself. No Blender, no Godot, and
nothing but the skin and the skeleton is rewritten: positions, normals,
tangents, UVs, materials, embedded textures and every animation clip leave
this tool byte-for-byte as they arrived.

WHY THE RIG NEEDED THIS (REQ-002, the rig audit in docs/hero-rig-audit.md).
The hero shipped with twelve bones and ONE bone per leg. A foot on a one-bone
leg sits at a fixed distance from its pivot, so it can only move on a sphere:
it cannot stay on a point of ground while the body travels over it, which is
what a planted foot IS. Everything the animation layer did about foot sliding
was therefore a bounded rotation of a rigid stick, and said so.

Looking at why the feet read as broken found something worse than the missing
joint. The skin weights had been diffused by bone heat against a MIRRORED
skeleton, and the sculpt is not mirrored: it is frozen mid-stride, with the
front-left foot reaching forward under the head while the front-right stands
out to the side. The mirrored front-left bone therefore pointed at where the
foot was not, and bone heat handed the real foot to the nearest bone it could
find. Measured on the shipped file, the front-left sole was bound

    57% to the head, 28% to its own leg, 10% to the left gill

so it swung when the head turned and barely moved when the leg stepped. The
front-right leg, meanwhile, carried stray weight on 6,912 vertices across the
head and gills.

WHAT THIS DOES, per leg:

  * FINDS THE LIMB ON THE SURFACE, NOT IN SPACE. Starting from the sole (the
    lowest vertices in the leg's quadrant), it measures distance outward along
    the mesh itself. The gills and the head sit a few centimetres from the
    front feet in a straight line and are a long walk away over the skin, by
    way of the shoulder and the neck -- which is exactly the distinction bone
    heat could not make and a geodesic makes for free.
  * FINDS WHERE THE LIMB ENDS by its own thickness: rings of equal distance
    stay narrow along the shaft and widen abruptly where the leg meets the
    body.
  * ADDS FOUR BONES under the existing one: upper_xx at the shoulder or hip,
    where the limb actually leaves the body; shin_xx at mid-shaft; foot_xx at
    the ankle; toe_xx on the ground contact. toe carries no weight; it is the
    contact point, stored where an engine cannot lose it.
  * REBINDS THE LIMB to that chain by distance along the surface, blends into
    the body's existing weights across the shoulder, and removes leg weight
    from everything that is not a leg.

WHY upper_xx AND NOT JUST leg_xx. The mirrored leg_xx pivots sit deep inside
the body, and on the reaching front-left leg the pivot is 0.25 units from the
shoulder the limb grows out of. A leg solved from there is one very long bone
and one very short one (0.43 and 0.13): it cannot fold closer than 0.30, so a
foot placed under the body went through the floor instead. The first version
of this tool shipped exactly that and the gait probe caught it. Solved from the
real shoulder the two bones are near equal and the limb folds like a limb.

WHAT IT DELIBERATELY KEEPS. The twelve original bones keep their names, their
parents and their rest transforms EXACTLY. leg_xx is still the pivot inside
the body it always was, so every clip already keyed on it means what it meant,
and every line of engine code that finds a bone by name finds the same bone.
The new bones have no animation channels: left at rest they are rigid
extensions of leg_xx, and the limb moves as it did -- except that the whole
foot now comes with it. Bending them is the engine's job (two-bone IK in
core/rendering/hero_motion.gd), not this file's.

RE-RUNNABLE. Run on its own output it reuses the bones it finds and arrives at
the same weights, because the body blend reads only non-leg weights and those
are already normalised. --check does that comparison and writes nothing.

Exit codes follow every other tool here:
    0  extended (or, with --check, already conforming)
    1  a gate failed -- a limb could not be found, or a sole is still not
       owned by its own leg
    2  invocation error
"""

from __future__ import annotations

import argparse
import collections
import heapq
import json
import math
import os
import struct
import sys

TOOL_NAME = "hero-rig-extender"
TOOL_VERSION = "1.0"

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_INVOCATION = 2

LEGS = ("leg_fl", "leg_fr", "leg_bl", "leg_br")

## Vertices closer than this are one point of surface. glTF splits a mesh along
## its UV seams, so the file's own connectivity stops at every seam; walking
## the skin needs the seams closed again.
WELD_TOLERANCE = 1e-4

## How far above the model's lowest point still counts as "the sole".
SOLE_BAND = 0.04

## Ring width used when profiling a limb by surface distance.
PROFILE_STEP = 0.02

## A limb has ended where its rings are this much wider than its shaft.
JUNCTION_GROWTH = 1.45

## Surface distance from the sole to the ankle: just past the foot pad, whose
## own rim and upper face sit within about this distance of its underside.
ANKLE_DISTANCE = 0.07

## Half-width of the blend between two neighbouring bones of the chain.
JOINT_BLEND = 0.028

## The shoulder blend: how far before the limb's end the body starts to share
## the skin, and how far past it the leg lets go entirely.
SHOULDER_LEAD = 0.04
SHOULDER_TRAIL = 0.08

## How far inside the limb's end its top joint sits: on the last ring that is
## still limb, not on the first one that is already body.
SHOULDER_INSET = 0.03

## How much of a sole must belong to its own foot bone once this has run.
SOLE_OWNERSHIP_GATE = 0.99


CHAIN_PREFIXES = ("upper", "shin", "foot", "toe")


def chain_names(leg: str) -> tuple[str, str, str, str]:
    """upper, shin, foot and toe for one leg bone."""
    suffix = leg[len("leg_"):]
    return tuple(prefix + "_" + suffix for prefix in CHAIN_PREFIXES)


# --------------------------------------------------------------------------
# GLB in and out
# --------------------------------------------------------------------------

_COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
              5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
_WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path: str) -> tuple[dict, bytearray]:
    with open(path, "rb") as handle:
        data = handle.read()
    if data[:4] != b"glTF":
        raise ValueError("not a binary glTF file")
    document, binary = None, bytearray()
    offset = 12
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + length]
        if kind == 0x4E4F534A:
            document = json.loads(chunk)
        elif kind == 0x004E4942:
            binary = bytearray(chunk)
        offset += 8 + length
    if document is None:
        raise ValueError("no JSON chunk")
    return document, binary


def write_glb(path: str, document: dict, binary: bytearray) -> None:
    while len(binary) % 4:
        binary.append(0)
    document["buffers"][0]["byteLength"] = len(binary)
    text = json.dumps(document, separators=(",", ":")).encode("utf-8")
    text += b" " * ((4 - len(text) % 4) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    with open(path, "wb") as handle:
        handle.write(struct.pack("<4sII", b"glTF", 2, total))
        handle.write(struct.pack("<II", len(text), 0x4E4F534A))
        handle.write(text)
        handle.write(struct.pack("<II", len(binary), 0x004E4942))
        handle.write(binary)


def _layout(document: dict, index: int) -> tuple[str, int, int, int, int]:
    accessor = document["accessors"][index]
    view = document["bufferViews"][accessor["bufferView"]]
    code, size = _COMPONENT[accessor["componentType"]]
    width = _WIDTH[accessor["type"]]
    base = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    stride = view.get("byteStride") or size * width
    return code * width, base, stride, accessor["count"], size * width


def read_accessor(document: dict, binary: bytearray, index: int) -> list:
    pattern, base, stride, count, _ = _layout(document, index)
    return [struct.unpack_from("<" + pattern, binary, base + row * stride)
            for row in range(count)]


def overwrite_accessor(document: dict, binary: bytearray, index: int,
                       rows: list) -> None:
    """Rewrite an accessor where it stands. Same count, same layout."""
    pattern, base, stride, count, _ = _layout(document, index)
    if len(rows) != count:
        raise ValueError("accessor %d holds %d rows, was given %d"
                         % (index, count, len(rows)))
    for row, values in enumerate(rows):
        struct.pack_into("<" + pattern, binary, base + row * stride, *values)


def append_accessor(document: dict, binary: bytearray, rows: list,
                    component: int, kind: str) -> int:
    """A new tightly packed accessor at the end of the buffer."""
    code, _size = _COMPONENT[component]
    while len(binary) % 4:
        binary.append(0)
    start = len(binary)
    for values in rows:
        binary.extend(struct.pack("<" + code * _WIDTH[kind], *values))
    document["bufferViews"].append({
        "buffer": 0, "byteOffset": start, "byteLength": len(binary) - start})
    document["accessors"].append({
        "bufferView": len(document["bufferViews"]) - 1,
        "componentType": component, "count": len(rows), "type": kind})
    return len(document["accessors"]) - 1


# --------------------------------------------------------------------------
# Just enough linear algebra, as rows of rows
# --------------------------------------------------------------------------

def identity() -> list:
    return [[1.0 if r == c else 0.0 for c in range(4)] for r in range(4)]


def multiply(a: list, b: list) -> list:
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)]
            for r in range(4)]


def from_gltf(values) -> list:
    """glTF stores matrices column-major."""
    return [[values[c * 4 + r] for c in range(4)] for r in range(4)]


def to_gltf(matrix: list) -> list:
    return [matrix[r][c] for c in range(4) for r in range(4)]


def from_trs(node: dict) -> list:
    if "matrix" in node:
        return from_gltf(node["matrix"])
    x, y, z, w = node.get("rotation", (0.0, 0.0, 0.0, 1.0))
    sx, sy, sz = node.get("scale", (1.0, 1.0, 1.0))
    tx, ty, tz = node.get("translation", (0.0, 0.0, 0.0))
    return [
        [(1 - 2 * (y * y + z * z)) * sx, (2 * (x * y - z * w)) * sy,
         (2 * (x * z + y * w)) * sz, tx],
        [(2 * (x * y + z * w)) * sx, (1 - 2 * (x * x + z * z)) * sy,
         (2 * (y * z - x * w)) * sz, ty],
        [(2 * (x * z - y * w)) * sx, (2 * (y * z + x * w)) * sy,
         (1 - 2 * (x * x + y * y)) * sz, tz],
        [0.0, 0.0, 0.0, 1.0],
    ]


def invert_affine(m: list) -> list:
    a = [row[:3] for row in m[:3]]
    det = (a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1])
           - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
           + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]))
    if abs(det) < 1e-12:
        raise ValueError("a bone's bind matrix is singular")
    inverse = [[(a[(c + 1) % 3][(r + 1) % 3] * a[(c + 2) % 3][(r + 2) % 3]
                 - a[(c + 1) % 3][(r + 2) % 3] * a[(c + 2) % 3][(r + 1) % 3])
                / det for c in range(3)] for r in range(3)]
    shift = [-sum(inverse[r][k] * m[k][3] for k in range(3)) for r in range(3)]
    return [inverse[0] + [shift[0]], inverse[1] + [shift[1]],
            inverse[2] + [shift[2]], [0.0, 0.0, 0.0, 1.0]]


def apply(matrix: list, point) -> tuple:
    return tuple(sum(matrix[r][k] * point[k] for k in range(3)) + matrix[r][3]
                 for r in range(3))


def origin_of(matrix: list) -> tuple:
    return (matrix[0][3], matrix[1][3], matrix[2][3])


def centroid(points: list) -> tuple:
    count = float(len(points))
    return tuple(sum(point[axis] for point in points) / count
                 for axis in range(3))


def smoothstep(low: float, high: float, value: float) -> float:
    if high <= low:
        return 1.0 if value >= high else 0.0
    t = max(0.0, min(1.0, (value - low) / (high - low)))
    return t * t * (3.0 - 2.0 * t)


# --------------------------------------------------------------------------
# The surface
# --------------------------------------------------------------------------

def weld(positions: list) -> tuple[list, list]:
    """Close the UV seams: one welded index per distinct point of surface."""
    scale = 1.0 / WELD_TOLERANCE
    seen: dict = {}
    mapping, welded = [], []
    for point in positions:
        key = (round(point[0] * scale), round(point[1] * scale),
               round(point[2] * scale))
        index = seen.get(key)
        if index is None:
            index = len(welded)
            seen[key] = index
            welded.append(point)
        mapping.append(index)
    return mapping, welded


def surface_graph(indices: list, mapping: list, welded: list) -> list:
    graph: list = [dict() for _ in welded]
    for start in range(0, len(indices) - 2, 3):
        a, b, c = (mapping[indices[start]], mapping[indices[start + 1]],
                   mapping[indices[start + 2]])
        for first, second in ((a, b), (b, c), (c, a)):
            if first != second and second not in graph[first]:
                length = math.dist(welded[first], welded[second])
                graph[first][second] = length
                graph[second][first] = length
    return graph


def surface_distance(graph: list, seeds: list, limit: float) -> dict:
    """Distance from the seeds along the mesh, out to a limit (Dijkstra)."""
    distance = {seed: 0.0 for seed in seeds}
    heap = [(0.0, seed) for seed in seeds]
    heapq.heapify(heap)
    while heap:
        travelled, vertex = heapq.heappop(heap)
        if travelled > distance.get(vertex, math.inf):
            continue
        for neighbour, length in graph[vertex].items():
            reached = travelled + length
            if reached <= limit and reached < distance.get(neighbour,
                                                           math.inf):
                distance[neighbour] = reached
                heapq.heappush(heap, (reached, neighbour))
    return distance


def ring_profile(welded: list, distance: dict, limit: float) -> list:
    """(start, count, centre, mean radius) for each ring of equal distance."""
    bins: dict = collections.defaultdict(list)
    for vertex, travelled in distance.items():
        if travelled < limit:
            bins[int(travelled / PROFILE_STEP)].append(welded[vertex])
    profile = []
    for index in sorted(bins):
        points = bins[index]
        centre = centroid(points)
        radius = sum(math.dist(point, centre) for point in points) \
            / len(points)
        profile.append((index * PROFILE_STEP, len(points), centre, radius))
    return profile


def limb_end(profile: list) -> float | None:
    """Where the leg meets the body: the first ring much wider than the shaft.

    The shaft is read from the stretch just above the foot pad. Its rings are
    all about the limb's own thickness; the first ring that is not belongs to
    the body the limb grew out of.
    """
    shaft = sorted(radius for start, _count, _centre, radius in profile
                   if ANKLE_DISTANCE <= start < 0.22)
    if not shaft:
        return None
    typical = shaft[len(shaft) // 2]
    for start, _count, _centre, radius in profile:
        if start >= 0.16 and radius > JUNCTION_GROWTH * typical:
            return start
    return None


def ring_centre(welded: list, distance: dict, at: float) -> tuple | None:
    points = [welded[vertex] for vertex, travelled in distance.items()
              if abs(travelled - at) <= PROFILE_STEP]
    return centroid(points) if len(points) >= 4 else None


def chain_weights(travelled: float, ankle: float, elbow: float) -> tuple:
    """(upper, shin, foot) for a point this far along the skin from the sole.

    A partition of unity by construction, so a limb weighted with it can
    neither tear nor double-count at a joint.
    """
    foot = 1.0 - smoothstep(ankle - JOINT_BLEND, ankle + JOINT_BLEND,
                            travelled)
    upper = smoothstep(elbow - JOINT_BLEND, elbow + JOINT_BLEND, travelled)
    return upper, max(0.0, 1.0 - foot - upper), foot


def membership(travelled: float, end: float) -> float:
    """How much of a vertex belongs to the limb rather than to the body."""
    return 1.0 - smoothstep(end - SHOULDER_LEAD, end + SHOULDER_TRAIL,
                            travelled)


# --------------------------------------------------------------------------
# The rig
# --------------------------------------------------------------------------

class Rig:
    """The skeleton and the one skinned primitive, read once."""

    def __init__(self, document: dict, binary: bytearray) -> None:
        self.document = document
        self.binary = binary
        if len(document.get("skins", [])) != 1:
            raise ValueError("expected exactly one skin, found %d"
                             % len(document.get("skins", [])))
        self.skin = document["skins"][0]
        primitives = [primitive for mesh in document["meshes"]
                      for primitive in mesh["primitives"]
                      if "JOINTS_0" in primitive["attributes"]]
        if len(primitives) != 1:
            raise ValueError("expected exactly one skinned primitive, "
                             "found %d" % len(primitives))
        self.primitive = primitives[0]
        attributes = self.primitive["attributes"]
        if "JOINTS_1" in attributes:
            raise ValueError("the skin uses a second influence set; this "
                             "tool rewrites four influences per vertex")
        self.positions = read_accessor(document, binary,
                                       attributes["POSITION"])
        self.joints = read_accessor(document, binary, attributes["JOINTS_0"])
        self.weights = read_accessor(document, binary,
                                     attributes["WEIGHTS_0"])
        self.indices = [row[0] for row in read_accessor(
            document, binary, self.primitive["indices"])]
        self.parents: dict = {}
        for index, node in enumerate(document["nodes"]):
            for child in node.get("children", []):
                self.parents[child] = index
        self._globals: dict = {}

    def names(self) -> list:
        return [self.document["nodes"][joint].get("name", "")
                for joint in self.skin["joints"]]

    def node_of(self, name: str) -> int | None:
        for joint in self.skin["joints"]:
            if self.document["nodes"][joint].get("name") == name:
                return joint
        return None

    def world(self, node: int) -> list:
        if node not in self._globals:
            local = from_trs(self.document["nodes"][node])
            parent = self.parents.get(node)
            self._globals[node] = local if parent is None \
                else multiply(self.world(parent), local)
        return self._globals[node]

    def ensure_bone(self, name: str, parent_name: str, at: tuple) -> int:
        """A bone at a bind-space point, oriented like its parent."""
        parent = self.node_of(parent_name)
        local = apply(invert_affine(self.world(parent)), at)
        node = self.node_of(name)
        if node is None:
            self.document["nodes"].append({"name": name})
            node = len(self.document["nodes"]) - 1
            self.document["nodes"][parent].setdefault("children",
                                                      []).append(node)
            self.parents[node] = parent
            self.skin["joints"].append(node)
        record = self.document["nodes"][node]
        record.pop("matrix", None)
        record.pop("rotation", None)
        record.pop("scale", None)
        record["translation"] = [float(value) for value in local]
        self._globals.pop(node, None)
        return node


def find_soles(rig: Rig, welded: list) -> dict:
    """The lowest vertices, sorted into the quadrant of the leg they belong to."""
    floor = min(point[1] for point in welded)
    front = [origin_of(rig.world(rig.node_of(leg)))[2]
             for leg in ("leg_fl", "leg_fr")]
    back = [origin_of(rig.world(rig.node_of(leg)))[2]
            for leg in ("leg_bl", "leg_br")]
    divide = 0.5 * (sum(front) / 2.0 + sum(back) / 2.0)
    head_is_negative = sum(front) < sum(back)
    soles: dict = {leg: [] for leg in LEGS}
    for index, point in enumerate(welded):
        if point[1] >= floor + SOLE_BAND:
            continue
        forward = (point[2] < divide) == head_is_negative
        side = origin_of(rig.world(rig.node_of("leg_fl")))[0] > 0
        left = (point[0] > 0) == side
        soles[("leg_f" if forward else "leg_b") + ("l" if left else "r")] \
            .append(index)
    return soles


def extend(rig: Rig) -> tuple[dict, list]:
    """Fit every leg, add its chain and rewrite the skin. Returns the report."""
    violations: list = []
    names = rig.names()
    missing = [leg for leg in LEGS if leg not in names]
    if missing:
        raise ValueError("the skeleton has no %s" % ", ".join(missing))

    mapping, welded = weld(rig.positions)
    graph = surface_graph(rig.indices, mapping, welded)
    soles = find_soles(rig, welded)
    floor = min(point[1] for point in welded)

    # Skin statistics BEFORE, so the report can say what changed.
    def ownership(sole: list, owners: set, joints: list, weights: list,
                  joint_names: list) -> float:
        members = set(sole)
        mine = total = 0.0
        for vertex, welded_index in enumerate(mapping):
            if welded_index not in members:
                continue
            for slot in range(4):
                weight = weights[vertex][slot]
                if weight <= 0.0:
                    continue
                total += weight
                if joint_names[joints[vertex][slot]] in owners:
                    mine += weight
        return mine / total if total else 0.0

    legs: dict = {}
    fields: dict = {}
    for leg in LEGS:
        sole = soles[leg]
        entry: dict = {"soleVertices": len(sole)}
        legs[leg] = entry
        if len(sole) < 24:
            violations.append({
                "rule": TOOL_NAME + ".sole_not_found", "severity": "error",
                "message": "%s: only %d vertices near the floor in its "
                           "quadrant; there is no foot to fit" % (leg,
                                                                  len(sole))})
            continue
        entry["soleOwnedByOwnLegBefore"] = round(ownership(
            sole, {leg, *chain_names(leg)}, rig.joints, rig.weights, names), 4)

        field = surface_distance(graph, sole, 0.7)
        profile = ring_profile(welded, field, 0.7)
        end = limb_end(profile)
        if end is None or not 0.2 <= end <= 0.5:
            violations.append({
                "rule": TOOL_NAME + ".limb_end_not_found",
                "severity": "error",
                "message": "%s: the limb never widens into the body within "
                           "reach of its sole (found %r)" % (leg, end)})
            continue
        shoulder_at = end - SHOULDER_INSET
        elbow_at = ANKLE_DISTANCE + 0.5 * (shoulder_at - ANKLE_DISTANCE)
        ankle = ring_centre(welded, field, ANKLE_DISTANCE)
        elbow = ring_centre(welded, field, elbow_at)
        shoulder = ring_centre(welded, field, shoulder_at)
        if ankle is None or elbow is None or shoulder is None:
            violations.append({
                "rule": TOOL_NAME + ".joint_not_found", "severity": "error",
                "message": "%s: too little surface at a joint to place a "
                           "bone inside the limb" % leg})
            continue
        contact = centroid([welded[index] for index in sole])
        contact = (contact[0], floor, contact[2])
        fields[leg] = (field, end, elbow_at)

        upper, shin, foot, toe = chain_names(leg)
        pivot = origin_of(rig.world(rig.node_of(leg)))
        rig.ensure_bone(upper, leg, shoulder)
        rig.ensure_bone(shin, upper, elbow)
        rig.ensure_bone(foot, shin, ankle)
        rig.ensure_bone(toe, foot, contact)
        upper_length = math.dist(shoulder, elbow)
        lower_length = math.dist(elbow, ankle)
        entry.update({
            "limbEndsAtSurfaceDistance": round(end, 3),
            "pivot": [round(value, 4) for value in pivot],
            "shoulder": [round(value, 4) for value in shoulder],
            "elbow": [round(value, 4) for value in elbow],
            "ankle": [round(value, 4) for value in ankle],
            "contact": [round(value, 4) for value in contact],
            "pivotToShoulder": round(math.dist(pivot, shoulder), 4),
            "upperLength": round(upper_length, 4),
            "lowerLength": round(lower_length, 4),
            "restExtension": round(math.dist(shoulder, ankle)
                                   / (upper_length + lower_length), 4),
        })

    if violations:
        return {"legs": legs}, violations

    # ---- the skin --------------------------------------------------------
    names = rig.names()
    index_of = {name: index for index, name in enumerate(names)}
    limb_bones = set()
    for leg in LEGS:
        limb_bones.update((leg, *chain_names(leg)))
    limb_indices = {index_of[name] for name in limb_bones}

    stripped = 0
    new_joints, new_weights = [], []
    for vertex, welded_index in enumerate(mapping):
        body = {}
        had_leg = False
        for slot in range(4):
            weight = rig.weights[vertex][slot]
            if weight <= 0.0:
                continue
            joint = rig.joints[vertex][slot]
            if joint in limb_indices:
                had_leg = True
            else:
                body[joint] = body.get(joint, 0.0) + weight
        body_total = sum(body.values())

        blended: dict = {}
        share = 0.0
        for leg, (field, end, elbow_at) in fields.items():
            travelled = field.get(welded_index)
            if travelled is None:
                continue
            part = membership(travelled, end)
            if part <= 0.0:
                continue
            upper, shin, foot = chain_weights(travelled, ANKLE_DISTANCE,
                                              elbow_at)
            upper_name, shin_name, foot_name, _toe = chain_names(leg)
            for name, weight in ((upper_name, upper), (shin_name, shin),
                                 (foot_name, foot)):
                if weight > 0.0:
                    blended[index_of[name]] = blended.get(
                        index_of[name], 0.0) + part * weight
            share += part

        if share <= 0.0:
            if body_total <= 1e-9:
                # Skin that had nothing but a leg and is not on one: keep it
                # where it was rather than invent an owner for it.
                new_joints.append(rig.joints[vertex])
                new_weights.append(rig.weights[vertex])
                continue
            if had_leg:
                stripped += 1
            final = {joint: weight / body_total
                     for joint, weight in body.items()}
        else:
            share = min(share, 1.0)
            total = sum(blended.values())
            final = {joint: weight / total * share
                     for joint, weight in blended.items()}
            if share < 1.0 and body_total > 1e-9:
                for joint, weight in body.items():
                    final[joint] = final.get(joint, 0.0) \
                        + (1.0 - share) * weight / body_total

        ranked = sorted(final.items(), key=lambda item: -item[1])[:4]
        total = sum(weight for _joint, weight in ranked) or 1.0
        ranked += [(0, 0.0)] * (4 - len(ranked))
        new_joints.append(tuple(joint for joint, _weight in ranked))
        new_weights.append(tuple(weight / total for _joint, weight in ranked))

    changed = sum(1 for old_j, old_w, new_j, new_w in zip(
        rig.joints, rig.weights, new_joints, new_weights)
        if old_j != new_j or any(abs(a - b) > 1e-6
                                 for a, b in zip(old_w, new_w)))
    rig.joints, rig.weights = new_joints, new_weights

    for leg in LEGS:
        upper, shin, foot, _toe = chain_names(leg)
        owned = ownership(soles[leg], {foot}, rig.joints, rig.weights, names)
        legs[leg]["soleOwnedByFootAfter"] = round(owned, 4)
        counts = collections.Counter()
        for vertex in range(len(rig.joints)):
            top = max(range(4), key=lambda slot: rig.weights[vertex][slot])
            counts[names[rig.joints[vertex][top]]] += 1
        legs[leg]["verticesLedBy"] = {name: counts.get(name, 0)
                                      for name in (upper, shin, foot)}
        if owned < SOLE_OWNERSHIP_GATE:
            violations.append({
                "rule": TOOL_NAME + ".sole_not_owned", "severity": "error",
                "message": "%s: its foot bone holds only %.1f%% of its own "
                           "sole" % (leg, 100.0 * owned)})

    return {
        "bones": len(names),
        "vertices": len(rig.positions),
        "weldedVertices": len(welded),
        "triangles": len(rig.indices) // 3,
        "verticesReweighted": changed,
        "bodyVerticesFreedOfLegWeight": stripped,
        "legs": legs,
    }, violations


def commit(rig: Rig) -> None:
    """Write the skin and the bind matrices back into the document."""
    attributes = rig.primitive["attributes"]
    overwrite_accessor(rig.document, rig.binary, attributes["JOINTS_0"],
                       rig.joints)
    overwrite_accessor(rig.document, rig.binary, attributes["WEIGHTS_0"],
                       rig.weights)
    # Bind matrices in the mesh's own space. The originals are kept exactly;
    # only bones this tool placed get a computed one.
    originals = read_accessor(rig.document, rig.binary,
                              rig.skin["inverseBindMatrices"])
    matrices = []
    for order, joint in enumerate(rig.skin["joints"]):
        if order < len(originals) and rig.document["nodes"][joint].get(
                "name", "").split("_")[0] not in CHAIN_PREFIXES:
            matrices.append(tuple(originals[order]))
        else:
            matrices.append(tuple(to_gltf(invert_affine(rig.world(joint)))))
    rig.skin["inverseBindMatrices"] = append_accessor(
        rig.document, rig.binary, matrices, 5126, "MAT4")


def main(argv: list | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="oax-extend-rig",
        description="Add upper, shin, foot and toe bones under each leg and "
                    "bind every limb to its own chain.")
    parser.add_argument("--input", required=True, help="the rigged hero .glb")
    parser.add_argument("--output", default="",
                        help="where to write it (may equal --input)")
    parser.add_argument("--check", action="store_true",
                        help="write nothing; fail if running would change "
                             "the skin")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv)

    if not os.path.isfile(args.input):
        print("error: input %r is not a file" % args.input, file=sys.stderr)
        return EXIT_INVOCATION
    if not args.check and not args.output:
        print("error: give --output, or --check to only verify",
              file=sys.stderr)
        return EXIT_INVOCATION

    try:
        document, binary = read_glb(args.input)
        rig = Rig(document, binary)
        already = all(rig.node_of(name) is not None
                      for leg in LEGS for name in chain_names(leg)
                      if leg in rig.names())
        summary, violations = extend(rig)
    except (ValueError, KeyError, struct.error) as problem:
        print("error: %s" % problem, file=sys.stderr)
        return EXIT_INVOCATION

    summary["alreadyExtended"] = already
    if args.check and not violations:
        if not already or summary.get("verticesReweighted", 0):
            violations.append({
                "rule": TOOL_NAME + ".not_conforming", "severity": "error",
                "message": "running the extender would change this file: "
                           "%d vertices reweighted, chain bones %s"
                           % (summary.get("verticesReweighted", 0),
                              "present" if already else "missing")})
    if not violations and not args.check:
        commit(rig)
        write_glb(args.output, document, binary)

    passed = not violations
    if args.format == "json":
        print(json.dumps({
            "tool": TOOL_NAME, "schemaVersion": TOOL_VERSION,
            "target": args.input, "output": args.output, "passed": passed,
            "summary": summary, "violations": violations}, indent=2))
    else:
        print("%s v%s — %s" % (TOOL_NAME, TOOL_VERSION, args.input))
        for key, value in summary.items():
            if key != "legs":
                print("  %s: %s" % (key, value))
        for leg, entry in summary.get("legs", {}).items():
            print("  %s" % leg)
            for key, value in entry.items():
                print("    %s: %s" % (key, value))
        for entry in violations:
            print("\n[%s]\n%s" % (entry["rule"], entry["message"]))
        print("\n" + ("PASS" if passed else "FAIL — %d problem(s)"
                      % len(violations)))
    return EXIT_OK if passed else EXIT_VIOLATIONS


if __name__ == "__main__":
    sys.exit(main())
