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

        DlBegin
        DlAdd   #2, #$22, #$0f
        DlAdd   #$d0, #$d1
        ; Clear space to the left and right of the fruit as well
        ; (in case bonus points have been drawn here)
        DlAdd   #4, #$22, #$2e
        DlAdd   #$20, #$e0, #$e1, #$20
        DlAdd   #2, #$22, #$4f
        DlAdd   #$f0, #$f1
        DlEnd

        rts


HandleFruit:
        lda     EatingGhostClock
        bne     @end

        lda     FruitClockL
        beq     @maybe_zero
        jmp     @nonzero
@maybe_zero:
        ldx     FruitClockH
        beq     @end
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
