<cfscript>
coldsoupObj = new coldsoup.coldsoup(server.system.environment.javalib & "\jsoup-1.20.1.jar");
bridge = new bridgetestObj(jsoupObj=coldsoupObj);
logger = new logger.logger(debug=1);
bridge.loggerObj = logger;
path = getDirectoryFromPath(getCurrentTemplatePath());


auction = "1♣ - 1♠ -
4♠ - 4NT -
5♥ - ?  ";

dump( bridge.parseAuction(auction) );
</cfscript>