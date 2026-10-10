# BigFix Logo 3D

Generates a 3D-printable, multi-colour BigFix logo coin where the circles are true arcs, not stepped segments.

Importing the logo SVG into a slicer tessellates its curves coarsely, so the counter and dot come out as visible flat segments. This script builds the logo with [build123d](https://github.com/gumyr/build123d) instead, so the STEP output contains real circles and the mesh outputs use ~600 segments per circle.

![top view](https://raw.githubusercontent.com/jgstew/jgstew.github.io/master/images/BigFix/BigFix_logo_DevSite_512.png)

## Usage

With [uv](https://docs.astral.sh/uv/) (installs build123d automatically from the inline script metadata):

```bash
uv run bigfix_logo_3d.py --diameter 40
```

Or with pip:

```bash
pip install build123d
python bigfix_logo_3d.py --diameter 40
```

## Options

| Option | Default | Meaning |
|---|---|---|
| `--diameter` | `40` | Outer diameter in mm |
| `--base` | `1.2` | White base thickness in mm |
| `--top` | `0.6` | Coloured top layer thickness in mm (5 layers at 0.12 mm) |
| `--dot-raise` | `0` | Extra height of the green dot above the top layer in mm |
| `--proportions` | `devsite` | `devsite` or `bigfix-svg` (see Geometry) |
| `--angular-deflection` | `0.02` | Mesh angular tolerance in radians; smaller is finer |
| `--out` | `./out` | Output folder |

## Outputs

For `--diameter 40` with default proportions, written to `out/`:

- `bigfix_logo_devsite_40mm.step` - three coloured, named solids with exact arcs. **Preferred.**
- `bigfix_logo_devsite_40mm.3mf` - the same three bodies as a fine mesh.
- `bigfix_logo_devsite_40mm_{white,blue,green}.stl` - one mesh per colour.

The three bodies tile the coin exactly, with no overlaps:

- **white**: base disc, plus the counter and stem slot in the top layer
- **blue**: the outer ring in the top layer
- **green**: the centre dot

## Printing in Bambu Studio / OrcaSlicer

1. Import the `.step` file. When asked, load it as **a single object with multiple parts**.
2. Assign a filament to each part: white, blue and green.
3. Optional: lower the STEP import tolerance (angle/linear deflection) for even smoother circles.

The 3MF and STLs load the same way, but they don't carry any filament assignments.

## Geometry

The default `devsite` proportions come from [BigFix_logo_DevSite.svg](https://github.com/jgstew/jgstew.github.io/blob/master/images/BigFix/BigFix_logo_DevSite.svg). It's a 256-unit design built only from concentric circles and one rectangle:

| Feature | SVG units | Fraction of outer radius |
|---|---|---|
| Outer disc radius | 128 | 1 |
| Counter radius | 70 | 0.547 |
| Dot radius | 32 | 0.25 |
| Stem slot, x relative to centre | -70 to -32 | -0.547 to -0.25 |

The slot's left edge lines up with the counter's leftmost point, and its right edge touches the dot.

`bigfix-svg` uses proportions measured from an older variant of the logo, where the counter is drawn with Bezier curves. It has a slightly larger counter and dot and a wider slot.
