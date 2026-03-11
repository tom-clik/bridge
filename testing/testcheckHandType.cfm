<cfscript>
bridge = new bridge.testing.bridgeTestObj();
logger = new logger.logger(debug=1);

bridge.loggerObj = logger;
path = getDirectoryFromPath(getCurrentTemplatePath());

tests = [
	{
	"name"="Simple suit combo",
	"text"="kq7 - A3 - "
	},
  {"name"="Hand Vertical",
    "text"="
    akq78.5634.kq7.7
   "}
  ,{"name"="Hand Inline",
    "text"="akq78.5634.kq7.7"
   } ,{"name"="Simple hand",
    "text"="-.akq78.5634.kq75"}
 ];
 
for (test in tests) {
	writeOutput("<h2>#test.name#</h2>");
	styleAtts= {};
	bridge.checkHandType(test.text,styleAtts);
	dump( styleAtts );
}



</cfscript>