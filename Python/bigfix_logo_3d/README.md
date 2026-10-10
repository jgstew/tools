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
| `--top` | `0.6` | Coloured face layer thickness in mm (5 layers at 0.12 mm) |
| `--face-up` | off | Put the white base on the bed instead of the face |
| `--dot-raise` | `0` | Extra height of the green dot above the face in mm (needs `--face-up`) |
| `--proportions` | `devsite` | `devsite` or `bigfix-svg` (see Geometry) |
| `--angular-deflection` | `0.02` | Mesh angular tolerance in radians; smaller is finer |
| `--out` | `./out` | Output folder |

## Outputs

For `--diameter 40` with default proportions, written to `out/`:

- `bigfix_logo_devsite_40mm.3mf` - **use this for printing.** One object made of three parts, already assigned to filaments 1, 2 and 3. Uses ~600 segments per circle.
- `bigfix_logo_devsite_40mm.step` - the same three solids with exact arcs, for CAD. Slicers ignore STEP colours, so every part imports on filament 1.
- `bigfix_logo_devsite_40mm_{white,blue,green}.stl` - one mesh per colour.

By default the coin is built **face-down**: the coloured face layer is at z=0, so all three colours print against the build plate, with the white base on top.

The flip is a rotation, not a mirror, so the logo reads correctly once the coin is turned over. Every part touches the bed, so the layout comes out right even if a slicer drops each part to the bed separately.

The three parts tile the coin exactly, with no overlaps:

| Part | Filament | Colour | Contents |
|---|---|---|---|
| white | 1 | `#FFFFFF` | Base disc, plus the counter and stem slot in the face layer |
| blue | 2 | `#0045D9` | Outer ring in the face layer |
| green | 3 | `#ABC450` | Centre dot |

## Printing in Bambu Studio

1. Open or import the `.3mf` file. It loads as one object with three parts, each already on its own filament.
   - If your project has fewer than 3 filaments, Bambu Studio adds the missing slots.
   - Newer Bambu Studio versions may show a colour-mapping dialog. Accept it to match the parts to the filaments in your AMS.
2. Set filaments 1, 2 and 3 to white, blue and green, or map them to your AMS slots.

Bambu Studio ignores the material colours in a standard 3MF. So the script also writes `Metadata/model_settings.config`, which is the file Bambu itself uses to store each part's filament (`extruder`).

To use the STEP or STLs instead, add the parts to one object and change each part's filament by hand.

OrcaSlicer is a fork of Bambu Studio and reads the same `model_settings.config`, but this hasn't been tested.

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
