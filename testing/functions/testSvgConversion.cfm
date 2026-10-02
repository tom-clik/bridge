<!--- Requires Maven-enabled Lucee; dependencies resolve through svg_convert.cfm. --->
<cfinclude template="../svg_convert.cfm">
<cfscript>
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    checks++;
    if (!condition) failures.append(message);
}
imageIO = createObject("java", "javax.imageio.ImageIO");
fileClass = createObject("java", "java.io.File");
svg = xmlParse(fileRead(svgPath));
png = imageIO.read(fileClass.init(pngPath));
check(png.getWidth() == int(val(svg.svg.xmlAttributes.width) + 0.5), "Intrinsic PNG width");
check(png.getHeight() == int(val(svg.svg.xmlAttributes.height) + 0.5), "Intrinsic PNG height");
check(png.getColorModel().hasAlpha(), "Transparent PNG output");
folder = getTempDirectory() & "bridge batik " & createUUID() & "/";
directoryCreate(folder);
try {
    source = folder & "test diagram.svg";
    target = folder & "test diagram.png";
    fileCopy(svgPath, source);
    check(svgToPng(source, target, 1200), "Conversion with spaces in file paths");
    png = imageIO.read(fileClass.init(target));
    check(png.getWidth() == 1200, "Requested pixel width");
    expectedHeight = 1200 * val(svg.svg.xmlAttributes.height) / val(svg.svg.xmlAttributes.width);
    check(abs(png.getHeight() - expectedHeight) <= 1, "Aspect ratio preserved");
    rejected = false;
    try { svgToPng(svgPath=source, pngPath=target, fontFiles=[folder & "missing.ttf"]); }
    catch (FileNotFoundException e) { rejected = true; }
    check(rejected, "Missing requested font raises an error");
    badFont = folder & "invalid.ttf";
    fileWrite(badFont, "not a font");
    rejected = false;
    try { svgToPng(svgPath=source, pngPath=target, fontFiles=[badFont]); }
    catch (any e) { rejected = true; }
    check(rejected, "Invalid font file raises an error");
    // Pixel-level regression: layout formulas alone missed negative word spacing.
    parser = createObject("component", "bridge.bridge_parser");
    compactSvg = parser.exportSvg("N:A.K.Q.J A.K.Q.J A.K.Q.J AKQJT98765432...",
        {handGap:"18", columnGap:"6", wordSpacing:"-4", suitGap:"12", rowSpacing:"16"});
    fileWrite(source, compactSvg, "utf-8");
    compactXml = xmlParse(compactSvg);
    scale = 4;
    svgToPng(source, target, val(compactXml.svg.xmlAttributes.width) * scale);
    png = imageIO.read(fileClass.init(target));
    rose = xmlSearch(compactXml, "//*[local-name()='rect']")[1];
    west = xmlSearch(compactXml, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-w']/*")[1];
    roseX = val(rose.xmlAttributes.x);
    baseline = val(west.xmlAttributes.y);
    rightmost = 0;
    for (py = int((baseline - 14) * scale); py < int((baseline + 2) * scale); py++) {
        for (px = int(west.xmlAttributes.x * scale); px < int((roseX - 2) * scale); px++) {
            if (bitAnd(png.getRGB(javacast("int", px), javacast("int", py)), -16777216) != 0)
                rightmost = max(rightmost, px + 1);
        }
    }
    visibleGap = roseX - 0.5 - rightmost / scale;
    check(rightmost > 0 && abs(visibleGap - 24) <= 2,
        "Batik West-to-rose gap with negative word spacing: " & visibleGap);
    leftmost = png.getWidth();
    roseRight = roseX + val(rose.xmlAttributes.width) + 0.5;
    for (py = int((baseline - 14) * scale); py < int((baseline + 3 * 16 + 3) * scale); py++) {
        for (px = int((roseRight + 2) * scale); px < png.getWidth(); px++) {
            if (bitAnd(png.getRGB(javacast("int", px), javacast("int", py)), -16777216) != 0)
                leftmost = min(leftmost, px);
        }
    }
    eastGap = leftmost / scale - roseRight;
    check(leftmost < png.getWidth() && abs(eastGap - 24) <= 2,
        "Batik rose-to-East painted gap: " & eastGap);
    check(abs(visibleGap - eastGap) <= 2, "Monospace model keeps both visible gaps within glyph bearing tolerance");
    previous = hash(fileReadBinary(target));
    fileWrite(source, "<svg>malformed", "utf-8");
    rejected = false;
    try { svgToPng(source, target); } catch (any e) { rejected = true; }
    check(rejected, "Malformed SVG raises an error");
    check(hash(fileReadBinary(target)) == previous, "Failed conversion preserves existing PNG");
    rejected = false;
    try { svgToPng(folder & "missing.svg", target); } catch (FileNotFoundException e) { rejected = true; }
    check(rejected, "Missing SVG raises an error");
    rejected = false;
    try { svgToPng(svgPath, target, -1); } catch (bridge.svgConversion e) { rejected = true; }
    check(rejected, "Negative output width rejected");
} finally {
    directoryDelete(folder, true);
}
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
