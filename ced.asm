// vim: set syntax=off:
 ; ast 55
;
;            ******** cedriver ********
;
;     driver for computereyes video interface
;               commodore-64 version
;                   revision 1.1
;
;                copyright 1984 by
;               digital vision, inc.
;             14 oak street - suite 2
;                needham, ma 02192
;
;               all rights reserved
;
;   revision history:
;     1.0    9/84  original
;     1.1   11/84  compensation for older c-64
;                  clr/home kernal routine
;
; ast 55
;
dirreg=$dd03
cereg=$dd01
bitpos=$06
ptr=$fb
ptra=$fd
nvert=76
thresh=$cff0
dcompv=$cff1 ;delay compensation reg
dcomp=9 ;delay compensation value
xoff=$02
temp=$04
ndx=198 ;# chrs in keyboard que
vicscn=$400 ;screen memory
msgst=$7c9 ;screen loc of start of message
vcr=$d011 ;vic control reg (=53265)
vmcr=$d018 ;vic mem ctrl reg (=53272)
scnkey=$ff9f ;kernal keyboard scan
getin=$ffe4 ;kernal get character
tbuf=$cfe0 ;swap buffer for pack/unpack
ctr=6
bitctr=8 ;bit counter for pack
data=9 ;data reg for pack
save=$ffd8
; page
;
 .word $c000
 *=$c000
;
; jump table
;
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
;
; ast 55
;
; wait subroutine
;
wait sec
wal1 pha
wal2 sbc #1
 bne wal2
 pla
 sbc #1
 bne wal1
 rts
;
; ast 55
;
; initialization subroutine
;
init and vcr ;conditionally blank screen
 sta vcr
;
initb lda vmcr ;put bit map @ loc $2000
 ora #$08
 sta vmcr
;
 lda vcr ;enter bit map mode
 ora #$20
 sta vcr
;
inita lda #$3f ;set data direction reg to
 sta dirreg ;  00111111 (1 = output)
;
 sei  ;disable interrupts
;
 jsr swap ;free up zpage locs
 rts
;
; page
; ast 55
;
; clear hi-res background/foreground colors
;
color lda #0
 sta ptr ;ptr = start of text memory
 lda #$04
 sta ptr+1
 ldy #0
collp1 lda #$10
collp2 sta (ptr),y
 inc ptr
 bne collp2
 inc ptr+1
 lda ptr+1
 cmp #$08
 bne collp1
 rts
;
; test for keypress
;
kbtest jsr scnkey ;scan keyboard
 lda ndx ;a = # chrs in kbd que
 rts
;
; ast 55
;
; memory swap routine for pack/unpack
;
swap ldx #$0c ;swap locs 2 thru $0e
swaplp lda $02,x ;store on stack
 pha
 lda tbuf,x ;move from tbuf to zpage
 sta $02,x
 pla
 sta tbuf,x ;store zpage in tbuf
 dex  ;next loc
 bpl swaplp
;
 rts  ;done
;
; page
; ast 55
;
; brightness adjust routine
;
bright lda #7 ;thresh = 7
 sta thresh
 lda #$ff ;leave scrn unblanked
 jsr init ;init things
 jsr color ;scrn colors
 lda #dcomp ;delay comp
 sta dcompv
bloop lda #$ff ;wait for c/e to settle
 jsr wait
 jsr acq ;acquire
 jsr kbtest ;test for keypress
 beq bloop ;loop if not
;
 jsr swap
 cli
 rts
; page
; ast 55
;
; normal acquisition
;
nacq lda #7 ;level = 7
 sta thresh
pacq lda #$ef ;blank screen
 jsr init ;initialize things
 jsr color ;init screen color
 lda #dcomp ;set delay comp value
 sta dcompv
 jsr acq ;acquire
;
pfini lda #$10 ;unblamk screen
 ora vcr
 sta vcr
 jsr swap ;restore zpage locs
 cli  ;enable interrupts
 rts
;
; ast 55
;
;         main acquisition subroutine
;
; the timing of these loops is very critical.
; do not modify, or at least be very careful!
;
acq lda thresh ;set threshold and start
 ora #$08 ;  video interface
 sta cereg
;
 lda #0 ;init x offset register
 sta xoff
 sta xoff+1
;
; wait nvert vert syncs before beginning acquisition
;
 lda #nvert ;delay compensation for
 clc  ;  first scan
 adc dcompv
 tay
wvlp jsr wvert ;call wait-for-vert routine
 dey
 bne wvlp ;do this nvert times
;
; now begin acquiring - init bit position location
;
mlp lda #$80 ;bit 7 is left-most bit on screen
 sta bitpos
;
; acquire one column - wait for vsync plus some hsyncs
;
clp jsr kbtest ;test for keypress
 bne adone ;abort if so
 jsr wvert
 clc
; page
;
; the inner loop - get data and save
;
ilp lda tablo,x ;get hi-res ptr from table
 adc xoff ;add x offset
 sta ptr
 lda tabhi,x
 beq wnxt ;if 0, done with column
 adc xoff+1
 sta ptr+1
;
whlp1 bit cereg ;wait for hor sync
 bmi whlp1
;
 bvc aov0 ;test video data
;
 lda bitpos ;data = 1, set bit
 ora (ptr),y ;
 bcc ov0
;
aov0 lda bitpos ;data = 0, clear bit
 eor #$ff ;complement
 and (ptr),y ;mask off bit to clear
;
ov0 sta (ptr),y ;restore
 inx  ;next row
 bne ilp ;goto top of inner loop
;
; column done - update bit position, check for last column
;
wnxt lsr bitpos ;shift bit right
 bne clp ;next column if not shifted out
;
 clc  ;next set of 8 columns
 lda xoff ;add 8 to x offset
 adc #8
 sta xoff
 lda xoff+1
 adc #0
 sta xoff+1
;
 cmp #$01 ;test for last column
 bne mlp ;goto main loop if not
 lda xoff
 cmp #$40
 bne mlp
;
adone lda thresh ;disable interface
 sta cereg
 rts  ;done
;
; page
;
;              subroutine wvert
; wait for vert sync plus time delay
;
wvert lda #0 ;init sync interval ctr
 sta ptra
;
wvlp1 lda cereg ;wait for start of sync
 bmi wvlp1
;
 ldx #2 ;wait 18 usec
wvlp2 dex
 bne wvlp2
;
 lda cereg ;sync still here?
 bmi wvlp1 ;if no, try again
;
 lda #25 ;wait 1.9 msec
 jsr wait
;
 rts  ;done
; page
;
; tables used to convert "y" hires coordinate to address
;
tabhi .byt $20,$20,$20,$20,$20,$20,$20,$20
 .byt $21,$21,$21,$21,$21,$21,$21,$21
 .byt $22,$22,$22,$22,$22,$22,$22,$22
 .byt $23,$23,$23,$23,$23,$23,$23,$23
 .byt $25,$25,$25,$25,$25,$25,$25,$25
 .byt $26,$26,$26,$26,$26,$26,$26,$26
 .byt $27,$27,$27,$27,$27,$27,$27,$27
 .byt $28,$28,$28,$28,$28,$28,$28,$28
 .byt $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
 .byt $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b
 .byt $2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c
 .byt $2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d
 .byt $2f,$2f,$2f,$2f,$2f,$2f,$2f,$2f
 .byt $30,$30,$30,$30,$30,$30,$30,$30
 .byt $31,$31,$31,$31,$31,$31,$31,$31
 .byt $32,$32,$32,$32,$32,$32,$32,$32
 .byt $34,$34,$34,$34,$34,$34,$34,$34
 .byt $35,$35,$35,$35,$35,$35,$35,$35
 .byt $36,$36,$36,$36,$36,$36,$36,$36
 .byt $37,$37,$37,$37,$37,$37,$37,$37
 .byt $39,$39,$39,$39,$39,$39,$39,$39
 .byt $3a,$3a,$3a,$3a,$3a,$3a,$3a,$3a
 .byt $3b,$3b,$3b,$3b,$3b,$3b,$3b,$3b
 .byt $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c
 .byt $3e,$3e,$3e,$3e,$3e,$3e,$3e,$3e
; page
tablo .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
 .byt $40,$41,$42,$43,$44,$45,$46,$47
 .byt $80,$81,$82,$83,$84,$85,$86,$87
 .byt $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
 .byt $00,$01,$02,$03,$04,$05,$06,$07
;
; page
; ast 55
;
;         message output subroutine
;
;
msgout pla  ;get start addr of message
 sta temp ;  = subroutine return addr
 pla
 sta temp+1
 lda #<msgst
 sta ptr ;cursor to bottom of screen
 lda #>msgst
 sta ptr+1
 ldy #0
msglp inc temp ;next char
 bne skipadd ;test for 0
 inc temp+1
skipadd lda (temp),y ;get char
 beq msgrts ;test for done
 sta (ptr),y ;send to screen
 inc ptr ;next screen loc
 bne msglp ;next char
;
msgrts lda temp+1 ;update stack with return
 pha  ;  address from subroutine
 lda temp ;  after output message
 pha
 rts
;
; page
; ast 55
;
; synchronizer
;
syncer jsr inita ;initialize things
 jsr fore ;text foreground color
 lda #$08 ;enable computereyes
 sta cereg
;
slp1 lda #0 ;init hsync ctr
 sta ptr
 sta ptr+1
;
slp2 jsr kbtest ;test for keypress
 bne sdone
 lda #0
 sta ptra ;init sync interval counter
;
slp3 inc ptra ;inc    "      "       "
 beq sdn ;if it overflowed
 lda cereg ;sync here?
 bpl slp3 ;loop here if so
;
 lda ptra ;test sync interval ctr
 cmp #4 ;greater than vlo?
 bmi spinc ;if too short sync
 cmp #95 ;less than vhi?
 bpl sdn ;if too long
;
 jmp sth ;now test hsyncs
;
spinc inc ptr ;inc hsync ctr
 bne spov
 inc ptr+1
spov lda ptr+1 ;test if too many short syncs
 cmp #3
 bne slp2 ;if not yet, loop
 jmp sup
;
sdone jsr msgout ;clear bottom of screen
 .asc '                     '
 .byt $00
 lda #0
 sta cereg ;disable computereyes
 jsr swap ;restore zpage locs
 cli  ;enable interrupts
 rts  ;done!
;
; page
sdn jsr msgout ;print <--- adjust sync
 .byt $3c,$2d,$2d,$2d,$20,$01,$04,$0a,$15,$13,$14,$20,$13,$19,$0e,$03,$20,$20,$20,$20,$20,$20
 .byt $00
 jmp slp1
;
sin jsr msgout ;print        in sync
 .byt $20,$20,$20,$20,$20,$20,$20,$20,$09,$0e,$20,$13,$19,$0e,$03,$20,$20,$20,$20,$20,$20,$20,$20
 .byt $00
 jmp slp1
;
sup jsr msgout ;print     adjust sync --->
 .byt $20,$20,$20,$20,$20,$01,$04,$0a,$15,$13,$14,$20,$13,$19,$0e,$03,$20,$2d,$2d,$2d,$3e
 .byt $00
 jmp slp1
;
sth lda #22 ;wait 1.5 msec to get
 jsr wait ;  into frame
 lda #100 ;look for 156 good hsyncs
 sta ptra
;
sthlp lda cereg ;wait for sync
 bmi sthlp
 lda #1 ;wait 30 usec
 jsr wait
 lda cereg ;sync still here?
 bpl sdn ;bad sync if so
;
 inc ptra ;count good sync
 bne sthlp ;repeat
;
 beq sin ;in sync!
;
; page
; ast 55
;
; main grey-scale routine
;
four lda #0 ;4/8 flag =0
 beq gov0
;
eight lda #1 ;4/8 flag = 1
gov0 pha
;
 lda #$ef ;blank screen
 jsr init ;initialize things
 lda #dcomp ;set delay comp value
 sta dcompv
 lda #7 ;threshold level = 7
 sta thresh
 jsr color ;init color memory
 jsr acq ;acquire
 lda #0 ;reset delay comp value
 sta dcompv
 jsr kbtest ;test keypress
 bne gdone1
 lda #$b1 ;'move' for grok
 sta grokinst
 jsr grok ;copy; page 1 to; page 2
 lda #$11 ;'or' for grok
 sta grokinst
 pla ;test 4/8 flag
 pha
 beq gnxt1
;
 lda #6 ;level = 6
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone1
 jsr merge
;
gnxt1 lda #5 ;level = 5
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone1
 jsr merge
 pla ;test 4/8 flag
 pha
 beq gnxt2
;
 lda #4 ;level = 4
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone1
 jsr merge
;
; page
gnxt2 lda #3 ;level = 3
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
gdone1 bne gdone
 jsr merge
 pla ;test 4/8 flag
 pha
 beq gnxt3
;
 lda #2 ;level = 2
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone
 jsr merge
;
gnxt3 lda #1 ;level = 1
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone
 pla ;test 4/8 flag
 pha
 beq gnxt4
 jsr merge
;
 lda #0 ;level = 0
 sta thresh
 jsr acq
 jsr kbtest ;test keypress
 bne gdone
gnxt4 lda #temp ;change merge so that image
 sta mginst+1 ;ends up on; page 1
 jsr merge
 lda #ptra
 sta mginst+1 ;restore merge routine
;
gdone pla  ;dummy pop
 jmp pfini ;clean up & exit
;
; page
; ast 55
;
; subroutine to grok; page 1 into; page 2
; change loc 'grokinst' to one of the following:
;    or $11
;   eor $51
;   and $31
;  move $b1
;
grok lda #0 ;init; page 1 and; page 2 ptrs
 sta temp
 sta ptr
 lda #$40
 sta ptr+1
 lda #$20
 sta temp+1 ;init counter
 ldy #0
;
groklp lda (ptr),y ;get value from; page 2
grokinst ora (temp),y ;modify it w/page 1 value
 sta (ptr),y ;store it back
 iny  ;next
 bne groklp
;
 inc temp+1 ;next; page
 inc ptr+1
 lda temp+1
 cmp #$40 ;test for done
 bne groklp ;if not
 rts
;
; page
; ast 55
;
; subroutine to merge images acquired at different thresholds
; into common image in; page 2
;
merge lda thresh ;calc dither table addr
 asl ;a
 asl ;a
 asl ;a
 adc #<dthrtab
 sta ptr
 lda #0
 adc #>dthrtab
 sta ptr+1
;
 lda #0 ;init pointers
 sta temp
 sta ptra
 lda #$20
 sta temp+1
 lda #$40
 sta ptra+1
;
mglp1 ldy #7 ;for eight times thru loop
mglp2 lda (temp),y ;get image data
 and (ptr),y ;mask with dither data
 ora (ptra),y ;'or' with composite image
mginst sta (ptra),y
 dey
 bpl mglp2
;
 clc  ;inc pointers by 8
 lda temp
 adc #8
 sta temp
 sta ptra
 bcc mglp1
 inc temp+1
 inc ptra+1
 lda temp+1 ;test for done
 cmp #$40
 bne mglp1
;
 rts  ;done
;
dthrtab .byt $80,$04,$20,$01,$08,$40,$02,$10
 .byt $90,$84,$24,$21,$09,$48,$42,$12
 .byt $94,$a4,$25,$29,$49,$4a,$52,$92
 .byt $95,$ac,$65,$2b,$59,$ca,$56,$b2
 .byt $b5,$ad,$6d,$6b,$5b,$da,$d6,$b6
 .byt $bd,$ed,$6f,$7b,$db,$de,$f6,$b7
 .byt $fd,$ef,$7f,$fb,$df,$fe,$f7,$bf
;
; page
; ast 55
;
;       image pack routine
;
pack jsr pinit ;init things
 jsr pread ;get image data
 sta temp ;init old data
 jsr pwrite ;store in packed mem
;
plp1 bcs pdone ;if after last byte
 lda #0 ;clear ctr
 sta ctr
 jsr pread ;get next data
 eor temp ; = old?
 beq psame
;
plcont lda temp+1 ;test for = 0
 bne plov ;if not
;
 jsr pwrite ;store leading zero
;
plov jsr pwrite ;store data in packed mem
 sta temp ;old = new
 jmp plp1 ;back to top
;
; new = old  -  inc ctr etc.
;
psame inc ctr ;inc ctr
 lda ctr ;test for max value
 eor #255
 beq psctrd
;
 bcs psdn ;if after last byte
;
 jsr pread ;get next byte
 eor temp ; = old?
 beq psame ;if so
;
 jsr pwctr ;store ctr value
 lda temp+1 ;retrieve image data
 jmp plcont ;back into main loop
;
psctrd jsr pwctr ;save counter value
 jmp plp1
;
psdn jsr pwctr ;save ctr value
;
pdone jsr swap
 rts  ;done!
; page
;
; ast 55
;
; pack/unpack initialization
;
pinit jsr swap ;save zpage values
 lda #0 ;init pointers
 sta ptr
 sta ptra
 lda #$20
 sta ptr+1
 lda #$40
 sta ptra+1
 ldy #0 ;y always 0
 rts
;
; read data from image memory
;
pread lda (ptr),y
 pha
 inc ptr
 bne prov
 inc ptr+1
prov clc
 lda ptr+1
 eor #$40
 bne prdn
 sec
prdn pla
 sta temp+1 ;save
 rts
;
; store data in packed memory
;
pwrite sta (ptra),y
 inc ptra
 bne pwov
 inc ptra+1
pwov rts
;
; store counter in packed memory
;
pwctr lda #0
 jsr pwrite
 lda ctr
 jmp pwrite
; page
;
; read from packed memory
;
uread lda (ptra),y
 pha
 sta temp+1
 inc ptra
 bne urov
 inc ptra+1
urov pla
 rts
;
; store data in image memory
;
uwrite sta (ptr),y
 pha
 inc ptr
 bne uwov
 inc ptr+1
uwov clc
 lda ptr+1
 eor #$40
 bne uwdn
 sec
uwdn pla
 rts
;
; page
; ast 55
;
; image unpack routine
;
unpack jsr pinit
 jsr uread
 jsr uwrite
 sta temp ;init old
;
ulp1 bcs udone ;after last byte
 jsr uread ;get packed byte
 bne ustr ;if <> 0
;
 jsr uread ;read second of pair
 bne usame ;if ctr value
;
ustr jsr uwrite ;store in image mem
 sta temp ;old = new
 jmp ulp1 ;back to top
;
usame sta ctr ;ctr = data
uslp lda temp ;get old data
 jsr uwrite ;store in image mem
 dec ctr
 bne uslp
;
 jmp ulp1
;
udone jsr swap
 rts
;
; page
; ast 55
;
;                save.c
;
; commodore binary file save subroutine
;
; loc 251-252 = start address of file to save
; loc 251-254 = length
;
; poke these locs, open file, and sys saver
;
;
saver clc  ;add length to start address
 lda 251
 adc 253
 tax  ;store low byte in x
 lda 252
 adc 254
 tay  ;and high byte in y
 lda #251 ;a = ptr to start address
 jsr save ;call kernal save routine
 rts  ;done
;
; page
; ast 55
;
; init text screen foreground color
;
fore lda #0 ;init pointer
 sta ptr
 lda #$d8
 sta ptr+1
 ldy #0
;
floop lda #$01 ;color = white
 sta (ptr),y ;store
 iny  ;next
 bne floop
 inc ptr+1
 lda ptr+1
 cmp #$dc
 bne floop
 rts
; lst off
