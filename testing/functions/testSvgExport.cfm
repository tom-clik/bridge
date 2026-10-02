<cfscript>
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
parser = new bridge.bridge_parser(jsoupObj=soup);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    checks++;
    if (!condition) failures.append(message);
}
hand = parser.exportSvg("AKQ.10X..987", {title:'A & B <diagram> "test"'});
xml = xmlParse(hand);
check(xml.svg.xmlAttributes.xmlns == "http://www.w3.org/2000/svg", "SVG namespace");
check(xml.svg.title.xmlText == 'A & B <diagram> "test"', "Escaped accessible title");
check(arrayLen(xmlSearch(xml, "//*[local-name()='text']")) == 4, "Four suits in a hand");
check(find("10 x", hand) > 0, "Ten and unknown rank formatting");
check(find('style=', hand) == 0 && find('<style', hand) > 0, "Embedded CSS instead of inline styles");
check(find("foreignObject", hand) == 0 && find("word-spacing", hand) == 0, "Portable SVG primitives");
check(find('>-</tspan>', hand) > 0, "Empty suit rendered as a dash");
check(arrayLen(xmlSearch(xmlParse(parser.exportSvg("...")), "//*[local-name()='text']")) == 4, "All empty suits");
deal = 'E:AKQ.JT9.876.543 2.3.4.5 - T98.AKQ.JT9.876';
svg = parser.exportSvg('[Deal "' & deal & '"]');
xml = xmlParse(svg);
check(arrayLen(xmlSearch(xml, "//*[local-name()='text']")) == 16, "Three known hands and compass");
check(arrayLen(xmlSearch(xml, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-w']")) == 0, "Unknown West omitted");
east = xmlSearch(xml, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-e']");
check(find('A K Q', toString(east[1])) > 0, "East-starting deal rotation");
check(parser.exportSvg(deal) == svg, "Raw deal and PBN agree");
filtered = parser.exportSvg(deal, {deal:"NS", rose:false, monochrome:true});
check(arrayLen(xmlSearch(xmlParse(filtered), "//*[local-name()='text']")) == 8, "Seat selection and no compass");
check(find('class="bridge-svg bridge-svg-mono"', filtered) > 0, "Monochrome class");
longHand = xmlParse(parser.exportSvg("AKQJT98765432..."));
check(longHand.svg.xmlAttributes.width >= 280, "Long holdings grow the canvas");
for (bad in ["", "AKQ.JT.98", "N:AKQ.JT9.876.543", '[Event "No deal"]', "AK-Q...", "AKQ<script>..."]) {
    rejected = false;
    try { parser.exportSvg(bad); } catch (any e) { rejected = true; }
    check(rejected, "Reject invalid input: " & bad);
}
for (badOptions in [{deal:"bad"}, {rose:"maybe"}, {monochrome:"maybe"}, {unknown:true}]) {
    rejected = false;
    try { parser.exportSvg("AKQ.JT9.876.543", badOptions); } catch (any e) { rejected = true; }
    check(rejected, "Reject invalid options: " & serializeJSON(badOptions));
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
