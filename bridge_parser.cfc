/*

# bridge parser

Parse bridge hands from <bridge> tags

See docs for information regarding hand format and diagram settings

## Usage

Pass in a jsoup node and (if using external files a basepath)

Returns HTML for hand, suit combo, or deal diagram

*/

component {

	public function init(jsoupObj, boolean debug=0) {
		if (structKeyExists(arguments, "jsoupObj")) variables.jsoupObj = arguments.jsoupObj;
		variables.playerList = ['n','e','w','s'];
		this.debug = arguments.debug;

		return this;
	}

    /** Import one hand from raw LIN, a Handviewer query/URL, or a redirect/LIN URL.
     * Uses the same deal/auction/notes schema as parsePBN. No jsoup object needed.
     * Network resolution is optional; callers handling untrusted input can disable it.
     */
    public struct function parseHandviewer(required string input, boolean resolveURLs=true) localmode=true {
        source = trim(arguments.input);
        for (hop = 0; hop <= 5; hop++) {
            if (reFindNoCase("^[a-z]{2}\|", source)) return parseLIN(source);
            query = source;
            if (find("?", query)) query = mid(query, find("?", query) + 1, len(query));
            params = {};
            for (pair in listToArray(query, "&")) {
                equals = find("=", pair);
                if (equals) {
                    key = lCase(urlDecode(left(pair, equals - 1)));
                    value = mid(pair, equals + 1, len(pair));
                    // BBO also emits partly encoded LIN URLs with literal pipes and 3+ explanations.
                    if (key == "lin" && find("|", value)) value = replace(value, "+", "%2B", "all");
                    params[key] = urlDecode(value);
                }
            }
            if (params.keyExists("lin")) return parseLIN(params.lin);
            if (params.keyExists("n") || params.keyExists("s") || params.keyExists("e") || params.keyExists("w") || params.keyExists("a")) {
                return importHandviewerFields(params);
            }
            if (!reFindNoCase("^https?://", source) || !arguments.resolveURLs || hop == 5) {
                throw(type="bridge", message="Expected LIN data or a Handviewer URL/query; URL resolution is disabled, exhausted, or unavailable.");
            }
            validateHandviewerURL(source);
            response = requestHandviewerURL(source);
            status = val(response.statusCode);
            if (status >= 300 && status < 400 && response.responseHeader.keyExists("Location")) {
                source = createObject("java", "java.net.URI").init(source).resolve(response.responseHeader.Location).toString();
            } else if (status >= 200 && status < 300) {
                source = trim(toString(response.fileContent));
                if (!reFindNoCase("^[a-z]{2}\|", source)) throw(type="bridge", message="The URL did not return LIN data.");
            } else {
                throw(type="bridge", message="Unable to load Handviewer/LIN URL (HTTP " & status & ").");
            }
        }
    }

    /** Exact host allowlist, checked before each request, including redirected requests. */
    private void function validateHandviewerURL(required string url) localmode=true {
        try {
            uri = createObject("java", "java.net.URI").init(arguments.url);
            scheme = isNull(uri.getScheme()) ? "" : lCase(uri.getScheme());
            authority = isNull(uri.getRawAuthority()) ? "" : uri.getRawAuthority();
            port = uri.getPort();
            allowed = (scheme == "http" || scheme == "https")
                && reFindNoCase("^(?:www\.)?(?:bridgebase\.com|tinyurl\.com)(?::[0-9]+)?$", authority)
                && (port == -1 || (scheme == "http" && port == 80) || (scheme == "https" && port == 443));
        } catch (any e) {
            allowed = false;
        }
        if (!allowed) throw(type="bridge", message="URL fetching is restricted to bridgebase.com and tinyurl.com (with optional www) on standard HTTP/HTTPS ports. Paste the Handviewer link containing hand data or raw LIN instead.");
    }

    /** Keep transport separate so redirect policy can be tested without network access. */
    private struct function requestHandviewerURL(required string url) localmode=true {
        http url=arguments.url method="get" redirect=false timeout=15 result="response";
        return response;
    }

    /** Parse LIN command/value pairs, preserving empty values and ignoring unknown commands. */
    public struct function parseLIN(required string text) localmode=true {
        fields = listToArray(trim(arguments.text), "|", true);
        if (fields.len() && fields[fields.len()] == "") fields.deleteAt(fields.len());
        if (fields.len() % 2) throw(type="bridge", message="LIN commands must have a value (which may be empty).");
        hand = {auction:[], notes:[], play_ordered:[], comments:[]};
        rawDeal = {};
        positions = ["s", "w", "n", "e"];
        names = {s:"South", w:"West", n:"North", e:"East"};
        seenDeal = false;
        for (i = 1; i < fields.len(); i += 2) {
            command = lCase(trim(fields[i]));
            value = fields[i + 1];
            switch (command) {
                case "md":
                    if (seenDeal) throw(type="bridge", message="Import one LIN board at a time.");
                    seenDeal = true;
                    if (!reFind("^[1-4]", value)) throw(type="bridge", message="Invalid LIN dealer.");
                    hand.dealer = uCase(positions[val(left(value, 1))]);
                    hands = listToArray(mid(value, 2, len(value)), ",", true);
                    if (hands.len() > 4) throw(type="bridge", message="Too many hands in LIN deal.");
                    for (j = 1; j <= hands.len(); j++) rawDeal[positions[j]] = hands[j];
                    break;
                case "pn":
                    players = listToArray(value, ",", true);
                    for (j = 1; j <= min(4, players.len()); j++) hand[names[positions[j]]] = players[j];
                    break;
                case "sv": hand.vulnerable = importVulnerability(value); break;
                case "ah": hand.board = reReplaceNoCase(value, "^Board\s+", ""); break;
                case "st": case "title": if (len(value)) hand.event = value; break;
                case "nt": hand.comments.append(value); break;
                case "mb": appendImportedCall(hand, value); break;
                case "an": appendImportedNote(hand, value); break;
                case "pc":
                    card = uCase(trim(value));
                    if (!reFind("^[SHDC][AKQJT2-9]$", card)) throw(type="bridge", message="Invalid LIN card: " & value);
                    hand.play_ordered.append(card);
                    break;
            }
        }
        if (!seenDeal && !hand.auction.len() && !hand.play_ordered.len()) throw(type="bridge", message="No hand, auction or play found in LIN data.");
        if (seenDeal) hand.deal = importDeal(rawDeal);
        deriveImportedContract(hand);
        return hand;
    }

    private struct function importHandviewerFields(required struct fields) localmode=true {
        hand = {auction:[], notes:[], play_ordered:[]};
        mapping = {b:"board", d:"dealer", sn:"South", wn:"West", nn:"North", en:"East", st:"event"};
        for (key in mapping) if (fields.keyExists(key)) hand[mapping[key]] = fields[key];
        if (fields.keyExists("v")) hand.vulnerable = importVulnerability(fields.v);
        rawDeal = {};
        for (pos in ["n", "e", "s", "w"]) if (fields.keyExists(pos)) rawDeal[pos] = fields[pos];
        if (rawDeal.count()) hand.deal = importDeal(rawDeal);
        if (fields.keyExists("a")) {
            // Consume the whole auction: unmatched text must not silently disappear.
            auction = trim(fields.a);
            while (len(auction)) {
                token = reFindNoCase("^(\([^)]*\)|[1-7](?:NT|[NSHDC])!?|PASS|AP|XX|RDBL|DBL|[PDRX]|[-?])", auction, 1, true);
                if (!token.len[1]) throw(type="bridge", message="Invalid Handviewer auction near: " & auction);
                value = left(auction, token.len[1]);
                if (left(value, 1) == "(") appendImportedNote(hand, mid(value, 2, len(value) - 2));
                else appendImportedCall(hand, value);
                auction = trim(mid(auction, len(value) + 1, len(auction)));
            }
        }
        if (fields.keyExists("p")) {
            play = uCase(reReplace(fields.p, "\s+", "", "all"));
            if (len(play) % 2 || reFind("[^SHDCAKQJT2-9]", play)) throw(type="bridge", message="Invalid Handviewer play sequence.");
            for (i = 1; i <= len(play); i += 2) {
                card = mid(play, i, 2);
                if (!reFind("^[SHDC][AKQJT2-9]$", card)) throw(type="bridge", message="Invalid Handviewer card: " & card);
                hand.play_ordered.append(card);
            }
        }
        deriveImportedContract(hand);
        return hand;
    }

    private string function importVulnerability(required string value) localmode=true {
        mapping = {o:"None", "-":"None", none:"None", b:"Both", both:"Both", all:"Both", n:"NS", ns:"NS", e:"EW", ew:"EW"};
        if (!mapping.keyExists(trim(value))) throw(type="bridge", message="Invalid vulnerability: " & value);
        return mapping[trim(value)];
    }

    private void function appendImportedCall(required struct hand, required string value) localmode=true {
        call = uCase(trim(value));
        alerted = right(call, 1) == "!";
        if (alerted) call = left(call, len(call) - 1);
        aliases = {p:"Pass", pass:"Pass", d:"X", dbl:"X", r:"XX", rdbl:"XX"};
        if (aliases.keyExists(call)) call = aliases[call];
        if (reFind("^[1-7]N$", call)) call &= "T";
        if (!reFindNoCase("^(?:[1-7](?:NT|[SHDC])|Pass|AP|X|XX|[-?])$", call)) throw(type="bridge", message="Invalid auction call: " & value);
        hand.auction.append({bid:call, note:"", flage:""});
        if (alerted) appendImportedNote(hand, "Alert");
    }

    private void function appendImportedNote(required struct hand, required string value) localmode=true {
        if (!hand.auction.len()) throw(type="bridge", message="An explanation must follow an auction call.");
        suits = {S:"♠", H:"♥", C:"♣", D:"♦"};
        for (suit in suits) arguments.value = replaceNoCase(arguments.value, "!" & suit, suits[suit], "all");
        call = hand.auction[hand.auction.len()];
        if (len(call.note)) {
            note = hand.notes[val(call.note)];
            note.note = note.note == "Alert" ? value : note.note & "; " & value;
        } else {
            call.note = toString(hand.notes.len() + 1);
            hand.notes.append({marker:call.note, note:value});
        }
    }

    /** Normalize holdings; infer only the fourth hand when the other three contain 39 cards. */
    private struct function importDeal(required struct rawDeal) localmode=true {
        deal = {};
        used = {};
        missing = [];
        counts = {};
        for (pos in ["n", "e", "s", "w"]) {
            deal[pos] = {s:"", h:"", d:"", c:""};
            counts[pos] = 0;
            holding = rawDeal.keyExists(pos) ? uCase(reReplace(rawDeal[pos], "\s+", "", "all")) : "";
            if (!len(holding) || holding == "-") { missing.append(pos); continue; }
            holding = replace(holding, "10", "T", "all");
            suit = "";
            for (i = 1; i <= len(holding); i++) {
                char = mid(holding, i, 1);
                if (find(char, "SHDC")) { suit = lCase(char); continue; }
                if (char == "-") continue;
                if (!len(suit) || !find(char, "AKQJT98765432")) throw(type="bridge", message="Invalid holding for " & pos & ": " & holding);
                card = suit & char;
                if (used.keyExists(card)) throw(type="bridge", message="Duplicate card: " & card);
                used[card] = true;
                deal[pos][suit] &= char;
                counts[pos]++;
            }
            if (counts[pos] > 13) throw(type="bridge", message="More than 13 cards in hand " & pos);
        }
        if (missing.len() == 1 && used.count() == 39) {
            for (suit in ["s", "h", "d", "c"]) {
                for (i = 1; i <= 13; i++) {
                    rank = mid("AKQJT98765432", i, 1);
                    if (!used.keyExists(suit & rank)) deal[missing[1]][suit] &= rank;
                }
            }
        }
        for (pos in deal) {
            for (suit in deal[pos]) {
                sorted = "";
                for (i = 1; i <= 13; i++) {
                    rank = mid("AKQJT98765432", i, 1);
                    if (find(rank, deal[pos][suit])) sorted &= rank;
                }
                deal[pos][suit] = len(sorted) ? sorted : "-";
            }
        }
        return deal;
    }

    private void function deriveImportedContract(required struct hand) localmode=true {
        if (!hand.keyExists("dealer") || !len(hand.dealer)) return;
        if (!reFindNoCase("^[NESW]$", hand.dealer)) throw(type="bridge", message="Invalid dealer: " & hand.dealer);
        hand.dealer = uCase(hand.dealer);
        bidder = hand.dealer;
        firstBidders = {};
        contract = "";
        modifier = "";
        passes = 0;
        complete = false;
        unknown = false;
        for (call in hand.auction) {
            if (complete) throw(type="bridge", message="Auction continues after completion.");
            bid = uCase(call.bid);
            if (reFind("^[1-7]", bid)) {
                denomination = mid(bid, 2, len(bid));
                side = findNoCase(bidder, "NS") ? "NS" : "EW";
                key = side & denomination;
                if (!firstBidders.keyExists(key)) firstBidders[key] = bidder;
                declarer = firstBidders[key];
                contract = bid;
                modifier = "";
                passes = 0;
            } else if (bid == "X" || bid == "XX") {
                if (!len(contract)) throw(type="bridge", message="A double or redouble must follow a contract bid.");
                modifier = bid;
                passes = 0;
            } else if (bid == "PASS" || bid == "AP") {
                passes++;
                complete = bid == "AP" || passes >= (len(contract) ? 3 : 4);
            } else unknown = true;
            bidder = uCase(getNextPosition(bidder));
        }
        // Incomplete/example auctions must not acquire a made-up final contract.
        if (!complete || unknown) return;
        hand.contract = len(contract) ? contract & modifier : "Pass";
        if (len(contract)) hand.declarer = declarer;
    }

    /** Export the shared parser schema. Play is copied verbatim into our unofficial extension. */
    public string function exportPBN(required struct hand) localmode=true {
        lines = [];
        if (hand.keyExists("comments")) for (comment in hand.comments) {
            for (line in listToArray(comment, chr(13) & chr(10))) lines.append("% " & line);
        }
        for (tag in ["Event", "Site", "Date", "Board", "West", "North", "East", "South", "Dealer", "Vulnerable", "Scoring", "Declarer", "Contract", "Result"]) {
            if (hand.keyExists(tag)) lines.append(pbnTag(tag, hand[tag]));
        }
        if (hand.keyExists("deal")) {
            holdings = [];
            for (pos in ["n", "e", "s", "w"]) {
                if (!hand.deal.keyExists(pos)) { holdings.append("-"); continue; }
                suits = [];
                for (suit in ["s", "h", "d", "c"]) suits.append(replace(hand.deal[pos][suit], "-", "", "all"));
                holding = arrayToList(suits, ".");
                holdings.append(holding == "..." ? "-" : holding);
            }
            lines.append(pbnTag("Deal", "N:" & arrayToList(holdings, " ")));
        }
        if (hand.keyExists("auction") && hand.auction.len()) {
            lines.append(pbnTag("Auction", hand.keyExists("dealer") ? hand.dealer : "?"));
            row = [];
            for (call in hand.auction) {
                text = call.bid;
                if (call.keyExists("note") && len(call.note)) text &= " =" & call.note & "=";
                row.append(text);
                if (row.len() == 4) { lines.append(arrayToList(row, " ")); row = []; }
            }
            if (row.len()) lines.append(arrayToList(row, " "));
            if (hand.keyExists("notes")) for (note in hand.notes) lines.append(pbnTag("Note", note.marker & ":" & note.note));
        }
        if (hand.keyExists("play_ordered") && hand.play_ordered.len()) {
            lines.append("[play_ordered]");
            lines.append(arrayToList(hand.play_ordered, " "));
            if (hand.keyExists("play_notes")) for (note in hand.play_notes) lines.append(pbnTag("Note", note.marker & ":" & note.note));
        }
        return arrayToList(lines, chr(10)) & chr(10);
    }

    private string function pbnTag(required string name, required string value) {
        var escaped = replace(arguments.value, '\', '\\', "all");
        escaped = replace(escaped, '"', '\"', "all");
        return '[' & arguments.name & ' "' & escaped & '"]';
    }

	/** Convert Markdown inline code to publication auction text, keeping code blocks literal. */
	public void function formatInlineAuctions(required node) localmode=true {
		for (code in arguments.node.select("code")) {
			if (!isNull(code.closest("pre")) || !isInlineAuction(code.text())) continue;
			code.tagName("span").addClass("bridge-inline-auction");
		}
	}

    /** Only bridge call sequences should lose their inline code semantics. */
    public boolean function isInlineAuction(required string text) {
        return reFindNoCase("^\s*\(?\s*(?:[1-7](?:NT|[SHDC♠♥♦♣])|PASS|P|DBL|RDBL|XX|X|\?)\s*\)?(?:[\s,;:\-–—→]+\(?\s*(?:[1-7](?:NT|[SHDC♠♥♦♣])|PASS|P|DBL|RDBL|XX|X|\?)\s*\)?)*\s*$", arguments.text) > 0;
    }

    /** Process text and inline auctions without reserializing the caller's document. */
    public string function formatInlineHtml(required string html) localmode=true {
        // Match complete literal blocks before individual tags. Quoted > stays inside a tag.
        tagPattern = "<(?:[^>""']|""[^""]*""|'[^']*')*>";
        expression = "<!--.*?-->|<(pre|script|style|textarea|title|bridge)\b[^>]*>.*?</\1\s*>|<code\b[^>]*>.*?</code\s*>|" & tagPattern;
        patternClass = createObject("java", "java.util.regex.Pattern");
        matcher = patternClass.compile(expression, patternClass.CASE_INSENSITIVE + patternClass.DOTALL).matcher(arguments.html);
        result = [];
        cursor = 1;
        suitSpanDepth = 0;
        while (matcher.find()) {
            start = matcher.start() + 1;
            if (start > cursor) {
                text = mid(arguments.html, cursor, start - cursor);
                result.append(suitSpanDepth ? text : wrapSuitText(text));
            }
            tag = matcher.group();
            if (reFindNoCase("^<code\b", tag)) {
                document = variables.jsoupObj.Jsoup.parse(tag);
                code = document.select("code").first();
                if (isInlineAuction(code.text())) {
                    formatInlineAuctions(document);
                    wrapSuitSymbols(document);
                    tag = document.body().html();
                }
            } else if (reFindNoCase("^<span\b", tag)) {
                if (suitSpanDepth || reFindNoCase("\bclass\s*=\s*['""][^'""]*\bsuit\b", tag)) suitSpanDepth++;
            } else if (reFindNoCase("^</span\s*>", tag) && suitSpanDepth) {
                suitSpanDepth--;
            }
            result.append(tag);
            cursor = matcher.end() + 1;
        }
        if (cursor <= len(arguments.html)) {
            text = mid(arguments.html, cursor, len(arguments.html) - cursor + 1);
            result.append(suitSpanDepth ? text : wrapSuitText(text));
        }
        return result.toList("");
    }

    private string function wrapSuitText(required string text) localmode=true {
        suits = {"♠":"s", "♥":"h", "♦":"d", "♣":"c"};
        for (symbol in suits) {
            arguments.text = replace(arguments.text, symbol, "<span class='suit " & suits[symbol] & "'>" & symbol & "</span>", "all");
        }
        return arguments.text;
    }

	/** Wrap visible suit characters without interpreting escaped text as HTML. */
	public void function wrapSuitSymbols(required node) localmode=true {
		suits = {"♠":"s", "♥":"h", "♦":"d", "♣":"c"};
		for (element in arguments.node.select("*")) {
			if (!isNull(element.closest("pre, code, script, style, .suit"))) continue;
			for (textNode in element.textNodes()) {
				// outerHtml retains escaping for literal <, > and & in inline auctions.
				original = textNode.outerHtml();
				replaced = original;
				for (symbol in suits) {
					replaced = replace(replaced, symbol, "<span class='suit " & suits[symbol] & "'>" & symbol & "</span>", "all");
				}
				if (replaced != original) {
					fragment = variables.jsoupObj.Jsoup.parse(replaced).body().childNodes();
					for (child in fragment) textNode.before(child);
					textNode.remove();
				}
			}
		}
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

	public function parsePBN(required string text) localmode=true {

		data = parseTaggedText(text);

		pbnData = {};
		currentTag = "";

		for ( tag in data ) {
			
			switch (tag.tag) {
				case "play": case "play_ordered":
					// Preserve source order only. Standard Play columns are NOT reordered.
					pbnData["play_ordered"] = listToArray(tag.text, " " & chr(9) & chr(10) & chr(13));
					break;
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
					if (currentTag == "play" || currentTag == "play_ordered") {
						if (!pbnData.keyExists("play_notes")) pbnData.play_notes = [];
						pbnData.play_notes.append({marker:listFirst(tag.attributes, ":"), note:listRest(tag.attributes, ":")});
						continue;
					}
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

			// Notes belong to the preceding section; do not let the first note
			// hide the auction context from subsequent notes (or admit play notes).
			if (tag.tag != "note") {
				currentTag = tag.tag;
			}
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

	            // Only a complete PBN header (or our bare play_ordered extension) starts a record; auction markers such
	        // as [1] must remain in the text passed to parseAuction.
	        if (!inTag && ch == "[" && reFindNoCase('\[\s*(?:[A-Za-z][A-Za-z0-9_]*\s+"(?:\\.|[^"\\])*"|play_ordered)\s*\]', arguments.input, i) == i) {
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
	            if (inQuote && ch == '\' && i < lenInput && (mid(arguments.input, i + 1, 1) == '"' || mid(arguments.input, i + 1, 1) == '\')) {
	                currentAttributes &= mid(arguments.input, i + 1, 1);
	                i++;
	                continue;
	            }
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

		suits = find(".", retStr)
			? ListToArray(retStr, ".", true)
			: ListToArray(retStr, "#chr(10)##chr(13)#, ");
		for (var suitIndex = 1; suitIndex <= arrayLen(suits); suitIndex++) {
			if (!len(suits[suitIndex])) suits[suitIndex] = "-";
		}
		
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

		// An explicit vertical hand overrides the inferred or requested inline layout.
		if (arguments.styleAtts["type"] == "hand" && arguments.styleAtts.keyExists("vertical")
			&& (!isBoolean(arguments.styleAtts.vertical) || arguments.styleAtts.vertical)) {
			arguments.styleAtts["inline"] = false;
		}

		var classes = getClasses(arguments.styleAtts);
		
		if (arguments.styleAtts["type"] == "pbn") {

			classes = listAppend(classes, "bridgefull", " ");

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
		imageAttribute = arguments.styleAtts.keyExists("data") && arguments.styleAtts.data.keyExists("image")
			? ' data-image="' & encodeForHTMLAttribute(arguments.styleAtts.data.image) & '"'
			: "";
		if (len(imageAttribute) && arguments.styleAtts.keyExists("width")) {
			imageAttribute &= ' width="' & encodeForHTMLAttribute(arguments.styleAtts.width) & '"';
		}

		wrapper = arguments.styleAtts["type"] == "hand" && listFind(classes, "inline", " ") ? "span" : "div";
		retStr = "<#wrapper# #id#class='#classes#'#imageAttribute#>" & retStr & "</#wrapper#>";
		
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
		text = replace(text, "X","x","all");

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
				// Decode HTML entities as text and reuse the idempotent suit wrapper.
				noteDocument = variables.jsoupObj.Jsoup.parse(note.note);
				wrapSuitSymbols(noteDocument);
				retStr &= "#tab##tab#<tr><td>(#note.marker#)</td><td>#noteDocument.body().html()#</td></tr>#cr#";
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
