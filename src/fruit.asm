FRUIT_TIMEOUT = 10*60
FRUIT_POINTS_TIMEOUT = 2*60


; Order is important!
.enum
        CHERRY
        STRAWBERRY
        PEACH
        APPLE
        GRAPES
        GALAXIAN
        BELL
        KEY
.endenum


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
        lda     #CHERRY
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
        lda     #CHERRY                     ; @TODO@ -- depends on level
        jsr     AddFruitPoints
        lda     #FRUIT_POINTS_TIMEOUT
        sta     FruitPointsClock
@end:
        rts
@zero:
        ; Check if we're drawing points
        lda     FruitPointsClock
        beq     @no_points
        dec     FruitPointsClock
        rts

@no_points:
        jmp     ClearFruitGraphic


; Input:
;   A = ID of fruit (CHERRY, etc.)
AddFruitPoints:
        ; First entry of PointsTbl is dummy entry
        add     #1
        ; Entries are 8 bytes
        asl
        asl
        asl
        tax
        lda     PointsTbl,x
        sta     TmpL
        inx
        lda     PointsTbl,x
        sta     TmpH
        inx
        txa
        pha
        jsr     AddPoints
        pla
        tay
        jmp     DrawPointsGraphic


; Input:
;   A = ID of fruit (CHERRY, etc.)
DrawFruitGraphic:
        asl
        add     #$d0
        tay
        DlBegin

        ; Top row
        DlAdd   #2, #$22, #$0f
        tya
        DlAddA
        add     #1
        DlAddA
        add     #$0f
        tay

        ; Middle row
        DlAdd   #4, #$22, #$2e
        DlAdd   #$20
        tya
        DlAddA
        add     #1
        DlAddA
        add     #$0f
        tay
        DlAdd   #$20

        ; Bottom row
        DlAdd   #2, #$22, #$4f
        tya
        DlAddA
        add     #1
        DlAddA

        DlEnd
        rts


; Input:
;   Y = byte index into PointsTbl
DrawPointsGraphic:
        DlBegin

        ; Clear top two tiles of fruit
        DlAdd   #2, #$22, #$0f
        DlAdd   #$a8, #$a8

        DlAdd   #4, #$22, #$2e
.repeat 4
        lda     PointsTbl,y
        iny
        DlAddA
.endrepeat

        ; Clear bottom two tiles of fruit
        DlAdd   #2, #$22, #$4f
        DlAdd   #$82, #$82

        DlEnd
        rts


ClearFruitGraphic:
        ldy     #2
        jmp     DrawPointsGraphic


LevelToFruit:
        .byte   CHERRY                      ; 0 (level 1)
        .byte   STRAWBERRY                  ; 1
        .byte   PEACH                       ; 2
        .byte   PEACH                       ; 3
        .byte   APPLE                       ; 4
        .byte   APPLE                       ; 5
        .byte   GRAPES                      ; 6
        .byte   GRAPES                      ; 7
        .byte   GALAXIAN                    ; 8
        .byte   GALAXIAN                    ; 9
        .byte   BELL                        ; 10
        .byte   BELL                        ; 11
        .byte   KEY                         ; 12


; First two bytes of each entry are address of points BCD number
; Next four bytes are the graphic
; Last two bytes are padding to make each entry 8 bytes
PointsTbl:
        .addr   0                           ; blank (will clear fruit graphic if drawn)
        .byte   $20, $20, $20, $20, 0, 0    ; (address is dummy address)

        .addr   Points100
        .byte   $20, $c0, $c1, $20, 0, 0
