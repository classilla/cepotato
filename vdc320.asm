// vim: set syntax=off:

/*

   VDC "live" camera for the ComputerEyes for the Commodore 128
   runs in 64 mode
   requires a VDC-capable monitor like the 1902 and a ComputerEyes.

   (c)2023 Cameron Kaiser. all rights reserved. BSD license.
   note that this code requires the ComputerEyes driver, which is (c)1984
   digital vision, inc. and/or its successor companies.
   https://oldvcr.blogspot.com/

*/


/* define FAST for fast-n-loose 5 second capture covering 88% of the screen
   otherwise 7 seconds */

zp	= 253

	.word $0801
	*=$0801

; basic loader

	.word $080b
	.word $fce2
	.byte $9e, $32, $30, $36, $31
	.byte $00, $00, $00

	jmp entry

	.asc $0d, $0a, "http://oldvcr.blogspot.com/", $0d, $0a

	; vdc initialization bytes (NTSC)
vdcri	.byt $7e,$50,$66,$49,$20,$e0,$19,$1d
	/* PAL:              ^^^- $27    ^^^- $20 */
	.byt $fc,$e7,$e0,$f0,$00,$00,$20,$00
	.byt $ff,$ff,$00,$00,$08,$00,$78,$e8
	.byt $20,$ff,$f0,$00,$2f,$e7,$ff,$ff
	.byt $ff,$ff,$7d,$64,$f5

	; workspace for the all important register 25
vdc25	.byt 0
	; shot#
shotz	.byt 0

	; generic read or write to a VDC register
vdcrm	ldx #$1f	; enter here for memory
vdcrw	stx $d600	; enter here for other registers in X
	bit $d600
	bpl *-3		; wait for ready
vdcop	sta $d601	; change opcode to $ad=read $8d=store
	rts

; calls into the standard cedriver
/*
 jmp nacq ;normal acquire
 jmp four ;4-level acquisition
 jmp syncer ;sync adjust routine
 jmp initb ;hi-res initialization
 jmp color ;init color memory
 jmp eight ;8-level acquisition
 jmp pacq ;pre-set threshold acquire
 jmp pack ;image pack routine
 jmp unpack ;image unpack routine
 jmp saver ;image save
 jmp bright ;brightness adjust
 jmp fore ;text screen foreground
*/
ced=$c000
nacq=ced
four=ced+3
syncer=ced+6
initb=ced+9
color=ced+12
eight=ced+15
pacq=ced+18
pack=ced+21
unpack=ced+24
saver=ced+27
bright=ced+30
fore=ced+33

; unofficial entry points
acq=$c0c9
clp=$c0e8
ilp=$c0f1
thresh=$cff0
dcompv=$cff1

; kernal
setlfs = $ffba
setnam = $ffbd
open = $ffc0
close = $ffc3
chkout = $ffc9
clrchn = $ffcc
print = $ffd2
clall = $ffe7

entry
	; set up screen
	lda #27
	sta 53265
	lda #21
	sta 53272
	lda #0
	sta 53280
	sta 53281
	lda #147
	jsr $ffd2
	jsr fore
	
	; call cedriver sync manual calibration routine
	lda #0
	sta 198
	jsr syncer
	; call cedriver brightness manual calibration routine
	lda #0
	sta 198
	jsr bright

	;
	; switch to vdc acquire
	;

	lda #11
	sta 53265
	lda #2
	sta 53280

	; default initialize vdc
	ldy #$47	; handle version 0 VDC (early 128s)
	lda $d600
	and #$03
	bne *+4
	ldy #$40	; old vdc use value 40, new vdc use value 47
	tya
	ldx #25
	sta vdc25
	jsr vdcrw

	; load default NTSC values, skipping $ffs
	ldx #0
vloop	lda vdcri,x
	cmp #$ff
	beq *+5
	jsr vdcrw
	inx
	cpx #37
	bcc vloop

	; 8568 has an extra register 37 for hsync/vsync (ignored on 8563)
	; set both hsync (7) and vsync (6) bits for positive polarity
	; since most people will use a Commodore 1902 monitor or similar
	lda #255
	jsr vdcrw

	; patch for PAL
	lda 678
	beq vnotpal
	ldx #4
	lda #$27
	jsr vdcrw
	ldx #7
	lda #$20
	jsr vdcrw
vnotpal

	; force VDC 320x200 mode
	; do this in this weird order since it works on both
	; VICE and a real NTSC 128DCR
	ldx #25
	lda vdc25
	ora #128
	jsr vdcrw		; hires on

	ldx #0
	lda #63
	jsr vdcrw		; 64 clock cycles per rasterline

	ldx #1
	lda #40
	jsr vdcrw		; 40 visible character columns displayed

	ldx #25
	lda vdc25
	ora #144
	and #191
	jsr vdcrw		; hires + double pixel clock both on,
				; attributes off

	ldx #22
	lda #$89
	jsr vdcrw		; character width to 9

	ldx #27
	lda #1
	jsr vdcrw		; insert "wait byte" between rows to remove
				; dot noise on right edge

	ldx #2			
	lda #53
	jsr vdcrw		; hsync pos to 53, was best on tested screens

caplup	sei
	lda #1
	sta 53296

	; copy VIC 320x200 screen to VDC memory
	; attempt to do as much as we can with VDC autoincrement
	ldx #18
	lda #0
	jsr vdcrw
	ldx #19
	lda #0
	jsr vdcrw
	lda #31
	sta $d600		; set up for memory blast

	lda #0
	sta zp
	lda #32
	sta zp+1

	; strategy. copy 25 sections of 320x8 pixels, reorganizing it
	; to VDC linear memory
	lda #25
	sta $02			; section count

	; copy 320x8 segment
loop42	ldy #0
	; do 40 horizontal 8x1 cells to equal 320 horizontal pixels
loop41	ldx #0
loop40	lda (zp),y
#ifdef FAST
	; mask first 34 pixel columns
	cpx #6
	bcs loopok
	bcc loopbl
	and #$3f
	jmp loopok
loopbl	lda #0
loopok
#endif
	bit $d600
	bpl *-3
	sta $d601
	lda zp
	clc
	adc #8
	sta zp
	lda zp+1
	adc #0
	sta zp+1
	inx
	cpx #40
	bcc loop40
	; insert dummy byte between scan lines
	lda #0
	bit $d600
	bpl *-3
	sta $d601
	; do eight scan lines
	iny
	cpy #8
	bcs lupska
	; and take back one kadam to honor Bil Herd, whose Ark this is
	lda zp
	sec
	sbc #64
	sta zp
	lda zp+1
	sbc #1
	sta zp+1
	jmp loop41

	; and do it 25 times
lupska	dec $02
	bne loop42

	; now get next frame from digitizer
#ifdef FAST
	; don't do all the initialization nacq does; do abbreviated work
	; and call into the acquire routine directly
	ldx #$0b		; "swap"
swapl0	lda $03,x
	sta zps,x
	dex
	bpl swapl0

	lda #0
	sta 198

	; set defaults and capture
	sta 2			; xoff
	sta 3
	lda #7			; "init" (no need for "color")
	sta thresh
	lda #9
	sta dcompv
	lda #128
	sta 6			; bitpos
	; turn on CE
	lda #252
	sta 53296
	lda #$3f
	sta $dd03
	lda thresh
	ora #8
	sta $dd01
	ldx #0
	jsr clp+5		; jump into routine at vsync check

	ldx #$0b		; "swap"
swapl1	lda zps,x
	sta $03,x
	dex
	bpl swapl1
	cli
#else
	lda #252
	sta 53296
	lda #0
	sta 198
	jsr nacq
#endif

	; check shift lock and C= key
friz	lda 653
	and #2
	bne savevdc
	lda 653
	sta 53280
	bne friz
	
	jmp caplup

	;
	; save VDC memory as a PBM (because it's basically organized that way)
	;

savevdc	; get next file
	lda shotz
	clc
	adc #48
	sta scrtchn
	sta writen

	; use default drive or 8
	ldx #8
	lda 186
	cmp #8
	bcs *+4
	stx 186

	; scratch any existing file
	lda #15
	ldx 186
	tay
	jsr setlfs
	lda #(writen-scrtch)
	ldx #<scrtch
	ldy #>scrtch
	jsr setnam
	jsr open
	jsr clall

	; create new image dump
	lda #1
	ldx 186
	ldy #2
	jsr setlfs
	lda #(pbmh-writen)
	ldx #<writen
	ldy #>writen
	jsr setnam
	jsr open
	ldx #1
	jsr chkout

	; write PBM header
	ldy #0
savepbh	lda pbmh,y
	jsr $ffd2
	iny
	cpy #11
	bcc savepbh

	; write VDC bytes to disk, skipping the dummy bytes
	; do 40 bytes per line, do 200 lines
	lda #200
	sta $02			; line counter

	ldx #18
	lda #0
	jsr vdcrw
	ldx #19
	lda #0
	jsr vdcrw
	lda #31
	sta $d600		; set up for memory suck

saverow	ldy #40
savelup	bit $d600
	bpl *-3
	lda $d601
	; invert for PBM
	eor #255
	jsr $ffd2
	dey
	bne savelup
	; discard dummy
	bit $d600
	bpl *-3
	lda $d601
	dec $02
	bne saverow

	; don't clall
	jsr clrchn
	lda #1
	jsr close

	; only 10 allowed, 0-9
	inc shotz
	lda shotz
	cmp #10
	bne savedbn
	lda #0
	sta shotz

	; debounce C= key
savedbn	lda 653
	and #2
	bne savedbn
	; back to freeze
	jmp friz

	; needs -O PETSCII
scrtchn = *+3
scrtch	.asc "s0:-vdcgrab.pbm"
writen	.asc "-vdcgrab.pbm,p,w"

	; PBM P4 320 200 header
;              1   2   3   4   5   6   7   8   9  10  11
pbmh	.byt $50,$34,$0a,$33,$32,$30,$20,$32,$30,$30,$0a
	; temp storage for cedriver's zp usage
;              3   4   5   6   7   8   9   a   b   c   d   e
zps	.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
