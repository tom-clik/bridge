<cfscript>
// Run on the local CFML server after installing the converter's dependencies.
setting requesttimeout=180;
markdown = new markdown.testing.flexmarkTestObj();
plugin = new bridge.coldlight_plugin(markdownObj=markdown, coldsoupObj=markdown.coldsoupObj);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
folder = getTempDirectory() & "coldlight-image-test-" & createUUID() & "/";
directoryCreate(folder);
try {
    fileWrite(folder & "layout.css", 'table {border-collapse:collapse;width:120px;height:40px} td {padding:0} body {margin:0}', "utf-8");
    html = '<!doctype html><html><head><title>Batch test</title><link rel="stylesheet" href="layout.css"></head><body>'
        & '<table id="first" data-image="old.png"><tr><td>First ♠</td></tr></table>'
        & '<table id="second" data-image><tr><td>Second ♥</td></tr></table>'
        & '<table id="ignored"><tr><td>Not marked</td></tr></table></body></html>';
    node = markdown.coldsoupObj.Jsoup.parse(html);
    before = node.outerHtml();
    batch = plugin.tableImageBatch(node);
    check(batch.len() == 2, "Only marked tables are collected");
    check(batch[1].filename == "images/table-first.png", "Filename derives from the ID, not the old data-image value");
    baseUrl = createObject("java", "java.io.File").init(folder).toURI().toString();
    nodePath = server.os.name contains "Windows" ? "C:/Program Files/nodejs/node.exe" : "/usr/bin/node";
    options = {scale:2, width:600, height:400};
    if (fileExists("C:/Program Files/Google/Chrome/Application/chrome.exe"))
        options.executablePath = "C:/Program Files/Google/Chrome/Application/chrome.exe";
    result = plugin.saveImages(node, batch, folder, baseUrl, nodePath, options);
    check(result.len() == 2, "Both images are returned");
    for (item in result) {
        check(fileExists(item.path), "PNG exists: " & item.id);
        check(item.width == 240 && item.height == 80, "CSS resource and scale apply to " & item.id);
        image = createObject("java", "javax.imageio.ImageIO").read(createObject("java", "java.io.File").init(item.path));
        check(image.getWidth() == 240 && image.getHeight() == 80, "Valid PNG dimensions for " & item.id);
    }
    check(node.outerHtml() == before, "Original Jsoup document is unchanged");
    check(plugin.saveImages(node, [], folder, baseUrl, "not-installed").isEmpty(), "Empty batch starts no process");
    options.scale = 1;
    result = plugin.saveImages(html, [batch[1]], folder, baseUrl, nodePath, options);
    check(result[1].width == 120, "HTML strings are accepted and existing PNGs can be regenerated");
    try {
        plugin.saveImages(node, [{id:"missing",filename:"images/missing.png"}], folder, baseUrl, nodePath, options);
        check(false, "Missing ID must throw");
    } catch (coldlight.htmlToPng e) {
        check(find("exactly one", e.message) > 0, "Renderer errors reach Lucee");
    }
} finally {
    directoryDelete(folder, true);
}
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
