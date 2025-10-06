component {

	struct function parse(string handviewer_link, struct log={}) {
		local.params = ListLast(arguments.handviewer_link,"?");

		local.params = Replace(local.params,"st","title");
		local.link = ListLast(arguments.handviewer_link,"=");
		local.fields = ListToArray(local.link,"|");
		
		local.delim = "";
		local.players = ["South"=1,"West"=2,"North"=3,"East"=4];
		local.player_positions = ["South","West","North","East"];
		local.pbn = {};
		local.pbn["bids"] = [];// array gets converted to string for "auction" later
		local.pbn["cards"] = [];// array gets converted to string for "play" later

		for (local.field in local.fields) {

			switch (local.field) {
				case "title":case "pn":case "md":case "mb":case "an":case "pc":case "pc":case "sv":case "rh":case "ah":
					local.delim = local.field;
					continue;

			}
			if (local.delim eq "") {
				arguments.log[now()] = "Unknown delim #local.field#";
				continue;
			}

			// writeOutput("Delim: #local.delim#, field #local.field#<br>");
			try {
				switch (local.delim) {
					case "title":
						// title 
						local.pbn["title"] = local.field;
					break;
					case "sv":
						switch (local.field) {
							case "o":
								local.pbn["Vulnerable"] = "None";
								break;
							case "b":
								local.pbn["Vulnerable"] = "Both";
								break;
							case "e":
								local.pbn["Vulnerable"] = "EW";
								break;
							case "n":
								local.pbn["Vulnerable"] = "NS";
								break;
						}
					break;
					case "pn":
						
						local.names = listToArray(local.field);
						for (local.i = 1 ; local.i <= 4; local.i++ ) {
							local.player = local.player_positions[local.i];
							local.pbn["#local.player#"] = local.names[local.i];
						}

					break;
					case "md":
						// dealer is first number of deal string
						local.dealer_num = Left(local.field,1) ;
						local.deal = Right( local.field, len(local.field) -1 );
						local.deal = Replace(local.deal, ",", " ","all");
						local.deal = ReplaceList(local.deal, "S", "");
						local.deal = ReplaceList(local.deal, "H,C,D", ".,.,.");
						local.pbn["Deal"] = "S:" & local.deal;
					break;
					case "mb":
						local.pbn.bids.append({"bid":local.field});
					break;
					case "an":
						local.pbn.bids[local.pbn.bids.len()]["note"] = local.field;
					break;
					case "pc":
						local.pbn.cards.append(local.field);
					break;
					case "pg":
						// looks redundant
					break;

				}
			}
			catch (any e) {
				writeDump("Unable to parse field #local.field#. Delim #local.delim#");
				writeDump(e);
			}
		}
		
		// work out contract
		// get array num of winning bid
		local.contract_bidnum = 0;
		local.bidnum = 1;
		for (local.bid in local.pbn.bids) {
			switch (local.bid.bid) {
				case "P": case "pass":case "AP":
					break;
				default:
					local.contract_bidnum = local.bidnum;
			}
			local.bidnum ++;
		}

		local.pbn["contract"] = local.pbn.bids[local.contract_bidnum].bid;
		
		// work out declarer
		local.pbn["Declarer"] = Left(player_positions[this.player(local.dealer_num + local.contract_bidnum)],1);
		local.pbn["Dealer"] = Left(player_positions[local.dealer_num],1);

		return local.pbn;
	}

	/**
	 * return position of player from bid number e.g. 1 for 13, 2 for 6
	 * 
	 * @i Integer number of bid
	 */
	numeric function player(i) {
		return ( ( i - 1 ) % 4 ) + 1 ;
	}

	string function pbn(required struct hand) {
		
		local.ret = "";
		
		for (local.tag in ["Event","Site","Date","Board","West","North","East","South","Dealer","Vulnerable","Deal","Scoring","Declarer","Contract","Result"]) {
			if ( StructKeyExists(arguments.hand, local.tag) ) {
				local.ret &= "[#local.tag# ""#arguments.hand[local.tag]#""]" & newLine();
			}
		}

		local.ret &= "[Auction ""#arguments.hand.dealer#""]" & newLine();
		local.bid_notes = [];
		local.count = 1;
		for (local.bid in arguments.hand.bids ) {
			local.ret &= local.bid.bid;
			if (local.bid.keyExists("note")) {
				local.bid_notes.append(local.bid.note);
				local.ret &= " =#local.bid_notes.len()#=";
			}
			if (local.count % 4 eq 0) {
				local.ret &= newLine();
			}
			else {
				local.ret &= " ";
			}
			local.count++;
		}
		local.count = 1;
		for (local.note in local.bid_notes) {
			local.ret &= "[Note ""#local.count#:#local.note#""]" & newLine();
			local.count++;
		}

		// note that the PBN play tag contains cards in order of player not the
		// order they are played.
		local.ret &= "[Play_order]" & newLine();;
		local.count = 1;
		writeDump(arguments.hand.cards);
		for (local.card in arguments.hand.cards ) {
			local.ret &= local.card;
			if (local.count % 4 eq 0) {
				local.ret &= newLine();
			}
			else {
				local.ret &= " ";
			}
			local.count++;
		}
		
		return local.ret;
	}

	// NOTE I haven't tested this or actually used it in anger
	// The PBN format is such a nonsense I don't really anticipate using it
	/** convert simple array of cards to pbn format where the columns are the player
	and the order can only be ascertained by working out who won each trick. */
	string function convertPlayArrayToPBNNonsense(hand, string opener) {
		
		var dealStruct = playerCardStruct(arguments.hand.deal);
		
		var retAuction = {"n"=[],"s"=[],"e"=[],"w"=[]};
		var suit = false;
		var card = false;
		var rank = false;
		var player = false;
		local.noteNum = 1;
		local.notes = [];
		for (card in arguments.hand.play) {
			local.noteText = "";
					
			if (structKeyExists(card,"note")) {
				local.noteText = " =#local.noteNum#=";
				local.notes[local.noteNum] = card.note;
				local.noteNum++;
			}
			ArrayAppend(retAuction[dealStruct[card.data]],card.data&local.noteText);
					
		}

		
		local.outputOrder = [arguments.opener];
		for (local.i = 2; local.i lte 4;local.i++) {
			local.outputOrder[local.i] = getNextPosition(local.outputOrder[local.i-1]);
		}
		var retVal = "";
		for (local.i = 1; local.i lte 13;local.i++) {
			local.trick = "";
			for (player in local.outputOrder) {
				if (arrayLen(retAuction[player]) gte i) {
					local.trick = listAppend(local.trick,retAuction[player][i]," ");
				}
			}
			retVal = ListAppend(retVal,local.trick,chr(13)&chr(10));
		}

		for (local.i = 1; local.i lte ArrayLen(local.notes);local.i++) {
			retVal &= "[Note ""#local.i#:#local.notes[local.i]#""],chr(13)&chr(10)";
		}
		
		return retVal;

	}
}