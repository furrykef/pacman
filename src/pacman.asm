PacManOAM = MyOAM + 32


.segment "ZEROPAGE"

PacX:               .res 1
PacY:               .res 1
PacTileX:           .res 1
PacTileY:           .res 1
PacPixelX:          .res 1
PacPixelY:          .res 1
PacDirection:       .res 1
PacMoveCounter:     .res 1

PacTryDirection:    .res 1

PacDelay:           .res 1

fPacDead:           .res 1

PacBaseSpeed:       .res 1
PacEnergizerSpeed:  .res 1


.segment "CODE"


PacBaseSpeedTbl:
        .byte  Speed80
.repeat 3
        .byte  Speed90
.endrepeat
.repeat 16
        .byte  Speed100
.endrepeat
        .byte  Speed90

PacEnergizerSpeedTbl:
        .byte  Speed90
.repeat 3
        .byte  Speed95
.endrepeat
.repeat 16
        .byte  Speed100
.endrepeat
        .byte  Speed90


InitPacMan:
        lda     #127
        sta     PacX
        lda     #187
        sta     PacY
        jsr     CalcPacCoords
        lda     #WEST
        sta     PacDirection
        lda     #0
        sta     PacMoveCounter
        sta     PacDelay
        sta     fPacDead

        ldx     NumPlayer
        ldy     PlayersLevel
        cpy     #21
        blt     :+
        ldy     #20                         ; difficulty maxes out at level 21
:
        lda PacBaseSpeedTbl,y
        sta PacBaseSpeed
        lda PacEnergizerSpeedTbl,y
        sta PacEnergizerSpeed

        rts


MovePacMan:
        ; Do not move Pac-Man while he's eating a ghost
        lda     EatingGhostClock
        bne     @end

        ; ...or while eating a dot
        lda     PacDelay
        beq     @no_delay
        ; Delay Pac-Man
        dec     PacDelay
        rts
@no_delay:

        lda     PacBaseSpeed
        ldx     fEnergizerActive
        beq     @no_energizer
        lda     PacEnergizerSpeed
@no_energizer:
        pha                                 ; save speed for later
        AddSpeed PacMoveCounter
        bcc     :+
        jsr     MovePacManOneTick
:
        pla                                 ; get speed back
        AddSpeed PacMoveCounter
        bcc     @end
        bcs     MovePacManOneTick
@end:
        rts


MovePacManOneTick:
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
        lda     PacTileY
        add     DeltaYTbl,x                 ; X still holds Pac-Man's direction
        tay
        lda     PacTileX
        add     DeltaXTbl,x
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
        lda     JoyState
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
        lda     PacTileY
        add     DeltaYTbl,x
        tay
        lda     PacTileX
        add     DeltaXTbl,x
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


; Note: eating fruit is handled in fruit.asm
EatStuff:
        ; Check for dots or energizers
        ldx     PacTileX
        ldy     PacTileY
        jsr     GetTile
        cmp     #BMP_DOT
        beq     @eat_dot
        cmp     #BMP_ENERGIZER
        beq     @eat_energizer
        rts

@eat_dot:
        lda     #1
        sta     PacDelay
        lda     #<Points10
        sta     AL
        lda     #>Points10
        sta     AH
        tya
        pha
        jsr     AddPoints
        jsr     EatDot
        pla
        tay
        jmp     @eat_object

@eat_energizer:
        lda     #3
        sta     PacDelay
        lda     #<Points50
        sta     AL
        lda     #>Points50
        sta     AH
        tya
        pha
        jsr     AddPoints
        jsr     StartEnergizer
        jsr     EatDot
        pla
        tay
        ; FALL THROUGH to @eat_object

@eat_object:
        ldx     NumPlayer
        lda     PlayersNumDots,x
        and     #$01
        add     #1
        sta     SfxTMunchDot

        ; Remove object from maze
        ldx     PacTileX
        ldy     PacTileY
        lda     #BMP_EMPTY
        jsr     SetTile

        ; Draw space where Pac-Man is
        DlBegin
        DlAdd   #1

        ; Compute PPU address MSB
        lda     PacTileY
        lsr
        lsr
        lsr
        add     #$20                        ; first nametable
        DlAddA

        ; Compute PPU address LSB
        lda     PacTileY
        asl
        asl
        asl
        asl
        asl
        ora     PacTileX
        DlAddA

        DlAdd   #SPACE
        DlEnd
        rts


EatDot:
        ldx     NumPlayer
        dec     PlayersNumDots,x
        lda     PlayersNumDots,x
        cmp     #244 - 70
        beq     @fruit
        cmp     #244 - 170
        bne     @no_fruit
@fruit:
        jsr     SpawnFruit
@no_fruit:
        jmp     GhostHandleDot


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
        sta     SprY

        ; Pattern index
        ; If Pac-Man is eating a ghost, draw number of points
        lda     EatingGhostClock
        beq     @not_eating_ghost
        lda     EnergizerPoints
        asl
        asl
        add     #$4c
        sta     SprStartPattern
        jmp     @attributes
@not_eating_ghost:
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
        sta     AL
        lda     PacDirection
        asl
        asl
        ora     AL
        add     #$60
        sta     SprStartPattern

        ; Attributes
@attributes:
        ; Use palette 3 normally, palette 2 while displaying points
        lda     #$03
        ldx     EatingGhostClock
        beq     :+
        lda     #$02
:
        sta     SprAttrib

        lda     PacX
        sta     SprX

        ldy     #PacManOAM
        jmp     DrawSprite16x16


DoPacManDeathAnimation:
        ; Y position
        lda     PacY
        sta     SprY

        ; Pattern
        lda     #$a0
        sta     SprStartPattern

        ; Attributes
        lda     #$03
        sta     SprAttrib

        ; X position
        lda     PacX
        sta     SprX

        ldy     #PacManOAM
        jsr     DrawSprite16x16

        ldy     #30
        jsr     WaitFrames

        lda     #BGM_DYING
        sta     BGM

        lda     #$a4
@loop:
        sta     SprStartPattern
        pha
        ldy     #PacManOAM
        jsr     DrawSprite16x16
        ldy     #8
        jsr     WaitFrames
        pla
        add     #4
        cmp     #$c8
        bne     @loop

        ldx     #BGM_DYING2
        stx     BGM

@loop2:
        sta     SprStartPattern
        pha
        ldy     #PacManOAM
        jsr     DrawSprite16x16
        ldy     #8
        jsr     WaitFrames
        pla
        add     #4
        cmp     #$d4
        bne     @loop2

        ldy     #60
        jmp     WaitFrames
