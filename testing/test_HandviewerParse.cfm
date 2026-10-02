<cfscript>
parser = new bridge.bridge_parser();
text = fileRead(expandPath("../handviewer_samples/test1.txt"));
hand = parser.parseHandviewer(input=text, resolveURLs=false);
writeOutput("<pre>" & encodeForHTML(parser.exportPBN(hand)) & "</pre>");
</cfscript>
