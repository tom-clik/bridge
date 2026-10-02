<!---
Optional ImageMagick conversion example. Requires `magick` on PATH and an SVG
renderer with CSS support (such as librsvg). See docs/svg-export.md for CairoSVG.
The generated SVG embeds its stylesheet; no HTML page or external CSS is needed.
--->

<cfscript>
svgPath = expandPath("svg_test.svg");

pngPath = expandPath("_output/output.png");

svgToPng(svgPath,pngPath);

// Convert an SVG file to PNG using ImageMagick
boolean function svgToPng(required string svgPath, required string pngPath, numeric density=300) localmode=true {
    if ( !fileExists(svgPath) ) {
        throw(type="FileNotFoundException", message="SVG file not found: " & svgPath);
    }

    // Build command array
    cmd = [
        "magick",
        "-background", "transparent",
        "-density", density,
        svgPath,
        pngPath
    ];

    // Start process
    pb = createObject("java", "java.lang.ProcessBuilder").init(cmd);
    pb.redirectErrorStream(true);
    process = pb.start();

    // Capture output (optional)
    reader = createObject("java", "java.io.BufferedReader").init(createObject("java", "java.io.InputStreamReader").init(process.getInputStream()));
    line = "";
    while ((nextLine = reader.readLine()) != javacast("null", "")) {
        line &= nextLine & chr(10);
    }
    reader.close();

    // Wait for completion
    exitCode = process.waitFor();
    if (exitCode != 0 || !fileExists(pngPath)) {
        throw(type="bridge.svgConversion", message="ImageMagick SVG conversion failed", detail=line);
    }
    return true;
}

</cfscript>
