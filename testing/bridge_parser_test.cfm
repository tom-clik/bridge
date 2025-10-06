<!---

## Usage

Preview in browser

http://tpc25.clikpic.com/customtags/bridge/bridge_parser_test.cfm

--->

<cfscript>
coldsoupObj = new coldsoup.coldsoup(server.system.environment.javalib & "\jsoup-1.20.1.jar");
bridge = new bridge.bridge_parser(jsoupObj=coldsoupObj);
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

<bridge positions="1">
[West "~~v3fakebot"]
[North "~~v3fakebot"]
[East "~~v3fakebot"]
[South "tompeer"]
[Dealer "W"]
[Vulnerable "Both"]
[Deal "S:K.AQ92.AQ732.JT9 764.84.K4.AKQ743 QJT982.KJ.J86.86 A53.T7653.T95.52"]
[Declarer "N"]
[Contract "2C"]
[Auction "W"]
1C =1= 1S =2= P P
2C =3= P P P
[Note "1:Minor suit opening -- 3  !C; 11-21 HCP; 12-22 total points"]
[Note "2:One-level overcall -- 5  !S; 8-17 HCP; 9-19 total points"]
[Note "3:6  !C; 21- HCP; 15-22 total points"]
[Play_order]
C8 C5 C9 CA
CK C6 C2 CT
CQ S2 H3 CJ
C7 D6 H5 D2
C3 SQ S3 D3
S7 S8 SA SK
D5 D7 D4 D8
SJ S5 H2 S6
ST H6 H9 S4
S9 H7 DQ H8
DJ D9 DA DK
HA H4 HJ HT
HQ C4 HK DT
</bridge>

<!--- <h2>Notes</h2>
<bridge style="0_2" north="Partner" south="You">
[auction]
2♣ - 2♦ =1= - 
2♠ - 3♠ =2= - 
?
[note "1:waiting"]
[note "2:positive"]	  
</bridge> --->

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

#logger.viewLog()#

</cfoutput>

</body>
</html>

