<cfscript>
// Run /bridge/testing/functions/testInlineAuctions.cfm on the local CFML server.
markdown = new markdown.testing.flexmarkTestObj();
soup = markdown.coldsoupObj;
coldPlugin = new bridge.coldlight_plugin(markdownObj=markdown, coldsoupObj=soup);
htmlPlugin = new bridge.html_plugin(coldsoupObj=soup);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}

fixture = '<p>After <code class="existing" title="Keep">1♥ - (Pass) - 2♥ - (2♠)</code>.</p>
<p><code>&lt;b&gt;1♦ &amp; 2♣&lt;/b&gt;</code></p>
<pre><code>1♥ &lt; 2♠</code></pre>
<p title="1♥">Ordinary 1♥ prose.</p>
<p><span class="suit h">♥</span></p>';

for (mode in ["coldlight", "html"]) {
    if (mode == "coldlight") {
        section = {"node":soup.Jsoup.parse(fixture)};
        coldPlugin.process(section=section, document={"basepath":""});
        node = section.node;
    } else {
        output = htmlPlugin.process(doc={html:fixture});
        check(!findNoCase("<html", output), "HTML fragments remain fragments");
        node = soup.Jsoup.parse(output);
    }
    check(node.select("span.bridge-inline-auction").size() == 1, mode & ": auction code becomes an auction span");
    check(node.select("p code").size() == 1, mode & ": non-auction inline code remains code");
    check(node.select("span.bridge-inline-auction.existing[title=Keep]").size() == 1, mode & ": attributes are preserved");
    check(node.select(".bridge-inline-auction .suit").size() == 3, mode & ": inline auction suits have styling spans");
    check(node.select(".bridge-inline-auction b").isEmpty(), mode & ": escaped markup stays literal");
    check(node.select("p code").first().text() == "<b>1♦ & 2♣</b>", mode & ": escaped non-auction code is preserved");
    check(node.select("pre code").size() == 1 && node.select("pre span").isEmpty(), mode & ": fenced code stays literal");
    check(node.select("pre code").text() == "1♥ < 2♠", mode & ": code block text is preserved");
    check(node.select("p[title]").last().attr("title") == "1♥", mode & ": suit in an attribute is unchanged");
    check(node.select(".suit .suit").isEmpty(), mode & ": existing suit spans are not nested");
}

full = htmlPlugin.process(doc={html:'<!DOCTYPE html><html><head><title>Test</title></head><body><code>1♥</code></body></html>'});
check(findNoCase("<!doctype html>", full) > 0 && findNoCase("<head>", full) > 0, "Full HTML documents retain their document structure");

// End-to-end Markdown conversion, independent of any local publication files.
rendered = markdown.markdown(text='After `1♥ - (Pass) - 2♥ - (2♠)` and `1♦ - (Pass) - 1♥ - (2♠)`.

<bridge style="0_4" info="0">
[Auction "W"]
1H Pass 2H 2S
2NT =1= Pass 3C =2= Pass
3H =3=
[Note "1:Artificial."]
[Note "2:Relay."]
[Note "3:Competitive."]
</bridge>', options={"meta":false});
coldPlugin.process(section=rendered, document={"basepath":""});
check(rendered.node.select(".bridge-inline-auction").size() == 2, "Both Markdown backtick auctions become spans");
check(rendered.node.select("code").isEmpty(), "Converted Markdown has no remaining inline code");
check(rendered.node.select(".bridgeauction .note").size() == 3, "Full auction annotations still render");
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
