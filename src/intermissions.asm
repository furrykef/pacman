.segment "ZEROPAGE"

IntermissionCounter:    .res 1


.segment "CODE"

Intermission1:
        ; Wherein Pac-Man becomes larger than life
        jsr     BeginIntermission

        ; Enter Pac-Man
        ; Also prep Blinky's initial position
        lda     #255
        sta     PacX
        sta     GhostsPosX+BLINKY
        lda     #120
        sta     PacY
        sta     GhostsPosY+BLINKY
        lda     #WEST
        sta     PacDirection
        lda     #Speed90
        sta     PacBaseSpeed

        lda     #25
        sta     IntermissionCounter
@loop1:
        jsr     DrawPacMan
        jsr     MovePacManIntermission
        jsr     WaitForVblank
        dec     IntermissionCounter
        bne     @loop1

        ; Enter Blinky
        lda     #Speed105
        sta     GhostBaseSpeed

        ; Let 'em move until Pac-Man scrolls offscreen
@loop2:
        jsr     DrawPacMan
        jsr     DrawBlinky
        jsr     MovePacManIntermission
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        lda     PacX
        bne     @loop2

        ; Hide Pac-Man
        jsr     ClearMyOAM

        ; Let Blinky move until he scrolls offscreen
@loop3:
        jsr     DrawBlinky
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        lda     GhostsPosX+BLINKY
        bne     @loop3

        ldy     #60
        jsr     WaitFrames

        rts


Intermission2:
        ; Wherein Blinky runs into a snag
        jmp     Intermission1


Intermission3:
        ; Wherein Blinky takes it all off
        jmp     Intermission1


BeginIntermission:
        lda     #BGM_INTERMISSION
        sta     BGM
        lda     #0
        sta     VScroll
        sta     GhostsPriority+BLINKY
        sta     PacMoveCounter
        sta     GhostsMoveCounter+BLINKY
        sta     fEnergizerActive            ; ensure ghosts not blue
        sta     GhostAnim
        lda     #GhostState::active
        sta     GhostsState+BLINKY
        lda     #WEST
        sta     GhostsTurnDir+BLINKY
        jsr     RenderOff
        jsr     ClearNametable1
        jsr     ClearMyOAM
        jmp     RenderOn


MovePacManIntermission:
        lda     #Speed90
        AddSpeed PacMoveCounter
        bcc     :+
        dec     PacX
        jmp     CalcPacCoords


MoveBlinkyIntermission:
        lda     GhostBaseSpeed
        AddSpeed GhostsMoveCounter+BLINKY
        bcc     :+
        dec     GhostsPosX+BLINKY
:
        rts


DrawBlinky:
        inc     GhostAnim
        ldx     #BLINKY
        stx     GhostId
        jmp     DrawOneGhost
