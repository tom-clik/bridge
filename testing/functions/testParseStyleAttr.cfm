<cfscript>
bridge = new bridge.testing.bridgeTestObj();

attrs={"style"='2_4_1'};
bridge.parseStyleShortcuts(attrs)
dump( attrs );

attrs={"style"='2_2'};
bridge.parseStyleShortcuts(attrs)
dump( attrs );

attrs={"auction"='EW',"deal"="EW", "rose"=0};
bridge.parseStyleShortcuts(attrs)
dump( attrs );
</cfscript>