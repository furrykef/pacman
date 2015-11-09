.include "nes.inc"
.include "header.inc"


NUM_SCORE_DIGITS = 6

.define MAGIC_COOKIE "You're a dirty cheater, aren't you?"

; This ordering is used so that you can reverse direction using EOR #$03
.enum
        WEST
        NORTH
        SOUTH
        EAST
.endenum


; Exports for easy debugging
.export HandleVblank
.export WaitForVblank
.export HandleIrq
.export ReadJoys
.export ComputeTurn
.export MovePacMan
.export MoveGhosts
.export DisplayList
.export Blinky
.export EnergizerClockL


MyOAM = $200


.segment "ZEROPAGE"

TmpL:               .res 1
TmpH:               .res 1
Tmp2L:              .res 1
Tmp2H:              .res 1
FrameCounter:       .res 1
fSpriteOverflow:    .res 1                  ; true values won't necessarily be $01
fRenderOn:          .res 1                  ; tells vblank handler not to mess with PPU memory if zero
fPaused:            .res 1
DisplayListIndex:   .res 1
Joy1State:          .res 1
Joy2State:          .res 1                  ; must immediately follow Joy1State
Joy1PrevState:      .res 1
Joy2PrevState:      .res 1                  ; must immediately follow Joy1PrevState
Joy1Down:           .res 1
Joy2Down:           .res 1                  ; must immediately follow Joy1Down
VScroll:            .res 1
IrqVScroll:         .res 1
RngSeedL:           .res 1
RngSeedH:           .res 1
JsrIndAddrL:        .res 1                  ; Since we're on the zero page,
JsrIndAddrH:        .res 1                  ; we won't get bit by the $xxFF JMP bug

NumDots:            .res 1
Score:              .res NUM_SCORE_DIGITS   ; BCD
FruitClockL:        .res 1
FruitClockH:        .res 1


.include "pacman.asm"
.include "ghosts.asm"
.include "map.asm"


.segment "BSS"

DisplayList:        .res 256                ; can shrink and move to zero page if we need a perfomance boost


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
        stx     $e000                       ; no MMC3 IRQs

        ; First wait for vblank
        bit     PPUSTATUS
@vblank1:
        bit     PPUSTATUS
        bpl     @vblank1

        ; Init sound regs and other stuff here
        ; @XXX@

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
        tax                                 ; X := 0
        ldy     #$10
@clear_vram:
        sta     PPUDATA
        dex
        bne     @clear_vram
        dey
        bne     @clear_vram

        ; Init mapper
        ; Set CHR banks
        ldx     #$c0
        stx     $8000
        inx
        ldy     #4
        sty     $8001
        iny
        iny
        stx     $8000
        sty     $8001
        ldx     #$c2
        stx     $8000
        inx
        ldy     #0
        sty     $8001
        iny
        stx     $8000
        inx
        sty     $8001
        iny
        stx     $8000
        inx
        sty     $8001
        iny
        stx     $8000
        sty     $8001

        ; Vertical mirroring
        lda     #$01
        sta     $a000

        ; Init variables
        lda     #0
        sta     FrameCounter
        sta     VScroll
        sta     DisplayListIndex
        sta     fRenderOn
        sta     fPaused
        sta     Joy1State
        sta     Joy2State

        ; @TODO@ -- better way to init this?
        lda     #%11001001
        sta     RngSeedL
        sta     RngSeedH

        ; Unlock PRG RAM
        lda     #$80
        sta     $a001

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

        ; Lock PRG RAM
        lda     #$00
        sta     $a001

        ; Second wait for vblank
@vblank2:
        bit     PPUSTATUS
        bpl     @vblank2

        ; Enable interrupts and NMIs
        cli
@wait_vblank_end:
        bit     PPUSTATUS
        bmi     @wait_vblank_end
        lda     #$80                        ; NMI on
        sta     PPUCTRL
        ; FALL THROUGH to NewGame

NewGame:
        lda     #0
.repeat NUM_SCORE_DIGITS, I
        sta     Score+I
.endrepeat
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
        lda     #$80
        sta     PPUCTRL

        lda     #244
        sta     NumDots

        jsr     InitLife
        jsr     Render
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
        jsr     Render
        lda     NumDots
        bne     @game_loop
        ; Round has been won
        ldy     #120
        jsr     WaitFrames
        jmp     PlayRound


InitLife:
        jsr     InitAI
        jsr     InitPacMan
        lda     #0
        sta     FruitClockL
        sta     FruitClockH
        rts


SpawnFruit:
        lda     #<10*60
        sta     FruitClockL
        lda     #>10*60
        sta     FruitClockH

        ldx     DisplayListIndex
        lda     #2
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$0f
        sta     DisplayList,x
        inx
        lda     #$d0
        sta     DisplayList,x
        inx
        lda     #$d1
        sta     DisplayList,x
        inx
        ; Clear space to the left and right of the fruit as well
        ; (in case bonus points have been drawn here)
        lda     #4
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$2e
        sta     DisplayList,x
        inx
        lda     #$20
        sta     DisplayList,x
        inx
        lda     #$e0
        sta     DisplayList,x
        inx
        lda     #$e1
        sta     DisplayList,x
        inx
        lda     #$20
        sta     DisplayList,x
        inx
        lda     #2
        sta     DisplayList,x
        inx
        lda     #$22
        sta     DisplayList,x
        inx
        lda     #$4f
        sta     DisplayList,x
        inx
        lda     #$f0
        sta     DisplayList,x
        inx
        lda     #$f1
        sta     DisplayList,x
        inx
        stx     DisplayListIndex

        rts


; Input:
;   TmpL,H = address of number of points to add
;
; Output:
;   carry flag
.macro AddDigit num
.local end
        lda     Score+(NUM_SCORE_DIGITS-num-1)
        adc     (TmpL),y
        dey
        cmp     #10
        blt     end                         ; carry flag will be clear
        sub     #10
        ; carry flag will be set
end:
        sta     Score+(NUM_SCORE_DIGITS-num-1)
.endmacro

AddPoints:
        ldy     #NUM_SCORE_DIGITS-1
        clc
.repeat NUM_SCORE_DIGITS, I
        AddDigit I
.endrepeat
        ; Update high score if necessary
        ; Unlock PRG RAM first
        lda     #$80
        sta     $a001
.repeat NUM_SCORE_DIGITS, I
        lda     Score+I
        cmp     HiScore+I
        bne     @scores_differ
.endrepeat
        ; Scores are the same!
        rts
@scores_differ:
        blt     @end                        ; branch if Score < HiScore
        ; Update high score
.repeat NUM_SCORE_DIGITS, I
        lda     Score+I
        sta     HiScore+I
.endrepeat
@end:
        ; Lock PRG RAM
        lda     #$00
        sta     $a001
        rts


Pause:
        lda     #1
        sta     fPaused
@loop:
        jsr     WaitForVblank
        jsr     ReadJoys
        lda     #JOY_START
        bit     Joy1Down
        beq     @loop
        lda     #0
        sta     fPaused
        rts


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
        ldx     DisplayListIndex
        ; Draw score
        lda     #NUM_SCORE_DIGITS
        sta     DisplayList,x
        inx
        lda     #$2b
        sta     DisplayList,x
        inx
        lda     #$a6
        sta     DisplayList,x
        inx
.repeat NUM_SCORE_DIGITS, I
        lda     Score+I
        sta     DisplayList,x
        inx
.endrepeat
        ; Draw high score
        ; Unlock PRG RAM, read-only
        lda     #$c0
        sta     $a001
        lda     #NUM_SCORE_DIGITS
        sta     DisplayList,x
        inx
        lda     #$2b
        sta     DisplayList,x
        inx
        lda     #$b0
        sta     DisplayList,x
        inx
.repeat NUM_SCORE_DIGITS, I
        lda     HiScore+I
        sta     DisplayList,x
        inx
.endrepeat
        ; Lock PRG RAM
        lda     #$00
        sta     $a001
        stx     DisplayListIndex
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

        ; Check if sprites overflowed on previous frame
        lda     PPUSTATUS
        and     #$20
        sta     fSpriteOverflow

        ; Render display list
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
        lda     #$a2                        ; NMI on, 8x16 sprites, second nametable (where status bar is)
        sta     PPUCTRL
        lda     #0
        sta     PPUSCROLL
        lda     #208
        sta     PPUSCROLL

        lda     #$08                        ; BG on, sprites off
        ldx     fPaused
        beq     @not_paused
        ora     #$e0                        ; color emphasis bits on
@not_paused:
        sta     PPUMASK

        ; Save VScroll for IRQ handler
        ; (IRQ using VScroll directly causes a race condition and IRQ may use
        ;  the value for the next frame)
        lda     VScroll
        sta     IrqVScroll

        ; Enable IRQ for split screen
        ; This has to be done after we're done messing with PPU memory
        lda     #31                         ; number of scanlines before IRQ
        sta     $c000
        sta     $c001                       ; reload IRQ counter (value irrelevant)
        sta     $e001                       ; enable IRQ (value irrelevant)

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
        pha
        txa
        pha
        sta     $e000                       ; acknowledge and disable IRQ (value irrelevant)

        lda     fRenderOn
        beq     @end

        ; Wait until we're nearly at hblank
.repeat 30
        nop
.endrepeat

        ; See: http://wiki.nesdev.com/w/index.php/PPU_scrolling#Split_X.2FY_scroll
        ; NES hardware is weird, man
        lda     #0
        sta     PPUADDR
        lda     IrqVScroll
        sta     PPUSCROLL
        lda     #0
        sta     PPUSCROLL
        lda     IrqVScroll
        and     #$f8
        asl
        asl
        sta     PPUADDR
        lda     #$18                        ; BG and sprites on
        ldx     fPaused
        beq     @not_paused
        ora     #$e0                        ; color emphasis bits on
@not_paused:
        sta     PPUMASK

@end:
        pla
        tax
        pla
        rti


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
; Expects controllers to already have been strobed
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
        .byte   "        1UP   HIGH SCORE        "
        .byte   "                                "
        .byte   0


Points10:   .byte   0,0,0,0,1,0
Points50:   .byte   0,0,0,0,5,0
Points200:  .byte   0,0,0,2,0,0
Points400:  .byte   0,0,0,4,0,0
Points800:  .byte   0,0,0,8,0,0
Points1600: .byte   0,0,1,6,0,0

Palette:
.incbin "../assets/palette.dat"
PaletteSize = * - Palette

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
