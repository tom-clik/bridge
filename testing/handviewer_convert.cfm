<!---

# Convert Handviewer links to PBN

Convert handviewer links to PBN format

Copes with tiny urls

## Usage

action=parselin|parseHandviewer*
data=handviewlink or link to fetch lin data

## Status

Basics are working. Needs tidying up and test case scenarios doing properly etc.

Possibly move all methods in to main parser. Data struct for hand is slightly different from main parser. This is better. Rework main parser so all formats are parsed into a standard data structure.

## Hands

http://tinyurl.com/y763g5qg
http://tinyurl.com/oqzf8m7  --
http://tinyurl.com/ybmpx2d6 -- playing your highest card on lead.

--->

<!--- <cfset url.data = "http://www.bridgebase.com/myhands/fetchlin.php?id=1343085560&when_played=1498285420"> --->

<!--- <cfparam name="url.action" default="parselin"> --->
<cfset url.data = "http://tinyurl.com/y763g5qg">

<cfparam name="url.action" default="parseHandviewer">
<cfparam name="url.data">

<cfswitch expression="#url.action#">
	<cfcase value="parselin">
		<cfset lin = loadURL(url.data)>
		
		<cfset myLinData = parseLin(lin)>
		<cfset myLinData = parseData(myLinData)>
		
		<pre><cfoutput>#outputPBN(myLinData)#</cfoutput>
		</pre>

	</cfcase>

	<cfcase value="parseHandviewer">
		<cfset myData = parseURL(url.data)>
		<cfdump var="#myData#">
		<cfset myVal = parseData(myData)>
		<cfset pbnText = outputPBN(myVal)>
		<!--- <cfdump var="#myVal#"> --->
		<pre><cfoutput>#pbnText#</cfoutput></pre>

	</cfcase>

	<cfdefaultcase>
		No action specified
	</cfdefaultcase>

</cfswitch>

<cffunction name="parseURL" returntype="struct" output="false" hint="Parse url into key value pairs">

	<cfargument name="sURL">

	<cfif findNoCase("tinyurl",arguments.sURL) OR findNoCase("myhand",arguments.sURL)>
		<cfset arguments.sURL = getProperURL(arguments.sURL)>
	</cfif>

	<cfset local.QueryString = ListLast(arguments.sURL,"?")>
	<cfset local.data =  server.utils.parseQueryString(local.QueryString)>
	
	<cfreturn local.data>

</cffunction>

<cffunction name="parseData" returntype="struct" output="false" hint="Parse data struct into hand">

	<cfargument name="data">
	<cfset var hand = newHand()>

	<cfset var simpleVals = {
	    "b" = "Board",
	    "d" = "Dealer",
	    "en" = "East",
	    "nn" = "North",
	    "wn" = "West",
	    "sn" = "South",
	    "v" = "Vulnerable"
	}>

	<cfloop item="local.simpleField" collection="#simpleVals#">
		<cfif structKeyExists(arguments.data,local.simpleField)>
			<cfset hand[simpleVals[local.simpleField]] = arguments.data[local.simpleField]>
		</cfif>
	</cfloop>
	<!--- deal --->
	<cfset checkDeal(arguments.data)>
	<cfloop index="local.dealpos" list="n,s,e,w">
		<cfset hand.deal[local.dealpos] = arguments.data[local.dealpos]>
	</cfloop>	

	<!--- auction --->
	<cfif structKeyExists(arguments.data,"a")>
		<cfset  var auctionStr = arguments.data["a"]>
		
		<cfscript>
		local.patternObj = createObject( "java", "java.util.regex.Pattern" );
		local.pattern = local.patternObj.compile("[drx]{1,2}|p|\d([shcd]|NT?)|\(.*?\)", local.patternObj.CASE_INSENSITIVE);
		local.tagObjs = local.pattern.matcher(auctionStr);
		local.bidList = [];
		while (local.tagObjs.find()){
		    arrayAppend(local.bidList, local.tagObjs.group());
		}
		// writeDump(local.bidList);
		for (local.bid in local.bidList) {
			// if (local.bid eq "p") {
			// 	arrayAppend(hand.auction,{"data"="p"});
			// }
			// else 
			if (Left(local.bid,1) neq "(") {
				switch (local.bid) {
					case "r":
						local.bid = "XX";
						break;
					case "d":
						local.bid = "X";
						break;

				}
				arrayAppend(hand.auction,{"data"=local.bid});
			}
			else if (Left(local.bid,1) eq "(") {
				hand.auction[ArrayLen(hand.auction)]["note"] = ListFirst(local.bid,"()");
			}

		}
		</cfscript>

		<!--- <cfloop condition="#Len(auctionStr)#">
			
			<cfif Left(auctionStr,1) eq "P">
				<cfset local.bid = {"bid"="p"}>
				<cfset local.removeChars = 1>
			<cfelse>
				<cfset bid = reFindNoCase(reg_expression, "string", [start], [returnsubexpressions])
				<cfset local.bid = {"bid"=Left()}>
			</cfif>

		</cfloop> --->

	</cfif>

	<!--- play --->
	<cfif structKeyExists(arguments.data,"p")>
		<cfloop index="local.i" from="1" to="#Len(arguments.data.p)#" step="2">
			<cfset arrayAppend(hand.play,{"data"=Mid(arguments.data.p,local.i,2)})>
		</cfloop>
	</cfif>

	<cfset checkContract(hand)>
	<cfreturn hand>

</cffunction>

<cffunction name="loadURL" returntype="string" hint="Get ffilecontent url" output="false">

	<cfargument name="sURL">

	<cfhttp url="#arguments.sURL#" redirect="false">
		
	</cfhttp>
	<cfset local.content = cfhttp.fileContent.toString()>
	
	<cfreturn local.content>
</cffunction>

<cffunction name="getProperURL" returntype="string" hint="Get full rul from tiny url" output="false">

	<cfargument name="sURL">

	<cfhttp url="#arguments.sURL#" redirect="false">
		
	</cfhttp>
	<cfset local.location = cfhttp.Responseheader.Location>
	<cfreturn local.location>
</cffunction>

<cffunction name="newHand" returntype="Struct" hint="Return empty struct for storing info" output="false">

	<cfset var hand = {
		"Comments" = [],
		"Event" = "",
		"Site" = "",
		"Date" = "",
		"Board" = "",
		"West" = "",
		"North" = "",
		"East" = "",
		"South" = "",
		"Dealer" = "",
		"Vulnerable" = "",
		"Deal" = {},
		"Scoring" = "",
		"Declarer" = "",
		"Contract" = "",
		"Result" = "",
		"Auction" = [],
		"Play" = []

	}>

	<cfreturn hand>

</cffunction>

<cffunction name="getPBNFieldOrder" returntype="Array" output="false">
	<cfreturn ListToArray("Comments,Event,Site,Date,Board,West,North,East,South,Dealer,Vulnerable,Deal,Scoring,Declarer,Contract,Result,Auction,Play")>

</cffunction>


<cffunction name="checkContract" returntype="void" output="false">
	
	<cfargument name="hand" required="true">
	
	<cfset var currentPlayer = getPreviousPosition(arguments.hand.dealer)>
	<cfset var contract = "">
	<cfset var contractModifier = "">

	<cfset var firstSuits = {}>

	<cfloop index="local.bid" array="#arguments.hand.auction#">
		<cfset currentPlayer = getNextPosition(currentPlayer)>
		<cfswitch expression="#local.bid.data#">
			<cfcase value="pass,p,ap,all pass">
				
			</cfcase>
			
			<cfcase value="x,xx,r">
				<cfset contractModifier = local.bid.data>
			</cfcase>
			<cfdefaultcase>
				<cfset contract = local.bid.data>
				<cfset local.suit = Right(contract,1)>
				<cfif NOT structKeyExists(firstSuits, local.suit)>
					<cfset firstSuits[local.suit] = currentPlayer>
				</cfif>
				<cfset contractModifier = "">
			</cfdefaultcase>
		</cfswitch>
		
	</cfloop>

	<cfset local.suit = Right(contract,1)>
	<cfset arguments.hand.declarer = Ucase(firstSuits[local.suit])>
	<cfset arguments.hand.contract = contract & contractModifier>

</cffunction>

<cffunction name="getOpener" returntype="String" output="false">
	
	<cfargument name="hand" required="true">
	
	<cfreturn getNextPosition(arguments.hand.declarer)>

</cffunction>

<cffunction name="outputPBN" returntype="String" output="false">

	<cfargument name="deal" required="true">

	<cfset var pbn = "">
	<cfset var cr = chr(13) & chr(10)>
	
	<cfloop index="local.field" array="#getPBNFieldOrder()#">
		
		<cfswitch expression="#local.field#">
			<cfcase value="comments">
				<cfloop index="local.comment" array="#arguments.deal[local.field]#">
					<cfset pbn &= "%#local.comment##cr#">
				</cfloop>
			</cfcase>

			<cfcase value="deal">
				<cfset local.dealStr = "">
				<cfloop index="local.pos" list="n,e,s,w">
					<cfset local.dealStr = listAppend(local.dealStr,arguments.deal.deal[local.pos]," ")>
				</cfloop>
				<cfset pbn &= "[#local.field# ""N:#local.dealStr#""]#cr#">
			</cfcase>
			<cfcase value="auction">
				<cfset local.notes = "">
				<cfset local.col = 1>
				<cfset local.text = "">
				<cfset local.noteNum = 1>
				<cfset local.notes = "">
				<cfset local.who = arguments.deal.dealer>

				<cfloop index="local.action" array="#arguments.deal[local.field]#">
					
					<cfset local.text &= local.action.data & " ">
					<cfif structKeyExists(local.action, "note")>
						<cfset local.text &= "=#local.noteNum#= ">
						<cfset local.notes &= "[Note ""#local.noteNum#:#local.action.note#""]" & cr>
						<cfset local.noteNum += 1>
					</cfif>
					<cfset local.col += 1>
					<cfif local.col eq 5>
						<cfset local.text = Trim(local.text) & cr>
						<cfset local.col = 1>
					</cfif>
				</cfloop>

				<cfset pbn &= "[#local.field# ""#Ucase(local.who)#""]" & cr & local.text& cr & local.notes>
			</cfcase>	
			<cfcase value="play">
				<cfset local.notes = "">
				<cfset local.col = 1>
				<cfset local.text = "">
				<cfset local.noteNum = 1>
				<cfset local.notes = "">
				<cfset local.who = getOpener(arguments.deal)>

				<cfset local.dealStr = convertPlayArrayToPBNNonsense(arguments.deal,local.who)>
				<!--- 
				<cfloop index="local.action" array="#arguments.deal[local.field]#">
					
					<cfset local.text &= local.action.data & " ">
					<cfif structKeyExists(local.action, "note")>
						<cfset local.text &= "=#local.noteNum#= ">
						<cfset local.notes &= "[Note ""#local.noteNum#:#local.action.note#""]" & cr>
						<cfset local.noteNum += 1>
					</cfif>
					<cfset local.col += 1>
					<cfif local.col eq 5>
						<cfset local.text = Trim(local.text) & cr>
						<cfset local.col = 1>
					</cfif>
				</cfloop>
 --->
				<cfset pbn &= "[#local.field# ""#Ucase(local.who)#""]" & cr & local.dealStr>
			</cfcase>	

			<cfdefaultcase>
				<cfset pbn &= "[#local.field# ""#arguments.deal[local.field]#""]#cr#">
			</cfdefaultcase>
		</cfswitch>
	</cfloop>

	<cfreturn pbn>
	
</cffunction>

<cffunction name="parseLin" int="Parse lin into data struct like handviewer">
	
	<cfargument name="Lin">
	<cfset var nextAction = "ignore">
	<cfset var field = false>
	<cfset var list = ["s","w","n","e"]>
	<cfset var data = {"a"="","p"=""}>

	<cfloop index="field" list="#arguments.lin#" delimiters="|">
	
		<cfswitch expression="#field#">
			<cfcase value="pn">
				<cfset nextAction = "names">
			</cfcase>
			<cfcase value="st,pg,rh">
				<cfset nextAction = "ignore">
			</cfcase>
			<cfcase value="md">
				<cfset nextAction = "hand">
			</cfcase>
			<cfcase value="mb">
				<cfset nextAction = "bid">
			</cfcase>
			<cfcase value="pc">
				<cfset nextAction = "play">
			</cfcase>
			<cfdefaultcase>
				<cfswitch expression="#nextAction#">
					<cfcase value="names">
						<cfloop index="local.i" from="1" to="4">
							<cfset data[list[local.i] & "n"] = ListGetAt(field,local.i)>
						</cfloop>
 					</cfcase>
 					<cfcase value="hand">
						<cfset data["d"] = list[Left(field,1)]>
						<cfset data["s"] = ListGetAt(field,1)>
						<cfset data["s"] = Right(data["s"],Len(data["s"]) - 1)>
						<cfset data["w"] = ListGetAt(field,2)>
						<cfset data["n"] = ListGetAt(field,3)>
						<cfif ListLen(field) eq 3>
							<cfset data["e"] = "">
						<cfelse>
							<cfset data["e"] = ListGetAt(field,4)>
						</cfif>
 					</cfcase>
 					<cfcase value="bid">
						<cfset data["a"] &= field>
 					</cfcase>
 					<cfcase value="play">
						<cfset data["p"] &= field>
 					</cfcase>
 				</cfswitch>
				<cfset nextAction = "ignore">
			</cfdefaultcase>
		</cfswitch>


	</cfloop>

	
	<cfreturn data>

</cffunction>



<CFSCRIPT>
/**
 * Check that cards are in the right order and if one hand is left undealt, assign all other cards to it.
 * @param  struct deal     A struct with keys for each known hand (n,s,e,w)
 */
struct function checkDeal(struct deal) {

	var cards = {2=2,3=3,4=4,5=5,6=6,7=7,8=8,9=9,"T"=10,"J"=11,"Q"=12,"K"=13,"A"=14};
	var dealtCards = {};
	var card = false;
	var suit = false;
	var suitList = ['S','H','D','C'];
	for (suit in suitList) {
		for (card in cards) {
			dealtCards["#suit##card#"] = 0;
		}
	}

	var hand = false;
	var suits = false;
	var suitName = false;
	// create a temporary struct where every card is represented as a key of a substruct
	var dealStruct = {};
	for (var player in ['N','S','E','W']) {
		dealStruct[player] = {};
		if (NOT structKeyExists(arguments.deal, player)) arguments.deal[player] = "";
		// replace 10s
		arguments.deal[player] = replace(arguments.deal[player],"10","T","all");
		// looop over sting e.g. S59JKAH5KD79JC47J
		suitName = "S";
		for (var i=1 ; i lte Len(arguments.deal[player]); i++) {
			card = Mid(arguments.deal[player],i,1);
			if (NOT structKeyExists(cards,card)) {
				suitName = card;
				dealStruct[player][suitName] = {};
				continue;
			}
			dealStruct[player][suitName][card] = cards[card];
			dealtCards["#suitName##card#"] = 1;
		}
	}

	// check undealt cards
	var undealtCards = [];
	for (card in dealtCards) {
		if (dealtCards[card] eq 0) arrayAppend(undealtCards,card);
	}
	
	
	// deal remainder. nb if just one hand is missing it won't be random!
	var count = false;

	for (player in ['N','S','E','W']) {
		count = 0;
		for (suitName in suitList) {
			if (structKeyExists(dealStruct[player],suitName)) {
				count += structCount(dealStruct[player][suitName]);
			}
		}
		if (count NEQ 13) {
			for (i = 1 ; i lte (13 - count) ; i++) {
				local.newPos = RandRange(1,arrayLen(undealtCards));
				local.newCard = undealtCards[local.newPos];
				suitName = Left(local.newCard,1);
				card = Right(local.newCard,1);
				dealStruct[player][suitName][card] = cards[card];
				arrayDeleteAt(undealtCards, local.newPos);
			}
		}
	}

	// sort cards and update original struct
	for (player in ['N','S','E','W']) {
		local.hand = "";
		for (suitName in suitList) {
			// sort cards and create single string
			local.suit = Replace(ArrayToList(structSort(dealStruct[player][suitName], "numeric", "desc")),",","","all");

			local.hand = ListAppend(local.hand,local.suit,".");
		}
		arguments.deal[player] = local.hand;
	}
	return dealStruct;
}


private function getNextPosition(pos) {
        
    var posList = 'swne';
    var posFind = FindNoCase(arguments.pos,posList);
    if (posFind gt 0) {
        posFind += 1;
        if (posFind == 5) {
            posFind = 1;
        }
    }
    else {
        throw(message = 'Invalid bridge position ' & arguments.pos,type="bridge");
    }

    return Mid(posList,posFind,1);
}
private function getPreviousPosition(pos) {
        
    var posList = 'swne';
    var posFind = FindNoCase(arguments.pos,posList);
    if (posFind gt 0) {
        posFind -= 1;
        if (posFind == 0) {
            posFind = 4;
        }
    }
    else {
        throw(message = 'Invalid bridge position ' & arguments.pos,type="bridge");
    }

    return Mid(posList,posFind,1);
}


struct function playerCardStruct(deal) {
	
	var suits = ["s","h","d","c"];
	var retVal = {};
	var player = false;
	var i = false;
	var j = false;
	var cards = false;

	for (player in deal) {
		cards = ListToArray(deal[player],".",true);
		for (i=1; i lte 4; i++) {
			for (j=1; j lte Len(cards[i]) ; j++) {
				retVal[suits[i] & Mid(cards[i],j,1)] = player;
			}
		}
	}
	return retVal;	
}

</CFSCRIPT>