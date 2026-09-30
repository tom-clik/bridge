<cfscript>
markdown = new markdown.testing.flexmarkTestObj();
plugin = new bridge.html_plugin(coldsoupObj=markdown.coldsoupObj);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
cases = [
    {name:"Markdown paragraph and list boundaries", text:"## Heading" & chr(10) & chr(10) & "First paragraph." & chr(10) & chr(10) & "* Item one" & chr(10) & "* Item two"},
    {name:"Table fragments", text:'<tr><td>Keep this cell</td><td>And this one</td></tr>'},
    {name:"Self-closing publication includes", text:'<div href="chapter.md" />' & chr(10) & '<div href="next.md" />'},
    {name:"Inline whitespace", text:'<p>Hello <em>world</em> and <strong>everyone</strong>.</p>'},
    {name:"General inline code", text:'<p>Run <code>git status</code>.</p>'},
    {name:"Scripts and comments", text:'<!-- ♥ --><script>const x = "<code>1♥</code>";</script>'}
];
for (item in cases) check(plugin.process(item.text) == item.text, item.name & " is preserved exactly");
source = "## Heading" & chr(10) & chr(10) & "* Play 1♥" & chr(10) & "* Next item";
expected = replace(source, "♥", "<span class='suit h'>♥</span>");
check(plugin.process(source) == expected, "Adding a suit span leaves all Markdown whitespace intact");
source = '<div href="chapter.md" />' & chr(10) & '<tr><td><code>1♥ - (Pass) - 2♥ - (2♠)</code></td></tr>';
converted = plugin.process(source);
check(find('<div href="chapter.md" />' & chr(10) & '<tr><td>', converted) == 1, "Auction conversion preserves enclosing includes and table fragments");
check(find('bridge-inline-auction', converted) > 0, "Auction converts inside an otherwise preserved fragment");
check(plugin.process(converted) == converted, "Repeated processing does not add nested suit spans or change whitespace");
converted = plugin.process('<bridge data-image="images/hand.png">AKQ.432.AJ98.765</bridge>');
node = markdown.coldsoupObj.parse(converted).select("div.bridge").first();
check(node.attr("data-image") == "images/hand.png", "Bridge image reference survives HTML conversion");
converted = plugin.process('<bridge data-image="images/hand.png" width="200">AKQ.432.AJ98.765</bridge>');
node = markdown.coldsoupObj.parse(converted).select("div.bridge").first();
check(node.attr("width") == "200", "Bridge image display width survives HTML conversion");
converted = plugin.process('<bridge data-image="images/a&amp;b&quot;c.png">AKQ.432.AJ98.765</bridge>');
node = markdown.coldsoupObj.parse(converted).select("div.bridge").first();
check(node.attr("data-image") == 'images/a&b"c.png', "Bridge image reference is safely escaped");
converted = plugin.process('<bridge>AKQ.432.AJ98.765</bridge>');
check(!find("data-image", converted), "Bridge diagrams without image references stay unchanged");
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(),"checks":checks,"failures":failures}));
</cfscript>
