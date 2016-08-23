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
B1      = $1a
C2      = $1b
Cs2     = $1c
D2      = $1d
Ds2     = $1e
E2      = $1f
F2      = $20
Fs2     = $21
G2      = $22
Gs2     = $23
A2      = $24
As2     = $25
B2      = $26
C3      = $27
Cs3     = $28
D3      = $29
Ds3     = $2a
E3      = $2b
F3      = $2c
Fs3     = $2d
G3      = $2e
Gs3     = $2f
A3      = $30
As3     = $31
B3      = $32
C4      = $33
Cs4     = $34
D4      = $35
Ds4     = $36
E4      = $37
F4      = $38
Fs4     = $39
G4      = $3a
Gs4     = $3b
A4      = $3c
As4     = $3d
B4      = $3e
C5      = $3f
Cs5     = $40
D5      = $41
Ds5     = $42
E5      = $43
F5      = $44
Fs5     = $45
G5      = $46
Gs5     = $47
A5      = $48
As5     = $49
B5      = $4a

LEN_BASE    = $60
DUR_BASE    = $80
VOL_BASE    = $d0
DUTY_BASE   = $e0
CMD_BASE    = $f0

NEXT        = CMD_BASE+0
END         = CMD_BASE+1

.define LEN(length)     LEN_BASE + (length)
.define DUR(duration)   DUR_BASE + (duration)
.define VOL(volume)     VOL_BASE + (volume)
.define DUTY(duty)      DUTY_BASE + (duty)


.segment "ZEROPAGE"

; Order is significant
.enum
        SQ1
        SQ2
        TRI
        NOISE
        DMC
.endenum

fSoundOn:           .res 1

; One byte per channel
pPatternListL:      .res 3
pPatternListH:      .res 3
PatternListIdx:     .res 3
PatternIdx:         .res 3
Wait:               .res 3
NoteDuration:       .res 3
NoteLength:         .res 3
pPatternL:          .res 3
pPatternH:          .res 3

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
        jsr     SoundTick

        rts


; NB: This routine (or anything it calls) must NOT clobber temp
; variables like TmpL that can be used by other modules
SoundTick:
        lda     fSoundOn
        beq     @end

        lda     BGM
        cmp     PrevBGM
        beq     :+
        jsr     SetBGM
:

        ldx     #2
@loop:
        stx     CurChannel
        jsr     PatternTick
        ldx     CurChannel                  ; X might have gotten clobbered
        dex
        bpl     @loop

@end:
        rts


; Input:
;   A = number of tune
;
; Must not clobber temp variables used by other modules
; (called by SoundTick)
SetBGM:
        ldx     #0
        stx     fSoundOn
        ldy     #2
@init_loop:
        stx     PatternListIdx,y
        stx     PatternIdx,y
        stx     Wait,y
        dey
        bpl     @loop

        asl                                 ; 16-bit table entries
        tax

        ; Get pointer to song data from song table
        lda     SongTbl,x
        sta     SoundTmpL
        inx
        lda     SongTbl,x
        sta     SoundTmpH

        ; Load pointers to pattern lists from song data table
        ldy     #0
        ldx     #0
@load_pattern_list:
        lda     (SoundTmpL),y
        sta     pPatternListL,x
        iny
        lda     (SoundTmpL),y
        sta     pPatternListH,x
        iny
        inx
        cpx     #3
        blt     @load_pattern_list

        ; Init sound regs
        lda     #0
        sta     $4015                       ; channel enable
        sta     $4011                       ; DMC counter
        sta     $4001                       ; pulse 1 sweep
        sta     $4005                       ; pulse 2 sweep
        XXX

        lda     #1
        sta     fSoundOn
        rts


; Input:
;   X = CurChannel = number of channel to process
PatternTick:
        ldy     PatternIdx,x
        lda     (pCurPatternL),y
        cmp     #LEN_BASE
        blt     @handle_note
        cmp     #DUR_BASE
        blt     @handle_length
        cmp     #VOL_BASE
        blt     @handle_duration
        cmp     #DUTY_BASE
        blt     @handle_volume
        cmp     #CMD_BASE
        blt     @handle_duty
        ; Handle command
        sub     #CMD_BASE
        tax
        lda     CmdTblL,x
        sta     SoundTmpL
        lda     CmdTblH,x
        sta     SoundTmpH
        jmp     (SoundTmpL)

@handle_note:
        jmp     HandleNote

@handle_length:
        sub     #LEN_BASE
        sta     NoteLength,x
        rts

@handle_duration:
        sub     #DUR_BASE
        sta     NoteDuration,x
        rts

@handle_duty:
        sub     #DUTY_BASE
        sta     NoteDuty,x
        rts


SongTbl:
        .addr   BgmNone
        .addr   BgmIntro
        .addr   BgmAlarm1


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
        .addr   BgmIntroTriPattern2
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern3

BgmIntroSq1Init:
        .byte   VOL $a, NEXT

BgmIntroSq2Init:
        .byte   VOL 3, NEXT

BgmIntroSqPattern1:
        .byte   DUTY(2), LEN(4)
        .byte   DUR(8), C4, C5, G4, E4
        .byte   DUR(4), C5, DUR(12), G4
        .byte   DUR(16), LEN(12), E4
        .byte   NEXT

BgmIntroSqPattern2:
        .byte   LEN(4)
        .byte   DUR(8), Cs4, Cs5, Gs4, Es4
        .byte   DUR(4), Cs5, DUR(12), Gs4
        .byte   DUR(16), LEN(12), F4
        .byte   NEXT

BgmIntroSqPattern3:
        .byte   LEN(4)
        .byte   DUR(8), Ds4, E4, F4, REST
        .byte   F4, Fs4, G4, REST
        .byte   G4, Gs4, A4, REST
        .byte   LEN(8), DUR(8), C5
        .byte   END

BgmIntroTriPattern1:
BgmIntroTriPattern2:
BgmIntroTriPattern3:
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
