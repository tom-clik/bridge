<cfscript>

PBNParser = new bridge.PBNparser();

text = urlDecode( FileRead( expandPath("../handviewer_samples/test1.txt") ) );

vals = PBNParser.parse( text );

writeDump(vals);

writeoutput("<pre>" & PBNParser.pbn(vals) & "</pre>");


</cfscript>