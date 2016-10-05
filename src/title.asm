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
        jsr     ReadJoys
        lda     Joy1Down
        beq     @loop
        jsr     NewGame
        jmp     TitleScreen


TitleScreenCompressed:
        .incbin "../assets/title.nam.lzss"
