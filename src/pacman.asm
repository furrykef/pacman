PacManOAM = MyOAM


.segment "ZEROPAGE"

PacX:               .res 1
PacY:               .res 1
PacTileX:           .res 1
PacTileY:           .res 1
PacPixelX:          .res 1                  ; outside code should not rely on this
PacPixelY:          .res 1                  ; or this
PacDirection:       .res 1

PacTryX:            .res 1
PacTryY:            .res 1
PacTryTileX:        .res 1
PacTryTileY:        .res 1
PacTryPixelX:       .res 1
PacTryPixelY:       .res 1
PacTryDirection:    .res 1


.segment "CODE"

MovePacMan:
        ; @TODO@ -- move this somewhere more appropriate
        ; (We do this again at the end of the routine, but we also need good values before it)
        ; ***
        lda     PacX
        tax
        lsr
        lsr
        lsr
        sta     PacTileX
        txa
        and     #$07
        sta     PacPixelX
        lda     PacY
        tax
        lsr
        lsr
        lsr
        sta     PacTileY
        txa
        and     #$07
        sta     PacPixelY
        ; ***

        jsr     TryTurningPacMan

        ; Now try to move
        lda     PacDirection
        tax
        lda     PacX
        add     DeltaXTbl,x
        sta     PacTryX
        pha
        lsr
        lsr
        lsr
        sta     PacTryTileX
        tay                                 ; Will be passed to IsTileEnterable
        pla
        and     #$07
        sta     PacTryPixelX
        lda     PacY
        add     DeltaYTbl,x
        sta     PacTryY
        pha
        lsr
        lsr
        lsr
        sta     PacTryTileY
        tax                                 ; Will be passed to IsTileEnterable
        pla
        and     #$07
        sta     PacTryPixelY
        jsr     IsTileEnterable
        bne     @reject_move
        ; Move is OK; make it so
        lda     PacTryX
        sta     PacX
        lda     PacTryY
        sta     PacY
        lda     PacTryTileX
        sta     PacTileX
        lda     PacTryTileY
        sta     PacTileY
        lda     PacTryPixelX
        sta     PacPixelX
        lda     PacTryPixelY
        sta     PacPixelY
        jsr     MovePacManTowardCenter
@reject_move:
        rts


TryTurningPacMan:
; Figure out direction we're trying to go in
        ; Upper four bits of joy state are directions
        lda     Joy1State
        lsr
        lsr
        lsr
        lsr
        beq     @end                        ; no change if player pressed no button
        ; Player pressed direction button
        tax
        lda     JoyDirTbl,x
        ; Pac-Man can always reverse direction
        eor     #$03                        ; reverse direction to compare
        cmp     PacDirection
        php
        eor     #$03                        ; unreverse
        plp
        beq     @direction_set              ; Pac-Man will reverse direction
        ; Changing direction, but not reversing
        ; Only allow if Pac-Man isn't blocked by the next tile in that direction
        sta     PacTryDirection
        tax
        lda     PacTileX
        add     DeltaXTbl,x
        tay
        lda     PacTileY
        add     DeltaYTbl,x
        tax
        jsr     IsTileEnterable
        bne     @end                        ; reject turn if not enterable
        ; accept turn
        lda     PacTryDirection
@direction_set:
        sta     PacDirection
@end:
        rts

; Converts D-pad state to a direction
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


; Bumps Pac-Man toward center of his lane
; Does not update PacPixelX or PacPixelY
MovePacManTowardCenter:
        lda     PacDirection
        cmp     #Direction::up
        beq     @vertical
        cmp     #Direction::down
        beq     @vertical
        ; Moving horizontally; center vertically
        lda     PacPixelY
        ldx     PacY
        cmp     #3
        beq     @end
        blt     @shift_down
        dex
        stx     PacY
        jmp     @end
@shift_down:
        inx
        stx     PacY
        jmp     @end
@vertical:
        ; Moving vertically; center horizontally
        lda     PacPixelX
        ldx     PacX
        cmp     #3
        beq     @end
        blt     @shift_right
        dex
        stx     PacX
        jmp     @end
@shift_right:
        inx
        stx     PacX
@end:
        rts


DrawPacMan:
        ; Y position
        lda     PacY
        sub     #8
        sub     VScroll
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
