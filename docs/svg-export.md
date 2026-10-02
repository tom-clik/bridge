# SVG export

`bridge_parser.exportSvg(text, options={})` returns an SVG string without embedded CSS or font-loading declarations. Use an
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
    characterWidth: 8.4287109375, // Optional; derived from fontSize when omitted
    letterSpacing: 0,
    wordSpacing: -2,
    rowSpacing: 2,
    suitGap: 4,
    handGap: 10,
    columnGap: 16,
    padding: 12
});
```

| Option | Default | Meaning |
| --- | --- | --- |
| `fontSize` | 14 | Card and suit-symbol font size. |
| `characterWidth` | `fontSize × 1233 / 2048` | Monospace advance per character, including spaces and each digit of `10`, before letter/word spacing. |
| `letterSpacing` | 0 | Extra spacing per character, including between the digits of `10`. |
| `wordSpacing` | 0 | Extra spacing at the literal spaces between cards. Negative values tighten gaps. |
| `rowSpacing` | 2 | Extra vertical space: suit-row baselines are `fontSize + rowSpacing` apart. |
| `suitGap` | 4 | Extra horizontal space after one symbol cell: cards start `characterWidth + suitGap` after the suit origin. |
| `handGap` | 10 | Extra space between hands: horizontal offset uses `characterWidth + handGap`; the vertical gap after the last suit baseline uses `fontSize + handGap`. |
| `columnGap` | 12 | Additional E/W clearance beyond `characterWidth + handGap`. |
| `padding` | 12 | Space around the diagram. |

`fontSize` and `characterWidth` must be positive; all gap options, including zero, must be
nonnegative. `letterSpacing` and `wordSpacing` may be negative provided estimated
character advances remain positive. All values must be finite decimal numbers
with magnitude at most 1000. Invalid settings raise `bridge.svg` errors.

**Changed semantics:** `rowSpacing`, `suitGap`, and `handGap` are additional space,
not total distances. At 14px with the default character width, `{rowSpacing:2,
suitGap:4, handGap:10}` gives row baselines 16px apart, cards about 12.43px after
the suit origin, a horizontal hand offset of about 18.43px, and a vertical
inter-hand baseline gap of 24px (unless the compass needs a taller band).
To migrate an old total `rowSpacing` or `suitGap`, subtract `fontSize` or
`characterWidth`, respectively. For `handGap`, horizontal distances subtract
`characterWidth` and vertical distances subtract `fontSize`; the one shared
option now adds the same extra whitespace to each axis's natural cell size.

The rose stays centered in the canvas. North and South share a starting x-coordinate
exactly `characterWidth + handGap` left of the rose's left edge. East and West reserve equal widths,
using the longest displayed suit in either of those hands. The West hand is
right-aligned as a block within its column, leaving unused space on the left. Its
modeled text advance ends `characterWidth + handGap + columnGap` before the outside edge of
the rose stroke; East’s text starts the same distance after the opposite stroke
edge. Actual painted edges can differ slightly due to glyph side bearings. Longer outer suits expand both sides equally, leaving the
N/S-to-rose offset unchanged. Long N/S suits can add equal outer margins to prevent
clipping. Thus diagrams centered on a page keep their roses and N/S starts aligned
when using the same spacing options. Hiding the rose retains these horizontal anchors.

The canvas dimensions and vertical compass position are recalculated from these options.
Zero gap values retain the natural font-size/character-width spacing. Compact
bands also reserve space for the 56-unit compass when enabled. Symbols wider than
the assumed character cell may need additional `suitGap`. Width calculations assume a monospace card font and use:

`characters × characterWidth + (characters − 1) × letterSpacing + spaces × wordSpacing`

The DejaVu Sans Mono default is hardcoded from its 1233-unit advance and 2048-unit
em: `characterWidth = fontSize × 0.60205078125`. It works at arbitrary sizes,
including 10–24px; no lookup table, font file reading, or Java font inspection is
performed by the parser. An explicit `characterWidth` overrides this calculation
without changing the rendered font size. For another monospace font, set its
advance at the selected size. Negative spacing is included in layout calculations.
The layout also accounts for the rose’s 1-unit stroke.

Text options are inherited SVG presentation attributes on the root, so different
inline diagrams can use different values while sharing one page stylesheet.
The compass labels retain their own 12px font and normal spacing. Use these options
for sizing rather than changing font size in CSS, so layout can account for it.

## Styling and web use

SVGs contain geometry, classes, and configurable font/spacing presentation
attributes, but **no embedded stylesheet, font data, or font-loading declarations**.
Use them inline in a web page so page styles and web fonts apply:

```cfml
<link rel="stylesheet" href="/bridge/assets/css/bridge_svg.css">
<cfoutput>#parser.exportSvg(pbnText)#</cfoutput>
```

The shared stylesheet controls suit colors, the rose, and compass labels. Load
any web fonts in the HTML page's CSS. `testing/svg_test.html` demonstrates this
using ordinary font-file URLs and inlining fetched SVGs. Serve the example over
HTTP through the CFML server; a server-rendered page can output the SVG directly
without JavaScript. Do not use an `<img>` or `<object>` for these web diagrams:
those create separate documents that cannot inherit the host page's CSS.

Each SVG has explicit dimensions and a matching `viewBox`. There are no generated
IDs that can collide when several diagrams share a page. Page CSS can customize
`bridge-svg-*` classes. A raw SVG opened alone will lack diagram styling; use the
inline example for browser review or the Batik converter for a styled PNG.

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
resolve to Courier New on Windows. Font loading remains solely in the PNG
converter; the parser uses `characterWidth` and never reads font files.

For web pages, define `@font-face` in the **host page stylesheet**, using ordinary
font URLs or installed fonts as appropriate. No `local()` rules are included in
the SVG or shared diagram CSS. The demo loads the repository's DejaVu fonts from
normal URLs. Chrome DevTools **Computed → Rendered Fonts** shows which family
actually rendered the inline text.

## PNG conversion

Batik does not need CSS embedded in the SVG. It does need the diagram styling,
which the converter supplies externally using `KEY_USER_STYLESHEET_URI`. The
converter combines `assets/css/bridge_svg.css` with any font sources supplied to
`fontFiles` in a temporary stylesheet and deletes it after conversion. Other PNG
converters must likewise be supplied the shared stylesheet.

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
// Optional: stylesheetPath="/absolute/path/to/custom-diagram.css"
```

The destination directory must already exist and be writable. Batik consumes the
external shared stylesheet and uses installed or supplied fonts, with no external process. Conversion errors propagate to the caller; PNG bytes are
buffered before writing so failed transcoding does not replace an existing file.
Only pass trusted SVG files: Batik may resolve resources referenced by an SVG.

## Examples and verification

`testing/svg_export.cfm` serves a live export. `testing/svg_test.svg` is its full
deal output; `testing/svg_inline.svg` shows a long single hand.
`testing/svg_test.html` displays the live and saved diagrams inline with page-level fonts and CSS.
Run `testing/functions/testSvgExport.cfm` in the same CFML setup as the existing
parser tests; it returns JSON with assertion counts and failures.
With Maven access, `testing/functions/testSvgConversion.cfm` additionally
checks PNG dimensions, scaling, transparency, paths containing spaces, and failure
handling. It regenerates the example PNG in `testing/_output`.

The original experiments disabled the main font rule, relied on the HTML page's
CSS, used `:first-of-type` for suit coloring, and compensated for spaced cards
with negative word spacing. Their fixed 240-unit canvas could clip hands. The
new examples instead use explicit font properties, shared CSS for suit spans,
and size the canvas from the formatted holdings.
