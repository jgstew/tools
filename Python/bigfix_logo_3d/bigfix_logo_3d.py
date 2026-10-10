# /// script
# requires-python = ">=3.10"
# dependencies = ["build123d>=0.13"]
# ///
"""
Generate a 3D printable, multi-colour BigFix logo coin with true-arc circles.

Geometry follows BigFix_logo_DevSite.svg, a 256-unit design where every
feature is concentric:
https://github.com/jgstew/jgstew.github.io/blob/master/images/BigFix/BigFix_logo_DevSite.svg

    outer disc      r = 128
    counter (hole)  r = 70
    stem slot       x = -70 .. -32 (relative to centre), from centre up to edge
    dot             r = 32           (slot's right edge is tangent to the dot)

Layout (default, double-sided):
    face layer  (--top thick): blue ring, white counter+slot, green dot
    white core  (--base thick)
    face layer  (--top thick), mirrored through the core

The bottom face sits at z=0 so it prints against the build plate; the top
face is its mirror image, so the coin reads as a "b" from either side.

--single-sided builds one face plus a white base, face-down (the face at z=0,
so every part touches the bed). --face-up puts the white base on the bed
instead. --dot-raise raises the green dot on the upward face, so it works
double-sided or --face-up, but not single-sided face-down.

Outputs:
    .3mf  Bambu Studio ready: one object, three parts pre-assigned to
          filaments 1 (white), 2 (blue), 3 (green), ~600 segments per circle
    .step exact arcs for CAD (slicers ignore STEP colours/filaments)
    _<colour>.stl one mesh per colour

Usage:
    uv run bigfix_logo_3d.py --diameter 40
"""

import argparse
import zipfile
from pathlib import Path
from xml.sax.saxutils import quoteattr

from build123d import (
    Box,
    Color,
    Compound,
    Cylinder,
    Pos,
    Rot,
    export_step,
    export_stl,
)

# Feature sizes as fractions of the outer radius.
PROPORTIONS = {
    # BigFix_logo_DevSite.svg (default): clean circles + rectangle
    "devsite": {
        "counter": 70 / 128,
        "dot": 32 / 128,
        "slot_l": -70 / 128,
        "slot_r": -32 / 128,
    },
    # bigfix.svg (Bezier counter, measured): bigger counter/dot, wider slot
    "bigfix-svg": {
        "counter": 2.986 / 5.29,
        "dot": 1.382 / 5.29,
        "slot_l": -2.986 / 5.29,
        "slot_r": -1.076 / 5.29,
    },
}

# Part name -> display colour. Order sets the filament number (1, 2, 3).
COLORS = {
    "white": "#FFFFFF",
    "blue": "#0045D9",
    "green": "#ABC450",  # BigFix green
}


def build(diameter, base, top, dot_raise, proportions, layout="double"):
    """Return {"white", "blue", "green"} solids that tile the coin without overlap.

    layout:
        "double"     face (at z=0, face-down) + white core + face on top
        "face-down"  face (at z=0) + white base
        "face-up"    white base (at z=0) + face
    """
    p = PROPORTIONS[proportions]
    R = diameter / 2
    r_counter = R * p["counter"]
    r_dot = R * p["dot"]
    slot_w = R * (p["slot_r"] - p["slot_l"])
    slot_cx = R * (p["slot_l"] + p["slot_r"]) / 2

    def disc(r, h, z0):
        # Cylinder is centred on its height by default; shift so it spans z0..z0+h.
        return Pos(0, 0, z0 + h / 2) * Cylinder(r, h)

    def face(z0, raise_=0.0):
        """One logo face layer spanning z0..z0+top, reading as a "b" from above."""
        # The "b" counter: hole + stem slot (from centre straight up past the edge, +Y).
        slot = Pos(slot_cx, R / 2 + 0.5, z0 + top / 2) * Box(slot_w, R + 1, top)
        counter = disc(r_counter, top, z0) + slot
        dot = disc(r_dot, top + raise_, z0)
        return {
            "white": (counter & disc(R, top, z0)) - dot,
            "blue": disc(R, top, z0) - counter,
            "green": dot,
        }

    def flipped(shape, height):
        # Turn over (a rotation, not a mirror, so the logo still reads correctly
        # from that side) and sit it back on z=0.
        return Pos(0, 0, height) * Rot(180, 0, 0) * shape

    if layout == "double":
        # Bottom face: identical to the face-down single-sided coin's face.
        bottom = {n: flipped(s, top) for n, s in face(0).items()}
        # Top face: the same layer un-flipped, i.e. the bottom face mirrored
        # through the core, so the coin reads as a "b" from either side.
        upper = face(top + base, dot_raise)
        parts = {n: bottom[n] + upper[n] for n in bottom}
        parts["white"] = parts["white"] + disc(R, base, top)
    else:
        parts = face(base, dot_raise)
        parts["white"] = parts["white"] + disc(R, base, 0)
        if layout == "face-down":
            parts = {n: flipped(s, base + top + dot_raise) for n, s in parts.items()}

    for name, shape in parts.items():
        shape.label = name
        hex_rgb = COLORS[name].lstrip("#")
        shape.color = Color(*(int(hex_rgb[i : i + 2], 16) / 255 for i in (0, 2, 4)))
    return parts


def mesh(shape, angular_deflection):
    """Tessellate a solid into shared vertices + triangles (watertight)."""
    verts, tris = shape.tessellate(0.001, angular_deflection)
    # tessellate() repeats vertices on every face; weld them so edges are shared.
    index, points, remap = {}, [], []
    for v in verts:
        key = (round(v.X, 6), round(v.Y, 6), round(v.Z, 6))
        if key not in index:
            index[key] = len(points)
            points.append(key)
        remap.append(index[key])
    triangles = []
    for a, b, c in tris:
        a, b, c = remap[a], remap[b], remap[c]
        if a != b and b != c and a != c:
            triangles.append((a, b, c))
    return points, triangles


def write_bambu_3mf(parts, path, angular_deflection, object_name="bigfix_logo"):
    """Write a 3MF that Bambu Studio / OrcaSlicer load as one multi-part object.

    Bambu ignores 3MF base materials, so the filament for each part is set in
    Metadata/model_settings.config (read even for 3MFs from other tools).
    An m:colorgroup is also included; newer Bambu Studio versions use it to
    suggest matching filament colours, older ones ignore it.
    """
    names = list(parts)
    group_id = 1
    part_ids = {name: i + 2 for i, name in enumerate(names)}
    assembly_id = len(names) + 2

    model = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<model unit="millimeter" xml:lang="en-US"'
        ' xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"'
        ' xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02">',
        f' <metadata name="Title">{object_name}</metadata>',
        ' <metadata name="Application">bigfix_logo_3d.py</metadata>',
        " <resources>",
        f'  <m:colorgroup id="{group_id}">',
        *(f'   <m:color color="{COLORS[n]}FF"/>' for n in names),
        "  </m:colorgroup>",
    ]
    for pindex, name in enumerate(names):
        points, triangles = mesh(parts[name], angular_deflection)
        model += [
            f'  <object id="{part_ids[name]}" name="{name}" type="model"'
            f' pid="{group_id}" pindex="{pindex}">',
            "   <mesh>",
            "    <vertices>",
            *(f'     <vertex x="{x:g}" y="{y:g}" z="{z:g}"/>' for x, y, z in points),
            "    </vertices>",
            "    <triangles>",
            *(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in triangles),
            "    </triangles>",
            "   </mesh>",
            "  </object>",
        ]
    model += [
        f'  <object id="{assembly_id}" name="{object_name}" type="model">',
        "   <components>",
        *(f'    <component objectid="{part_ids[n]}"/>' for n in names),
        "   </components>",
        "  </object>",
        " </resources>",
        f' <build><item objectid="{assembly_id}"/></build>',
        "</model>",
    ]

    config = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        "<config>",
        f' <object id="{assembly_id}">',
        f'  <metadata key="name" value={quoteattr(object_name)}/>',
        '  <metadata key="extruder" value="1"/>',
    ]
    for filament, name in enumerate(names, start=1):
        config += [
            f'  <part id="{part_ids[name]}" subtype="normal_part">',
            f'   <metadata key="name" value={quoteattr(name)}/>',
            f'   <metadata key="extruder" value="{filament}"/>',
            "  </part>",
        ]
    config += [" </object>", "</config>"]

    content_types = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels"'
        ' ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="model"'
        ' ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
        "</Types>\n"
    )
    rels = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Target="/3D/3dmodel.model" Id="rel0"'
        ' Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
        "</Relationships>\n"
    )
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", "\n".join(model) + "\n")
        z.writestr("Metadata/model_settings.config", "\n".join(config) + "\n")


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--diameter", type=float, default=40.0, help="outer diameter in mm (default 40)"
    )
    ap.add_argument(
        "--base",
        type=float,
        default=1.2,
        help="white base/core thickness in mm (default 1.2)",
    )
    ap.add_argument(
        "--top",
        type=float,
        default=0.6,
        help="coloured top layer thickness in mm (default 0.6 = 5 x 0.12)",
    )
    ap.add_argument(
        "--dot-raise",
        type=float,
        default=0.0,
        help="extra height of the green dot above the top face in mm (default 0)",
    )
    ap.add_argument(
        "--single-sided",
        action="store_true",
        help="logo on one side only, built face-down (default is double-sided)",
    )
    ap.add_argument("--proportions", choices=PROPORTIONS, default="devsite")
    ap.add_argument(
        "--face-up",
        action="store_true",
        help="single-sided with the white base on the bed instead of the face",
    )
    ap.add_argument(
        "--angular-deflection",
        type=float,
        default=0.02,
        help="mesh export angular tolerance in radians (default 0.02)",
    )
    ap.add_argument(
        "--out", type=Path, default=Path("out"), help="output folder (default ./out)"
    )
    args = ap.parse_args()
    if args.face_up:
        layout = "face-up"
    elif args.single_sided:
        layout = "face-down"
    else:
        layout = "double"
    if args.dot_raise and layout == "face-down":
        ap.error(
            "--dot-raise cannot be used with --single-sided face-down"
            " (a raised dot cannot print against the bed); add --face-up"
        )

    parts = build(
        args.diameter,
        args.base,
        args.top,
        args.dot_raise,
        args.proportions,
        layout=layout,
    )
    args.out.mkdir(parents=True, exist_ok=True)
    suffix = "_double" if layout == "double" else ""
    stem = args.out / f"bigfix_logo_{args.proportions}_{args.diameter:g}mm{suffix}"

    assembly = Compound(label="bigfix_logo", children=list(parts.values()))
    export_step(assembly, f"{stem}.step")

    write_bambu_3mf(parts, f"{stem}.3mf", args.angular_deflection)

    for name, shape in parts.items():
        export_stl(
            shape,
            f"{stem}_{name}.stl",
            tolerance=0.001,
            angular_tolerance=args.angular_deflection,
        )

    for name, shape in parts.items():
        bb = shape.bounding_box()
        print(
            f"{name:6s} volume={shape.volume:8.2f} mm^3"
            f"  z={bb.min.Z:.2f}..{bb.max.Z:.2f}  valid={shape.is_valid}"
        )
    print(f"wrote {stem}.step / .3mf / _<colour>.stl")


if __name__ == "__main__":
    main()
