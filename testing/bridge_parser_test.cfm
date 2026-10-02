<!---

## Usage

Preview in browser

http://tpc25.clikpic.com/customtags/bridge/bridge_parser_test.cfm

--->

<cfscript>
bridge = new bridge.testing.bridgeTestObj();
logger = new logger.logger(debug=1);
bridge.loggerObj = logger;
path = getDirectoryFromPath(getCurrentTemplatePath());
</cfscript>

<cfscript>
bridgeHands = fileRead( expandPath( "hands/test_data.html") );
data = bridge.flexmark.coldsoupObj.parse(bridgeHands);
hands = data.select("bridge");
result = [=];
count = 1;
for (hand in hands) {
	id = hand.attr("id");
	if ( isNull(id) ) id = "hand_#count#";
	count++;
	
	data = {};
	data.title = hand.attr("title") ? : "Hand #count#";
	hand.removeAttr("title");
	hand.removeAttr("id");
	hand.removeAttr("href");
	data.raw = htmlCodeFormat( hand.outerHtml() );
	data.html = bridge.bridgeTag(hand, path);
	result["#id#"] = data;
}
</cfscript>

<html>
<head>
	<title>Bridge parser samples</title>
	
	<link rel="stylesheet" href="/bridge/assets/css/bridge_styles.css">
	
</head>
<body>

<cfscript>
loop collection=result key="id" value="val" {
	writeOutput("<div class='section'>");
	writeOutput("<h2>#val.title#</h2>");
	writeOutput("<pre>#val.raw#</raw>");
	writeOutput("<pre>#val.html#</raw>");	
	writeOutput("</div>");
}
writeOutput(logger.viewLog());
</cfscript>

</body>
</html>

