PacManOAM = MyOAM


.segment "ZEROPAGE"

PacX:               .res 1
PacY:               .res 1
PacTileX:           .res 1
PacTileY:           .res 1
PacPixelX:          .res 1
PacPixelY:          .res 1
PacDirection:       .res 1

PacTryDirection:    .res 1

PacDelay:           .res 1


.segment "CODE"

InitPacMan:
        lda     #127
        sta     PacX
        lda     #187
        sta     PacY
        jsr     CalcPacCoords
        lda     #WEST
        sta     PacDirection
        lda     #0
        sta     PacDelay
        rts


MovePacMan:
        dec     PacDelay
        bmi     @no_delay
        ; Delay Pac-Man
        rts
@no_delay:
        inc     PacDelay

        jsr     TryTurningPacMan

        ; Now try to move

        ; Move always OK if at tunnel edges
        lda     PacTileX
        beq     @accept_move
        cmp     #31
        beq     @accept_move

        ; Not in a tunnel
        ldx     PacDirection
        cpx     #NORTH
        beq     @vertical
        cpx     #SOUTH
        beq     @vertical
        ; Moving horizontally; check X coordinate
        lda     PacX
        jmp     @got_coord
@vertical:
        lda     PacY
@got_coord:
        and     #$07
        cmp     #3                          ; is Pac-Man at center of tile?
        bne     @accept_move                ; move is OK if not
        ; Reject the move if he's about to run into a wall
        lda     PacTileX
        add     DeltaXTbl,x                 ; X still holds Pac-Man's direction
        tay
        lda     PacTileY
        add     DeltaYTbl,x
        tax
        jsr     IsTileEnterable
        bne     @reject_move
        ; Move is OK; make it so
@accept_move:
        ldx     PacDirection
        lda     PacX
        add     DeltaXTbl,x
        sta     PacX
        lda     PacY
        add     DeltaYTbl,x
        sta     PacY
        jsr     MovePacManTowardCenter
        jsr     CalcPacCoords
        jsr     EatStuff
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
        jsr     GetTile
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
        .byte   NORTH                       ; 0001
        .byte   SOUTH                       ; 0010
        .byte   SOUTH                       ; 0011
        .byte   WEST                        ; 0100
        .byte   WEST                        ; 0101
        .byte   WEST                        ; 0110
        .byte   WEST                        ; 0111
        .byte   EAST                        ; 1000
        .byte   EAST                        ; 1001
        .byte   EAST                        ; 1010
        .byte   EAST                        ; 1011
        .byte   EAST                        ; 1100
        .byte   EAST                        ; 1101
        .byte   EAST                        ; 1110
        .byte   EAST                        ; 1111


; Bumps Pac-Man toward center of his lane
MovePacManTowardCenter:
        lda     PacDirection
        cmp     #NORTH
        beq     @vertical
        cmp     #SOUTH
        beq     @vertical
        ; Moving horizontally; center vertically
        lda     PacY
        and     #$07
        cmp     #3
        beq     @end
        blt     @shift_down
        dec     PacY
        rts
@shift_down:
        inc     PacY
        rts
@vertical:
        ; Moving vertically; center horizontally
        lda     PacX
        and     #$07
        cmp     #3
        beq     @end
        blt     @shift_right
        dec     PacX
        rts
@shift_right:
        inc     PacX
@end:
        rts


EatStuff:
        ldy     PacTileX
        ldx     PacTileY
        jsr     GetTile
        cmp     #DOT
        beq     @eat_dot
        cmp     #ENERGIZER
        beq     @eat_energizer
        rts

@eat_dot:
        lda     #1
        sta     PacDelay
        dec     NumDots
        lda     #<Points10
        sta     TmpL
        lda     #>Points10
        sta     TmpH
        tya
        pha
        jsr     AddPoints
        pla
        tay
        jmp     @eat_object

@eat_energizer:
        lda     #3
        sta     PacDelay
        dec     NumDots
        lda     #<Points50
        sta     TmpL
        lda     #>Points50
        sta     TmpH
        tya
        pha
        jsr     AddPoints
        jsr     StartEnergizer
        pla
        tay
        jmp     @eat_object

@eat_object:
        ; Remove object from maze
        lda     #SPACE
        sta     (RowAddrL),y

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
        lda     #SPACE                      ; space
        sta     DisplayList,x
        inx
        stx     DisplayListIndex
        rts


CalcPacCoords:
        lda     PacX
        lsr
        lsr
        lsr
        sta     PacTileX
        lda     PacX
        and     #$07
        sta     PacPixelX
        lda     PacY
        lsr
        lsr
        lsr
        sta     PacTileY
        lda     PacY
        and     #$07
        sta     PacPixelY
        rts


DrawPacMan:
        ; Y position
        lda     PacY
        add     #24                         ; -8 to convert center to edge, +32 for status area
        sub     VScroll
        sta     PacManOAM
        sta     PacManOAM+4

        ; Pattern index
        lda     PacDirection
        cmp     #WEST
        beq     @horizontal
        cmp     #EAST
        beq     @horizontal
        lda     PacPixelY
        jmp     :+
@horizontal:
        lda     PacPixelX
:
        and     #$06
        asl
        asl
        asl
        asl
        sta     TmpL
        lda     PacDirection
        asl
        asl
        ora     TmpL
        add     #$81
        sta     PacManOAM+1
        add     #2
        sta     PacManOAM+5

        ; Attributes
        lda     #$03
        ; Flip priority if Pac-Man is at edges of tunnel
        ldx     PacTileX
        cpx     #3
        blt     @flip
        cpx     #29
        blt     @no_flip
@flip:
        lda     #$23
@no_flip:

        sta     PacManOAM+2
        sta     PacManOAM+6

        ; X position
        lda     PacX
        sub     #7
        sta     PacManOAM+3
        add     #8
        sta     PacManOAM+7
        rts
