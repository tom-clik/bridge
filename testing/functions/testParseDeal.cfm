<cfscript>
bridge = new bridge.testing.bridgeTestObj();

deal = "S:.t.5. .q9.. .kj.. .8.j.";

dump( bridge.parseDealData(deal) );
</cfscript>