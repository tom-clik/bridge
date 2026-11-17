---
Author:		Unknown
Editor:		Tom Peer
style:		clikwriter/_styles/reset.css,clikwriter/_styles/standard.css,bridge.clik.com/assets/css/bridge_styles.css
pdf: 0
title: Revised Jacoby 2NT Responses
description: Improved responses to the Jacoby 2NT bid
plugins: bridge.html_plugin
---

The new responses exploit limit bidding to improve our slam auctions by making it easier to tell when to cuebid and when to sign off in game and our game auctions by allowing us to jump to game uninformatively when we are not in the slam zone.

<bridge style="0_4">
[auction]
1♥ P 2NT P
?
</bridge>

| Bid | Meaning                                                                            |
| --- | ---------------------------------------------------------------------------------- |
| 3♣  | Any minimum (approximately 11-13 unbalanced or  11-14 balanced)                    |
| 3♦  | Extras (14+ HCP) with a singleton somewhere                                        |
| 3♥  | Extras (14+ HCP) with a void somewhere                                             |
| 3♠  | Moderate extras (15-16) and no singleton  (5-4-2-2, 6-3-2-2, 5-3-3-2, 7-2-2-2)     |
| 3NT | Significant extras (17-19 including adjustments for distribution) and no singleton |
| 4X  | A 5-card second suit with 2 of top 3 honors                                        |
{.two .styled}

The most important call is the 3♣ bid. This low level call is opener's first move on all minimum hands. Any other call by opener promises at least moderate extras. Opener will simplify many auctions by immediately identifying the minimum hands. 

## Auction 1--Opener has a minimum

When opener shows a minimum, there are two possibilities:

### 1.	Responder has a minimum too

Slam is unlikely so responder can immediately place the contract in game.

<bridge>
AQxx.KJx.Qx.xxxx
</bridge>

<bridge style="0_4">
[auction]
1♠	P	2NT	P
3♣	P	4♠	AP
</bridge>

Holding a 12-count himself, South can tell immediately that slam is unlikely whatever opener holds so he jumps to 4M. This has two important benefits:

1. A slam misunderstanding is instantly avoided.
2. Opponents must defend 4♠ when both partners are minimum, without information about opener's side suit distribution.

### 2.	Responder has extras

Slam is still possible so more exploration is needed. Responder now has a second decision to make, should he describe his own hand or should he ask opener to describe his? In general, when responder has a singleton, he should describe. When responder is balanced, he should ask.

<bridge type="hand">
AQxx.xx.AQxx.KQx
</bridge>

<bridge style="0_4">
[auction]
1♠	P	2NT	P
3♣	P	3♦	P
?
</bridge>

Responder is balanced with extras, so he asks for opener's side suit shape. The responses are {.keep}

| Bid | Meaning                              |
| --- | ------------------------------------ |
| 1♥  | 2NT                                  |
| 3♣  | 3♦                                   |
| 3♥  | no shortness                         |
| 3♠  | lowest singleton (clubs)             |
| 3NT | middle singleton (diamonds)          |
| 4♣  | highest singleton (hearts or spades) |
{.two .styled}


This is almost the same scheme we used over the mini-splinter. The only difference is the first step response (3♥) which shows no shortness. The acronym to remember is NLMH which stands for none-lowest-middle-highest, since the first step response shows no singleton, the second step shows the lowest singleton, etc.

<bridge type="hand">
AQxx.KJxx.AQxx.x
</bridge>

<bridge style="0_4">
[auction]
1♠	P	2NT	P
3♣	P	4♣	P
?
</bridge>

Responder has a singleton club and is too strong for a direct splinter (15-17 HCP). Rather than ask about opener's he hand, he should describe his own shape. Opener should be the captain of this auction.

## Auction 2 and 3--Opener has extras and shortness

### a)	1M -- 2NT

3♦ (singleton somewhere)  --  3♥ (where?) {.keep}

| Bid | Meaning                              |
| --- | ------------------------------------ |
| 3♠  | lowest singleton (clubs)             |
| 3NT | middle singleton (diamonds)          |
| 4♣  | highest singleton (hearts or spades) |
{.two .styled}


### b)	1M  --  2NT

3♥ (void somewhere)  --  3♠ (where?) {.keep}

| Bid | Meaning                         |
| --- | ------------------------------- |
| 3NT | lowest void (clubs)             |
| 4♣  | middle void (diamonds)          |
| 4♦  | highest void (hearts or spades) |
{.two .styled}


Note that the responses to the asking bid are the same as over a mini-splinter:

| Step     | Meaning                |
| -------- | ---------------------- |
| 1st step | lowest shortness       |
| 2nd step | middle shortness, etc. |
{.two .styled}


## Auction 4 and 5--Opener has extras and is balanced

### a) 1M  --  2NT

3♠ (no shortness 14-16)  --  ?

### b) 1M  --  2NT

3NT  (no shortness 17-19)  --  ?

Opener is narrowly limited. The J2N bidder is captain and may cue bid, bid RKC, or signoff in game.

## Interference

As stated above, this convention is never on if they interfere after our 1MAJ opening. However, we do need to cope if they interfere after the 2NT response:

| Bid                 | Meaning                                                                             |
| ------------------- | ----------------------------------------------------------------------------------- |
| Opener’s double     | Shortness in suit doubled                                                           |
| Opener’s new suits  | natural or a control                                                                |
| 3NT                 | Balanced Maximum (Ace or King in their suit)                                        |
| Opener’s Pass       | Nothing special--flat hand, could be 5x3x2 awful after which, responder's X=penalty |
| Opener’s jump to 4M | dead minimum, but 6x3x2                                                             |
{.two .styled}

If they double Asks or re-asks : XX = business, Pass=S1, etc.
If they bid after Ask or re-ask : X=Penalty, Pass=S1, etc. (except when double = short as above)

## Summary

In summary then, our new responses: {.keep}

* Allow opener to limit his hand
* Allow opener to describe his shape
* When responder holds a singleton, allow responder to describe his shape and limit his hand
* Allow responder to bid game without revealing opener's shape when both hands are minimum