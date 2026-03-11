<cfscript>
bridge = new bridge.testing.bridgeTestObj();

data = bridge.parsePBN(bridge.testhand) ;
// writeDump( var=data );

html = bridge.displayDeal(data, {"hands"="NS","rose"=0});
writeOutput(htmlCodeFormat(html));

writeOutput(bridge.styles);
writeOutput(html);

html = bridge.displayAuction(data, {"style"="2_4_1"});
writeOutput(htmlCodeFormat(html));

writeOutput(html);


</cfscript>