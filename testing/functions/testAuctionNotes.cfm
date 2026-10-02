<cfscript>
// Run /bridge/testing/functions/testAuctionNotes.cfm on the local CFML server.
markdown = new markdown.testing.flexmarkTestObj();
bridge = new bridge.testing.auctionNotesTestObj(jsoupObj=markdown.coldsoupObj);
failures = [];
checks = 0;

function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) failures.append(arguments.message);
}

auction = '[Auction "N"]
1C =1= P 1H =2= P
2H =3= P P P
[Note "1:Strong club"]
[Note "2:Natural: four or more hearts"]
[Note "3:Support
with a minimum hand"]';
data = bridge.parsePBN(auction);
check(data.notes.len() == 3, "All consecutive auction notes are retained");
if (data.notes.len() == 3) {
    check(data.notes[2].marker == "2" && data.notes[3].marker == "3", "Note markers retain their order");
    check(data.notes[2].note == "Natural: four or more hearts", "Colons in note text are preserved");
    check(find("with a minimum hand", data.notes[3].note) > 0, "Multiline note text is preserved");
}
html = bridge.displayAuction(data, {"style":"0_4"});
for (marker in [1, 2, 3]) {
    check(find("(#marker#)</span>", html) > 0, "Auction call displays marker #marker#");
    check(find("<td>(#marker#)</td>", html) > 0, "Note table displays note #marker#");
}

withPlay = bridge.parsePBN(auction & '
[Play "N"]
SA S2 S3 S4
[Note "1:Play note must not replace auction note"]
[Note "4:Another play note"]');
check(withPlay.notes.len() == 3, "Play notes are excluded after auction notes");
check(withPlay.notes[1].note == "Strong club", "Reused play marker does not overwrite auction note");

playOnly = bridge.parsePBN('[Play "N"]
SA S2 S3 S4
[Note "1:Play only"]
[Note "2:Also play only"]');
check(!structKeyExists(playOnly, "notes"), "A play-only record has no auction notes");

orphan = bridge.parsePBN('[Note "1:No auction"]');
check(!structKeyExists(orphan, "notes"), "A note without an auction is ignored");

// Square-bracket annotations belong to auction text, not to PBN records.
bracketAuction = '[Auction "N"] 1C [1] P 1H [2] P [Note "1:Strong club"] [Note "2:Natural [four hearts]"]';
tags = bridge.parseTaggedText(bracketAuction);
check(tags.len() == 3, "Square-bracket markers do not create PBN records");
check(tags[1].text == "1C [1] P 1H [2] P", "Complete auction text retains square-bracket annotations");
bracketData = bridge.parsePBN(bracketAuction);
check(bracketData.auction.len() == 4, "Calls after square-bracket annotations are retained");
check(!structKeyExists(bracketData, "1") && !structKeyExists(bracketData, "2"), "Annotation markers do not become PBN keys");
check(structKeyExists(bracketData, "notes") && bracketData.notes.len() == 2, "Notes still belong to the annotated auction");
if (structKeyExists(bracketData, "notes") && bracketData.notes.len() == 2) {
    check(bracketData.notes[2].note == "Natural [four hearts]", "Brackets inside quoted tag values are preserved");
}
// Bracketed text without a valid tag name and quoted value stays in the body.
tags = bridge.parseTaggedText('[Auction "N"] 1C [1] [Note] [Note unquoted] [1 "invalid"] P [Note "1:Strong club"]');
check(tags.len() == 2 && tags[1].text == '1C [1] [Note] [Note unquoted] [1 "invalid"] P', "Invalid PBN headers remain in the preceding record text");

// Auction seats may be omitted when the Dealer tag supplies the opening seat.
for (auctionTag in ['[auction]', '[Auction]', '[ Auction ]', '[Auction ""]']) {
    source = '[Dealer "S"] [Vulnerable "EW"] [Deal "S:aq2.t72.a53.aj74 kt765.q95.7.9862 j843.akj.k82.kq5 9.8643.qjt964.t3"] ' & auctionTag & ' 1nt p 4c p 4nt p 6nt ap';
    data = bridge.parsePBN(source);
    check(structKeyExists(data, "auction"), "#auctionTag# creates an auction record");
    check(data.dealer == "S", "#auctionTag# preserves the Dealer tag");
    if (structKeyExists(data, "auction")) {
        check(data.auction.len() == 8 && data.auction[1].bid == "1nt", "#auctionTag# retains all calls");
        html = bridge.displayAuction(data, {"style":"0_4"});
        document = markdown.coldsoupObj.Jsoup.parse(html);
        check(findNoCase("1", document.select("tbody tr").first().select("td").first().text()) == 1, "#auctionTag# starts the auction in South's column");
    }
}
for (seat in ["W", "N", "E"]) {
    data = bridge.parsePBN('[Dealer "#seat#"] [auction] 1C P P P');
    if (structKeyExists(data, "auction")) {
        html = bridge.displayAuction(data, {"style":"0_4"});
        document = markdown.coldsoupObj.Jsoup.parse(html);
        cells = document.select("tbody tr").first().select("td");
        offset = arrayFind(["S", "W", "N", "E"], seat) - 1;
        check(cells.get(javacast("int", offset)).text() == "1♣", "Bare auction starts in Dealer #seat#'s column");
    } else {
        check(false, "Bare auction is parsed for Dealer #seat#");
    }
}
data = bridge.parsePBN('[Dealer "S"] [Auction "E"] 1C P P P');
check(data.dealer == "E", "Explicit auction seat still overrides Dealer");
data = bridge.parsePBN('[auction] 1C [1] P P P [Note "1:Strong club"]');
check(structKeyExists(data, "auction"), "Bare auction works without a Dealer tag");
if (structKeyExists(data, "auction")) {
    html = bridge.displayAuction(data, {"style":"0_4"});
    check(data.dealer == "s", "Auction without either seat defaults to South");
    check(data.auction.len() == 4 && data.notes.len() == 1, "Bare auctions retain bracket annotations and notes");
}

single = bridge.parsePBN('[Auction "S"]
1NT =1= P P P
[Note "1:15-17"]');
check(single.notes.len() == 1 && single.notes[1].note == "15-17", "Single-note auctions still work");

cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
