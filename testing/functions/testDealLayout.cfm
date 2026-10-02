<cfscript>
// Open on the local CFML server in a browser: these checks require CSS layout.
markdown = new markdown.testing.flexmarkTestObj();
plugin = new bridge.html_plugin(coldsoupObj=markdown.coldsoupObj);
pbn = '[Deal "N:AKQ.432.AJ98.765 JT9.AKQ.T76.AKQ 876.JT9.KQ5.JT98 5432.8765.432.32"]
[Auction "N"]
1C P 1H P';
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Deal layout regression checks</title>
    <link rel="stylesheet" href="../../assets/css/bridge_styles.css">
    <style>
        body { margin: 2em; }
        .fixture { padding: 1em 120px; border-bottom: 1px solid #ccc; }
    </style>
</head>
<body>
<h1>Deal layout regression checks</h1>
<pre id="results">Waiting for layout...</pre>
<cfscript>
for (fontSize in [16, 32]) {
    for (deal in ["N", "E", "S", "W", "NE", "NS", "NW", "ES", "EW", "SW", "NES", "NEW", "NSW", "ESW", "NESW"]) {
        for (rose in ["default", "yes", "no"]) {
            roseAttribute = rose == "default" ? "" : ' rose="' & rose & '"';
            label = deal & ", rose=" & rose & ", font=" & fontSize;
            writeOutput('<section class="fixture" style="font-size:' & fontSize & 'px" data-case="' & label & '">');
            writeOutput('<h2>' & label & '</h2>');
            writeOutput(plugin.process(doc={html:'<bridge deal="' & deal & '" info="no"' & roseAttribute & '>' & pbn & '</bridge>'}));
            writeOutput('<p class="following">Following paragraph must clear every visible hand.</p></section>');
        }
    }
}
</cfscript>
<script>
window.addEventListener('load', async () => {
    await document.fonts.ready;
    const failures = [];
    let checks = 0;
    function check(condition, message) {
        checks++;
        if (!condition) failures.push(message);
    }
    for (const fixture of document.querySelectorAll('.fixture')) {
        const label = fixture.dataset.case;
        const deal = fixture.querySelector('.bridgedeal').getBoundingClientRect();
        const row = fixture.querySelector('.deal-middle').getBoundingClientRect();
        const auction = fixture.querySelector('.bridgeauction').getBoundingClientRect();
        const paragraph = fixture.querySelector('.following').getBoundingClientRect();
        const visible = [...fixture.querySelectorAll('.dealhand')].filter(hand => getComputedStyle(hand).display !== 'none');
        for (const hand of visible) {
            const bounds = hand.getBoundingClientRect();
            check(bounds.height > 0 && bounds.top >= deal.top - 1 && bounds.bottom <= deal.bottom + 1, label + ': deal contains ' + hand.className);
            check(auction.top >= bounds.bottom - 1 && paragraph.top >= bounds.bottom - 1, label + ': following content clears ' + hand.className);
            if (hand.matches('.e, .w')) {
                check(row.height >= bounds.height - 1, label + ': middle row contains side hand');
                const south = fixture.querySelector('.dealhand.s:not(.hide)');
                if (south) check(south.getBoundingClientRect().top >= bounds.bottom - 1, label + ': south clears side hand');
            }
        }
    }
    document.querySelector('#results').textContent = JSON.stringify({passed: failures.length === 0, checks, failures}, null, 2);
});
</script>
</body>
</html>
