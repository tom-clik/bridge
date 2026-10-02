<cfscript>
parser = new bridge.bridge_parser();
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
function rejects(required string input, string message="Malformed input is rejected") {
    var rejected = false;
    try { variables.parser.parseHandviewer(arguments.input, false); }
    catch (bridge e) { rejected = true; }
    check(rejected, message);
}
sample = fileRead(expandPath('../../handviewer_samples/test1.txt'));
hand = parser.parseHandviewer(sample, false);
check(hand.dealer == 'W' && hand.board == '4' && hand.vulnerable == 'Both', 'Sample metadata');
check(hand.contract == '2C' && hand.declarer == 'W', 'Sample contract and declarer');
check(hand.auction.len() == 8 && hand.notes.len() == 3, 'Sample auction and explanations');
check(find('3+', hand.notes[1].note) > 0, 'Literal plus in URL explanations is preserved');
check(hand.play_ordered.len() == 52 && hand.play_ordered[1] == 'C8' && hand.play_ordered[52] == 'DT', 'All played cards retain source order');
pbn = parser.exportPBN(hand);
check(find('[play_ordered]', pbn) > 0 && find('[Play ', pbn) == 0, 'Only the unofficial play section is written');
roundtrip = parser.parsePBN(pbn);
check(serializeJSON(roundtrip.play_ordered) == serializeJSON(hand.play_ordered), 'Play order roundtrips');
check(roundtrip.notes[1].note == hand.notes[1].note, 'Explanations roundtrip');
check(roundtrip.deal.n.s == hand.deal.n.s && roundtrip.deal.s.h == hand.deal.s.h, 'Deal roundtrips');
check(roundtrip.auction[1].note == '1', 'Auction note markers roundtrip');
lin = 'st||pn|South,,North,East|zz|mb|md|1SAKQJT98765432HDC,SH AKQJT98765432 DC,SHD AKQJT98765432 C|sv|o|mb|1S|mb|P|mb|2S|an|Support|mb|P|mb|4S|mb|X|mb|P|mb|P|mb|P|pc|C2|pg||pc|C3|';
hand = parser.parseLIN(lin);
check(hand.west == '' && hand.north == 'North', 'Empty player names do not shift positions');
check(hand.auction.len() == 9, 'Unknown commands and command-like values are ignored in pairs');
check(hand.deal.e.c == 'AKQJT98765432' && hand.deal.e.s == '-', 'Missing fourth hand is inferred, including voids');
check(hand.contract == '4SX' && hand.declarer == 'S', 'Doubled contract uses first partnership bidder');
check(arrayToList(hand.play_ordered) == 'C2,C3', 'Page commands do not corrupt play');
check(parser.parseHandviewer('lin=' & urlEncodedFormat(lin), false).contract == '4SX', 'Encoded LIN query');
check(parser.parseHandviewer('https://example.invalid/?lin=' & urlEncodedFormat(lin) & '&other=ignored', false).north == 'North', 'LIN query is isolated from other parameters');
hand = parser.parseHandviewer('https://example.invalid/handviewer.html?d=n&v=e&n=SAH2D3C4&a=1N(15%2B%20%22balanced%22)ppp&p=SAH2D3C4&nn=A%26B', false);
check(hand.contract == '1NT' && hand.declarer == 'N' && hand.vulnerable == 'EW', 'Direct Handviewer query normalization');
check(hand.north == 'A&B' && hand.notes[1].note == '15+ "balanced"', 'Query values decoded separately');
roundtrip = parser.parsePBN(parser.exportPBN(hand));
check(roundtrip.notes[1].note == '15+ "balanced"', 'Quoted PBN note roundtrips');
check(hand.deal.e.s == '-' && hand.deal.n.s == 'A', 'Incomplete deals are not filled randomly');
hand = parser.parseHandviewer('d=n&a=1h1s2h2s4hppp', false);
check(hand.declarer == 'N' && hand.contract == '4H', 'Declarer is first bidder of denomination in winning partnership');
hand = parser.parseHandviewer('d=n&a=1h1s2s4sppp', false);
check(hand.declarer == 'E' && hand.contract == '4S', 'Opponent bidding same denomination does not change declarer');
for (auction in ['pppp', 'ap']) {
    hand = parser.parseHandviewer('d=s&a=' & auction, false);
    check(hand.contract == 'Pass' && !hand.keyExists('declarer'), 'Passed-out deal has no declarer');
}
hand = parser.parseHandviewer('d=e&a=1sxrppp', false);
check(hand.contract == '1SXX' && hand.declarer == 'E', 'Redoubled contract');
hand = parser.parseHandviewer('d=w&a=1s', false);
check(!hand.keyExists('contract') && !hand.keyExists('declarer'), 'Incomplete auction has no final contract');
hand = parser.parseLIN('md|3SAHDC,,,|mb|1C!|an|Strong|mb|P|mb|P|mb|P|');
check(hand.notes.len() == 1 && hand.notes[1].note == 'Strong', 'Explanation replaces generic alert');
hand = parser.parsePBN('[Auction "N"] 1C =1= P P P [Note "1:Auction"] [Play "E"] SA S2 S3 S4 =1= [Note "1:Play"]');
roundtrip = parser.parsePBN(parser.exportPBN(hand));
check(arrayToList(roundtrip.play_ordered) == 'SA,S2,S3,S4,=1=', 'PBN play tokens copied without interpreting columns');
check(roundtrip.notes[1].note == 'Auction' && roundtrip.play_notes[1].note == 'Play', 'Play and auction notes remain separate');
hand = parser.parsePBN('[play_ordered] SA H2 [Note "1:Raw"]');
check(arrayToList(hand.play_ordered) == 'SA,H2', 'Bare unofficial header is recognized');
hand = parser.parseLIN('md|1SAHDC,,,|mb|1C|an|Path C:\tmp and "quoted" text|mb|AP|');
roundtrip = parser.parsePBN(parser.exportPBN(hand));
check(roundtrip.notes[1].note == hand.notes[1].note, 'Backslash and quote escaping roundtrip');
rejects('md|1SAHDC,SAHDC,,|', 'Duplicate cards rejected');
rejects('md|1SAHDC,,,|md|2SKHDC,,,|', 'Multiple boards rejected');
rejects('d=n&a=1zppp');
rejects('d=n&a=1spppp', 'Calls after auction completion rejected');
rejects('d=n&a=1sppp&p=S', 'Odd play token rejected');
rejects('md|9SAHDC,,,|', 'Invalid dealer rejected');
rejects('https://example.invalid/unresolved', 'Disabled URL resolution does not fetch');
rejects('an|Orphan|', 'Orphan explanation rejected');
rejects('mb|1S|pc|', 'Unpaired LIN command rejected');
rejects('d=n&a=xppp', 'Double without a bid rejected');
hand = parser.parseLIN('md|1SHDAKQC,,,|mb|AP|');
roundtrip = parser.parsePBN(parser.exportPBN(hand));
check(roundtrip.deal.s.s == '-' && roundtrip.deal.s.h == '-' && roundtrip.deal.s.d == 'AKQ', 'Consecutive void suits roundtrip');
check(find(' - - -', parser.exportPBN(hand)) > 0 || find('N:- - ', parser.exportPBN(hand)) > 0, 'Unknown hands export as missing holdings');
network = new bridge.testing.handviewerURLTestObj();
baseURL = 'https://tinyurl.com/';
linResponse = {statusCode:'200 OK', fileContent:'md|1SAHDC,,,|mb|1S|mb|P|mb|P|mb|P|pc|SA|pc|H2|'};
network.responses[baseURL & 'lin'] = linResponse;
network.responses[baseURL & 'redirect'] = {statusCode:'302 Found', responseHeader:{Location:'lin'}};
network.responses[baseURL & 'viewer'] = {statusCode:'302 Found', responseHeader:{Location:'https://www.bridgebase.com/tools/handviewer.html?d=w&a=1sppp&p=SAH2'}};
network.responses[baseURL & 'loop'] = {statusCode:'302 Found', responseHeader:{Location:'loop'}};
network.responses[baseURL & 'html'] = {statusCode:'200 OK', fileContent:'<html>Not LIN</html>'};
for (mode in ['lin', 'redirect', 'viewer']) {
    hand = network.parseHandviewer(baseURL & mode);
    check(hand.contract == '1S' && arrayToList(hand.play_ordered) == 'SA,H2', 'HTTP source: ' & mode);
}
for (mode in ['loop', 'html']) {
    rejected = false;
    try { network.parseHandviewer(baseURL & mode); }
    catch (bridge e) { rejected = true; }
    check(rejected, 'HTTP source rejected: ' & mode);
}
// Neither initial input nor redirects may cause a request to a non-allowlisted destination.
for (target in ['http://localhost/', 'http://127.0.0.1/', 'http://10.0.0.1/', 'http://172.16.0.1/',
    'http://192.168.1.1/', 'http://169.254.169.254/latest/meta-data/', 'http://[::1]/',
    'http://2130706433/', 'https://bridgebase.com.attacker.invalid/', 'https://attackerbridgebase.com/',
    'https://bridgebase.com@127.0.0.1/', 'https://user@bridgebase.com/', 'https://bridgebase.com:8080/',
    'https://bridgebase.com:80/', 'http://tinyurl.com:443/', 'https://bridgebase.com./',
    'http://%31%32%37.0.0.1/', 'file:///etc/passwd']) {
    before = network.requests.len();
    rejected = false;
    try { network.parseHandviewer(target); } catch (bridge e) { rejected = true; }
    check(rejected && network.requests.len() == before, 'Blocked initial destination without request: ' & target);
    network.responses[baseURL & 'blocked'] = {statusCode:'302 Found', responseHeader:{Location:target}};
    rejected = false;
    try { network.parseHandviewer(baseURL & 'blocked'); } catch (bridge e) { rejected = true; }
    check(rejected && network.requests.len() == before + 1, 'Blocked redirect before second request: ' & target);
}
network.responses[baseURL & 'blocked'] = {statusCode:'302 Found', responseHeader:{Location:'//127.0.0.1/private'}};
before = network.requests.len();
rejected = false;
try { network.parseHandviewer(baseURL & 'blocked'); } catch (bridge e) { rejected = true; }
check(rejected && network.requests.len() == before + 1, 'Scheme-relative private redirect blocked');
for (target in ['https://bridgebase.com/lin', 'http://www.bridgebase.com:80/lin', 'https://www.tinyurl.com:443/lin']) {
    network.responses[target] = linResponse;
    check(network.parseHandviewer(target).contract == '1S', 'Allowed destination: ' & target);
}
cfcontent(type='application/json; charset=utf-8', reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(), checks:checks, failures:failures}));
</cfscript>
