# Bridge Hand Formats

Bridge hands for plain text mark up are included using the `<bridge>` tag. They vary in detail from a simple suit position to full hands with auction and details of the competition.

There are three short forms of the tag for a simple hand, suit combo, or auction.

1.  A simple hand
	
	```
	<bridge>
	AK952.QJ6.-.QT742
	</bridge>
	```

	Unknown values should be x's. Voids should be a single dash -. There must be **No spaces** in the individual suits, and dots dividing the suits. There must also be no suit indicators or other extraneous information. This is all added by the system.

	Technically you don't need the dashes for a void but it makes it much easier than getting confused by double dots.

2.	Suit showing one, two or four hands { #suit}

	```
	<bridge>
	AK542 Q97 63 JT8
	</bridge>
	```

	There must be **No spaces** in the individual hands, and space dividing the other hands.

	The first entry is assumed to be South. Two entries will be North and South. To show other combos, you have to use the full tag definition.

3.  Simple 2 player auction

	A simple opener/responder auction with no notes can be added with two columns of text.

	```
	<bridge>
	1C  1S
	2S  3D
	3S  4S
	</bridge>
	```

## Using PBN

Anything else -- including a deal digram with no other information -- is marked up using PBN inside the the bridge tag. A file attribute can be supplied to include an external file, better practice, e.g.

```
<bridge file="../hands/euro2020/hand64.pdn"></bridge>
```

The following tags from PBN are used. Note that "dealer" is set in the `Auction` tag.

```
[Vulnerable "None|All|NS|EW"]
[Deal "S:.63.AKQ987.A9732 A8654.KQ5.T.QJT6 J973.J98742.3.K4 KQT2.AT.J6542.85"]
[Scoring "IMP"]
[Declarer "S"]
[Contract "5HX"]
[Result "9"]
[Auction "N"]
1D 1S 3H =1= 4S
4NT =2= X Pass Pass
5C X 5H X
Pass Pass Pass
[Note "1:non-forcing 6-9 points, 6-card"]
[Note "2:two colors: clubs and diamonds"]
```

The PBN is quite tolerant, many files are just two hands.  

	[Deal "S:.63.AKQ987.A9732 - J973.J98742.3.K4 -"]

A single dash is used for a blank entry.

The auction needs to be filled out even if only two columns are going to be shown:

	[auction]
	1D  p 3H p 
	4NT p 5C p
	5D  p 5H p

Note that all formatting in this case is irrelevant and controlled by the output style.

## Output styles

Output styles are controlled by the following settings, applied as attributes of the tag, e.g.

```
<bridge hands="NS" auction="NS">...
```

Hands
: The hands to show. 0,2,4, or any combination of NSEW. Two or more positions will show a compass.
: A single hand will show the position above the hand. The `show_hand_name` setting (true|false) will turn this off

Auction
: The auction to show. Values can be 0,2,4, or EW. Default is 4. 2 shows NS.

Info
: Show vulnerability and dealer. Default is True

Other tags in PBN can be shown using a boolean value:

`Dealer="yes|no"`

The tags available are dealer, lead, scoring, vulnerability, contract, declarer, result, and par.

## Quick styles

These are the available built-in styles. Using these changes the default for `info` to false. Apply with the `style` attribute, e.g.

```
<bridge hands="NS" style="2_4">...
```

2_0 
: Shows just the north and south hands with no auction. Info will be shown above the right.

4_0 
: Shows all four hands with no auction. Info will be shown above.

2_2 
: Shows the north and south hands with only their bidding auction, shown to the right vertically aligned middle. Info will be shown above the auction.

2_4 
: Shows the north and south hands with all four columns of bidding, shown to the right vertically aligned middle. Info will be shown above the auction.

4_4 
: All four hands and all four columns of bidding. Same as default but with `info=false`

