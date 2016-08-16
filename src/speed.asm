; Speed names are percentages in the Pac-Man Dossier
; e.g. Spd80 is the speed given as 80% in the Dossier
; These are expressed in 32nds of a pixel per tick

Speed40  = 8
Speed45  = 9
Speed50  = 10
Speed55  = 11
Speed60  = 12
Speed75  = 15
Speed80  = 16
Speed85  = 17
Speed90  = 18
Speed95  = 19
Speed100 = 20
Speed105 = 22
SpeedMax = 32


.macro _AddSpeedBody
.local @end
        cmp     #32
        blt     @end                        ; carry will be clear
        and     #$1f                        ; mod by 32
        sec
@end:
.endmacro


; Input:
;   A = speed to add
;
; Output:
;   carry = set if character should move a pixel, clear if not
.macro AddSpeed move_counter
        add     move_counter
        _AddSpeedBody
        sta     move_counter
.endmacro

.macro AddSpeedX move_counter
        add     move_counter,x
        _AddSpeedBody
        sta     move_counter,x
.endmacro
