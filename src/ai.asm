.enum GhostState
        active
        blue
        eaten
        waiting
        exiting
.endenum


.struct Ghost
        pos_x           .byte               ; center of ghost, not upper left
        pos_y           .byte
        tile_x          .byte
        tile_y          .byte
        direction       .byte
        turn_dir        .byte               ; direction ghost has planned to turn in
        speed           .byte
        state           .byte
        reverse         .byte
        get_target_tile .addr
        oam_offset      .byte
        palette         .byte
.endstruct


.segment "ZEROPAGE"

Blinky:     .tag Ghost
Pinky:      .tag Ghost
Inky:       .tag Ghost
Clyde:      .tag Ghost

GhostL:         .res 1
GhostH:         .res 1

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

GhostOamL:      .res 1
GhostOamH:      .res 1

fScatter:       .res 1
ModeClockL:     .res 1
ModeClockH:     .res 1
ModeCount:      .res 1


.segment "CODE"

; Times are guessed based on Pac-Man Dossier
Lvl1Modes:
        .word   $01a0                       ; 0 (scatter) - 7 secs
        .word   $04b0                       ; 1 (chase) - 20 secs
        .word   $01a0                       ; 2 (scatter) - 7 secs
        .word   $04b0                       ; 3 (chase) - 20 secs
        .word   $0130                       ; 4 (scatter) - 5 secs
        .word   $04b0                       ; 5 (chase) - 20 secs
        .word   $0130                       ; 6 (scatter) - 5 secs

Lvl2Modes:
        .word   $01a0                       ; 0 (scatter) - 7 secs
        .word   $04b0                       ; 1 (chase) - 20 secs
        .word   $01a0                       ; 2 (scatter) - 7 secs
        .word   $04b0                       ; 3 (chase) - 20 secs
        .word   $0130                       ; 4 (scatter) - 5 secs
        .word   $f220                       ; 5 (chase) - 1033 secs
        .word   $0001                       ; 6 (scatter) - 1/60 sec

Lvl5Modes:
        .word   $0130                       ; 0 (scatter) - 5 secs
        .word   $04b0                       ; 1 (chase) - 20 secs
        .word   $0130                       ; 2 (scatter) - 5 secs
        .word   $04b0                       ; 3 (chase) - 20 secs
        .word   $0130                       ; 4 (scatter) - 5 secs
        .word   $f300                       ; 5 (chase) - 1037 secs
        .word   $0001                       ; 6 (scatter) - 1/60 sec


InitAI:
        lda     #1
        sta     fScatter

        lda     #0
        sta     ModeCount
        jsr     SetModeClock

        ; Blinky
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
        sta     Blinky+Ghost::reverse
        lda     #<GetBlinkyTargetTile
        sta     Blinky+Ghost::get_target_tile
        lda     #>GetBlinkyTargetTile
        sta     Blinky+Ghost::get_target_tile+1
        lda     #$08
        sta     Blinky+Ghost::oam_offset
        lda     #$00
        sta     Blinky+Ghost::palette

        ; Pinky
        lda     #127
        sta     Pinky+Ghost::pos_x
        lda     #115
        sta     Pinky+Ghost::pos_y
        lda     #Direction::left
        sta     Pinky+Ghost::direction
        sta     Pinky+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Pinky+Ghost::state
        lda     #0
        sta     Pinky+Ghost::reverse
        lda     #<GetPinkyTargetTile
        sta     Pinky+Ghost::get_target_tile
        lda     #>GetPinkyTargetTile
        sta     Pinky+Ghost::get_target_tile+1
        lda     #$10
        sta     Pinky+Ghost::oam_offset
        lda     #$01
        sta     Pinky+Ghost::palette

        ; Inky
        lda     #111
        sta     Inky+Ghost::pos_x
        lda     #115
        sta     Inky+Ghost::pos_y
        lda     #Direction::left
        sta     Inky+Ghost::direction
        sta     Inky+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Inky+Ghost::state
        lda     #0
        sta     Inky+Ghost::reverse
        lda     #<GetInkyTargetTile
        sta     Inky+Ghost::get_target_tile
        lda     #>GetInkyTargetTile
        sta     Inky+Ghost::get_target_tile+1
        lda     #$18
        sta     Inky+Ghost::oam_offset
        lda     #$02
        sta     Inky+Ghost::palette

        ; Clyde
        lda     #143
        sta     Clyde+Ghost::pos_x
        lda     #115
        sta     Clyde+Ghost::pos_y
        lda     #Direction::left
        sta     Clyde+Ghost::direction
        sta     Clyde+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Clyde+Ghost::state
        lda     #0
        sta     Clyde+Ghost::reverse
        lda     #<GetClydeTargetTile
        sta     Clyde+Ghost::get_target_tile
        lda     #>GetClydeTargetTile
        sta     Clyde+Ghost::get_target_tile+1
        lda     #$20
        sta     Clyde+Ghost::oam_offset
        lda     #$03
        sta     Clyde+Ghost::palette

        rts

MoveGhosts:
        jsr     ModeClockTick
        lda     #<Blinky
        sta     GhostL
        lda     #>Blinky
        sta     GhostH
        jsr     MoveOneGhost
        lda     #<Pinky
        sta     GhostL
        lda     #>Pinky
        sta     GhostH
        jsr     MoveOneGhost
        lda     #<Inky
        sta     GhostL
        lda     #>Inky
        sta     GhostH
        jsr     MoveOneGhost
        lda     #<Clyde
        sta     GhostL
        lda     #>Clyde
        sta     GhostH
        jmp     MoveOneGhost

ModeClockTick:
        lda     ModeCount
        cmp     #7
        beq     @end                        ; only 7 mode changes
        lda     ModeClockL
        sub     #1
        sta     ModeClockL
        beq     @clock_lsb_zero
        lda     ModeClockH
        sbc     #0
        sta     ModeClockH
        rts
@clock_lsb_zero:
        lda     ModeClockH
        beq     @toggle_mode
        sbc     #0
        sta     ModeClockH
        rts
@toggle_mode:
        lda     fScatter
        eor     #$01
        sta     fScatter
        lda     #1
        sta     Blinky+Ghost::reverse
        sta     Pinky+Ghost::reverse
        sta     Inky+Ghost::reverse
        sta     Clyde+Ghost::reverse
        inc     ModeCount
        jsr     SetModeClock
@end:
        rts

SetModeClock:
        ; @TODO@ -- choose table based on level number
        lda     ModeCount
        asl
        tax
        lda     Lvl1Modes,x
        sta     ModeClockL
        inx
        lda     Lvl1Modes,x
        sta     ModeClockH
        rts

MoveOneGhost:
        ldy     #Ghost::direction 
        lda     (GhostL),y
        tax
        ldy     #Ghost::pos_x
        lda     (GhostL),y
        add     DeltaXTbl,x
        sta     (GhostL),y
        tay
        lsr
        lsr
        lsr
        sta     TileX
        tya
        and     #$07
        sta     PixelX
        ldy     #Ghost::pos_y
        lda     (GhostL),y
        add     DeltaYTbl,x
        sta     (GhostL),y
        tay
        lsr
        lsr
        lsr
        sta     TileY
        tya
        and     #$07
        sta     PixelY

        ; Needed since Inky's targeting depends on Blinky's position
        lda     TileX
        ldy     #Ghost::tile_x
        sta     (GhostL),y
        lda     TileY
        iny
        sta     (GhostL),y

        ; @TODO@ -- if TileX and TileY match Pac-Man's, kill Pac-Man

        ; JSR to Ghost::get_target_tile
        ldy     #Ghost::get_target_tile
        lda     (GhostL),y
        sta     JsrIndAddrL
        iny
        lda     (GhostL),y
        sta     JsrIndAddrH
        jsr     JsrInd

        ; If ghost is centered in tile, have it turn or reverse if necessary
        ; Then compute next turn
        lda     PixelX
        cmp     #$03
        bne     @not_centered
        lda     PixelY
        cmp     #$03
        bne     @not_centered
        ldy     #Ghost::reverse
        lda     (GhostL),y
        beq     @no_reverse
        ; Reversing direction
        lda     #0                          ; clear reverse flag
        sta     (GhostL),y
        ldy     #Ghost::direction
        lda     (GhostL),y
        eor     #$03
        jmp     @changed_direction
@no_reverse:
        ldy     #Ghost::turn_dir
        lda     (GhostL),y
@changed_direction:
        ldy     #Ghost::direction
        sta     (GhostL),y
        tax
        lda     TileX
        add     DeltaXTbl,x
        sta     NextTileX
        lda     TileY
        add     DeltaYTbl,x
        sta     NextTileY
        jsr     ComputeTurn
@not_centered:

        rts


GetBlinkyTargetTile:
        ; @TODO@ -- do not scatter while Elroy once Clyde has left house
        lda     fScatter
        bne     @scatter

        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY
        rts

@scatter:
        ; Go to upper right of the maze
        lda     #27
        sta     TargetTileX
        lda     #-3
        sta     TargetTileY
        rts


GetPinkyTargetTile:
        lda     fScatter
        bne     @scatter

        ldx     PacDirection
        lda     PacTileX
        add     DeltaX4Tbl,x
        sta     TargetTileX
        lda     PacTileY
        add     DeltaY4Tbl,x
        sta     TargetTileY
        rts

@scatter:
        ; Go to upper left corner of the maze
        lda     #4
        sta     TargetTileX
        lda     #-3
        sta     TargetTileY
        rts


GetInkyTargetTile:
        lda     fScatter
        bne     @scatter

        ; Target X is computed as follows:
        ; First, find the tile two tiles in front of Pac-Man.
        ; Let's call its X coordinate SubtargetX.
        ; TargetX = SubtargetX*2 - Blinky's X
        ; This is akin to drawing a line from Blinky to SubtargetX,
        ; then doubling the length of the line.
        ldx     PacDirection
        lda     PacTileX
        add     DeltaX2Tbl,x
        asl
        sub     Blinky+Ghost::tile_x
        sta     TargetTileX
        ; Target Y is computed the same way.
        lda     PacTileY
        add     DeltaY2Tbl,x
        asl
        sub     Blinky+Ghost::tile_y
        sta     TargetTileY
        rts

@scatter:
        ; Go to lower right corner of the maze
        lda     #29
        sta     TargetTileX
        lda     #32
        sta     TargetTileY
        rts


GetClydeTargetTile:
        lda     fScatter
        bne     @scatter

        lda     TileX
        sub     PacTileX
        bpl     @positive_x
        eor     #$ff
        add     #1
@positive_x:
        cmp     #9
        bge     @chase
        tax
        lda     SquareTbl,x
        tay                                 ; save square of horizontal distance
        lda     TileY
        sub     PacTileY
        bpl     @positive_y
        eor     #$ff
        add     #1
@positive_y:
        cmp     #9
        bge     @chase
        tax
        tya                                 ; get square of horizontal distance back
        add     SquareTbl,x
        ; A is now the square of the distance between Clyde and Pac-Man
        ; Retreat to corner if too close
        cmp     #65                         ; 8**2 = 64
        blt     @scatter
@chase:
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY
        rts

@scatter:
        ; Go to lower left corner of the maze
        lda     #2
        sta     TargetTileX
        lda     #32
        sta     TargetTileY
        rts


DeltaX2Tbl:
        .byte   -2                          ; left
        .byte   0                           ; up
        .byte   0                           ; down
        .byte   2                           ; right

DeltaY2Tbl:
        .byte   0                           ; left
        .byte   -2                          ; up
        .byte   2                           ; down
        .byte   0                           ; right

DeltaX4Tbl:
        .byte   -4                          ; left
        .byte   0                           ; up
        .byte   0                           ; down
        .byte   4                           ; right

DeltaY4Tbl:
        .byte   0                           ; left
        .byte   -4                          ; up
        .byte   4                           ; down
        .byte   0                           ; right

SquareTbl:
        .byte   0                           ; 0*0
        .byte   1                           ; 1*1
        .byte   4                           ; 2*2
        .byte   9                           ; 3*3
        .byte   16                          ; 4*4
        .byte   25                          ; 5*5
        .byte   36                          ; 6*6
        .byte   49                          ; 7*7
        .byte   64                          ; 8*8


ComputeTurn:
        ; Scores here will be $00..$ff, but think of $00 = -128, $01 = -127 ... $ff = 127
        ; This is called excess-128 representation (a form of excess-K, a.k.a. offset binary).
        ; This is done because signed comparisons suck on 6502.
        lda     #0
        sta     MaxScore
        lda     NextTileX
        sub     TargetTileX
        tax
        add     #$80
        sta     ScoreLeft
        txa
        eor     #$ff                        ; negate and add $80
        sec
        adc     #$80
        sta     ScoreRight
        lda     NextTileY
        sub     TargetTileY
        tax
        add     #$80
        sta     ScoreUp
        txa
        eor     #$ff
        sec
        adc     #$80
        sta     ScoreDown

        ; Will we be able to go up?
        ldy     #Ghost::direction           ; Disallow if going down
        lda     (GhostL),y
        cmp     #Direction::down
        beq     @no_up
        ldy     NextTileX
        ldx     NextTileY
        dex
        jsr     IsTileEnterable
        bne     @no_up
        lda     ScoreUp
        ;cmp     MaxScore
        ;blt     @no_up
        sta     MaxScore
        lda     #Direction::up
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
@no_up:
        ; Try left
        ldy     #Ghost::direction           ; Disallow if going right
        lda     (GhostL),y
        cmp     #Direction::right
        beq     @no_left
        ldy     NextTileX
        dey
        ldx     NextTileY
        jsr     IsTileEnterable
        bne     @no_left
        lda     ScoreLeft
        cmp     MaxScore
        blt     @no_left
        sta     MaxScore
        lda     #Direction::left
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
@no_left:
        ; Try down
        ldy     #Ghost::direction           ; Disallow if going up
        lda     (GhostL),y
        cmp     #Direction::up
        beq     @no_down
        ldy     NextTileX
        ldx     NextTileY
        inx
        jsr     IsTileEnterable
        bne     @no_down
        lda     ScoreDown
        cmp     MaxScore
        blt     @no_down
        sta     MaxScore
        lda     #Direction::down
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
@no_down:
        ; Try right
        ldy     #Ghost::direction           ; Disallow if going left
        lda     (GhostL),y
        cmp     #Direction::left
        beq     @no_right
        ldy     NextTileX
        iny
        ldx     NextTileY
        jsr     IsTileEnterable
        bne     @no_right
        lda     ScoreRight
        cmp     MaxScore
        blt     @no_right
        ;sta     MaxScore
        lda     #Direction::right
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
@no_right:
        rts


DrawGhosts:
        lda     #<Blinky
        sta     GhostL
        lda     #>Blinky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Pinky
        sta     GhostL
        lda     #>Pinky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Inky
        sta     GhostL
        lda     #>Inky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Clyde
        sta     GhostL
        lda     #>Clyde
        sta     GhostH
        jmp     DrawOneGhost

DrawOneGhost:
        ; Update ghost in OAM
        ldy     #Ghost::oam_offset
        lda     (GhostL),y
        sta     GhostOamL
        lda     #>MyOAM
        sta     GhostOamH

        ; Y position
        ldy     #Ghost::pos_y
        lda     (GhostL),y
        sub     #8
        sub     VScroll
        ldy     #0
        sta     (GhostOamL),y
        ldy     #4
        sta     (GhostOamL),y
        ; Pattern index
        ; Toggle between two frames
        lda     FrameCounter
        and     #$08
        beq     @first_frame                ; This will store $00 to TmpL
        lda     #$10                        ; Second frame is $10 tiles after frame
@first_frame:
        sta     TmpL
        ldy     #Ghost::turn_dir
        lda     (GhostL),y
        asl
        asl
        ora     #$01                        ; Use $1000 bank of VRAM
        add     TmpL
        ldy     #1
        sta     (GhostOamL),y
        add     #2
        ldy     #5
        sta     (GhostOamL),y
        ; Attributes
        ldy     #Ghost::palette
        lda     (GhostL),y
        ldy     #2
        sta     (GhostOamL),y
        ldy     #6
        sta     (GhostOamL),y
        ; X position
        ldy     #Ghost::pos_x
        lda     (GhostL),y
        sub     #7
        ldy     #3
        sta     (GhostOamL),y
        add     #8
        ldy     #7
        sta     (GhostOamL),y
        rts
