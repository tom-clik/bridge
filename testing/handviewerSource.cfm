<cfparam name="url.mode" default="lin">
<cfscript>
// Local HTTP fixtures: no external service or credentials required.
switch (url.mode) {
    case 'redirect':
        cfheader(statuscode=302, statustext='Found');
        cfheader(name='Location', value='handviewerSource.cfm?mode=lin');
        break;
    case 'viewer':
        cfheader(statuscode=302, statustext='Found');
        cfheader(name='Location', value='handviewerSource.cfm?d=w&a=1sppp&p=SAH2');
        break;
    case 'loop':
        cfheader(statuscode=302, statustext='Found');
        cfheader(name='Location', value='handviewerSource.cfm?mode=loop');
        break;
    case 'html': writeOutput('<html>Not LIN</html>'); break;
    default:
        cfcontent(type='text/plain', reset=true);
        writeOutput('md|1SAHDC,,,|mb|1S|mb|P|mb|P|mb|P|pc|SA|pc|H2|');
}
</cfscript>
