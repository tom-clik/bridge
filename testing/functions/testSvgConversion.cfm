<!--- Requires Maven-enabled Lucee; dependencies resolve through bridge_parser. --->
<cfscript>
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    checks++;
    if (!condition) failures.append(message);
}
parser = createObject("component", "bridge.bridge_parser");
exampleDirectory = getCanonicalPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../");
svgPath = exampleDirectory & "svg_test.svg";
cssPath = exampleDirectory & "../assets/css/bridge_svg.css";
folder = getTempDirectory() & "bridge batik " & createUUID() & "/";
directoryCreate(folder);
try {
outputs = parser.svgToPng(svgPath=svgPath, outputFolder=folder, stylesheetPath=cssPath);
pngPath = outputs[1];
check(arrayLen(outputs) == 1 && getFileFromPath(pngPath) == "svg_test.png", "Single input defaults to input basename with PNG extension");
imageIO = createObject("java", "javax.imageio.ImageIO");
fileClass = createObject("java", "java.io.File");
svg = xmlParse(fileRead(svgPath));
png = imageIO.read(fileClass.init(pngPath));
check(png.getWidth() == int(val(svg.svg.xmlAttributes.width) + 0.5), "Intrinsic PNG width");
check(png.getHeight() == int(val(svg.svg.xmlAttributes.height) + 0.5), "Intrinsic PNG height");
check(png.getColorModel().hasAlpha(), "Transparent PNG output");
check(arrayLen(xmlSearch(svg, "//*[local-name()='style']")) == 0, "Batik input contains no embedded CSS");
redPixels = 0;
for (py=0; py < png.getHeight(); py++) {
    for (px=0; px < png.getWidth(); px++) {
        color = png.getRGB(javacast("int", px), javacast("int", py));
        if (bitAnd(color, -16777216) != 0 && bitAnd(bitSHRN(color, 16), 255) > 100
            && bitAnd(bitSHRN(color, 8), 255) < 80 && bitAnd(color, 255) < 80) redPixels++;
    }
}
check(redPixels > 0, "External stylesheet colors hearts and diamonds red");
    source = folder & "test diagram.svg";
    target = folder & "test diagram.png";
    fileCopy(svgPath, source);
    check(arrayLen(parser.svgToPng(svgPath=source, outputFolder=folder, stylesheetPath=cssPath, outputName="test diagram.png", width=1200)) == 1, "Custom outputName and spaces in file paths");
    png = imageIO.read(fileClass.init(target));
    check(png.getWidth() == 1200, "Requested pixel width");
    expectedHeight = 1200 * val(svg.svg.xmlAttributes.height) / val(svg.svg.xmlAttributes.width);
    check(abs(png.getHeight() - expectedHeight) <= 1, "Aspect ratio preserved");
    rejected = false;
    try { parser.svgToPng(svgPath=source, outputFolder=folder, stylesheetPath=cssPath, outputName="test diagram.png", fontFiles=[folder & "missing.ttf"]); }
    catch (FileNotFoundException e) { rejected = true; }
    check(rejected, "Missing requested font raises an error");
    badFont = folder & "invalid.ttf";
    fileWrite(badFont, "not a font");
    rejected = false;
    try { parser.svgToPng(svgPath=source, outputFolder=folder, stylesheetPath=cssPath, outputName="test diagram.png", fontFiles=[badFont]); }
    catch (any e) { rejected = true; }
    check(rejected, "Invalid font file raises an error");
    // Pixel-level regression: layout formulas alone missed negative word spacing.
    compactSvg = parser.exportSvg("N:A.K.Q.J A.K.Q.J A.K.Q.J AKQJT98765432...",
        {handGap:"18", columnGap:"6", wordSpacing:"-4", suitGap:"12", rowSpacing:"16"});
    fileWrite(source, compactSvg, "utf-8");
    compactXml = xmlParse(compactSvg);
    expectedGap = 14 * 1233 / 2048 + 18 + 6;
    rowAdvance = 14 + 16;
    scale = 4;
    parser.svgToPng(svgPath=source, outputFolder=folder, stylesheetPath=cssPath, outputName="test diagram.png", width=val(compactXml.svg.xmlAttributes.width) * scale);
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
    check(rightmost > 0 && abs(visibleGap - expectedGap) <= 2,
        "Batik West-to-rose gap with negative word spacing: " & visibleGap);
    leftmost = png.getWidth();
    roseRight = roseX + val(rose.xmlAttributes.width) + 0.5;
    for (py = int((baseline - 14) * scale); py < int((baseline + 3 * rowAdvance + 3) * scale); py++) {
        for (px = int((roseRight + 2) * scale); px < png.getWidth(); px++) {
            if (bitAnd(png.getRGB(javacast("int", px), javacast("int", py)), -16777216) != 0)
                leftmost = min(leftmost, px);
        }
    }
    eastGap = leftmost / scale - roseRight;
    check(leftmost < png.getWidth() && abs(eastGap - expectedGap) <= 2,
        "Batik rose-to-East painted gap: " & eastGap);
    check(abs(visibleGap - eastGap) <= 2, "Monospace model keeps both visible gaps within glyph bearing tolerance");
    previous = hash(fileReadBinary(target));
    fileWrite(source, "<svg>malformed", "utf-8");
    rejected = false;
    try { parser.svgToPng(svgPath=source, outputFolder=folder, stylesheetPath=cssPath, outputName="test diagram.png"); } catch (any e) { rejected = true; }
    check(rejected, "Malformed SVG raises an error");
    check(hash(fileReadBinary(target)) == previous, "Failed conversion preserves existing PNG");
    rejected = false;
    try { parser.svgToPng(svgPath=folder & "missing.svg", outputFolder=folder, stylesheetPath=cssPath); } catch (FileNotFoundException e) { rejected = true; }
    check(rejected, "Missing SVG raises an error");
    rejected = false;
    try { parser.svgToPng(svgPath=svgPath, outputFolder=folder, stylesheetPath=cssPath, width=-1); } catch (bridge.svgConversion e) { rejected = true; }
    check(rejected, "Negative output width rejected");
    // Different intrinsic sizes catch leaked transcoder state and unreset buffers.
    a = folder & "batch one.svg";
    b = folder & "batch two.svg";
    fileWrite(a, parser.exportSvg("AKQ.JT9.876.543"), "utf-8");
    fileWrite(b, parser.exportSvg("N:A.K.Q.J A.K.Q.J A.K.Q.J AKQJT98765432..."), "utf-8");
    batch = parser.svgToPng(svgPath=[a,b], outputFolder=folder, stylesheetPath=cssPath);
    check(arrayLen(batch) == 2 && getFileFromPath(batch[1]) == "batch one.png"
        && getFileFromPath(batch[2]) == "batch two.png", "Batch preserves order and derives separate names");
    for (i=1; i <= 2; i++) {
        inputDoc = xmlParse(fileRead([a,b][i]));
        result = imageIO.read(fileClass.init(batch[i]));
        check(result.getWidth() == int(inputDoc.svg.xmlAttributes.width + 0.5)
            && result.getHeight() == int(inputDoc.svg.xmlAttributes.height + 0.5), "Independent intrinsic dimensions for batch item " & i);
    }
    scaled = parser.svgToPng(svgPath=[a,b], outputFolder=folder, stylesheetPath=cssPath, width=600);
    for (resultPath in scaled)
        check(imageIO.read(fileClass.init(resultPath)).getWidth() == 600, "Batch applies requested width to every input");
    untouchedFolder = folder & "preflight/";
    directoryCreate(untouchedFolder);
    rejected = false;
    try { parser.svgToPng(svgPath=[a,folder & "missing.svg"], outputFolder=untouchedFolder, stylesheetPath=cssPath); }
    catch (FileNotFoundException e) { rejected = true; }
    check(rejected && arrayLen(directoryList(untouchedFolder, false, "path")) == 0,
        "Missing later input is rejected before writing the first output");
    check(arrayLen(parser.svgToPng(svgPath=[], outputFolder=folder, stylesheetPath=cssPath)) == 0, "Empty batch returns no paths");
    renamed = parser.svgToPng(svgPath=[a], outputFolder=folder, stylesheetPath=cssPath, outputName="renamed");
    check(getFileFromPath(renamed[1]) == "renamed.png", "Single-item batch supports outputName and adds extension");
    for (bad in [
        {svgPath:[a,b],outputName:"same.png"},
        {svgPath:[a,a]},
        {svgPath:[a,folder & "missing.svg"]},
        {svgPath:a,outputName:"../outside.png"},
        {svgPath:a,stylesheetPath:folder & "missing.css"},
        {svgPath:a,outputFolder:folder & "missing/"}
    ]) {
        args = {outputFolder:folder, stylesheetPath:cssPath};
        structAppend(args,bad,true);
        rejected = false;
        try { parser.svgToPng(argumentCollection=args); } catch (any e) { rejected = true; }
        check(rejected, "Reject invalid batch/output configuration");
    }
    rejected = false;
    try { parser.svgToPng(svgPath=a, outputFolder=folder); } catch (any e) { rejected = true; }
    check(rejected, "stylesheetPath is required");
} finally {
    directoryDelete(folder, true);
}
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
