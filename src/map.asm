SPACE           = $20                       ; enterable
DOT             = $92
ENERGIZER       = $95


.segment "ZEROPAGE"

RowAddrL:       .res 1
RowAddrH:       .res 1
pCurrentBoardL: .res 1
pCurrentBoardH: .res 1


.segment "BSS"

CurrentBoard:   .res 32*31


.segment "CODE"

LoadBoard:
        lda     #<FullBoardCompressed
        sta     pCompressedDataL
        lda     #>FullBoardCompressed
        sta     pCompressedDataH
        lda     #<LoadBoardByte
        sta     JsrIndAddrL
        lda     #>LoadBoardByte
        sta     JsrIndAddrH
        lda     #<CurrentBoard
        sta     pCurrentBoardL
        lda     #>CurrentBoard
        sta     pCurrentBoardH
        jsr     LzssDecode
        jmp     CopyBoardIntoVram


; Must preserve X and Y
LoadBoardByte:
        sty     TmpL
        ldy     #0
        sta     (pCurrentBoardL),y
        inc     pCurrentBoardL
        bne     :+
        inc     pCurrentBoardH
:
        ldy     TmpL
        rts


CopyBoardIntoVram:
        ; Load first nametable
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #<CurrentBoard
        sta     TmpL
        lda     #>CurrentBoard
        sta     TmpH
        ldx     #30
@copy_row:
        ldy     #0
@copy_cell:
        lda     (TmpL),y
        sta     PPUDATA
        iny
        cpy     #32
        bne     @copy_cell
        ; Finished this row; bump pointer by a row
        lda     TmpL
        add     #32
        sta     TmpL
        lda     TmpH
        adc     #0
        sta     TmpH
        dex
        bne     @copy_row

        ; Last row has to be written to other nametable
        lda     #$28
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        tax
@loop:
        lda     CurrentBoard+32*30,x
        sta     PPUDATA
        inx
        cpx     #32
        bne     @loop

        ; Clear attribute tables
        lda     #$23
        sta     PPUADDR
        lda     #$c0
        sta     PPUADDR
        jsr     ClearAttr
        lda     #$2b
        sta     PPUADDR
        lda     #$c0
        sta     PPUADDR
        jsr     ClearAttr

        ; Attributes for door to ghost house (X=15..16, Y=12)
        ; These use palette 1 instead of palette 0
        ldx     #$23
        stx     PPUADDR
        ldy     #$db
        sty     PPUADDR
        lda     #1 << 2
        sta     PPUDATA
        lda     #1
        sta     PPUDATA

        ; Attributes for side tunnels
        ; Left: X=0..1, Y=13..15
        ; Right: X=30..31, Y=13..15
        stx     PPUADDR
        ldy     #$d8
        lda     #%01010101
        sty     PPUADDR
        sta     PPUDATA
        stx     PPUADDR
        ldy     #$df
        sty     PPUADDR
        sta     PPUDATA

        ; Attributes for fruit area (X=14..17, Y=16..18)
        stx     PPUADDR
        lda     #$e3
        sta     PPUADDR
        lda     #%11111111
        sta     PPUDATA
        sta     PPUDATA

        ; Attributes for status area
        lda     #$2b
        sta     PPUADDR
        lda     #$f8
        sta     PPUADDR
        lda     #%10101010
.repeat 8
        sta     PPUDATA
.endrepeat

        rts

ClearAttr:
        lda     #0
        ldx     #64
@loop:
        sta     PPUDATA
        dex
        bne     @loop
        rts


; Input:
;   Y = X coordinate
;   X = Y coordinate
;
; Yes, I know it's backwards!
;
; Output:
;   A = the tile
;   Y = unchanged (column of tile)
;   RowAddr = address of row of tile
GetTile:
        ; Set RowAddr to the appropriate row of CurrentBoard
        lda     CurrentBoardRowAddrL,x
        sta     RowAddrL
        lda     CurrentBoardRowAddrH,x
        sta     RowAddrH
        ; Now check if the tile can be entered or not
        lda     (RowAddrL),y
        rts


; Input:
;   A = tile ID
;
; Output:
;   EQ if so, NE if not
IsTileEnterable:
        jsr     GetTile
        cmp     #$20                        ; space
        beq     @done
        cmp     #$92                        ; dot
        beq     @done
        cmp     #$95                        ; energizer
        beq     @done
        cmp     #$90                        ; enterable mask
@done:
        rts


; Some codes:
;   $20 = blank, enterable
;   $80 = mask, non-enterable (blank tile that sprites should move behind instead of in front of)
;   $90 = mask, enterable
;   $92 = dot
;   $95 = energizer
FullBoardCompressed:
    .incbin "../assets/map.lzss"

;FullBoardRowAddrL:
;.repeat I, 31
;    .byte <FullBoard+(32*I)
;.endrepeat
;
;FullBoardRowAddrH:
;.repeat I, 31
;    .byte <FullBoard+(32*I)
;.endrepeat

CurrentBoardRowAddrL:
.repeat 31, I
    .byte <CurrentBoard+(32*I)
.endrepeat

CurrentBoardRowAddrH:
.repeat 31, I
    .byte >(CurrentBoard+(32*I))
.endrepeat
