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
check(find("foreignObject", hand) == 0, "Portable SVG primitives");
check(find('data:font', hand) == 0 && find('base64,', hand) == 0 && len(hand) < 5000,
    "SVG stays small without embedded fonts");
check(find('local("DejaVuSansMono")', hand) > 0, "Local PostScript name provided for Chrome");
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
check(longHand.svg.xmlAttributes.width >= 260, "Long holdings grow the canvas");
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
// Options must affect geometry as well as the exported text styling.
spaced = xmlParse(parser.exportSvg(deal, {fontSize:18, letterSpacing:1.5, wordSpacing:2,
    rowSpacing:28, suitGap:32, handGap:40, columnGap:20, padding:16}));
check(spaced.svg.xmlAttributes["letter-spacing"] == 1.5 && spaced.svg.xmlAttributes["word-spacing"] == 2
    && spaced.svg.xmlAttributes["font-size"] == 18, "Text spacing and font size exported");
northRows = xmlSearch(spaced, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-n']/*");
eastRows = xmlSearch(spaced, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-e']/*");
southRows = xmlSearch(spaced, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-s']/*");
check(northRows[2].xmlAttributes.y - northRows[1].xmlAttributes.y == 28, "Custom suit row spacing");
check(northRows[1].xmlChildren[2].xmlAttributes.x - northRows[1].xmlAttributes.x == 32, "Custom symbol-to-card gap");
check(eastRows[1].xmlAttributes.y - northRows[4].xmlAttributes.y == 40
    && southRows[1].xmlAttributes.y - eastRows[4].xmlAttributes.y == 40, "Custom inter-hand baseline gaps");
check(northRows[1].xmlAttributes.y == 34, "Font size and padding set first baseline");
check(spaced.svg.xmlAttributes.width > xml.svg.xmlAttributes.width
    && spaced.svg.xmlAttributes.height > xml.svg.xmlAttributes.height, "Canvas grows with spacing");
check(southRows[4].xmlAttributes.y < spaced.svg.xmlAttributes.height, "South remains inside canvas");
second = xmlParse(parser.exportSvg(deal, {columnGap:30}));
check(second.svg.xmlAttributes.width - xml.svg.xmlAttributes.width == 36, "Column gaps contribute to canvas width");
tight = parser.exportSvg("AKQ.10X..987", {letterSpacing:-1, wordSpacing:-2});
check(xmlParse(tight).svg.xmlAttributes["word-spacing"] == -2, "Negative spacing supported");
check(parser.exportSvg("AKQ.10X..987", {title:'A & B <diagram> "test"'}) == hand, "Options do not leak between exports");
for (badOptions in [{rowSpacing:0}, {fontSize:-1}, {padding:-1}, {suitGap:"oops"},
    {letterSpacing:-100}, {wordSpacing:-100}, {handGap:1001}, {columnGap:[]}, {fontSize:'14" onload="bad'}]) {
    rejected = false;
    try { parser.exportSvg("AKQ.JT9.876.543", badOptions); } catch (bridge.svg e) { rejected = true; }
    check(rejected, "Reject invalid spacing: " & serializeJSON(badOptions));
}
// Long outer suits must not change the N/S-to-rose offset or centered alignment.
function layout(required string source, struct options={}) {
    var doc = xmlParse(parser.exportSvg(source, options));
    var result = {width:val(doc.svg.xmlAttributes.width)};
    for (var seat in ["n","e","s","w"]) {
        var rows = xmlSearch(doc, "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-" & seat & "']/*");
        if (arrayLen(rows)) result[seat] = val(rows[1].xmlAttributes.x);
    }
    var rose = xmlSearch(doc, "//*[local-name()='rect']");
    if (arrayLen(rose)) {
        result.rose = val(rose[1].xmlAttributes.x);
        result.roseWidth = val(rose[1].xmlAttributes.width);
    }
    return result;
}
shortDeal = "N:A.K.Q.J A.K.Q.J A.K.Q.J A.K.Q.J";
longEast = "N:A.K.Q.J AKQJT98765432... A.K.Q.J A.K.Q.J";
longWest = "N:A.K.Q.J A.K.Q.J A.K.Q.J AKQJT98765432...";
longNorth = "N:AKQJT98765432... A.K.Q.J A.K.Q.J A.K.Q.J";
// DejaVu Sans Mono's hardcoded 1233/2048 advance scales linearly.
characterWidth = 14 * 1233 / 2048;
longAdvance = 26 * characterWidth;
expectedWingWidth = 24 + longAdvance;
shortWestWidth = 24 + characterWidth;
symbolLeft = 0;
baseLayout = layout(shortDeal);
for (source in [shortDeal, longEast, longWest, longNorth]) {
    diagram = layout(source);
    check(diagram.n == diagram.s && diagram.rose - diagram.n == 24, "Rose anchored handGap right of N/S");
    check(diagram.rose + diagram.roseWidth / 2 == diagram.width / 2, "Rose centered in canvas");
    check(diagram.n - diagram.width / 2 == baseLayout.n - baseLayout.width / 2,
        "N/S aligns across centered diagrams with differing suit lengths");
    check(abs(diagram.e + symbolLeft - (diagram.rose + diagram.roseWidth + 0.5) - 36) < 0.001, "East starts handGap plus columnGap from rose");
}
eastLayout = layout(longEast);
westLayout = layout(longWest);
check(eastLayout.width == westLayout.width && eastLayout.e == westLayout.e,
    "Swapping long East/West holdings preserves canvas width and East position");
check(abs(eastLayout.rose - 0.5 - (eastLayout.w + shortWestWidth) - 36) < 0.001,
    "Short West hand stays beside rose when East is long");
check(abs(westLayout.rose - 0.5 - (westLayout.w + expectedWingWidth) - 36) < 0.001,
    "Long West hand retains the same clearance from rose");
check(eastLayout.w - westLayout.w == expectedWingWidth - shortWestWidth,
    "Unused West column space is placed on the left");
check(eastLayout.w + shortWestWidth - eastLayout.width / 2 == baseLayout.w + shortWestWidth - baseLayout.width / 2,
    "West right edge aligns across centered deals when only East grows");
check(abs(westLayout.w + symbolLeft + eastLayout.e + expectedWingWidth - eastLayout.width) < 0.001,
    "Reserved E/W columns retain symmetric outer margins");
westRows = xmlSearch(xmlParse(parser.exportSvg(longEast)), "//*[local-name()='g' and @class='bridge-svg-hand bridge-svg-w']/*");
for (row in westRows)
    check(row.xmlAttributes.x == eastLayout.w, "West suits remain left-aligned within the right-aligned hand");
customShortWest = layout(longEast, {handGap:40, columnGap:20, padding:16});
check(abs(customShortWest.rose - 0.5 - (customShortWest.w + shortWestWidth) - 60) < 0.001,
    "Short West respects custom clearance from rose");
noRoseShortWest = layout(longEast, {rose:false});
check(noRoseShortWest.w == eastLayout.w, "Short West alignment retained with rose hidden");
check(layout(longNorth).n + expectedWingWidth <= layout(longNorth).width - 12, "Long N/S fits within padded canvas");
customLayout = layout(longWest, {handGap:40, columnGap:20, padding:16});
check(customLayout.rose - customLayout.n == 40
    && customLayout.rose - (customLayout.w + expectedWingWidth) == 60.5,
    "Custom handGap and columnGap apply to horizontal anchors");
check(abs(customLayout.e + symbolLeft - customLayout.rose - customLayout.roseWidth - 0.5 - 60) < 0.001, "Custom East gap matches West");
noRose = layout(longWest, {rose:false});
check(noRose.n == westLayout.n && noRose.w == westLayout.w && noRose.e == westLayout.e,
    "Hiding rose preserves horizontal alignment");
requestedSpacing = {handGap:"18", columnGap:"6", wordSpacing:"-4", suitGap:"12", rowSpacing:"16"};
compactWest = layout(longWest, requestedSpacing);
compactWidth = 12 + longAdvance - 12 * 4;
check(abs(compactWest.rose - 0.5 - compactWest.w - compactWidth - 24) < 0.001,
    "Exact reported settings leave 24 units after the longest West suit");
noWordSpacing = duplicate(requestedSpacing);
noWordSpacing.wordSpacing = 0;
unspacedWest = layout(longWest, noWordSpacing);
check(abs((unspacedWest.rose - unspacedWest.w) - (compactWest.rose - compactWest.w) - 48) < 0.001,
    "Twelve spaces at minus four remove 48 units of reserved width");
negativeLetters = duplicate(requestedSpacing);
negativeLetters.letterSpacing = -1;
letterWest = layout(longWest, negativeLetters);
check(abs(letterWest.rose - 0.5 - letterWest.w - (compactWidth - 25) - 24) < 0.001,
    "Negative letter spacing also changes the West anchor");
for (size in [10,12,14,16,18,20,22,24]) {
    automatic = parser.exportSvg(longWest, {fontSize:size});
    explicit = parser.exportSvg(longWest, {fontSize:size, characterWidth:size * 1233 / 2048});
    check(automatic == explicit, "Calculated default character width at font size " & size);
}
customWidth = layout(longWest, {characterWidth:"9.5"});
check(abs(customWidth.rose - 0.5 - customWidth.w - (24 + 26 * 9.5) - 36) < 0.001,
    "Explicit character width controls West alignment");
check(parser.exportSvg(longWest, {characterWidth:9.5}) == parser.exportSvg(longWest, {characterWidth:"9.5"}),
    "Character width accepts numeric strings");
for (badOptions in [{characterWidth:0}, {characterWidth:-1}, {characterWidth:"bad"},
    {characterWidth:[]}, {characterWidth:2, wordSpacing:-2}]) {
    rejected = false;
    try { parser.exportSvg(shortDeal, badOptions); } catch (bridge.svg e) { rejected = true; }
    check(rejected, "Reject invalid character width or nonpositive space advance");
}
fontOptions = {fontFamily:'"My Cards", monospace', suitFontFamily:"My Symbols", labelFontFamily:"My Labels"};
fontDoc = xmlParse(parser.exportSvg(shortDeal, fontOptions));
check(fontDoc.svg.xmlAttributes["font-family"] == fontOptions.fontFamily, "Escaped configurable card family");
check(xmlSearch(fontDoc, "//*[local-name()='tspan' and @font-family='My Symbols']").len() == 16,
    "Configurable suit family on every suit");
check(xmlSearch(fontDoc, "//*[local-name()='text' and @font-family='My Labels']").len() == 4,
    "Configurable label family");
for (badOptions in [{fontFamily:""}, {suitFontFamily:[]}, {labelFontFamily:chr(10)}]) {
    rejected = false;
    try { parser.exportSvg(shortDeal, badOptions); } catch (bridge.svg e) { rejected = true; }
    check(rejected, "Reject invalid font family");
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
