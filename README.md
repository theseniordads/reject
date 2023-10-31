# Reject Demo (Patched Version)

Full assembler source for the patched version of the "Reject" demo by Reject, released by the Senior Dads on 23rd March 1998.

The original version of the demo, as released by Reject in early 1998, required the user to switch the screen resolution to low-res on an ST, and did not include any music. The Senior Dads verdion worked from any colour graphics mode, and added music.

This release is not the original source, (which is lost), but a reverse-engineer of the source code from the original binary. The original binary was disassembled and the source code was re-created from the disassembly. The original graphics and sound were also re-created from the binary. 

## Specifications

* An Atari ST or later with at least 1 megabytes of memory, TOS 1.04 minumum, a hard drive, and colour display.
* ... Alternatively, a decent emulator like Hatari, configured as above.
* Devpac 3 or VASM/Vlink to assemble the code.
* [UPX](https://upx.github.io/) packer to pack the executable.

## How to assemble on an Atari

* Load "MAIN.S" into Devpac 3.
* Make sure settings are set to assemble to Motorola 68000.
* Assemble to executable file "MAIN.PRG".
* Rename exectuable to "REJECT.TOS".
* Pack "REJECT.TOS" with packer. (**NOTE**: We've only managed to get [UPX](https://upx.github.io/) to pack this!)
* Run "REJECT.TOS".

## How to assemble on modern systems

This requires [VASM](http://sun.hasenbraten.de/vasm/https:/) and [Vlink](http://www.compilers.de/vlink.html), which you can get for most modern systems.

To compile the source:

`vasmm68k_mot main.s build/main.o -m68000 -Felf -noesc -quiet -no-opt`

To turn the compiled binary to an Atari executable:

`vlink build/main.o build/REJECT.TOS -bataritos`

## Files

* `MAIN.S` - Main source code file. Assemble this to create the demo.
* `COMPILED` - Compiled versions of the demo.
  * `ORIGINAL` - Original compiled demo and accompanying [README](https://github.com/theseniordads/reject/blob/main/COMPILED/ORIGINAL/README.TXT).
  * `REMASTER` - Compiled version of the demo from the reverse-engineered source code.
* `DEMOPARTS` - Inidividual parts of the demo, used by `MAIN.S`.
* `DISASSEMB/REJECT.S` - Disassembly of the original binary using TT-Digger. This is what we started out with!
* `ETC`
  * `RASERO.SND` - Music converted into SNDH format.
  * `SCREENSHOT.PNG` - Screenhot of demo.
* `GRAPHICS`
  * `REJECT.PI1`- Intro page for the reject demo
* `INCLUDES` - Various macro and helpers code.
* `MUSIC` - `.THK` Chip tune music used by the demo.
  * `RASERO.THK` - "Rasero Team F**k Out" music. (With reply code)
  * `RASERO.MUS` - "Rasero Team F**k Out" music.    (Megatizer editor file.)
* `REJECT.OLD` - Original version of "Reject" demo before patching.
