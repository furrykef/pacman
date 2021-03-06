; This code has a timing loop in it. The loop's branch must not cross a page boundary.
; Thus, this code should be placed at the start of a bank to keep the page boundary predictable.
.segment "CODE"

HandleVblank:
        bit     PPUSTATUS                   ; make sure vblank flag gets cleared
        pha
        txa
        pha
        tya
        pha

        ; OAM DMA
        lda     #$00
        sta     OAMADDR
        lda     #>MyOAM
        sta     OAMDMA

        ; Render display list if ready
        lda     fDisplayListReady
        beq     @skip_display_list
        jsr     FlushDisplayList
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
        lda     #$a2                        ; NMI on, 8x16 sprites, 2nd nametable (where status bar is)
        sta     PPUCTRL
        lda     #0
        sta     PPUSCROLL
        lda     #208
        sta     PPUSCROLL

        lda     #$18                        ; BG and sprites on
        ldx     fPaused
        beq     @not_paused
        ora     #$e0                        ; color emphasis bits on
@not_paused:
        sta     PPUMASK

        ; Split the screen with a sprite zero hit
        ; First wait for rendering
@wait_for_rendering_to_begin:
        bit     PPUSTATUS
        bvs     @wait_for_rendering_to_begin

        ; Run sound engine while we wait for sprite zero
        jsr     SoundTick

        ; Skip sprite zero hit if flag is set
        ; (thus skipping to setting scroll)
        lda     fSplitScreen
        beq     @skip_sprite_zero

@wait_for_sprite_zero:
        bit     PPUSTATUS
        bvc     @wait_for_sprite_zero

        ; Burn some cycles until we're nearly at hblank
        ldx     #30                         ; 2 cycles
@delay:
        dex                                 ; 2 cycles
        bne     @delay                      ; 3 cycles (2 on last iteration)
        assert_branch_page @delay

@skip_sprite_zero:
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

        inc     FrameCounter
        pla
        tay
        pla
        tax
        pla
        rti
