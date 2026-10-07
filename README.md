# CFML Bridge

Tom's Bridge Notes and Code Libraries



## Handviewer / LIN import and PBN export

All conversion lives in `bridge_parser.cfc`; the former `PBNParser.cfc` has been
removed. The pages in `testing` are adapters, not separate parsers.

```cfml
parser = new bridge.bridge_parser(); // jsoupObj is needed only for HTML rendering
hand = parser.parseHandviewer(handviewerURL);
pbn = parser.exportPBN(hand);

hand = parser.parseLIN(linText);
hand = parser.parsePBN(pbnText);
```

`parseHandviewer(input, resolveURLs=true)` accepts a Handviewer URL or query
(including `lin=...`), raw or URL-encoded LIN, or a URL returning LIN. Short links and relative
redirects are resolved with a bounded redirect count and HTTP timeout.
Network requests, including every redirect hop, are restricted to the exact
hosts `bridgebase.com`, `www.bridgebase.com`, `tinyurl.com` and `www.tinyurl.com`
on standard HTTP/HTTPS ports, without URL credentials. Other hosts can only
be used as pasted links containing hand parameters (no request is made). Set
`resolveURLs=false` for offline parsing or untrusted URLs. Query values are
URL-decoded once; raw LIN is already decoded text. Vulnerability `0` and `o`
both import as `None`.

The shared hand structure contains `deal[position][suit]`, `auction` entries
with `bid` and note markers, `notes` entries with `marker` and `note`, metadata
such as `dealer` and `vulnerable`, and a `play_ordered` array. LIN player/deal
order is South, West, North, East. One omitted hand is inferred only when the
other three account for 39 distinct cards; incomplete deals are never filled
randomly. Import one board at a time. Contract and declarer are derived only
from a completed auction; pass-outs have `contract="Pass"` and no declarer.

`exportPBN(hand)` emits metadata, the deal in North/East/South/West order,
auction calls and explanations. Played cards are copied in source order to
an **unofficial `[play_ordered]` section**, with no conversion into standard
PBN player columns. `parsePBN` recognizes this extension. For an existing
standard `[Play "..."]` section it copies the tokens as written; it does not
reconstruct chronological play from those columns. Play notes are kept
separately in `play_notes` and exported after the play section.

Run `testing/functions/testHandviewerImport.cfm` on the local CFML server for
import/export regressions, including mocked HTTP redirects and blocked destinations. The interactive
`testing/handviewer_convert.cfm` form accepts a pasted URL or raw LIN, renders
the hand and auction, and offers **Save PBN file** to a configured local folder
or **Download instead**. **View PBN** shows the exact text that will be saved.
Existing `?data=...` links also work.

Copy `testing/handviewer_folders.sample.json` to
`testing/handviewer_folders.json` and edit its JSON array of `{id, label, path}`
folder definitions. IDs must be unique; paths must be absolute, existing
directories writable by the CFML server. The actual configuration is ignored
by Git. The page throws an explanatory configuration error if the file is
missing, malformed or contains an invalid folder.

Choose a folder and filename beside **Save PBN file**. Saving writes UTF-8 PBN
directly on the machine running CFML; it refuses to overwrite an existing file.
