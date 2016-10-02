; Some codes used in the map:
;   $20 = blank, enterable
;   $80 = mask, non-enterable (blank tile that sprites should move behind instead of in front of)
;   $90 = mask, enterable
;   $92 = dot
;   $95 = energizer

SPACE           = $20                       ; enterable
ENTERABLE_MASK  = $90
DOT             = $92
ENERGIZER       = $95


; Values of bit pairs
.enum
    BMP_WALL                                ; must be zero
    BMP_EMPTY
    BMP_DOT
    BMP_ENERGIZER
.endenum


BMP_BYTES_PER_ROW = 8


.segment "ZEROPAGE"

; Used during LZSS decoding
MapX:       .res 1
MapY:       .res 1

pCurrentBoardL: .res 1
pCurrentBoardH: .res 1


.segment "BSS"

P1Board:    .res BMP_BYTES_PER_ROW*31
P2Board:    .res BMP_BYTES_PER_ROW*31


.segment "CODE"

NewBoard:
        ; @TODO@ -- move this somewhere appropriate and support 2-player mode
        lda     #<P1Board
        sta     pCurrentBoardL
        lda     #>P1Board
        sta     pCurrentBoardH
        ; end TODO

        jsr     PrepMapDecode
        lda     #<NewBoardTile
        sta     JsrIndAddrL
        lda     #>NewBoardTile
        sta     JsrIndAddrH
        jmp     LzssDecode


NewBoardTile:
        ldy     MapY
        cpy     #30
        bge     @end
        ldx     MapX
        cmp     #SPACE
        beq     @empty
        cmp     #ENTERABLE_MASK
        beq     @empty
        cmp     #DOT
        beq     @dot
        cmp     #ENERGIZER
        beq     @energizer
        ; Wall
        lda     #BMP_WALL
        bpl     @set                        ; always taken
@empty:
        lda     #BMP_EMPTY
        bpl     @set
@dot:
        lda     #BMP_DOT
        bpl     @set
@energizer:
        lda     #BMP_ENERGIZER
@set:
        jsr     SetTile
        jsr     BumpMapCoords
@end:
        rts


; Call while rendering is disabled
LoadBoardIntoVram:
        jsr     PrepMapDecode
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #<LoadTileIntoVram
        sta     JsrIndAddrL
        lda     #>LoadTileIntoVram
        sta     JsrIndAddrH
        jmp     LzssDecode

LoadTileIntoVram:
        ldy     MapY
        cpy     #30
        bge     @copy
        cmp     #ENTERABLE_MASK             ; special-cased since this is BMP_EMPTY in the bitmap
        beq     @copy
        ldx     MapX
        pha
        jsr     GetTile
        tax
        pla
        cpx     #BMP_WALL
        beq     @copy
        lda     BmpTileToVramTileTbl,x
@copy:
        sta     PPUDATA
        jsr     BumpMapCoords
        rts

BmpTileToVramTileTbl:
        .byte   0                           ; wall (dummy value)
        .byte   SPACE
        .byte   DOT
        .byte   ENERGIZER


PrepMapDecode:
        lda     #<FullBoardCompressed
        sta     pCompressedDataL
        lda     #>FullBoardCompressed
        sta     pCompressedDataH
        lda     #0
        sta     MapX
        sta     MapY
        rts


; Won't touch X
BumpMapCoords:
        inc     MapX

        ; if MapX % 32 == 0...
        lda     MapX
        and     #31
        bne     @end

        ; ...then we finished this row; move to the next one
        sta     MapX                        ; stores zero
        inc     MapY
@end:
        rts


; Input:
;   X = X coord (clobbered)
;   Y = Y coord (clobbered)
;
; Output:
;   A = value of tile
;   flags will be set according to the value of A
;
; Clobbers AX
;
; If the X coord is >= 32, it wraps around (i.e. mod 32)
; If the Y coord is >= 30, return wall.
; These don't necessarily apply to other map routines.
GetTile:
        cpy     #30
        bge     @wall

        ; X %= 32 (wrap around)
        txa
        and     #31
        tax

        jsr     CalcMapIndex

        ; Shift the bit pair of interest into the least significant position
        lda     (pCurrentBoardL),y
        cpx     #0
        beq     @skip_shift
@shift:
        lsr
        dex
        bne     @shift
@skip_shift:

        ; Mask out all the other bits
        and     #$03
        rts

@wall:
        lda     #BMP_WALL
        rts


; Input:
;   A = value of tile
;   X = X coord (clobbered)
;   Y = Y coord (clobbered)
;
; Clobbers AX
SetTile:
        pha
        jsr     CalcMapIndex
        pla
        sta     AL

        ; Set up a bitmask to clear a pair of bits
        ; Rotate it left one bits for each X
        lda     #%11111100
        cpx     #0
        beq     @skip_shift
@shift:
        sec
        rol
        asl     AL
        dex
        bne     @shift
@skip_shift:

        and     (pCurrentBoardL),y          ; Clear the bits in the maze data
        ora     AL                          ; Add in the new bits
        sta     (pCurrentBoardL),y
        rts


; Input:
;   X = X coord
;   Y = Y coord
;
; Output:
;   X = X % 4 * 2 (number of bits to shift)
;   Y = byte offset into map
;   AX = clobbered
CalcMapIndex:
        ; AL = Y*BMP_BYTES_PER_ROW
        lda     #0
        cpy     #0
        beq     @skip_multiply
@multiply:
        add     #BMP_BYTES_PER_ROW
        dey
        bne     @multiply
@skip_multiply:
        sta     AL

        ; Y = AL + X/4
        txa
        lsr
        lsr
        add     AL
        tay

        ; Y is now an index into a byte in the map
        ; X = X % 4 * 2
        txa
        and     #$03
        asl
        tax

        rts


; Input:
;   Same as GetTile
;
; Output:
;   EQ if so, NE if not (@TODO@ - reverse this?)
;
; Clobbers AX
IsTileEnterable:
        jsr     GetTile
        beq     @wall
        lda     #0
        rts
@wall:
        lda     #1
        rts


FullBoardCompressed:
    .incbin "../assets/board.nam.lzss"
