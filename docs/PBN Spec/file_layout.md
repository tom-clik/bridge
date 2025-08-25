# 2.  File layout

A PBN file contains one or more text lines. A text line consists of zero or more visible characters. An empty text line has zero visible characters. A visible character is defined as a character that a user can edit. A text line also contains non-visible characters, needed to represent a text line.  The representation of a text line differs among platforms.  The non-visible characters can be linefeeds, carriage returns, zero bytes, padding bytes or even bytes telling the length of a line.

## 2.1  Import format and export format

The PBN standard discerns two formats:  the "import" format and the "export" format.

The import format is rather flexible and is used to describe data that may have been prepared by hand.  The order of tags is unimportant; the use of (superfluous) tabs and space characters does not matter, etc.  A PBN file in import format can have text lines according to the platform's native line representation.  A PBN parser should be able to handle a PBN file with import format, that has been created on a computer, the parser is running on.

The export format is rather strict and is used to describe data that is usually prepared under program control.  A file with export format can be read by a PBN parser on any computer!  So, a PBN parser with the capability of writing a PBN file in export format guarantees the portability of PBN files.

## 2.2  Character set

PBN data is represented using a subset of the eight bit ISO 8859/1 (Latin 1) character set.  ("ISO" is an acronym for the International Standards Organization.) This set is also known as ECMA-94 and is similar to other ISO Latin character sets.  ISO 8859/1 includes the standard seven bit ASCII character set for the 32 control character code values from zero to 31.

The 95 printing character code values from 32 to 126 are also equivalent to seven bit ASCII usage.  (Code value 127, the ASCII DEL control character, is a graphic character in ISO 8859/1; it is not used for PBN data representation.)

The 32 ISO 8859/1 code values from 128 to 159 are non-printing control characters.  They are not used for PBN data representation.  The 32 code values from 160 to 191 are mostly non-alphabetic printing characters and their use for PBN data is discouraged as their graphic representation varies considerably among other ISO Latin sets.  Finally, the 64 code values from 192 to 255 are mostly alphabetic printing characters with various diacritical marks; their use is encouraged for those languages that require such characters.  The graphic representations of this last set of 64 characters is fairly constant for the ISO Latin family.

Printing character codes outside of the seven bit ASCII range may only appear in string data and in commentary.  They are not permitted for use in symbol construction.

The horizontal tab and vertical tab are permitted.  No other ASCII control characters are permitted, except for the (non-visible) control characters for the line representation.

Because some PBN users' environments may not support presentation of non-ASCII characters, PBN game authors should refrain from using such characters in critical commentary or string values in game data that may be referenced in such environments.  PBN software authors should have their programs handle such environments by displaying a question mark ("?") for non-ASCII character codes.  This is an important point because there are many computing systems that can display eight bit character data, but the display graphics may differ among machines and operating systems from different manufacturers.

## 2.3  Line specification

A text line contains any characters from the allowed character set. However, tab characters may not appear inside of string data.

The export format obeys some additional rules.  In export format a textline contains printing characters concluded by an end-of-line indicator.

This end-of-line indicator equals the CRLF character-pair consisting of the ASCII control character CR (Carriage Return, decimal value 13, hexadecimal value 0x0d) and the ASCII control character LF (LineFeed, decimal value 10, hexadecimal value 0x0a).

Tab characters, both horizontal and vertical, are not permitted in the export format.  This is because the treatment of tab characters is highly dependent upon the particular software in use on the host computing system.

The length of a PBN text line is maximally 255 characters, including the non-visible characters, especially the end-of-line indicator.  Lines with 80 or more printing characters are strongly discouraged because of the difficulties experienced by common text editors with long lines.

## 2.4  Escape mechanism

The escape character "%" in the first column means that the rest of the line can be ignored.  A percent sign appearing in any other place other than the first position in a line does not trigger the escape mechanism.

The escape convention can be applied to embed non-PBN commands and data in PBN streams. In PBN, there are two proposed uses:

1.	It indicates the version of the PBN standard used by a computer program. The syntax is:
	
	`% PBN <major version #>.<minor version #>`
    
2.	It indicates that a PBN file has export format. The syntax is:
	    
	`% EXPORT`
