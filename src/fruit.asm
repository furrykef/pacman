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

        DlBegin
        DlAdd   #2, #$22, #$0f
        DlAdd   #$d0, #$d1
        ; Clear space to the left and right of the fruit as well
        ; (in case bonus points have been drawn here)
        DlAdd   #4, #$22, #$2e
        DlAdd   #$20, #$e0, #$e1, #$20
        DlAdd   #2, #$22, #$4f
        DlAdd   #$f0, #$f1
        DlEnd

        rts
