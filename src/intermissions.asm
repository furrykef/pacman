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
        lda     #Speed75
        sta     PacBaseSpeed

        lda     #27
        sta     IntermissionCounter
:       jsr     DrawPacMan
        jsr     MovePacManIntermission
        jsr     WaitForVblank
        dec     IntermissionCounter
        bne     :-

        ; Enter Blinky
        lda     #Speed80
        sta     GhostBaseSpeed

        ; Let 'em move until they're halfway across the screen
        ; (so their sign bits clear)
:       jsr     DrawPacMan
        jsr     DrawBlinky
        jsr     MovePacManIntermission
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        lda     GhostsPosX+BLINKY
        bmi     :-

        ; Let 'em move until Pac-Man scrolls offscreen
:       jsr     DrawPacMan
        jsr     DrawBlinky
        jsr     MovePacManIntermission
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        lda     PacX
        bpl     :-

        ; Hide Pac-Man
        jsr     ClearMyOAM

        ; Let Blinky move until he scrolls offscreen
:       jsr     DrawBlinky
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        lda     GhostsPosX+BLINKY
        bpl     :-

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
        sta     fSprAtLeftEdge
        lda     #GhostState::active
        sta     GhostsState+BLINKY
        lda     #WEST
        sta     GhostsTurnDir+BLINKY
        jsr     RenderOff
        jsr     ClearNametable1
        jsr     ClearMyOAM
        jmp     RenderOn


MovePacManIntermission:
.repeat 2
        lda     PacBaseSpeed
        AddSpeed PacMoveCounter
        bcc     :+
        dec     PacX
:
.endrepeat
        jmp     CalcPacCoords


MoveBlinkyIntermission:
.repeat 2
        lda     GhostBaseSpeed
        AddSpeed GhostsMoveCounter+BLINKY
        bcc     :+
        dec     GhostsPosX+BLINKY
:
.endrepeat
        rts


DrawBlinky:
        inc     GhostAnim
        ldx     #BLINKY
        stx     GhostId
        jmp     DrawOneGhost
