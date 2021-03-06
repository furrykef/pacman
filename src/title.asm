.enum
        MNU_1_PLAYER
        MNU_2_PLAYER
.endenum


.segment "ZEROPAGE"

CursorPos:  .res 1


.segment "CODE"

; JMP here, not JSR
TitleScreen:
        jsr     RenderOff
        jsr     SplitOff
        lda     #0
        sta     VScroll
        sta     BGM
        sta     NumPlayer                   ; respond to player 1's input
        jsr     ClearJoy
        jsr     ClearMyOAM
        jsr     LoadPalette

        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #<TitleScreenCompressed
        sta     pCompressedDataL
        lda     #>TitleScreenCompressed
        sta     pCompressedDataH
        lda     #<DrawTile
        sta     JsrIndAddrL
        lda     #>DrawTile
        sta     JsrIndAddrH
        jsr     LzssDecode
        lda     #MNU_1_PLAYER
        sta     CursorPos
        jsr     RenderOn

@loop:
        jsr     DrawCursor
        jsr     EndFrame
        lda     #JOY_UP | JOY_DOWN | JOY_SELECT
        bit     JoyDown
        beq     :+
        lda     CursorPos
        eor     #$01
        sta     CursorPos
:
        lda     #JOY_START | JOY_A
        bit     JoyDown
        beq     @loop
        lda     #3
        sta     P1Lives
        sta     P2Lives
        lda     CursorPos
        cmp     #MNU_2_PLAYER
        beq     :+
        lda     #0
        sta     P2Lives
:
        jsr     NewGame
        jmp     TitleScreen


DrawCursor:
        lda     #68
        sta     SprX
        ldx     CursorPos
        lda     DrawCursorYTbl,x
        sta     SprY
        lda     #$6c
        sta     SprStartPattern
        lda     #$03
        sta     SprAttrib
        ldy     #0
        jmp     DrawSprite16x16

DrawCursorYTbl:
        .byte   108                         ; 1-player game
        .byte   124                         ; 2-player game


TitleScreenCompressed:
        .incbin "../assets/title.nam.lzss"
