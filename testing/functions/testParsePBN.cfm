<cfscript>
bridge = new bridge.testing.bridgeTestObj();

//data = bridge.parsePBN(bridge.testhand) ;

deal ="[Deal ""S:JT3.9.AQ75.AT643""]
[South ""Partner""]
[North ""You""]
[Auction ""S""]
1C P 2C";

deal = "[Deal ""S:.t.5. .q9.. .kj.. .8.j.""]";
data = bridge.parsePBN(deal);
writeDump(data);

abort;
html = bridge.displayDeal(data, {"deal"="S","rose"=0});
writeOutput(htmlCodeFormat(html));

writeOutput(bridge.styles);
writeOutput(html);

html = bridge.displayAuction(data, {"auction"="NS"});
writeOutput(htmlCodeFormat(html));

writeOutput(html);


</cfscript>