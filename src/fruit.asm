FRUIT_TIMEOUT = 10*60


.segment "ZEROPAGE"

FruitClockL:        .res 1
FruitClockH:        .res 1


.segment "CODE"

InitFruit:
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        rts


SpawnFruit:
        lda     #<FRUIT_TIMEOUT
        sta     FruitClockL
        lda     #>FRUIT_TIMEOUT
        sta     FruitClockH

        ; @TODO@ -- depends on level
        lda     #1
        jmp     DrawFruitGraphic


HandleFruit:
        lda     EatingGhostClock
        bne     @end

        lda     FruitClockL
        beq     @maybe_zero
        jmp     @nonzero
@maybe_zero:
        ldx     FruitClockH
        beq     @zero
@nonzero:
        sub     #1
        sta     FruitClockL
        lda     FruitClockH
        sbc     #0
        sta     FruitClockH

        ; Check if Pac-Man is eating fruit
        ldx     PacTileY
        cpx     #17
        bne     @end
        lda     PacX
        cmp     #126
        blt     @end
        cmp     #130
        bge     @end

        ; Pac-Man is in the fruit zone
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        lda     #<Points100
        sta     TmpL
        lda     #>Points100
        sta     TmpH
        jsr     AddPoints
@end:
        rts
@zero:
        ; Clear fruit graphic
        lda     #0
        jmp     DrawFruitGraphic


DrawFruitGraphic:
        ; Entries are 8 bytes
        asl
        asl
        asl
        tay

        DlBegin
        DlAdd   #2, #$22, #$0f
.repeat 2
        lda     FruitGraphicTbl,y
        iny
        DlAddA
.endrepeat
        DlAdd   #4, #$22, #$2e
.repeat 4
        lda     FruitGraphicTbl,y
        iny
        DlAddA
.endrepeat
        DlAdd   #2, #$22, #$4f
.repeat 2
        lda     FruitGraphicTbl,y
        iny
        DlAddA
.endrepeat
        DlEnd

        rts


; First two bytes correspond to (15, 16) and (16, 16)
; Next four correspond to (14, 17) through (17, 17)
; Last two bytes correspond to (15, 18) through (16, 18)
FruitGraphicTbl:
        .byte   $a8, $a8, $20, $20, $20, $20, $82, $82      ; blank
        .byte   $d0, $d1, $20, $e0, $e1, $20, $f0, $f1      ; cherry