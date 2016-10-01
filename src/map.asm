; Some codes used in the map:
;   $20 = blank, enterable
;   $80 = mask, non-enterable (blank tile that sprites should move behind instead of in front of)
;   $90 = mask, enterable
;   $92 = dot
;   $95 = energizer

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
        sty     AL
        ldy     #0
        sta     (pCurrentBoardL),y
        inc     pCurrentBoardL
        inc_z   pCurrentBoardH
        ldy     AL
        rts


CopyBoardIntoVram:
        ; Load first nametable
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #<CurrentBoard
        sta     AL
        lda     #>CurrentBoard
        sta     AH
        ldx     #30
@copy_row:
        ldy     #0
@copy_cell:
        lda     (AX),y
        sta     PPUDATA
        iny
        cpy     #32
        bne     @copy_cell
        ; Finished this row; bump pointer by a row
        lda     AL
        add     #32
        sta     AL
        inc_cs  AH
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

        ; Attributes for fruit area (X=11..20, Y=16..18)
        ; It's wide to accommodate the "GAME OVER" message
        stx     PPUADDR
        lda     #$e2
        sta     PPUADDR
        lda     #%11001100
        sta     PPUDATA
        lda     #%11111111
        sta     PPUDATA
        sta     PPUDATA
        lda     #%00110011
        sta     PPUDATA

        ; Attributes for status area
        lda     #$2b
        sta     PPUADDR
        lda     #$f8
        sta     PPUADDR
        lda     #%10101010
        ldx     #8
@loop2:
        sta     PPUDATA
        dex
        bne     @loop2

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
;   X = X coordinate
;   Y = Y coordinate
;
; Output:
;   A = the tile
;   RowAddr = address of row of tile
;
; Won't touch AX
GetTile:
        ; RowAddr := CurrentBoard + Y*32
        ; Note that Y's max value is 31, hence we don't start ROLling until
        ; carry is a possibility
        lda     #0
        sta     RowAddrH
        tya
        asl
        asl
        asl
        asl
        rol     RowAddrH
        asl
        rol     RowAddrH

        add     #<CurrentBoard
        sta     RowAddrL
        lda     #>CurrentBoard
        adc     RowAddrH
        sta     RowAddrH

        ; Now check if the tile can be entered or not
        txa
        tay
        lda     (RowAddrL),y
        rts


; Input:
;   Same as GetTile
;
; Output:
;   EQ if so, NE if not
;
; Won't touch AX
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


FullBoardCompressed:
    .incbin "../assets/map.lzss"
