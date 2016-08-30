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
        cmp     #22
        bge     :+
        lda     #$ff                        ; hide upper half
:
        ldy     #0
        sta     (OamPtrL),y
        ldy     #8
        sta     (OamPtrL),y
        add     #8
        cmp     #22
        bge     :+
        lda     #$ff                        ; hide lower half
:
        ldy     #4
        sta     (OamPtrL),y
        ldy     #12
        sta     (OamPtrL),y

        ; Tile
        lda     SprStartTile
        ldy     #1
        sta     (OamPtrL),y
        add     #1
        ldy     #5
        sta     (OamPtrL),y
        adc     #1
        ldy     #9
        sta     (OamPtrL),y
        adc     #1
        ldy     #13
        sta     (OamPtrL),y

        ; Attributes
        lda     SprAttrib
        ldy     #2
        sta     (OamPtrL),y
        ldy     #6
        sta     (OamPtrL),y
        ldy     #10
        sta     (OamPtrL),y
        ldy     #14
        sta     (OamPtrL),y

        ; X position
        lda     SprX
        sub     #7
        ldy     #3
        sta     (OamPtrL),y
        ldy     #7
        sta     (OamPtrL),y
        add     #8
        ldy     #11
        sta     (OamPtrL),y
        ldy     #15
        sta     (OamPtrL),y

        rts
