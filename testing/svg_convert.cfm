<!---
Convert the standalone SVG example to PNG using Apache Batik.
Install Batik and its runtime dependencies on the CFML Java classpath first;
see docs/svg-export.md. No external executable is required.
--->

<cfscript>
exampleDirectory = getDirectoryFromPath(getCurrentTemplatePath());
svgPath = exampleDirectory & "svg_test.svg";
pngPath = exampleDirectory & "_output/output.png";
svgToPng(svgPath, pngPath);

/** Convert at intrinsic SVG size, or set width to a target pixel width. */
boolean function svgToPng(required string svgPath, required string pngPath, numeric width=0) localmode=true {
    if (!fileExists(arguments.svgPath)) {
        throw(type="FileNotFoundException", message="SVG file not found: " & arguments.svgPath);
    }
    if (arguments.width < 0) {
        throw(type="bridge.svgConversion", message="PNG width must be zero (intrinsic size) or positive");
    }

    transcoder = createObject("java", "org.apache.batik.transcoder.image.PNGTranscoder").init();
    if (arguments.width > 0) {
        transcoder.addTranscodingHint(transcoder.KEY_WIDTH,
            createObject("java", "java.lang.Float").valueOf(javacast("string", arguments.width)));
    }
    // A file URI handles spaces and gives Batik a base URI for relative resources.
    source = createObject("java", "java.io.File").init(arguments.svgPath).toURI().toString();
    input = createObject("java", "org.apache.batik.transcoder.TranscoderInput").init(source);
    // Buffer the PNG so a failed transcode does not overwrite an existing output.
    bytes = createObject("java", "java.io.ByteArrayOutputStream").init();
    try {
        output = createObject("java", "org.apache.batik.transcoder.TranscoderOutput").init(bytes);
        transcoder.transcode(input, output);
        fileWrite(arguments.pngPath, bytes.toByteArray());
    } finally {
        bytes.close();
    }
    return true;
}
</cfscript>
