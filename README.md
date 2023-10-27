# Reject Demo (Patched Version)
Source code for the patched version of Reject's "Reject Demo"

# Mono-mental

Full assembler source for the "Mono-mental" demo by The Senior Dads, which was released on the Atari 16 bit platform on the 11th April 1998 at the first ALT Party in Turku, Finland.

This release is different to other demo source code releases from us in that it's not the original source, (which is lost), but a reverse-engineer of the source code from the original binary. The original binary was disassembled and the source code was re-created from the disassembly. The original graphics and sound were also re-created from the binary. You can find out more about how this was done [here](https://github.com/theseniordads/monomental/blob/main/DOCS/README.md).

## Specifications

* An Atari ST or later with at least 1 megabytes of memory, TOS 1.04 minumum, a hard drive, and **hi-res mono monitor**.
* ... Alternatively, a decent emulator like Hatari, configured as above.
* Devpac 3 to assemble the code.
* Atomix packer or better to pack the executable.

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
* `GRAPHICS` 
  * `REJECT.PI1`- Intro page for the reject demo
* `DEMOPARTS` - Inidividual parts of the demo, used by `MAIN.S`.
* `DISASSEMB/REJECT.S` - Disassembly of the original binary using TT-Digger. This is what we started out with!
* `INCLUDES` - Various macro and helpers code.
* `REJECT.OLD` - Original version of "Reject" demo before patching.
* `MUSIC` - `.THK` Chip tune music used by the demo.
  * `RASERO.THK` - "Rasero Team F**k Out" music. (With reply code)
  * `RASERO.MUS` - "Rasero Team F**k Out" music.    (Megatizer editor file.)
