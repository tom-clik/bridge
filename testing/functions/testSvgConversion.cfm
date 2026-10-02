<!--- Requires the Batik runtime dependencies described in docs/svg-export.md. --->
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
check(png.getWidth() == val(svg.svg.xmlAttributes.width), "Intrinsic PNG width");
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
