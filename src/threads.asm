; Main thread is thread 0

NUM_THREADS = 8
THREAD_STACK_SIZE = 256/NUM_THREADS


.segment "ZEROPAGE"

ThreadId:       .res 1
ThreadsSP:      .res 8


.segment "CODE"

DummyThread:
        jsr     NextThread
        jmp     DummyThread


InitThreads:
        lda     #$ff - THREAD_STACK_SIZE
        ldx     NUM_THREADS

        lda     #0
        sta    ThreadId

        lda     #<(DummyThread - 1)
        sta     AL
        lda     #>(DummyThread - 1)
        sta     AH

        ; Init all threads but thread 0 (main thread)
        ldx     #NUM_THREADS - 1
@loop:
        jsr     InitThread
        dex
        bne     @loop

        rts


; Input:
;   AX = address of thread's entry point, minus one
;   X = number of thread (must not be 0)
;
; Output:
;   X = X
InitThread:
        ; Calculate starting stack address
        txa
        tay
        lda     #-1
@loop:
        add     #THREAD_STACK_SIZE
        dey
        bne     @loop

        ; Init the thread's stack
        ; Entry point goes at bottom of stack so NextThread will pop it off
        tay
        lda     AH
        sta     $100,y
        dey
        lda     AL
        sta     $100,y
        tya
        sub     #4                          ; 1 byte for rest of return address, 3 bytes for regs NextThread will pop off
        sta     ThreadsSP,y

        rts


; Keep in mind an NMI or IRQ can occur in the middle of this routine if
; they're not disabled. So while calling this routine normally uses 5
; bytes of stack, you'll probably want at least 11 bytes free if there's
; any danger of this happening!
NextThread:
        ; Preserve old thread's regs
        pha
        txa
        pha
        tya
        pha

        ; Store old thread's SP
        ldy     ThreadId
        tsx
        stx     ThreadsSP,y

        ; Switch to next thread
        dey
        bpl     :+
        ldy     #NUM_THREADS - 1
:
        sty     ThreadId

        ; Get new thread's SP
        ldx     ThreadsSP,y
        txs

        ; Get new thread's preserved regs
        pla
        tay
        pla
        tax
        pla
        rts
