.include "nes.inc"
.include "header.inc"


; Number of digits used in unpacked BCD numbers representing point values
NUM_SCORE_DIGITS = 6


MyOAM = $200


; Signature that appears at the start of save file
; If not present, save file is uninitialized
.define MAGIC_COOKIE "Cheaters never prosper."

; This ordering is used so that you can reverse direction using EOR #$03
.enum
        WEST
        NORTH
        SOUTH
        EAST
.endenum

; INC if carry set
.macro inc_cs foo
.local @skip
        bcc     @skip
        inc     foo
@skip:
.endmacro

; DEC if carry clear
.macro dec_cc foo
.local @skip
        bcs     @skip
        dec     foo
@skip:
.endmacro

; INC if zero set
.macro inc_z foo
.local @skip
        bne     @skip
        inc     foo
@skip:
.endmacro


; None of these macros touch the Y register
.macro DlBegin
        ldx     DisplayListIndex
.endmacro

.macro DlAddA
        sta     DisplayList,x
        inx
.endmacro

.macro DlAdd a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16
.ifblank a1
        .exitmacro
.endif
        lda     a1
        DlAddA
        DlAdd a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16
.endmacro

.macro DlEnd
        stx     DisplayListIndex
.endmacro


; Thanks to rainwarrior for this macro
.macro assert_branch_page label
    .assert >label = >*, error, "PAGE CROSSING DETECTED"
.endmacro


.segment "ZEROPAGE"

; Temp variables, named like registers
; AL and AH can be seen as the low and high bytes of a 16-bit register AX
AX:
AL:                 .res 1
AH:                 .res 1

FrameCounter:       .res 1
fPaused:            .res 1
DisplayListIndex:   .res 1
fDisplayListReady:  .res 1
Joy1State:          .res 1
Joy2State:          .res 1                  ; must immediately follow Joy1State
Joy1PrevState:      .res 1
Joy2PrevState:      .res 1                  ; must immediately follow Joy1PrevState
Joy1Down:           .res 1
Joy2Down:           .res 1                  ; must immediately follow Joy1Down
VScroll:            .res 1
RngSeedL:           .res 1
RngSeedH:           .res 1
JsrIndAddrL:        .res 1                  ; Since we're on the zero page,
JsrIndAddrH:        .res 1                  ; we won't get bit by the $xxFF JMP bug

NumLevel:           .res 1
NumLives:           .res 1
NumDots:            .res 1
Score:              .res NUM_SCORE_DIGITS   ; BCD
fDiedThisRound:     .res 1
fBonusLifeAwarded:  .res 1
fStartOfGame:       .res 1


.include "nmi.asm"
.include "sprites.asm"
.include "sound.asm"
.include "sounddata.asm"
.include "speed.asm"
.include "pacman.asm"
.include "ghosts.asm"
.include "map.asm"
.include "fruit.asm"
.include "lzss.asm"
.include "intermissions.asm"


.segment "BSS"

; Use same memory for LZSS sliding window and display list
LzssBuf:
DisplayList:        .res 256


.segment "SAVE"

SaveMagicCookie:    .res .strlen(MAGIC_COOKIE)
HiScore:            .res NUM_SCORE_DIGITS   ; BCD


.segment "CODE"

Main:
        sei
        cld
        ldx     #$40
        stx     $4017
        ldx     #$ff
        txs
        inx                                 ; X will now be 0
        stx     PPUCTRL                     ; no NMI
        stx     PPUMASK                     ; rendering off
        stx     DMCFREQ                     ; no DMC IRQs

        ; First wait for vblank
        bit     PPUSTATUS
@vblank1:
        bit     PPUSTATUS
        bpl     @vblank1

        ; Init main RAM
        ; Value >= $ef should be used to clear OAM
        lda     #$ff
        ldx     #0
@init_ram:
        sta     $000,x
        sta     $100,x
        sta     $200,x
        sta     $300,x
        sta     $400,x
        sta     $500,x
        sta     $600,x
        sta     $700,x
        inx
        bne     @init_ram

        ; Clear VRAM ($2000-2fff)
        lda     #$20
        sta     PPUADDR
        lda     #0
        sta     PPUADDR
        lda     #' '
        ldx     #0
        ldy     #$10
@clear_vram:
        sta     PPUDATA
        inx
        bne     @clear_vram
        dey
        bne     @clear_vram

        ; Init variables
        lda     #0
        sta     FrameCounter
        sta     VScroll
        sta     DisplayListIndex
        sta     fDisplayListReady
        sta     fPaused
        sta     Joy1State
        sta     Joy2State

        ; @TODO@ -- better way to init this?
        lda     #%11001001
        sta     RngSeedL
        sta     RngSeedH

        lda     #>MyOAM
        sta     OamPtrH

        ; Set up sprite zero and dummy sprites for status area clipping
        ; This will appear in the 0 at the end of player 1's score
        ldx     #31
@init_dummy_sprites:
        lda     #56
        sta     MyOAM,x                     ; X position
        dex
        lda     #0                          ; palette, priority, flip
        sta     MyOAM,x
        dex
        lda     #$ff                        ; Tile ID
        sta     MyOAM,x
        dex
        lda     #15                         ; Y position
        sta     MyOAM,x
        dex
        bpl     @init_dummy_sprites

        ; Check if save data is initialized, and initialize it if not
        ldx     #0
@check_cookie:
        lda     MagicCookie,x
        cmp     SaveMagicCookie,x
        bne     @bad_cookie
        inx
        cpx     #.strlen(MAGIC_COOKIE)
        bne     @check_cookie
        beq     @cookie_ok
@bad_cookie:
        ; Initialize magic cookie
        ldx     #0
@save_cookie:
        lda     MagicCookie,x
        sta     SaveMagicCookie,x
        inx
        cpx     #.strlen(MAGIC_COOKIE)
        bne     @save_cookie
        ; Clear high score
        lda     #0
        ldx     #NUM_SCORE_DIGITS-1
@clear_high_score:
        sta     HiScore,x
        dex
        bpl     @clear_high_score
@cookie_ok:

        ; Init sound
        jsr     InitSound

        ; Second wait for vblank
@vblank2:
        bit     PPUSTATUS
        bpl     @vblank2
        ; FALL THROUGH to NewGame

NewGame:
        lda     #3
        sta     NumLives
        lda     #0
        sta     NumLevel
        sta     fBonusLifeAwarded
        ldx     #NUM_SCORE_DIGITS-1
@clear_score:
        sta     Score,x
        dex
        bpl     @clear_score

        lda     #1
        sta     fStartOfGame
        ; FALL THROUGH to PlayRound

PlayRound:
        jsr     ClearMyOAM
        jsr     RenderOff
        jsr     LoadPalette
        jsr     LoadBoard
        jsr     LoadStatusBar
        jsr     RenderOn

        lda     #244
        sta     NumDots
        lda     #0
        sta     fDiedThisRound

@start_life:
        jsr     InitLife
        jsr     DrawReady
        jsr     Render
        lda     fStartOfGame
        beq     @not_start_of_game
        lda     #0
        sta     fStartOfGame
        lda     #BGM_INTRO
        sta     BGM
        ldy     #200
        jsr     WaitFrames
@not_start_of_game:
        ldy     #60
        jsr     WaitFrames
        jsr     ClearReady
@game_loop:
        jsr     WaitForVblank
        jsr     ReadJoys
        lda     #JOY_START
        bit     Joy1Down
        beq     :+
        jsr     Pause
:
        jsr     MoveGhosts
        jsr     MovePacMan
        jsr     HandleFruit
        jsr     Render
        jsr     DecideBGM
        lda     fPacDead
        bne     @pac_dead
        lda     NumDots
        bne     @game_loop
        ; Round has been won
        jsr     WonRound
        jmp     PlayRound

@pac_dead:
        lda     #BGM_NONE
        sta     BGM
        ldy     #60
        jsr     WaitFrames
        jsr     ClearMyOAM
        jsr     DoPacManDeathAnimation
        jsr     ClearFruitGraphic
        dec     NumLives
        beq     @game_over
        lda     #1
        sta     fDiedThisRound
        bne     @start_life                 ; always taken
@game_over:
        jsr     DrawStatus                  ; to show 0 lives
        DlBegin
        DlAdd   #10, #$22, #$2b
        DlAdd   #'G', #'A', #'M', #'E', #' ', #' ', #'O', #'V', #'E', #'R'
        ; Change fruit palette so GAME OVER will be in red
        DlAdd   #1, #$3f, #$0e
        DlAdd   #$16
        DlEnd
        ldy     #180
        jsr     WaitFrames
        jmp     NewGame


InitLife:
        jsr     InitAI
        jsr     InitPacMan
        jsr     InitFruit
        rts


DrawReady:
        DlBegin
        DlAdd   #6, #$22, #$2d
        DlAdd   #'R', #'E', #'A', #'D', #'Y', #'!'
        DlEnd
        rts


ClearReady:
        DlBegin
        DlAdd   #6, #$22, #$2d
        lda     #' '
        ldy     #6
@loop:
        DlAddA
        dey
        bne     @loop
        DlEnd
        rts


DecideBGM:
        ; If any ghosts have been eaten, use that
        ldx     #3
@check_eaten_ghosts:
        lda     GhostsState,x
        cmp     #GhostState::eaten
        beq     @ghost_eaten
        dex
        bpl     @check_eaten_ghosts

        ; Alarm 2 triggers when 128 dots remain, alarm 3 when 64 remain, etc.
        ldx     #BGM_ALARM1
        lda     #128
@loop:
        cmp     NumDots
        blt     @check_energizer
        lsr
        inx
        cpx     #BGM_ALARM5
        blt     @loop

@check_energizer:
        lda     fEnergizerActive
        beq     :+
        ldx     #BGM_ENERGIZER
:
        stx     BGM
        rts

@ghost_eaten:
        lda     #BGM_EATEN_GHOST
        sta     BGM
        rts


WonRound:
        lda     #BGM_NONE
        sta     BGM
        ldy     #60
        jsr     WaitFrames

        ; Hide ghosts
        jsr     ClearMyOAM
        jsr     DrawPacMan

        ; Make the maze flash
        lda     #4
@loop:
        pha
        lda     #$30                        ; white
        jsr     SetMazeColor
        ldy     #12
        jsr     WaitFrames
        lda     #$12                        ; blue
        jsr     SetMazeColor
        ldy     #12
        jsr     WaitFrames
        pla
        sub     #1
        bne     @loop

        lda     NumLevel
        cmp     #99 - 1
        beq     :+                          ; don't inc past level 99
        inc     NumLevel
:

        ; Check for intermissions
        ; A still has the old level number
        cmp     #1                          ; intermission 1 after level 2
        blt     @no_intermission
        beq     @intermission1
        cmp     #4                          ; intermission 2 after level 5
        blt     @no_intermission
        beq     @intermission2
        ; Intermission 3 appears at level 9 and every four levels thereafter
        sub     #8
        blt     @no_intermission
        and     #$03
        bne     @no_intermission
        jsr     Intermission3
@no_intermission:
        rts

@intermission1:
        jmp     Intermission1

@intermission2:
        jmp     Intermission2


SetMazeColor:
        sta     AL
        DlBegin
        DlAdd   #1, #$3f, #$01, AL
        DlAdd   #1, #$3f, #$05, AL
        DlAdd   #1, #$3f, #$0d, AL
        DlEnd
        rts


; Input:
;   AX = address of number of points to add
;   Y = number of digit (0 = most significant)
;   carry flag
;
; Output:
;   AX = unchanged
;   Y = unchanged
;   carry flag
.macro AddDigit
.local @end
        lda     Score,y
        adc     (AX),y
        cmp     #10
        blt     @end                        ; carry flag will be clear
        sub     #10
        ; carry flag will be set
@end:
        sta     Score,y
.endmacro

AddPoints:
        ldy     #NUM_SCORE_DIGITS-1
        clc
@add_digit:
        AddDigit
        dey
        bpl     @add_digit

        ; Update high score if necessary
        ; We count up instead of down 'cause we must start with the
        ; most significant digit
        ldy     #0
@compare_high_score:
        lda     Score,y
        cmp     HiScore,y
        bne     @scores_differ
        iny
        cpy     #NUM_SCORE_DIGITS
        blt     @compare_high_score
        ; Scores are the same!
        bge     @hiscore_done

@scores_differ:
        blt     @hiscore_done               ; branch if Score < HiScore
        ; Update high score
        ldy     #NUM_SCORE_DIGITS-1
@update_high_score:
        lda     Score,y
        sta     HiScore,y
        dey
        bpl     @update_high_score
@hiscore_done:

        ; Award life at 10,000 points
        lda     fBonusLifeAwarded
        bne     @no_bonus_life
        lda     Score+1                     ; is the ten thousands digit of the score nonzero?
        beq     @no_bonus_life
        ; Score reached 10,000 points for the first time
        inc     NumLives
        lda     #1
        sta     fBonusLifeAwarded
        sta     fSfxTExtraLife
@no_bonus_life:

        rts


Pause:
        lda     #1
        sta     fPaused
        jsr     SoundOff
@loop:
        jsr     WaitForVblank
        jsr     ReadJoys
        lda     #JOY_START
        bit     Joy1Down
        beq     @loop
        lda     #0
        sta     fPaused
        jmp     SoundOn


Render:
        ; Set scroll
        lda     PacTileY
        asl
        asl
        asl
        ora     PacPixelY
        sub     #99
        bcc     @too_high
        cmp     #56 + 1
        blt     @scroll_ok                  ; OK if scroll is 0-56
        lda     #56                         ; scroll is >56; snap to 56
        bne     @scroll_ok                  ; always taken
@too_high:
        lda     #0
@scroll_ok:
        sta     VScroll
        ; Now that we've set the scroll, we can put stuff in MyOAM
        jsr     DrawGhosts
        jsr     DrawPacMan
        jmp     DrawStatus


DrawStatus:
        DlBegin

        ; Draw score
        DlAdd   #NUM_SCORE_DIGITS, #$2b, #$a2
        ldy     #0
@draw_score:
        DlAdd   {Score,y}
        iny
        cpy     #NUM_SCORE_DIGITS
        blt     @draw_score

        ; Draw high score
        DlAdd   #NUM_SCORE_DIGITS, #$2b, #$ac
        ldy     #0
@draw_high_score:
        DlAdd   {HiScore,y}
        iny
        cpy     #NUM_SCORE_DIGITS
        blt     @draw_high_score

        ; Draw level number
        DlAdd   #2, #$2b, #$99
        lda     NumLevel
        add     #1                          ; level number is 0-based, but displayed as 1-based
        jsr     DrawTwoDigitNumber

        ; Draw number of lives
        DlAdd   #2, #$2b, #$b9
        lda     NumLives
        jsr     DrawTwoDigitNumber

        DlEnd
        rts


; Adds a two-digit number to the display list.
; If the number is less than 10, the second digit is a space.
;
; Input:
;   A = the number (0-99)
;
; Call this between DlBegin and DlEnd
DrawTwoDigitNumber:
        cmp     #10
        blt     @less_than_ten
        ldy     #0
@divmod:
        sub     #10
        iny
        cmp     #10
        bge     @divmod

        ; Y holds tens digit, A holds ones digit
        pha
        tya
        DlAddA
        pla
        DlAddA
        rts

@less_than_ten:
        DlAddA
        DlAdd   #' '
        rts



LoadPalette:
        ; Load palette
        lda     #$3f
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        ldx     #0
@copy_palette:
        lda     Palette,x
        sta     PPUDATA
        inx
        cpx     #PaletteSize
        bne     @copy_palette
        rts


LoadStatusBar:
        lda     #$2b
        sta     PPUADDR
        lda     #$40
        sta     PPUADDR
        ldx     #0
@loop:
        lda     StatusBar,x
        beq     @end
        sta     PPUDATA
        inx
        jmp     @loop
@end:
        rts


RenderOff:
        lda     #0
        sta     PPUCTRL
        sta     PPUMASK
        rts

RenderOn:
        lda     #$80
        sta     PPUCTRL
        rts


; Won't touch Y
WaitForVblank:
        lda     #0                          ; mark end of display list
        ldx     DisplayListIndex
        sta     DisplayList,x
        lda     #1
        sta     fDisplayListReady
        lda     FrameCounter
@loop:
        cmp     FrameCounter
        beq     @loop
        rts

; Input:
;   Y = number of frames to wait (0 = 256)
WaitFrames:
        jsr     WaitForVblank
        dey
        bne     WaitFrames
        rts


HandleIrq:
        ; Loop infinitely since we should never get here
        jmp     HandleIrq


; Won't clear first eight sprites
; (sprite zero plus dummy sprites for status area clpping)
ClearMyOAM:
        lda     #$ff
        ldx     #32
@loop:
        sta     MyOAM,x
        inx
        bne     @loop
        rts


ClearNametable1:
        ; Fill $2000-23ff with spaces
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        lda     #' '
        ldx     #0
        ldy     #4
@fill_spaces:
        sta     PPUDATA
        inx
        bne     @fill_spaces
        dey
        bne     @fill_spaces

        ; Fill $23c0-23ff (attribute table) with zero
        lda     #$23
        sta     PPUADDR
        lda     #$c0
        sta     PPUADDR
        lda     #0
        ldx     #32
@fill_zero:
        sta     PPUDATA
        dex
        bne     @fill_zero

        rts


ReadJoys:
        ldy     #0                          ; controller 1
        jsr     ReadOneJoy
        iny                                 ; controller 2
        ; FALL THROUGH to ReadOneJoy

; Inputs:
;   Y = number of controller to read (0 = controller 1)
;
; Expects Joy2State to follow Joy1State in memory
; Expects Joy2PrevState to follow Joy1PrevState in memory
; Expects Joy2Down to follow Joy1Down in memory
ReadOneJoy:
        lda     Joy1State,y
        sta     Joy1PrevState,y
        jsr     ReadJoyImpl
@no_match:
        sta     Joy1State,y
        jsr     ReadJoyImpl
        cmp     Joy1State,y
        bne     @no_match
        eor     Joy1PrevState,y             ; get buttons that have changed
        and     Joy1State,y                 ; filter out buttons not currently pressed
        sta     Joy1Down,y
        rts

ReadJoyImpl:
        ldx     #1
        stx     JOYSTROBE
        dex
        stx     JOYSTROBE
        txa
        ldx     #8
@loop:
        pha
        lda     JOY1,y
        and     #$03
        cmp     #$01                        ; carry will be set if A is nonzero
        pla                                 ; (i.e., if the button is pressed)
        ror
        dex
        bne     @loop
        rts


; http://wiki.nesdev.com/w/index.php/Random_number_generator
; Won't touch Y
Rand:
        ldx     #8                          ; iteration count: controls entropy quality (max 8,7,4,2,1 min)
        lda     RngSeedL
@loop:
        asl                                 ; shift the register
        rol     RngSeedH
        bcc     :+
        eor     #$2D                        ; apply XOR feedback whenever a 1 bit is shifted out
:
        dex
        bne     @loop
        sta     RngSeedL
        rts


DeltaXTbl:
        .byte   -1                          ; west
        .byte   0                           ; north
        .byte   0                           ; south
        .byte   1                           ; east

DeltaYTbl:
        .byte   0                           ; west
        .byte   -1                          ; north
        .byte   1                           ; south
        .byte   0                           ; east


StatusBar:
        .byte   "                                "
        .byte   "                                "
        .byte   "    1UP   HIGH SCORE   L=       "
        .byte   "                       ", $98, $a0, "       "
        .byte   0


; Unpacked BCD representations of points
Points10:   .byte   0,0,0,0,1,0
Points50:   .byte   0,0,0,0,5,0
Points100:  .byte   0,0,0,1,0,0
Points200:  .byte   0,0,0,2,0,0
Points300:  .byte   0,0,0,3,0,0
Points400:  .byte   0,0,0,4,0,0
Points500:  .byte   0,0,0,5,0,0
Points700:  .byte   0,0,0,7,0,0
Points800:  .byte   0,0,0,8,0,0
Points1000: .byte   0,0,1,0,0,0
Points1600: .byte   0,0,1,6,0,0
Points2000: .byte   0,0,2,0,0,0
Points3000: .byte   0,0,3,0,0,0
Points5000: .byte   0,0,5,0,0,0


Palette:
.incbin "../assets/palette.dat"
PaletteSize = * - Palette

; Palette cycle for flashing energizers
ColorCycle:
        .byte   $0f, $36, $30, $36

MagicCookie:
        .byte   MAGIC_COOKIE


; Indirect JSR
; To use: load address into JsrIndAddrL and JsrIndAddrH
; Then just JSR JsrInd
JsrInd:
        jmp     (JsrIndAddrL)


.segment "VECTORS"

        .addr   HandleVblank                ; NMI
        .addr   Main                        ; RESET
        .addr   HandleIrq                   ; IRQ/BRK


.segment "CHR"
.incbin "../assets/gfx.chr"
