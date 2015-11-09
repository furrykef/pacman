.segment "ZEROPAGE"

FruitClockL:        .res 1
FruitClockH:        .res 1


.segment "CODE"

InitFruit:
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        rts


SpawnFruit:
        lda     #<10*60
        sta     FruitClockL
        lda     #>10*60
        sta     FruitClockH

        ldx     DisplayListIndex
        lda     #2
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$0f
        sta     DisplayList,x
        inx
        lda     #$d0
        sta     DisplayList,x
        inx
        lda     #$d1
        sta     DisplayList,x
        inx
        ; Clear space to the left and right of the fruit as well
        ; (in case bonus points have been drawn here)
        lda     #4
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$2e
        sta     DisplayList,x
        inx
        lda     #$20
        sta     DisplayList,x
        inx
        lda     #$e0
        sta     DisplayList,x
        inx
        lda     #$e1
        sta     DisplayList,x
        inx
        lda     #$20
        sta     DisplayList,x
        inx
        lda     #2
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$4f
        sta     DisplayList,x
        inx
        lda     #$f0
        sta     DisplayList,x
        inx
        lda     #$f1
        sta     DisplayList,x
        inx
        stx     DisplayListIndex

        rts
