.segment "ZEROPAGE"

SprX:               .res 1
SprY:               .res 1
SprStartPattern:    .res 1
SprAttrib:          .res 1

; This requires a little explanation...
; Sometimes during intermissions a sprite will have a position (such as X=255)
; such that the left half of the sprite will be at the right side of the screen
; and vice versa. If we do nothing about it, the sprite will be seen on both
; sides at once. This flag tells us which half to hide. If it's zero, the
; sprite will poke out of the left side of the screen; if it's nonzero, it will
; poke out of the right.
fSprAtLeftEdge:     .res 1


.segment "CODE"

; Y = OAM index (not clobbered)
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
        sta     MyOAM,y
        sta     MyOAM+4,y

        ; PatternID
        lda     SprStartPattern
        add     #1                          ; use $1000-1fff for sprites
        sta     MyOAM+1,y
        add     #2
        sta     MyOAM+5,y

        ; Attributes
        ; Flip priority if sprite is at edges of tunnel
        lda     SprX
        lsr
        lsr
        lsr
        tax
        lda     SprAttrib
        cpx     #3
        blt     @flip
        cpx     #29
        blt     @no_flip
@flip:
        ora     #$20
@no_flip:
        sta     MyOAM+2,y
        sta     MyOAM+6,y

        ; X position of left half
        lda     SprX
        sub     #7
        ldx     fSprAtLeftEdge
        beq     :+
        cmp     #256 - 8
        blt     :+
        ; Hide left half of sprite
        pha                                 ; we'll need the X coordinate again
        lda     #$ff
        sta     MyOAM,y
        pla                                 ; get back X coord of left half of sprite
:
        sta     MyOAM+3,y

        ; X position of right half
        add     #8
        ldx     fSprAtLeftEdge
        bne     :+
        cmp     #8
        bge     :+
        ; Hide right half of sprite
        lda     #$ff
        sta     MyOAM+4,y
:
        sta     MyOAM+7,y

        rts


HideSprite16x16:
        lda     #$ff
        sta     MyOAM,y
        sta     MyOAM+4,y
        rts
