<cfscript>
bridge = new bridge.testing.bridgeTestObj();

hand = "63 AKQ";
res = bridge.parseSuitCombo(hand) ;
writeDump(res);

hand = "63 AKQ 789 t5j";
res2 = bridge.parseSuitCombo(hand) ;
writeDump(res2);

html = bridge.displaySuitCombo(res);
writeOutput(htmlCodeFormat(html));

writeOutput(bridge.styles);

writeOutput(html);

html = bridge.displaySuitCombo(res2);
writeOutput(htmlCodeFormat(html));

writeOutput(html);

// <!--- this doesn't work... --->
// writeOutput("<style>.inline { --card-font:inherit;}</style>");

// writeOutput("Text in here <div class='bridge inline'>" & html & "</div> and here");
</cfscript>