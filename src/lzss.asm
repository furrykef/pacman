; Description of our LZSS format:
;
; The stream is divided into chunks that are in turn divided into (up to) eight
; subchunks. Each chunk has a one-byte header called the flags byte.
;
; For each bit in the flags byte:
;   If it's 0, the next subchunk is a literal byte.
;   If it's 1, the next subchunk is a backref.
;
; Backrefs are two bytes, a length byte and an index byte.
; A length of zero signifies the end of the stream.
; Indexes are absolute (not relative) indexes into the LZSS sliding window,
; implemented here as a 256-byte circular buffer.

.segment "ZEROPAGE"

pCompressedDataL:   .res 1
pCompressedDataH:   .res 1
LzssFlagCount:      .res 1
LzssFlags:          .res 1
LzssSrcIdx:         .res 1
LzssBackrefLen:     .res 1
LzssTmpX:           .res 1
LzssTmpY:           .res 1


.segment "BSS"

LzssBuf:            .res 256


.segment "CODE"

; Algorithm ends when backref size is 0.
; Backreference indexes are absolute, not relative offsets.
;
; Input:
;   JsrInd: Called for every byte output
;   pCompressedData: Pointer to compressed data
LzssDecode:
        ldx     #0
        ldy     #0
@process_chunk:
        lda     #8
        sta     LzssFlagCount
        lda     (pCompressedDataL),y
        sta     LzssFlags
        jsr     BumpPtr
@process_subchunks:
        lsr     LzssFlags
        bcs     @backref
        ; Not a backref; copy one byte
        lda     (pCompressedDataL),y
        jsr     BumpPtr
        sta     LzssBuf,x
        inx
        stx     LzssTmpX
        sty     LzssTmpY
        jsr     JsrInd
        ldx     LzssTmpX
        ldy     LzssTmpY
        jmp     @subchunk_processed

@backref:
        ; Get backref length
        lda     (pCompressedDataL),y
        beq     @end
        jsr     BumpPtr
        sta     LzssBackrefLen

        ; Get backref source index
        lda     (pCompressedDataL),y
        jsr     BumpPtr
        sty     LzssSrcIdx
        tay

        ; Process the backref
@backref_loop:
        lda     LzssBuf,y
        iny
        sta     LzssBuf,x
        inx
        stx     LzssTmpX
        sty     LzssTmpY
        jsr     JsrInd
        ldx     LzssTmpX
        ldy     LzssTmpY
        dec     LzssBackrefLen
        bne     @backref_loop

        ldy     LzssSrcIdx

@subchunk_processed:
        dec     LzssFlagCount
        bne     @process_subchunks
        beq     @process_chunk

@end:
        rts


BumpPtr:
        iny
        inc_z   pCompressedDataH
        rts
