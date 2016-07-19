.segment "ZEROPAGE"

fSoundOn:           .res 1

pSq1PatternListL:   .res 1
pSq1PatternListH:   .res 1
Sq1PatternNum:      .res 1
Sq1PatternPos:      .res 1
Sq1Wait:            .res 1

pSq2PatternListL:   .res 1
pSq2PatternListH:   .res 1
Sq2PatternNum:      .res 1
Sq2PatternPos:      .res 1
Sq2Wait:            .res 1

pTriPatternListL:   .res 1
pTriPatternListH:   .res 1
TriPatternNum:      .res 1
TriPatternPos:      .res 1
TriWait:            .res 1

pPatternL:          .res 1
pPatternH:          .res 1


.segment "CODE"

InitSound:
        ; Init APU
        XXX

        ldx     #-1                         ; will force SoundTick to initialize BGM
        stx     PrevBGM
        inx
        stx     BGM

        rts


; NB: This routine (or anything it calls) must NOT clobber temp
; variables like Tmp that can be used by other modules
SoundTick:
        lda     fSoundOn
        beq     @end

        lda     BGM
        cmp     PrevBGM
        beq     :+
        jsr     SetBGM
:

@end:
        rts


; Input:
;   A = number of tune
;
; Must not clobber temp variables
SetBGM:
        ldx     #0
        stx     fSoundOn

        asl
        tax

        XXX

        ; Init sound regs
        XXX

        lda     #1
        sta     fSoundOn
        rts


SongTbl:
        .addr   BgmNone
        .addr   BgmIntro
        .addr   BgmAlarm1
