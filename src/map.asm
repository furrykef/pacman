.segment "BSS"

CurrentBoard:   .res 32*31


.segment "CODE"

LoadBoard:
        lda     #<FullBoard
        sta     TmpL
        lda     #>FullBoard
        sta     TmpH
        lda     #<CurrentBoard
        sta     Tmp2L
        lda     #>CurrentBoard
        sta     Tmp2H
        ldx     #31
@copy_row:
        ldy     #0
@copy_cell:
        lda     (TmpL),y
        sta     (Tmp2L),y
        iny
        cpy     #32
        bne     @copy_cell
        ; Finished this row; bump pointers by a row
        lda     TmpL
        add     #32
        sta     TmpL
        lda     TmpH
        adc     #0
        sta     TmpH
        lda     Tmp2L
        add     #32
        sta     Tmp2L
        lda     Tmp2H
        adc     #0
        sta     Tmp2H
        dex
        bne     @copy_row
        jmp     CopyBoardIntoVram


CopyBoardIntoVram:
        ; Load first nametable
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #<CurrentBoard
        sta     TmpL
        lda     #>CurrentBoard
        sta     TmpH
        ldx     #30
@copy_row:
        ldy     #0
@copy_cell:
        lda     (TmpL),y
        sta     PPUDATA
        iny
        cpy     #32
        bne     @copy_cell
        ; Finished this row; bump pointer by a row
        lda     TmpL
        add     #32
        sta     TmpL
        lda     TmpH
        adc     #0
        sta     TmpH
        dex
        bne     @copy_row

        ; Last row has to be written to other nametable
        lda     #$28
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        tax
@loop:
        lda     CurrentBoard+32*30,x
        sta     PPUDATA
        inx
        cpx     #32
        bne     @loop

        ; Clear attribute tables
        lda     #$23
        sta     PPUADDR
        lda     #$c0
        sta     PPUADDR
        lda     #$00
        jsr     ClearAttr
        lda     #$2b
        sta     PPUADDR
        lda     #$c0
        sta     PPUADDR
        jsr     ClearAttr

        ; Attributes for door to ghost house (X=15..16, Y=12)
        ; These use palette 1 instead of palette 0
        lda     #$23
        sta     PPUADDR
        lda     #$db
        sta     PPUADDR
        lda     #1 << 2
        sta     PPUDATA
        lda     #1
        sta     PPUDATA

        rts

ClearAttr:
        ldx     #64
@loop:
        sta     PPUDATA
        dex
        bne     @loop
        rts


; Input:
;   Y = X coordinate
;   X = Y coordinate
;
; Yes, I know it's backwards!
;
; Output:
;   EQ if so, NE if not
IsTileEnterable:
        ; Set Tmp to the appropriate row of CurrentBoard
        lda     CurrentBoardRowAddrL,x
        sta     TmpL
        lda     CurrentBoardRowAddrH,x
        sta     TmpH
        ; Now check if the tile can be entered or not
        lda     (TmpL),y
        cmp     #$20                        ; space
        beq     @done
        cmp     #$92                        ; dot
        beq     @done
        cmp     #$95                        ; energizer
        beq     @done
        cmp     #$90                        ; enterable mask
@done:
        rts


; Some codes:
;   $00 = blank, non-enterable
;   $20 = blank, enterable
;   $80 = mask, non-enterable (blank tile that sprites should move behind instead of in front of)
;   $90 = mask, enterable
;   $92 = dot
;   $95 = energizer
FullBoard:
    .byte $00,$00,$84,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$aa,$ab,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$86,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$81,$82,$82,$83,$92,$81,$82,$82,$82,$83,$92,$91,$93,$92,$81,$82,$82,$82,$83,$92,$81,$82,$82,$83,$92,$96,$00,$00
    .byte $00,$00,$94,$95,$91,$00,$00,$93,$92,$91,$00,$00,$00,$93,$92,$91,$93,$92,$91,$00,$00,$00,$93,$92,$91,$00,$00,$93,$95,$96,$00,$00
    .byte $00,$00,$94,$92,$a1,$a2,$a2,$a3,$92,$a1,$a2,$a2,$a2,$a3,$92,$a1,$a3,$92,$a1,$a2,$a2,$a2,$a3,$92,$a1,$a2,$a2,$a3,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$81,$82,$82,$83,$92,$81,$83,$92,$81,$82,$82,$82,$82,$82,$82,$83,$92,$81,$83,$92,$81,$82,$82,$83,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$a1,$a2,$a2,$a3,$92,$91,$93,$92,$a1,$a2,$a2,$8b,$8a,$a2,$a2,$a3,$92,$91,$93,$92,$a1,$a2,$a2,$a3,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$a4,$a5,$a5,$a5,$a5,$83,$92,$91,$9a,$82,$82,$83,$20,$91,$93,$20,$81,$82,$82,$9b,$93,$92,$81,$a5,$a5,$a5,$a5,$a6,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$8a,$a2,$a2,$a3,$20,$a1,$a3,$20,$a1,$a2,$a2,$8b,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$93,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$91,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$93,$20,$87,$88,$8c,$8d,$8d,$8e,$88,$89,$20,$91,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $80,$80,$85,$85,$85,$85,$85,$a3,$92,$a1,$a3,$20,$97,$00,$00,$00,$00,$00,$00,$99,$20,$a1,$a3,$92,$a1,$85,$85,$85,$85,$85,$80,$80
    .byte $90,$90,$20,$20,$20,$20,$20,$20,$92,$20,$20,$20,$97,$00,$00,$00,$00,$00,$00,$99,$20,$20,$20,$92,$20,$20,$20,$20,$20,$20,$90,$90
    .byte $80,$80,$a5,$a5,$a5,$a5,$a5,$83,$92,$81,$83,$20,$97,$00,$00,$00,$00,$00,$00,$99,$20,$81,$83,$92,$81,$a5,$a5,$a5,$a5,$a5,$80,$80
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$93,$20,$a7,$a8,$a8,$a8,$a8,$a8,$a8,$a9,$20,$91,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$93,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$91,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$94,$92,$91,$93,$20,$81,$82,$82,$82,$82,$82,$82,$83,$20,$91,$93,$92,$96,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$84,$85,$85,$85,$85,$a3,$92,$a1,$a3,$20,$a1,$a2,$a2,$8b,$8a,$a2,$a2,$a3,$20,$a1,$a3,$92,$a1,$85,$85,$85,$85,$86,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$81,$82,$82,$83,$92,$81,$82,$82,$82,$83,$92,$91,$93,$92,$81,$82,$82,$82,$83,$92,$81,$82,$82,$83,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$a1,$a2,$8b,$93,$92,$a1,$a2,$a2,$a2,$a3,$92,$a1,$a3,$92,$a1,$a2,$a2,$a2,$a3,$92,$91,$8a,$a2,$a3,$92,$96,$00,$00
    .byte $00,$00,$94,$95,$92,$92,$91,$93,$92,$92,$92,$92,$92,$92,$92,$20,$20,$92,$92,$92,$92,$92,$92,$92,$91,$93,$92,$92,$95,$96,$00,$00
    .byte $00,$00,$ac,$82,$83,$92,$91,$93,$92,$81,$83,$92,$81,$82,$82,$82,$82,$82,$82,$83,$92,$81,$83,$92,$91,$93,$92,$81,$82,$ad,$00,$00
    .byte $00,$00,$bc,$a2,$a3,$92,$a1,$a3,$92,$91,$93,$92,$a1,$a2,$a2,$8b,$8a,$a2,$a2,$a3,$92,$91,$93,$92,$a1,$a3,$92,$a1,$a2,$bd,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$91,$93,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$81,$82,$82,$82,$82,$9b,$9a,$82,$82,$83,$92,$91,$93,$92,$81,$82,$82,$9b,$9a,$82,$82,$82,$82,$83,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$a1,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a3,$92,$a1,$a3,$92,$a1,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a3,$92,$96,$00,$00
    .byte $00,$00,$94,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$96,$00,$00
    .byte $00,$00,$a4,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a5,$a6,$00,$00

;FullBoardRowAddrL:
;.repeat I, 31
;    .byte <FullBoard+(32*I)
;.endrepeat
;
;FullBoardRowAddrH:
;.repeat I, 31
;    .byte <FullBoard+(32*I)
;.endrepeat

CurrentBoardRowAddrL:
.repeat 31, I
    .byte <CurrentBoard+(32*I)
.endrepeat

CurrentBoardRowAddrH:
.repeat 31, I
    .byte >(CurrentBoard+(32*I))
.endrepeat
