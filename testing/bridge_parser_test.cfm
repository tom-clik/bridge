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

<cfsavecontent variable="bridgeHands">
<!--- 
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
<bridge id="hand">akq78.5634.kq7.7</bridge>

<h2>Simple hand</h2>
<bridge id="hand2" class="standalone">-.akq78.5634.kq75</bridge>

<h2>Full PBN</h2>
<bridge id="hand1_4" file="hands/test_hand2.pbn" info="yes" style="2_4" lead="yes"></bridge> 
 --->
<!--- <bridge>
AKQJ1098765432...
</bridge>
 --->
<!--- <h2>Notes</h2>
<bridge style="0_2" north="Partner" south="You">
[auction]
2♣ - 2♦ =1= - 
2♠ - 3♠ =2= - 
?
[note "1:waiting"]
[note "2:positive"]	  
</bridge> --->                          

<!--- <bridge id="test" class="testclass" deal="S" auction="NS">
[Deal "S:JT3.9.AQ75.AT643"]
[South "Partner"]
[North "You"]
[Auction "S"]
1C P 2C
</bridge>
<bridge deal="S" auction="NS">
[Deal "S:JT3.9.AQ75.AT643"]
[South "Partner"]
[North "You"]
[Auction "S"]
1C P 2C
</bridge> --->

<bridge deal="EN">
[Dealer "S"]
[Vulnerable "EW"]
[Deal "S:aq2.t72.a53.aj74 kt765.q95.7.9862 j843.akj.k82.kq5 9.8643.qjt964.t3"]
[auction]
1nt p 4c p
4nt p 6nt ap
</bridge>

<bridge deal="wn">
[Dealer "S"]
[Vulnerable "EW"]
[Deal "S:aq2.t72.a53.aj74 kt765.q95.7.9862 j843.akj.k82.kq5 9.8643.qjt964.t3"]
[auction]
1nt p 4c p
4nt p 6nt ap
</bridge>

<bridge deal="S" auction="NS">
[Deal "S:976.AT9.KQ875.AK"]
[Auction "S"]
1D      P       2D
[South "Partner"]
[North "You"]
</bridge>

<bridge deal="S" auction="NS">
[Deal "S:92.87.AQ75.JT732"]
[South "Partner"]
[North "You"]
[Auction "S"]
1D  P  1NT
</bridge>

<bridge deal="EW">
[Deal "E:AKJT9872.A9.J.K5 -.-.-.- 3.KQJ873.T98.643 -.-.-.-"]
[Auction "E"]
4D =1=  p 4S =2= p p
[Note "1:shows 7+ strong spades and 8-9 tricks."]
[Note "2:is a signoff."]
[East "Opener"]
[West "Responder"]
[Dealer "N"]
</bridge>
<bridge style="4_0">
[Deal "S:.t.5. .q9.. .kj.. .8.j."]
</bridge>
</cfsavecontent>

<cfscript>
data = bridge.flexmark.coldsoupObj.parse(bridgeHands);
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

#logger.viewLog()#

</cfoutput>

</body>
</html>

