<!--- Run svg_export.cfm first to generate the two ignored input SVGs. --->
<cfscript>
exampleDirectory = getDirectoryFromPath(getCurrentTemplatePath());
parser = createObject("component", "bridge.bridge_parser");
outputs = parser.svgToPng(
    svgPath=[exampleDirectory & "svg_sample.svg", exampleDirectory & "svg_sample_inline.svg"],
    outputFolder=exampleDirectory & "_output/",
    stylesheetPath=exampleDirectory & "../assets/css/bridge_svg.css",
    fontFiles=[exampleDirectory & "../assets/fonts/dejavu-sans-mono/DejaVuSansMono.ttf",
        exampleDirectory & "../assets/fonts/dejavu-sans/DejaVuSans.ttf"]
);
for (pngPath in outputs)
    writeOutput('<img src="_output/' & encodeForHTMLAttribute(getFileFromPath(pngPath)) & '" alt="Converted bridge diagram">');
</cfscript>
