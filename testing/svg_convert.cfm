<!---
Convert SVG using Batik or ImageMagick

Both very unsatisfactoy. Can't use <style> attribute and our attempts
at inline the styling didn't work very well

Need a different solution for automated digram production
--->

<cfscript>
svgPath = expandPath("svg_test.svg");

pngPath = expandPath("_output/output.png");

svgToPng(svgPath,pngPath);

/*
svgTranscoder = createObject("java", "org.apache.batik.transcoder.image.PNGTranscoder");
input = createObject("java", "org.apache.batik.transcoder.TranscoderInput").init(createObject("java", "java.io.FileInputStream").init(svgPath));
output = createObject("java", "org.apache.batik.transcoder.TranscoderOutput").init(createObject("java", "java.io.FileOutputStream").init(pngPath));

svgTranscoder.transcode(input, output);
*/

// Convert an SVG file to PNG using ImageMagick
boolean function svgToPng(required string svgPath, required string pngPath, numeric density=300) localmode=true {
    if ( !fileExists(svgPath) ) {
        throw(type="FileNotFoundException", message="SVG file not found: " & svgPath);
    }

    // Build command array
    cmd = [
        "C:/Program Files/ImageMagick-7.1.2-Q16-HDRI/magick",
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
    process.waitFor();

    // Return true if PNG created
    return fileExists(pngPath);
}

</cfscript>
