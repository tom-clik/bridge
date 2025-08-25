<!---

## Usage

Preview in browser

http://tpc25.clikpic.com/customtags/bridge/bridge_parser_test.cfm

--->

<cfscript>
coldsoupObj = new coldsoup.coldsoup();
bridge = new bridge.bridge_parser(jsoupObj=coldsoupObj);
logger = new logger.logger(debug=1);
bridge.loggerObj = logger;
path = getDirectoryFromPath(getCurrentTemplatePath());
</cfscript>

<cfsavecontent variable="bridgeHands">

<h2>Simple suit combo</h2>
<bridge id='simplesuitcombo' test=1>kq7 - A3 - 
</bridge>

<h2>Whole suit (start with W)</h2>
<bridge id="wholesuit" type="suit">
W:542 kq7 jt986 A3
</bridge>

<h2>Hand Vertical</h2>
<bridge id="hand_vertical" vertical>
	akq78.5634.kq7.7
</bridge>

<h2>Hand</h2>
<bridge id="hand" vertical=false>akq78.5634.kq7.7</bridge>

<h2>Simple hand</h2>
<bridge id="hand2">-.akq78.5634.kq75</bridge>

<h2>Full PBN</h2>
<bridge id="hand1_4" file="hands/test_hand2.pbn" info="yes" style="2_4" lead="yes" /> 


</cfsavecontent>

<cfscript>
data = coldsoupObj.parse(bridgeHands);
hands = data.select("bridge");
for (hand in hands) {
	html = bridge.bridgeTag(hand, path);
	writeOutput( htmlCodeFormat( html ) );
	hand.html(html).unwrap();
}
</cfscript>

<html>
<head>
	<title>Bridge parser samples</title>
	
	<link rel="stylesheet" href="/bridge/assets/css/bridge_styles.css">
	
</head>
<body>

<cfoutput>

#data.body().html()#

#logger.viewLog(category="bridge")#

</cfoutput>

</body>
</html>

