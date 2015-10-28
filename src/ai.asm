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

MaxScore:       .res 1
ScoreUp:        .res 1
ScoreRight:     .res 1
ScoreDown:      .res 1
ScoreLeft:      .res 1


.segment "CODE"

InitAI:
        lda     #127
        sta     Blinky+Ghost::pos_x
        lda     #91
        sta     Blinky+Ghost::pos_y
        lda     #Direction::right
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

        ; If ghost is centered in tile, have him turn if necessary
        ; and compute next turn
        lda     PixelX
        cmp     #$03
        bne     @not_centered
        lda     PixelY
        cmp     #$03
        bne     @not_centered
        lda     Blinky+Ghost::turn_dir
        sta     Blinky+Ghost::direction
        jsr     ComputeTurn
@not_centered:

        ; Update Blinky in OAM
        lda     Blinky+Ghost::pos_y
        sub     VScroll
        sub     #8
        sta     MyOAM
        sta     MyOAM+4
        lda     Blinky+Ghost::turn_dir
        asl
        asl
        ora     #$01
        sta     MyOAM+1                     ; Sprite index number
        add     #2
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


ComputeTurn:
        lda     #0
        sta     MaxScore
        lda     NextTileX
        sub     TargetTileX
        sta     ScoreLeft
        eor     #$ff
        add     #1
        sta     ScoreRight
        lda     NextTileY
        sub     TargetTileY
        sta     ScoreUp
        eor     #$ff
        add     #1
        sta     ScoreDown

        ; Will we be able to go up?
        lda     Blinky+Ghost::direction     ; Disallow if going down
        cmp     #Direction::down
        beq     @no_up
        ldy     NextTileX
        ldx     NextTileY
        dex
        jsr     IsTileEnterable
        bne     @no_up
        lda     ScoreUp
        bmi     @no_up
        sta     MaxScore
        lda     #Direction::up
        sta     Blinky+Ghost::turn_dir
        jmp     @try_right
@no_up:
        lda     #0
        sta     ScoreUp
@try_right:
        lda     Blinky+Ghost::direction     ; Disallow if going left
        cmp     #Direction::left
        beq     @no_right
        ldy     NextTileX
        iny
        ldx     NextTileY
        jsr     IsTileEnterable
        bne     @no_right
        lda     ScoreRight
        bmi     @no_right
        cmp     MaxScore
        blt     @no_right
        sta     MaxScore
        lda     #Direction::right
        sta     Blinky+Ghost::turn_dir
        jmp     @try_down
@no_right:
        lda     #0
        sta     ScoreRight
@try_down:
        lda     Blinky+Ghost::direction     ; Disallow if going up
        cmp     #Direction::up
        beq     @no_down
        ldy     NextTileX
        ldx     NextTileY
        inx
        jsr     IsTileEnterable
        bne     @no_down
        lda     ScoreRight
        bmi     @no_down
        cmp     MaxScore
        blt     @no_down
        sta     MaxScore
        lda     #Direction::down
        sta     Blinky+Ghost::turn_dir
        jmp     @try_left
@no_down:
        lda     #0
        sta     ScoreDown
@try_left:
        lda     Blinky+Ghost::direction     ; Disallow if going right
        cmp     #Direction::right
        beq     @no_left
        ldy     NextTileX
        dey
        ldx     NextTileY
        jsr     IsTileEnterable
        bne     @no_left
        lda     ScoreRight
        bmi     @no_left
        cmp     MaxScore
        blt     @no_left
        ;sta     MaxScore
        lda     #Direction::left
        sta     Blinky+Ghost::turn_dir
@no_left:
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
        cmp     #$20                    ; space
        beq     @done
        cmp     #$92                    ; dot
        beq     @done
        cmp     #$95                    ; energizer
@done:
        rts
