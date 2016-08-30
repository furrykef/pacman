.segment "ZEROPAGE"

OamPtrL:            .res 1
OamPtrH:            .res 1
SprX:               .res 1
SprY:               .res 1
SprStartPattern:    .res 1
SprAttrib:          .res 1


.segment "CODE"

DrawSprite16x16:
        ; Y position
        lda     SprY
        add     #24                         ; -8 to get top edge, +32 to compensate for status
        bcc     @not_too_low
        ; Carry here means sprite is at very bottom of the maze and its
        ; Y coordinate is >= 256. This means it has not wrapped around
        ; and will not need to be hidden
        sub     VScroll
        jmp     @scroll_ok
@not_too_low:
        sub     VScroll
        bcs     @scroll_ok
        ; Sprite has gone off the top of the screen and wrapped around
        ; Hide it so it won't peek up from the bottom
        lda     #$ff
@scroll_ok:

        ; Hide sprite if it's in status area
        cmp     #16
        bge     :+
        lda     #$ff                        ; hide upper half
:
        ldy     #0
        sta     (OamPtrL),y
        ldy     #4
        sta     (OamPtrL),y

        ; PatternID
        lda     SprStartPattern
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


HideSprite16x16:
        lda     #$ff
        ldy     #0
        sta     (OamPtrL),y
        ldy     #4
        sta     (OamPtrL),y
        rts
