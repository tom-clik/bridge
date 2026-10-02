<cfscript>
markdown = new markdown.testing.flexmarkTestObj();
soup = markdown.coldsoupObj;
htmlPlugin = new bridge.html_plugin(coldsoupObj=soup);
coldlightPlugin = new bridge.coldlight_plugin(markdownObj=markdown,coldsoupObj=soup);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
function renderBoth(required string source) {
    var section = {node:variables.soup.parse(arguments.source)};
    variables.coldlightPlugin.process(section=section,document={basepath:""});
    return {
        preview:variables.soup.parse(variables.htmlPlugin.process(doc={html:arguments.source})),
        coldlight:variables.soup.parse(section.node.body().html())
    };
}
// Reparse the final HTML to catch block elements that split a prose paragraph.
for (atts in ["", "inline", 'inline="yes"', 'type="hand" inline']) {
    outputs = renderBoth('<p>Before <bridge ' & atts & ' data-image="hand.png" width="200">AKQ.432.AJ98.765</bridge> after</p>');
    for (adapter in outputs) {
        doc = outputs[adapter];
        check(doc.select("p").size() == 1, adapter & ": inline hand preserves one paragraph");
        check(doc.select("p > span.bridge.inline").size() == 1, adapter & ": inline wrapper stays inside paragraph");
        check(left(doc.select("p").text(), 6) == "Before" && right(doc.select("p").text(), 5) == "after",
            adapter & ": surrounding prose remains in paragraph");
        hand = doc.select(".bridge").first();
        check(hand.attr("data-image") == "hand.png" && hand.attr("width") == "200",
            adapter & ": inline image attributes survive");
    }
}
for (atts in ['inline="no"', 'vertical inline="yes"']) {
    outputs = renderBoth('<bridge ' & atts & '>AKQ.432.AJ98.765</bridge>');
    for (adapter in outputs)
        check(outputs[adapter].select("div.bridge").size() == 1, adapter & ": block hand keeps div wrapper");
}
// Each supported legacy separator must produce the same four suits as dotted notation.
expected = soup.parse(htmlPlugin.process(doc={html:'<bridge type="hand">AKQ.432.AJ98.765</bridge>'})).select(".bridgehand").html();
for (separator in [chr(10), chr(13), chr(13) & chr(10), ",", " "]) {
    outputs = renderBoth('<bridge type="hand">' & arrayToList(["AKQ","432","AJ98","765"], separator) & '</bridge>');
    for (adapter in outputs)
        check(outputs[adapter].select(".bridgehand").html() == expected, adapter & ": legacy separator " & asc(separator));
}
// The publication must continue after a bad tag and still format valid hands and prose.
section = {node:soup.parse('<p>Before</p><bridge type="hand">AKQ.432</bridge><p>Play 1♥</p><bridge>AKQ.432.AJ98.765</bridge><p>After</p>')};
coldlightPlugin.process(section=section,document={basepath:""});
check(find("<!-- Failed to parse bridge hand -->", section.node.body().html()) > 0, "Malformed tag becomes fallback comment");
check(section.node.select(".bridgehand").size() == 1, "Valid hand after malformed tag still renders");
check(section.node.select("p .suit.h").size() == 1, "Prose still receives suit formatting");
check(find("Before", section.node.text()) && find("After", section.node.text()), "Surrounding publication survives");
// Metadata and deal must share the positioned full-diagram wrapper.
pbn = '[Dealer "N"]' & chr(10) & '[Vulnerable "EW"]' & chr(10) & '[Scoring "MP"]' & chr(10) & '[Deal "N:AKQ.432.AJ98.765"]';
for (atts in ['info="yes"', 'dealer="yes"', 'vulnerable="yes"', 'scoring="yes"']) {
    outputs = renderBoth('<bridge auction="0" ' & atts & '>' & pbn & '</bridge>');
    for (adapter in outputs) {
        check(outputs[adapter].select("div.bridgefull > .bridgeinfo").size() == 1, adapter & ": metadata inside full wrapper for " & atts);
        check(outputs[adapter].select("div.bridgefull > .bridgedeal").size() == 1, adapter & ": deal shares metadata wrapper");
    }
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
