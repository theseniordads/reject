* REJECT DEMO (By Reject) patched music version source by SENIOR DADS
* 
* Original demo by REJECT in GFA Basic, realeaed early 1998. 
* Patched version released by the SENIOR DADS on 23rd March 1998.
*
* The original demo required to be run in ST Low resolution, and had no music.
* This version has been patched to run in any resolution, and has music added.

* NOTE: This is not the original source code, as that is almost certainly lost.
* The source and data has been reverse engineered from the original executable,
* using a disassembler, various Atari rippers, MONST2, Steven Tattersall's HRDB,
* and Visual Studio Code along with VASM and Vlink to recreate the executable on
* modern systems. 

* As this is not the original source, you can safetly assume all comments here are new.

* ## Assembly information ##
 * Assembly format: Devpac 3 (VASM compatible)
 * Target processor: Motorola 68000, but 680x0 compatible. (Allegedly!)
 * Exectuable format: Atari TOS .TOS
 * Minimum hardware: Atari STFM with 0.5MB RAM, colour display.

FINAL_VERSION							; < Comment for labels and faster assembly

    IFD	FINAL_VERSION
	opt	d-
	ENDC

    text

	include includes/genmacro.s			; Useful general macros

code_start
    	jmp		setup
		; Little message for all the code rippers!
    	dc.b 	'Reject v1.1- extra code by Old Fart of Senior Dads! '
   	 	dc.b 	'Extra music "RASERO TEAM FUCK OUT" by Dame Vera Lynn of Senior Dads!'
    	even

set_screen:
	  	super_execute   #check_for_falcon   ; Our Faclon checking routine needs to be run in supervisior mode
        getrez_st   d7
    	cmpi	#2,d7           ; Is it running on a mono moniter?
    	bne	    .continue
    	tst.b	is_falcon       ; Is it running on a Falcon?
    	bne	    .continue
        print_string    #.cant_run_demo
        wait_key
    	clr	    -(a7)           ; As we haven't set up anything yet, we can use the normal exit routine
    	trap	#1		        ; Gemdos

.cant_run_demo:	
        dc.b    27,'E'          ; Clear screen
        dc.b    'You lamer! This requires a monitor capable of',13,10
        dc.b    'an ST LOW RESOLUTION display!!! Now piss off!!!',0
        even

.continue:	
        move	d7,old_rez              ; Save the current resolution
        getphys	old_phys
        getlog	old_log
        super_execute   #save_pallette  ; Save the current pallette, and switch off keyclick
        setrez_st   #0,#-1,#-1          ; Set resolution to ST low, with the same physical and logical screens 
    	rts

save_pallette:	
        bclr	#0,keyclick.w           ; Switch off keyclick
        movem.l	d0-d7,-(a7)
        movem.l	c16regs.w,d0-d7         ; Get all 16 colours
        movem.l	d0-d7,old_pallette      ; ... and save them
        movem.l	(a7)+,d0-d7
        rts

restore:
        setrez_st       old_rez,old_phys,old_log
        super_execute   #restore_pallette
    	rts

restore_pallette:
    	bset	#0,keyclick.w           ; Switch keyclick back on
	    movem.l	d0-d7,-(a7)
    	movem.l	old_pallette,d0-d7      ; Restore the old 16 colour pallette
    	movem.l	d0-d7,c16regs.w
    	movem.l	(a7)+,d0-d7
    	rts

* CHECK FOR IF WE'RE RUNNING ON A FALCON:
; The reason we do this check is that this demo can run a Falcon, but someone might be running the desktop
; in a mono compatible mode, and we only want to test for a mono monitor, not a mono compatible mode!
check_for_falcon:
    	sf	is_falcon
    	move.l	#'_MCH',d0      ; We're looking for the machine type cookie
    	bsr	    get_cookie
    	tst.l	d0              ; If there's no cookie jar, exit
    	beq.s	.exit
    	cmpi.l	#'NULL',d0      ; If we've reached the end of the cookie jar without a result, exit
    	beq.s	.exit
    	swap	d0              ; The machine type is in the high word of the cookie, so we swap it to the low word
    	cmpi.l	#3,d0           ; If the machine type is 3, it's a Falcon,
    	bne.s	.exit           ; ... otherwise exit
    	st	is_falcon           ; Now we're sure, we set the is_falcon flag
.exit:	rts

* Get cookie jar value for cookie string in d0
get_cookie:	
            move.l	cookie_jar.w,d1         ; Get the address of the cookie jar
            tst	d1                          ; If there's no address...
            beq.s	.exit                   ; ... there's no cookie jar, so we exit
            movea.l	d1,a0
.next       move.l	(a0)+,d1
            cmpi.l	#'NULL',d1              ; If we've reached the end of the cookie jar, exit
            beq.s	.exit
            tst.l	d1                      ; Unofficial cookie jar end- also exit.
            beq.s	.exit
            cmp.l	d0,d1                   ; If we've found the cookie we're looking for...
            beq.s	.found
            addq.l	#4,a0                   ; If not, go to the next cookie
            bra.s	.next
.found:     move.l	(a0)+,d0                ; If we've found the cookie, get it's value
            bra.s	.found2
.exit:	    move.l	d1,d0
.found2:    rts
is_falcon:	ds.b	1
    even

; For some reason this code was including in the original demo, but never used! =====================

* Wait for a number of VBLs specified in d0
wait_for:	
        bsr.s	wait_vbl
    	dbf	d0,wait_for
    	rts

* Wait a single VBL
wait_vbl:
    	move	timer.w,d1
.wait:	cmp	    timer.w,d1
    	beq.s	.wait
    	rts

; ===================================================================================================

* RELOCATE TOS BINARY:
; We've included the original demo as a binary include in this source code, so we don't need to load it 
; from the disk. However in order to run it, we need to do the same thing the TOS loader does, which is
; to relocate the program in memory. This is done by reading the relocation table at the end of the program
; "file", and updating the addresses in the program code with the correct addresses for where the program 
; is in memory.
;
; a6 = the address of the program. (This assumes we're wanting the program to be relocated to the same
; 	address it was stored at.)
relocate:	
        movem.l	d0-d7/a0-a6,-(a7)
    	movea.l	a6,a0						; Get the start address of the program
    	move.l	tos_header_text(a0),d0  	; Add the length of the text section
    	add.l	tos_header_data(a0),d0		; Add the length of the data section (We don't need to add the length of the bss section, as it's not stored in the file)
    	add.l	tos_header_symbol(a0),d0    ; Add length of symbol table. d0 now points to the relative position of the relocation table
    	adda.l	#tos_code_start,a0          ; Add the length of the program header, and a0 now points to the start of the program code (text section)
    	movea.l	a0,a1
    	movea.l	a1,a2
    	move.l	a6,d1
    	addi.l	#tos_code_start,d1
    	adda.l	d0,a1               ; a1 now contains the address of the relocation table
    	move.l	(a1)+,d0            ; Get the relative address we want to relocate
    	adda.l	d0,a2               ; a2 now contains the absolute address we want to relocate
    	add.l	d1,(a2)             ; Relocate the address  
    	clr.l	d0                  ; We need to clear this, as we're doing a byte compare next
.next:	move.b	(a1)+,d0            ; Get next byte from table
    	beq.s	.end                ; If the value is zero, we're at the end of the relcoation table
    	cmp.b	#1,d0               ; If the value is 1, ...
    	beq.s	.jump               ; ... the next address to relocate is at least 254 bytes away, so add 254 byte to the address
    	adda.l	d0,a2               ; Otherwise, add the value to the current address to get our next address to relocate
    	add.l	d1,(a2)             ; Relocate the address
    	bra.s	.next               ; Go to the next byte in the relocation table
.jump:	adda.l	#254,a2
    	bra.s	.next
.end:	movem.l	(a7)+,d0-d7/a0-a6
    	rts

* Here we save the old screen pallette, resolution, and stack pointer, so we can restore them when the demo exits
old_pallette:	ds.w    16			; Save all colour pallette registers, after all we may be coming in from ST lo-rez
old_rez:	    ds.w    1			; Old resolution
old_phys:	    ds.l    1			; Old physical screen address
old_log:	    ds.l    1			; Old logical screen address

; ===================================================================================================

* MAIN SETUP AND EXIT ROUTINE:
; Why this is in this part of the code- we don't know!
;
; You may have noticed a a few uses of 'super_execute' in this code. This is because we don't want to
; run the original demo in supervisor mode!
setup:	move.l	4(a7),d0        ; First, work out where we are in memory via the return address that's on the stack
        movea.l	d0,a0
        move.l	#end,d1         ; Now we get where the end of the program is in memory
        sub.l	d0,d1           ; ... and use that to get the length of the program
    	move.l	d1,-(a7)        ; Now we've got that we can use Trap #1 Mshrink to protect the memory
    	pea	    (a0)            ; ... from the rest of the system!
    	clr	    -(a7)
        move	#$4a,-(a7)	    ; Mshrink
        trap	#1		        ; Gemdos
        lea	    12(a7),a7
	    tst.l	d0              ; Success?
        bne.s	exit_program    ; No, so we quit

	    move.l	a7,old_stack    ; Save the old stack, since we're going to use our own one!
        jsr	    set_screen

        super_execute   #set_trap_one		; Set up our own Trap #1 handler
        super_execute	#set_screen_music	; Set up the music

    	lea	    main_prog,a6                ; The program is included in this binary, ...
    	bsr	    relocate                    ; ... so now we relocate it
		bsr 	patch
    	lea	    code_start-256,a0
        jmp	    32(a6)                      ; Jump to the start of the original program
exit_demo:
        super_execute	#stop_music			; Stop the music
    	super_execute	#restore_trap_one	; Restore the original TOS Trap #1
    	jsr		restore
    	movea.l	old_stack,a7
exit_program:
    	clr	    -(a7)
    	trap	#1		     ; Gemdos

* PATCH THE ORIGINAL PROGRAM:
; This is a new bit we had to do as we found that the original demo caused a bus error at a certain point.
; We don't know why this didn't happen on our original patch, but on this version, the GFA code, which
; appears to do a test for whether to turn the mouse pointer on or off, checks for a variable in an impossible
; memory location, which causes a bus error. We've patched this so that the check is skipped.
patch:	stack_save	a0/a1
		lea 	main_prog,a0			; We're only checking between the start of the program and the end (approx 9K)
		lea 	end,a1
.loop   cmp.l  a0,a1
		ble.s   .exit
		cmpi.l	#$4a6afdaa,(a0)			; This is the code that causes the bus error. 'tst.w -256(a2)'
		bne.s   .next
		move.l	#$4a404e71,(a0)			; We're replacing it with 'tst.w d0' followed by 'NOP'
		bra.s	.exit
.next   adda.l	#2,a0					; If we can't find the code, we go to the next word
		bra.s	.loop
.exit	stack_restore  a0/a1
		rts

old_stack:	ds.l    1					; Old stack pointer. Dunno why this is here in the code!

set_screen_music:
    	moveq	#0,d0                   ; <- Why?!?!?!?!??!! It doesn't do anything!
    	jsr     music					; Initialise the music
    	move.l	vbl.w,old_vbl			; We're playing music on the vertical blank interrupt, so we need to save the old one
    	move.l	#music_vbl,vbl.w
    	rts

* MUSIC ROUTINE:
; This just plays the music, and then jumps back to the original VBL routine. (As GFA basic might be using it)
music_vbl:
    	movem.l	d0-d7/a0-a6,-(a7)
    	jsr		music+8
    	movem.l	(a7)+,d0-d7/a0-a6
goto_old_vbl
    	jmp		0.l					; Jump to the original VBL routine
old_vbl equ goto_old_vbl+2			; <- What do you mean "Yikes!!!"?!?! Have you never seen self-modifying code before?

stop_music:	
        move.l	old_vbl,vbl.w
	    jsr		music+4
    	rts

; ===================================================================================================

* TRAP #1 HANDLER:
; This is the most important part of the patch, as it handles a couple of things:
; * The demo ends with a Trap #1 exit, so we intercept that and restore the resolution, pallette, and stop
;   the music so we can exit cleanly.
; * The original demo reads a Degas PI1 file (REJECT.DAT in the original demo), which we've included as a
;   binary in this source, so we intercept the file open, read, close, and seek commands, and use it to
;   copy the data from the binary include.
trap_one	equ	$84
bus_error   equ $8

* SET UP TRAP #1 HANDLER:
; You might think this part is easy- just set up a new Trap #1 handler, and we're done. BUT remember we're
; checking for the trap #1 call being used. The trap #1 call is an exception, so on a 68000 processor, the 
; exception saves the return address as a longword and status register (sr) as a word on the stack, so the 
; trap #1 call is 6 bytes behind on the stack. 
;
; So far so good, we just go back 6 bytes on the stack to see the call, right? NOPE! Remember, the Atari 
; Falcon uses a 68030 processor, and on a 68030, the exception also saves the 68030 cache register (cacr) as 
; a word value on the stack, so the trap #1 call is now *8 bytes* behind on the stack! We can't just check if 
; we're running on a Falcon, as me might also be running on a TT, which also uses a 68030 processor,
; or a souped up STFM with a 68030 accelerator card, or Hatari running as an STFM with a 68030 processor, 
; or... That's even before we get onto Ataris with 68060 processors!
;
; So, as the issue is that we need know how many bytes back the trap #1 call is, we need to find a way to
; determine that. The way we do this is to set up a test trap #1 handler, which we can use to determine how
; many bytes back the trap #1 call is, and then save that to an offset variable, which we can then use in
; our REAL trap #1 handler.
set_trap_one:	
        move.l	trap_one.w,old_trap_one					; Save the old trap #1 handler
    	move.l	#test_trap_one,trap_one.w				; Set up our test trap #1 handler
    	move.l	a7,d0									; Put the address of the current stack pointer in d0
    	trap	#1										; Our test trap #1 handler will reduce d0 by the address of the current stack pointer whilst inside the exception
    	subq.l	#4,d0									; Remove the return address from the offset on d0
    	move.w	d0,address_offset						; Save the offset
    	move.l	#new_trap_one,trap_one.w				; Now we set up our real trap #1 handler
    	move	#7,d0									; {
    	lea	    bus_error.w,a0							; { - Errr, not sure why, but we're saving the
    	lea	    old_exceptions,a1						; {   old exception handlers here!
.save	move.l	(a0),(a1)+								; {
    	addq.l	#4,a0									; {
    	dbf	d0,.save									; {
    	rts

* TEST TRAP #1 HANDLER:
; Pretty easy this one- we just reduce d0 by the address of the current stack pointer, and then return.
; Remember d0 has been set to the address of the current stack pointer *before* calling the exception,
; so by reducing d0 by the address of the current stack pointer *within* the exception, we can determine
; how much the stack has moved since calling the exception.
test_trap_one:
    	sub.l	a7,d0
    	rte

* RESTORE TRAP #1 HANDLER:
; Pretty easy, just restore the old trap #1 handler, and the old exception handlers.
restore_trap_one:
    	move.l	old_trap_one,trap_one.w
    	move	#7,d0
    	lea	    bus_error.w,a0
    	lea	    old_exceptions,a1
.restore:
    	move.l	(a1)+,(a0)+
    	dbf	    d0,.restore
    	rts

* NEW TRAP #1 HANDLER:
; Here's what's relevant in our new trap #1 handler in relation to the original demo:
; * The demo opens 'REJECT.DAT' (which we've included as a binary in this source) to read the data from.
;   This a cunningly disguised Degas Elite PI1 file.
; * There's a file seek of 2 bytes at the start of the file, so that the reader is now pointing at the 
;   colour pallette data.
; * 4096 bytes are read (4096?!?! Surely you only need 32 bytes for a colour pallette?!?!) from the file.
; * Another file seek- this time the reader is now 34 bytes from the start of the file, so it's pointing
;   at the start of the bitmap data.
; * 32000 bytes are read from the file. (This is the size of the bitmap data.)
; * The file is closed.
; * The demo exits.
program_exit 		equ 0
program_terminate   equ $4c
file_open           equ $3d
file_read           equ $3f
file_close          equ $3e
file_seek           equ $42

* Main trap #1 handler:
; You may notice there's a bit a strange one here, as we're doing a test to see if the trap #1 is being called 
; from supervisor mode. If it's not, we can use the user stack pointer, and we don't have to faff about with
; offsets for the return address and interrupt information!
new_trap_one:	
        movem.l	d0-d7/a0-a6,saved_registers		; Make sure we save all registers
        movea.l	a7,a0
	    movea.l	a0,a1					; <- Why?!?!?!?!??!! We don't use a1 anywhere else in this routine!
	    move	address_offset,d0		; Get the address offset ready...
    	btst	#5,(a7)                 ; Check if we're in supervisor mode
    	bne.s	.supervisor
    	move	usp,a0                  ; ... if not, use the user stack pointer
	    bra.s	.check_command
.supervisor:
    	addq.l	#4,a0                   ; if we're in supervisor mode, the stack contains the return address, so we skip past that
    	adda	d0,a0                   ; ... as well as the interrupt information
.check_command:                         ; Here we check the commands that have been sent to us
    	cmpi.w	#program_exit,(a0)      ; When the original demo exit
    	beq.s	demo_has_ended
    	cmpi	#program_terminate,(a0) ; Alternative program exit
    	beq.s	demo_has_ended
    	cmpi	#file_open,(a0)         ; For when the original demo opens the data file
    	beq.s	open_data_file
    	cmpi	#file_read,(a0)         ; For when the original demo reads the data file
    	beq.s	read_data_file
    	cmpi	#file_close,(a0)        ; For when the original demo closes the data file
    	beq.s	open_data_file
    	cmpi	#file_seek,(a0)         ; For when the original demo does a file seek in the data file
    	beq.s	data_file_seek
    	movem.l	saved_registers,d0-d7/a0-a6     ; if none of these, we execute the original Trap #1 code.
go_to_original_trap_one:	
        jmp		0.l
old_trap_one  equ go_to_original_trap_one+2		; "Yikes!!!" etc...

* DEMO HAS ENDED:
; Simple, we just put the address of our cleanup routine in the return address, and then exit the exception.
demo_has_ended:	
        move.l	#exit_demo,(a7,d0.w)	; d0 contains the offset we add to the stack to find out where to put the return address
        rte

* OPEN DATA FILE:
; We're using this to open the data file, and then close it again. We don't need to pay attention to the 
; parameters passed to the original Trap #1 call, as we're not using them. All we need to do is pass back 
; a file handle in d0, and clear the file seek offset.
open_data_file:	
        movem.l	saved_registers,d0-d7/a0-a6
	    move	#6,d0							; Why 6 as a file handle? Dunno, but it works!
        clr.l	data_file_offset				; Clear the file seek offset
        rte

* DATA FILE SEEK:
; We use one of the parameters passed to the original Trap #1 call to get the file seek offset.
; This is probably the dodgiest bit of code in this whole patch, as we're assuming that the offset is
; from the start of the file- there are two other options, which are from the current seek position, or 
; from the end of the file. However the original demo uses "start of file", so it still works.
data_file_seek:	
        move.l	2(a0),data_file_offset
        movem.l	saved_registers,d0-d7/a0-a6
    	rte

* READ DATA FILE:
; Relatively easy, as we're passed the length of data to read, and the address to copy it to.
; All we have to do is take into account any file seek offsets, and all we then have to do is
; copy the data from the binary
read_data_file:	
        movea.l	8(a0),a1                        ; Address to copy data to
    	move.l	4(a0),d0                        ; Length of data to copy
    	move.l	d0,d7                           ; Save this, as we need to pass the file length to the code that called it
    	subq.l	#1,d0                           ; Modify the value, so we can it in a loop
        lea		data_file,a0
        adda.l	data_file_offset,a0             ; If there's been a seek on the file, add the offset
.copy:	move.b	(a0)+,(a1)+
    	dbf	d0,.copy
    	move.l	d7,d0                           ; <- Should really used d7 for the loop, then we wouldn't need to do this as the value is meant to be passed back in d0!
    	movem.l	saved_registers+4,d1-d7/a0-a6
        rte

address_offset:     ds.l    1					; Trap #1 call address offset
data_file_offset:	ds.l    1					; File seek offset
saved_registers:    ds.l    16					; Saved registers for new trap #1 handler
old_exceptions:     ds.l    8					; Old exception handlers
	even

music:	    incbin music/rasero.thk				; "Rasero Team Fuck Out" by Dame Vera Lynn of the Senior Dads
    even
data_file:  incbin reject.old/reject.dat		; "Reject" demo logo. (PI1 file)
    even
main_prog:  incbin reject.old/reject.prg		; Original "Reject" demo binary.
    even

end:	end	
