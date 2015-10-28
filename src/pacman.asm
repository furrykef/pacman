PacManOAM = MyOAM + $10


.segment "ZEROPAGE"

PacX:           .res 1
PacY:           .res 1
PacTileX:       .res 1
PacTileY:       .res 1
PacPixelX:      .res 1
PacPixelY:      .res 1
PacDirection:   .res 1


.segment "CODE"

SetPacDirection:
        lda     Joy1State
        lsr
        lsr
        lsr
        lsr
        beq     @end
        tax
        lda     PacDirTbl,x
        sta     PacDirection
@end:
        rts

PacDirTbl:                                  ; RLDU (right, left, down, up)
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

MovePacMan:
        ldx     PacDirection
        lda     PacX
        add     DeltaXTbl,x
        sta     PacX
        pha
        lsr
        lsr
        lsr
        sta     PacTileX
        pla
        and     #$07
        sta     PacPixelX
        lda     PacY
        add     DeltaYTbl,x
        sta     PacY
        pha
        lsr
        lsr
        lsr
        sta     PacTileY
        pla
        and     #$07
        sta     PacPixelY
        rts


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
        lda     #0
        sta     PacManOAM+2
        sta     PacManOAM+6
        ; X position
        lda     PacX
        sub     #7
        sta     PacManOAM+3
        add     #8
        sta     PacManOAM+7
        rts
