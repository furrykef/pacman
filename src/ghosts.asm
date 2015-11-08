.enum GhostState
        active
        eaten
        waiting
        exiting
        entering
.endenum


.struct Ghost
        PosX            .byte               ; center of ghost, not upper left
        PosY            .byte
        HomeX           .byte
        TileX           .byte
        TileY           .byte               ; must follow TileX in memory
        Direction       .byte
        TurnDir         .byte               ; direction ghost has planned to turn in
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
        State           .byte
        fScared         .byte
        fReverse        .byte
        fBeingEaten     .byte
        DotCounter      .byte
        pGetTargetTileL .byte
        pGetTargetTileH .byte
        Priority        .byte
        Palette         .byte
.endstruct


.segment "ZEROPAGE"

Blinky:     .tag Ghost
Pinky:      .tag Ghost
Inky:       .tag Ghost
Clyde:      .tag Ghost

GhostL:         .res 1
GhostH:         .res 1

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

EnergizerTimeoutL:  .res 1
EnergizerTimeoutH:  .res 1
EnergizerClockL:    .res 1
EnergizerClockH:    .res 1

EnergizerPoints:    .res 1                  ; 0 = 200, 1 = 400...

EatingGhostClock:   .res 1


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


.macro InitGhostPos ghost, pos_x, pos_y
        lda     #pos_x
        sta     ghost+Ghost::PosX
        sta     ghost+Ghost::HomeX
        lda     #pos_y
        sta     ghost+Ghost::PosY
        lda     #pos_x / 8
        sta     ghost+Ghost::TileX
        lda     #pos_y / 8
        sta     ghost+Ghost::TileY
.endmacro

InitAI:
        lda     #1
        sta     fScatter

        lda     #0
        sta     ModeCount
        jsr     SetModeClock

        ; Blinky
        InitGhostPos Blinky, 127, 91
        lda     #WEST
        sta     Blinky+Ghost::Direction
        sta     Blinky+Ghost::TurnDir
        lda     #GhostState::active
        sta     Blinky+Ghost::State
        lda     #0
        sta     Blinky+Ghost::fReverse
        sta     Blinky+Ghost::fScared
        sta     Blinky+Ghost::fBeingEaten
        sta     Blinky+Ghost::DotCounter
        lda     #<GetBlinkyTargetTile
        sta     Blinky+Ghost::pGetTargetTileL
        lda     #>GetBlinkyTargetTile
        sta     Blinky+Ghost::pGetTargetTileH
        lda     #0
        sta     Blinky+Ghost::Priority
        lda     #$00
        sta     Blinky+Ghost::Palette

        ; Pinky
        InitGhostPos Pinky, 127, 115
        lda     #SOUTH
        sta     Pinky+Ghost::Direction
        sta     Pinky+Ghost::TurnDir
        lda     #GhostState::exiting
        sta     Pinky+Ghost::State
        lda     #0
        sta     Pinky+Ghost::fReverse
        sta     Pinky+Ghost::fScared
        sta     Pinky+Ghost::fBeingEaten
        sta     Pinky+Ghost::DotCounter
        lda     #<GetPinkyTargetTile
        sta     Pinky+Ghost::pGetTargetTileL
        lda     #>GetPinkyTargetTile
        sta     Pinky+Ghost::pGetTargetTileH
        lda     #1
        sta     Pinky+Ghost::Priority
        lda     #$01
        sta     Pinky+Ghost::Palette

        ; Inky
        InitGhostPos Inky, 111, 115
        lda     #NORTH
        sta     Inky+Ghost::Direction
        sta     Inky+Ghost::TurnDir
        lda     #GhostState::waiting
        sta     Inky+Ghost::State
        lda     #0
        sta     Inky+Ghost::fReverse
        sta     Inky+Ghost::fScared
        sta     Inky+Ghost::fBeingEaten
        lda     #30 + 1
        sta     Inky+Ghost::DotCounter
        lda     #<GetInkyTargetTile
        sta     Inky+Ghost::pGetTargetTileL
        lda     #>GetInkyTargetTile
        sta     Inky+Ghost::pGetTargetTileH
        lda     #2
        sta     Inky+Ghost::Priority
        lda     #$02
        sta     Inky+Ghost::Palette

        ; Clyde
        InitGhostPos Clyde, 143, 115
        lda     #NORTH
        sta     Clyde+Ghost::Direction
        sta     Clyde+Ghost::TurnDir
        lda     #GhostState::waiting
        sta     Clyde+Ghost::State
        lda     #0
        sta     Clyde+Ghost::fReverse
        sta     Clyde+Ghost::fScared
        sta     Clyde+Ghost::fBeingEaten
        lda     #60 + 1
        sta     Clyde+Ghost::DotCounter
        lda     #<GetClydeTargetTile
        sta     Clyde+Ghost::pGetTargetTileL
        lda     #>GetClydeTargetTile
        sta     Clyde+Ghost::pGetTargetTileH
        lda     #3
        sta     Clyde+Ghost::Priority
        lda     #$03
        sta     Clyde+Ghost::Palette

        ; Speed
        ; @TODO@ -- change depending on level
        lda     #$55
        sta     Blinky+Ghost::Speed4
        sta     Blinky+Ghost::Speed3
        sta     Pinky+Ghost::Speed4
        sta     Pinky+Ghost::Speed3
        sta     Inky+Ghost::Speed4
        sta     Inky+Ghost::Speed3
        sta     Clyde+Ghost::Speed4
        sta     Clyde+Ghost::Speed3
        lda     #$2a
        sta     Blinky+Ghost::Speed2
        sta     Pinky+Ghost::Speed2
        sta     Inky+Ghost::Speed2
        sta     Clyde+Ghost::Speed2
        lda     #$aa
        sta     Blinky+Ghost::Speed1
        sta     Pinky+Ghost::Speed1
        sta     Inky+Ghost::Speed1
        sta     Clyde+Ghost::Speed1

        ; Waiting speed
        lda     #$22
        sta     Blinky+Ghost::WaitingSpeed4
        sta     Blinky+Ghost::WaitingSpeed3
        sta     Blinky+Ghost::WaitingSpeed2
        sta     Blinky+Ghost::WaitingSpeed1
        sta     Pinky+Ghost::WaitingSpeed4
        sta     Pinky+Ghost::WaitingSpeed3
        sta     Pinky+Ghost::WaitingSpeed2
        sta     Pinky+Ghost::WaitingSpeed1
        sta     Inky+Ghost::WaitingSpeed4
        sta     Inky+Ghost::WaitingSpeed3
        sta     Inky+Ghost::WaitingSpeed2
        sta     Inky+Ghost::WaitingSpeed1
        sta     Clyde+Ghost::WaitingSpeed4
        sta     Clyde+Ghost::WaitingSpeed3
        sta     Clyde+Ghost::WaitingSpeed2
        sta     Clyde+Ghost::WaitingSpeed1

        ; Tunnel speed
        lda     #$22
        sta     Blinky+Ghost::TunnelSpeed4
        sta     Blinky+Ghost::TunnelSpeed3
        sta     Blinky+Ghost::TunnelSpeed2
        sta     Blinky+Ghost::TunnelSpeed1
        sta     Pinky+Ghost::TunnelSpeed4
        sta     Pinky+Ghost::TunnelSpeed3
        sta     Pinky+Ghost::TunnelSpeed2
        sta     Pinky+Ghost::TunnelSpeed1
        sta     Inky+Ghost::TunnelSpeed4
        sta     Inky+Ghost::TunnelSpeed3
        sta     Inky+Ghost::TunnelSpeed2
        sta     Inky+Ghost::TunnelSpeed1
        sta     Clyde+Ghost::TunnelSpeed4
        sta     Clyde+Ghost::TunnelSpeed3
        sta     Clyde+Ghost::TunnelSpeed2
        sta     Clyde+Ghost::TunnelSpeed1

        ; Scared speed
        lda     #$24
        sta     Blinky+Ghost::ScaredSpeed4
        sta     Blinky+Ghost::ScaredSpeed2
        sta     Pinky+Ghost::ScaredSpeed4
        sta     Pinky+Ghost::ScaredSpeed2
        sta     Inky+Ghost::ScaredSpeed4
        sta     Inky+Ghost::ScaredSpeed2
        sta     Clyde+Ghost::ScaredSpeed4
        sta     Clyde+Ghost::ScaredSpeed2
        lda     #$92
        sta     Blinky+Ghost::ScaredSpeed3
        sta     Blinky+Ghost::ScaredSpeed1
        sta     Pinky+Ghost::ScaredSpeed3
        sta     Pinky+Ghost::ScaredSpeed1
        sta     Inky+Ghost::ScaredSpeed3
        sta     Inky+Ghost::ScaredSpeed1
        sta     Clyde+Ghost::ScaredSpeed3
        sta     Clyde+Ghost::ScaredSpeed1

        ; @TODO@ -- depends on level
        lda     #240
        sta     DotTimeout
        sta     DotClock

        ; @TODO@ -- depends on level
        lda     #<360
        sta     EnergizerTimeoutL
        lda     #>360
        sta     EnergizerTimeoutH

        lda     #0
        sta     EnergizerClockL
        sta     EnergizerClockH
        sta     EatingGhostClock

        rts


MoveGhosts:
        jsr     ModeClockTick
        jsr     DotClockTick
        lda     #<Blinky
        sta     GhostL
        lda     #>Blinky
        sta     GhostH
        jsr     HandleOneGhost
        lda     #<Pinky
        sta     GhostL
        lda     #>Pinky
        sta     GhostH
        jsr     HandleOneGhost
        lda     #<Inky
        sta     GhostL
        lda     #>Inky
        sta     GhostH
        jsr     HandleOneGhost
        lda     #<Clyde
        sta     GhostL
        lda     #>Clyde
        sta     GhostH
        jsr     HandleOneGhost
        lda     EatingGhostClock
        beq     @no_ghost_being_eaten
        dec     EatingGhostClock
        rts
@no_ghost_being_eaten:
        lda     #0
        sta     Blinky+Ghost::fBeingEaten
        sta     Inky+Ghost::fBeingEaten
        sta     Pinky+Ghost::fBeingEaten
        sta     Clyde+Ghost::fBeingEaten
        rts


ModeClockTick:
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
        sta     Blinky+Ghost::fReverse
        sta     Pinky+Ghost::fReverse
        sta     Inky+Ghost::fReverse
        sta     Clyde+Ghost::fReverse
        inc     ModeCount
        jsr     SetModeClock
@end:
        rts


SetModeClock:
        ; @TODO@ -- choose table based on level number
        lda     ModeCount
        asl
        tax
        lda     Lvl1Modes,x
        sta     ModeClockL
        inx
        lda     Lvl1Modes,x
        sta     ModeClockH
        rts

; @TODO@ -- don't use this if global dot counter is active
DotClockTick:
        ldx     DotClock
        beq     @release_ghost
        dex
        stx     DotClock
        rts
@release_ghost:
        lda     DotTimeout
        sta     DotClock
        ldx     #GhostState::exiting
        lda     Pinky+Ghost::State
        cmp     #GhostState::waiting
        beq     @release_pinky
        lda     Inky+Ghost::State
        cmp     #GhostState::waiting
        beq     @release_inky
        lda     Clyde+Ghost::State
        cmp     #GhostState::waiting
        beq     @release_clyde
        rts
@release_pinky:
        stx     Pinky+Ghost::State          ; GhostState::exiting
        rts
@release_inky:
        stx     Inky+Ghost::State
        rts
@release_clyde:
        stx     Clyde+Ghost::State
        rts


HandleOneGhost:
        ; Ghost doesn't move while being eaten
        ldy     #Ghost::fBeingEaten
        lda     (GhostL),y
        bne     @end

        ; Only eaten ghosts move if another ghost is being eaten
        lda     EatingGhostClock
        beq     @can_move
        ; Another ghost is being eaten
        ldy     #Ghost::State
        lda     (GhostL),y
        cmp     #GhostState::eaten
        beq     @can_move
        cmp     #GhostState::entering
        bne     @end                        ; we're not an eaten ghost
@can_move:

        ; Release ghost if waiting and its dot counter is clear
        ldy     #Ghost::State
        lda     (GhostL),y
        cmp     #GhostState::waiting
        bne     @no_release
        ldy     #Ghost::DotCounter
        lda     (GhostL),y
        bne     @no_release
        ldy     #Ghost::State
        lda     #GhostState::exiting
        sta     (GhostL),y
@no_release:

        ; Need to check collisions both before and after moving the ghost.
        ; This will prevent the bug in the arcade version where Pac-Man may 
        ; sometimes pass through ghosts.
        jsr     CheckCollisions

.repeat 2
        jsr     GetSpeed
        ; Get least significant bit of speed value so we can rotate it in
        lda     (GhostL),y
        lsr                                 ; put the bit in the carry flag
        iny                                 ; point y at MSB
        iny
        iny
        lda     (GhostL),y
        ror
        sta     (GhostL),y
        dey
        lda     (GhostL),y
        ror
        sta     (GhostL),y
        dey
        lda     (GhostL),y
        ror
        sta     (GhostL),y
        dey
        lda     (GhostL),y
        ror
        sta     (GhostL),y
        bcc     :+
        jsr     MoveOneGhost
:
.endrepeat

        jmp     CheckCollisions

@end:
        rts


; Output:
;   Y = points to first byte of the ghost's speed
GetSpeed:
        ldy     #Ghost::State
        lda     (GhostL),y
        cmp     #GhostState::waiting
        beq     @in_house
        cmp     #GhostState::exiting
        beq     @in_house
        ldy     #Ghost::TileY
        lda     (GhostL),y
        cmp     #14
        bne     @not_in_tunnel
        ldy     #Ghost::TileX
        lda     (GhostL),y
        cmp     #8
        blt     @in_tunnel
        cmp     #24
        bge     @in_tunnel
@not_in_tunnel:
        ldy     #Ghost::fScared
        lda     (GhostL),y
        bne     @scared
        ; No special conditions apply
        ldy     #Ghost::Speed1
        rts
@in_house:
        ldy     #Ghost::WaitingSpeed1
        rts
@in_tunnel:
        ldy     #Ghost::TunnelSpeed1
        rts
@scared:
        ldy     #Ghost::ScaredSpeed1
        rts


CheckCollisions:
        ldy     #Ghost::TileX
        lda     (GhostL),y
        cmp     PacTileX
        bne     @no_collision
        iny
        lda     (GhostL),y
        cmp     PacTileY
        bne     @no_collision
        ; collided
        ldy     #Ghost::fScared
        lda     (GhostL),y
        bne     @scared
        ; Kill Pac-Man
        ; @TODO@
        rts
@scared:
        ; Get eaten
        lda     #0                          ; clear fScared
        sta     (GhostL),y
        ldy     #Ghost::fBeingEaten
        lda     #1
        sta     (GhostL),y
        ldy     #Ghost::State
        lda     #GhostState::eaten
        sta     (GhostL),y
        lda     #60
        sta     EatingGhostClock
        lda     EnergizerPoints
        asl                                 ; 16-bit entries
        tax
        lda     EnergizerPtsTbl,x
        sta     TmpL
        lda     EnergizerPtsTbl+1,x
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
        ldy     #Ghost::State
        lda     (GhostL),y
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
        ldy     #Ghost::Direction
        lda     (GhostL),y
        tax
        lda     DeltaYTbl,x
        ldy     #Ghost::PosY
        add     (GhostL),y
        sta     (GhostL),y
        cmp     #111
        beq     @reverse
        cmp     #119
        beq     @reverse
        rts
@reverse:
        ldy     #Ghost::Direction
        lda     (GhostL),y
        eor     #$03
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        rts


MoveOneGhostEaten:
        jsr     MoveOneGhostNormal
        ldy     #Ghost::PosX
        lda     (GhostL),y
        cmp     #127
        bne     @not_above_house
        ldy     #Ghost::PosY
        lda     (GhostL),y
        cmp     #91
        bne     @not_above_house
        ldy     #Ghost::State
        lda     #GhostState::entering
        sta     (GhostL),y
@not_above_house:
        rts


MoveOneGhostExiting:
        ldy     #Ghost::PosX
        lda     (GhostL),y
        cmp     #127
        blt     @move_east
        beq     @move_north
        ; Move west
        lda     #WEST
        ldy     #Ghost::Direction
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        ldy     #Ghost::PosX
        lda     (GhostL),y
        sub     #1
        sta     (GhostL),y
        rts

@move_east:
        lda     #EAST
        ldy     #Ghost::Direction
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        ldy     #Ghost::PosX
        lda     (GhostL),y
        add     #1
        sta     (GhostL),y
        rts

@move_north:
        lda     #NORTH
        ldy     #Ghost::Direction
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        ldy     #Ghost::PosY
        lda     (GhostL),y
        sub     #1
        sta     (GhostL),y
        cmp     #91
        beq     @exited
        rts
@exited:
        lda     #WEST
        ldy     #Ghost::Direction
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        ldy     #Ghost::State
        lda     #GhostState::active
        sta     (GhostL),y
        rts


MoveOneGhostEntering:
        ldy     #Ghost::Direction
        lda     #SOUTH
        sta     (GhostL),y
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
        ldy     #Ghost::PosY
        lda     (GhostL),y
        cmp     #115
        blt     @move_south
        ; In vertical position
        ldy     #Ghost::HomeX
        lda     (GhostL),y
        sta     TmpL
        ldy     #Ghost::PosX
        lda     (GhostL),y
        cmp     TmpL
        beq     @ready
        blt     @move_east
        ; Move west
        sub     #1
        sta     (GhostL),y
        rts
@move_south:
@move_east:
        add     #1
        sta     (GhostL),y
        rts
@ready:
        ldy     #Ghost::State
        lda     #GhostState::waiting
        sta     (GhostL),y
@end:
        rts


MoveOneGhostNormal:
        ldy     #Ghost::Direction 
        lda     (GhostL),y
        tax
        ldy     #Ghost::PosX
        lda     (GhostL),y
        add     DeltaXTbl,x
        sta     (GhostL),y
        tay
        lsr
        lsr
        lsr
        sta     TileX
        tya
        and     #$07
        sta     PixelX
        ldy     #Ghost::PosY
        lda     (GhostL),y
        add     DeltaYTbl,x
        sta     (GhostL),y
        tay
        lsr
        lsr
        lsr
        sta     TileY
        tya
        and     #$07
        sta     PixelY

        lda     TileX
        ldy     #Ghost::TileX
        sta     (GhostL),y
        lda     TileY
        iny
        sta     (GhostL),y

        ldy     #Ghost::State
        lda     (GhostL),y
        cmp     #GhostState::eaten
        bne     @not_eaten
        ; Eaten; target tile is (15, 11)
        lda     #15
        sta     TargetTileX
        lda     #11
        sta     TargetTileY
        jmp     @got_target
@not_eaten:
        ; JSR to Ghost::pGetTargetTile
        ldy     #Ghost::pGetTargetTileL
        lda     (GhostL),y
        sta     JsrIndAddrL
        iny
        lda     (GhostL),y
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
        ldy     #Ghost::fReverse
        lda     (GhostL),y
        beq     @no_reverse
        ; Reversing direction
        lda     #0                          ; clear reverse flag
        sta     (GhostL),y
        ldy     #Ghost::Direction
        lda     (GhostL),y
        eor     #$03
        jmp     @changed_direction
@no_reverse:
        ldy     #Ghost::TurnDir
        lda     (GhostL),y
@changed_direction:
        ldy     #Ghost::Direction
        sta     (GhostL),y
        tax
        lda     TileX
        add     DeltaXTbl,x
        sta     NextTileX
        lda     TileY
        add     DeltaYTbl,x
        sta     NextTileY
        jsr     ComputeTurn
@not_centered:

        rts


GetBlinkyTargetTile:
        ; @TODO@ -- do not scatter while Elroy once Clyde has left house
        lda     fScatter
        bne     @scatter

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

        ldx     PacDirection
        lda     PacTileX
        add     DeltaX4Tbl,x
        sta     TargetTileX
        lda     PacTileY
        add     DeltaY4Tbl,x
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
        ldx     PacDirection
        lda     PacTileX
        add     DeltaX2Tbl,x
        asl
        sub     Blinky+Ghost::TileX
        sta     TargetTileX
        ; Target Y is computed the same way.
        lda     PacTileY
        add     DeltaY2Tbl,x
        asl
        sub     Blinky+Ghost::TileY
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
        rts

@scatter:
        ; Go to southwest corner of the maze
        lda     #2
        sta     TargetTileX
        lda     #32
        sta     TargetTileY
        rts


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
.local end
        ldy     #Ghost::Direction           ; Disallow if going the opposite direction
        lda     (GhostL),y
        cmp     #dir ^ $03
        beq     end
        ldy     NextTileX
.if dir = WEST
        dey
.elseif dir = EAST
        iny
.endif
        ldx     NextTileY
.if dir = NORTH
        dex
.elseif dir = SOUTH
        inx
.endif
        jsr     GetTile
        jsr     IsTileEnterable
        bne     end
        lda     score
        cmp     MaxScore
        blt     end
        beq     end
        sta     MaxScore
        lda     #dir
        ldy     #Ghost::TurnDir
        sta     (GhostL),y
end:
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

        ldy     #Ghost::fScared
        lda     (GhostL),y
        bne     @random

        ; Scores here will be $00..$ff, but think of $00 = -128, $01 = -127 ... $ff = 127
        ; This is called excess-128 representation (a form of excess-K, a.k.a. offset binary).
        ; This is done because signed comparisons suck on 6502.
        lda     NextTileX
        sub     TargetTileX
        tax
        add     #$80
        sta     ScoreWest
        txa
        eor     #$ff                        ; negate and add $80
        sec
        adc     #$80
        sta     ScoreEast
        lda     NextTileY
        sub     TargetTileY
        tax
        add     #$80
        sta     ScoreNorth
        txa
        eor     #$ff
        sec
        adc     #$80
        sta     ScoreSouth

        ; Ban northward turns in certain regions of the maze
        ldy     #Ghost::TileY
        lda     (GhostL),y
        cmp     #11
        beq     @maybe_restricted
        cmp     #23
        beq     @maybe_restricted
        jmp     @north_ok
@maybe_restricted:
        ldy     #Ghost::TileX
        lda     (GhostL),y
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


.macro GhostHandleEnergizer ghost
.local end
        lda     ghost+Ghost::State
        cmp     #GhostState::eaten
        beq     end
        cmp     #GhostState::entering
        beq     end
        lda     #1
        sta     ghost+Ghost::fReverse
        sta     ghost+Ghost::fScared
end:
.endmacro

StartEnergizer:
        GhostHandleEnergizer Blinky
        GhostHandleEnergizer Inky
        GhostHandleEnergizer Pinky
        GhostHandleEnergizer Clyde
        lda     #0
        sta     EnergizerPoints
        rts


GhostHandleDot:
        lda     DotTimeout
        sta     DotClock

        lda     Inky+Ghost::State
        cmp     #GhostState::waiting
        bne     @try_clyde
        ; Inky is waiting
        dec     Inky+Ghost::DotCounter
        rts
@try_clyde:
        lda     Clyde+Ghost::State
        cmp     #GhostState::waiting
        bne     @end
        ; Clyde is waiting
        dec     Clyde+Ghost::DotCounter
@end:
        rts


DrawGhosts:
        lda     fSpriteOverflow
        beq     @no_overflow
        ; More than 8 hardware sprites/scanline on previous frame; cycle priorities
        lda     Blinky+Ghost::Priority
        add     #1
        and     #$03
        sta     Blinky+Ghost::Priority
        lda     Pinky+Ghost::Priority
        add     #1
        and     #$03
        sta     Pinky+Ghost::Priority
        lda     Inky+Ghost::Priority
        add     #1
        and     #$03
        sta     Inky+Ghost::Priority
        lda     Clyde+Ghost::Priority
        add     #1
        and     #$03
        sta     Clyde+Ghost::Priority
@no_overflow:

        lda     #<Blinky
        sta     GhostL
        lda     #>Blinky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Pinky
        sta     GhostL
        lda     #>Pinky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Inky
        sta     GhostL
        lda     #>Inky
        sta     GhostH
        jsr     DrawOneGhost
        lda     #<Clyde
        sta     GhostL
        lda     #>Clyde
        sta     GhostH
        jmp     DrawOneGhost

DrawOneGhost:
        ; Update ghost in OAM
        ldy     #Ghost::Priority
        lda     (GhostL),y
        asl
        asl
        asl
        add     #8
        sta     GhostOamL
        lda     #>MyOAM
        sta     GhostOamH

        ; Don't draw ghost if it's being eaten
        ldy     #Ghost::fBeingEaten
        lda     (GhostL),y
        beq     @not_being_eaten
        lda     #$ff
        ldy     #0
        sta     (GhostOamL),y
        ldy     #4
        sta     (GhostOamL),y
        rts
@not_being_eaten:

        ; Y position
        ldy     #Ghost::PosY
        lda     (GhostL),y
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
        ldy     #Ghost::State
        lda     (GhostL),y
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
        ldy     #Ghost::fScared
        lda     (GhostL),y
        bne     @scared
        ; Ghost is not scared
        ldy     #Ghost::TurnDir
        lda     (GhostL),y
        asl
        asl
        jmp     @store_pattern
@scared:
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
        ldy     #Ghost::TileX
        lda     (GhostL),y
        tax
        ldy     #Ghost::Palette
        lda     (GhostL),y                  ; get palette
        ; Flip priority if ghost is at edges of tunnel
        cpx     #3
        blt     @flip
        cpx     #29
        blt     @no_flip
@flip:
        ora     #$20
@no_flip:
        ldy     #2
        sta     (GhostOamL),y
        ldy     #6
        sta     (GhostOamL),y

        ; X position
        ldy     #Ghost::PosX
        lda     (GhostL),y
        sub     #7
        ldy     #3
        sta     (GhostOamL),y
        add     #8
        ldy     #7
        sta     (GhostOamL),y
        rts
