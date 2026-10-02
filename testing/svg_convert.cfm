<!---
Convert the standalone SVG example to PNG using Apache Batik.
Lucee resolves Batik and its dependencies from Maven using per-object settings.
See docs/svg-export.md for font registration. No external executable is required.
--->

<cfscript>
exampleDirectory = getDirectoryFromPath(getCurrentTemplatePath());
svgPath = exampleDirectory & "svg_test.svg";
pngPath = exampleDirectory & "_output/output.png";
// Supply application font files here when the selected SVG fonts are not installed.
// Example: [expandPath("../assets/fonts/MyCards.ttf"), expandPath("../assets/fonts/MySymbols.ttf")]
fontFiles = [];
svgToPng(svgPath=svgPath, pngPath=pngPath, fontFiles=fontFiles);

/** Convert at intrinsic SVG size, or set width to a target pixel width. */
boolean function svgToPng(required string svgPath, required string pngPath, numeric width=0, array fontFiles=[]) localmode=true {
    if (!fileExists(arguments.svgPath)) {
        throw(type="FileNotFoundException", message="SVG file not found: " & arguments.svgPath);
    }
    if (arguments.width < 0) {
        throw(type="bridge.svgConversion", message="PNG width must be zero (intrinsic size) or positive");
    }

    batikSettings = {
        maven: [
            {groupId:"org.apache.xmlgraphics", artifactId:"batik-transcoder", version:"1.19"},
            {groupId:"org.apache.xmlgraphics", artifactId:"batik-codec", version:"1.19"}
        ]
    };

    // Register fonts before Batik initializes its font resolver. Registration is
    // JVM-wide; CSS must use the font's internal family name, not its filename.
    graphics = createObject("java", "java.awt.GraphicsEnvironment").getLocalGraphicsEnvironment();
    fontClass = createObject("java", "java.awt.Font");
    fontRules = [];
    for (fontPath in arguments.fontFiles) {
        if (!fileExists(fontPath))
            throw(type="FileNotFoundException", message="Font file not found: " & fontPath);
        fontFile = createObject("java", "java.io.File").init(fontPath);
        font = fontClass.createFont(fontClass.TRUETYPE_FONT, fontFile);
        graphics.registerFont(font);
        family = replace(replace(font.getFamily(), chr(92), chr(92) & chr(92), "all"), '"', chr(92) & '"', "all");
        fontURI = replace(fontFile.toURI().toASCIIString(), '"', "%22", "all");
        fontRules.append('@font-face { font-family: "' & family & '"; src: url("' & fontURI & '"); }');
    }

    transcoder = createObject("java", "org.apache.batik.transcoder.image.PNGTranscoder", batikSettings).init();
    if (arguments.width > 0) {
        transcoder.addTranscodingHint(transcoder.KEY_WIDTH,
            createObject("java", "java.lang.Float").valueOf(javacast("string", arguments.width)));
    }
    // A file URI handles spaces and gives Batik a base URI for relative resources.
    source = createObject("java", "java.io.File").init(arguments.svgPath).toURI().toString();
    input = createObject("java", "org.apache.batik.transcoder.TranscoderInput", batikSettings).init(source);
    // Buffer the PNG so a failed transcode does not overwrite an existing output.
    bytes = createObject("java", "java.io.ByteArrayOutputStream").init();
    fontStylesheet = "";
    try {
        if (arrayLen(fontRules)) {
            // Batik caches installed families. Explicit font-face sources also work
            // when a new application font is supplied after an earlier conversion.
            fontStylesheet = getTempFile(getTempDirectory(), "bridge-batik-fonts", ".css");
            fileWrite(fontStylesheet, arrayToList(fontRules, chr(10)), "utf-8");
            stylesheetURI = createObject("java", "java.io.File").init(fontStylesheet).toURI().toString();
            transcoder.addTranscodingHint(transcoder.KEY_USER_STYLESHEET_URI, stylesheetURI);
        }
        output = createObject("java", "org.apache.batik.transcoder.TranscoderOutput", batikSettings).init(bytes);
        transcoder.transcode(input, output);
        fileWrite(arguments.pngPath, bytes.toByteArray());
    } finally {
        bytes.close();
        if (len(fontStylesheet) && fileExists(fontStylesheet)) fileDelete(fontStylesheet);
    }
    return true;
}
</cfscript>
