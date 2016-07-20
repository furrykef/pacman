.enum GhostState
        active
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


.struct GhostSpeeds
        Speed1          .byte
        Speed2          .byte
        Speed3          .byte
        Speed4          .byte
        WaitingSpeed1   .byte
        WaitingSpeed2   .byte
        WaitingSpeed3   .byte
        WaitingSpeed4   .byte
        TunnelSpeed1    .byte
        TunnelSpeed2    .byte
        TunnelSpeed3    .byte
        TunnelSpeed4    .byte
        ScaredSpeed1    .byte
        ScaredSpeed2    .byte
        ScaredSpeed3    .byte
        ScaredSpeed4    .byte
        EatenSpeed1     .byte
        EatenSpeed2     .byte
        EatenSpeed3     .byte
        EatenSpeed4     .byte
.endstruct


.segment "ZEROPAGE"

BlinkySpeeds:   .tag GhostSpeeds
PinkySpeeds:    .tag GhostSpeeds
InkySpeeds:     .tag GhostSpeeds
ClydeSpeeds:    .tag GhostSpeeds

GhostId:        .res 1

; Each of these is a 4-byte array, one byte per ghost
GhostsPosX:         .res 4                  ; center of ghost, not upper left
GhostsPosY:         .res 4
GhostsTileX:        .res 4
GhostsTileY:        .res 4
GhostsHomeX:        .res 4                  ; @TODO@ -- doesn't need to be in RAM
GhostsDirection:    .res 4
GhostsTurnDir:      .res 4                  ; direction ghost has planned to turn in
GhostsState:        .res 4
fGhostsScared:      .res 4
fGhostsReverse:     .res 4
fGhostsBeingEaten:  .res 4
GhostsDotCounter:   .res 4
GhostsPriority:     .res 4
GhostsPalette:      .res 4                  ; @TODO@ -- doesn't need to be in RAM

TileX:          .res 1
TileY:          .res 1
PixelX:         .res 1
PixelY:         .res 1
NextTileX:      .res 1
NextTileY:      .res 1
TargetTileX:    .res 1
TargetTileY:    .res 1

MaxScore:       .res 1
ScoreNorth:     .res 1
ScoreEast:      .res 1
ScoreSouth:     .res 1
ScoreWest:      .res 1

GhostOamL:      .res 1
GhostOamH:      .res 1

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

Elroy1Speed1:       .res 1
Elroy1Speed2:       .res 1
Elroy1Speed3:       .res 1
Elroy1Speed4:       .res 1
Elroy2Speed1:       .res 1
Elroy2Speed2:       .res 1
Elroy2Speed3:       .res 1
Elroy2Speed4:       .res 1

fClydeLeft:         .res 1
ElroyState:         .res 1


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
        .dword lvl1speed
.repeat 3
        .dword lvl2speed
.endrepeat
.repeat 15
        .dword lvl5speed
.endrepeat
.endmacro

GhostSpeedTbl:
        MakeSpeedTbl Speed75, Speed85, Speed95

GhostScaredSpeedTbl:
        MakeSpeedTbl Speed50, Speed55, Speed60

GhostTunnelSpeedTbl:
        MakeSpeedTbl Speed40, Speed45, Speed50

GhostElroy1SpeedTbl:
        MakeSpeedTbl Speed80, Speed90, Speed100

GhostElroy2SpeedTbl:
        MakeSpeedTbl Speed85, Speed95, Speed105


GhostSpeedsAddrLTbl:    .byte <BlinkySpeeds, <PinkySpeeds, <InkySpeeds, <ClydeSpeeds
GhostSpeedsAddrHTbl:    .byte >BlinkySpeeds, >PinkySpeeds, >InkySpeeds, >ClydeSpeeds


.macro InitGhostPos ghost, pos_x, pos_y
        lda     #pos_x
        sta     GhostsPosX+ghost
        sta     GhostsHomeX+ghost
        lda     #pos_y
        sta     GhostsPosY+ghost
        lda     #pos_x / 8
        sta     GhostsTileX+ghost
        lda     #pos_y / 8
        sta     GhostsTileY+ghost
.endmacro

InitAI:
        lda     #1
        sta     fScatter

        ; Common vars
        ldx     #NUM_GHOSTS - 1
@loop:
        lda     #0
        sta     fGhostsScared,x
        sta     fGhostsReverse,x
        sta     fGhostsBeingEaten,x
        lda     #GhostState::waiting
        sta     GhostsState,x
        txa
        sta     GhostsPriority,x
        sta     GhostsPalette,x
        dex
        bpl     @loop

        ; Blinky
        InitGhostPos BLINKY, 127, 91
        lda     #WEST
        sta     GhostsDirection+BLINKY
        sta     GhostsTurnDir+BLINKY
        lda     #GhostState::active
        sta     GhostsState+BLINKY

        ; Pinky
        InitGhostPos PINKY, 127, 115
        lda     #SOUTH
        sta     GhostsDirection+PINKY
        sta     GhostsTurnDir+PINKY

        ; Inky
        InitGhostPos INKY, 111, 115
        lda     #NORTH
        sta     GhostsDirection+INKY
        sta     GhostsTurnDir+INKY

        ; Clyde
        InitGhostPos CLYDE, 143, 115
        lda     #NORTH
        sta     GhostsDirection+CLYDE
        sta     GhostsTurnDir+CLYDE

        ; Waiting speed
        lda     #$22
        sta     BlinkySpeeds+GhostSpeeds::WaitingSpeed4
        sta     BlinkySpeeds+GhostSpeeds::WaitingSpeed3
        sta     BlinkySpeeds+GhostSpeeds::WaitingSpeed2
        sta     BlinkySpeeds+GhostSpeeds::WaitingSpeed1
        sta     PinkySpeeds+GhostSpeeds::WaitingSpeed4
        sta     PinkySpeeds+GhostSpeeds::WaitingSpeed3
        sta     PinkySpeeds+GhostSpeeds::WaitingSpeed2
        sta     PinkySpeeds+GhostSpeeds::WaitingSpeed1
        sta     InkySpeeds+GhostSpeeds::WaitingSpeed4
        sta     InkySpeeds+GhostSpeeds::WaitingSpeed3
        sta     InkySpeeds+GhostSpeeds::WaitingSpeed2
        sta     InkySpeeds+GhostSpeeds::WaitingSpeed1
        sta     ClydeSpeeds+GhostSpeeds::WaitingSpeed4
        sta     ClydeSpeeds+GhostSpeeds::WaitingSpeed3
        sta     ClydeSpeeds+GhostSpeeds::WaitingSpeed2
        sta     ClydeSpeeds+GhostSpeeds::WaitingSpeed1

        ; Eaten speed
        lda     #$ff
        sta     BlinkySpeeds+GhostSpeeds::EatenSpeed4
        sta     BlinkySpeeds+GhostSpeeds::EatenSpeed3
        sta     BlinkySpeeds+GhostSpeeds::EatenSpeed2
        sta     BlinkySpeeds+GhostSpeeds::EatenSpeed1
        sta     PinkySpeeds+GhostSpeeds::EatenSpeed4
        sta     PinkySpeeds+GhostSpeeds::EatenSpeed3
        sta     PinkySpeeds+GhostSpeeds::EatenSpeed2
        sta     PinkySpeeds+GhostSpeeds::EatenSpeed1
        sta     InkySpeeds+GhostSpeeds::EatenSpeed4
        sta     InkySpeeds+GhostSpeeds::EatenSpeed3
        sta     InkySpeeds+GhostSpeeds::EatenSpeed2
        sta     InkySpeeds+GhostSpeeds::EatenSpeed1
        sta     ClydeSpeeds+GhostSpeeds::EatenSpeed4
        sta     ClydeSpeeds+GhostSpeeds::EatenSpeed3
        sta     ClydeSpeeds+GhostSpeeds::EatenSpeed2
        sta     ClydeSpeeds+GhostSpeeds::EatenSpeed1

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
        sta     GhostsDotCounter+BLINKY
        sta     GhostsDotCounter+PINKY
        lda     #30 + 1
        sta     GhostsDotCounter+INKY
        lda     #60 + 1
        sta     GhostsDotCounter+CLYDE
@died:

        ; Set difficulty level based on level
        lda     NumLevel
        cmp     #19                         ; ghost difficulty capped at 18 (level 19)
        blt     :+
        lda     #18
:
        tax
        lda     ElroyDotsTbl,x
        sta     Elroy1Dots
        lsr
        sta     Elroy2Dots
        lda     DotTimeoutTbl,x
        sta     DotTimeout
        sta     DotClock
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
        txa
        asl                                 ; X will now point at 32-bit entries
        tax
        CopyDwordFromTbl GhostSpeedTbl, BlinkySpeeds+GhostSpeeds::Speed1
        CopyDwordFromTbl GhostSpeedTbl, PinkySpeeds+GhostSpeeds::Speed1
        CopyDwordFromTbl GhostSpeedTbl, InkySpeeds+GhostSpeeds::Speed1
        CopyDwordFromTbl GhostSpeedTbl, ClydeSpeeds+GhostSpeeds::Speed1
        CopyDwordFromTbl GhostScaredSpeedTbl, BlinkySpeeds+GhostSpeeds::ScaredSpeed1
        CopyDwordFromTbl GhostScaredSpeedTbl, PinkySpeeds+GhostSpeeds::ScaredSpeed1
        CopyDwordFromTbl GhostScaredSpeedTbl, InkySpeeds+GhostSpeeds::ScaredSpeed1
        CopyDwordFromTbl GhostScaredSpeedTbl, ClydeSpeeds+GhostSpeeds::ScaredSpeed1
        CopyDwordFromTbl GhostTunnelSpeedTbl, BlinkySpeeds+GhostSpeeds::TunnelSpeed1
        CopyDwordFromTbl GhostTunnelSpeedTbl, PinkySpeeds+GhostSpeeds::TunnelSpeed1
        CopyDwordFromTbl GhostTunnelSpeedTbl, InkySpeeds+GhostSpeeds::TunnelSpeed1
        CopyDwordFromTbl GhostTunnelSpeedTbl, ClydeSpeeds+GhostSpeeds::TunnelSpeed1
        CopyDwordFromTbl GhostElroy1SpeedTbl, Elroy1Speed1
        CopyDwordFromTbl GhostElroy2SpeedTbl, Elroy2Speed1

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
@eating_ghost:
        jsr     EatingGhostClockTick

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

        ; Cruise Elroy speed
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
        lda     ElroyState
        bne     @elroy_done                 ; branch if we already changed Blinky's speed
        lda     #1
        sta     ElroyState
        CopyDword Elroy1Speed1, BlinkySpeeds+GhostSpeeds::Speed1
        jmp     @elroy_done
@elroy2:
        lda     ElroyState
        cmp     #2
        beq     @elroy_done
        lda     #2
        sta     ElroyState
        CopyDword Elroy2Speed1, BlinkySpeeds+GhostSpeeds::Speed1
@elroy_done:

        ; Move the ghosts
        ldx     #NUM_GHOSTS - 1
@move_loop:
        stx     GhostId
        jsr     HandleOneGhost
        dex
        bpl     @move_loop

        rts


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
        lda     ModeClockH
        sbc     #0
        sta     ModeClockH
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


SetModeClock:
        ; @TODO@ -- choose table based on level number
        lda     ModeCount
        asl
        tay
        lda     (pModesL),y
        sta     ModeClockL
        iny
        lda     (pModesL),y
        sta     ModeClockH
        rts


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
        jmp     @nonzero
@maybe_zero:
        ldy     EnergizerClockH
        beq     @zero
@nonzero:
        sub     #1
        sta     EnergizerClockL
        lda     EnergizerClockH
        sbc     #0
        sta     EnergizerClockH
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


EatingGhostClockTick:
        lda     EatingGhostClock
        beq     @no_ghost_being_eaten
        dec     EatingGhostClock
        rts
@no_ghost_being_eaten:
        lda     #0
        sta     fGhostsBeingEaten+BLINKY
        sta     fGhostsBeingEaten+PINKY
        sta     fGhostsBeingEaten+INKY
        sta     fGhostsBeingEaten+CLYDE
        rts


; X = ghost ID (also in GhostId var) on entry and exit
HandleOneGhost:
        ; Ghost doesn't move while being eaten
        lda     fGhostsBeingEaten,x
        bne     @end

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

        ; Release ghost if (all must apply):
        ; 1) Global dot counter is inactive
        lda     GhostGlobalDotCounter
        bne     @no_release
        ; 2) It is waiting
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
.repeat 2
        jsr     SpeedTick
        bcc     :+
        jsr     MoveOneGhost
        jsr     CalcGhostCoords
:
.endrepeat

        jmp     CheckCollisions

@end:
        rts


; Output:
;   pSpeed = pointer to first byte of the ghost's speed
GetSpeed:
        lda     GhostSpeedsAddrLTbl,x
        sta     TmpL
        lda     GhostSpeedsAddrHTbl,x
        sta     TmpH

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
        ; No special conditions apply
        lda     #GhostSpeeds::Speed1
        jmp     @end
@eaten:
        lda     #GhostSpeeds::EatenSpeed1
        jmp     @end
@in_house:
        lda     #GhostSpeeds::WaitingSpeed1
        jmp     @end
@in_tunnel:
        lda     #GhostSpeeds::TunnelSpeed1
        jmp     @end
@scared:
        lda     #GhostSpeeds::ScaredSpeed1
@end:
        add     TmpL                        ; add address of GhostSpeeds struct
        sta     pSpeedL
        lda     TmpH
        adc     #0
        sta     pSpeedH
        rts


CheckCollisions:
        lda     GhostsTileX,x
        cmp     PacTileX
        bne     @no_collision
        lda     GhostsTileY,x
        cmp     PacTileY
        bne     @no_collision
        ; Collided
        ; Ignore collision if ghost has been eaten
        lda     GhostsState,x
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
        lda     #1
        sta     fGhostsBeingEaten,x
        lda     #GhostState::eaten
        sta     GhostsState,x
        lda     #60
        sta     EatingGhostClock
        lda     EnergizerPoints
        asl                                 ; 16-bit entries
        tay
        lda     EnergizerPtsTbl,y
        sta     TmpL
        lda     EnergizerPtsTbl+1,y
        sta     TmpH
        jsr     AddPoints
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
        lda     GhostsHomeX,x
        sta     TmpL
        lda     GhostsPosX,x
        cmp     TmpL
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
@end:
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
        jmp     @got_target
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
        jmp     @changed_direction
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
        ; Preserve X, since we clobber it
        ; @TODO@ -- maybe rewrite routine not to clobber X?
        txa
        pha

        lda     fScatter
        bne     @scatter

        lda     TileX
        sub     PacTileX
        bpl     @positive_x
        eor     #$ff
        add     #1
@positive_x:
        cmp     #8
        bge     @chase
        tax
        lda     SquareTbl,x
        tay                                 ; save square of horizontal distance
        lda     TileY
        sub     PacTileY
        bpl     @positive_y
        eor     #$ff
        add     #1
@positive_y:
        cmp     #8
        bge     @chase
        tax
        tya                                 ; get square of horizontal distance back
        add     SquareTbl,x
        ; A is now the square of the distance between Clyde and Pac-Man
        ; Retreat to corner if too close
        cmp     #49+1                       ; 7**2 = 49
        blt     @scatter
@chase:
        lda     PacTileX
        sta     TargetTileX
        lda     PacTileY
        sta     TargetTileY

        ; restore X
        pla
        tax
        rts

@scatter:
        ; Go to southwest corner of the maze
        lda     #2
        sta     TargetTileX
        lda     #32
        sta     TargetTileY

        ; restore X
        pla
        tax
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


.macro EvalDirection dir, score
.local @end
        lda     GhostsDirection,x           ; Disallow if going the opposite direction
        cmp     #dir ^ $03
        beq     @end
        ldy     NextTileX
.if dir = WEST
        dey
.elseif dir = EAST
        iny
.endif
        ldx     NextTileY                   ; clobber X; it'll be restored later
.if dir = NORTH
        dex
.elseif dir = SOUTH
        inx
.endif
        jsr     GetTile
        jsr     IsTileEnterable
        bne     @end
        lda     score
        cmp     MaxScore
        blt     @end
        beq     @end
        sta     MaxScore
        ; X got clobbered earlier; have to reload it
        ldx     GhostId
        lda     #dir
        sta     GhostsTurnDir,x
@end:
        ; Reload X in case we skipped over the reload a few lines up
        ldx     GhostId
.endmacro

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
        EvalDirection NORTH, ScoreNorth
        EvalDirection WEST, ScoreWest
        EvalDirection SOUTH, ScoreSouth
        EvalDirection EAST, ScoreEast
        rts


.macro GenRandomScore score
        jsr     Rand
        ; Don't allow a score of 0 (reserved for invalid directions)
        cmp     #0
        bne     :+
        lda     #1
:
        sta     score
.endmacro

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
        jmp     @north_ok
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
        GenRandomScore ScoreNorth
        GenRandomScore ScoreWest
        GenRandomScore ScoreSouth
        GenRandomScore ScoreEast
        rts


StartEnergizer:
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
        lda     fSpriteOverflow
        beq     @no_overflow
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
        dex
        bpl     @draw_loop

        rts

; X is ghost ID (also in GhostId var) on entry and exit
DrawOneGhost:
        ; Update ghost in OAM
        lda     GhostsPriority,x
        asl
        asl
        asl
        add     #8
        sta     GhostOamL
        lda     #>MyOAM
        sta     GhostOamH

        ; Don't draw ghost if it's being eaten
        lda     fGhostsBeingEaten,x
        beq     @not_being_eaten
        lda     #$ff
        ldy     #0
        sta     (GhostOamL),y
        ldy     #4
        sta     (GhostOamL),y
        rts
@not_being_eaten:

        ; Y position
        lda     GhostsPosY,x
        add     #24                         ; -8 to get top edge, +32 to compensate for status
        bcc     @not_too_low
        ; Carry here means ghost is at very bottom of the maze and its
        ; Y coordinate is >= 256. This means it has not wrapped around
        ; and will not need to be hidden
        sub     VScroll
        jmp     @scroll_ok
@not_too_low:
        sub     VScroll
        bcs     @scroll_ok
        ; Sprite has gone off the top of the screen and wrapped around
        ; Hide it so it won't peek up from the bottom
        lda     #$ff
@scroll_ok:
        ldy     #0
        sta     (GhostOamL),y
        ldy     #4
        sta     (GhostOamL),y

        ; Pattern index
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @eaten
        cmp     #GhostState::entering
        bne     @not_eaten
@eaten:
        ; Ghost has been eaten
        lda     #$40
        jmp     @first_frame
@not_eaten:
        ; Toggle between two frames
        lda     FrameCounter
        and     #$08
        beq     @first_frame                ; This will store $00 to TmpL
        lda     #$10                        ; Second frame is $10 tiles after first frame
@first_frame:
        sta     TmpL
        lda     fGhostsScared,x
        bne     @scared
        ; Ghost is not scared
        lda     GhostsTurnDir,x
        asl
        asl
        jmp     @store_pattern
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
        jmp     @store_pattern
@scared_blue:
        lda     #$20
@store_pattern:
        ora     #$01                        ; Use $1000 bank of PPU memory
        add     TmpL
        ldy     #1
        sta     (GhostOamL),y
        add     #2
        ldy     #5
        sta     (GhostOamL),y

        ; Attributes
        ; Scared ghosts use palette 0
        lda     fGhostsScared,x
        bne     @scared2
        lda     GhostsPalette,x
        jmp     @got_palette
@scared2:
        lda     #0
@got_palette:
        ; Flip priority if ghost is at edges of tunnel
        ldy     GhostsTileX,x
        cpy     #3
        blt     @flip
        cpy     #29
        blt     @no_flip
@flip:
        ora     #$20
@no_flip:
        ldy     #2
        sta     (GhostOamL),y
        ldy     #6
        sta     (GhostOamL),y

        ; X position
        lda     GhostsPosX,x
        sub     #7
        ldy     #3
        sta     (GhostOamL),y
        add     #8
        ldy     #7
        sta     (GhostOamL),y
        rts
