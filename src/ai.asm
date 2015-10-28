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
        palette         .byte
        get_target_tile .addr
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
        lda     #<GetBlinkyTargetTile
        sta     Blinky+Ghost::get_target_tile
        lda     #>GetBlinkyTargetTile
        sta     Blinky+Ghost::get_target_tile+1
        rts

MoveGhosts:
        lda     #<Blinky
        sta     GhostL
        lda     #>Blinky
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
        pha
        lsr
        lsr
        lsr
        sta     TileX
        pla
        and     #$07
        sta     PixelX
        ldy     #Ghost::pos_y
        lda     (GhostL),y
        add     DeltaYTbl,x
        sta     (GhostL),y
        pha
        lsr
        lsr
        lsr
        sta     TileY
        pla
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
        ; Update Blinky in OAM
        ; Y position
        lda     Blinky+Ghost::pos_y
        sub     VScroll
        sub     #8
        sta     MyOAM
        sta     MyOAM+4
        ; Pattern index
        ; Toggle between two frames
        lda     FrameCounter
        and     #$08
        beq     @first_frame                ; This will store $00 to TmpL
        lda     #$10                        ; Second frame is $10 tiles after frame
@first_frame:
        sta     TmpL
        lda     Blinky+Ghost::turn_dir
        asl
        asl
        ora     #$01                        ; Use $1000 bank of VRAM
        add     TmpL
        sta     MyOAM+1
        add     #2
        sta     MyOAM+5
        ; Attributes
        lda     #$00
        sta     MyOAM+2
        sta     MyOAM+6
        ; X position
        lda     Blinky+Ghost::pos_x
        sub     #7
        sta     MyOAM+3
        add     #8
        sta     MyOAM+7
        rts
