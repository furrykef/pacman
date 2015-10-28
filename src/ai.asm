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
        pla
        and     #$07
        sta     PixelY

        ; @TODO@ -- if TileX and TileY match Pac-Man's, kill Pac-Man

        ; *** TEST ***
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
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
        tax
        lda     TileX
        add     DeltaXTbl,x
        sta     NextTileX
        lda     TileY
        add     DeltaYTbl,x
        sta     NextTileY
        jsr     ComputeTurn
@not_centered:

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
        beq     :+                          ; This will store $00 to TmpL
        lda     #$10                        ; Second frame is $10 tiles after frame
:
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
        lda     Blinky+Ghost::direction     ; Disallow if going down
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
        sta     Blinky+Ghost::turn_dir
        jmp     @try_right
@no_up:
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
        cmp     MaxScore
        blt     @no_right
        sta     MaxScore
        lda     #Direction::right
        sta     Blinky+Ghost::turn_dir
        jmp     @try_down
@no_right:
@try_down:
        lda     Blinky+Ghost::direction     ; Disallow if going up
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
        sta     Blinky+Ghost::turn_dir
        jmp     @try_left
@no_down:
@try_left:
        lda     Blinky+Ghost::direction     ; Disallow if going right
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
        sta     Blinky+Ghost::turn_dir
@no_left:
        rts
