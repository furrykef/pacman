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
        direction       .byte
        turn_dir        .byte               ; direction ghost has planned to turn in
        speed           .byte
        state           .byte
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


.segment "CODE"

InitAI:
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
        lda     #<GetPinkyTargetTile
        sta     Pinky+Ghost::get_target_tile
        lda     #>GetPinkyTargetTile
        sta     Pinky+Ghost::get_target_tile+1
        lda     #$10
        sta     Pinky+Ghost::oam_offset
        lda     #$01
        sta     Pinky+Ghost::palette

        ; Inky
        lda     #127
        sta     Inky+Ghost::pos_x
        lda     #115
        sta     Inky+Ghost::pos_y
        lda     #Direction::left
        sta     Inky+Ghost::direction
        sta     Inky+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Inky+Ghost::state
        lda     #<GetInkyTargetTile
        sta     Inky+Ghost::get_target_tile
        lda     #>GetInkyTargetTile
        sta     Inky+Ghost::get_target_tile+1
        lda     #$18
        sta     Inky+Ghost::oam_offset
        lda     #$02
        sta     Inky+Ghost::palette

        ; Clyde
        lda     #127
        sta     Clyde+Ghost::pos_x
        lda     #115
        sta     Clyde+Ghost::pos_y
        lda     #Direction::left
        sta     Clyde+Ghost::direction
        sta     Clyde+Ghost::turn_dir
        ; @TODO@ -- speed
        lda     #GhostState::active
        sta     Clyde+Ghost::state
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

        ; @TODO@ -- if TileX and TileY match Pac-Man's, kill Pac-Man

        ; JSR to Ghost::get_target_tile
        ldy     #Ghost::get_target_tile
        lda     (GhostL),y
        sta     JsrIndAddrL
        iny
        lda     (GhostL),y
        sta     JsrIndAddrH
        jsr     JsrInd

        ; If ghost is centered in tile, have it turn if necessary
        ; and compute next turn
        lda     PixelX
        cmp     #$03
        bne     @not_centered
        lda     PixelY
        cmp     #$03
        bne     @not_centered
        ldy     #Ghost::turn_dir
        lda     (GhostL),y
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
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY
        rts

GetPinkyTargetTile:
        ldx     PacDirection
        lda     PacTileX
        add     DeltaX4Tbl,x
        sta     TargetTileX
        lda     PacTileY
        add     DeltaY4Tbl,x
        sta     TargetTileY
        rts

GetInkyTargetTile:
        lda     #0
        sta     TargetTileX
        sta     TargetTileY
        rts

GetClydeTargetTile:
        lda     #31
        sta     TargetTileX
        lda     #0
        sta     TargetTileY
        rts

DeltaX4Tbl:
        .byte   -4                          ; left
        .byte   4                           ; right
        .byte   0                           ; up
        .byte   0                           ; down

DeltaY4Tbl:
        .byte   0                           ; left
        .byte   0                           ; right
        .byte   -4                          ; up
        .byte   4                           ; down


ComputeTurn:
        ; Scores here will be 0..255, but think of 0 = -128, 1 = -127 ... 255 = 127
        ; (signed comparisons suck on the 6502)
        lda     #0
        sta     MaxScore
        lda     NextTileX
        sub     TargetTileX
        sta     ScoreRight
        add     #$80
        sta     ScoreLeft
        lda     NextTileY
        sub     TargetTileY
        sta     ScoreDown
        add     #$80
        sta     ScoreUp

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
        sta     MaxScore
        lda     #Direction::up
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
        jmp     @try_right
@no_up:
@try_right:
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
        sta     MaxScore
        lda     #Direction::right
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
        jmp     @try_down
@no_right:
@try_down:
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
        jmp     @try_left
@no_down:
@try_left:
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
        ;sta     MaxScore
        lda     #Direction::left
        ldy     #Ghost::turn_dir
        sta     (GhostL),y
@no_left:
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
