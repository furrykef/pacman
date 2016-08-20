; Display list doubles as LZSS buffer.
; Don't use LZSS while rendering!

.segment "ZEROPAGE"

pCompressedDataL:   .res 1
pCompressedDataH:   .res 1
LzssFlagCount:      .res 1
LzssFlags:          .res 1
LzssSrcIdx:         .res 1
LzssBackrefLen:     .res 1


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
@outer:
        lda     #8
        sta     LzssFlagCount
        lda     (pCompressedDataL),y
        jsr     BumpPtr
@process_8_chunks:
        lsr
        sta     LzssFlags
        bcs     @backref
        ; Not a backref; copy one byte
        lda     (pCompressedDataL),y
        jsr     BumpPtr
        sta     LzssBuf,x
        inx
        jsr     JsrInd
        jmp     @chunk_processed

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
        jsr     JsrInd
        dec     LzssBackrefLen
        bne     @backref_loop

        ldy     LzssSrcIdx

@chunk_processed:
        lda     LzssFlags
        dec     LzssFlagCount
        bne     @process_8_chunks
        jmp     @outer

@end:
        rts


BumpPtr:
        iny
        bne     :+
        inc     pCompressedDataH
:
        rts
