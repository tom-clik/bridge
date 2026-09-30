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

single = bridge.parsePBN('[Auction "S"]
1NT =1= P P P
[Note "1:15-17"]');
check(single.notes.len() == 1 && single.notes[1].note == "15-17", "Single-note auctions still work");

cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
