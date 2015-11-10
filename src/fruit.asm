FRUIT_TIMEOUT = 10*60
FRUIT_POINTS_TIMEOUT = 2*60


.segment "ZEROPAGE"

FruitClockL:        .res 1
FruitClockH:        .res 1
FruitPointsClock:   .res 1


.segment "CODE"

InitFruit:
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        sta     FruitPointsClock
        rts


SpawnFruit:
        lda     #<FRUIT_TIMEOUT
        sta     FruitClockL
        lda     #>FRUIT_TIMEOUT
        sta     FruitClockH

        ; @TODO@ -- depends on level
        lda     #0
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

        ; Pac-Man is eating the fruit
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        lda     #<Points100
        sta     TmpL
        lda     #>Points100
        sta     TmpH
        jsr     AddPoints
        lda     #FRUIT_POINTS_TIMEOUT
        sta     FruitPointsClock
@end:
        rts
@zero:
        ; Check if we're drawing points
        lda     FruitPointsClock
        beq     @no_points
        ; Drawing points
        dec     FruitPointsClock
        lda     #1                          ; @TODO@
        jmp     DrawPointsGraphic

@no_points:
        jmp     ClearFruitGraphic


DrawFruitGraphic:
        asl
        add     #$d0
        tay
        DlBegin

        DlAdd   #2, #$22, #$0f
        tya
        DlAddA
        add     #1
        DlAddA
        add     #$0f
        tay

        DlAdd   #4, #$22, #$2e
        DlAdd   #$20
        tya
        DlAddA
        add     #1
        DlAddA
        add     #$0f
        tay
        DlAdd   #$20

        DlAdd   #2, #$22, #$4f
        tya
        DlAddA
        add     #1
        DlAddA

        DlEnd
        rts


DrawPointsGraphic:
        ; 4-byte entries
        asl
        asl
        tay
        DlBegin

        DlAdd   #2, #$22, #$0f
        DlAdd   #$a8, #$a8

        DlAdd   #4, #$22, #$2e
.repeat 4
        lda     PointsGraphicTbl,y
        iny
        DlAddA
.endrepeat

        DlAdd   #2, #$22, #$4f
        DlAdd   #$82, #$82

        DlEnd
        rts


ClearFruitGraphic:
        lda     #0
        jmp     DrawPointsGraphic


PointsGraphicTbl:
        .byte   $20, $20, $20, $20          ; blank (will clear fruit graphic if drawn)
        .byte   $20, $c0, $c1, $20          ; 100 points
