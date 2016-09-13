.segment "CODE"

StartBlinky:
        ldx     #BLINKY
        jsr     InitGhost
        jmp     GhostActive

StartPinky:
        ldx     #PINKY
        jsr     InitGhost
        jmp     GhostWaiting

StartInky:
        ldx     #INKY
        jsr     InitGhost
        jmp     GhostWaiting

StartClyde:
        ldx     #CLYDE
        jmp     GhostWaiting


InitGhost:
        stx     GhostId
        ???
        rts


GhostWaiting:
        lda     #Speed40
        sta     GhostsSpeed,x
        jsr     CanGhostLeave
        bcs     GhostBeginLeaving
        jsr     MoveGhostWaiting
        jsr     NextThread
        jmp     GhostWaiting

GhostLeaveCenterV:
        jsr     IsGhostVCentered
        bcs     GhostLeaveCenterH
        jsr     MoveGhostTowardVCenter
        jsr     NextThread
        jmp     GhostLeaveCenterV

GhostLeaveCenterH:
        jsr     IsGhostHCentered
        bcs     GhostLeaveNorthward
        jsr     MoveGhostTowardHCenter
        jsr     NextThread
        jmp     GhostLeaveCenterH

; @TODO@ -- check collisions with Pac-Man?
GhostLeaveNorthward:
        jsr     MoveGhostNorthward
        jsr     NextThread
        jsr     HasGhostLeft
        bcc     GhostLeaveNorthward
        ; FALL THROUGH to GhostActive

GhostActive:
        jsr     MoveGhostToCenter
        ???


MoveGhostToCenter:
        jsr     SetActiveGhostSpeed
        jsr     IsGhostCenteredOnTile
        bcs     @end
        jsr     MoveGhostTowardCenterOfTile
        jsr     NextThread
        jmp     MoveGhostToCenter
@end:
        rts
