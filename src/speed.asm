; Speed names are percentages in the Pac-Man Dossier
; e.g. Spd80 is the speed given as 80% in the Dossier
; The numbers (before shifting) are expressed in 32nds of a pixel per tick
; There are two ticks per frame

Speed40  = 8 << 3
Speed45  = 9 << 3
Speed50  = 10 << 3
Speed55  = 11 << 3
Speed60  = 12 << 3
Speed75  = 15 << 3
Speed80  = 16 << 3
Speed85  = 17 << 3
Speed90  = 18 << 3
Speed95  = 19 << 3
Speed100 = 20 << 3
Speed105 = 22 << 3
SpeedMax = $ff


; Input:
;   A = speed to add
;
; Output:
;   carry = set if character should move a pixel, clear if not
.macro AddSpeed move_counter
        add     move_counter
        sta     move_counter
.endmacro

.macro AddSpeedX move_counter
        add     move_counter,x
        sta     move_counter,x
.endmacro
