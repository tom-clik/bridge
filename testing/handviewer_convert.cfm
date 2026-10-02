<!--- Interactive adapter; all import and export logic lives in bridge_parser. --->
<cfparam name="url.data" default="">
<cfscript>
if (len(trim(url.data))) {
    parser = new bridge.bridge_parser();
    hand = parser.parseHandviewer(url.data);
    writeOutput("<pre>" & encodeForHTML(parser.exportPBN(hand)) & "</pre>");
} else {
    writeOutput('Supply a Handviewer URL, LIN URL or raw LIN in the data query parameter.');
}
</cfscript>
