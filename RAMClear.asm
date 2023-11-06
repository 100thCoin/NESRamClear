	;;;; HEADER AND COMPILER STUFF ;;;;
	.inesprg 1  ; 2 banks
	.ineschr 1  ; 
	.inesmap 0  ; mapper 0 = NROM
	.inesmir 0  ; background mirroring

	
	;;;; ASSEMBLY CODE ;;;;
	.org $8000
	
	Reset:
	SEI	; disable interrupts
	LDA #0	; initialize the A, X, and Y registers with 0s
	LDX #0
	LDY #0
	CLD
StartupLoop1:
	LDA $2002
	BPL StartupLoop1	; stall for 2 frames so the PPU is ready to accept writes
StartupLoop2:
	LDA $2002
	BPL StartupLoop2    ; bit 7 of $2002 is set during VBlank, and cleared when read.
	; it's alive!
	
	; Let's start by setting up the color palette.
	; before we do that, let's disable rendering.
	LDA #$00	; per the NESdev wiki, these are already defaulted to 0, but better safe than sorry.
	STA $2000	; it's also important we do this *after* the two frames of stalling.
	STA $2001
	
	; the palette info is at PPU Address $3F00, 
	LDA #$3F
	STA $2006
	STY $2006 ; Y = 0
	; now the PPU ADDR is at $3F00
	
PaletteLoop:
	LDA DefaultPalette, X	; load palette color from LUT
	STA $2007				; store it in the PPU
	INX						; increment X
	CPX #32					; once X is 32, we got all the colors.
	BNE PaletteLoop			; if not X !=32, loop
	
	; wow, that palette is all set up!
	
ClearNametable:
	; Let's clear the nametable.	
	LDA $2002	; Reading $2002 resets the address latch.

	; change the PPU Address again
	LDA #$20
	STA $2006
	STY $2006 ; Y = 0
	; PPU ADDR is at $2000, the 1st nametable.

	LDX #$C0 ; 0x10C0 tiles
	LDY #$10 ; 
	LDA #$FF ; tile FF is an empty square.This also will set the palette info to pallete 3 for every tile.
NametableLoop:
	STA $2007			; store the empty tile on the nametable.
	DEX 				; decrement x
	BNE NametableLoop 	; if X is not zero, loop
	DEY					; decrement y
	BNE NametableLoop	; if y is not zero, loop
	
	; both X and Y are zero, so the loop is done.
	
	; okay, the entire background is a blank canvas now.
	
	; Clear RAM

	LDX #0	; initialize the A, X, and Y registers.
	LDY #0
	LDA #0

RAMClearLoop:	; The goal of this loop is to set up the consoles RAM to FCEUX's default pattern				
	STA <$0,X	; Store A (either 00 or FF) at address $0 with offset X
	STA $100,X	; since X will increment through all of 0 to 256, this gets every byte.
	STA $200,X  ; the pattern used by FCEUX is:
	STA $300,X	; 00 00 00 00 FF FF FF FF
	STA $400,X	
	STA $500,X	; RAM is only from address $0000 to $07FF
	STA $600,X	; Work RAM ($6000 to $7FFF) is handeled by mapper chips on cartridges
	STA $700,X	; so clearing WRAM wouldn't really achieve anything here.
		
	INX					; Increment X
	CPX #0				; if X overflows, we've cleared everything.
	BEQ ExitRAMClearLoop; exits the loop if X is zero.
	INY					; Y is used to count every 4 bytes to swap between writing 00s and FFs
	CPY #4				; if Y is not 4, go to the top of the loop
	BNE RAMClearLoop	; if Y is 4, flip the bits in A, and reset Y.
	EOR #$FF			; flips the bits in the A register from all 0s to all 1s.
	LDY #0				; reset Y
	BEQ RAMClearLoop 	; always branch back ot the top of the loop.

ExitRAMClearLoop:
	
	; alright, all RAM is cleared
	
	; Let's draw "RAM CLEARED!"

	LDA #$21
	STA $2006
	LDA #$CA
	STA $2006
	
	; PPU ADDR is at $21CA, the middle of the 1st nametable.

PrintMSG_StartLoop:	; loop over the Look Up Table
	LDA MSG_Start, X; Grab the character
	STA $2007		; Store it
	INX				; Increment X
	CPX #12			; Do it until X = 12, the length of the message
	BNE PrintMSG_StartLoop
	
	; let's print the word pattern
	
	LDA #$22
	STA $2006
	LDA #$0C
	STA $2006 ; PPU Address is set to $220C
	
	LDX #0

PrintMSG_PatternLoop: ; Loop over the LUT
	LDA MSG_Pattern, X; Load
	STA $2007		  ; Store
	INX				  ; INX
	CPX #8			  ; Compare with 8, the length of *this* message
	BNE PrintMSG_PatternLoop
	
	; let's print the bytes from RAM
	
	LDA #$22
	STA $2006
	LDA #$44
	STA $2006	; PPU Address is set to $2244
	
	LDX #0 ; initialize X as 0 for this upcoming loop.
	
PrintBytes:		; I also wanted to show what the pattern is, but to be extra cool...
				; I decided to print the data from the bytes in RAM instead of hard-code it.
	LDA <$0, X	; load bytes from $0 to $7
	AND #$F0	; seperate the left nybble
	LSR A
	LSR A
	LSR A
	LSR A
	STA $2007	; store that on the nametable
	LDA <$0, X	; grab the same byte
	AND #$0F	; seperate the right nybble
	STA $2007	; store that on the nametable
	LDA #$24	; grab a blank tile
	STA $2007	; store the blank tile on the nametable.

	INX			; increment X
	CPX #8		; if X is 8, then we're done. otherwise, loop.
	BNE PrintBytes
	
	; everything is ready.
	
	; Let's enable rendering	
	; Set screen position / scroll
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006	; PPU Address = $2000
	STA $2005
	STA $2005	; Scroll = (0,0)
	; sets the PPU registers to enable rendering, but make sure the NMI is disabled.
	LDA #$10
	STA $2000
	LDA #$08
	STA $2001
		
	; time to add something to the top of the stack.
	; this writes JMP $1FD at address $1FD
	LDA #$4C
	STA $1fD
	LDA #$FD
	STA $1FE
	LDA #1
	STA $1FF
	
	; I'm fairly certain the NES will set these values here when powering on, but just for fun:
	LDX #$FD
	TXS    ; Set the stack pointer to $FD
	LDA #0 ; initialize the A, X, and Y registers with 0s
	LDX #0 ; this step is probably unnecessary.
	LDY #0 ; I think it adds some "closure" though. We've cleared it all.
	
InfiniteLoop;
	JMP $1FD
	; an infinite loop, as opposed to a HLT instruction.

	;; LOOK UP TABLES ;;

DefaultPalette:
	.byte $0F, $0, $10, $20
	.byte $0F, $0, $10, $20
	.byte $0F, $0, $10, $20
	.byte $0F, $0, $10, $20
	
	.byte $0F, $0, $10, $20
	.byte $0F, $0, $0, $0
	.byte $0F, $0, $0, $0
	.byte $0F, $0, $0, $0

MSG_Start: ; R A M   C L E A R E D !
	.byte $1B, $0A, $16, $24, $0C, $15, $0E, $0A, $1B, $0E, $0D, $26
	
MSG_Pattern: ; P A T T E R N :
	.byte $19, $0A, $1D, $1D, $0E, $1B, $17, $28
	
	.org $9000
UnusedInterruptVector: ; Both the IRQ and NMI point here.
	.byte $02	; HLT (this should never happen)
	
	.bank 1
	.org $BFFA	; Interrupt vectors go here:
	.word $9000 ; NMI
	.word $8000 ; Reset
	.word $9000 ; IRQ

	;;;; MORE COMPILER STUFF, ADDING THE PATTERN DATA ;;;;

	.incchr "Sprites.pcx"
	.incchr "Tiles.pcx"