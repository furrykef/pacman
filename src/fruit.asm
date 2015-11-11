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


GetFruitId:
        ldx     NumLevel
        cpx     #12
        bge     @key
        lda     LevelToFruit,x
        rts
@key:
        lda     #KEY
        rts


SpawnFruit:
        lda     #<FRUIT_TIMEOUT
        sta     FruitClockL
        lda     #>FRUIT_TIMEOUT
        sta     FruitClockH

        jsr     GetFruitId
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


AddFruitPoints:
        jsr     GetFruitId

        asl                                 ; entries are 2 bytes
        pha
        tax
        lda     FruitPointsTbl,x
        sta     TmpL
        inx
        lda     FruitPointsTbl,x
        sta     TmpH
        inx
        txa
        jsr     AddPoints
        pla
        asl                                 ; entries are 4 bytes
        add     #4                          ; first entry is a dummy entry
        tay
        jmp     DrawPointsGraphic


; Input:
;   A = ID of fruit (CHERRY, etc.)
DrawFruitGraphic:
        asl
        pha                                 ; keep doubled fruit ID for later
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

        ; Palette
        DlAdd   #2, #$3f, #$0e
        pla                                 ; get doubled fruit ID back
        tay
        lda     FruitPalettes,y
        iny
        DlAddA
        lda     FruitPalettes,y
        DlAddA

        DlEnd
        rts


; Input:
;   Y = byte index into FruitPointsGfxTbl
DrawPointsGraphic:
        DlBegin

        ; Clear top two tiles of fruit
        DlAdd   #2, #$22, #$0f
        DlAdd   #$a8, #$a8

        DlAdd   #4, #$22, #$2e
.repeat 4
        lda     FruitPointsGfxTbl,y
        iny
        DlAddA
.endrepeat

        ; Clear bottom two tiles of fruit
        DlAdd   #2, #$22, #$4f
        DlAdd   #$82, #$82

        ; Palette
        DlAdd   #1, #$3f, #$0e
        DlAdd   #$25

        DlEnd
        rts


ClearFruitGraphic:
        ldy     #0
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
FruitPointsTbl:
        .addr   Points100                   ; cherry
        .addr   Points300                   ; strawberry
        .addr   Points500                   ; peach
        .addr   Points700                   ; apple
        .addr   Points1000                  ; grapes
        .addr   Points2000                  ; galaxian
        .addr   Points3000                  ; bell
        .addr   Points5000                  ; key


FruitPointsGfxTbl:
        .byte   $20, $20, $20, $20          ; blank (will clear fruit graphic if drawn)
        .byte   $20, $c0, $c1, $20          ; 100 points (cherry)
        .byte   $20, $c2, $c1, $20          ; 300 points (strawberry)
        .byte   $20, $c3, $c1, $20          ; 500 points (peach)
        .byte   $20, $c4, $c1, $20          ; 700 points (apple)
        .byte   $20, $c5, $c6, $c7          ; 1000 points (grape)
        .byte   $c8, $c9, $c6, $c7          ; 2000 points (galaxian)
        .byte   $ca, $cb, $c6, $c7          ; 3000 points (bell)
        .byte   $cc, $cd, $c6, $c7          ; 5000 points (key)


FruitPalettes:
        .byte   $16, $27                    ; cherry
        .byte   $16, $30                    ; strawberry
        .byte   $26, $2a                    ; peach
        .byte   $16, $27                    ; apple
        .byte   $2a, $30                    ; grapes
        .byte   $28, $16                    ; galaxian
        .byte   $28, $30                    ; bell
        .byte   $31, $20                    ; key
