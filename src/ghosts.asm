; In most code in this file, the X register is reserved for the ID of the
; ghost being operated on. If a routine uses the X register without first
; putting anything in it, that's what it is unless otherwise specified.
; These routines are expected to preserve the X register on exit as well.
; The variable GhostId remembers what X should be in case it needs to be
; clobbered temporarily.


.enum GhostState
        active
        being_eaten
        eaten
        waiting
        exiting
        entering
.endenum

; Order and indexes are significant
.enum
        BLINKY
        PINKY
        INKY
        CLYDE
        NUM_GHOSTS
.endenum


.segment "ZEROPAGE"

GhostId:        .res 1

; Each of these is a 4-byte array, one byte per ghost
GhostsPosX:         .res 4                  ; center of ghost, not upper left
GhostsPosY:         .res 4
GhostsTileX:        .res 4
GhostsTileY:        .res 4
GhostsDirection:    .res 4
GhostsTurnDir:      .res 4                  ; direction ghost has planned to turn in
GhostsMoveCounter:  .res 4
GhostsState:        .res 4
fGhostsScared:      .res 4
fGhostsReverse:     .res 4
GhostsDotCounter:   .res 4
GhostsPriority:     .res 4

GhostBaseSpeed:     .res 1
GhostScaredSpeed:   .res 1
GhostTunnelSpeed:   .res 1
GhostElroy1Speed:   .res 1
GhostElroy2Speed:   .res 1

TileX:          .res 1
TileY:          .res 1
PixelX:         .res 1
PixelY:         .res 1
NextTileX:      .res 1
NextTileY:      .res 1
TargetTileX:    .res 1
TargetTileY:    .res 1

MaxScore:       .res 1
Scores:
ScoreWest:      .res 1                      ; equiv. Scores+WEST
ScoreNorth:     .res 1
ScoreSouth:     .res 1
ScoreEast:      .res 1

fScatter:       .res 1
ModeClockL:     .res 1
ModeClockH:     .res 1
ModeCount:      .res 1

DotTimeout:     .res 1
DotClock:       .res 1
GhostGlobalDotCounter:  .res 1

EnergizerTimeoutL:  .res 1
EnergizerTimeoutH:  .res 1
EnergizerClockL:    .res 1
EnergizerClockH:    .res 1
fEnergizerActive:   .res 1

EnergizerPoints:    .res 1                  ; 0 = 200, 1 = 400...

EatingGhostClock:   .res 1

pModesL:            .res 1
pModesH:            .res 1
Elroy1Dots:         .res 1
Elroy2Dots:         .res 1

fClydeLeft:         .res 1
ElroyState:         .res 1

GhostAnim:          .res 1                  ; counter used to toggle between animation frames


.segment "CODE"

; Times are guessed based on Pac-Man Dossier
Lvl1Modes:
        .word   7*60                        ; 0 (scatter) - 7 secs
        .word   20*60                       ; 1 (chase) - 20 secs
        .word   7*60                        ; 2 (scatter) - 7 secs
        .word   20*60                       ; 3 (chase) - 20 secs
        .word   5*60                        ; 4 (scatter) - 5 secs
        .word   20*60                       ; 5 (chase) - 20 secs
        .word   5*60                        ; 6 (scatter) - 5 secs

Lvl2Modes:
        .word   7*60                        ; 0 (scatter) - 7 secs
        .word   20*60                       ; 1 (chase) - 20 secs
        .word   7*60                        ; 2 (scatter) - 7 secs
        .word   20*60                       ; 3 (chase) - 20 secs
        .word   5*60                        ; 4 (scatter) - 5 secs
        .word   1033*60                     ; 5 (chase) - 1033 secs
        .word   1                           ; 6 (scatter) - 1/60 sec

Lvl5Modes:
        .word   5*60                        ; 0 (scatter) - 5 secs
        .word   20*60                       ; 1 (chase) - 20 secs
        .word   5*60                        ; 2 (scatter) - 5 secs
        .word   20*60                       ; 3 (chase) - 20 secs
        .word   5*60                        ; 4 (scatter) - 5 secs
        .word   1037*60                     ; 5 (chase) - 1037 secs
        .word   1                           ; 6 (scatter) - 1/60 sec

ModesMetaTbl:
        .addr   Lvl1Modes
.repeat 3
        .addr   Lvl2Modes
.endrepeat
.repeat 15
        .addr   Lvl5Modes
.endrepeat

ElroyDotsTbl:
        ; Level 1   2   3   4   5   6   7   8   9   10  11  12  13  14  15   16   17   18   19
        .byte   20, 30, 40, 40, 40, 50, 50, 50, 60, 60, 60, 80, 80, 80, 100, 100, 100, 100, 120

EnergizerTimeoutTbl:
        ; Level 1     2     3     4     5     6     7     8     9     10    11    12    13    14    15    16    17 18    19
        .word   6*60, 5*60, 4*60, 3*60, 2*60, 5*60, 2*60, 2*60, 1*60, 5*60, 2*60, 1*60, 1*60, 3*60, 1*60, 1*60, 0, 1*60, 0

DotTimeoutTbl:
.repeat 4
        .byte   4*60
.endrepeat
.repeat 15
        .byte   3*60
.endrepeat


.macro MakeSpeedTbl lvl1speed, lvl2speed, lvl5speed
        .byte lvl1speed
.repeat 3
        .byte lvl2speed
.endrepeat
.repeat 15
        .byte lvl5speed
.endrepeat
.endmacro

GhostBaseSpeedTbl:
        MakeSpeedTbl Speed75, Speed85, Speed95

GhostScaredSpeedTbl:
        MakeSpeedTbl Speed50, Speed55, Speed60

GhostTunnelSpeedTbl:
        MakeSpeedTbl Speed40, Speed45, Speed50

GhostElroy1SpeedTbl:
        MakeSpeedTbl Speed80, Speed90, Speed100

GhostElroy2SpeedTbl:
        MakeSpeedTbl Speed85, Speed95, Speed105

;                           Blinky      Pinky       Inky        Clyde
;                           -------------------------------------------
GhostsStartX:       .byte   127,        127,        111,        143
GhostsStartY:       .byte   91,         115,        115,        115
GhostsStartDir:     .byte   WEST,       SOUTH,      NORTH,      NORTH
GhostsPalette:      .byte   0,          1,          2,          3


InitAI:
        lda     #1
        sta     fScatter

        ; Common vars
        ldx     #NUM_GHOSTS - 1
@loop:
        lda     GhostsStartX,x
        sta     GhostsPosX,x
        lsr
        lsr
        lsr
        sta     GhostsTileX,x
        lda     GhostsStartY,x
        sta     GhostsPosY,x
        lsr
        lsr
        lsr
        sta     GhostsTileY,x
        lda     GhostsStartDir,x
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        lda     #0
        sta     GhostsMoveCounter,x
        sta     GhostsDotCounter,x
        sta     fGhostsScared,x
        sta     fGhostsReverse,x
        lda     #GhostState::waiting
        sta     GhostsState,x
        txa
        sta     GhostsPriority,x
        dex
        bpl     @loop

        ; Blinky starts active
        lda     #GhostState::active
        sta     GhostsState+BLINKY

        lda     #0
        sta     EnergizerClockL
        sta     EnergizerClockH
        sta     EatingGhostClock
        sta     ElroyState
        sta     fClydeLeft

        lda     #32
        sta     GhostGlobalDotCounter

        ; Reset individual dot counters if global dot counter is not active
        lda     fDiedThisRound
        bne     @died
        lda     #0
        sta     GhostGlobalDotCounter       ; global dot counter only active when Pac-Man had died
@died:

        ; Set difficulty level based on level
        ldx     NumLevel
        cpx     #19                         ; ghost difficulty capped at 18 (level 19)
        blt     :+
        ldx     #18
:
        lda     ElroyDotsTbl,x
        sta     Elroy1Dots
        lsr
        sta     Elroy2Dots
        lda     DotTimeoutTbl,x
        sta     DotTimeout
        sta     DotClock

        lda     GhostBaseSpeedTbl,x
        sta     GhostBaseSpeed
        lda     GhostScaredSpeedTbl,x
        sta     GhostScaredSpeed
        lda     GhostTunnelSpeedTbl,x
        sta     GhostTunnelSpeed
        lda     GhostElroy1SpeedTbl,x
        sta     GhostElroy1Speed
        lda     GhostElroy2SpeedTbl,x
        sta     GhostElroy2Speed

        ; Inky and Clyde's dot counters depend on level
        cpx     #0
        beq     @level1
        cpx     #1
        bne     @end_dot_counters
        ; Level 2
        lda     #50 + 1
        sta     GhostsDotCounter+CLYDE
        bne     @end_dot_counters           ; always taken
@level1:
        lda     #30 + 1
        sta     GhostsDotCounter+INKY
        lda     #60 + 1
        sta     GhostsDotCounter+CLYDE
@end_dot_counters:

        txa
        asl                                 ; X will now point at 16-bit entries
        tax
        lda     EnergizerTimeoutTbl,x
        sta     EnergizerTimeoutL
        lda     EnergizerTimeoutTbl+1,x
        sta     EnergizerTimeoutH
        lda     ModesMetaTbl,x
        sta     pModesL
        lda     ModesMetaTbl+1,x
        sta     pModesH

        lda     #0
        sta     ModeCount
        jsr     SetModeClock

        rts


MoveGhosts:
        lda     EatingGhostClock
        bne     @eating_ghost
        jsr     ModeClockTick
        jsr     DotClockTick
        jsr     EnergizerClockTick
        inc     GhostAnim
@eating_ghost:

        ; Blinky never waits
        ; (can get in this state if global dot counter is active)
        lda     GhostsState+BLINKY
        cmp     #GhostState::waiting
        bne     @blinky_not_waiting
        lda     #GhostState::exiting
        sta     GhostsState+BLINKY
@blinky_not_waiting:

        ; Set fClydeLeft if Clyde left at any point
        ; (do not clear until end of life or round)
        lda     GhostsState+CLYDE
        cmp     #GhostState::waiting
        beq     @clyde_waiting
        lda     #1
        sta     fClydeLeft
@clyde_waiting:

        ; Set Blinky to "Cruise Elroy" mode if enough dots have been eaten
        ; Do not adjust for Elroy if Clyde never left house
        lda     fClydeLeft
        beq     @elroy_done
        lda     NumDots
        cmp     Elroy2Dots
        blt     @elroy2
        beq     @elroy2
        cmp     Elroy1Dots
        beq     @elroy1
        bge     @elroy_done
@elroy1:
        lda     #1
        sta     ElroyState
        bne     @elroy_done                 ; always taken
@elroy2:
        lda     #2
        sta     ElroyState
@elroy_done:

        ; Move the ghosts
        ldx     #NUM_GHOSTS - 1
@move_loop:
        stx     GhostId
        jsr     HandleOneGhost
        dex
        bpl     @move_loop

        rts


; Decrements ModeClock every tick and progresses to the next ghost mode
; (chase/scatter) when it hits zero.
ModeClockTick:
        ; Mode clock paused while energizer is active
        lda     fEnergizerActive
        bne     @end

        lda     ModeCount
        cmp     #7
        beq     @end                        ; only 7 mode changes
        lda     ModeClockL
        sub     #1
        sta     ModeClockL
        beq     @clock_lsb_zero
        dec_cc  ModeClockH
        rts
@clock_lsb_zero:
        lda     ModeClockH
        beq     @toggle_mode                ; branch if clock hit $0000
        sbc     #0
        sta     ModeClockH
        rts
@toggle_mode:
        lda     fScatter
        eor     #$01
        sta     fScatter
        lda     #1
        sta     fGhostsReverse+BLINKY
        sta     fGhostsReverse+PINKY
        sta     fGhostsReverse+INKY
        sta     fGhostsReverse+CLYDE
        inc     ModeCount
        jsr     SetModeClock
@end:
        rts


; Initialize ModeClock based on ModeCount.
SetModeClock:
        lda     ModeCount
        asl
        tay
        lda     (pModesL),y
        sta     ModeClockL
        iny
        lda     (pModesL),y
        sta     ModeClockH
        rts


; Decrements DotClock every frame and releases a ghost if it's zero.
; (Eating a dot resets the clock.)
DotClockTick:
        ldy     DotClock
        beq     @release_ghost
        dey
        sty     DotClock
        rts
@release_ghost:
        lda     DotTimeout
        sta     DotClock
        ldy     #GhostState::exiting
        lda     GhostsState+PINKY
        cmp     #GhostState::waiting
        beq     @release_pinky
        lda     GhostsState+INKY
        cmp     #GhostState::waiting
        beq     @release_inky
        lda     GhostsState+CLYDE
        cmp     #GhostState::waiting
        beq     @release_clyde
        rts
@release_pinky:
        sty     GhostsState+PINKY           ; GhostState::exiting
        rts
@release_inky:
        sty     GhostsState+INKY
        rts
@release_clyde:
        sty     GhostsState+CLYDE
        lda     #0
        sta     GhostGlobalDotCounter
        rts


EnergizerClockTick:
        lda     EnergizerClockL
        beq     @maybe_zero
        bne     @nonzero
@maybe_zero:
        ldy     EnergizerClockH
        beq     @zero
@nonzero:
        sub     #1
        sta     EnergizerClockL
        dec_cc  EnergizerClockH
        lda     #1
        sta     fEnergizerActive
        rts
@zero:
        lda     #0
        sta     fEnergizerActive
        sta     fGhostsScared+BLINKY
        sta     fGhostsScared+PINKY
        sta     fGhostsScared+INKY
        sta     fGhostsScared+CLYDE
        rts


; X = ghost ID (also in GhostId var) on entry and exit
HandleOneGhost:
        ; Ghost doesn't move while being eaten
        lda     GhostsState,x
        cmp     #GhostState::being_eaten
        beq     @being_eaten

        ; Only eaten ghosts move if another ghost is being eaten
        lda     EatingGhostClock
        beq     @can_move
        ; Another ghost is being eaten
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @can_move
        cmp     #GhostState::entering
        bne     @end                        ; we're not an eaten ghost
@can_move:

        ; Release ghost from ghost house if (all must apply):
        ; 1) Global dot counter is inactive
        lda     GhostGlobalDotCounter
        bne     @no_release
        ; 2) It is waiting in the ghost house
        lda     GhostsState,x
        cmp     #GhostState::waiting
        bne     @no_release
        ; 3) Its dot counter is zero
        lda     GhostsDotCounter,x
        bne     @no_release
        lda     #GhostState::exiting
        sta     GhostsState,x
@no_release:

        ; Need to check collisions both before and after moving the ghost.
        ; This will prevent the bug in the arcade version where Pac-Man may 
        ; sometimes pass through ghosts.
        jsr     CheckCollisions

        jsr     GetSpeed
        pha                                 ; save speed for later
        AddSpeedX GhostsMoveCounter
        bcc     :+
        jsr     MoveOneGhost
        jsr     CalcGhostCoords
:
        pla                                 ; get speed back
        AddSpeedX GhostsMoveCounter
        bcc     :+
        jsr     MoveOneGhost
        jsr     CalcGhostCoords
:

        jmp     CheckCollisions

@being_eaten:
        dec     EatingGhostClock
        bne     @end
        lda     #GhostState::eaten
        sta     GhostsState,x
@end:
        rts


; Output:
;   A = ghost's speed
GetSpeed:
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @eaten
        cmp     #GhostState::entering
        beq     @eaten
        cmp     #GhostState::waiting
        beq     @in_house
        cmp     #GhostState::exiting
        beq     @in_house
        lda     GhostsTileY,x
        cmp     #14
        bne     @not_in_tunnel
        lda     GhostsTileX,x
        cmp     #8
        blt     @in_tunnel
        cmp     #24
        bge     @in_tunnel
@not_in_tunnel:
        lda     fGhostsScared,x
        bne     @scared
        cpx     #BLINKY                     ; only Blinky has Elroy mode
        bne     @no_elroy
        lda     ElroyState
        beq     @no_elroy
        cmp     #1
        beq     @elroy1
        ; Elroy 2
        lda     GhostElroy2Speed
        rts
@elroy1:
        lda     GhostElroy1Speed
        rts
@no_elroy:
        ; No special conditions apply
        lda     GhostBaseSpeed
        rts
@eaten:
        lda     #SpeedMax
        rts
@in_house:
        lda     #Speed40
        rts
@in_tunnel:
        lda     GhostTunnelSpeed
        rts
@scared:
        lda     GhostScaredSpeed
        rts


CheckCollisions:
        lda     GhostsTileX,x
        cmp     PacTileX
        bne     @no_collision
        lda     GhostsTileY,x
        cmp     PacTileY
        bne     @no_collision
        ; Collided
        ; Ignore collision if this ghost is being or has been eaten
        lda     GhostsState,x
        cmp     #GhostState::being_eaten
        beq     @no_collision
        cmp     #GhostState::eaten
        beq     @no_collision
        cmp     #GhostState::entering
        beq     @no_collision
        ; Ghost gets eaten if scared
        lda     fGhostsScared,x
        bne     @scared
        ; Kill Pac-Man
        lda     #1
        sta     fPacDead
        rts
@scared:
        ; Get eaten
        lda     #0
        sta     fGhostsScared,x
        lda     #GhostState::being_eaten
        sta     GhostsState,x
        sta     fSfxTEatingGhost
        lda     #48
        sta     EatingGhostClock
        lda     EnergizerPoints
        asl                                 ; 16-bit entries
        tay
        lda     EnergizerPtsTbl,y
        sta     AL
        lda     EnergizerPtsTbl+1,y
        sta     AH
        jsr     AddPoints
        ldx     GhostId                     ; AddPoints can clobber X
        inc     EnergizerPoints
@no_collision:
        rts

EnergizerPtsTbl:
        .addr   Points200
        .addr   Points400
        .addr   Points800
        .addr   Points1600


MoveOneGhost:
        lda     GhostsState,x
        cmp     #GhostState::waiting
        beq     @waiting
        cmp     #GhostState::eaten
        beq     @eaten
        cmp     #GhostState::exiting
        beq     @exiting
        cmp     #GhostState::entering
        beq     @entering
        jmp     MoveOneGhostNormal
@eaten:
        jmp     MoveOneGhostEaten
@waiting:
        jmp     MoveOneGhostWaiting
@exiting:
        jmp     MoveOneGhostExiting
@entering:
        jmp     MoveOneGhostEntering


MoveOneGhostWaiting:
        ldy     GhostsDirection,x
        lda     DeltaYTbl,y
        add     GhostsPosY,x
        sta     GhostsPosY,x
        cmp     #111
        beq     @reverse
        cmp     #119
        beq     @reverse
        rts
@reverse:
        lda     GhostsDirection,x
        eor     #$03
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        rts


MoveOneGhostEaten:
        jsr     MoveOneGhostNormal
        lda     GhostsPosX,x
        cmp     #127
        bne     @not_above_house
        lda     GhostsPosY,x
        cmp     #91
        bne     @not_above_house
        lda     #GhostState::entering
        sta     GhostsState,x
@not_above_house:
        rts


MoveOneGhostExiting:
        lda     GhostsPosX,x
        cmp     #127
        blt     @move_east
        beq     @move_north
        ; Move west
        lda     #WEST
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        ldy     GhostsPosX,x
        dey
        sty     GhostsPosX,x
        rts

@move_east:
        lda     #EAST
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        ldy     GhostsPosX,x
        iny
        sty     GhostsPosX,x
        rts

@move_north:
        lda     #NORTH
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        ldy     GhostsPosY,x
        dey
        sty     GhostsPosY,x
        cpy     #91
        beq     @exited
        rts
@exited:
        lda     #WEST
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        lda     #GhostState::active
        sta     GhostsState,x
        rts


MoveOneGhostEntering:
        lda     #SOUTH
        sta     GhostsDirection,x
        sta     GhostsTurnDir,x
        lda     GhostsPosY,x
        cmp     #115
        blt     @move_south
        ; In vertical position
        lda     GhostsStartX,x
        sta     AL
        lda     GhostsPosX,x
        cmp     AL
        beq     @ready
        blt     @move_east
        ; Move west
        sub     #1
        sta     GhostsPosX,x
        rts
@move_south:
        add     #1
        sta     GhostsPosY,x
        rts
@move_east:
        add     #1
        sta     GhostsPosX,x
        rts
@ready:
        lda     #GhostState::waiting
        sta     GhostsState,x
        ; Clear energizer status if no scared ghosts are left
        ; (stops energizer BGM)
        ldy     #3
@loop:
        lda     fGhostsScared,y
        bne     @at_least_one_scared_ghost
        dey
        bpl     @loop
        ; No scared ghosts left
        lda     #0
        sta     EnergizerClockL
        sta     EnergizerClockH
        sta     fEnergizerActive
@at_least_one_scared_ghost:
        rts


MoveOneGhostNormal:
        ldy     GhostsDirection,x
        lda     GhostsPosX,x
        add     DeltaXTbl,y
        sta     GhostsPosX,x
        lda     GhostsPosY,x
        add     DeltaYTbl,y
        sta     GhostsPosY,x

        jsr     CalcGhostCoords

        lda     GhostsState,x
        cmp     #GhostState::eaten
        bne     @not_eaten
        ; Eaten; target tile is (15, 11)
        lda     #15
        sta     TargetTileX
        lda     #11
        sta     TargetTileY
        bne     @got_target                 ; always taken
@not_eaten:
        ; JSR to Get[Ghost]TargetTile
        lda     GetTargetTileLTbl,x
        sta     JsrIndAddrL
        lda     GetTargetTileHTbl,x
        sta     JsrIndAddrH
        jsr     JsrInd
@got_target:

        ; If ghost is centered in tile, have it turn or reverse if necessary
        ; Then compute next turn
        lda     PixelX
        cmp     #$03
        bne     @not_centered
        lda     PixelY
        cmp     #$03
        bne     @not_centered
        lda     fGhostsReverse,x
        beq     @no_reverse
        ; Reversing direction
        lda     #0
        sta     fGhostsReverse,x
        lda     GhostsDirection,x
        eor     #$03
        bpl     @changed_direction          ; always taken
@no_reverse:
        lda     GhostsTurnDir,x
@changed_direction:
        sta     GhostsDirection,x
        tay
        lda     TileX
        add     DeltaXTbl,y
        sta     NextTileX
        lda     TileY
        add     DeltaYTbl,y
        sta     NextTileY
        jsr     ComputeTurn
@not_centered:

        rts


GetBlinkyTargetTile:
        ; Blinky never scatters while Elroy
        lda     ElroyState
        bne     @chase

        lda     fScatter
        bne     @scatter

@chase:
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY
        rts

@scatter:
        ; Go to northeast of the maze
        lda     #27
        sta     TargetTileX
        lda     #-3
        sta     TargetTileY
        rts


GetPinkyTargetTile:
        lda     fScatter
        bne     @scatter

        ldy     PacDirection
        lda     PacTileX
        add     DeltaX4Tbl,y
        sta     TargetTileX
        lda     PacTileY
        add     DeltaY4Tbl,y
        sta     TargetTileY
        rts

@scatter:
        ; Go to northwest corner of the maze
        lda     #4
        sta     TargetTileX
        lda     #-3
        sta     TargetTileY
        rts


GetInkyTargetTile:
        lda     fScatter
        bne     @scatter

        ; Target X is computed as follows:
        ; First, find the tile two tiles in front of Pac-Man.
        ; Let's call its X coordinate SubtargetX.
        ; TargetX = SubtargetX*2 - Blinky's X
        ; This is akin to drawing a line from Blinky to SubtargetX,
        ; then doubling the length of the line.
        ldy     PacDirection
        lda     PacTileX
        add     DeltaX2Tbl,y
        asl
        sub     GhostsTileX+BLINKY
        sta     TargetTileX
        ; Target Y is computed the same way.
        lda     PacTileY
        add     DeltaY2Tbl,y
        asl
        sub     GhostsTileY+BLINKY
        sta     TargetTileY
        rts

@scatter:
        ; Go to southeast corner of the maze
        lda     #29
        sta     TargetTileX
        lda     #32
        sta     TargetTileY
        rts


GetClydeTargetTile:
        lda     fScatter
        bne     @scatter

        lda     TileX
        sub     PacTileX
        bpl     @positive_x                 ; we want the absolute value
        eor     #$ff
        add     #1
@positive_x:
        cmp     #8
        bge     @chase                      ; chase if too far away
        tax
        lda     SquareTbl,x
        tay                                 ; save square of horizontal distance
        lda     TileY
        sub     PacTileY
        bpl     @positive_y                 ; absolute value again
        eor     #$ff
        add     #1
@positive_y:
        cmp     #8
        bge     @chase                      ; chase if too far away
        tax
        tya                                 ; get square of horizontal distance back
        add     SquareTbl,x
        ; A is now the square of the distance between Clyde and Pac-Man
        ; Retreat to corner if too close
        cmp     #64                         ; 8**2
        blt     @scatter
@chase:
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY

        ldx     GhostId
        rts

@scatter:
        ; Go to southwest corner of the maze
        lda     #2
        sta     TargetTileX
        lda     #32
        sta     TargetTileY

        ldx     GhostId
        rts


GetTargetTileLTbl:      .byte <GetBlinkyTargetTile, <GetPinkyTargetTile, <GetInkyTargetTile, <GetClydeTargetTile
GetTargetTileHTbl:      .byte >GetBlinkyTargetTile, >GetPinkyTargetTile, >GetInkyTargetTile, >GetClydeTargetTile


DeltaX2Tbl:
        .byte   -2                          ; west
        .byte   0                           ; north
        .byte   0                           ; south
        .byte   2                           ; east

DeltaY2Tbl:
        .byte   0                           ; west
        .byte   -2                          ; north
        .byte   2                           ; south
        .byte   0                           ; east

DeltaX4Tbl:
        .byte   -4                          ; west
        .byte   0                           ; north
        .byte   0                           ; south
        .byte   4                           ; east

DeltaY4Tbl:
        .byte   0                           ; west
        .byte   -4                          ; north
        .byte   4                           ; south
        .byte   0                           ; east

SquareTbl:
.repeat 8, I
        .byte   I*I
.endrepeat


ComputeTurn:
        ; First check if we're at the edges of the tunnels, and reject turn if so
        lda     TileX
        cmp     #2
        blt     @at_edge
        cmp     #30
        blt     @not_at_edge
@at_edge:
        rts
@not_at_edge:

        jsr     ComputeScores
        ; Order is significant for replicating behavior of arcade Pac-Man
        lda     #NORTH
        jsr     EvalDirection
        lda     #WEST
        jsr     EvalDirection
        lda     #SOUTH
        jsr     EvalDirection
        lda     #EAST
        ; FALL THROUGH to EvalDirection

; Input:
;   A = direction to evaluate
EvalDirection:
        sta     AL                          ; keep direction for later
        eor     #$03                        ; get opposite direction
        cmp     GhostsDirection,x           ; is this ghost trying to reverse direction?
        beq     @end                        ; disallow if so
        eor     #$03                        ; put original direction back in A
        ldy     NextTileX
        cmp     #WEST
        bne     :+
        dey
:
        cmp     #EAST
        bne     :+
        iny
:
        ldx     NextTileY                   ; clobber X; it'll be restored later
        cmp     #NORTH
        bne     :+
        dex
:
        cmp     #SOUTH
        bne     :+
        inx
:
        jsr     GetTile
        jsr     IsTileEnterable
        php
        ldx     GhostId                     ; restore X
        plp
        bne     @end                        ; skip to end if tile not enterable
        ldy     AL                          ; put direction in Y
        lda     Scores,y
        cmp     MaxScore
        blt     @end
        beq     @end
        sta     MaxScore
        sty     GhostsTurnDir,x
@end:
        rts


ComputeScores:
        lda     #0
        sta     MaxScore

        lda     fGhostsScared,x
        bne     @random

        ; Scores here will be $00..$ff, but think of $00 = -128, $01 = -127 ... $ff = 127
        ; This is called excess-128 representation (a form of excess-K, a.k.a. offset binary).
        ; This is done because signed comparisons suck on 6502.
        lda     NextTileX
        sub     TargetTileX
        tay
        add     #$80
        sta     ScoreWest
        tya
        eor     #$ff                        ; negate and add $80
        sec
        adc     #$80
        sta     ScoreEast
        lda     NextTileY
        sub     TargetTileY
        tay
        add     #$80
        sta     ScoreNorth
        tya
        eor     #$ff
        sec
        adc     #$80
        sta     ScoreSouth

        ; Ban northward turns in certain regions of the maze
        lda     GhostsTileY,x
        cmp     #11
        beq     @maybe_restricted
        cmp     #23
        beq     @maybe_restricted
        bne     @north_ok
@maybe_restricted:
        lda     GhostsTileX,x
        cmp     #13
        blt     @north_ok
        cmp     #18 + 1
        bge     @north_ok
        ; Ghost is in restricted zone
        lda     #0
        sta     ScoreNorth
@north_ok:
        rts

@random:
        ; Scared ghosts move randomly
        ldy     #3
@gen_random_scores:
        jsr     Rand
        ldx     GhostId                     ; Rand can clobber X
        ; Don't allow a score of 0 (reserved for invalid directions)
        cmp     #0
        bne     :+
        lda     #1
:
        sta     Scores,y
        dey
        bpl     @gen_random_scores

        rts


StartEnergizer:
        ; All non-eaten ghosts become scared and reverse direction
        ldx     #NUM_GHOSTS - 1
@loop:
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @skip
        cmp     #GhostState::entering
        beq     @skip
        lda     #1
        sta     fGhostsReverse,x
        sta     fGhostsScared,x
@skip:
        dex
        bpl     @loop

        lda     EnergizerTimeoutL
        sta     EnergizerClockL
        lda     EnergizerTimeoutH
        sta     EnergizerClockH
        lda     #0
        sta     EnergizerPoints
        rts


; Input:
;   A = global dot counter (won't be changed)
.macro TestGlobalDotCounter ghost, count
.local @end
        cmp     #32 - count
        bne     @end
        ldy     GhostsState+ghost
        cpy     #GhostState::waiting
        bne     @end
        ldy     #GhostState::exiting
        sty     GhostsState+ghost
@end:
.endmacro

GhostHandleDot:
        lda     DotTimeout
        sta     DotClock

        lda     GhostGlobalDotCounter
        beq     @individual_counters
        ; Use individual counters if Clyde is out and about
        ldy     GhostsState+CLYDE
        cpy     #GhostState::waiting
        bne     @individual_counters
        ; Using global dot counter
        sub     #1
        sta     GhostGlobalDotCounter
        TestGlobalDotCounter PINKY, 7
        TestGlobalDotCounter INKY, 17
        rts

@individual_counters:
        ; Individual dot counters
        lda     GhostsState+INKY
        cmp     #GhostState::waiting
        bne     @try_clyde
        ; Inky is waiting
        lda     GhostsDotCounter+INKY
        beq     @end
        dec     GhostsDotCounter+INKY
        rts
@try_clyde:
        lda     GhostsState+CLYDE
        cmp     #GhostState::waiting
        bne     @end
        ; Clyde is waiting
        lda     GhostsDotCounter+CLYDE
        beq     @end
        dec     GhostsDotCounter+CLYDE
@end:
        rts


; Ghost ID is in X (will be preserved)
CalcGhostCoords:
        lda     GhostsPosX,x
        tay
        lsr
        lsr
        lsr
        sta     TileX
        sta     GhostsTileX,x
        tya
        and     #$07
        sta     PixelX

        lda     GhostsPosY,x
        tay
        lsr
        lsr
        lsr
        sta     TileY
        sta     GhostsTileY,x
        tya
        and     #$07
        sta     PixelY

        rts


DrawGhosts:
        jsr     CheckSpriteOverflow
        bcc     @no_overflow

        ; More than 8 hardware sprites/scanline on previous frame; cycle priorities
        ldx     #NUM_GHOSTS - 1
@priority_loop:
        lda     GhostsPriority,x
        add     #1
        and     #$03
        sta     GhostsPriority,x
        dex
        bpl     @priority_loop

@no_overflow:
        ldx     #NUM_GHOSTS - 1
@draw_loop:
        stx     GhostId
        jsr     DrawOneGhost
        ldx     GhostId                     ; DrawOneGhost can clobber this
        dex
        bpl     @draw_loop

        rts

; Input:
;   X = GhostId
DrawOneGhost:
        ; Calculate OAM address for this ghost
        lda     GhostsPriority,x
        asl
        asl
        asl
        asl
        add     #40
        sta     OamPtrL

        ; Don't draw ghost if it's being eaten
        lda     GhostsState,x
        cmp     #GhostState::being_eaten
        bne     @not_being_eaten
        jmp     HideSprite16x16
@not_being_eaten:

        ; Y position
        lda     GhostsPosY,x
        sta     SprY

        ; Pattern index
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @eaten
        cmp     #GhostState::entering
        bne     @not_eaten
@eaten:
        ; Ghost has been eaten
        lda     #$40
        bne     @first_frame                ; always taken
@not_eaten:
        ; Toggle between two frames
        lda     GhostAnim
        and     #$08
        beq     @first_frame                ; This will store $00 to AL
        lda     #$10                        ; Second frame is $10 tiles after first frame
@first_frame:
        sta     AL
        lda     fGhostsScared,x
        bne     @scared
        ; Ghost is not scared
        lda     GhostsTurnDir,x
        asl
        asl
        bcc     @store_pattern              ; always taken
@scared:
        lda     EnergizerClockH
        bne     @scared_blue
        lda     EnergizerClockL
        cmp     #120 + 1
        bge     @scared_blue
        and     #%00010000
        beq     @scared_blue
        ; Ghost is flashing white
        lda     #$24
        bne     @store_pattern              ; always taken
@scared_blue:
        lda     #$20
@store_pattern:
        add     AL
        sta     SprStartPattern

        ; Attributes
        ; Scared ghosts use palette 0
        lda     fGhostsScared,x
        bne     @scared2
        lda     GhostsPalette,x
        jmp     @got_palette
@scared2:
        lda     #0
@got_palette:
        sta     SprAttrib

        ; X position
        lda     GhostsPosX,x
        sta     SprX

        jmp     DrawSprite16x16


; Check if Pac-Man and all four ghosts are on a line
;
; Output:
;   carry = set on overflow
CheckSpriteOverflow:
        ldx     #3
@loop:
        lda     GhostsPosY,x
        add     #16
        bcc     :+
        lda     #$ff                        ; clamp to range
:
        cmp     PacY
        blt     @nope                       ; branch if ghost entirely above Pac-Man

        lda     GhostsPosY,x                ; in case A got clamped
        sub     #15
        bcs     :+
        lda     #0                          ; clamp to range
:
        cmp     PacY
        bge     @nope                       ;  branch if ghost entirely below Pac-Man

        ; Ghost is in line with Pac-Man
        dex
        bpl     @loop

        ; All four ghosts in line with Pac-Man
        ; Sprite overflow
        sec
        rts

@nope:
        clc
        rts
