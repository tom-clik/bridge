/*

# bridge parser

Parse bridge hands from <bridge> tags

See docs for information regarding hand format and diagram settings

## Usage

Pass in a jsoup node and (if using external files a basepath)

Returns HTML for hand, suit combo, or deal diagram

*/

component {

	public function init(required jsoupObj, boolean debug=0) {
		variables.jsoupObj = arguments.jsoupObj; 
		variables.playerList = ['n','e','w','s'];
		this.debug = arguments.debug;

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
		
		local.tagAtts = variables.jsoupObj.getAttributes(arguments.node);
		
		if ( StructKeyExists(local.tagAtts,"file") ) {
			try {
				local.tagContents = FileRead( getCanonicalPath( arguments.basepath & local.tagAtts.file) );
			} 
			catch (filemissing cfcatch) {
				return "<p class=""missinginclude"">**file #local.tagAtts.file# !found**</p>";
			}
		} else {
			local.tagContents = Trim(node.wholeText());
		}

		try {
			retVal = parseBridgeData(text=local.tagContents,styleAtts = local.tagAtts);
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
		
		className = "bridge";

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
	 */
	private function parseStyleShortcuts(required struct styles) localmode=true {
		
		compassTags = ["deal","auction"];

		if ( StructKeyExists(arguments.styles,'style') ) {
			style = ListToArray( arguments.styles['style'], "_" );
			
			// # style = deal(_auction)(_info)
			// # where deal is 0, 2 or 4, auction is 0,2 or 4
			// # and info is 1,0 or all. auction and info default to 0
			
			numsStr = {};

			/* first Item is deal */
			numsStr['deal'] = style[1];
			/* second item is auction */
			if ( style.len()  gt 1) {
				numsStr['auction'] = style[2];
			}
			else {
				numsStr['auction'] = '0';
			}
			/* third item is info */
			if (style.len()  gt 2) {
				arguments.styles['info'] = style[3];
			}
			else {
				arguments.styles['info'] = '0';
			}

			// #convert number to string value. 2 = ns, 4=nsew
			
			for (tag in compassTags) {
				
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

		else {
			StructAppend(arguments.styles, {"info"=false}, false);
		}

		// # info = boolean for basic tags, 'all' for full tags
		// # remember these will only show if the tag is defined.
		
		// list of all options
		options = ['dealer'=1,'scoring'=1,'vulnerable'=1,'lead'=0,'contract'=0,'result'=0,'par'=0,'players'=0,'positions'=0];

		// create list of tags to turn on if not defined explicitly
		tagList = [];
		
		// go through each option and check if it was supplied explicitly or by using info short cut
		loop collection=options key="tag" value="basic" {
			
			if ( StructKeyExists(arguments.styles, tag)) {
				arguments.styles[tag] = isValid("boolean",arguments.styles[tag]) ?  ( arguments.styles[tag] && true ) : 0;
			}
			else {
				arguments.styles[tag] = (arguments.styles['info'] eq "all" OR arguments.styles['info'] && basic );
			}
		}

		for (tag IN compassTags) {
			if (NOT StructKeyExists(arguments.styles,tag)) {
				styles[tag] = 'nsew';
			}
		}

		 // # show deal rose in middle? Default is yes with more than one hand to show
		if (NOT StructKeyExists(arguments.styles,'rose')) {
			arguments.styles['rose'] = (len(arguments.styles['deal']) gt 1);
		}
	 
	}

	/**
		@hint parse the full data 
		
		First loop over the text and create a struct keyed by main tag name

		Each value is another struct with key attibributes and text
		

	*/

	private function parsePBN(required string text) localmode=true {

		data = parseTaggedText(text);

		pbnData = {};
		currentTag = "";

		for ( tag in data ) {
			
			switch (tag.tag) {
				case "deal":
					pbnData["deal"] = parseDealData(tag.attributes);
					break;
				case "auction":
					if ( tag.attributes neq "")  {
						pbnData["dealer"] = tag.attributes;
					}
					pbnData["auction"] = parseAuction( tag.text );
					break;
				case "note":
					// ignore play notes for now
					if ( currentTag != "auction") continue;
					if (not StructKeyExists(pbnData,'notes')) {
						pbnData['notes'] = ArrayNew(1);
					}
					note = {};
					note['marker'] = ListFirst(tag.attributes,":");
					note['note'] = ListRest(tag.attributes,":");
					ArrayAppend(pbnData['notes'],note);
					break;
				default:
					pbnData[tag.tag] = tag.attributes;

			}

			currentTag = tag.tag;
		}
		
		return pbnData;
	}

	/**
	 * @hint Convert tagged text to array
	 *
	 * Values are struct with keys tag, attributes, and text
	 * Can't convert to struct as some keys are duplicate (e.g. note)
	 *
	 * Also note may belong to auction or play
	 * 
	 */
	
	array function parseTaggedText( required string input) {
	    var result = [];
	    var lenInput = len(arguments.input);

	    var i = 1;
	    var ch = "";

	    var inTag = false;
	    var inQuote = false;
	    var readingTagName = false;
	    var readingAttribute = false;

	    var currentTagName = "";
	    var currentAttributes = "";
	    var currentText = "";

	    var currentKey = "";

	    for (i = 1; i <= lenInput; i++) {
	        ch = mid(arguments.input, i, 1);

	        // Start of a new tag
	        if (!inTag && ch == "[") {
	            // Save previous tag before starting new one
	            if (len(currentKey)) {
	                result.append( {
	                    tag = currentKey,
	                    attributes = currentAttributes,
	                    text = trim(currentText)
	                });
	            }

	            // Reset state for new tag
	            inTag = true;
	            inQuote = false;
	            readingTagName = true;
	            readingAttribute = false;

	            currentTagName = "";
	            currentAttributes = "";
	            currentText = "";
	            currentKey = "";

	            continue;
	        }

	        if (inTag) {
	            // End of tag
	            if (!inQuote && ch == "]") {
	                inTag = false;
	                readingTagName = false;
	                readingAttribute = false;

	                currentKey = lCase( currentTagName );
	                continue;
	            }

	            // Quote handling for attributes
	            if (ch == '"') {
	                inQuote = !inQuote;

	                if (inQuote) {
	                    readingTagName = false;
	                    readingAttribute = true;
	                }
	                else {
	                    readingAttribute = false;
	                }

	                continue;
	            }

	            // Build tag name until first space or quote
	            if (readingTagName) {
	                if (ch != " " && ch != chr(9) && ch != chr(10) && ch != chr(13)) {
	                    currentTagName &= ch;
	                }
	                continue;
	            }

	            // Build attribute text only while inside quotes
	            if (readingAttribute && inQuote) {
	                currentAttributes &= ch;
	                continue;
	            }

	            continue;
	        }

	        // Outside tag, this belongs to current tag's text
	        if (len(currentKey)) {
	            currentText &= ch;
	        }
	    }

	    // Save the final tag
	    if (len(currentKey)) {
	        result.append( {
	            tag = currentKey,
	            attributes = currentAttributes,
	            text = trim(currentText)
	        });
	    }

	    return result;
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
	 * parse a string like "S:.63.AKQ987.A9732 A8654.KQ5.T.QJT6 J973.J98742.3.K4 KQT2.AT.J6542.85"
	 * into a four key struct (nsew) of bridge hands (also a 4 key struct -- see parseHand())
	 * The first position e.g. S: is optional, the default is south.
	 * 
	 * @dealStr [description]
	 */
	private function parseDealData(required string dealStr) localmode=true {
		
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
		dealData['n']={"s"="-","h"="-","d"="-","c"="-"};
		dealData['s']={"s"="-","h"="-","d"="-","c"="-"};
		dealData['w']={"s"="-","h"="-","d"="-","c"="-"};
		dealData['e']={"s"="-","h"="-","d"="-","c"="-"};
		
		for (hand in deal){
			if ( Trim(hand) neq "-" ) {
				dealData[startpos] = parseHand(hand);
			}
			startpos = getNextPosition(startpos);
		}

		return dealData;

	}

	private function parseHand(required string text) {
		
		var suits = false;
		var handData = {};

		retStr = tidyHand(text=arguments.text);

		if (Left(retStr,1) eq '.') {
			retStr = '-' & retStr;
		}

		if (Right(retStr,1) eq '.') {
			retStr = retStr & '-';
		}
		
		retStr  = replace(retStr,"..",".-.");
		
		suits = ListToArray(retStr,".");
		
		if (not ArrayLen(suits) == 4) {
			throw(message = 'Hand [#arguments.text#]only has ' & ArrayLen(suits) & ' suits',type="bridge");
		}
	   
		handData['s'] = suits[1];
		handData['h'] = suits[2];
		handData['d'] = suits[3];
		handData['c'] = suits[4];

		return handData;
	}

	private function tidyHand(required string text) {
		
		// # always work with T for 10 no matter what output option
		arguments.text = replace(arguments.text, "10","T");
		arguments.text = ucase(arguments.text);
		arguments.text = ReReplaceNoCase(arguments.text,"[♠♥♦♣SHDC]","","all");
		
		return arguments.text;
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

	private function parseBridgeData(text,styleAtts={}) localmode=true {

		parseStyleShortcuts(arguments.styleAtts);

		// if we have tags, it's a full PBN type
		if (ReFind("\[\w+.*?\]",arguments.text)) {
			arguments.styleAtts["type"] = "pbn";
		}

		// # short form options
		if (not StructKeyExists(arguments.styleAtts,'type')) {
			
			arguments.text =  checkHandType( text=arguments.text, styleAtts=arguments.styleAtts);
			
		}

		var classes = getClasses(arguments.styleAtts);
		
		if (arguments.styleAtts["type"] == "pbn") {

			pbndata = parsePBN(text);
			
			retStr = '';
			
			options = ['dealer','scoring','vulnerable','lead','contract','result','par','players','positions'];
			
			for (option in options) {
				
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

			if (arguments.styleAtts['deal'] neq '0') {
				retStr &= displayDeal(pbndata,arguments.styleAtts);
			}
			if (arguments.styleAtts['auction'] neq '0') {
				retStr &= displayAuction(pbndata,arguments.styleAtts);
			}
			
		}    
	 
		else if (styleAtts["type"] == "hand") {
			local.hand = parseHand(text=arguments.text);
			retStr = displayHand(hand=local.hand);
		}

		// # displayHand(hand)
		else if (styleAtts["type"] == "suit") {
			local.suit = parseSuitCombo(text);
			retStr = displaySuitCombo(suit=local.suit);
		}

		else {
			extendedinfo = {"textreplaced"=arguments.text};
			throw(message='Unknown type',type="bridge",extendedinfo=serializeJSON(extendedinfo));
		}

		id = arguments.styleAtts.keyExists("id") ? "id=#arguments.styleAtts.id# " : "";

		retStr = "<div #id#class='#classes#'>" & retStr & "</div>";
		
		return retStr;
	}

	/**
	 * Deduce the type from the text either simple hand, simple suit combo, or full deal for anything else
	 *
	 * Checks the text and returns cleaned copy.
	 */
	private string function checkHandType(required text, required struct styleAtts) {

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

		return arguments.text;
	}

	// # Display a full deal using the pbndata
	private function displayDeal(pbndata, styleAtts) localmode=true {

		tab = this.debug ? chr(9) : "";
		cr = this.debug ? newLine() : "";

		logger("Display hands for #arguments.styleAtts['deal']#","i","bridge");

		// # display hands
		handsHtml = {};
		for (player in variables.playerList) {
			// TODO: better logic. Need space for E or W if we are showing one of them and also a N or S
			// May well be better to canonicalise the "deal" and add all the permutations to CSS
			show = findNoCase(player,arguments.styleAtts['deal']) ? "" : " hide";
			handsHtml[player] = "#tab#<div class='dealhand " & player & show & "'>#cr#";
			handsHtml[player] &= displayHand( pbndata['deal'][player] );
			handsHtml[player] &= "#tab#</div>#cr#";
			
		}

		rosehtml = styleAtts.rose ? dealRose() : "";

		retStr = "<div class='bridgedeal'>#cr#";
		retStr &= "#tab#<div class='dealrow deal-top'>#handsHtml.n#</div>#cr#";
		retStr &= "#tab#<div class='dealrow deal-middle'>#handsHtml.w##rosehtml##handsHtml.e#</div>#cr#";
		retStr &= "#tab#<div class='dealrow deal-top'>#handsHtml.s#</div>#cr#";
		retStr &= "#cr#</div>#cr#";

		return retStr;
	}

	// Display a hand
	private function displayHand(hand) localmode=true {

		retStr = "<span class='bridgehand'>";
		
		suitList = ["s","h","d","c"];

		if (NOT IsStruct(arguments.hand)) {
			throw(message="hand is not struct",type="bridge");
		}

		for (suit in suitList) {
			retStr &= "<span class='suit " & suit & "'>" & getSymbol(suit) & "</span>";
			retStr &= "<span class='cards'>" & suitFormat(arguments.hand[suit]) & "</span>";
		}

		retStr &= "</span>";

		return retStr;
	}

	private string function dealRose() localmode=true {
		
		tab = this.debug ? chr(9) : "";
		cr = this.debug ? newLine() : "";

		roseStr = "#tab#<div class='dealrose'>#cr##tab##tab#<div class='inner'>";

		for (position in variables.playerList) {
			roseStr &= "#tab##tab##tab#<div class='r#position#'>#ucase(position)#</div>";
		}

		roseStr &= "#tab##tab#</div>#cr##tab#</div>#cr#";
		return roseStr
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
	 * @hint Format a single suit for output
	 * 
	 * Becuase we us 10, we can't use letter spacing and have to use word-spacing
	* 
	 * @suit  suit string without spaces
	 */
	private function suitFormat(string suit) localmode=true {
		
		arguments.suit = trim( arguments.suit );
		text = [];
		for (i=1; i <= arguments.suit.len(); i++) {
			text.append( mid( arguments.suit,i,1 ) );
		}
		text = text.toList(" ");

		text = replace(text, "T","10");
		text = replace(text, "X","x");

		return text;
	}

	// # displayAuction

	private function displayAuction(pbndata, styleAtts) localmode=true {

		tab = this.debug ? chr(9) : "";
		cr = this.debug ? newLine() : "";

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

		retStr = "<div class='bridgeauction#roomStyle##lenclass#'>#cr#";
		retStr &= "#tab#<table class='auction'>#cr#";

		playerList = ['South','West','North','East'];

		// # Header rows with positions and/or names
		retStr &= "#tab##tab#<thead>#cr#";
		
			retStr &= "#tab##tab##tab#<tr>";
			for (i=1; i lte ArrayLen(playerList); i += 1) {
				player = playerList[i];
				if (FindNoCase(left(player,1),arguments.styleAtts['auction'])) {
					retStr &= "<th  class='#player#'><div>#arguments.pbndata[player]#</div></th>";
				}
			}
			retStr &= "</tr>#cr#";
		
		retStr &= "#tab##tab#</thead>#cr#";
		
		retStr &= "#tab##tab#<tbody>#cr#";

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
			
			retStr &= "#tab##tab##tab#<tr class='#oddeven#'>#cr##tab##tab##tab##tab#";

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
			retStr &= "#cr##tab##tab##tab#</tr>#cr#";
		}

		retStr &= "#tab##tab#</tbody>#cr##tab#</table>#cr##cr#";

		// # Add list of notes in new table
		
		if (IsStruct(arguments.pbndata["notes"])) {
			throw(message="Notes are Struct??",type="bridge");
		}

		if (arraylen(arguments.pbndata["notes"])) {
			retStr &= "#tab#<table class='notes'>#cr#";
			
			for (i=1; i lte ArrayLen(arguments.pbndata['notes']); i += 1) {
				note = arguments.pbndata["notes"][i];
				retStr &= "#tab##tab#<tr><td>(#note.marker#)</td><td>#note.note#</td></tr>#cr#";
			}

			retStr &= "#tab#</table>#cr#";
		}

		retStr &= "</div>#cr#";


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
	private function displaySuitCombo(required struct suit) {
		
		var retStr = false;
		var standclass = "";
		var colspan = " colspan='2'";
		var noMiddle = false;

		// # ignore middle row if both void
		if (suit['w'] eq "-" and suit['e'] eq "-") {
		   noMiddle = true;
		   colspan = "";
		}
		retStr = [];
		retStr.append("<table class='bridgesuitcombo'>");    

		retStr.append("<tr><td class='n'#colspan#><span class='cards'>" & suitFormat(arguments.suit['n']) & "</span></td></tr>");
		
		// # ignore middle row if both void
		if (not noMiddle) {
			retStr.append("<tr><td class='w'><span class='cards'>" & suitFormat(arguments.suit['w']) & "</span></td>");
			retStr.append("<td class='e'><span class='cards'>" & suitFormat(arguments.suit['e']) & "</span></td></tr>");
		}

		retStr.append("<tr><td class='s'#colspan#><span class='cards'>" & suitFormat(arguments.suit['s']) & "</span></td></tr>");
		
		retStr.append("</table>");

		return retStr.toList(newLine());
	}

	private function parseSuitCombo(required string deal) localmode=true {
		
		arguments.deal = tidyHand(arguments.deal);
		
		if (ListLen(arguments.deal,":") gt 1) {
			startpos = ListFirst(arguments.deal,":");
			deal = ListLast(arguments.deal,":");
		}
		else {
			startpos = 's';
			deal = arguments.deal;
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