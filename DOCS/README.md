# "Reject Demo (Patched Version)" Recompilation notes

By **THE SENIOR DADS**

*19 Dec 2023*

This is another one of our source code reverse-engineer specials! Don't worry though, this document will not be another epic journey like with "Mono Mental"! The code in this case is actually quite a small (if fiddly!) thing, and was fairly easy to decompile and clean up. We used the previous setup we evolved when decompiling "Mono Mental" (Running TT-Digger v6.2 in Hatari to disassemble the code-you can see the results in [`DISASSEMB/REJECT.S`](../DISASSEMB/REJECT.S)- HRDB to emaulate the Atari and debug, Visual Studio Code with AmigaAssembly extension to clean up and compile the source code.) to do this one, and compared to "Mono Mental" it was like a walk in the park!

To set the scene, the original "Reject demo" by Reject was released in early 1998. It didn't have any music, and required to be run in lo-res, as it didn't change resolution by itself. It also loaded a file called `REJECT.DAT` from disk. Our patched version added music, could run in any resolution (almost!), incorporated the `REJECT.DAT` file into the program itself so it didn't need to load it from disk, meaning we could also pack the whole demo into about 14K!

## How it works

At the start of our code, we check if the program is running on an Atari Falcon. The reason we do this is that the next check is if the program is running on a machine with a monochrome display. Normally that means you can't run the demo **BUT** you can if you're running monochrome compatibility mode on a Falcon with a colour display! If that's not the case, you'll get a jolly little message telling you to *"piss off"*, and the program will end!

The next thing that happens is that we determine where our program is in memory, and the length of the code and data, which includes our music file, `REJECT.DAT`, and the original demo binary file, and then use that to call a Trap #1 `mshrink` to protect the program memory. We've included the three data files in our program using an `incbin` statement, so that when it's compiled it's all in the one file, and we don't have to load anything from disk once the demo's loaded. 

The three data files were easy to recover. We already had the original music file to hand, and we could get `REJECT.DAT` and the original demo binary file from the original demo, which we found on [Demozoo](https://demozoo.org/productions/74425/)!

One thing we found early on when we first did the patch was that is that `REJECT.DAT` is actually a Degas Elite PI1 file! If you can run a graphics program that can import PI1 files, you can see it for yourself if you load [`GRAPHICS/REJECT.PI1`](../GRAPHICS/REJECT.PI1) into it! (Otherwise, you can see it converted into PNG here: [`ETC/screenshot.png`](..//ETC/screenshot.png)

The next thing we do is save the current resolution, and set the screen to lo-res, which fixed one problem with the demo! We then start up the music, which fixes the other problem! The music has a blank pattern at the start, which how it appears the music starts *after* the intro text has appeared!

Before we start the music though, we set up a patch on trap #1 to sort out the final problem of having to load `REJECT.DAT` from disk! We'll talk about that later.

As we've included the original demo binary in our program, in order to run it, we need to do the same thing the TOS loader does, which is to relocate the program in memory. This is done by reading the relocation table at the end of the program  "file", and updating the addresses in the program code with the correct addresses for where the program is in memory.

Finally we pass the address of our program's basepage (256 bytes before the start of code) to `a0`, as that gets picked up by the original demo code, and we then jump into the binary code, and the demo runs as normal, but with music, and our super-duper patch!

When the demo ends, we restore the screen resolution, stop the music, and then exit the program, but that's also part of the patch, so let's get onto that!

## How the Trap #1 patch works

The Trap #1 patch is an evolution of code we used when we patched the Falcon demo "[A L'Aube Du Matin Du Soir II](https://demozoo.org/productions/65073/)" to run on an STE in 1996. It's a bit of a fiddly thing, but thankfully not as fiddly as "LADMDS2"!

The principle behind the patch is that you save the old trap #1 vector, and then slot in your own code into that vector. Then, when some program calls trap #1, your code can check what trap #1 call is being used, and if it's the one you want to patch, you can do your own thing, otherwise you jump to the address in the old trap #1 vector you just saved.

In this case, we're looking for the code to load `REJECT.DAT` from disk, and the code to exit the program. (Since we want to stop the music, restore the screen resolution, and then exit the program ourselves!)

Finding out the trap #1 call is a bit fiddly. The trap #1 call is an exception, so on a 68000 processor, the exception saves the return address as a longword and status register (`sr`) as a word on the stack, so the trap #1 call, followed by it's parameters, is 6 bytes behind on the stack. 

So far so good, we just go back 6 bytes on the stack to see the call, right? **NOPE**! Remember, the Atari Falcon uses a 68030 processor, and on a 68030, the exception also saves the 68030 cache register (`cacr`) as a word value on the stack, so the trap #1 call is now *8 bytes* behind on the stack! We can't just check if  we're running on a Falcon, as me might also be running on a TT, which also uses a 68030 processor, or a souped up STFM with a 68030 accelerator card, or Hatari running as an STFM with a 68030 processor, or... That's even before we get onto Ataris with 68060 processors!

So, as the issue is that we need know how many bytes back the trap #1 call is, we needed to find a way to determine that. The way we did this is to set up a *test* trap #1 handler, which we used to determine how many bytes back the trap #1 call is, and then save that to an offset variable, which we could then use in our **real** trap #1 handler.

The added complication to this is that the offset only really matters if you're in supervisor mode! If you're not in supervisor mode, you can just go to the address in the user stack pointer (`usp`), and the trap #1 command will be there! So the first thing you have to do in your trap #1 handler is do a bit of faffing around to check if you're running in supervisor mode or not, in order to determine if you need to use the offset or not!

When we first did the patch, we ran it through `MONST2` to see what trap #1 calls were being used by the demo, and what was relevant to us. We found the following:
* The demo uses an `fopen ($3d)` trap #1 call to open `REJECT.DAT` for reading.
* Next there's an `fseek ($42)` call, which we didn't expect. However, when we noticed that it moved to 2 bytes from the start of the file, it made sense, as on a Degas PI1 file, that's where the palette data is stored.
* Then there's an `fread ($3f)` call to read 4096 bytes. (4096?!?! Surely you only need 32 bytes for a colour pallette?!?!)
* Then another  `fseek ($42)` to move to 32 bytes from the start of the file. On Degas PI1 files, that's where the image data is stored.
* Then another `fread ($3f)` call to read 32000 bytes. (ie the image data)
* Then there's an `fclose ($3e)` call to close the file.
* Finally there's an `exit (0)` call to exit the program.

So, that's five calls to patch!

### The `fopen ($3d)` patch
Since we're patching `fseek`, we'll need to use our own internal file seek pointer, so we'll set it to zero here, and then all we need to do is set `d0` to a file handle as TOS does, and exit trap #1. We're doing this the quick and dirty way, as we're not checking if the filename is `REJECT.DAT`, and we're passing back the hard-coded (but common) value of `6` as the file handle!

### The `fseek ($42)` patch
Here we get the length of the seek from the stack, and set our internal file seek pointer to that value, and exit trap #1. This is even more quick and dirty than the `fopen` patch, as we're not checking the file handle, and we're assuming the seek mode is from the start of the file, even though there are different modes! (Just as well the original demo only loads one file, no?)

### The `fread ($3f)` patch
This is much less dodgy! We get the length of read and the address to read to from the stack, and then we copy from the address (With file seek offset added) of our `incbin`'d `REJECT.DAT` file to the address to read to for the length of the read, and exit trap #1.

### The `fclose ($3e)` patch
Actually, all this has to do is return the file handle in `d0`, and exit trap #1, so we just jump to the `fopen` patch!

### The `exit (0)` patch
This is the easiest patch. All we have to do is put the address of our exit code into the return address of the exception on the stack (Don't forget the offset!), and `rte`! The code will then jump to our exit code, which will stop the music, restore the screen resolution and other stuff, and exit the program.

## "Remix" version
As with "Mono Mental", we wanted to fix something with the demo. In this case, the fact that the music runs off the vbl interrupt. This was fine when the original demo was released, as 50Hz monitors were the norm on Atari systems, but nowadays, more people are running their Ataris on 60Hz monitors (Even Hatari defaults to 60Hz!), and the music runs too fast! This was quite an easy fix, as we used the same code we used in "Mono Mental" to run the music off Timer D set to a 50Hz interrupt, so now the music runs at the correct speed on all monitors! We also used UPX to pack the demo, which reduced the size of the demo from 14K to 12.3K!

**SENIOR DADS RULEC!!!**

*19 Dec 2023*