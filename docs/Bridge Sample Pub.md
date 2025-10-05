---
author: Tom Peer
title: Sample Bridge Publication
---

How to include Bridge hands in a Markdown Plus document { .description}

# Background

The ColdLight Bridge plugin allows for Bridge hands to be included in markdown publications. There are two simplified formats for a simple suit combination and a single hand, and a full tag that takes PBN data and can be used for creating more complex diagrams including auctions.

## A simple hand

<bridge>
akq78.5634.kq7.7
</bridge>

A simple hand holding can also be shown using the following syntax. 10s are represented with a `T`. They can be output as `10` if required.

    <bridge>
       akqT8.5643.kj7.7
    </bridge>

Three dots are required. A void in spades or clubs will then mean the hand starts or ends with a dot. E.g. `.akq784.kq76543.`

Note that the default is to show the hand inline. The simplest way to change this is to add a vertical attribute to show it in a column.

<bridge vertical>
akq78.5634.kq7.7
</bridge>

    <bridge vertical>
       akq78.5634.kq7.7
    </bridge>


## A simple suit combination

<bridge>
546 kq7 - 3A
</bridge>

A simple suit layout like the one above is entered with the following syntax:

    <bridge>
    654 kq7 - A3
    </bridge>

The system will recognise it as a suit combination from the spaces.

Either 2 (NS) or 4 player's holdings must be represented -- use a single dash (-) for a void. The entries are free text -- unknown holdings can be a query (?), an x, or anything you like.

### Simple suit example

A simple suit combination like the following needs just two entries for the opposite hands.

<bridge>
AKQ65 42
</bridge>

    <bridge>
    AKQ65 42
    </bridge>


## The full tag

All other layouts are done using PBN notation and some formatting options. You only need to enter the data you need although if you have an existing PBN file, you can reference that and only use the information you want to show. There is no need to remove the additional information. This is taken care of by the system.

If you store the files externally you can reuse them, often showing perhaps two hands and then later the full deal. You can also build a library of hands to reference in different publications.

## Sample Bridge Deal

PBN data consists of the main data fields and then the auction. Note that we don't use the "play" section but you can include it if you like.

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

### The deal tag

The Deal tag consists of 4 hands with suits divided by dots. The first letter (followed by a colon) indicates the first player in NESW order. Always use N if you are writing the data yourself.

### The auction tag

The auction tag sets the dealer and is then followed by the auction. Notes can be included using the number of the note surrounded by = characters.

### Data tags

The ColdLight Bridge plug in can use data from the following tags

* Scoring
* Vulnerable
* Contract
* Result

## Styling the output

You can choose to show 1 to 4 hands, the auction, and the various information tags from the PBN file.

These can be controlled by individual settings or the style shortcut which is more common, for example

```<bridge style='2_4'>```

### The style attribute

Most of the common formats are handled by the style attribute. In conjunction with the info attribute this will cover almost all hands.

The style names follow the following format:
 
`D_A` where D is the number of hands to show in the deal and A is the number of hands to whown in the auction

The number in either case can only be 0, 2, or 4 with 2 always being N and S. 

|Style name  |Description                                 
|------------|--------------------------------------------
|2_0         |Show just north and south hands             
|2_4         |Show north and south hands and full bidding
|0_4         |Show just auction

### The info attribute

The info attribute is a shortcut to turn on "scoring", "vulnerable", and "dealer".

```<bridge style='2_4' info='1'>```

### The full attributes

You can use the full settings for more precise control. This allows for showing e.g. the E and N hands.

|Attribute |Values                     |Default|Description
|----------|---------------------------|-------|-------------------------
|deal      |0,2,4 or any combo of NSEW |4      |Hands to show in deal
|auction   |0,2, or 4                  |4      |Hands to show in auction
|scoring   |0 or 1                     |1      |Show scoring
|vulnerable|0 or 1                     |1      |Show vulnerability
|dealer    |0 or 1                     |1      |Show dealer
|contract  |0 or 1                     |0      |Show Contract
|result    |0 or 1                     |0      |Show Result

Where the options are 0 or 1 you can also use no and yes for easier reading.

## Including an external file

To link to an external PBN file, use the `file` attribute and a _relative_ path. 

E.g. for a hand in a subfolder, use

```<bridge file="hand78_1.pbn"></bridge>```

For a hand in a "library" folder, use something like

```<bridge file="../library/bermudabowl2018/hand78_1.pbn" style="2_4" info="1"></bridge>```
