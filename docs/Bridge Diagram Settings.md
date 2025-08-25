---
author: Tom Peer
title: Bridge Diagram Settings
description: Tech notes on how the Bridge Hand diagrams are constructed
notes: Bit pre-historic (i.e. 2000s vintage). Have always wanted to rework this with SVG
---

## Introduction

Bridge hands can be included in ClikWriter documents using a single hand, suit layout (1-4 hands), simple auction (2/4 players), or by using a full PBN definition.

This document describes the settings for creating diagrams using the full definitions. 

## Diagram Sections

The HTML looks like this. NB the `style` controls what gets displayed rather than any actual styling.

```
div.bridge.bridgediagram[.bridgestyleX_Y]
    |
    |----div.info
    |
    |----div.deal
    |
    |----div.auction
    |
    |----div.play
``` 

### Outer Div

`div.bridge.bridgediagram`

The main div has two classes -- `.bridge` is the class that applies the standard settings for the font across all bridge items, and `.bridgediagram` is the class that you can use to set the layout of the whole diagram:

|Setting      |  Description    |Implementation
|-------------|-----------------|-----------------------------
|margin-top   |Top margin       |__
|margin-bottom|Bottom margin    |__
|align        |Left or center   |Applies auto margin if needed
|width        |auto or dim      |auto (default) calculates from other sizes
|padding      |inner padding    |apply full 4-dim CSS padding(see also paddings for the inner divs)

{.settings}

### Info Div

The info div is shown if any of the following fields are set to be displayed:

+ Event
+ Dealer
+ Vulnerable
+ Scoring

!!! note 
    Lead and contract might possibly go into the info with a position parameter. At the moment they go into the `div.play` section.

Each of these is a separate `p` tag of class lowercase variable name e.g. `p.event`. You can apply classes to all with `div.info p`.

### Deal div

The main deal div is where our technical problems start. Most of items within this are positioned absolutely. This causes a bit of a headache when it comes to the deal rose as you can't position relative inside an absolutely positioned item.

So: we position the rose using a left and top margin and the hands using absolute positions.

<!-- to do: turn off rose and have player labels above the hands -->

#### Deal Rose

The little box at the center is the deal rose. This is sized as a square, with offsets for the position letters and a margin. There is also a shadow setting which doesn't work but might one day.

|Setting         |  Description    |Implementation
|----------------|-----------------|-----------------------------
|size            |Side of square   |apply width and height
|margin          |Single margin    |add to other margins
|letter-offset   |Distance from side to letter|Apply as outside position
|letter-font     |font for letters |font
|Border          |                 |
|background-color|                 |

The top position is calculated from the hand height -- which is four line heights plus 4 deal item margins. This is added to any rose margin.

The left hand position is calculated from the hand width -- sum of the suit symbol width, suit symbol padding, and suit lengthX(char width+suit letter spacing). We assume a suit length of 7. If any suit is longer than that in the West hand, we have to increase the suit width at the start and recalculate.

For nice looking diagrams, you should restrict 8 card or longer suits to North or South. If you are reporting on real deals and can't do this, consider switching off the deal rose.

The size is calculated from the hand height so that it should be the same as the height of the left and right hands.

#### Hands

The hands have a few settings that should inherit from the general bridge settings:

|Setting       |  Description    |Implementation
|--------------|-----------------|-----------------------------
|symbol_padding|                 |Apply padding to inline-block span
|suit-spacing  |Spacing between symbols|See [](#spacing)
|suit-margin   |marg in between suits|bottommarginon inidividual suits

## Suit symbol spacing { #spacing}

Spacing out the cards in a suit is annoying because of the 10. We therefore can't use letter spacing which was working fine when we could insist on the use of 'T', but not with both.

Accordingly we have to place a space between each card and then use a _negative_ word spacing. All spacings should therefore be a % -- with 100% being the normal full space and 0 being no space. The default is 50%.

## Font settings

Fonts need to be applied as a single string CSS setting. The family can be omitted to inherit from `.bridge`.

    selector {
        font: font-style font-variant font-weight font-size/line-height font-family;
    }

### Card font

The card font can be different from the main bridge font. How?

