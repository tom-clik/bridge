<!--- UI only: importing, PBN export and rendering belong to bridge_parser. --->
<cfparam name="url.data" default="">
<cfparam name="form.action" default="">
<cfparam name="form.source" default="#url.data#">
<cfparam name="form.pbn" default="">
<cfparam name="form.filename" default="hand.pbn">
<cfparam name="form.folder" default="">
<cfscript>
configPath = expandPath('handviewer_folders.json');
if (!fileExists(configPath)) {
    throw(type='bridge.configuration', message='Missing Handviewer folder configuration: ' & configPath,
        detail='Copy handviewer_folders.sample.json to handviewer_folders.json beside handviewer_convert.cfm, then set each folder path to an existing local directory. The actual configuration is excluded from Git.');
}
try {
    folders = deserializeJSON(fileRead(configPath, 'utf-8'));
} catch (any e) {
    throw(type='bridge.configuration', message='Invalid JSON in ' & configPath, detail='Use the array of folder definitions shown in handviewer_folders.sample.json.');
}
if (!isArray(folders) || !arrayLen(folders)) throw(type='bridge.configuration', message='Handviewer folder configuration must be a non-empty JSON array.');
folderPaths = {};
for (folder in folders) {
    if (!isStruct(folder) || !folder.keyExists('id') || !folder.keyExists('label') || !folder.keyExists('path')
        || !isSimpleValue(folder.id) || !isSimpleValue(folder.label) || !isSimpleValue(folder.path)
        || !reFind('^[A-Za-z0-9_-]+$', folder.id) || !len(trim(folder.label)) || folderPaths.keyExists(folder.id)) {
        throw(type='bridge.configuration', message='Each Handviewer folder needs a unique id, a label and an absolute path. See handviewer_folders.sample.json.');
    }
    if (!createObject('java', 'java.io.File').init(folder.path).isAbsolute() || !directoryExists(folder.path)) {
        throw(type='bridge.configuration', message='Handviewer folder path must be an existing absolute directory: ' & folder.path);
    }
    folderPaths[folder.id] = getCanonicalPath(folder.path);
}
if (form.action == 'download' && len(trim(form.pbn))) {
    filename = reReplace(form.filename, '[^A-Za-z0-9._-]', '-', 'all');
    if (!len(filename)) filename = 'hand.pbn';
    if (right(filename, 4) != '.pbn') filename &= '.pbn';
    cfheader(name='Content-Disposition', value='attachment; filename="' & filename & '"');
    cfcontent(type='text/plain; charset=utf-8', variable=charsetDecode(form.pbn, 'utf-8'), reset=true);
    abort;
}
source = trim(form.source);
errorMessage = '';
saveMessage = '';
preview = '';
pbn = '';
filename = 'hand.pbn';
if (form.action == 'parse' || form.action == 'save' || len(source)) {
    if (!len(source) && form.action != 'save') {
        errorMessage = 'Paste a Handviewer or LIN link first.';
    } else {
        try {
            parser = new bridge.bridge_parser();
            if (form.action == 'save') {
                if (!len(trim(form.pbn))) throw(type='bridge', message='Parse a hand before saving.');
                pbn = form.pbn;
                hand = parser.parsePBN(pbn);
                if (!hand.keyExists('auction')) hand.auction = [];
                if (!hand.keyExists('notes')) hand.notes = [];
            } else {
                hand = parser.parseHandviewer(source);
                pbn = parser.exportPBN(hand);
            }
            if (hand.keyExists('board') && len(hand.board)) {
                filename = 'board-' & reReplace(hand.board, '[^A-Za-z0-9_-]', '-', 'all') & '.pbn';
            }
            soup = new coldsoup.coldsoup(server.system.environment.javalib & '/jsoup-1.22.1.jar');
            renderer = new bridge.bridge_parser(jsoupObj=soup);
            // Render escaped display values while retaining original text in the download.
            displayHand = duplicate(hand);
            for (key in displayHand) {
                if (isSimpleValue(displayHand[key])) displayHand[key] = encodeForHTML(displayHand[key]);
            }
            for (note in displayHand.notes) note.note = encodeForHTML(note.note);
            node = soup.parse('<bridge type="pbn" info="yes" contract="yes" positions="yes"></bridge>').select('bridge').first();
            if (!hand.keyExists('deal')) node.attr('deal', '0');
            if (!hand.auction.len()) node.attr('auction', '0');
            node.text(renderer.exportPBN(displayHand));
            preview = renderer.bridgeTag(node);
        } catch (any e) {
            pbn = '';
            errorMessage = 'Could not import this hand. ' & e.message;
        }
    }
}
if (form.action == 'save' && len(pbn)) {
    filename = trim(form.filename);
    try {
        if (!folderPaths.keyExists(form.folder)) throw(type='bridge', message='Choose a configured save folder.');
        if (!reFindNoCase('^[A-Za-z0-9][A-Za-z0-9 _.-]*\.pbn$', filename)
            || reFindNoCase('^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])\.', filename)) {
            throw(type='bridge', message='Enter a filename ending in .pbn, using letters, numbers, spaces, dots, hyphens or underscores. Do not include a folder path.');
        }
        destination = folderPaths[form.folder] & '/' & filename;
        lock name=('handviewer-save-' & hash(lCase(getCanonicalPath(destination)))) type='exclusive' timeout=10 {
            if (fileExists(destination)) throw(type='bridge', message='That file already exists. Choose another filename to keep the existing file.');
            fileWrite(destination, pbn, 'utf-8');
        }
        saveMessage = 'Saved to ' & getCanonicalPath(destination);
    } catch (any e) {
        errorMessage = 'Could not save the PBN. ' & e.message;
    }
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Import a bridge hand</title>
    <link rel="stylesheet" href="../assets/css/bridge_styles.css">
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; padding: 32px 16px; font: 16px/1.5 system-ui, sans-serif; color: #202b33; background: #f4f6f7; }
        main { max-width: 800px; margin: auto; }
        h1 { margin: 0 0 8px; font-size: 1.75rem; }
        h2 { font-size: 1.2rem; margin-top: 0; }
        .panel { background: white; border: 1px solid #dce2e5; border-radius: 8px; padding: 24px; margin: 20px 0; }
        label { display: block; font-weight: 600; margin-bottom: 8px; }
        textarea { width: 100%; padding: 12px; border: 1px solid #98a5ad; border-radius: 4px; font: 14px/1.5 ui-monospace, monospace; resize: vertical; }
        textarea:focus, button:focus-visible, summary:focus-visible { outline: 3px solid #82b9d9; outline-offset: 2px; }
        button { margin-top: 12px; padding: 10px 18px; border: 0; border-radius: 4px; background: #155c79; color: white; font: inherit; cursor: pointer; }
        button:hover { background: #10465c; }
        select, input[type="text"] { width: 100%; padding: 10px; margin-bottom: 12px; font: inherit; border: 1px solid #98a5ad; border-radius: 4px; }
        .success { padding: 12px 16px; background: #eaf5ed; overflow-wrap: anywhere; }
        .hint { color: #52616b; font-size: .9rem; }
        .error { border-left: 4px solid #ad2831; padding: 12px 16px; background: #fff0f0; }
        .preview { overflow-x: auto; padding-bottom: 12px; }
        .preview .bridgeinfo { position: static; width: auto; display: flex; flex-wrap: wrap; gap: 6px 16px; margin-bottom: 20px; }
        .preview .bridgeinfo p { margin: 0; }
        .preview .bridgefull { max-width: 100%; --card-font: ui-monospace; }
        .preview .bridgeauction { margin-top: 24px; }
        .preview .auctionnotes { overflow-wrap: anywhere; }
        summary { cursor: pointer; margin: 16px 0 8px; }
    </style>
</head>
<body>
<main>
    <h1>Import a bridge hand</h1>
    <p>Paste a Handviewer or LIN link to preview the hand and save a PBN file.</p>
    <cfoutput>
    <form method="post" action="handviewer_convert.cfm" class="panel">
        <label for="source">Handviewer / LIN URL</label>
        <textarea id="source" name="source" rows="5" required spellcheck="false" aria-describedby="source-help" placeholder="https://www.bridgebase.com/tools/handviewer.html?lin=...">#encodeForHTML(source)#</textarea>
        <p id="source-help" class="hint">You can also paste raw LIN text.</p>
        <button type="submit" name="action" value="parse">Parse hand</button>
    </form>
    <cfif len(errorMessage)>
        <p class="error" role="alert">#encodeForHTML(errorMessage)#</p>
    </cfif>
    <cfif len(saveMessage)><p class="success" role="status">#encodeForHTML(saveMessage)#</p></cfif>
    <cfif len(pbn)>
        <section class="panel" aria-labelledby="preview-heading">
            <h2 id="preview-heading">Hand preview</h2>
            <div class="preview">#preview#</div>
            <form method="post" action="handviewer_convert.cfm">
                <input type="hidden" name="source" value="#encodeForHTMLAttribute(source)#">
                <label for="folder">Save folder</label>
                <select id="folder" name="folder">
                    <cfloop array="#folders#" item="folder">
                        <option value="#encodeForHTMLAttribute(folder.id)#"<cfif form.folder == folder.id> selected</cfif>>#encodeForHTML(folder.label)#</option>
                    </cfloop>
                </select>
                <label for="filename">Filename</label>
                <input type="text" id="filename" name="filename" value="#encodeForHTMLAttribute(filename)#" required>
                <button type="submit" name="action" value="save">Save PBN file</button>
                <button type="submit" name="action" value="download">Download instead</button>
                <details>
                    <summary>View PBN</summary>
                    <label for="pbn">Exported PBN</label>
                    <textarea id="pbn" name="pbn" rows="14" readonly spellcheck="false">#encodeForHTML(pbn)#</textarea>
                </details>
            </form>
        </section>
    </cfif>
    </cfoutput>
</main>
</body>
</html>
