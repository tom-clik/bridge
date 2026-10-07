<cfscript>
bridge = new bridge.testing.bridgeTestObj();

data = [
	{val="4S",expected="4<span class='suit S'>♠</span>"},
	{val="JH",expected="J<span class='suit H'>♥</span>"},
	{val="C2",expected="<span class='suit C'>♣</span>2"}
];

for (test in data) {
	res = bridge.replaceSuitLetter( test.val ) ;
	if ( res neq test.expected ) {
		throw("incorrect test return: #test.val# #res# <> #test.expected#");
	}
}

writeOutput("passed ok");

</cfscript>