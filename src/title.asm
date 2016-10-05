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
        jsr     WaitForVblank
        jsr     DrawCursor
        jsr     ReadJoys
        lda     #JOY_UP | JOY_DOWN | JOY_SELECT
        bit     Joy1Down
        beq     :+
        lda     CursorPos
        eor     #$01
        sta     CursorPos
:
        lda     #JOY_START | JOY_A
        bit     Joy1Down
        beq     @loop
        jsr     NewGame
        jmp     TitleScreen


DrawCursor:
        lda     #0
        sta     OamPtrL
        lda     #68
        sta     SprX
        ldx     CursorPos
        lda     DrawCursorYTbl,x
        sta     SprY
        lda     #$6c
        sta     SprStartPattern
        lda     #$03
        sta     SprAttrib
        jmp     DrawSprite16x16

DrawCursorYTbl:
        .byte   108                         ; 1-player game
        .byte   124                         ; 2-player game


TitleScreenCompressed:
        .incbin "../assets/title.nam.lzss"
