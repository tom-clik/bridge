# 5. Supplemental sections

## 5.1  General description

A supplemental section is a unit of information consisting of a tag pair and section data following this tag pair.  In general, the section data are so large that they don't fit in a tag value.

The section data consist of so-called section elements. A section element has 2 representations.  Either it is a string token, or a section token.  A string token can be used for section data consisting of characters, that are not allowed for section tokens.  Thanks to the double quotes at the begin and end of the string token, it is clear where such a section element begins and ends.

The white space characters serve as separator between section elements. Section tokens do not include white space characters.  The string token can have spaces, and is used for e.g. names.

Only the tag pair of the section may be followed by commentary. Commentary after a section element is forbidden. To avoid confusion with commentary, the characters ';' , '{' , and '}' are forbidden in section tokens.

In export format, all the section elements in one text line are separated by a single space character. There is an exception to this rule, namely in case of tables that specify a minimum column width.

## 5.2  Description of tables

The supplemental sections below can be viewed as tables.  The section data of tables have some additional characteristics.  For clearness' sake, the section elements of tables are called table elements.

The section data of a table are structured in rows and columns.  A table element belongs to one row and one column.  The tag value of a table describes the columns of the table's section data.  A table has at least 1 column.  The tag value consists of 1 or more column name tokens separated by the semicolon ';' .

Each table below has a set of predefined column names.  It is not needed to use all these predefined columns, any subset is possible.  Furthermore, it is allowed to add columns with user defined column names.  Such a name may not have ';' since this character serves as separator. The rows of a table do not need to have a specific order.  In most cases there will be a numerical order, e.g.  based on a score.  When the table elements in a column have a descending or ascending order, then this can be indicated explicitly by entering a '+' or '-' just before the column name.

The character '+' means descending (i.e. highest value at first row), and the character '-' means ascending (i.e. lowest value at first row).

The minimum width of the table elements in a column can be specified. This is needed to format a table nicely in export format. The width is indicated by entering at the end of the column name a backslash '\' followed by an integer being the minimum width. Extra spaces must be added before/after the table element to reach the minimum width. Optionally, the alignment can be indicated. After the minimum width integer, character 'L' indicates left alignment (only extra spaces after the table element), and 'R' indicates right alignment (only extra spaces before the table element).

An unknown table element is indicated by '?' , and an irrelevant table element is indicated by '-' .  A table element representing an artificial score value is preceded by the caret character ("^").

In import format, there is no restriction on the number of table elements in a text line.

In export format, all the table elements of a row are contained in one text line, and they are separated by a single space character. There can be more than one space character, but only when a column has defined a minimum column width.

The following chapters describe the defined supplemental sections.  The title of each chapter contains the tag name of the section.

## 5.3  ActionTable

This table gives a scale of percentages for certain actions in a game. Some comment in the game can indicate the user's task.  After the user has made his choice, the table can be shown or even processed with the user's input.  The possible actions are:
 
1.	Making a call.

	All previous calls are given ending with '+' .

2.	Playing a card (especially the first lead card).

	All previous played cards are given ending with '+' .

3.	Bidding a contract.

	Comment can be added to tell opponent bidding. So, the final contract might be declared by the opponents, possibly doubled.

{.lower-alpha}

The predefined column names are:

Rank		
: rank order of action

Call		
: call as defined in auction section

Card		
: card as defined in play section

Declarer	
: declarer as defined in Declarer tag

Contract	
: contract as defined in Contract tag

Percentage	
: percentage for action


## 5.4  AuctionTimeTable

This table gives the thinking times of the calls during the auction. An Auction section must be given before this table section. Each row gives the thinking time of one call. The order of the thinking times is exactly the same as the order of the call tokens in the Auction section.

The predefined column names are:

Time
: thinking time for call

TotalTime
: total time since start of game


The syntax of these 2 fields equals (compare tag Time in chapter 4.5.1) :

|           |                           | 
|----------:|---------------------------|
|HH:MM:SS   |hours:minutes:seconds , or |
|MM:SS      |minutes:seconds , or       |
|SS         |seconds                    |
{.nohead}

## 5.5  InstantScoreTable

This table shows ranges of scores, so no contracts.  After playing a game, the realised score can be looked up immediately in the table and translated to a percentage.

The score ranges do not overlap, and all the score ranges together cover the whole score space.

The predefined column names are:

Rank
: rank order of score

ScoreRange_NS
: `<score_range>` of NS

ScoreRange_EW
: `<score_range>` of EW

IMP_NS
: IMP score of NS

IMP_EW
: IMP score of EW

Percentage_NS
: percentage score of NS

Percentage_EW
: percentage score of EW where `<score_range>` can be:
	
	`<score>`
    : score equal to `<score>` (as in Score tag)

	`<score1>`,`*`
    : scores higher than `<score1>`

	`<score1>`,`<score2>`
    : scores higher than `<score1>` and lower than score2>

	`*`,`<score2>`
    : scores lower than `<score2>`

## 5.6  PlayTimeTable

This table gives the thinking times of the cards during the play. A Play section must be given before this table section. Each row gives the thinking time of one played card. The order of the thinking times is exactly the same as the order of the card tokens in the Play section.

The predefined column names are:

Time
: thinking time for card
TotalTime
: total time since start of game

The syntax of these 2 fields equals (compare tag Time in chapter 4.5.1) :

`HH:MM:SS`
: hours:minutes:seconds , or

`MM:SS`
: minutes:seconds , or

`SS`
: seconds


## 5.7  ScoreTable

This table presents the duplicate game results of a tournament.  After playing a game, the result can be compared with the games that have actually been played in a tournament.

The advantage is that a deal can be described in a single game without auction and play section.  The input for such a game may come from a tournament administration program.  When a game has an auction and play section, then the game still occurs as entry in the ScoreTable.

The predefined column names are:

Rank			
: rank order of score; or best rank in case of ties

PairId_NS		
: pair identification of NS players

PairId_EW		
: pair identification of EW players

Names_NS		
: <names> of NS players

Names_EW		
: <names> of EW players

Contract		
: as in Contract tag: <k><denomination><risk>

Declarer		
: direction of declarer: W, N, E, S

Result			
: number of tricks won by declarer

Score_NS		
: trick score of NS

Score_EW		
: trick score of EW

IMP_NS			
: IMP score of NS

IMP_EW			
: IMP score of EW

MP_NS			
: MatchPoints score of NS

MP_EW			
: MatchPoints score of EW

Percentage_NS	
: percentage score of NS

Percentage_EW	
: percentage score of EW

Multiplicity	
: the multiplicity of the score where `<names>` is defined as:  a string token containing the names of the 2 players 
	separated by ';' , or the name of the partnership.

Also artificial scores due to irregularities can be included.  In such a case, possibly enter '-' for the fields Contract, Declarer, and Result.

# 5.8  TotalScoreTable

This table shows the total scores of (a part of) a tournament that have actually been realised.

The predefined column names are:

Rank				
: rank order of score; or best rank in case of ties

PairId				
: pair identification of players

Names				
: `<names>` of players (as defined in ScoreTable)

TotalScore			
: cumulative value of scores

TotalIMP			
: cumulative value of IMPs

TotalMP			
: cumulative value of MatchPoints

TotalPercentage	
: cumulative value of percentage

MeanScore			
: ean value of scores

MeanIMP			
: mean value of IMPs

MeanMP				
: mean value of MatchPoints

MeanPercentage		
: mean value of percentage

NrBoards			
: the number of played games

Multiplicity		
: the multiplicity of the scoreIn general, a mean value is averaged over the number of played games.

