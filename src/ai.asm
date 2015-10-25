.enum Direction
        left
        right
        up
        down
.endenum

.enum GhostState
        active
        scared
        eaten
        waiting
        exiting
.endenum


.struct Ghost
        pos_x       .byte
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

TileID:         .res 1
PixelOffset:    .res 1


.segment "CODE"

InitAI:
        lda     #128
        sta     Blinky+Ghost::pos_x
        lda     #83
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
        lda     Blinky+Ghost::pos_x
        sub     #1
        sta     Blinky+Ghost::pos_x
        pha
        lsr
        lsr
        lsr
        sta     TileID
        pla
        and     #$07
        sta     PixelOffset
        ; @XXX@
        lda     Blinky+Ghost::pos_y
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
        sta     MyOAM+3
        add     #8
        sta     MyOAM+7
        rts
