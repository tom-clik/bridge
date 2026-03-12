<cfscript>
bridge = new bridge.testing.bridgeTestObj();

deal = "[Deal ""S:.t.5. .q9.. .kj.. .8.j.""]";

dump( bridge.parseTaggedText(deal) );
</cfscript>