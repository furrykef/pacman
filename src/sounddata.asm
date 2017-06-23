; order of alarms is significant
.enum
        BGM_NONE
        BGM_INTRO
        BGM_ALARM1
        BGM_ALARM2
        BGM_ALARM3
        BGM_ALARM4
        BGM_ALARM5
        BGM_ENERGIZER
        BGM_EATEN_GHOST
        BGM_INTERMISSION
        BGM_DYING
        BGM_DYING2
.endenum


.segment "CODE"

SongTbl:
        .addr   BgmNone
        .addr   BgmIntro
        .addr   BgmAlarm1
        .addr   BgmAlarm2
        .addr   BgmAlarm3
        .addr   BgmAlarm4
        .addr   BgmAlarm5
        .addr   BgmEnergizer
        .addr   BgmEatenGhost
        .addr   BgmIntermission
        .addr   BgmDying
        .addr   BgmDying2


BgmNone:
        .addr   NullPatternList
        .addr   NullPatternList
        .addr   NullPatternList

NullPatternList:
        .addr   NullPattern

NullPattern:
        .byte   END


Transpose0:
        .byte   TRANSPOSE, 0, NEXT

Transpose1:
        .byte   TRANSPOSE, 1, NEXT


BgmIntro:
        .addr   BgmIntroSq1
        .addr   BgmIntroSq2
        .addr   BgmIntroTri

BgmIntroSq1:
        .addr   BgmIntroSq1Init
        .addr   BgmIntroSqPattern1
        .addr   Transpose1
        .addr   BgmIntroSqPattern1
        .addr   Transpose0
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern2

BgmIntroSq2:
        .addr   BgmIntroSq2Init
        .addr   BgmIntroSqPattern1
        .addr   Transpose1
        .addr   BgmIntroSqPattern1
        .addr   Transpose0
        .addr   BgmIntroSqPattern1
        .addr   BgmIntroSqPattern2

BgmIntroTri:
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern1
        .addr   Transpose1
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern1
        .addr   Transpose0
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern1
        .addr   BgmIntroTriPattern2

BgmIntroSq1Init:
        .byte   DUTYVOL, $ba, NEXT

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
        .byte   LEN(12), DUR(16)
        .byte   G2, A2, B2, C3
        .byte   END


BgmAlarm1:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm1PatternList

BgmAlarm1PatternList:
        .addr   BgmAlarm1Pattern

; F#4 to A5, 24 frames
; Thanks to OpenMPT's interpolator for helping me with these
BgmAlarm1Pattern:
        .byte   DUR(1), LEN(2)
        .byte   Fs4, Gs4, A4, As4, B4, Cs5, D5, Ds5, E5, Fs5, G5, Gs5
        .byte   A5, G5, Fs5, F5, E5, D5, Cs5, C5, B4, A4, Gs4, G4
        .byte   REPEAT


BgmAlarm2:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm2PatternList

BgmAlarm2PatternList:
        .addr   BgmAlarm2Pattern

; A#4 to C6, 22 frames
BgmAlarm2Pattern:
        .byte   DUR(1), LEN(2)
        .byte   As4, C5, Cs5, D5, E5, F5, Fs5, G5, A5, As5, B5
        .byte   C6, As5, A5, Gs5, Fs5, F5, E5, Ds5, Cs5, C5, B4
        .byte   REPEAT


BgmAlarm3:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm3PatternList

BgmAlarm3PatternList:
        .addr   BgmAlarm3Pattern

; C#5 to D#6, 20 frames (I measured 19, but 20 fits the pattern)
BgmAlarm3Pattern:
        .byte   DUR(1), LEN(2)
        .byte   Cs5, Ds5, E5, Fs5, G5, Gs5, As5, B5, Cs6, D6
        .byte   Ds6, Cs6, C6, As5, A5, Gs5, Fs5, F5, Ds5, D5
        .byte   REPEAT


BgmAlarm4:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm4PatternList

BgmAlarm4PatternList:
        .addr   BgmAlarm4Pattern

; Alarm4: F5 to F#6, 18 frames
BgmAlarm4Pattern:
        .byte   DUR(1), LEN(2)
        .byte   F5, G5, Gs5, As5, B5, Cs6, D6, E6, F6
        .byte   Fs6, E6, Ds6, Cs6, C6, As5, A5, G5, Fs5
        .byte   REPEAT


BgmAlarm5:
        .addr   0
        .addr   NullPatternList
        .addr   BgmAlarm5PatternList

BgmAlarm5PatternList:
        .addr   BgmAlarm5Pattern

; Alarm5: G#5 to G6, 16 frames
BgmAlarm5Pattern:
        .byte   DUR(1), LEN(2)
        .byte   Gs5, As5, B5, Cs6, D6, Ds6, F6, Fs6
        .byte   G6, F6, E6, D6, Cs6, C6, As5, A5
        .byte   REPEAT


BgmEnergizer:
        .addr   0
        .addr   BgmEnergizerPatternList
        .addr   NullPatternList

BgmEnergizerPatternList:
        .addr   BgmEnergizerPattern

BgmEnergizerPattern:
        .byte   DUTYVOL, $b8, DUR(1), LEN(2)
        .byte   Cs4, Gs4, Cs5, F5, Gs5, As5, B5, C6
        .byte   REPEAT


BgmEatenGhost:
        .addr   0
        .addr   NullPatternList
        .addr   BgmEatenGhostPatternList

BgmEatenGhostPatternList:
        .addr   BgmEatenGhostPattern

BgmEatenGhostPattern:
        .byte   DUR(1), LEN(2)
        .byte   Ds7, Cs7, B6, A6
        .byte   Fs6, E6, D6, C6
        .byte   A5, G5, F5, Ds5
        .byte   C5, As4, Gs4, Fs4
        .byte   REPEAT


BgmIntermission:
        .addr   BgmIntermissionSq1
        .addr   BgmIntermissionSq2
        .addr   BgmIntermissionTri

BgmIntermissionSq2:
        .addr   BgmIntermissionSq2Init
BgmIntermissionSq1:
        .addr   BgmIntermissionSqInit
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern2
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern3
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern4
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern2
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern3
        .addr   BgmIntermissionSqPattern1
        .addr   BgmIntermissionSqPattern4
        .addr   NullPattern

BgmIntermissionTri:
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern2
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern1
        .addr   BgmIntermissionTriPattern2
        .addr   NullPattern

BgmIntermissionSqInit:
        .byte   DUTYVOL, $78, NEXT

BgmIntermissionSq2Init:
        .byte   TRANSPOSE, 12, NEXT

BgmIntermissionSqPattern1:
        .byte   DUR(12), LEN(11)
        .byte   F3, F3, F3
        .byte   DUR(6), LEN(5)
        .byte   D3, C3, F3, F3, REST
        .byte   NEXT

BgmIntermissionSqPattern2:
        .byte   DUR(30), LEN(24)
        .byte   A3
        .byte   NEXT

BgmIntermissionSqPattern3:
        .byte   DUR(30), LEN(24)
        .byte   D3
        .byte   NEXT

BgmIntermissionSqPattern4:
        .byte   DUR(18), LEN(17)
        .byte   Gs3
        .byte   DUR(12), LEN(11)
        .byte   As3, B3, As3, Gs3, F3
        .byte   DUR(18), LEN(17)
        .byte   Gs3
        .byte   DUR(30), LEN(24)
        .byte   F3
        .byte   NEXT

BgmIntermissionTriPattern1:
.repeat 3
        .byte   DUR(18), LEN(12)
        .byte   F2
        .byte   DUR(6), LEN(5)
        .byte   F2
.endrepeat
        .byte   A2, As2, B2, C3
        .byte   NEXT

BgmIntermissionTriPattern2:
        .byte   DUR(12), LEN(11)
        .byte   F3
        .byte   DUR(6), LEN(5)
        .byte   C3, B2, As2, Gs2, F2, E2
        .byte   DUR(12), LEN(11)
        .byte   Ds2, E2, F2, REST
        .byte   NEXT


BgmDying:
        .addr   BgmDyingPatternList
        .addr   NullPatternList
        .addr   NullPatternList

BgmDyingPatternList:
        .addr   BgmDyingPatternInit
        .addr   BgmDyingPattern

BgmDyingPatternInit:
        .byte   DUR(1), LEN(31),  C5
        .byte   NEXT

BgmDyingPattern:
        .byte   LEN(31)
        .byte   SWEEP, $f1
        .byte   REPEAT


BgmDying2:
        .addr   NullPatternList
        .addr   NullPatternList
        .addr   BgmDying2PatternList

BgmDying2PatternList:
        .addr   BgmDying2Pattern
        .addr   BgmDying2Pattern
        .addr   NullPattern

BgmDying2Pattern:
        .byte   DUR(1), LEN(1)
        .byte   Fs3, Fs4, Cs5, Fs5, As5, Cs6, E6, Fs6, Gs6, As6, C7
        .byte   REST, NEXT


SfxEatingGhostPatternList:
        .addr   SfxEatingGhostPattern

SfxEatingGhostPattern:
        .byte   DUTYVOL, $bf, LEN(2)
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
        .byte   DUTYVOL, $3f, DUR(1), LEN(1)
        .byte   E2, As2, Ds3, Fs3, A3
        .byte   END

SfxMunchDot2Pattern:
        .byte   DUTYVOL, $3f, DUR(1), LEN(1)
        .byte   B3, Gs3, F3, Cs3, Gs2
        .byte   END
