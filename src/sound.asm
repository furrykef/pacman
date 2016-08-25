A0      = $00
As0     = $01
B0      = $02
C1      = $03
Cs1     = $04
D1      = $05
Ds1     = $06
E1      = $07
F1      = $08
Fs1     = $09
G1      = $0a
Gs1     = $0b
A1      = $0c
As1     = $0d
B1      = $0e
C2      = $0f
Cs2     = $10
D2      = $11
Ds2     = $12
E2      = $13
F2      = $14
Fs2     = $15
G2      = $16
Gs2     = $17
A2      = $18
As2     = $19
B2      = $1a
C3      = $1b
Cs3     = $1c
D3      = $1d
Ds3     = $1e
E3      = $1f
F3      = $20
Fs3     = $21
G3      = $22
Gs3     = $23
A3      = $24
As3     = $25
B3      = $26
C4      = $27
Cs4     = $28
D4      = $29
Ds4     = $2a
E4      = $2b
F4      = $2c
Fs4     = $2d
G4      = $2e
Gs4     = $2f
A4      = $30
As4     = $31
B4      = $32
C5      = $33
Cs5     = $34
D5      = $35
Ds5     = $36
E5      = $37
F5      = $38
Fs5     = $39
G5      = $3a
Gs5     = $3b
A5      = $3c
As5     = $3d
B5      = $3e
C6      = $3f
Cs6     = $40
D6      = $41
Ds6     = $42
E6      = $43
F6      = $44
Fs6     = $45
G6      = $46
Gs6     = $47
A6      = $48
As6     = $49
B6      = $4a

LEN_BASE    = $60
DUR_BASE    = $80
CMD_BASE    = $f0

NEXT        = CMD_BASE+0
END         = CMD_BASE+1
DUTYVOL     = CMD_BASE+2
REST        = CMD_BASE+3
REPEAT      = CMD_BASE+4

.define LEN(length)     LEN_BASE + (length)
.define DUR(duration)   DUR_BASE + (duration)


.segment "ZEROPAGE"

; Order is significant
.enum
        SQ1
        SQ2
        TRI
        NOISE
        DMC
.endenum

BGM:                .res 1
PrevBGM:            .res 1

; SfxT = Sound effect trigger
SfxTMunchDot:       .res 1                  ; 0 = none; 1 = SfxMunchDot1; 2 = SfxMunchDot2
fSfxTEatingGhost:   .res 1

; One byte per channel
pPatternListL:      .res 3
pPatternListH:      .res 3
PatternListIdx:     .res 3
PatternIdx:         .res 3
Wait:               .res 3
LengthCounter:      .res 3
NoteDuration:       .res 3
NoteLength:         .res 3

CurChannel:         .res 1
pCurPatternL:       .res 1
pCurPatternH:       .res 1

SoundTmpL:          .res 1
SoundTmpH:          .res 1


.segment "CODE"

InitSound:
        ldx     #-1                         ; will force SoundTick to initialize BGM
        stx     PrevBGM
        inx
        stx     BGM
        stx     SfxTMunchDot
        stx     fSfxTEatingGhost
        jsr     SoundOn

        ; Init sound regs
        lda     #0
        sta     $4011                       ; DMC counter
        sta     $4000                       ; pulse 1 volume
        sta     $4001                       ; pulse 1 sweep
        sta     $4004                       ; pulse 2 volume
        sta     $4005                       ; pulse 2 sweep
        ldx     #$81
        stx     $4008                       ; tri linear counter setup
        sta     $400a                       ; tri period low
        sta     $400b                       ; tri period high
        rts


SoundOff:
        lda     #0
        sta     $4015
        rts

SoundOn:
        lda     #$07
        sta     $4015
        rts


; NB: This routine (or anything it calls) must NOT clobber temp
; variables like TmpL that can be used by other modules
SoundTick:
        lda     BGM
        cmp     PrevBGM
        beq     :+
        jsr     SetBGM
:

        ldx     SfxTMunchDot
        beq     :+
        ; Munching a dot
        dex
        lda     SfxMunchDotLTbl,x
        sta     pPatternListL
        lda     SfxMunchDotHTbl,x
        sta     pPatternListH
        ldx     #0                          ; channel #0
        stx     SfxTMunchDot                ; also handy for clearing this
        jsr     InitChannel
:
        ldx     fSfxTEatingGhost
        beq     :+
        lda     #<SfxEatingGhostPatternList
        sta     pPatternListL
        lda     #>SfxEatingGhostPatternList
        sta     pPatternListH
        ldx     #0                          ; channel #0
        stx     fSfxTEatingGhost            ; also handy for clearing this
        jsr     InitChannel
:

        ldx     #2
@loop:
        stx     CurChannel
        jsr     ChannelTick
        ldx     CurChannel                  ; X might have gotten clobbered
        dex
        bpl     @loop

        rts


; Input:
;   A = number of tune
;
; Must not clobber temp variables used by other modules
; (called by SoundTick)
SetBGM:
        sta     PrevBGM
        pha

        ldx     #2
@init_loop:
        jsr     InitChannel
        dex
        bpl     @init_loop

        pla
        tax

        ; Get pointer to song data from song table
        lda     SongTbl,x
        sta     SoundTmpL
        inx
        lda     SongTbl,x
        sta     SoundTmpH

        ; Load pointers to pattern lists from song data table.
        ; We load the high byte first so we can skip the load if the
        ; high byte is zero.
        ldy     #0
        ldx     #0
@load_pattern_list:
        iny
        lda     (SoundTmpL),y
        beq     @skip
        sta     pPatternListH,x
        dey
        lda     (SoundTmpL),y
        sta     pPatternListL,x
        iny
@skip:
        iny
        inx
        cpx     #3
        blt     @load_pattern_list
        rts


; Input:
;   X = number of channel to init
InitChannel:
        lda     #0
        sta     PatternListIdx,x
        sta     PatternIdx,x
        sta     Wait,x
        sta     LengthCounter,x
        rts


; Input:
;   X = CurChannel = number of channel to process
ChannelTick:
        ; Keep processing commands until we get a wait
        ; (END generates a wait for this reason)
        lda     Wait,x
        bne     @waiting
        jsr     NextPatternCmd
        ldx     CurChannel                  ; might have gotten clobbered
        jmp     ChannelTick
@waiting:
        dec     Wait,x
        lda     LengthCounter,x
        bne     @end
        ; Duration ended; silence channel
        txa
        asl
        asl
        tay
        lda     #0
        sta     $4002,y
        sta     $4003,y
        rts
@end:
        dec     LengthCounter,x
        rts


; Input:
;   CurChannel = number of channel to process
NextPatternCmd:
        ldx     CurChannel
        lda     pPatternListL,x
        sta     SoundTmpL
        lda     pPatternListH,x
        sta     SoundTmpH
        ldy     PatternListIdx,x
        lda     (SoundTmpL),y
        sta     pCurPatternL
        iny
        lda     (SoundTmpL),y
        sta     pCurPatternH

        ldy     PatternIdx,x
        lda     (pCurPatternL),y
        iny
        sty     PatternIdx,x
        cmp     #LEN_BASE
        blt     @handle_note
        cmp     #DUR_BASE
        blt     @handle_length
        cmp     #CMD_BASE
        blt     @handle_duration
        ; Handle command
        sub     #CMD_BASE
        tay
        lda     CmdLTbl,y
        sta     SoundTmpL
        lda     CmdHTbl,y
        sta     SoundTmpH
        jmp     (SoundTmpL)

@handle_note:
        tay
        lda     NoteDuration,x
        sta     Wait,x
        lda     NoteLength,x
        sta     LengthCounter,x
        txa
        asl
        asl
        tax
        lda     PeriodLTbl,y
        sta     $4002,x
        lda     PeriodHTbl,y
        sta     $4003,x
        rts

@handle_length:
        sub     #LEN_BASE
        sta     NoteLength,x
        rts

@handle_duration:
        sub     #DUR_BASE
        sta     NoteDuration,x
        rts


CmdNext:
        inc     PatternListIdx,x
        inc     PatternListIdx,x
        lda     #0
        sta     PatternIdx,x
        rts


CmdEnd:
        dec     PatternIdx,x                ; point back at END command so we loop infinitely
        lda     #$ff                        ; force moving to next channel
        sta     Wait,x
        rts

CmdDutyVol:
        ldy     PatternIdx,x
        inc     PatternIdx,x
        lda     (pCurPatternL),y
        pha
        txa
        asl
        asl
        tax
        pla
        sta     $4000,x
        rts


CmdRest:
        lda     NoteDuration,x
        sta     Wait,x
        lda     #0
        sta     LengthCounter,x
        rts


CmdRepeat:
        lda     #0
        sta     PatternListIdx,x
        sta     PatternIdx,x
        rts


CmdLTbl:
        .byte   <CmdNext, <CmdEnd, <CmdDutyVol, <CmdRest, <CmdRepeat
CmdHTbl:
        .byte   >CmdNext, >CmdEnd, >CmdDutyVol, >CmdRest, >CmdRepeat


BGM_NONE    = 0
BGM_INTRO   = 2
BGM_ALARM1  = 4
BGM_ENERGIZER = 6

SongTbl:
        .addr   BgmNone
        .addr   BgmIntro
        .addr   BgmAlarm1
        .addr   BgmEnergizer


BgmNone:
        .addr   NullPatternList
        .addr   NullPatternList
        .addr   NullPatternList

NullPatternList:
        .addr   NullPattern

NullPattern:
        .byte   END


BgmIntro:
        .addr   BgmIntroSq1
        .addr   BgmIntroSq2
        .addr   BgmIntroTri

BgmIntroSq1:
        .addr   BgmIntroSq1Init
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern2
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern3

BgmIntroSq2:
        .addr   BgmIntroSq2Init
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern2
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern3

BgmIntroTri:
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern2
        .addr   BgmIntroTriPattern2
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern3

BgmIntroSq1Init:
        .byte   DUTYVOL, $9a, NEXT

BgmIntroSq2Init:
        .byte   DUR(4), REST, DUTYVOL, $b3, NEXT

BgmIntroSqPattern1:
        .byte   LEN(4)
        .byte   DUR(8), C4, C5, G4, E4
        .byte   DUR(4), C5, DUR(12), G4
        .byte   DUR(16), LEN(12), E4
        .byte   NEXT

BgmIntroSqPattern2:
        .byte   LEN(4)
        .byte   DUR(8), Cs4, Cs5, Gs4, F4
        .byte   DUR(4), Cs5, DUR(12), Gs4
        .byte   DUR(16), LEN(12), F4
        .byte   NEXT

BgmIntroSqPattern3:
        .byte   LEN(4)
        .byte   DUR(4), Ds4, E4, F4, REST
        .byte   F4, Fs4, G4, REST
        .byte   G4, Gs4, A4, REST
        .byte   LEN(8), DUR(8), C5
        .byte   END

BgmIntroTriPattern1:
        .byte   LEN(20), DUR(24), C2
        .byte   LEN(7), DUR(8), G2
        .byte   NEXT

BgmIntroTriPattern2:
        .byte   LEN(20), DUR(24), Cs2
        .byte   LEN(7), DUR(8), Gs2
        .byte   NEXT

BgmIntroTriPattern3:
        .byte   LEN(12), DUR(16)
        .byte   G2, A2, B2, C3
        .byte   END


BgmAlarm1:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm1PatternList

BgmAlarm1PatternList:
        .addr   BgmAlarm1Pattern

BgmAlarm1Pattern:
        .byte   DUR(1), LEN(2)
        .byte   As4, B4, C5, Cs5, D5, Ds5, E5, F5, Fs5, G5, Gs5, A5
        .byte   As5, A5, Gs5, G5, Fs5, F5, E5, Ds5, D5, Cs5, C5, B4
        .byte   REPEAT


BgmEnergizer:
        .addr   0
        .addr   BgmEnergizerPatternList
        .addr   NullPatternList

BgmEnergizerPatternList:
        .addr   BgmEnergizerPattern

BgmEnergizerPattern:
        .byte   DUTYVOL, $98, DUR(1), LEN(2)
        .byte   Cs4, Gs4, Cs5, DUR(2), F5, Gs5, B5, C6
        .byte   REPEAT


SfxEatingGhostPatternList:
        .addr   SfxEatingGhostPattern

SfxEatingGhostPattern:
        .byte   DUTYVOL, $9f, LEN(2)
        .byte   DUR(1), Cs2
        .byte   DUR(2), E3
        .byte   DUR(1), Gs3
        .byte   DUR(2), C4
        .byte   DUR(1), Ds4
        .byte   DUR(2), E4
        .byte   DUR(1), Fs4
        .byte   DUR(2), G4
        .byte   DUR(1), Gs4
        .byte   DUR(2), A4
        .byte   DUR(1), As4
        .byte   DUR(2), B4
        .byte   DUR(1), C5
        .byte   DUR(2), Cs5
        .byte   DUR(1), D5
        .byte   DUR(2), Ds5
        .byte   DUR(1), E5
        .byte   DUR(2), F5
        .byte   DUR(1), Fs5
        .byte   LEN(1), G5
        .byte   END


SfxMunchDotLTbl:
        .byte   <SfxMunchDot1PatternList, <SfxMunchDot2PatternList
SfxMunchDotHTbl:
        .byte   >SfxMunchDot1PatternList, >SfxMunchDot2PatternList

SfxMunchDot1PatternList:
        .addr   SfxMunchDot1Pattern

SfxMunchDot2PatternList:
        .addr   SfxMunchDot2Pattern

SfxMunchDot1Pattern:
        .byte   DUTYVOL, $1f, DUR(1), LEN(1)
        .byte   E2, As2, Ds3, Fs3, A3
        .byte   END

SfxMunchDot2Pattern:
        .byte   DUTYVOL, $1f, DUR(1), LEN(1)
        .byte   B3, Gs3, F3, Cs3, Gs2
        .byte   END


; From http://wiki.nesdev.com/w/index.php/APU_period_table
PeriodLTbl:
        .byte   $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
        .byte   $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
        .byte   $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
        .byte   $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
        .byte   $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
        .byte   $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
        .byte   $1f,$1d,$1b,$1a,$18,$17,$15,$14

PeriodHTbl:
        .byte   $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
        .byte   $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
