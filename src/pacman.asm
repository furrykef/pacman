PacManOAM = MyOAM


.segment "ZEROPAGE"

PacTileX:           .res 1
PacTileY:           .res 1
PacPixelX:          .res 1
PacPixelY:          .res 1
PacDirection:       .res 1

PacTryTileX:        .res 1
PacTryTileY:        .res 1
PacTryPixelX:       .res 1
PacTryPixelY:       .res 1
PacTryDirection:    .res 1

PacFrame:           .res 1                  ; used for animation; increments by $20


.segment "CODE"

InitPacMan:
        lda     #15
        sta     PacTileX
        lda     #7
        sta     PacPixelX
        lda     #23
        sta     PacTileY
        lda     #3
        sta     PacPixelY
        lda     #Direction::left
        sta     PacDirection
        lda     #0
        sta     PacFrame
        rts


MovePacMan:
        jsr     TryTurningPacMan

        ; Now try to move
        lda     PacTileX
        sta     PacTryTileX
        lda     PacTileY
        sta     PacTryTileY
        lda     PacPixelX
        sta     PacTryPixelX
        lda     PacPixelY
        sta     PacTryPixelY

        ldx     PacDirection
        lda     PacPixelX
        add     DeltaXTbl,x
        bmi     @dec_tile_x
        cmp     #$08
        beq     @inc_tile_x
        sta     PacTryPixelX
        jmp     @move_y
@dec_tile_x:
        dec     PacTryTileX
        lda     #7
        sta     PacTryPixelX
        jmp     @move_y
@inc_tile_x:
        inc     PacTryTileX
        lda     #0
        sta     PacTryPixelX
@move_y:
        lda     PacPixelY
        add     DeltaYTbl,x
        bmi     @dec_tile_y
        cmp     #$08
        beq     @inc_tile_y
        sta     PacTryPixelY
        jmp     @end_move
@dec_tile_y:
        dec     PacTryTileY
        lda     #7
        sta     PacTryPixelY
        jmp     @end_move
@inc_tile_y:
        inc     PacTryTileY
        lda     #0
        sta     PacTryPixelY
@end_move:

        ldy     PacTryTileX
        ldx     PacTryTileY
        jsr     IsTileEnterable
        bne     @reject_move
        ; Move is OK; make it so
        lda     PacTryTileX
        sta     PacTileX
        lda     PacTryTileY
        sta     PacTileY
        lda     PacTryPixelX
        sta     PacPixelX
        lda     PacTryPixelY
        sta     PacPixelY
        jsr     MovePacManTowardCenter

        jsr     EatDot
        jsr     AnimatePacMan
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
MovePacManTowardCenter:
        lda     PacDirection
        cmp     #Direction::up
        beq     @vertical
        cmp     #Direction::down
        beq     @vertical
        ; Moving horizontally; center vertically
        lda     PacPixelY
        cmp     #3
        beq     @end
        blt     @shift_down
        dec     PacPixelY
        rts
@shift_down:
        inc     PacPixelY
        rts
@vertical:
        ; Moving vertically; center horizontally
        lda     PacPixelX
        cmp     #3
        beq     @end
        blt     @shift_right
        dec     PacPixelX
        rts
@shift_right:
        inc     PacPixelX
@end:
        rts


EatDot:
        ; Draw space where Pac-Man is
        ldx     DisplayListIndex
        lda     #1
        sta     DisplayList,x               ; size of chunk
        inx
        lda     #0
        sta     TmpL
        lda     PacTileY
        asl
        rol     TmpL
        asl
        rol     TmpL
        asl
        rol     TmpL
        asl
        rol     TmpL
        asl
        rol     TmpL
        ora     PacTileX
        tay                                 ; this will be the LSB; keep for later
        lda     TmpL
        add     #$20                        ; first nametable
        sta     DisplayList,x               ; PPU address MSB
        inx
        tya
        sta     DisplayList,x               ; PPU address LSB
        inx
        lda     #$20                        ; space
        sta     DisplayList,x
        inx
        stx     DisplayListIndex
        rts


AnimatePacMan:
        lda     FrameCounter
        and     #$01
        beq     @end
        lda     PacFrame
        add     #$20
        and     #$7f
        sta     PacFrame
@end:
        rts


DrawPacMan:
        ; Y position
        lda     PacTileY
        asl
        asl
        asl
        ora     PacPixelY
        sub     #8
        sub     VScroll
        sta     PacManOAM
        sta     PacManOAM+4
        ; Pattern index
        lda     PacDirection
        asl
        asl
        add     PacFrame
        add     #$81
        sta     PacManOAM+1
        add     #2
        sta     PacManOAM+5
        ; Attributes
        lda     #$03
        sta     PacManOAM+2
        sta     PacManOAM+6
        ; X position
        lda     PacTileX
        asl
        asl
        asl
        ora     PacPixelX
        sub     #7
        sta     PacManOAM+3
        add     #8
        sta     PacManOAM+7
        rts
