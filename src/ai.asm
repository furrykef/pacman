; This ordering is used so that you can reverse direction using EOR #$03
.enum Direction
        left
        right
        up
        down
.endenum

.enum GhostState
        active
        blue
        eaten
        waiting
        exiting
.endenum


.struct Ghost
        pos_x       .byte                   ; center of sprite, not upper left
        pos_y       .byte
        direction   .byte
        turn_dir    .byte                   ; Direction ghost has planned to turn in
        speed       .byte
        state       .byte
        palette     .byte
.endstruct


.segment "ZEROPAGE"

Blinky:     .tag Ghost
Pinky:      .tag Ghost
Inky:       .tag Ghost
Clyde:      .tag Ghost

TileX:          .res 1
TileY:          .res 1
PixelX:         .res 1
PixelY:         .res 1
NextTileX:      .res 1
NextTileY:      .res 1
TargetTileX:    .res 1
TargetTileY:    .res 1


.segment "CODE"

InitAI:
        lda     #127
        sta     Blinky+Ghost::pos_x
        lda     #91
        sta     Blinky+Ghost::pos_y
        lda     #Direction::left
        sta     Blinky+Ghost::direction
        sta     Blinky+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Blinky+Ghost::state
        lda     #0
        sta     Blinky+Ghost::palette
        rts

MoveGhosts:
        ; Move Blinky
        ldx     Blinky+Ghost::direction
        lda     Blinky+Ghost::pos_x
        add     DeltaXTbl,x
        sta     Blinky+Ghost::pos_x
        pha
        lsr
        lsr
        lsr
        sta     TileX
        add     DeltaXTbl,x
        sta     NextTileX
        pla
        and     #$07
        sta     PixelX
        lda     Blinky+Ghost::pos_y
        add     DeltaYTbl,x
        sta     Blinky+Ghost::pos_y
        pha
        lsr
        lsr
        lsr
        sta     TileY
        add     DeltaYTbl,x
        sta     NextTileY
        pla
        and     #$07
        sta     PixelY

        ; @TODO@ -- if TileX and TileY match Pac-Man's, kill Pac-Man

        ; *** TEST ***
        lda     #0
        sta     TargetTileX
        sta     TargetTileY
        ; *** END TEST ***

        ; Will we be able to go north?
        ldy     NextTileX
        dey
        ldx     NextTileY
        jsr     IsTileEnterable

        ; @XXX@

        ; Update Blinky in OAM
        lda     Blinky+Ghost::pos_y
        sub     VScroll
        sub     #8
        sta     MyOAM
        sta     MyOAM+4
        lda     #$01                        ; Sprite index number
        sta     MyOAM+1
        lda     #$03
        sta     MyOAM+5
        lda     #$00                        ; Attributes
        sta     MyOAM+2
        sta     MyOAM+6
        lda     Blinky+Ghost::pos_x
        sub     #7
        sta     MyOAM+3
        add     #8
        sta     MyOAM+7
        rts

DeltaXTbl:
        .byte   -1                          ; left
        .byte   1                           ; right
        .byte   0                           ; up
        .byte   0                           ; down

DeltaYTbl:
        .byte   0                           ; left
        .byte   0                           ; right
        .byte   -1                          ; up
        .byte   1                           ; down

; Input:
;   Y = X coordinate
;   X = Y coordinate
;
; Yes, I know it's backwards!
;
; Output:
;   EQ if so, NE if not
IsTileEnterable:
        ; All this loop does is set TmpL to CurrentBoard+y_coord*32
        lda     #<CurrentBoard
        sta     TmpL
        lda     #>CurrentBoard
        sta     TmpH
@loop:
        dex
        bmi     @end_loop
        lda     TmpL
        add     #32
        sta     TmpL
        lda     TmpH
        adc     #0
        sta     TmpH
        jmp     @loop
@end_loop:
        ; Now we can finally check if the tile can be entered or not
        lda     (TmpL),y
        cmp     #$20                    ; space
        beq     @done
        cmp     #$92                    ; dot
        beq     @done
        cmp     #$95                    ; energizer
@done:
        rts
