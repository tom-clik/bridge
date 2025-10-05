/*

# bridge parser

Parse bridge hands from <bridge> tags

See docs for information regarding hand format and diagram settings

## Usage

Pass in a jsoup node and (if using external files a basepath)

Returns HTML for hand, suit combo, or deal diagram

*/

component {

	public function init(required jsoupObj) {
		variables.jsoupObj = arguments.jsoupObj; 
		return this;
	}

	/**
	 * Parse a JSOUP node into text and attributes and call parseBridgeData
	 * 
	 * @node      Jsoup node 
	 * @basepath  Base path if using external files
	 */
	string function bridgeTag(required node, basepath="") {
		
		if ( arguments.basepath != "" && right(arguments.basepath,1) != "/" ) {
			arguments.basepath &= "/";
		}
		local.class = arguments.node.attr("class");

		local.tagAtts = variables.jsoupObj.getAttributes(arguments.node);
		if (local.class != "") {
			local.tagAtts["class"] = local.class;
		}

		if ( StructKeyExists(local.tagAtts,"file") ) {
			try {
				// if ( Left(local.tagAtts.file,4) == "http" ) {
				//     local.tagAtts.file = arguments.basepath & local.tagAtts.file;
				// }
				local.tagContents = FileRead( getCanonicalPath( arguments.basepath & local.tagAtts.file) );
			} 
			catch (filemissing cfcatch) {
				return "<p class=""missinginclude"">**file #local.tagAtts.file# !found**</p>";
			}
		} else {
			local.tagContents = Trim(node.wholeText());
		}

		try {
			retVal = parseBridgeData(text=local.tagContents,styleAtts =local.tagAtts);
		}
		catch (any e) {
			local.extendedinfo = {"error"=e,"tagAtts"=local.tagAtts,"text"=local.tagContents};
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "Unable to parse #arguments.node.html()#:" & e.message, 
				detail       = e.detail  
			);
		}
		return retVal;
	}

	/**
	 * Get string for css class of bridge element from specified attributes
	 */
	private function getClasses(required struct styles) localmode="true" {
		
		// applied to all
		classes = {
			"hand"="bridgehand",
			"pbn" ="bridgefull",
			"suit"="bridgesuitcombo"
		}

		className = classes[arguments.styles.type] ? : "unknown";

		// user applied classes
		if (  arguments.styles.keyExists("class" ) ) {
			className = listAppend(className, arguments.styles.class, " ");
		}
		
		// apply classes from keywords 
		for (class in ['vertical','inline']) {
			if (arguments.styles.keyExists( class ) ) {
				if ( ! isBoolean(arguments.styles[class])  || arguments.styles[class] ) {
					className = listAppend(className, class, " ");
				}
			}

		}

		return className;

	}


	/**
	 * @hint populate settings from style shorthand
	 * 
	 * shorthand "style" attibute can be set which is:
	 *
	 * {Number of hands to show in deal}_{number of hands in auction}
	 *
	 * The numbers can be 0, 2, or 4. These will adjust "deal" and "auction" settings.
	 *
	 * `info` will set  “scoring”, “vulnerable”, and “dealer” to true
	 *
	 * 
	 * 
	 */
	private function parseStyleShortcuts(styles) {
		
		var style = false;
		var numsStr = false;
		var tag = false;
		var options = false;
		var tagList = false;
		var i = false;
		
		local.tagsTemp = ["hands","auction"];

		if (StructKeyExists(arguments.styles,'style')) {
			style = arguments.styles['style'];
			// # style = hands(_auction)(_info)
			// # where hands is 0, 2 or 4, auction is 0,2 or 4
			// # and info is 1,0 or all. auction and info default to 0
			
			numsStr = {};

			/* first Item is hands */
			numsStr['hands'] = ListFirst(arguments.styles.style,"_");
			/* second item is auction */
			if (ListLen(arguments.styles.style,"_") gt 1) {
				numsStr['auction'] = ListGetAt(arguments.styles.style,2,"_");
			}
			else {
				numsStr['auction'] = '0';
			}
			/* third item is info */
			if (ListLen(arguments.styles.style,"_") gt 2) {
				numsStr['info'] = ListGetAt(arguments.styles.style,3,"_");
			}
			else {
				numsStr['info'] = '0';
			}

			// #convert number to string value. 2 = ns, 4=nsew
			
			for (tag in local.tagsTemp) {
				
				if (numsStr[tag] == '2') {
					arguments.styles[tag] = 'ns';
				}
				else if (numsStr[tag] == '4') {
					arguments.styles[tag] = 'nsew';
				}
				else if (numsStr[tag] == '0') {
					arguments.styles[tag] = 0;
				}
				else {
					throw(message="Invalid value #numsStr[tag]# for style shortcut.",type="bridge");
				}
				// # add default info value only if not specified
				if (not StructKeyExists(arguments.styles,'info')) {
					styles['info'] = numsStr['info'];
				}
			}
		}

		// # info = boolean for basic tags, 'all' for full tags
		// # remember these will only show if the tag is defined.
		
		// list of all options
		options = ['dealer','scoring','vulnerable','lead','contract','result','par','players','positions'];

		// list of tags to turn on if not defined explicitly
		tagList = [];
		
		if (StructKeyExists(arguments.styles,'info')) {
			if (arguments.styles['info'] == 'all') {
				tagList = Duplicate(options);
			}
			else if (styles['info']) {
				tagList = ListToArray("#options[1]#,#options[2]#,#options[3]#");
			}
		}


		for (tag in options) {
			
			if (not StructKeyExists(arguments.styles,tag)) {
				arguments.styles[tag] = (ArrayFind(tagList,tag) AND 1);
			}
			else {
				try {
					arguments.styles[tag] = arguments.styles[tag] AND 1;
				}
				catch (any e) {
					arguments.styles[tag] = 0;
				}
			}
		}

		for (tag IN local.tagsTemp) {
			if (NOT StructKeyExists(arguments.styles,tag)) {
				styles[tag] = 'nsew';
			}
		}

		 // # show deal rose in middle? Default is yes with more than one hand to show
		if (NOT StructKeyExists(arguments.styles,'rose')) {
			arguments.styles['rose'] = (len(arguments.styles['hands']) gt 1);
		}
	 
	}

	// parse the full data

	private function parsePBN(text) {

		// line = re.compile();
		
		var rows = ListToArray(text,chr(10));
		var currenttag = "";
		var tagData = "";
		var tagText = "";
		var pbnData = {};
		var i = false;
		
		for (i=1;i lte ArrayLen(rows);i+=1) {
			row = Trim(rows[i]);
		   
			// # most tags are one-liners like [dealer ""]. In this case we just get the data,
			// # some though are multi lines like auction. If this is the case we append the
			// # line to the text of the previous tag. 

			if (REFind("\[\w+(\s+"".*?"")?\]",row)) {
				currenttag = Trim(ListFirst(row,"[]"""));    
				if (ListLen(row,"[]""") gt 1) {
					tagData = Trim(ListLast(row,"[]"""));
				} else {
					tagData = "";
				}

				if (tagData neq "" AND NOT ListFindNoCase("auction,play",currenttag)) {
					// # special case for notes -- we store an Array of structs with keys note and marker
					// e.g. [note "1:12-14"]
					if (currenttag == 'note') {
						if (not StructKeyExists(pbnData,'notes')) {
							pbnData['notes'] = ArrayNew(1);
						}
						note = {};
						note['marker'] = ListFirst(tagData,":");
						note['note'] = ListRest(tagData,":");
						ArrayAppend(pbnData['notes'],note);
					}
					else {
						pbnData[currenttag] = tagData;
					}
				}
			}
			else if (currenttag neq "") {
				if (StructKeyExists(pbnData,currenttag)) {
					pbnData[currenttag] &= chr(10) & row;
				}
				else {
					pbnData[currenttag] = row;
				}
			}
		}

		for (tag in pbnData) {
			if (tag == "auction") {
				pbnData[tag] = parseAuction(pbnData[tag]);
			}
			else if (tag == "deal") {
				pbnData[tag] = parseDealData(pbnData[tag]);
			}
		}
		
		return pbnData;
	}


	private function getScoringStr(str) {
		
		var retStr = false;

		if (str == "MP" or str == "MatchPoints") {
			retStr = "Matchpoints";
		}
		else if (str == "BAM") {
				retStr = "Board-A-Match";
		}
		else {
			retStr = str;
		}
		return retStr;
	}

	/* return customised text for the Vulnerability string
	The idea is that we'll parameterise this or have a settings file
	or something 

	Takes None, Love,All or Both and returns string configured qv

	*/
	private function getVulnerableStr(str) {
	   
		var retStr = false;

		if (arguments.str == "None" or arguments.str == "Love") {
			retStr = "Love All";
		}
		else if (arguments.str == "All" or arguments.str == "Both"){
			retStr = "Game all";
		}
		else {
			retStr = arguments.str & ' vulnerable';
		}

		return retStr;
	}

	private function positionLabel(str) {

		var retStr = false;

		if (arguments.str == 's'){
				retStr = 'South';
		}
		else if (arguments.str == 'n') {
			retStr = 'North';
		}
		else if (arguments.str == 'e') {
				retStr = 'East';
		}
		else if (arguments.str == 'w') {
			retStr = 'West';
		}

		return retStr;
	}


	private array function parseAuction(auctionStr) {
		
		arguments.auctionStr = replaceSymbols(arguments.auctionStr);
		
		var auctionData = [];
		var last_entry = 0;
		var note = false;
		var bid = false;
		var local = {};
		var i = false;

		local.bids = listToArray(arguments.auctionStr, " #chr(9)##chr(10)#");
		
		for (i=1;i lte ArrayLen(local.bids);i+=1) {
			entry = Trim(local.bids[i]);
			// # is it a note =1=,(1),[1]
			
			if (refind("[\=\[\(](.+?)[\=\]\)]",entry)) {
				if (last_entry eq 0) {
					throw(message="Note cannot be firstentry in auction",type="bridge");
				}
				auctionData[last_entry]['note'] = Trim(ListFirst(entry,"[\=("));
			}
			else {
				// # should parse flags here e.g. 2NT?? ?? = note v. questionable bid
				bid = {};
				bid['bid'] = entry;
				bid['note'] = '';
				bid['flage'] = '';
				last_entry += 1;
				ArrayAppend(auctionData,bid);
			}
		}

		return auctionData;

	}


	// #  
	// # replace symbol chars with suit chars
	// # ♠♥♦♣

	private function replaceSymbols(retStr) {
		
		arguments.retStr = replace(arguments.retStr,'♠','s',"all");
		arguments.retStr = replace(arguments.retStr,'♥','h',"all");
		arguments.retStr = replace(arguments.retStr,'♦','d',"all");
		arguments.retStr = replace(arguments.retStr,'♣','c',"all");

		return retStr;

	}


	/**
	 * parse a strin like "S:.63.AKQ987.A9732 A8654.KQ5.T.QJT6 J973.J98742.3.K4 KQT2.AT.J6542.85"
	 * into a four key struct (nsew) of bridge hands (also 4key struct -- see parseHand())
	 * The first position e.g. S: is optional, the default is south.
	 * 
	 * @dealStr [description]
	 */
	private function parseDealData(dealStr) {
		
		var startpos = false;
		var deal = false;
		var startpos = false;

		if (ListLen(arguments.dealStr,":") gt 1) {
			startpos = ListFirst(arguments.dealStr,":");
			deal = ListLast(arguments.dealStr,":");
		}
		else {
			startpos = 's';
			deal = arguments.dealStr;
		}

		deal = ListToArray(deal, " #chr(13)#");
		dealData ={};
		dealData['n']="";
		dealData['s']="";
		dealData['w']="";
		dealData['e']="";
		
		for (i = 1; i lte ArrayLen(deal); i+= 1){
			hand = deal[i];
			dealData[startpos] = parseHand(hand);
			startpos = getNextPosition(startpos);
		}

		return dealData;

	}

	private function parseHand(handStr) {
		
		var suits = false;
		var handData = {};

		retStr = tidyHand(arguments.handStr);

		/* old school might have 4 lines and an explicit type="hand" set */
		if (Trim(retStr) eq "-") {
			return handData;
		}
		else if (Find(".",retStr)) {
			if (Left(retStr,1) eq '.') {
				retStr = '-' & retStr;
			}

			if (Right(retStr,1) eq '.') {
				retStr = retStr & '-';
			}
			
			retStr  = replace(retStr,"..",".-.");
			
			suits = ListToArray(retStr,".");
		}
		else {
			suits = ListToArray(retStr,"#chr(10)#,#chr(13)#, ");
		}

		if (not ArrayLen(suits) == 4) {
			throw(message = 'Hand [#arguments.handStr#]only has ' & ArrayLen(suits) & ' suits',type="bridge");
		}
	   
		handData['s'] = suits[1];
		handData['h'] = suits[2];
		handData['d'] = suits[3];
		handData['c'] = suits[4];

		return handData;
	}

	private function tidyHand(handStr) {
		
		// # always work with T for 10 no matter what output option
		arguments.handStr = replace(arguments.handStr, "10","T");
		arguments.handStr = ucase(arguments.handStr);
		arguments.handStr = ReReplaceNoCase(arguments.handStr,"[♠♥♦♣SHDC]","","all");
		
		return arguments.handStr;
	}

	/*
	Given a position, get the next one s w e n
	*/
	private function getNextPosition(pos) {
			
		var posList = 'swne';
		var posFind = FindNoCase(arguments.pos,posList);
		if (posFind gt 0) {
			posFind += 1;
			if (posFind == len(posList) + 1) {
				posFind = 1;
			}
		}
		else {
			throw(message = 'Invalid bridge position ' & arguments.pos,type="bridge");
		}

		return Mid(posList,posFind,1);
	}

	/* The main function. Takes the PBN or shorthand data and the styles as a Struct
	Normally you call fnBridgeTag to parse this info from a tag and pass it to this function */

	private function parseBridgeData(text,styleAtts={}) {

		var options = false;
		var option = false;
		var retStr = false;
		var pbndata = false;
		var i = false;
		var label = false;

		parseStyleShortcuts(arguments.styleAtts);
		
		// if we have tags, it's a full PBN type
		if (ReFind("\[\w+.*?\]",arguments.text)) {
			arguments.styleAtts["type"] = "pbn";
		}

		// # short form options
		if (not StructKeyExists(arguments.styleAtts,'type')) {
			
			// First cope with legacy hand format
			arguments.text = reReplace(arguments.text, "\s*[♥♦♣]\s*", ".", "all");
			arguments.text = reReplace(arguments.text, "\s*♠\s*", "", "all");

			if (REFindNoCase("^\s*[AKQJTX\d\-]*\s+[AKQJTX\d\-]*\s+[AKQJTX\d\-]*\s+[AKQJTX\d\-]*\s*$",arguments.text)
				OR REFindNoCase("^\s*[AKQJTX\d\-]*\s+[AKQJTX\d\-]*\s*$",arguments.text)
				) {
				arguments.styleAtts["type"] = "suit";
			}

			// # 3. we have a single hand with dots
			//re.match(,text, re.IGNORECASE)
			else if (REFindNoCase("^\s*[AKQJTX\d\-]*\.[AKQJTX\d\-]*\.[AKQJTX\d\-]*\.[AKQJTX\d\-]*\s*$",arguments.text)) {
				arguments.styleAtts["type"] = "hand";
				// # inline true if it's one one line
				if (not StructKeyExists(arguments.styleAtts,'inline')) {
					if (find(chr(10),arguments.text)) {
						arguments.styleAtts["inline"] = False;
					}
					else {
						arguments.styleAtts["inline"] = True;
					}
				}
			}
			else {
				arguments.styleAtts["type"] = "unknown";
			}
		}

		var classes = getClasses(arguments.styleAtts);
		
		if (arguments.styleAtts["type"] == "pbn") {

			pbndata = parsePBN(text);
			retStr = '';
			
			options = ['dealer','scoring','vulnerable','lead','contract','result','par','players','positions'];
			
			for (i = 1; i lte ArrayLen(options); i+=1) {
				option = options[i];
				if (StructKeyExists(styleAtts,option) AND styleAtts[option] neq 0 and StructKeyExists(pbndata,option)) {
					if (option == 'dealer') {
						label = "Dealer " & positionLabel(pbndata[option]);
					}
					else if (option == 'scoring') {
						label = getScoringStr(pbndata[option]);
					}
					else if (option == 'vulnerable') {
						label = getVulnerableStr(pbndata[option]);
					}
					else {
						label = option & ' ' & pbndata[option];
					}
					retStr &= "<p class='" & option & "'>" & label & "</p>";
				}
			}

			if (retStr neq '') {
				retStr = "<div class='bridgeinfo'>" & retStr & '</div>';
			}

			if (arguments.styleAtts['hands'] neq '0') {
				retStr &= displayDeal(pbndata,arguments.styleAtts);
			}
			if (arguments.styleAtts['auction'] neq '0') {
				retStr &= displayAuction(pbndata,arguments.styleAtts);
			}
			
			retStr = "<div class='#classes#'>" & retStr & "</div>";
		}    
	 
		else if (styleAtts["type"] == "hand") {
			// default for inline is OFF unless turned on earlier
			// when using the short hand form
			if (NOT StructKeyExists(styleAtts,"inline")) {
				styleAtts["inline"] = 0;
			}
			local.hand = parseHand(text);
			retStr = displayHand(hand=local.hand, inline=styleAtts["inline"],standalone=true,classes=classes);

		}

		// # displayHand(hand)

		else if (styleAtts["type"] == "suit") {

			local.suit = parseSuitCombo(text);
			retStr = displaySuitCombo(suit=local.suit,standalone=true,classes=classes);
			
		}

		else {
			extendedinfo = {"textreplaced"=arguments.text};
			throw(message='Unknown type',type="bridge",extendedinfo=serializeJSON(extendedinfo));
		}

		retStr = replaceWhiteSpace(retStr);

		return retStr;
	}

	private function replaceWhiteSpace(inStr) {

		inStr = Replace(inStr,"\t",chr(9),"all");
		inStr = Replace(inStr,"\n",chr(10),"all");

		return  inStr;

	}

	// # Display a full deal using the pbndata
	private function displayDeal(pbndata,styleAtts) {

		var shortclass = false;
		var retStr = false;
		var hideclass = false;
		var roseStr = false;
		var player = false;
		var line = false;
		var i = false;
		var playerList = ['n','e','w','s'];
		var lines = false;


		// #need to let css know if there is no north
		if (NOT FindNoCase('n',arguments.styleAtts['hands'])) {
			shortclass = " short";
		}
		else {
			shortclass = "";
		}
			
		retStr = "<div class='bridgedeal#shortclass#'>\n";
		
		// # display dealrose in middle. 
		// # hide using css if not required so we keep its spacing
		
		if (NOT styleAtts['rose']) {
			hideclass = " hidden";
		}
		else {
			hideclass = "";
		}

		roseStr = "\t<div class='dealrose#hideclass#'>\n\t\t<div class='inner'>";

		for (i=1;i lte ArrayLen(playerList);i+=1) {
			position = playerList[i];
			roseStr &= "\t\t\t<div class='r#position#'>#ucase(position)#</div>";
		}

		roseStr &= "\t\t</div>\n\t</div>\n";

		logger("Display hands for #arguments.styleAtts['hands']#","i","bridge");

		// # display hands
		for (i=1;i lte ArrayLen(playerList);i+=1) {

			player = playerList[i];

			// # NS hands flow in normal position. EW are positioned absolutely
			// # we do the first three, then the deal rose, then south.

			if (findNoCase(player,arguments.styleAtts['hands'])) {
				retStr &= "\t<div class='dealhand " & player & "'>\n";
				mydeal = displayHand(pbndata['deal'][player],False);
				// # format source code nicely...

				lines = ListToArray(mydeal, chr(10));
				for (j=1;j lte ArrayLen(lines);j+=1){
					retStr &= "\t\t" & lines[j] & "\n";
				}

				retStr &= "\t</div>\n";
			}
			else {
				logger("#player# not found in hands","i","bridge");
			}

			// # add dealrose after w
			if (arguments.styleAtts['rose'] and player == "w") {
				retStr &= roseStr;
			}
		}

		retStr &= "\n</div>\n";

		return retStr;
	}


	// # Display a simple hand
	// # inline will output on same line

	private function displayHand(hand,boolean inline=false, boolean standalone=false, classes="") {

		var tag = false;
		var retStr = false;
		var i = false;
		var suit = false;
		var suitList = false;
		
		// display on one line
		if (NOT arguments.inline) {
			tag = "div";
		}
		else {
			tag = "span";
		}

		retStr = "<" & tag & " class='#arguments.classes#'>";
		
		suitList = ["s","h","d","c"];

		if (NOT IsStruct(arguments.hand)) {
			throw(message="hand is not struct",type="bridge");
		}

		for (i = 1;i lte ArrayLen(suitList);i+=1) {
			suit = suitList[i];
			retStr &= "<span class='suit " & suit & "'>" & getSymbol(suit) & "</span>";
			retStr &= "<span class='cards'>" & suitFormat(arguments.hand[suit]) & "</span>";
			if (NOT arguments.inline) {
				retStr &= "<br />\n";
			}
		}

		retStr &= "</" & tag & ">";

		return retStr;
	}

	// # getSymbol
	// # return actual symbol for suit

	private function getSymbol(suitChar) {

		var symbol = false;

		if (arguments.suitChar == "s") {
			symbol = '♠';
		}
		else if  (arguments.suitChar == "h") {
			symbol = '♥';
		}
		else if  (arguments.suitChar == "d") {
			symbol = '♦';
		}
		else if  (arguments.suitChar =="c") {
			symbol = '♣';
		}
		else {
			throw(message = 'Invalid suit char [' & arguments.suitChar & ']',type="bridge");
		}
		return symbol;
	}

	/**
	 * @hint Format a single suite for output
	 * 
	 * put 10's back in for ts and lowercase unknowns
	 * Add space between every letter
	 * 
	 * @suit  suit string without spaces
	 */
	private function suitFormat(string suit) {
		
		var retStr = "";
		var i = false;

		for (i = 1; i lte Len(arguments.suit); i+=1) {
			retStr &= Mid(arguments.suit, i, 1) & " ";
		}
		retStr = replace(retStr, "T","10");
		retStr = replace(retStr, "X","x");

		return trim(retStr);
	}

	// # displayAuction

	private function displayAuction(pbndata, styleAtts) {

		var retStr = false;
		var roomStyle = false;
		var player = false;
		var lenclass = false;
		var bidder = false;
		var rownum = false;
		var playerList = false;
		var i = false;
		var backList = false;
		var oddeven = false;
		var notestring = false;
		var note = false;
		var temp = false;

		// # default values
		// ## default dealer always south
		if (not StructKeyExists(arguments.pbndata,'dealer')) {
			arguments.pbndata['dealer'] = 's';
		}

		// # turn off display styles for not present data
		temp = {};
		temp['dealer']=1;
		temp['contract']=1;
		temp['scoring']=1;
		temp['vulnerable']=1;
		temp['result']=1;
		temp['par']=1;
		temp['lead']=1;
		for (tag in temp) {
			if (not StructKeyExists(arguments.pbndata,tag)) {
				arguments.styleAtts[tag] = 0;
			}
		}
		
		temp = [=];
		temp['north']="North";
		temp['east']="East";
		temp['south']="South";
		temp['west']="West";

		for (player in temp) {
			if (NOT StructKeyExists(arguments.pbndata,player) || arguments.styleAtts.positions) {
				arguments.pbndata["#player#"] = temp[player];
			}
		}

		if (not StructKeyExists(arguments.pbndata,'notes')) {
			arguments.pbndata['notes'] = ArrayNew(1);
		}
		
		// embryonic BW styling according to Room
		if ( StructKeyExists(arguments.pbndata,'room')) {
			 roomStyle = ' ' + arguments.pbndata['room'];
		}
		else {
			roomStyle = "";
		}
		
		// # generate a style to indicate how many columns we have
		if (len(arguments.styleAtts['auction']) lt 4) {
			lenclass = " size2";
		}
		else {
			lenclass = " size4";
		}

		retStr = "<div class='bridgeauction#roomStyle##lenclass#'>\n";
		retStr &= "\t<table class='auction'>\n";

		playerList = ['South','West','North','East'];

		// # Header rows with positions and/or names
		retStr &= "\t\t<thead>\n";
		
			retStr &= "\t\t\t<tr>";
			for (i=1; i lte ArrayLen(playerList); i += 1) {
				player = playerList[i];
				if (FindNoCase(left(player,1),arguments.styleAtts['auction'])) {
					retStr &= "<th  class='#player#'><div>#arguments.pbndata[player]#</div></th>";
				}
			}
			retStr &= "</tr>\n";
		
		retStr &= "\t\t</thead>\n";
		
		retStr &= "\t\t<tbody>\n";

		// # Start auction rows
		
		// How many rows do we need?
		// Add blank cells to start according to position and then 
		// count rows of 4

		// startoffset -- get from player list.
		startoffset = arrayFindNoCase(playerList, positionLabel(arguments.pbndata['dealer'])) - 1;
		
		bidCount = ArrayLen( arguments.pbndata['auction']) + startoffset;
		rowCount = Ceiling(bidCount  / 4 );

		// bidnum corresponds to the array position of the bid we want.
		bidNum = 1 - startoffset;

		bidder = "s";

		logger("startoffset is #startoffset#, #bidCount#, #rowCount#, #bidNum#");

		for (rownum = 1; rownum lte rowCount; rownum += 1) {

			// add class for odd and even rows
			if (rownum % 2 == 0) {
					oddeven = 'even';
			}
			else {
				oddeven = 'odd';
			}
			
			retStr &= "\t\t\t<tr class='#oddeven#'>\n\t\t\t\t";

			try{
				for (i=1; i lte 4; i += 1) {
					// may not be showing all cols -- sometimes just n and s
					if (FindNoCase(bidder,arguments.styleAtts['auction'])) {

						// bid or blank cell?
						if (bidNum gte 1 AND bidNum lte ArrayLen(arguments.pbndata['auction'])){
							bid = arguments.pbndata['auction'][bidNum];
							bidStr = formatBid(bid['bid']);
							// #add flag indicator for note if present
							if (bid['note'] neq "" AND noteInList(arguments.pbndata['notes'],bid['note'])) {
								bidStr &= "<span class='note'>(#bid['note']#)</span>";
							}
						}
						else {
							bidStr = "&nbsp;";
						}

						retStr &= "<td class='#bidder#'><div>#bidStr#</div></td>";
					}
					bidNum += 1;
					bidder = getNextPosition(bidder);
					
				}
			} 
            catch (any e) {
                local.extendedinfo = {"error"=e,pbndata=arguments.pbndata};
                throw(
                    extendedinfo = SerializeJSON(local.extendedinfo),
                    message      = "Can't display auction:" & e.message
                );
            }
			retStr &= "\n\t\t\t</tr>\n";
		}

		retStr &= "\t\t</tbody>\n\t</table>\n\n";

		// # Add list of notes in new table
		
		if (IsStruct(arguments.pbndata["notes"])) {
			throw(message="Notes are Struct??",type="bridge");
		}

		if (arraylen(arguments.pbndata["notes"])) {
			retStr &= "\t<table class='notes'>\n";
			
			for (i=1; i lte ArrayLen(arguments.pbndata['notes']); i += 1) {
				note = arguments.pbndata["notes"][i];
				retStr &= "\t\t<tr><td>(#note.marker#)</td><td>#note.note#</td></tr>\n";
			}

			retStr &= "\t</table>\n";
		}

		retStr &= "</div>\n";


		return retStr;
	}

	// # wrap suit symbol and replace p or ap with correct string
	private function formatBid(bidStr) {
		
		var bidMatch = false;
		var retStr = false;
		var suit = false;
		var num = false;

		arguments.bidStr = Trim(arguments.bidStr);

		bidMatch = rematchnocase("^\d[shcd].*$", arguments.bidStr);

		if (ArrayLen(bidMatch)) {
			num = left(arguments.bidStr,1);
			suit = lcase(mid(arguments.bidStr,2,1));
			retStr = "#num#<span class='suit #suit#'>" & getSymbol(suit) & "</span>";
			if (len( arguments.bidStr ) gt 2 ) {
				retStr &= right(arguments.bidStr, len(arguments.bidStr) - 2);
			}
		}
		else {
			retStr = ucase(bidStr);
		}
		
		retStr = replace(retStr,"AP","All pass");
		
		return retStr;
	}

	/* bit of a funny one. The notes in the Python version were an ordered dict. I changed them
	into an array of structs with keys "marker" and "note". The only problem is we need this to test 
	if a marker is defined */
	private function noteInList(arrNotes, marker) {
		var i = false;
		var retval = 0;
		for ( imarker in arguments.arrNotes ) {
			if (imarker.marker eq arguments.marker) {
				retval = 1;
				break;
			}
		}
		return retval;
	}


	// # Display a simple suit combo
	private function displaySuitCombo(required struct suit, string classes="") {
		
		var retStr = false;
		var standclass = "";
		var colspan = " colspan='2'";
		var noMiddle = false;

		// # ignore middle row if both void
		if (suit['w'] eq "-" and suit['e'] eq "-") {
		   noMiddle = true;
		   colspan = "";
		}

		retStr = "<table class='#arguments.classes#'>\n";    

		retStr &= "<tr><td class='n'#colspan#><span class='cards'>" & suitFormat(arguments.suit['n']) & "</span></td></tr>\n";
		
		// # ignore middle row if both void
		if (not noMiddle) {
			retStr &= "<tr><td class='w'><span class='cards'>" & suitFormat(arguments.suit['w']) & "</span></td>";
			retStr &= "<td class='e'><span class='cards'>" & suitFormat(arguments.suit['e']) & "</span></td></tr>\n";
		}

		retStr &= "<tr><td class='s'#colspan#><span class='cards'>" & suitFormat(arguments.suit['s']) & "</span></td></tr>\n";
		
		retStr &= "</table>";

		return retStr;
	}

	private function parseSuitCombo(dealStr) {
		
		var hasStartPos = false;
		var startpos = false;
		var deal = false;
		var dealData = false;
		var hand = false;
		var i = false;

		arguments.dealStr = tidyHand(arguments.dealStr);
		
		if (ListLen(arguments.dealStr,":") gt 1) {
			startpos = ListFirst(arguments.dealStr,":");
			deal = ListLast(arguments.dealStr,":");
		}
		else {
			startpos = 's';
			deal = arguments.dealStr;
		}
		
		deal = ListToArray(deal," #chr(9)#");
		
		dealData = {};
		dealData['n']="";
		dealData['s']="";
		dealData['w']="";
		dealData['e']="";

		
		for (i=1;i lte ArrayLen(deal);i+=1) {
			hand = deal[i];
			dealData[startpos] = hand;
			startpos = getNextPosition(startpos);
			// skip a place if we have just two entries
			if (ArrayLen(deal) eq 2) {
				startpos = getNextPosition(startpos);
			}
		}

		return dealData;
	}

	public void function logger(required text, type="I", category="") output=false {
		if (StructKeyExists(this,"loggerObj")) {
			this.loggerObj.log(argumentCollection = arguments);
		}
	}
}