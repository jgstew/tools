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

Layout (bottom to top):
    white base disc  (--base thick)
    top layer        (--top thick): blue ring, white counter+slot, green dot
    optional green dot raise (--dot-raise) above the top layer

Outputs a STEP (exact arcs, best for Bambu Studio / Orca), plus a finely
tessellated 3MF and per-colour STLs as fallbacks.

Usage:
    uv run bigfix_logo_3d.py --diameter 40
"""

import argparse
from pathlib import Path

from build123d import (
    Box,
    Color,
    Compound,
    Cylinder,
    Mesher,
    Pos,
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

COLORS = {
    "white": (1.0, 1.0, 1.0),
    "blue": (0.0, 0.27, 0.85),
    "green": (0.67, 0.77, 0.31),  # BigFix green #ABC450
}


def build(diameter, base, top, dot_raise, proportions):
    """Return {"white", "blue", "green"} solids that tile the coin without overlap."""
    p = PROPORTIONS[proportions]
    R = diameter / 2
    r_counter = R * p["counter"]
    r_dot = R * p["dot"]
    slot_w = R * (p["slot_r"] - p["slot_l"])
    slot_cx = R * (p["slot_l"] + p["slot_r"]) / 2

    def disc(r, h, z0):
        # Cylinder is centred on its height by default; shift so it spans z0..z0+h.
        return Pos(0, 0, z0 + h / 2) * Cylinder(r, h)

    z_top = base
    # The "b" counter: hole + stem slot (from centre straight up past the edge, +Y).
    slot = Pos(slot_cx, R / 2 + 0.5, z_top + top / 2) * Box(slot_w, R + 1, top)
    counter = disc(r_counter, top, z_top) + slot

    blue = disc(R, top, z_top) - counter
    dot = disc(r_dot, top + dot_raise, z_top)
    white = disc(R, base, 0) + (counter & disc(R, top, z_top)) - dot

    parts = {"white": white, "blue": blue, "green": dot}
    for name, shape in parts.items():
        shape.label = name
        shape.color = Color(*COLORS[name])
    return parts


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
        help="white base thickness in mm (default 1.2)",
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
        help="extra height of the green dot above the top layer in mm (default 0)",
    )
    ap.add_argument("--proportions", choices=PROPORTIONS, default="devsite")
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

    parts = build(args.diameter, args.base, args.top, args.dot_raise, args.proportions)
    args.out.mkdir(parents=True, exist_ok=True)
    stem = args.out / f"bigfix_logo_{args.proportions}_{args.diameter:g}mm"

    assembly = Compound(label="bigfix_logo", children=list(parts.values()))
    export_step(assembly, f"{stem}.step")

    mesher = Mesher()
    for shape in parts.values():
        mesher.add_shape(
            shape, linear_deflection=0.001, angular_deflection=args.angular_deflection
        )
    mesher.write(f"{stem}.3mf")

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
