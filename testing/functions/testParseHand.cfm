<cfscript>
bridge = new bridge.testing.bridgeTestObj();

hand = "63.AKQ..A32";
res = bridge.parseHand(hand) ;
writeDump(res);

html = bridge.displayHand(res);
writeOutput(htmlCodeFormat(html));

writeOutput(bridge.styles);

writeOutput(html);

<!--- this doesn't work... --->
writeOutput("<style>.inline { --card-font:inherit;}</style>");

writeOutput("Text in here <div class='bridge inline'>" & html & "</div> and here");
</cfscript>