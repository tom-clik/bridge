# 4.  Supplemental tags

The following tags can be used optionally.  They are not contained in the mandatory set MTS.

The title of each chapter contains the tag names. The tag value of each tag is a string token without any restrictions unless stated otherwise.

## 4.1  Game related information

### 4.1.1  Tag: Competition

This tag describes the type of competition.  Examples tag values are:

    "Cavendish", "Chicago", "Individuals", "Pairs", "Rubber", "Teams".

### 4.1.2  Tag: DealId

This tag identifies a deal by a unique value; no two PBN deals should have the same tag value for DealId.  The syntax of the tag value is left unspecified; typically, it will contain values from tags such as Round, Board, Event, Date, Generator, etc.

Adding this tag to games allows programs to easily find all games belonging to the same deal, for instance to do comparisons for duplicate scoring.  Usage is strongly recommended, when there is a chance that the PBN games are copied in other PBN files.

### 4.1.3  Tag: Description

The purpose of this tag is to give arbitrary game description.  It can be used when no other tag is suited.

### 4.1.4  Tag: FrenchMP

This tag indicates if French scoring is used, default is 'No'.  The only two possible tag values are:  "Yes" and "No".

### 4.1.5  Tag: Generator

This tag indicates how the cards have been generated. It is intended for bridge computer programs and especially hand generators. The tag value may include the name of the program and possibly a seed value.

### 4.1.6  Tag: Hidden

This tag indicates the directions of the hands that should be hidden by a viewer after the PBN game has been loaded.  The idea is to reveal the hands on user request, after the user has solved some task using only the visible cards.  The tag value is a sequence of characters representing the directions to be hidden.  The possible characters are:  W (West), N (North), E (East), and S (South). For example:  [Hidden "WE"] means, that initially the cards of E/W must be hidden.

### 4.1.7  Tag: Room

This tag can be used in a teams bridge tournament.  The only two possible tag values are:  "Open" and "Closed".

### 4.1.8  Tag: Termination

This takes a string that describes the reason for the conclusion of the game.  While the Result tag gives the result of the game, it does not provide any extra information and so the Termination tag is defined for this purpose. Examples are:

"abandoned"		
:abandoned game.
"adjudication"		
:result due to third party adjudication process
"death"			
:losing player called to greater things, one hopes
"emergency"		
:game concluded due to unforeseen circumstances
"normal"			
:game terminated in a normal fashion
"rules infraction"	
:administrative forfeit due to losing player's failure to observe either the Laws of Bridge or the event regulations
"time forfeit"		
:loss due to losing player's failure to meet time control requirements
"unterminated"		
:game not terminated

## 4.2  Score related information

### 4.2.1  Tag: Score

This tag gives the number of points of the game based on the trick score.

The score can be given in 5 possible formats:

"`<score>`"					
:score of declarer
"EW `<score>`"				
:score of EW
"NS `<score>`"				
:score of NS
"EW `<score>` NS `<score>`"	
:score of EW resp. NS
"NS `<score>` EW `<score>`"	
:score of NS resp. EW

here `<score>` is the integer number of points.

The score can deviate from the normal value due to irregularities. This can be explained in commentary.

### 4.2.2  Tag: ScoreIMP

This tag gives the score in International MatchPoints based on the difference between score points (given in tag Score).  The score can be given in the 5 possible formats, defined in the Score tag.  Now, `<score>` is the number of IMPs.  The value of `<score>` is normally an integer number. It can also be a broken number due to averaging of IMP values.  In that case, it is represented as a decimal number having a decimal dot. The modifiers in the Scoring tag specify how the IMPs are computed.

### 4.2.3  Tag: ScoreMP

This tag gives the MatchPoints based on the ranking of score points (given in tag Score).  The score can be given in the 5 possible formats, defined in the Score tag.  Now, `<score>` is the number of MatchPoints.  The value of `<score>` is normally an integer number.  It can also be a broken number due to averaging of MatchPoints values.  In that case, it is represented as a decimal number having a decimal dot.

The computation of the MatchPoints is computed as:  the sum of points, constructed by earning 2 points for each lower score, 1 point for each equal score, and 0 points for each higher score. This definition is indicated in the Scoring modifiers as 'MP1'.

### 4.2.4  Tag: ScorePercentage

This tag gives the percentage score.  The score can be given in the 5 possible formats, defined in the Score tag.  Now, `<score>` is the percentage, a decimal value between 0 and 100.

### 4.2.5  Tag: ScoreRubber

This tag gives the game's score for Rubber bridge or Chicago bridge.  The score can be given in the 5 possible formats, defined in the Score tag. Now, `<score>` is defined as:

    <score> = <non-negative integer>/<non-negative integer>

where the integer before "/" is the score above-the-line (bonus points or premium points), and the integer after "/" is the score below-the-line (trick points).

### 4.2.6  Tag: ScoreRubberHistory

This tag gives the scores above-the-line (bonus points or premium points) and the scores below-the-line (trick points) for both sides at the beginning of a deal in a rubber match. The syntax of the tag is:

    [ScoreRubberHistory "NS <HistoryScore> EW <HistoryScore>"]

Each `<HistoryScore>` consists of 3, 4 or 5 score units (being non-negative integers), depending on the number of finished rubber games in the current rubber. The syntax of `<HistoryScore>` is:

    <above_previous> <above_current>/<below-1> <below-2> <below-3>

where

`<above_previous>`	
:all above-the-line points in previous rubbers (if any)
`<above_current>`	
:all above-the-line points in the current rubber
`<below-n>` 		
:the below-the-line points, either at begin of the current deal in game 'n' or at the end of finished game 'n'

During the first game, the values for `<below-2>` and `<below-3>` are omitted.

During the second game, the values for `<below-3>` are omitted. The slash "/" separates the scores above-the-line from the scores below-the-line just as in tag ScoreRubber.

Note that the number of games won defines the vulnerability. This must be consistent with the Vulnerable tag (if present).

## 4.3  Player related information

### 4.3.1  Tags: BidSystemEW, BidSystemNS

These tags describe the bidding system for each side.

### 4.3.2  Tags: PairEW, PairNS

These tags describe the partnerships East/West and North/South.  Suitable tag values are the names of the players, when it is unknown who is sitting North, East, South, West.  Other suitable tag values are the values of the PairId_NS and PairId_EW columns from the ScoreTables, or the values of the PairId column from the TotalScoreTable.

### 4.3.3  Tags: WestNA, NorthNA, EastNA, SouthNA

These tags are the e-mail or network addresses of the players.

### 4.3.4  Tags: WestType, NorthType, EastType, SouthType


These tags describe the player types.  Two typical example tag values are:

"human"	
:a human player
"program"	
:an algorithmic (computer) player

## 4.4  Event related information

The following tags are used for providing additional information about the event.

### 4.4.1  Tag: EventDate

This tag describes the starting date of the event. The used format is
the same as for the Date tag.

### 4.4.2  Tag: EventSponsor

This tag gives the name of the sponsor of the event.

### 4.4.3  Tag: HomeTeam

This tag gives the name of the home team.

### 4.4.4  Tag: Round

The Round tag value gives the playing round for the game.  The round indicator consists of letter characters, digit characters and the underscore.

Some organizers employ unusual round designations and have multipart playing rounds and sometimes even have conditional rounds.  In these cases, a multipart round identifier can be made from a sequence of round indicators separated by periods.  The leftmost indicator represents the most significant playing round, and succeeding indicators represent playing rounds in descending hierarchical order.

### 4.4.5  Tag: Section

This tag is used for the playing section of a tournament. Examples are "Open", "Ladies" or "Reserve".

### 4.4.6  Tag: Stage

This tag is used for the stage of a multistage event. Examples are "Preliminary" or "Semifinal".

### 4.4.7  Tag: Table

This tag identifies the table in a tournament.  The tag value will normally be a positive integer.

### 4.4.8  Tag: VisitTeam

This tag gives the name of the visiting team.

## 4.5  Time and date related information

The following tags assist with further refinement of the time and data information associated with a game.

### 4.5.1  Tag: Time

This uses a time-of-day value in the form "HH:MM:SS"; similar to the Date tag except that it denotes the local clock time (hours, minutes, and seconds) of the start of the game.  Note that colons, not periods, are used for field separators for the Time tag value.  The value is taken from the local time corresponding to the location given in the Site tag pair.

### 4.5.2  Tag: UTCDate

This tag is similar to the Date tag except that the date is given according to the Universal Coordinated Time standard.

### 4.5.3  Tag: UTCTime

This tag is similar to the Time tag except that the time is given according to the Universal Coordinated Time standard.notes

## 4.6  Time control

The following tags are used to help describe the time control used with the game.

### 4.6.1  Tag: TimeControl

This tag indicates how many games must be played within a certain time limit.  The tag value has the syntax:  "`<NrGames>/<NrMinutes>`"This means that the number of games, given by `<NrGames>`, must be finished before a time in minutes, given by `<NrMinutes>`.

For example:  `[TimeControl "4/30"]` means, that 4 games must be finished in half an hour.

When there is no time limit at all, then use "" as tag value.

### 4.6.2  Tag: TimeCall

This tag is used to limit the time for making a single call.  The tag value is defined in number of seconds.

This tag can typically be applied for computer programs.

### 4.6.3  Tag: TimeCard

This tag is used to limit the time for playing a single card.  The tag value is defined in number of seconds.

This tag can typically be applied for computer programs.

## 4.7  Miscellaneous

These are tags that can be briefly described and that don't fit well in other chapters.

### 4.7.1  Tag: Annotator

This tag identifies the annotator or annotators of the game.

### 4.7.2  Tag: AnnotatorNA

This tag is the e-mail or network addresses of the annotator.

### 4.7.3  Tag: Application

The intention of this tag is to fill in a particular application (especially a computer program).  It can be used as an anchor for Application specific data, that are added immediately after this tag in comments.

### 4.7.4  Tag: Mode

This tag gives the playing mode of the game.  Examples are:

"EM"   	
:electronic mail
"IBS"  	
:Internet Bridge Server
"OKB"  	
:OK Bridge
"TABLE"	
:normal table
"TC"   	
:general telecommunication

## 4.8  Tag value inheritance

A tag with the special tag value "#" inherits the tag value of the corresponding tag in the nearest previous game.  This process repeats until a tag has been found with a 'real' tag value different from "#".  If no previous tag can be found, then the tag value is set to "".

There are some exceptions to this feature.  The tag value "#" is forbidden for the tags 'Dealer', 'Vulnerable', 'Deal', 'Declarer', 'Contract', 'Auction', 'Play', and the note tags in the auction section and the play section.

A program may show "#" on the user interface instead of the 'real'inherited tag value.  The user should be aware of this.  Thanks to the exceptions, the PBN game can still be played.

This optional feature not only minimizes the file size.  It also stresses that a PBN game is related to a previous PBN game.

The concept of the tag value "#" is defined one step further.  When a tag has a tag value beginning with ##, then the (optional) text after ## can be interpreted as:  use this text in all subsequent games.  So, all the subsequent games need not repeat the tag with a "#". This feature minimizes the file size a lot more.

The tags that are forbidden to use "#" (see above), are also forbidden to use ##.

The tags with ## at the top of the file can be seen as a header.  Such tags can still redefine their tag value in the middle of the file.  The redefined tag value need not begin with ##.

Example:  at the top of the file, the date tag is given using ##.  At the middle of the file the date tag is redefined because the next 24 boards are played at the next day.

Note that in export format a mandatory tag can be omitted when there is a corresponding tag using ## in a previous game.

## 4.9  Expandability

PBN is intended to be expandable.  Future versions can have new tag pairs, that are a valuable addition to the current version.  When a PBN file includes new tag pairs, then these tags might not be recognized by PBN parsers.  A PBN parser is robust when it just skips such tags, and perhaps shows a warning.

The syntax of a tag is designed so that it must be able to parse any tag without interpreting its contents.  The same remark holds for supplemental sections (chapter 5).  The syntax of a section element allows a parser to skip all the section data until a tag has been found or until the end of the game.

## 4.10  Compatibility

The PBN standard is subject to change.  Newer versions clarify ambiguities observed in applying the standard.  Also, usage of the PBN standard indicates shortcomings in the possibilities of the PBN notation.

The differences between the PBN versions lead to compatibility problems. The intention is to restrict these problems to a minimum. Backward compatibility is maintained by the following rule:  a PBN file complying to a certain PBN version must also be valid for any higher PBN version.

Forward compatibility can be guaranteed by honouring the expandability feature.  This implies that the syntax of tags and sections must obey the following rules.  The general syntax of a tag (as defined in chapter 3.3) may not change.  And, the general syntax of a section (as defined in chapter 5) may not change.
