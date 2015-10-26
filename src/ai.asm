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
        lda     Blinky+Ghost::pos_y
        add     DeltaYTbl,x
        sta     Blinky+Ghost::pos_y

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
