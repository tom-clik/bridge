<cfscript>
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
markdown = new markdown.flexmark(attributes=true,typographic=true,
    jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar",coldsoupObj=soup);
htmlPlugin = new bridge.html_plugin(coldsoupObj=soup);
coldlightPlugin = new bridge.coldlight_plugin(markdownObj=markdown,coldsoupObj=soup);
cases = [
    {attributes:"vertical", vertical:true, inline:false},
    {attributes:'vertical="yes"', vertical:true, inline:false},
    {attributes:'vertical="true"', vertical:true, inline:false},
    {attributes:'vertical="1" inline="yes"', vertical:true, inline:false},
    {attributes:'vertical type="hand"', vertical:true, inline:false},
    {attributes:'vertical="no"', vertical:false, inline:true},
    {attributes:'vertical="false"', vertical:false, inline:true},
    {attributes:'inline="no"', vertical:false, inline:false},
    {attributes:'inline', vertical:false, inline:true},
    {attributes:'', vertical:false, inline:true}
];
failures = [];
checks = 0;
for (item in cases) {
    source = '<bridge ' & item.attributes & '>AKQ.432.AJ98.765</bridge>';
    section = {node:soup.parse(source)};
    coldlightPlugin.process(section=section,document={basepath:""});
    outputs = {preview:soup.parse(htmlPlugin.process(doc={html:source})), coldlight:section.node};
    for (adapter in outputs) {
        node = outputs[adapter].select(".bridge").first();
        checks++;
        if (node.hasClass("vertical") != item.vertical || node.hasClass("inline") != item.inline)
            failures.append(adapter & ': ' & item.attributes & ' produced ' & node.className());
        checks++;
        if (node.select(".bridgehand > .suit").size() != 4 || node.select(".bridgehand > .cards").size() != 4)
            failures.append(adapter & ': hand contents changed for ' & item.attributes);
    }
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
