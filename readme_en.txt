dmm2xm v1.3 (18 Nov 2007)
=========================


Contents
========
* Description
* Usage
* Backward conversion
* Messages
* News
* Future
* Acknowledgements
* Other


Description
===========

dmm2xm converts music from DMM to XM format, which is playable in
many players and editable in trackers.

dmm2xm tries to do exact conversion, and even more, adds stereo,
which results in better sound, however, there are some special
cases (see "Messages" section).

Starting from version 1.0, backward conversion is available, from
XM and MOD to DMM. Most of simple songs converting pretty good,
and more complicated ones need to be edited first.
See "Backward conversion" section for details.

DMM is used in computer game Doom2D (c) Prikol Software.

Done for Doom2D: Forever project (http://www.doom2d.org/)
and all fans of Doom2D.


Usage
=====

dmm2xm can convert music from DMM with instruments,
or directly from doom2d.wad.
Theoretically, program works with any other WAD file
with DMM, if you find one, please let me know.

dmm2xm searches for instruments in 5 places:
- in specified WAD file;
- near specified file;
- in dmm2xm folder;
- in dmi\ subfolder near specified file;
- in dmm2xm\dmi\ folder.
Instruments should be named like "DMI00nn.smp".

dmm2xm has the following syntax:
dmm2xm [-q <number>] [-o <file>] [-f <name>] [-m] <song.dmm>|<file.wad>

Examples:
dmm2xm -q 8 -o ñ:\music\doom2d\best.xm BEST.dmm
dmm2xm ALLRIGHT.dmm
dmm2xm doom2d.wad (get list of possible names)
dmm2xm -f ALLRIGHT doom2d.wad

You can just drag'n'drop DMM on dmm2xm, if you're Explorer's fan,
but you will lose most of its functionality.

-q, Quantization determines how much notes' delays will be rounded.
The bigger it is, the less space used to record notes.
In DMM there are usually delays of 8, 12, 16 and greater, so,
in most cases, you can round to 4 without fear of misplacing notes.
Quantization = 4 is default value.
You should try to set maximum quantization that doesn't misplace notes.
For example, for "ALLRIGHT.dmm", best quantization is 8.

-o parameter allows to save resulting XM with different
name or in different place.

-f specifies which file to convert from doom2d.wad.
File name is case-sensitive.

-m makes converted song mono, instead of stereo.

You can get files from doom2d.wad with QPak plugin for Far Manager
(http://downloads.sourceforge.net/farplugins/qpak162.rar).


Backward conversion
===================

If you want to insert music in Doom2D map, this function is for you.

Syntax:
dmm2xm [-o <file>] <song.xm>|<song.mod>

Example:
dmm2xm song.xm

Most of effects can't be supported because limitations of DMM format,
and some are not implemented yet.

Supported effects in current version:
----------------------------------------------------------------------
Effect   Name                  Comment
----------------------------------------------------------------------
Cxx      Set volume      Setting non-zero volume without retriggering
                         note is not supported (limitation of DMM).
Dxx      Pattern break   Effect parameter is ignored, so next pattern
                         will be recorded from the first note.
Fxx      Set speed       Fully supported.
----------------------------------------------------------------------

How to edit song before backward conversion to get best results:
- Ensure that tempo (BPM) is multiple of 125 or 166, otherwise
  resulting DMM could play faster or slower than original.
  To do that, you can add variable Fxx effect into empty effect
  column, for example: F04 F03 F04 F03 ...
- Ensure that there's no too low or too high notes, as well as
  no notes with too high sample rate (greater than 44000 Hz, I
  suppose), otherwise Doom2D will play these notes as one with fixed
  frequency. Always test to see if song plays right.
- Get rid of such situations, when note is die away from Axx effect
  (Volume slide), in Doom2D it won't die away. You may prefer
  to set note stop somewhere in middle of reducing note's volume.
- Sometimes it's better to replace setting volume to note stop,
  if volume is set without replaying note.
  Doom2D will play note with starting volume.


Messages
========

"Error: file not found!"
Point to existent file.

"Error: invalid quantization value, should be 1 <= Q <= 256."
Set valid quantization.

"Error: unknown DMM format!"
Program accepts only DMM files and only of type 0.

"Warning: quantization may be wrong or too large, misaligned N notes."
In some songs, notes are misaligned from beginning, and have
delay of 15, 17, 31, 33, or other unrounded value. You shouldn't
worry about that, notes will be rounded to delays of 16 and 32,
and it's how it needs to be.
Usually there are a few such misplaces in these cases.

"conv_wad.bat" converts all Doom2D songs from doom2d.wad with
best quantization. "conv_dmm.bat" converts already ripped DMM files.
Note: there are some russian filenames, program may fail on them.

You can get "possibly broken data" message only if you have
damaged (incorrectly ripped) DMM files.

"Warning: too many notes in one pattern, lost data, set bigger
quantization!"
Message means that some notes was lost because of limit of notes in one
pattern (1024). You need to set larger quantization to avoid that.
That occurs only with single DMM from doom2d.wad.

"Warning: found more than 11 instruments, stereo is not available."
You have found non-standard DMM with large number of instruments.
Unfortunately, there's no table in dmm2xm to make that many
instuments stereo.


News
====

What's new in current version of dmm2xm.

v1.3 [18.11.2007]
- Small fixes.

v1.2 [02.11.2007]
- Setting speed to zero is ignored now in backward conversion.
- Yet another fixes in backward conversion.

v1.1 [01.11.2007]
- Fixed bug with squeaking in backward conversion.
- Fixed speed calculation and added Fxx effect in backward conversion.
- Small fixes.

v1.0 [01.10.2007]
- Fixed and changed method of looping. Now it should be same as
  original.
- Changed DMM to XM conversion. No hearable changes, files are smaller
  now.
- Backward conversion! (Experimental)
- Removed instruments' extension.
- Ability to leave converted song in mono.
- Various fixes.

v0.9 [20.09.2007]
- Conversion is now quicker a lot.
- Better command line support.
- Ability to convert files directly from doom2d.wad and other WAD
  files.
- Batch file "convall.bat" split to "conv_dmm.bat" and "conv_wad.bat".
- Small fixes.

v0.8
- Now converting with stereo.
- Small fixes.

v0.7
- Fixed redirection to file, written batch file "convall.bat".
- Fixed bug with large delays.
- Improved messages about misplaced notes.
- Unused channels are deleted now.
- No warnings about empty instruments.
- Small fixes.

v0.6 [14.09.2007]
- First public version.


Future
======

What is planned to be implemented in future versions of dmm2xm:

- Split patterns for convenient editing
- Improve backward conversion


Acknowledgements
================

Thanks to BeRo for BeRoXM unit for Delphi that works with XM files.

Thanks to 3EPHOEd for DMM format documentation and for batch file.

Thanks to Jabberwock for testing.

Thanks to -=CHE@TER=- for WAD reader unit.


Other
=====

A few DMM songs need to be edited after conversion.

In source folder you can find sources of the dmm2xm.
They will compile with any Delphi version, starting from 4,
and also with Free Pascal, starting from version 2.0.4.

If you find bugs or have anything to say,
you can contact me
- by email: grompe@yandex.ru
- by icq: 9070033

Regards, Grom PE
