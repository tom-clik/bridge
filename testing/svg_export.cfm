<!--- Live example: the same exporter used to generate svg_test.svg. --->
<cfscript>
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
parser = new bridge.bridge_parser(jsoupObj=soup);


tests = {

	"sample": {
		
		"hand": "N:A42.965.K9.Q9742 76.JT87.T8532.AK JT5.AKQ.AJ4.T853 KQ98345555567.432.Q76.J6",
		"options": {
				"title": "4 hands",
				"handGap": "10",
			    "columnGap": "6",
			    "wordSpacing": "-4",
				"suitGap":"8",
				"rowSpacing": "2"
		}

	},
	"sample_inline": {
		"hand": "AKQJ109876543...",
		"options": {
				"title": "Simple hand",
				"handGap": "10",
			    "columnGap": "6",
			    "wordSpacing": "-4",
				"suitGap":"8",
				"rowSpacing": "2"
		}
	}

}

for (code in tests) {
	test = tests[code];
	svg = parser.exportSvg(test.hand,test.options);
	filepath = expandPath("svg_#code#.svg");
	fileWrite( filepath ,svg);
	WriteOutput("File written to #filepath#<br>");
}

WriteOutput("<p><a href='svg_test.cfm'>Preview</a></p>");

</cfscript>
