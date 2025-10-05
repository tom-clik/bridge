# 1.  Introduction

In the past years a lot of bridge computer programs have been developed.

There are programs for dealing, bidding, playing, and/or teaching.  A widely accepted standard format for bridge games does not exist.

Therefore, the output of one program can't be used in another program.  This not only holds for programs running on different computer platforms, but even for programs on one and the same computer.

This document specifies a universal notation for bridge games, called "Portable Bridge Notation" (PBN).  PBN is based on "Portable Game Notation"(PGN), a standard for the representation of chess games.

The current PBN 2.0 standard has been released on 1999.09.01 and it will be frozen until 2000.09.01 . At that time an evaluation will be made for a possible update.

The PBN 1.0 standard has been released on 1998.04.01 and it has been frozen until 1999.04.01 . The PBN 2.0 standard is an update to PBN 1.0 .

This does not mean that the PBN 1.0 standard is invalid. PBN files obeying the PBN 1.0 standard are fully compliant to the PBN 2.0 standard.

## 1.1  Design criteria

PBN has been designed with several criteria in mind.  Portability is of course the main criterion.  Other criteria are:

1.	PBN is an open standard. It is publicly available for users and software developers. PBN is not subject to any copyrights.

2.	The PBN notation must be straightforward and comprehensible. A human must be able to read and write the PBN notation easily.

3.	PBN must be suitable for a variety of computer programs.  It can be used by dealing programs, bidding programs, playing programs, etc.

	The PBN files range from single deals to large databases.  Examples of database contents are:

	1.	tournament database
	2.	famous player database
	3.	database with 7NT deals

    {.lower-alpha}

4.	PBN must be able to serve as an interface between competing computer programs.

5.	The PBN standard must be expandable.

6.	The PBN notation must be worldwide applicable.

7.	The syntax of the PBN notation must be easy to parse by a computer program.

	The PBN standard is based on textual files, instead of binary files.

	A lot of PBN data, including comment, are text strings. Therefore, low priority is given to minimization of file sizes.

## 1.2  Example game

An example game is described below. The tags are specified in detail in chapter 3.

    [Event "International Amsterdam Airport Schiphol Bridgetournament"]
    [Site "Amsterdam, The Netherlands NLD"]
    [Date "1995.06.10"]
    [Board "1"]
    [West "Podgor"]
    [North "Westra"]
    [East "Kalish"]
    [South "Leufkens"]
    [Dealer "N"]
    [Vulnerable "None"]
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
    [Note "1:non-forcing 6-9 points, 6-card"]
    [Note "2:two colors: clubs and diamonds"]
    [Play "W"]
    SK =1= H3 S4 S3
    C5 C2 C6 CK
    S2 H6 S5 S7
    C8 CA CT C4
    D2 DA DT D3
    D4 DK H5 H7
    -  -  -  H2
    *
    [Note "1:highest of series"]

## 1.3  Relationship to PGN

PBN is derived from "Portable Game Notation" (PGN).  Although the name PGN suggest that it is a standard for arbitrary games, it is dedicated for representing chess games.  PGN has been very successful.  There are already many chess programs that understand PGN, and PGN databases with thousands of games are publicly available.

The specification of PGN can be downloaded from http://www.iae.nl/users/veugent/pgn.zip.

One standard, namely the "Portable Draughts Notation" (PDN), has already been derived from PGN.  Board games like chess and draughts have much similarity, so the derivation of PDN from PGN was straightforward.

The derivation of PBN from PGN is less straightforward for the following reasons:

+ the number of players is 4 instead of 2
+ the "initial position", i.e.  the cards, must be given
+ the auction must be described, and possibly some calls must be
explained
+ the "moves", i.e. the calls and the played cards, must be described as two separate sections. The moving player must be indicated.