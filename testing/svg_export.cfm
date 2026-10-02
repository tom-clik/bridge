<!--- Live example: the same exporter used to generate svg_test.svg. --->
<cfscript>
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
parser = new bridge.bridge_parser(jsoupObj=soup);
svg = parser.exportSvg('N:A42.965.K9.Q9742 76.JT87.T8532.AK JT5.AKQ.AJ4.T853 KQ98345555567.432.Q76.J6',{
	handGap: "10",
    columnGap: "6",
    wordSpacing: "-4",
	suitGap:"4",
	rowSpacing: "2"
});
exampleDirectory = getDirectoryFromPath(getCurrentTemplatePath());
fileWrite(exampleDirectory & "svg_sample.svg", svg, "utf-8");
fileWrite(exampleDirectory & "svg_sample_inline.svg", parser.exportSvg("AKQJT98765432..."), "utf-8");
cfcontent(type="image/svg+xml; charset=utf-8", reset=true);
writeOutput(svg);
</cfscript>
