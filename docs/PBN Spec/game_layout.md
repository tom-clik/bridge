# 3. Game layout

A PBN file contains zero or more PBN games.  Each game, except for the first game, starts with a semi-empty line.  A semi-empty line is either an empty text line (no characters), or a line having only spaces and/or tab characters.  In export format, each game (except for the first) must start with an empty text line.

So, a parser (and a human) knows that after a semi-empty line a new game begins.  There is one exception to this situation, namely a comment (chapter 3.8) may include semi-empty lines that do not end the game.

Every game contains all its required data.  Several games in a database file may contain identical information.  This costs more bytes, but the syntax can be kept simple to cope with a large diversity of databases. A PBN file does not have a header with general file information.

## 3.1  Game sections

A PBN game consists of several sections:

1.	the identification section,
2.	the auction section,
3.	the play section, and
4.	supplemental sections.

The identification section provides information that identifies the game by defining the values associated with a set of standard parameters.

The auction section gives the optionally annotated bids.  It starts with tag name 'Auction' and ends at the next tag or the end of the game.  The auction section is optional.  The outcome of the auction can be given by the tags 'Declarer' and 'Contract'. If the auction section is present, then the tag 'Dealer' must be filled before the auction section.

The play section shows the played cards.  It starts with tag name 'Play'and ends at the next tag or the end of the game.  The play section is optional.  If the play section is present, then the tags 'Deal', 'Declarer'and 'Contract' must be filled before the play section.

The supplemental sections are optional sections containing tables or user defined sections.

In import format, no tags are mandatory.  The tags can be given in any order.  As indicated above, in case of an auction section or a play section the needed tags and their order are prescribed.

In export format, the sections must be given in the above order.  The supplemental sections are sorted alphabetically by their tag name.  The identification section contains 15 mandatory tags.

## 3.2  Tokens

PBN character data is organized as tokens.  A token represents a basic semantic unit.  A token consists of a contiguous sequence of printing characters belonging to the allowed character set.  Tokens may be separated from adjacent tokens by white space characters.  (White space characters include space, newline, and tab characters.) A white space character can never be part of a token.  As a consequence, a token does not cross a text line boundary, and its length is limited to a maximum of 255 characters.

Some tokens are self delimiting and do not require white space characters to separate them from the next token.

The left and right bracket characters ("[" and "]") are tokens.  They are used to delimit tag pairs (see below).  Both tokens are self terminating.

A name token consists of one or more name characters.  These name characters are letter characters ("A-Za-z"), digit characters ("0-9"), and the underscore ("`_`").  All characters in a name are significant.  A name token is terminated just prior to the first non-name character.

A string token is a sequence of zero or more printing characters delimited by a pair of quote characters (ASCII decimal value 34, hexadecimal value 0x22).  An empty string is represented by two adjacent quotes.  (Note:  an apostrophe is not a quote.) A quote inside a string is represented by the backslash immediately followed by a quote.  A backslash inside a string is represented by two adjacent backslashes.  Strings are commonly used as tag pair values (see below).  A string token is terminated by its closing quote.  Note that, non-printing characters like newline and tab are not permitted inside of strings, because a string is a special case of a token.

A call token is a sequence of one or more letter characters ("A-Za-z"), digit characters ("0-9"), and the hyphen character ("-").  A call token is terminated just prior to the first non-call character.  The call tokens are defined in chapter 3.5.1 .

A card token is a sequence of one or more letter characters ("A-Za-z"), digit characters ("0-9"), and the hyphen character ("-").  A card token is terminated just prior to the first non-card character.  The card tokens are defined in chapter 3.6.1 .

A suffix token consists of one or two exclamation marks "!" and/or question marks "?".  A suffix token is terminated after the second suffix character, or just prior to the first non-suffix character.

A note token is a sequence of one or more digit characters ("0-9") preceded as well as succeeded by the equal sign ("=").  This token terminates just after the succeeding equal sign.

A Numeric Annotation Glyph ("NAG", see below) is a token; it is composed of a dollar sign character ("$") immediately followed by one or more digit characters.  It is terminated just prior to the first non-digit character following the digit sequence.

An asterisk character ("`*`") is a token by itself.  It is used as a termination marker of an incomplete auction section or an incomplete play section.  The token is self terminating.

A plus character ("+") is a token by itself.  It is used to denote the next call in an auction that must be continued, or to denote the next card of a play that must be continued.  The token is self terminating.

An irregularity token starts with the caret character ("^") and is followed by one of the characters "I", "S", "R", or "L".  This token terminates just after the second character.

A section token is a sequence of one or more ASCII characters from 33 to 126 with the exclusion of '[' , ']' , '{' , '}' , ';' , '"' , '%'.  This limited set of characters is needed to prevent problems in parsing a supplemental section.  The excluded characters are used for indicating tag pairs, comments, string tokens, and the escape mechanism.  The backslash is allowed, but has no special meaning.

A column name token is a sequence of zero or more printing characters with the exception of ';' , because it serves as separator between 2 column name tokens.  The first character '+' or '-' has a special meaning:  it indicates the order in the column. Also character '\' in the column name token has a special meaning: it must be followed by an integer that represents the minimum width of the data in the column. Optionally, this integer can be followed by 'L' or 'R' to indicate left or right alignment of column data.

## 3.3  Tag pair

The tag pair (or shortly 'tag') is the basic information unit.  A tag pair is composed of four consecutive tokens:  a left bracket token, a name token, a string token, and a right bracket token.  The name token is the tag name and the string token is the tag value associated with the tag name.  (There is a standard set of tag names and semantics described below.)

Tag names are case sensitive.  All tag names begin with an upper case letter.

For PBN import format, there may be zero or more white space characters between any adjacent pair of tokens in a tag pair.

For PBN export format, there are no white space characters between the left bracket and the tag name, there are no white space characters between the tag value and the right bracket, and there is a single space character between the tag name and the tag value. PBN import format may have multiple tag pairs on the same line and may even have a tag pair spanning more than a single line.  Export format requires each tag pair to appear left justified on a line by itself.

Some tag values may be composed of a sequence of items.  For example, a game may have more than one annotator.  When this occurs, the single character ";" (semicolon) appears between adjacent items.

## 3.4  Identification section

The identification section contains all the tag pairs, that are not involved with the auction section and the play section.

There is a set of 15 tags defined for storage of PBN data, called Mandatory Tag Set (MTS).  These tags are mandatory for a PBN file in export format.  The MTS is the common ground that all programs should follow for public data interchange.  When a tag value of a mandatory tag is unknown (because it was not given in the import format), then the tag is given with tag value "?".  When a tag value of a mandatory tag is inappropriate (e.g. a dealing program only gives the tags 'Dealer', 'Vulnerable', and 'Deal'), then the tag is given as an empty string.

For import format, the order of tag pairs is not important.  For export format, the order of tag pairs is:

1.	the mandatory tags in a fixed order
2.	the supplemental tags, sorted alphabetically by their tag name

The 15 tag names of the MTS are (in order):

|     |           |                                         |
|-----|-----------|-----------------------------------------|
|(1)  |Event      |(the name of the tournament or match)    |
|(2)  |Site       |(the location of the event)              |
|(3)  |Date       |(the starting date of the game)          |
|(4)  |Board      |(the board number)                       |
|(5)  |West       |(the west player)                        |
|(6)  |North      |(the north player)                       |
|(7)  |East       |(the east player)                        |
|(8)  |South      |(the south player)                       |
|(9)  |Dealer     |(the dealer)                             |
|(10) |Vulnerable |(the situation of vulnerability)         |
|(11) |Deal       |(the dealt cards)                        |
|(12) |Scoring    |(the scoring method)                     |
|(13) |Declarer   |(the declarer of the contract)           |
|(14) |Contract   |(the contract)                           |
|(15) |Result     |(the result of the game)                 |
{.nohead}

In export format, tag pairs may only occur once.  In import format, a tag pair that already occurred, is ignored.

### 3.4.1  The Event tag

The Event tag value should be reasonably descriptive.  Abbreviations are to be avoided unless absolutely necessary.  A consistent event naming should be used to help facilitate database scanning.

### 3.4.2  The Site tag

The Site tag value should include city and region names along with a standard name for the country.  The use of the ISO 3166 (or, EN 23166) three letter names (instead of the country name) is suggested for those countries where such codes are available.  A comma may be used to separate a city from a region.  No comma is needed to separate a city or region from the ISO 3166 country code.

The ISO 3166 standard is continuously updated.  A copy can be found on the PBN homepage.

### 3.4.3  The Date tag

The Date tag value gives the starting date for the game.  (Note: this is not necessarily the same as the starting date for the event.) The date is given with respect to the local time of the site given in the Event tag. The Date tag value field always uses a standard ten character format: "YYYY.MM.DD".  The first four characters are digits that give the year, the next character is a period, the next two characters are digits that give the month, the next character is a period, and the final two characters are digits that give the day of the month.  If any of the digit fields are not known, then question marks are used in place of the digits.

### 3.4.4  The Board tag

The Board tag value is a positive integer, indicating the board number of the deal.

### 3.4.5  The West tag

The West tag value is the name of the player or players at the West direction.  The names are given as they would appear in a telephone directory.  The family or last name appears first.  If a first name or first initial is available, it is separated from the family name by a comma and a space.  Finally, one or more middle initials may appear.  (Wherever a comma appears, the very next character should be a space.  Wherever an initial appears, the very next character should be a period.)

The intent is to allow meaningful ASCII sorting of the tag value that is independent of regional name formation customs.  If more than one person is playing West, the names are listed in alphabetical order and are separated by the semicolon character between adjacent entries.  A player who is also a computer program should have appropriate version information listed after the name of the program.

### 3.4.6  The North tag

The North tag value is the name of the player or players at the North direction.  The names are given here as they are for the West tag value.

### 3.4.7  The East tag

The East tag value is the name of the player or players at the East direction.  The names are given here as they are for the West tag value.

### 3.4.8  The South tag

The South tag value is the name of the player or players at the South direction.  The names are given here as they are for the West tag value.

### 3.4.9  The Dealer tag

The Dealer tag value is the direction of the game's dealer. The tag value is "W" (West), "N" (North), "E" (East), or "S" (South).

### 3.4.10  The Vulnerable tag

The Vulnerable tag value defines the situation of vulnerability. The following tag values are possible:

"None" , "Love" or "-"	
: no vulnerability

"NS" 					
: North-South vulnerable

"EW"					
: East-West vulnerable

"All" or "Both"		
: both sides vulnerable

In export format the tag values "None" and "All" are applied.

### 3.4.11  The Deal tag

The Deal tag value gives the cards of each hand.  The tag value is defined as `"<first>:<1st_hand> <2nd_hand> <3rd_hand> <4th_hand>"`.  The 4 hands are given in clockwise rotation.  A space character exists between two consecutive hands.  The direction of the `<1st_hand>` is indicated by `<first>`, being W (West), N (North), E (East), or S (South).  The cards of each hand are given in the order:  spades, hearts, diamonds, clubs.  A dot character "." exists between two consecutive suits of a hand.  The cards of a suit are given by their ranks.  The ranks are defined as (in descending order):

    A , K , Q , J , T , 9 , 8 , 7 , 6 , 5 , 4 , 3 , 2.

Note that the 'ten' is defined as the single character "T". If a hand contains a void in a certain suit, then no ranks are entered at the place of that suit.

Not all 4 hands need to be given. A hand whose cards are not given, is indicated by "-" . For example, only the east/west hands are given:

    [Deal "W:KQT2.AT.J6542.85 - A8654.KQ5.T.QJT6 -"]

In import format, the ranks of a suit can be given in any order; the value of `<first>` is free.  In export format, the ranks must be given in descending order; `<first>`   is equal to the dealer.

#### 3.4.12  The Scoring tag

This tag gives the used scoring method. It is an essential part of the game since the tactics of the players depend on the scoring method.

There are a lot of scoring systems with all kind of variations, refer to Bridge Encyclopedia.  New scoring systems evolve for coping with all kind of irregularities, see e.g.:

http://www.gallery.uunet.be/hermandw/bridge/hermtd.html.

The wealth of scoring systems makes standardisation difficult. Therefore, the specification of the tag value is open ended:  only example values are given.  The tag value consists of fields separated by semicolons.  A field indicates either a basic scoring system or a modifier. Examples of basic scoring systems are:

MP	
: MatchPoint scoring

MatchPoints	
: identical to 'MP'

IMP	
: IMP scoring (since 1962)

Cavendish	
: Cavendish scoring

Chicago	
: Chicago scoring

Rubber	
: Rubber scoring

BAM	
: Board-A-Match

Instant	
: apply InstantScoreTable


Examples of modifiers are:

Butler
: the trick point score is IMPed against the average value of all scores

Butler-2
: as 'Butler', but the 2 extreme scores are not used in computing the average value

Experts
: the trick point score is IMPed against a datum score determined by experts

Cross
: the trick point score is IMPed against every other trick point score, and summed

Cross1
: value of 'Cross' , divided by number of scores

Cross2
: value of 'Cross' , divided by number of comparisons

Mean
: the datum score is based on a (normal) average value

Median
: the datum score is based on the median value

MP1
: MatchPoints are computed as:  the sum of points, constructed by earning 2 points for each lower score, 1 point for each equal score, and 0 points for each higher score.

MP2
: MatchPoints are computed as:  the sum of points, constructed by earning 1 point for each lower score, 0.5 points for each equal score, and 0 points for each higher score.

OldMP
: NO bonus of 100 (Doubled) or 200 (Redoubled) for the fourth and each subsequent undertrick, when not vulnerable

Mitchell2
: see [http://www.gallery.uunet.be/hermandw/bridge/hermtd.html

Mitchell3
: idem

Mitchell4
: idem

Ascherman
: idem

Bastille
: idem

EMP
: European MatchPoints

IMP_1948
: IMP scoring used between 1948 and 1960

IMP_1961
: IMP scoring revised in 1961


### 3.4.13  The Declarer tag

The Declarer tag value is the direction of the declarer of the contract.

The tag value is "W" (West), "N" (North), "E" (East), or "S" (South).

The Declarer tag can also cope with the irregularity that the declarer and the dummy are swapped.  This may happen when e.g. South is declarer, but by accident East plays the first card and South puts his cards on the table.  The tag value becomes a caret (^) followed by the direction of the irregular declarer:  "^W", "^N", "^E", resp. "^S".

When all 4 players pass, then the tag value is an empty string.

### 3.4.14 The Contract tag

The Contract tag value can be "Pass" when all players pass, or a 'real'contract defined as:  "`<k><denomination><risk>`"with

`<k>`
: the number of odd tricks, <k> = 1 .. 7

`<denomination>`
: the denomination of the contract, being S (spades), H (Hearts), D (Diamonds), C (Clubs), or NT (NoTrump)

`<risk>`
: the risk of the contract, being void (undoubled), X (doubled), or XX (redoubled)

### 3.4.15  The Result tag

The Result tag value gives the result of the game in number of tricks.
The possible tag values are:

`<result>`						
: number of tricks won by declarer

EW `<result>`					
: number of tricks won by EW

NS `<result>`					
: number of tricks won by NS

EW `<result>` NS `<result>`	
: number of tricks won by EW resp. by NS

NS `<result>` EW `<result>`	
: number of tricks won by NS resp. by EW ith `<result>` = 0 .. 13 .

The `<result>` must match the actual number of won tricks.  However, the players could accidentally agree on a wrong number of tricks.  A caret character ("^") preceding one of the above tag values indicates that the `<result>` differs from the actual number of won tricks.

When all 4 players pass, then the tag value is an empty string.

In export format the tag value contains the number of tricks won by declarer.

The Result tag normally gives the final result after the play has ended.

This is the case when all 52 cards have been played, or when the Play section ends with '`*`'.  The Result tag can also be used to give a partial result.  When the play has not ended, then the Result tag indicates the number of won tricks for the completed, played tricks in the play section.

Usage of '+' in the play section would make it explicitly clear that the Result tag is based on a partial result.

## 3.5  Auction section

The auction section gives the calls, together with the optional annotation.  The start of the auction section is indicated by the tag pair with tag name 'Auction'.  The Auction tag is followed by multiple auction lines containing the calls.  The direction of the player making the first call is given as tag value in the Auction tag pair:  "W" (West), "N"(North), "E" (East), or "S" (South).

In export format this player is always the dealer.  Each auction line contains 4 calls.  Only due to much annotation, a line may contain less than 4 calls.  The call of the dealer always starts left justified at a new line.

In import format the player in the Auction tag value need not be the dealer.  For example, the calls are given in a table of 4 columns with West in the first column.  In that case, each player before the dealer has a hyphen ("-") in the first auction line.

The auction section ends with all passes, or with "`*`" .  The "`*`" character indicates that no further calls will or can be given.  In this case, the result of the auction can be given in the tags 'Declarer' and 'Contract'.

It is also possible that the auction has not been completed yet, with the intention to continue another time.  For example, a game might be saved in a PBN file so that another computer program might make the next call.  The '`+`' character is used to indicate explicitly this intention.  The '`+`'replaces the next call to be made. Hence, it is placed after the last call (and its annotations).  At the continuation, the '`+`' will be replaced by the made call, and possibly a new '`+`' can be inserted. In this situation, the '`*`' character is forbidden to end the auction section.  The usage of '`+'is not obligatory, only recommended.

### 3.5.1  Auction call

A call is represented by a call token.  The possibilities of a call token are:

AP	
: all players pass

Pass	
: the player passes

X	
: the player doubles

XX	
: the player redoubles

`<k><denomination>`  	
: the player bids a contract, where `<k>` and `<denomination>` are defined as in the Contract tag

`-`	
: it is not yet player's turn to make a call

### 3.5.2  Auction annotations

In import format, the following annotations can be added after each call, namely:

1.	at most one suffix annotation
2.	at most one note reference
3.	zero or more NAGs

These annotations are described below.  In import format, the annotations can be given in any order.  In export format, the order is:  the optional note reference, and then the NAGs in increasing order of the NAG values.

The optional suffix has been translated into the corresponding NAG (chapter 3.7).  For example, in an import format PBN file the construction '`1S !! =1= $25`' becomes in export format '`1S =1= $3 $25`'.

### 3.5.3  Auction suffix

Import format PBN allows for the use of suffix annotations for calls.  A suffix token exists for each suffix annotation.  There are exactly six such annotations available:

`!`	
: good call

`?`	
: poor call

`!!`	
: very good call

`??`	
: very poor call

`!?`	
: speculative call

`?!`
: questionable call

These suffixes correspond with the NAG values $1 - $6.  A one-to-one correspondence is needed, because the suffixes are translated to NAG values for the export format.

### 3.5.4  Auction note reference

A call can be followed by at most one note reference. A note is used for indicating alerts (e.g. transfer bids).  PBN does not distinguish between partner-alerts and self-alerts.

The note reference is given by means of a note token, defined as an integer surrounded by equal signs:  `=<note_index>=`   The value of `<note_index>`   lies between 1 and 32.  Several calls may use the same note reference.

In export format, a single space character is entered after the note reference, if it is followed by another token in the text line.

### 3.5.5  Auction note explanation

An auction note reference with index `<note_index>`   is explained in a note tag.  This note tag has tag name 'Note', and the tag value of the note tag equals:  "`<note_index>:<note_text>`"

Note tags may occur more than once (unlike other tags).  They must differ in the value of the `<note_index>`.

The note tags, dedicated to the auction, are placed in the auction section at the end of the auction calls.  They may not be placed in the identification section, nor the play section.

## 3.6  Play section

The play section gives the played cards, together with the optional annotation.  The start of the play section is indicated by the tag pair with tag name 'Play'.  The Play tag is followed by multiple play lines containing the played cards.  The direction of the player playing the first card is given as tag value in the Play tag pair:  "W" (West), "N" (North), "E" (East), or "S" (South).

In export format this player is always the opening leader, being declarer's left hand opponent.  Each play line contains 4 cards.  Only due to much annotation, a line may contain less than 4 cards.  The card of the opening leader always starts left justified at a new line.  A dash '-' is used for each card that is unknown or that has not been played (yet).

The play section ends after 13 tricks, or with "*" .  The "*" character indicates that no further cards will or can be given.  In this case, the result of the play can be given in the tags 'Result'. It is also possible that the play has not been completed yet, with the intention to continue another time.  For example, a game might be saved in a PBN file so that another computer program might play the next card.  The '+' character is used to indicate explicitly this intention.  The '+'replaces the next card to be played. At the continuation, the '+' will be replaced by the played card, and possibly a new '+' can be inserted. Note that the '+' need not be the last character in the Play section, e.g. in the fragment:

    [Play "W"]
    H2   H3   H4   HA
    +    -    -    CQ

South has played the last card, and the game must be continued by West playing the next card.

The usage of '+' is not obligatory, only recommended.  When '+' is not used, then instead a '-' must be used to represent the card to be played.

### 3.6.1  Play card

A card is represented by a card token.  The possibilities of a card token are:

`-`				
: the played card does not matter

`<suit><rank>`
: the played card with¬`<suit>` = S , H , D , C¬`<rank>` = A , K , Q , J , T , 9 , 8 , 7 , 6 , 5 , 4 , 3 , 2.


### 3.6.2  Play annotations

The play annotations are analogous to the auction annotations.

In import format, the following annotations can be added after each card, namely:

1.	at most one suffix annotation
2.	at most one note reference
3.	zero or more NAGs

These annotations are described below.  In import format, the annotations can be given in any order.  In export format, the order is:  the optional note reference, and then the NAGs in increasing order of the NAG values. The optional suffix has been translated into the corresponding NAG (chapter 3.7).  For example, in an import format PBN file the construction 'SK !! =1= $200' becomes in export format 'SK =1= $9 $200'.

### 3.6.3  Play suffix

The play suffixes are analogous to the auction suffixes.

Import format PBN allows for the use of suffix annotations for played cards.  A suffix token exists for each suffix annotation.  There are exactly six such annotations available:

`!`
: good card

`?`
: poor card

`!!`
: very good card

`??`
: very poor card

`!?`
: speculative card

`?!`
: questionable card

These suffixes correspond with the NAG values $7 - $12.  A one-to-one correspondence is needed, because the suffixes are translated to NAG values for the export format.

### 3.6.4  Play note reference

The play note references are analogous to the auction note references.

A card can be followed by at most one note reference. A note is used for indicating lead conventions, signals, etc. The note reference is given by means of a note token, defined as an integer surrounded by equal signs:  `=<note_index>=` The value of `<note_index>` lies between 1 and 32.  Several cards may use the same note reference.

In export format, a single space character is entered after the note reference, if it is followed by another token in the text line.

### 3.6.5  Play note explanation

The play note explanations are analogous to the auction note explanations.

A play note reference with index `<note_index>` is explained in a note tag.  This note tag has tag name 'Note', and the tag value of the note tag equals:  "`<note_index>:<note_text>`"

Note tags may occur more than once (unlike other tags).  They must differ in the value of the `<note_index>`.

The note tags, dedicated to the played cards, are placed in the play section at the end of the played cards.  They may not be placed in the identification section, nor the auction section.

## 3.7  Numeric Annotation Glyphs

An NAG (Numeric Annotation Glyph) is an element that is used to indicate a simple annotation in a language independent manner.  The NAG token consists of the dollar sign ("$") followed by a non-negative decimal integer.  The value of this integer must be between zero and 255.

In export format, a single space character is entered after the NAG if it is followed by another token in the text line.

.note Note:  the number assignments listed below should be considered preliminary in nature; they are likely to be changed as a result of reviewer feedback.

|NAG|Interpretation                  ||
|---|------------------|---------------|
|0  |'no annotation'                  ||
|1  |good call          |(same as "!") |
|2  |poor call          |(same as "?") |
|3  |very good call     |(same as "!!")|
|4  |very poor call     |(same as "??")|
|5  |speculative call   |(same as "!?")|
|6  |questionable call  |(same as "?!")|
|7  |good card          |(same as "!") |
|8  |poor card          |(same as "?") |
|9  |very good card     |(same as "!!")|
|10 |very poor card     |(same as "??")|
|11 |speculative card   |(same as "!?")|
|12 |questionable card  |(same as "?!")|
|13 |call has been corrected manually ||
|14 |card has been corrected manually ||
|15 |\                                ||
|.. | used for commenting calls and played cards||
|255|/                                ||

The NAG values $1 .. $6 and $13 may only be used for calls in the auction section.  The values $7 .. $12 and $14 may only be used for played cards in the play section.

The NAG interpretations are available in a file called "`pbn_eng.nag`".

This file will be publicly available.  It is possible to construct similar files in other languages.  In this way, the expandability of NAG values is guaranteed.

The format of the file is as follows.  The file consists of lines, ending by the CRLF character.  Each line has the syntax:

    <NAG_value> <NAG_text>

The line begins with a left justified non-negative integer.  A single space character separates the NAG value from the NAG text.

## 3.8  Commentary

Comment text may appear in PBN data.  There are two kinds of comments. The first kind is the 'rest of line' comment; this comment type starts with a semicolon character ";" and continues to the end of the line.  The second kind starts with a left brace character "{" and continues to the next right brace character "}".  Comments cannot appear inside any token, nor inside a tag pair.

Brace comments do not nest; a left brace character appearing in a brace comment loses its special meaning and is ignored.  A semicolon appearing inside of a brace comment loses its special meaning and is ignored.  Braces appearing inside of a semicolon comments lose their special meaning and are ignored.

Bridge comments often refer to a suit.  It would be nice to present a suit by a graphical symbol.  The notation for a suit is defined as a backslash folowed by the first character of the suit name.  Hence:

    \S = Spades, \H = Hearts, \D = Diamonds, \C = Clubs.

The position of comments is important.  A comment refers to the preceding event tag, auction call, played card, suffix, note reference, or nag.  Also a comment can be positioned at the begin of the game (before any tag).  The position of the comment must be preserved when a PBN file is converted from import format to export format.  This holds especially when the order of the tags is changed to obey the prescribed tag order in export format.  In export format comments succeeding an event tag are printed at the begin of a new line.  When a comment does not start at a new line, then a single space preceeds the comment begin character ";" or "{".

There are no rules for converting comments from import format to export format.  A conversion program has the freedom to merge comments, etc. After a conversion, the import file won't be used anymore; the export file is used, and the reader observes the comments as they are.

## 3.9  Irregularities

Several irregularities may occur during the auction and the card playing.

An irregularity is considered a problem if it violates the "normal" bridge rules.  Five problems have been identified:

1.	An insufficient bid, accepted by the opponents.
2.	A call out of rotation, accepted by the opponents.
3.	A revoke happened, without being noticed in time.
4.	A lead out of turn, accepted by the opponents.
5.	The declarer and the dummy are swapped, refer to chapter 3.4.13 .

{.upper-alpha .bracket}

NB. Irregular (re)double is impossible, and MUST be taken back.

When an irregularity (an insufficient bid that has been rejected) is solved, then there is no problem for PBN. The solved irregularity and its consequences (e.g. partner must keep passing) can be described as comment.

The following notation handles the irregularity (A) - (D):

^I
: preceding a bid indicates that the bid is insufficient (A)

^S
: indicates that a player was not able to call, because another player has done a call out of rotation (B); the ^S replaces the skipped player's call

^R
: preceding a card indicates a revoke (C)

^L
: preceding a card indicates a lead out of turn (D). The remaining 3 cards are "normally" played in clockwise order after the erroneous lead.

In the following examples West is dealer (situations (A) and (B)), or West must play the lead card (situations (C) and (D)) :

| num | cards                 | desc                                          |
|-----|-----------------------|-----------------------------------------------|
| A)  | `1D  ^I 1C`           | West opens 1 Diamonds, North bids 1 Clubs      |
| B)  | `^S  1D`              | West is dealer, but North opens 1 Diamonds     |
|     | `1D  ^S  2D`          | West opens 1 Diamonds, East bids 2 Diamonds    |
|     | `1D  ^S  ^I 1C`       | West opens 1 Diamonds, East bids 1 Clubs       |
|     | `1D  ^S  ^S  2D`      | West opens 1 Diamonds, South bids 2 Diamonds   |
|     | `1D  ^S  ^S  ^I 1C`   | West opens 1 Diamonds, South bids 1 Clubs      |
| C)  | `CA  ^R S6  C3  C4`   | West plays Clubs Ace, North discards Spades 6  |
| D)  | `CA  C2  ^L C3  C4`   | East instead of West plays the first card in a trick |
{.nohead}

## 3.10  End positions

PBN can be used to describe end positions.  A game is considered an end position when the maximum number of cards of each hand in the Deal tag is less than 13.

The trump is given by the Contract tag, but now the tag value only contains the denomination (without number of odd tricks and without risk) : S, H, D, C, NT.

The tag value of the play section indicates the lead player at the first trick.

## 3.11  Case sensitivity

PBN is case sensitive.  Suits, sides, ranks, etc are given by uppercase characters.  In import format, lowercase characters are allowed, to ease human input.  In export format, only uppercase characters are allowed.  The following table shows the tags where lowercase characters can be used:

|Upper|Lower|Description|Tags|
|-----|-----|-----------|----|
|W    |w    |West       |Dealer, Deal, Declarer, Auction, Play|
|N    |n    |North      |Dealer, Deal, Declarer, Auction, Play|
|E    |e    |East       |Dealer, Deal, Declarer, Auction, Play|
|S    |s    |South      |Dealer, Deal, Declarer, Auction, Play|
|S    |s    |Spades     |Deal, Contract, Auction, Play|
|H    |h    |Hearts     |Deal, Contract, Auction, Play|
|D    |d    |Diamonds   |Deal, Contract, Auction, Play|
|C    |c    |Clubs      |Deal, Contract, Auction, Play|
|NT   |nt   |NoTrump    |Contract, Auction|
|X    |x    |double     |Contract, Auction|
|XX   |xx   |redouble   |Contract, Auction|
|Pass |pass |Pass       |Contract, Auction|
|AP   |ap   |AllPass    |Auction|
|A    |a    |Ace        |Deal, Play|
|K    |k    |King       |Deal, Play|
|Q    |q    |Queen      |Deal, Play|
|J    |j    |Jack       |Deal, Play|
|T    |t    |Ten        |Deal, Play|
|None |none |no vuln.   |Vulnerable|
|Love |love |no vuln.   |Vulnerable|
|NS   |ns   |NS vuln.   |Vulnerable|
|EW   |ew   |EW vuln.   |Vulnerable|
|All  |all  |All vuln.  |Vulnerable|
|Both |both |All vuln.  |Vulnerable|
