---
author: Tom Peer
title: Sample Bridge Publication
---

How to include Bridge hands in a Markdown Plus document { .description}

# Background

Markdown is a simple text format that allows for HTML document creation without the tags. It provides a simple syntax for headings, paragraphs, lists, and other basic formatting.

With the addition of some simple tags (the "plus") we can use Markdown for publishing books, magazines and a range of other publications to Kindle, HTML, PDF, and other electronic formats.

One of the additions is a tag specifically for Bridge hands. There are two simplified formats for a simple suit combination and a single hand, and a full tag that takes PBN data and can be used for everything else.

## A simple suit combination

<bridge>
546 kq7 - 3A
</bridge>

A simple suit layout like the one above is entered with the following syntax:

    <bridge>
    546 kq7 - 3A
    </bridge>

The player is assumed to be South if omitted.

Either 2 (NS) or 4 player's holdings must be represented -- use a single - for a void. The entries are free text -- unknown holdings can be a query ?, an x, or anything you like.

To show anything more complicated, you need to use the full tag with the relevant options.

### Simple suit example

A simple suit combination like the following needs just two entries for the opposite hands.

<bridge type="suit">
AKQ65 42
</bridge>

    <bridge>
    AKQ65 42
    </bridge>

## A simple hand

<bridge>
akq78.5634.kq7.7
</bridge>

A simple hand holding can also be shown using a simplified version of the tag:

    <bridge>
       akq78.5634.kq7.7
    </bridge>

The dots distinguish the format from a suit. Note that the default is to show it inline. A vertical attribute needs to be added to show it in a column.

<bridge vertical>
akq78.5634.kq7.7
</bridge>

    <bridge vertical>
       akq78.5634.kq7.7
    </bridge>

## The full tag

All other layouts are done using the full tag. This varies from a simple two suit diagram for e.g. South and East to a full layout with auction and information.

To use this format, you first have to format the data in PBN format.

Only the tags you intend to use in the output need including -- one of auction or deal being required.

You can either store the data in an external file or include it inline. If you are using existing PBN files, there is no need to remove information you don't want to show! This is taken care of by the system.

If you store the files externally you can reuse them, often showing perhaps two hands and then later the full deal. 

## Styling the output

You can choose to show 1 to 4 hands, the auction, and the various information tags from the PBN file.

These can be controlled by individual settings or the style shortcut which is more common.

### The style attribute

Most of the common formats are handled by the style attribute. In conjunction with the info attribute this will cover almost all hands.

The style names follow the following format:
 
`Number of hands to show in deal`_underscore_`number of hands in auction`

The number in either case can only be 0, 2, or 4 with 2 always being N and S. 

|Style name  |Description                                 
|------------|--------------------------------------------
|2_0         |Show just north and south hands             
|2_4         |Show north and south hands and full bidding
|0_4         |Show just auction

### The info attribute

The info attribute is a shortcut to turn on "scoring", "vulnerable", and "dealer".

The default for these is altered to "false" if a style is used, this is a handy shortcut to turn them back on.

### The full attributes

You can use the full settings for more preise control. The usual reason is to show a defensive position with e.g. EN hands.

|Attribute |Values                     |Default|Description
|----------|---------------------------|-------|-------------------------
|Deal      |0,2,4 or any combo of NSEW |4      |Hands to show in deal
|Auction   |0,2, or 4                  |4      |Hands to show in auction
|Scoring   |Bool                       |Yes    |Show scoring
|Vulnerable|Bool                       |Yes    |Show vulnerability
|Dealer    |Bool                       |Yes    |Show dealer
|Contract  |Bool                       |No     |Show Contract
|Result    |Bool                       |No     |Show Result

## Sample Bridge Hand

<bridge deal="EN">
[Deal "N:.63.AKQ987.A9732 A8654.KQ5.T.QJT6 J973.J98742.3.K4 KQT2.AT.J6542.85"]
[Scoring "IMP"]
[Declarer "S"]
[Contract "5HX"]
[Result "9"]
[Auction "N"]
1D      1S   3H =1= 4S
4NT =2= X    Pass   Pass
5C      X    5H     X
Pass    Pass Pass
</bridge>

    <bridge deal="EN">
    [Deal "N:.63.AKQ987.A9732 A8654.KQ5.T.QJT6 J973.J98742.3.K4 KQT2.AT.J6542.85"]
    [Scoring "IMP"]
    [Declarer "S"]
    [Contract "5HX"]
    [Result "9"]
    [Auction "N"]
    1D      1S   3H =1= 4S
    4NT =2= X    Pass   Pass
    5C      X    5H     X
    Pass    Pass Pass
    </bridge>