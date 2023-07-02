	.word $cd00
	* = $cd00

lcd00	lda $033e
	sta lcd9b
	lda $01
	pha
	ora #$07
	sta $01
	lda #$01
	ldx #$08
	ldy #$00
	jsr $ffba
	lda #$04
	ldx #$98
	ldy #$cd
	jsr $ffbd
	jsr $ffc0
	lda #$00
	sta $90
	ldx #$01
	jsr $ffc6
	jsr $ffcf
	jsr $ffcf
lcd31	jsr $ffcf
	jsr $ffcf
	lda $90
	and #$40
	bne lcd5c
lcd3d	jsr lcd68
lcd40	lda $028d
	and #$01
	bne lcd40
lcd47	jsr $ffea
	jsr $ffe1
	bne lcd31
lcd4f	ldy #$10
lcd51	jsr $ffea
	jsr $ffe1
	beq lcd4f
lcd59	dey
	bne lcd51
lcd5c	jsr $ffcc
	lda #$01
	jsr $ffc3
	pla
	sta $01
	rts
lcd68	jsr $ffcf
	tay
	jsr $ffcf
	jsr $b391
	jsr $bddd
	jsr $ab1e
	lda #$20
lcd7a	jsr $ffd2
	jsr $ffcf
	pha
	lda $90
	and #$40
	beq lcd8d
lcd87	pla
	pla
	pla
	jmp lcd5c
lcd8d	pla
	cmp #$00
	bne lcd7a
lcd92	lda #$0d
	jsr $ffd2
	rts
	.byt $24,$2a,$3d
lcd9b 	.byt $00
