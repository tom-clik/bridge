<cfscript>
bridge = new bridge.testing.bridgeTestObj();

data = [
	{result="9",contract="3nt",expected="="},
	{result="4",contract="7nt",expected="-9"},
	{result="10",contract="3nt",expected="+1"}
];

for (test in data) {
	res = bridge.getResultStr( result=test.result,contract=test.contract) ;
	if ( res neq test.expected ) {
		throw("incorrect test return: #test.result# #test.contract# #res# <> #test.expected#");
	}
}

writeOutput("passed ok");

</cfscript>