; CPU detection used by CpuType (function: Integer, far).
; Hand-written assembler in the original (TASM-style encodings), linked as an
; external.  Returns 86 ($56) for 8086/88, 186 ($BA) for 80186, 286 ($11E) for
; 80286, 386 ($182) for 80386+; negative if the CPU runs in protected mode.
; Assembled with NASM (-f bin) to CPUID.BIN, then converted with BINOBJ.
; Register-register forms are given as db: NASM would pick the other encoding.
        bits 16
        cpu  386
        pushf
        push cx
        push bp
        db   8Bh, 0C4h            ; mov ax, sp   (TASM encoding)
        push sp
        pop cx
        db   3Bh, 0C1h            ; cmp ax, cx   (8086/186 push the decremented SP)
        jz   short .not86
        mov  ax, 186
        mov  cl, 32
        shl  ax, cl                 ; 186+ masks the count: result stays non-zero
        jnz  short .done
        mov  ax, 86
        jmp  short .done
.not86: pushf
        db   8Bh, 0CCh            ; mov cx, sp
        popf
        inc  cx
        inc  cx
        db   3Bh, 0C8h            ; cmp cx, ax
        jnz  short .is386
        sub  sp, byte 6
        db   8Bh, 0ECh            ; mov bp, sp
        sgdt [bp+0]
        add  sp, byte 4
        pop  ax
        inc  ah                     ; 286 stores FFh in the top byte
        jnz  short .is386b
        mov  ax, 286
        jmp  short .pm
        nop
.is386: db   66h                    ; (mov eax,...) - unreachable prefix, kept for the bytes
        mov  ax, 386
        jmp  short .pm
.is386b: mov ax, 386
.pm:    smsw cx
        ror  cx, 1
        jnc  short .done
        neg  ax
.done:  pop  bp
        pop  cx
        popf
        retf
