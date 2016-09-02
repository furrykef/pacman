Intermission1:
        ; Wherein Pac-Man becomes huge
        jsr     BeginIntermission
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
        jsr     RenderOff
        jsr     ClearNametable1
        jsr     ClearMyOAM
        jmp     RenderOn
