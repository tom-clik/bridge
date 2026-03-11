<cfscript>
bridge = new bridge.testing.bridgeTestObj();
logger = new logger.logger(debug=1);

bridge.loggerObj = logger;
path = getDirectoryFromPath(getCurrentTemplatePath());

deal = "S:.63.AKQ987.A9732 - J973.J98742.3.K4";

dump( bridge.parseDealData(deal) );
</cfscript>