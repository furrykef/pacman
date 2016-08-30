.segment "ZEROPAGE"

OamPtrL:        .res 1
OamPtrH:        .res 1
SprX:           .res 1
SprY:           .res 1
SprStartTile:   .res 1
SprAttrib:      .res 1


.segment "CODE"

DrawSprite16x16:
        ; Y position
        ; But hide sprite if it's too far behind status area
        lda     SprY
        cmp     #16
        bge     :+
        lda     #$ff                        ; hide upper half
:
        ldy     #0
        sta     (OamPtrL),y
        ldy     #4
        sta     (OamPtrL),y

        ; Tile
        lda     SprStartTile
        add     #1
        ldy     #1
        sta     (OamPtrL),y
        add     #2
        ldy     #5
        sta     (OamPtrL),y

        ; Attributes
        ; Flip priority if sprite is at edges of tunnel
        lda     SprX
        lsr
        lsr
        lsr
        tay
        lda     SprAttrib
        cpy     #3
        blt     @flip
        cpy     #29
        blt     @no_flip
@flip:
        ora     #$20
@no_flip:
        ldy     #2
        sta     (OamPtrL),y
        ldy     #6
        sta     (OamPtrL),y

        ; X position
        lda     SprX
        sub     #7
        ldy     #3
        sta     (OamPtrL),y
        add     #8
        ldy     #7
        sta     (OamPtrL),y

        rts
