# SVG export

`bridge_parser.exportSvg(text, options={})` returns a complete SVG string. Use an
initialized bridge parser, just as for HTML output:

```cfml
svg = parser.exportSvg("AKQ.JT9.876.543");
fileWrite(expandPath("hand.svg"), svg, "utf-8");

svg = parser.exportSvg(fileRead(expandPath("deal.pbn")), {
    deal: "NS", rose: false, monochrome: true, title: "North and South"
});
```

Supported input is a single dot-separated hand, a direction-prefixed deal
(`N:hand hand hand hand`, clockwise), or PBN containing a Deal tag. Use four hand
slots in a deal and `-` for an unknown hand, which is omitted. Empty suits become
dashes; `T` or `10` displays as `10`, and `X` displays as `x`. Input validation
checks notation, not whether cards form a legal 52-card deal.

Options are `deal` (visible seats, default `NESW`), `rose` (default true),
`monochrome` (default false), and `title` (accessible text, XML-escaped). The `deal`
and `rose` options apply only to full deals. Unknown options and invalid notation
raise errors. Auctions, suit combinations, player names, and other PBN metadata
are not included. Existing HTML rendering is unchanged.

## Spacing options

Pass layout values in the second argument to `exportSvg` (the SVG conversion
method). Values are numbers in SVG units, equivalent to pixels at intrinsic size.

```cfml
svg = parser.exportSvg(pbnText, {
    fontSize: 14,
    letterSpacing: 0,
    wordSpacing: -2,
    rowSpacing: 18,
    suitGap: 22,
    handGap: 28,
    columnGap: 16,
    padding: 12
});
```

| Option | Default | Meaning |
| --- | --- | --- |
| `fontSize` | 14 | Card and suit-symbol font size. |
| `letterSpacing` | 0 | Extra spacing per character, including between the digits of `10`. |
| `wordSpacing` | 0 | Extra spacing at the literal spaces between cards. Negative values tighten gaps. |
| `rowSpacing` | 20 | Baseline distance between suit rows within a hand. |
| `suitGap` | 24 | Distance from the suit symbol's starting x-coordinate to the cards' starting x-coordinate. |
| `handGap` | 24 | Horizontal offset from the N/S hand starts to the rose’s left edge; also the requested baseline gap between bands of hands. |
| `columnGap` | 12 | Additional clearance between each E/W column and the rose, beyond `handGap`. |
| `padding` | 12 | Space around the diagram. |

`fontSize` and `rowSpacing` must be positive; other layout distances must be
nonnegative. `letterSpacing` and `wordSpacing` may be negative provided estimated
character advances remain positive. All values must be finite decimal numbers
with magnitude at most 1000. Invalid settings raise `bridge.svg` errors.

The rose stays centered in the canvas. North and South share a starting x-coordinate
exactly `handGap` left of the rose's left edge. East and West reserve equal widths,
using the longest displayed suit in either of those hands. The West hand is
right-aligned as a block within its column, leaving unused space on the left. Its
longest suit ends `handGap + columnGap` before the rose's left edge; East starts the same distance
after its right edge. Longer outer suits expand both sides equally, leaving the
N/S-to-rose offset unchanged. Long N/S suits can add equal outer margins to prevent
clipping. Thus diagrams centered on a page keep their roses and N/S starts aligned
when using the same spacing options. Hiding the rose retains these horizontal anchors.

The canvas dimensions and vertical compass position are recalculated from these options.
Very small `handGap` values are enlarged to reserve the estimated font height;
compact rows also reserve space for the 56-unit compass when enabled. Deliberately
small `rowSpacing` or `suitGap` values can overlap text. Width calculations reserve
conservative font advances and expand for positive letter/word spacing; negative
spacing tightens text without reducing that safety allowance.

Text options are inherited SVG presentation attributes on the root, so different
inline diagrams can use different values without their embedded CSS conflicting.
The compass labels retain their own 12px font and normal spacing. Use these options
for sizing rather than changing font size in CSS, so layout can account for it.

## Styling and web use

The stylesheet in `assets/css/bridge_svg.css` is embedded in every export. Edit
that file to change the common design; regenerate existing SVGs after edits.
Rules use prefixed classes and simple SVG 1.1-compatible selectors. No external
stylesheet, JavaScript, `foreignObject`, CSS variables, or HTML layout is needed.
Coordinates remain attributes because they describe geometry, rather than style.
Each SVG has explicit pixel dimensions and a matching `viewBox`; columns grow
with the displayed holdings to avoid clipping. The background is transparent.

```html
<img src="hand.svg" alt="North's hand" style="max-width:100%;height:auto">
```

You can also insert the returned SVG directly into HTML or serve it with
`Content-Type: image/svg+xml; charset=utf-8`. There are no generated IDs that can
collide when several diagrams share a page. Inline SVGs can be customized using
host CSS targeting the `bridge-svg-*` classes; image elements use the embedded
styles. Avoid broad host rules that override SVG text styling.

### Configurable fonts

Set `fontFamily`, `suitFontFamily`, and `labelFontFamily` in `exportSvg` options.
They accept SVG font-family names or comma-separated fallback lists. Defaults are
`DejaVu Sans Mono, monospace`, `DejaVu Sans, sans-serif`, and `sans-serif`, respectively.
Font names are XML-escaped and attached as presentation attributes, so different
inline diagrams can use different font families without stylesheet collisions.

```cfml
svg = parser.exportSvg(pbnText, {
    fontFamily: "My Card Font, monospace",
    suitFontFamily: "My Symbol Font, sans-serif",
    labelFontFamily: "My Label Font, sans-serif"
});
fileWrite(svgPath, svg, "utf-8");
svgToPng(svgPath=svgPath, pngPath=pngPath, fontFiles=[
    expandPath("/fonts/MyCardFont.ttf"),
    expandPath("/fonts/MySymbolFont.ttf"),
    expandPath("/fonts/MyLabelFont.ttf")
]);
```

The converter's optional `fontFiles` array accepts TrueType files readable by Java
(`Font.createFont`). Configure the example's `fontFiles` variable or pass paths
to the helper. Use each font's **internal family name** in the export options,
which may differ from its filename. The helper registers supplied fonts with Java
and provides explicit `@font-face` sources to Batik via a temporary user stylesheet.
This also makes new fonts available after Batik has cached its installed-font list.
The temporary stylesheet is removed after conversion; supplied font files are
unchanged. Missing or invalid font files raise an error rather than being ignored.

Without supplied files, fonts must be installed on the conversion machine. A
missing font falls back according to the SVG family list; generic `monospace` may
resolve to Courier New on Windows. Use a monospace card font with ordinary metrics
for the exporter's conservative width estimates. Font files supplied to the PNG
converter are not embedded in SVGs: browsers need the selected fonts installed or
provided separately by the host page. Exact glyph metrics can vary by renderer.

## PNG conversion

For example, with Python and CairoSVG installed:

```sh
python -m cairosvg testing/svg_test.svg -o deal.png -s 2
```

This doubles the intrinsic pixel dimensions. Use `--background-color white` for
an opaque white background.

### Apache Batik (CFML)

`testing/svg_convert.cfm` uses Apache Batik's `PNGTranscoder` directly through Java.
Each Batik `createObject("java", ..., batikSettings)` call receives Lucee Maven
settings for `org.apache.xmlgraphics:batik-transcoder:1.19` and
`org.apache.xmlgraphics:batik-codec:1.19`. Lucee downloads these artifacts and their
transitive dependencies. Use a Lucee version supporting Maven Java settings and
allow its Maven repository access; manually installing JARs is not required.

Run `testing/svg_convert.cfm` to convert `testing/svg_test.svg` to
`testing/_output/output.png`. The helper accepts an optional target pixel width:

```cfml
svgToPng(svgPath, pngPath);       // Intrinsic SVG dimensions, transparent background
svgToPng(svgPath, pngPath, 1200); // 1200 pixels wide, preserving aspect ratio
```

The destination directory must already exist and be writable. Batik consumes the
embedded stylesheet and uses installed or supplied fonts, with no external process. Conversion errors propagate to the caller; PNG bytes are
buffered before writing so failed transcoding does not replace an existing file.
Only pass trusted SVG files: Batik may resolve resources referenced by an SVG.

## Examples and verification

`testing/svg_export.cfm` serves a live export. `testing/svg_test.svg` is its full
deal output; `testing/svg_inline.svg` shows a long single hand.
`testing/svg_test.html` displays both as independent images.
Run `testing/functions/testSvgExport.cfm` in the same CFML setup as the existing
parser tests; it returns JSON with assertion counts and failures.
With Maven access, `testing/functions/testSvgConversion.cfm` additionally
checks PNG dimensions, scaling, transparency, paths containing spaces, and failure
handling. It regenerates the example PNG in `testing/_output`.

The original experiments disabled the main font rule, relied on the HTML page's
CSS, used `:first-of-type` for suit coloring, and compensated for spaced cards
with negative word spacing. Their fixed 240-unit canvas could clip hands. The
new examples instead embed explicit font properties, color suit spans directly,
and size the canvas from the formatted holdings.
