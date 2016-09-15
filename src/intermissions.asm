GiantPacManOAM = MyOAM + 128


.segment "ZEROPAGE"

IntermissionCounter:    .res 1

; Handy aliases
BlinkyX = GhostsPosX+BLINKY
BlinkyDirection = GhostsDirection+BLINKY
BlinkyScared = fGhostsScared+BLINKY


.segment "CODE"

Intermission1:
        ; Wherein Pac-Man becomes larger than life
        jsr     BeginIntermission

        ldy     #20
        jsr     WaitFrames

        ; Enter Pac-Man
        ; Also prep Blinky's initial position
        lda     #0
        sta     PacX
        sta     BlinkyX
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
        lda     BlinkyX
        bmi     :-

        ; Make sure sprites won't wrap around when they go off the left edge
        lda     #1
        sta     fSprAtLeftEdge

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
        lda     BlinkyX
        bpl     :-

        ldy     #80
        jsr     WaitFrames

        ; Blinky gets scared
        ; Prepare giant Pac-Man too
        lda     #Speed100
        sta     GhostBaseSpeed
        sta     BlinkyScared
        lda     #EAST
        sta     BlinkyDirection
        sta     PacDirection

        ; Let scared Blinky move in a bit
        lda     #60
        sta     IntermissionCounter
:       jsr     DrawBlinky
        jsr     MoveBlinkyIntermission
        jsr     WaitForVblank
        dec     IntermissionCounter
        bne     :-

        ; Enter right half of giant Pac-Man
:       jsr     DrawBlinky
        jsr     DrawRightHalfOfGiantPacMan
        jsr     MoveBlinkyIntermission
        jsr     MovePacManIntermission
        jsr     WaitForVblank
        lda     PacX
        cmp     #8
        blt     :-

        ; Let 'em both move a bit
        lda     #60
        sta     IntermissionCounter
:       jsr     DrawBlinky
        jsr     DrawLeftHalfOfGiantPacMan
        jsr     DrawRightHalfOfGiantPacMan
        jsr     MoveBlinkyIntermission
        jsr     MovePacManIntermission
        jsr     WaitForVblank
        dec     IntermissionCounter
        bne     :-

        lda     #BGM_NONE
        sta     BGM
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
        sta     BlinkyScared
        sta     GhostAnim
        sta     fSprAtLeftEdge
        lda     #GhostState::active
        sta     GhostsState+BLINKY
        lda     #WEST
        sta     GhostsTurnDir+BLINKY
        sta     BlinkyDirection
        sta     PacDirection
        jsr     RenderOff
        jsr     ClearNametable1
        jsr     ClearMyOAM
        jmp     RenderOn


MovePacManIntermission:
        ldx     PacDirection
.repeat 2
        lda     PacBaseSpeed
        AddSpeed PacMoveCounter
        bcc     :+
        lda     PacX
        add     DeltaXTbl,x
        sta     PacX
:
.endrepeat
        jmp     CalcPacCoords


MoveBlinkyIntermission:
        ldx     BlinkyDirection
.repeat 2
        lda     GhostBaseSpeed
        AddSpeed GhostsMoveCounter+BLINKY
        bcc     :+
        lda     BlinkyX
        add     DeltaXTbl,x
        sta     BlinkyX
:
.endrepeat
        rts


DrawBlinky:
        inc     GhostAnim
        ldx     #BLINKY
        stx     GhostId
        jmp     DrawOneGhost


DrawLeftHalfOfGiantPacMan:
        lda     #GiantPacManOAM
        sta     OamPtrL
        lda     PacX
        sub     #8
        sta     SprX
        lda     PacY
        sub     #8
        sta     SprY
        jsr     GetGiantPacManAnimFrame
        jmp     DrawHalfOfGiantPacMan

DrawRightHalfOfGiantPacMan:
        lda     #GiantPacManOAM+16
        sta     OamPtrL
        lda     PacX
        add     #8
        sta     SprX
        lda     PacY
        sub     #8
        sta     SprY
        jsr     GetGiantPacManAnimFrame
        add     #4
        sta     SprStartPattern
        ; FALL THROUGH to DrawHalfOfGiantPacMan

DrawHalfOfGiantPacMan:
        lda     #$03                        ; palette 3
        sta     SprAttrib
        jsr     DrawSprite16x16
        lda     OamPtrL
        add     #8
        sta     OamPtrL
        lda     PacY
        add     #7
        sta     SprY
        lda     #$83                        ; palette 3, v-flip
        sta     SprAttrib
        jmp     DrawSprite16x16


GetGiantPacManAnimFrame:
        lda     PacPixelX
        and     #$06
        asl
        asl
        add     #$e0
        cmp     #$f8
        bne     :+
        lda     #$e8
:
        sta     SprStartPattern
        rts
