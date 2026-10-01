<cfscript>
markdown = new markdown.testing.flexmarkTestObj();
soup = markdown.coldsoupObj;
plugin = new bridge.coldlight_kindle(markdownObj=markdown,coldsoupObj=soup);
checks = 0;
failures = [];
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
source = '<div class="bridge vertical"><span class="bridgehand" id="original" data-test="preserve"><span class="suit s">♠</span><span class="cards">A K Q J 10 9 8 7 6 5 4 3 2</span><span class="suit h">♥</span><span class="cards">-</span><span class="suit d">♦</span><span class="cards">-</span><span class="suit c">♣</span><span class="cards">-</span></span></div>';
section = {node:soup.parse(source)};
originalCells = section.node.select(".bridgehand").first().children();
originalHtml = [];
for (cell in originalCells) originalHtml.append(cell.outerHtml());
plugin.process(section=section,document={});
table = section.node.select("div.bridge.vertical > div.nobreak > table.bridgehand").first();
check(!isNull(table), "Vertical hand becomes a table inside its original wrapper");
check(table.attr("id") == "original" && table.attr("data-test") == "preserve", "Hand attributes survive");
check(table.select("tbody > tr").size() == 4, "Four rows");
check(table.select("tbody > tr > td").size() == 8, "Eight cells");
convertedCells = table.select("td > span");
check(convertedCells.size() == 8, "All eight spans survive");
for (i = 0; i < 8; i++) {
    check(convertedCells.get(i).equals(originalCells.get(i)), "Original span node retained: " & i);
    check(convertedCells.get(i).outerHtml() == originalHtml[i + 1], "Span markup retained: " & i);
}
converted = section.node.body().html();
plugin.process(section=section,document={});
check(section.node.body().html() == converted, "Repeated conversion makes no changes");
section = {node:soup.parse(source & replace(source, 'id="original"', 'id="second"'))};
plugin.process(section=section,document={});
check(section.node.select("table.bridgehand").size() == 2, "Multiple hands convert");
section = {node:soup.parse(replace(source, 'class="bridge vertical"', 'class="bridge inline"'))};
original = section.node.body().html();
plugin.process(section=section,document={});
check(section.node.body().html() == original, "Inline hand remains unchanged");
section = {node:soup.parse(replace(source, '<span class="suit h">♥</span>', ''))};
original = section.node.body().html();
rejected = false;
try {
    plugin.process(section=section,document={});
} catch (bridge e) {
    rejected = true;
}
check(rejected, "Malformed hand rejected");
check(section.node.body().html() == original, "Validation leaves malformed hand intact");
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>