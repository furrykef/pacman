.include "nes.inc"
.include "header.inc"


; Number of digits used in unpacked BCD numbers representing point values
NUM_SCORE_DIGITS = 6


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


MyOAM = $200


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

TmpL:               .res 1
TmpH:               .res 1
Tmp2L:              .res 1
Tmp2H:              .res 1
FrameCounter:       .res 1
fRenderOn:          .res 1                  ; tells vblank handler not to mess with PPU memory if zero
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


.include "sprites.asm"
.include "sound.asm"
.include "speed.asm"
.include "pacman.asm"
.include "ghosts.asm"
.include "map.asm"
.include "fruit.asm"
.include "lzss.asm"


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
        lda     #' '
        sta     PPUADDR
        ldx     #0
        ldy     #$10
@clear_vram:
        sta     PPUDATA
        inx
        bne     @clear_vram
        dey
        bpl     @clear_vram

        ; Init variables
        lda     #0
        sta     FrameCounter
        sta     VScroll
        sta     DisplayListIndex
        sta     fDisplayListReady
        sta     fRenderOn
        sta     fPaused
        sta     Joy1State
        sta     Joy2State

        ; @TODO@ -- better way to init this?
        lda     #%11001001
        sta     RngSeedL
        sta     RngSeedH

        lda     #>MyOAM
        sta     OamPtrH

        ; Set up sprite zero
        ; This will appear in the 0 at the end of player 1's score
        lda     #23                         ; Y position
        sta     MyOAM
        lda     #$ff                        ; Tile ID
        sta     MyOAM+1
        lda     #0                          ; palette, priority, flip
        sta     MyOAM+2
        lda     #56
        sta     MyOAM+3

        ; Set up dummy sprites for status area sprite overflow
        ; (This will hide ghosts that appear in the status area)
        ldx     #4
@dummy_sprite_loop:
        lda     #23
        sta     MyOAM,x                     ; Y position
        inx
        lda     #$fe
        sta     MyOAM,x                     ; pattern
        inx
        inx                                 ; skip attributes (value irrelevant)
        inx                                 ; skip Y coordinate (ditto)
        cpx     #40
        bne     @dummy_sprite_loop

        ; Check if save data is initialized, and initialize it if not
        ldx     #0
@check_cookie:
        lda     MagicCookie,x
        cmp     SaveMagicCookie,x
        bne     @bad_cookie
        inx
        cpx     #.strlen(MAGIC_COOKIE)
        bne     @check_cookie
        jmp     @cookie_ok
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
@clear_high_score:
.repeat NUM_SCORE_DIGITS, I
        sta     HiScore+I
.endrepeat
@cookie_ok:

        ; Init sound
        jsr     InitSound

        ; Second wait for vblank
@vblank2:
        bit     PPUSTATUS
        bpl     @vblank2

        ; Enable NMIs
@wait_vblank_end:
        bit     PPUSTATUS
        bmi     @wait_vblank_end
        lda     #$80                        ; NMI on
        sta     PPUCTRL
        ; FALL THROUGH to NewGame

NewGame:
        lda     #3
        sta     NumLives
        lda     #0
        sta     NumLevel
        sta     fBonusLifeAwarded
.repeat NUM_SCORE_DIGITS, I
        sta     Score+I
.endrepeat
        lda     #1
        sta     fStartOfGame
        ; FALL THROUGH to PlayRound

PlayRound:
        lda     #0
        sta     fRenderOn
        sta     PPUMASK
        jsr     LoadPalette
        jsr     LoadBoard
        jsr     LoadStatusBar
        lda     #1
        sta     fRenderOn

        lda     #244
        sta     NumDots
        lda     #0
        sta     fDiedThisRound

@start_life:
        jsr     InitLife
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
        jmp     @start_life
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
        ; @XXX@ better way to do this
        lda     #GhostState::being_eaten
        sta     GhostsState+BLINKY
        sta     GhostsState+PINKY
        sta     GhostsState+INKY
        sta     GhostsState+CLYDE
        jsr     DrawGhosts

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
        beq     :+
        inc     NumLevel
:
        rts


SetMazeColor:
        sta     TmpL
        DlBegin
        DlAdd   #1, #$3f, #$01, TmpL
        DlAdd   #1, #$3f, #$05, TmpL
        DlAdd   #1, #$3f, #$0d, TmpL
        DlEnd
        rts


; Input:
;   TmpL,H = address of number of points to add
;   Y = number of digit (0 = most significant)
;   carry flag
;
; Output:
;   Y = Y-1
;   carry flag
.macro AddDigit num
.local @end
        lda     Score+(NUM_SCORE_DIGITS-num-1)
        adc     (TmpL),y
        dey
        cmp     #10
        blt     @end                        ; carry flag will be clear
        sub     #10
        ; carry flag will be set
@end:
        sta     Score+(NUM_SCORE_DIGITS-num-1)
.endmacro

AddPoints:
        ldy     #NUM_SCORE_DIGITS-1
        clc
.repeat NUM_SCORE_DIGITS, I
        AddDigit I
.endrepeat
        ; Update high score if necessary
.repeat NUM_SCORE_DIGITS, I
        lda     Score+I
        cmp     HiScore+I
        bne     @scores_differ
.endrepeat
        ; Scores are the same!
        jmp     @hiscore_done
@scores_differ:
        blt     @hiscore_done               ; branch if Score < HiScore
        ; Update high score
.repeat NUM_SCORE_DIGITS, I
        lda     Score+I
        sta     HiScore+I
.endrepeat
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
        jmp     @scroll_ok
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
.repeat NUM_SCORE_DIGITS, I
        DlAdd   Score+I
.endrepeat

        ; Draw high score
        DlAdd   #NUM_SCORE_DIGITS, #$2b, #$ac
.repeat NUM_SCORE_DIGITS, I
        DlAdd   HiScore+I
.endrepeat

        ; Draw level number
        DlAdd   #2, #$2b, #$99
        ldy     NumLevel
        iny                                 ; level number is 0-based, but displayed as 1-based
        jsr     DrawSmallNumber

        ; Draw number of lives
        DlAdd   #2, #$2b, #$b9
        ldy     NumLives
        jsr     DrawSmallNumber

        DlEnd
        rts


; Adds a two-digit number to the display list.
; If the number is less than 10, the second digit is a space.
;
; Input:
;   Y = the number (0-99)
;
; Call this between DlBegin and DlEnd
DrawSmallNumber:
        lda     FirstDigitTbl,y
        DlAddA
        lda     SecondDigitTbl,y
        DlAddA
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


HandleVblank:
        bit     PPUSTATUS                   ; make sure vblank flag gets cleared
        pha
        txa
        pha
        tya
        pha
        lda     fRenderOn
        bne     :+
        jmp     @end
:

        ; OAM DMA
        lda     #$00
        sta     OAMADDR
        lda     #>MyOAM
        sta     OAMDMA

        ; Render display list if ready
        lda     fDisplayListReady
        beq     @skip_display_list
        ldx     #0
@display_list_loop:
        ldy     DisplayList,x               ; size of chunk to copy
        beq     @display_list_end           ; size of zero means end of display list
        inx
        lda     DisplayList,x               ; PPU address LSB
        sta     PPUADDR
        inx
        lda     DisplayList,x               ; PPU address MSB
        sta     PPUADDR
        inx
@copy_block:
        lda     DisplayList,x
        sta     PPUDATA
        inx
        dey
        bne     @copy_block
        jmp     @display_list_loop
@display_list_end:
        lda     #0
        sta     DisplayListIndex
        sta     fDisplayListReady
@skip_display_list:

        ; Cycle color 3 of BG palette 0
        lda     #$3f
        sta     PPUADDR
        lda     #$03
        sta     PPUADDR
        lda     FrameCounter
        and     #%00011000
        lsr
        lsr
        lsr
        tax
        lda     ColorCycle,x
        sta     PPUDATA

        ; Set scroll
        lda     #$8a                        ; NMI on, 8x8 sprites, 2nd spr pattern table, 2nd nametable (where status bar is)
        sta     PPUCTRL
        lda     #0
        sta     PPUSCROLL
        lda     #208
        sta     PPUSCROLL

        lda     #$18                        ; BG on, sprites off
        ldx     fPaused
        beq     @not_paused
        ora     #$e0                        ; color emphasis bits on
@not_paused:
        sta     PPUMASK

        jsr     SoundTick

        ; Split the screen with a sprite zero hit
@wait_for_rendering_to_begin:
        bit     PPUSTATUS
        bvs     @wait_for_rendering_to_begin

@wait_for_sprite_zero:
        bit     PPUSTATUS
        bvc     @wait_for_sprite_zero

        ; Burn some cycles until we're nearly at hblank
        ldx     #30                         ; 2 cycles
@delay:
        dex                                 ; 2 cycles
        bne     @delay                      ; 3 cycles (2 on last iteration)
        assert_branch_page @delay

        ; See: http://wiki.nesdev.com/w/index.php/PPU_scrolling#Split_X.2FY_scroll
        ; NES hardware is weird, man
        ; These writes can occur outside hblank
        stx     PPUADDR                     ; X is already 0
        lda     VScroll
        sta     PPUSCROLL
        stx     PPUSCROLL
        lda     VScroll
        and     #$f8
        asl
        asl
        ; This write must occur inside hblank
        sta     PPUADDR

@end:
        inc     FrameCounter
        pla
        tay
        pla
        tax
        pla
        rti

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
        brk


; Won't clear first nine sprites
; (sprite zero plus dummy sprites for status area sprite overflow)
ClearMyOAM:
        lda     #$ff
        ldx     #4
@loop:
        sta     MyOAM,x
        inx
        bne     @loop
        rts


ReadJoys:
        ldy     #0                          ; controller 1
        jsr     ReadOneJoy
        iny                                 ; controller 2
        jmp     ReadOneJoy

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


; Tables for displaying two-digit numbers
FirstDigitTbl:
.repeat 10, I
        .byte I
.endrepeat
.repeat 9, I
    .repeat 10
        .byte I+1
    .endrepeat
.endrepeat

SecondDigitTbl:
.repeat 10
        .byte ' '
.endrepeat
.repeat 90, I
        .byte I .mod 10
.endrepeat


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
