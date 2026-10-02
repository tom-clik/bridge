<cfscript>
bridge = new bridge.testing.bridgeTestObj();

auction = "1♣ - 1♠ -
4♠ - 4NT -
5♥ - ?  ";

dump( bridge.parseAuction(auction) );
</cfscript>