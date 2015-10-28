PacManOAM = MyOAM


.segment "ZEROPAGE"

PacX:               .res 1
PacY:               .res 1
PacTileX:           .res 1
PacTileY:           .res 1
PacDirection:       .res 1

PacTryX:            .res 1
PacTryY:            .res 1
PacTryTileX:        .res 1
PacTryTileY:        .res 1
PacTryDirection:    .res 1


.segment "CODE"

MovePacMan:
        ; Figure out direction we're trying to go in
        ; Upper four bits of joy state are directions
        lda     Joy1State
        lsr
        lsr
        lsr
        lsr
        bne     @change_dir
        ; Player didn't press a direction button
        ; Pac-Man will continue in same direction
        lda     PacDirection
        jmp     @no_change
@change_dir:
        tax
        lda     JoyDirTbl,x
@no_change:
        sta     PacTryDirection
        ; Now try to move
        tax
        lda     PacX
        add     DeltaXTbl,x
        sta     PacTryX
        lsr
        lsr
        lsr
        sta     PacTryTileX
        tay                                 ; Will be passed to IsTileEnterable
        lda     PacY
        add     DeltaYTbl,x
        sta     PacTryY
        lsr
        lsr
        lsr
        sta     PacTryTileY
        tax
        jsr     IsTileEnterable
        bne     @reject_move
        ; Move is OK; make it so
        lda     PacTryDirection
        sta     PacDirection
        lda     PacTryX
        sta     PacX
        lda     PacTryY
        sta     PacY
        lda     PacTryTileX
        sta     PacTileX
        lda     PacTryTileY
        sta     PacTileY
@reject_move:
        rts

JoyDirTbl:                                  ; RLDU (right, left, down, up)
        .byte   0                           ; 0000 (dummy entry)
        .byte   Direction::up               ; 0001
        .byte   Direction::down             ; 0010
        .byte   Direction::down             ; 0011
        .byte   Direction::left             ; 0100
        .byte   Direction::left             ; 0101
        .byte   Direction::left             ; 0110
        .byte   Direction::left             ; 0111
        .byte   Direction::right            ; 1000
        .byte   Direction::right            ; 1001
        .byte   Direction::right            ; 1010
        .byte   Direction::right            ; 1011
        .byte   Direction::right            ; 1100
        .byte   Direction::right            ; 1101
        .byte   Direction::right            ; 1110
        .byte   Direction::right            ; 1111


DrawPacMan:
        ; Y position
        lda     PacY
        sub     VScroll
        sub     #8
        sta     PacManOAM
        sta     PacManOAM+4
        ; Pattern index
        lda     #$81
        sta     PacManOAM+1
        lda     #$83
        sta     PacManOAM+5
        ; Attributes
        lda     #$03
        sta     PacManOAM+2
        sta     PacManOAM+6
        ; X position
        lda     PacX
        sub     #7
        sta     PacManOAM+3
        add     #8
        sta     PacManOAM+7
        rts
