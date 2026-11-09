{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2823;

{ Mode 13h graphics primitives (hand-written BASM) and VGA DAC helpers.
  Most primitives write to segment g_E7D6 ($A000 or an off-screen buffer);
  the "copy" variants read the pixels from the buffer whose segment is
  passed as word ptr Buf (offset part unused). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918;

type
  TPalBlockProc = procedure(Start, Count: Integer; Buf: Pointer);
  TRGBProc = procedure(Color, R, G, B: Integer);

var
  { DS E7C0-E7E1 }
  g_E7C0: TPalBlockProc;  { SetPalette w/o retrace wait (used by the palette cycler ISR) }
  g_E7C4: procedure(Start, Count: Integer; Buf: Pointer);  { SetPalette (set by U2823 init) }
  g_E7C8: procedure(Color, R, G, B: Integer);  { SetRGB (set by U2823 init) }
  g_E7CC: ViewPortType;   { clip window (x1,y1,x2,y2,Clip) }
  g_E7D5: Byte;
  g_E7D6: Word;           { video segment used by the primitives }
  g_E7D8: Byte;           { use ports instead of BIOS }
  g_E7D9: Byte;           { no retrace wait }
  g_E7DA: Integer;        { CPU type (U2918_04A3) }
  g_E7DC: array[0..5] of Byte;

procedure U2823_0000;
procedure U2823_0006;
procedure U2823_0015;
procedure U2823_0025;
procedure U2823_0031(X1, Y1, X2, Y2: Integer; Color: Byte);
procedure U2823_0088(X1, Y1, X2, Y2: Integer; Color: Byte);
procedure U2823_00CC(X1, Y1, X2, Y2: Integer; Buf: Pointer);
procedure U2823_011A(X1, Y1, X2, Y2: Integer; Buf: Pointer);
procedure U2823_017D(X, Y, RX, RY: Integer; Color: Byte);
procedure U2823_0351(X, Y, RX, RY: Integer; Color: Byte);
procedure U2823_0687(X, Y, RX, RY: Integer; Buf: Pointer);
procedure U2823_09E4(X1, Y1, X2, Y2: Integer; Color: Byte);
procedure U2823_0AC0(X1, Y1, X2, Y2: Integer; Buf: Pointer);
procedure U2823_0BB6(X, Y: Integer; Color: Byte);
procedure U2823_0BD8(X, Y: Integer; Buf: Pointer);
function  U2823_0BFF(X, Y: Integer): Byte;
procedure U2823_0C20(Start, Count: Integer; Buf: Pointer);
procedure U2823_0C5A;
procedure U2823_0C6E(Start, Count: Integer; Buf: Pointer);
procedure U2823_0C95(Start, Count: Integer; Buf: Pointer);
procedure U2823_0CC2(Start, Count: Integer; Buf: Pointer);
procedure U2823_0CEB(Start, Count: Integer; Buf: Pointer);
procedure U2823_0D08(Start, Count: Integer; Buf: Pointer);
procedure U2823_0D32(Start, Count: Integer; Buf: Pointer);
procedure U2823_0D59(Color, R, G, B: Integer);
procedure U2823_0D71(Color, R, G, B: Integer);
procedure U2823_0D98(Color, R, G, B: Integer);
procedure U2823_0DB0(Color, R, G, B: Integer);
procedure U2823_0DCF(CPU: Integer; UsePorts, NoWait: Byte);

implementation

{ set VGA mode 13h }
{#U2823_0000}
procedure U2823_0000; assembler;
asm
    mov ax, $13
    int $10
end;

{ fetch the current Graph viewport into g_E7CC }
{#U2823_0006}
procedure U2823_0006;
begin
  GetViewSettings(g_E7CC);
end;

{ AX = y, BX = x  ->  ES:BX = pixel address }
{#U2823_0015}
procedure U2823_0015; assembler;
asm
    xchg ah, al
    add bx, ax
    shr ax, 1
    shr ax, 1
    add bx, ax
    mov ax, g_E7D6
    mov es, ax
end;

{ DX:AX := DX:AX * CX (low 32 bits) }
{#U2823_0025}
procedure U2823_0025; assembler;
asm
    push ax
    mov ax, dx
    mul cx
    xchg ax, cx
    pop dx
    mul dx
    add dx, cx
end;

{ rectangle outline }
{#U2823_0031}
procedure U2823_0031(X1, Y1, X2, Y2: Integer; Color: Byte); assembler;
asm
    push word ptr X1
    push word ptr Y1
    push word ptr X2
    push word ptr Y1
    push word ptr Color
    push word ptr X1
    push word ptr Y2
    push word ptr X2
    push word ptr Y2
    push word ptr Color
    push word ptr X1
    push word ptr Y1
    push word ptr X1
    push word ptr Y2
    push word ptr Color
    push word ptr X2
    push word ptr Y1
    push word ptr X2
    push word ptr Y2
    push word ptr Color
    call U2823_09E4
    call U2823_09E4
    call U2823_09E4
    call U2823_09E4
end;

{ filled bar }
{#U2823_0088}
procedure U2823_0088(X1, Y1, X2, Y2: Integer; Color: Byte); assembler;
asm
    mov bx, word ptr X1
    cmp bx, word ptr X2
    jng @L0099
    xchg bx, word ptr X2
    mov word ptr X1, bx
@L0099:
    mov cx, word ptr X2
    sub cx, bx
    inc cx
    mov ax, word ptr Y1
    cmp ax, word ptr Y2
    jng @L00AD
    xchg ax, word ptr Y2
    mov word ptr Y1, ax
@L00AD:
    mov dx, word ptr Y2
    inc dx
    sub dx, ax
    call U2823_0015
@L00B8:
    push cx
    mov al, byte ptr Color
    mov di, bx
    rep stosb
    pop cx
    add bx, $140
    dec dx
    jne @L00B8
end;

{ copy bar from a 64000 byte buffer (segment of Buf) to the screen }
{#U2823_00CC}
procedure U2823_00CC(X1, Y1, X2, Y2: Integer; Buf: Pointer); assembler;
asm
    push ds
    push si
    push di
    mov bx, word ptr X1
    cmp bx, word ptr X2
    jng @L00E0
    xchg bx, word ptr X2
    mov word ptr X1, bx
@L00E0:
    mov cx, word ptr X2
    sub cx, bx
    inc cx
    mov ax, word ptr Y1
    cmp ax, word ptr Y2
    jng @L00F4
    xchg ax, word ptr Y2
    mov word ptr Y1, ax
@L00F4:
    mov dx, word ptr Y2
    inc dx
    sub dx, ax
    call U2823_0015
@L00FF:
    push cx
    mov ax, word ptr Buf+2
    mov ds, ax
    mov di, bx
    mov si, di
    rep movsb
    pop cx
    add bx, $140
    dec dx
    jne @L00FF
    pop di
    pop si
    pop ds
end;

{ copy rectangle outline from buffer }
{#U2823_011A}
procedure U2823_011A(X1, Y1, X2, Y2: Integer; Buf: Pointer); assembler;
asm
    push word ptr X1
    push word ptr Y1
    push word ptr X2
    push word ptr Y1
    push word ptr Buf+2
    push word ptr Buf+2
    push word ptr X1
    push word ptr Y2
    push word ptr X2
    push word ptr Y2
    push word ptr Buf+2
    push word ptr Buf+2
    push word ptr X1
    push word ptr Y1
    push word ptr X1
    push word ptr Y2
    push word ptr Buf+2
    push word ptr Buf+2
    push word ptr X2
    push word ptr Y1
    push word ptr X2
    push word ptr Y2
    push word ptr Buf+2
    push word ptr Buf+2
    call U2823_0AC0
    call U2823_0AC0
    call U2823_0AC0
    call U2823_0AC0
end;

{ ellipse outline (no clipping); contains the far-called sub-routine @L02F5 (plot 4 points) }
{#U2823_017D}
procedure U2823_017D(X, Y, RX, RY: Integer; Color: Byte); assembler;
var
  Frame: array[1..$28] of Byte;
asm
    mov ax, word ptr RX
    mul ax
    mov [bp-$1A], ax
    mov [bp-$1C], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$22], ax
    mov [bp-$24], dx
    mov ax, word ptr RY
    mul ax
    mov [bp-$1E], ax
    mov [bp-$20], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$26], ax
    mov [bp-$28], dx
    mov ax, $140
    mul word ptr RY
    mov si, ax
    mov di, ax
    mov ax, word ptr Y
    mov bx, word ptr X
    call U2823_0015
    add si, bx
    mov [bp-2], si
    mov [bp-4], si
    sub bx, di
    mov [bp-6], bx
    mov [bp-8], bx
    xor ax, ax
    mov [bp-$12], ax
    mov [bp-$14], ax
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    mov cx, word ptr RY
    call U2823_0025
    mov [bp-$16], ax
    mov [bp-$18], dx
    mov ax, [bp-$1A]
    mov dx, [bp-$1C]
    sar dx, 1
    rcr ax, 1
    sar dx, 1
    rcr ax, 1
    add ax, [bp-$1E]
    adc dx, [bp-$20]
    mov [bp-$E], ax
    mov [bp-$10], dx
    mov ax, [bp-$1A]
    mov dx, [bp-$1C]
    mov cx, word ptr RY
    call U2823_0025
    sub [bp-$E], ax
    sbb [bp-$10], dx
    mov bx, word ptr RY
    xor cx, cx
@L0221:
    mov ax, [bp-$12]
    mov dx, [bp-$14]
    sub ax, [bp-$16]
    sbb dx, [bp-$18]
    jns @L0278
    call far ptr @L02F5
    mov cx, 1
    cmp word ptr [bp-$10], byte +0
    js @L0258
    mov ch, 1
    dec bx
    mov ax, [bp-$16]
    mov dx, [bp-$18]
    sub ax, [bp-$22]
    sbb dx, [bp-$24]
    mov [bp-$16], ax
    mov [bp-$18], dx
    sub [bp-$E], ax
    sbb [bp-$10], dx
@L0258:
    mov ax, [bp-$12]
    mov dx, [bp-$14]
    add ax, [bp-$26]
    adc dx, [bp-$28]
    mov [bp-$12], ax
    mov [bp-$14], dx
    add ax, [bp-$1E]
    adc dx, [bp-$20]
    add [bp-$E], ax
    adc [bp-$10], dx
    jmp @L0221
@L0278:
    push bx
    push cx
    mov ax, [bp-$1A]
    mov dx, [bp-$1C]
    sub ax, [bp-$1E]
    sbb dx, [bp-$20]
    mov bx, ax
    mov cx, dx
    sar dx, 1
    rcr ax, 1
    add ax, bx
    adc dx, cx
    sub ax, [bp-$12]
    sbb dx, [bp-$14]
    sub ax, [bp-$16]
    sbb dx, [bp-$18]
    sar dx, 1
    rcr ax, 1
    add [bp-$E], ax
    adc [bp-$10], dx
    pop cx
    pop bx
@L02AA:
    call far ptr @L02F5
    mov cx, $100
    cmp word ptr [bp-$10], byte +0
    jns @L02D2
    mov cl, 1
    mov ax, [bp-$12]
    mov dx, [bp-$14]
    add ax, [bp-$26]
    adc dx, [bp-$28]
    mov [bp-$12], ax
    mov [bp-$14], dx
    add [bp-$E], ax
    adc [bp-$10], dx
@L02D2:
    mov ax, [bp-$16]
    mov dx, [bp-$18]
    sub ax, [bp-$22]
    sbb dx, [bp-$24]
    mov [bp-$16], ax
    mov [bp-$18], dx
    sub ax, [bp-$1A]
    sbb dx, [bp-$1C]
    sub [bp-$E], ax
    sbb [bp-$10], dx
    dec bx
    jns @L02AA
    jmp @L034B
{#U2823_02F5}
@L02F5:
    push ax
    push bx
    push dx
    xor bx, bx
    test ch, ch
    je @L0303
    mov bx, $140
    neg bx
@L0303:
    mov si, cx
    xor ch, ch
    xchg si, cx
    mov di, si
    add si, [bp-2]
    add si, bx
    add di, [bp-6]
    sub di, bx
    mov [bp-2], si
    mov [bp-6], di
    mov ah, byte ptr Color
    mov es:[si], ah
    mov es:[di], ah
    mov si, cx
    xor ch, ch
    xchg si, cx
    neg si
    mov di, si
    add si, [bp-4]
    add si, bx
    add di, [bp-8]
    sub di, bx
    mov [bp-4], si
    mov [bp-8], di
    mov ah, byte ptr Color
    mov es:[si], ah
    mov es:[di], ah
    pop dx
    pop bx
    pop ax
    retf
@L034B:
end;

{ ellipse outline, clipped to g_E7CC when needed }
{#U2823_0351}
procedure U2823_0351(X, Y, RX, RY: Integer; Color: Byte); assembler;
var
  Frame: array[1..$3C] of Byte;
asm
    mov ax, g_E7CC.x1
    add word ptr X, ax
    mov ax, g_E7CC.y1
    add word ptr Y, ax
    mov word ptr [bp-$3A], seg @Code
    mov word ptr [bp-$3C], offset @L053F
    cmp byte ptr g_E7CC.Clip, 0
    je @L03A9
    mov ax, word ptr X
    mov bx, ax
    add ax, word ptr RX
    cmp ax, g_E7CC.x2
    jg @L03A4
    sub bx, word ptr RX
    cmp bx, g_E7CC.x1
    jl @L03A4
    mov ax, word ptr Y
    mov bx, ax
    add ax, word ptr RY
    cmp ax, g_E7CC.y2
    jg @L03A4
    sub bx, word ptr RY
    cmp bx, g_E7CC.y1
    jl @L03A4
    jmp @L03A9
@L03A4:
    mov word ptr [bp-$3C], offset @L0595
@L03A9:
    mov ax, word ptr RX
    mul ax
    mov [bp-$2A], ax
    mov [bp-$2C], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$32], ax
    mov [bp-$34], dx
    mov ax, word ptr RY
    mul ax
    mov [bp-$2E], ax
    mov [bp-$30], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$36], ax
    mov [bp-$38], dx
    mov ax, $140
    mul word ptr RY
    mov si, ax
    mov di, ax
    mov ax, word ptr X
    mov [bp-$A], ax
    mov [bp-$E], ax
    mov [bp-$12], ax
    mov [bp-$16], ax
    mov ax, word ptr Y
    add ax, word ptr RY
    mov [bp-$C], ax
    mov [bp-$10], ax
    mov ax, word ptr Y
    sub ax, word ptr RY
    mov [bp-$14], ax
    mov [bp-$18], ax
    mov ax, word ptr Y
    mov bx, word ptr X
    call U2823_0015
    add si, bx
    mov [bp-2], si
    mov [bp-4], si
    sub bx, di
    mov [bp-6], bx
    mov [bp-8], bx
    xor ax, ax
    mov [bp-$22], ax
    mov [bp-$24], ax
    mov ax, [bp-$32]
    mov dx, [bp-$34]
    mov cx, word ptr RY
    call U2823_0025
    mov [bp-$26], ax
    mov [bp-$28], dx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    sar dx, 1
    rcr ax, 1
    sar dx, 1
    rcr ax, 1
    add ax, [bp-$2E]
    adc dx, [bp-$30]
    mov [bp-$1E], ax
    mov [bp-$20], dx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    mov cx, word ptr RY
    call U2823_0025
    sub [bp-$1E], ax
    sbb [bp-$20], dx
    mov bx, word ptr RY
    xor cx, cx
@L046E:
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    sub ax, [bp-$26]
    sbb dx, [bp-$28]
    jns @L04C3
    call dword ptr [bp-$3C]
    mov cx, 1
    cmp word ptr [bp-$20], byte +0
    js @L04A3
    mov ch, 1
    dec bx
    mov ax, [bp-$26]
    mov dx, [bp-$28]
    sub ax, [bp-$32]
    sbb dx, [bp-$34]
    mov [bp-$26], ax
    mov [bp-$28], dx
    sub [bp-$1E], ax
    sbb [bp-$20], dx
@L04A3:
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    add ax, [bp-$36]
    adc dx, [bp-$38]
    mov [bp-$22], ax
    mov [bp-$24], dx
    add ax, [bp-$2E]
    adc dx, [bp-$30]
    add [bp-$1E], ax
    adc [bp-$20], dx
    jmp @L046E
@L04C3:
    push bx
    push cx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    sub ax, [bp-$2E]
    sbb dx, [bp-$30]
    mov bx, ax
    mov cx, dx
    sar dx, 1
    rcr ax, 1
    add ax, bx
    adc dx, cx
    sub ax, [bp-$22]
    sbb dx, [bp-$24]
    sub ax, [bp-$26]
    sbb dx, [bp-$28]
    sar dx, 1
    rcr ax, 1
    add [bp-$1E], ax
    adc [bp-$20], dx
    pop cx
    pop bx
@L04F5:
    call dword ptr [bp-$3C]
    mov cx, $100
    cmp word ptr [bp-$20], byte +0
    jns @L051B
    mov cl, 1
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    add ax, [bp-$36]
    adc dx, [bp-$38]
    mov [bp-$22], ax
    mov [bp-$24], dx
    add [bp-$1E], ax
    adc [bp-$20], dx
@L051B:
    mov ax, [bp-$26]
    mov dx, [bp-$28]
    sub ax, [bp-$32]
    sbb dx, [bp-$34]
    mov [bp-$26], ax
    mov [bp-$28], dx
    sub ax, [bp-$2A]
    sbb dx, [bp-$2C]
    sub [bp-$1E], ax
    sbb [bp-$20], dx
    dec bx
    jns @L04F5
    jmp @L0681
@L053F:
    push ax
    push bx
    push dx
    xor bx, bx
    test ch, ch
    je @L054D
    mov bx, $140
    neg bx
@L054D:
    mov si, cx
    xor ch, ch
    xchg si, cx
    mov di, si
    add si, [bp-2]
    add si, bx
    add di, [bp-6]
    sub di, bx
    mov [bp-2], si
    mov [bp-6], di
    mov ah, byte ptr Color
    mov es:[si], ah
    mov es:[di], ah
    mov si, cx
    xor ch, ch
    xchg si, cx
    neg si
    mov di, si
    add si, [bp-4]
    add si, bx
    add di, [bp-8]
    sub di, bx
    mov [bp-4], si
    mov [bp-8], di
    mov ah, byte ptr Color
    mov es:[si], ah
    mov es:[di], ah
    pop dx
    pop bx
    pop ax
    retf
@L0595:
    push ax
    push bx
    push dx
    xor bx, bx
    test ch, ch
    je @L05A3
    mov bx, $140
    neg bx
@L05A3:
    mov al, cl
    cbw
    add [bp-$E], ax
    sub [bp-$A], ax
    add [bp-$16], ax
    sub [bp-$12], ax
    mov al, ch
    cbw
    sub [bp-$10], ax
    sub [bp-$C], ax
    add [bp-$18], ax
    add [bp-$14], ax
    mov si, cx
    xor ch, ch
    xchg si, cx
    mov di, si
    add si, [bp-2]
    add si, bx
    add di, [bp-6]
    sub di, bx
    mov [bp-2], si
    mov [bp-6], di
    mov ch, byte ptr Color
    mov ax, [bp-$E]
    cmp ax, g_E7CC.x1
    jl @L05FD
    cmp ax, g_E7CC.x2
    jg @L05FD
    mov ax, [bp-$10]
    cmp ax, g_E7CC.y1
    jl @L05FD
    cmp ax, g_E7CC.y2
    jg @L05FD
    mov es:[si], ch
@L05FD:
    mov ax, [bp-$16]
    cmp ax, g_E7CC.x1
    jl @L061E
    cmp ax, g_E7CC.x2
    jg @L061E
    mov ax, [bp-$18]
    cmp ax, g_E7CC.y1
    jl @L061E
    cmp ax, g_E7CC.y2
    jg @L061E
    mov es:[di], ch
@L061E:
    mov si, cx
    xor ch, ch
    xchg si, cx
    neg si
    mov di, si
    add si, [bp-4]
    add si, bx
    add di, [bp-8]
    sub di, bx
    mov [bp-4], si
    mov [bp-8], di
    mov ch, byte ptr Color
    mov ax, [bp-$A]
    cmp ax, g_E7CC.x1
    jl @L065C
    cmp ax, g_E7CC.x2
    jg @L065C
    mov ax, [bp-$C]
    cmp ax, g_E7CC.y1
    jl @L065C
    cmp ax, g_E7CC.y2
    jg @L065C
    mov es:[si], ch
@L065C:
    mov ax, [bp-$12]
    cmp ax, g_E7CC.x1
    jl @L067D
    cmp ax, g_E7CC.x2
    jg @L067D
    mov ax, [bp-$14]
    cmp ax, g_E7CC.y1
    jl @L067D
    cmp ax, g_E7CC.y2
    jg @L067D
    mov es:[di], ch
@L067D:
    pop dx
    pop bx
    pop ax
    retf
@L0681:
end;

{ ellipse outline copied from buffer }
{#U2823_0687}
procedure U2823_0687(X, Y, RX, RY: Integer; Buf: Pointer); assembler;
var
  Frame: array[1..$3C] of Byte;
asm
    mov ax, g_E7CC.x1
    add word ptr X, ax
    mov ax, g_E7CC.y1
    add word ptr Y, ax
    mov word ptr [bp-$3A], seg @Code
    mov word ptr [bp-$3C], offset @L0875
    cmp byte ptr g_E7CC.Clip, 0
    je @L06DF
    mov ax, word ptr X
    mov bx, ax
    add ax, word ptr RX
    cmp ax, g_E7CC.x2
    jg @L06DA
    sub bx, word ptr RX
    cmp bx, g_E7CC.x1
    jl @L06DA
    mov ax, word ptr Y
    mov bx, ax
    add ax, word ptr RY
    cmp ax, g_E7CC.y2
    jg @L06DA
    sub bx, word ptr RY
    cmp bx, g_E7CC.y1
    jl @L06DA
    jmp @L06DF
@L06DA:
    mov word ptr [bp-$3C], offset @L08D4
@L06DF:
    mov ax, word ptr RX
    mul ax
    mov [bp-$2A], ax
    mov [bp-$2C], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$32], ax
    mov [bp-$34], dx
    mov ax, word ptr RY
    mul ax
    mov [bp-$2E], ax
    mov [bp-$30], dx
    shl ax, 1
    rcl dx, 1
    mov [bp-$36], ax
    mov [bp-$38], dx
    mov ax, $140
    mul word ptr RY
    mov si, ax
    mov di, ax
    mov ax, word ptr X
    mov [bp-$A], ax
    mov [bp-$E], ax
    mov [bp-$12], ax
    mov [bp-$16], ax
    mov ax, word ptr Y
    add ax, word ptr RY
    mov [bp-$C], ax
    mov [bp-$10], ax
    mov ax, word ptr Y
    sub ax, word ptr RY
    mov [bp-$14], ax
    mov [bp-$18], ax
    mov ax, word ptr Y
    mov bx, word ptr X
    call U2823_0015
    add si, bx
    mov [bp-2], si
    mov [bp-4], si
    sub bx, di
    mov [bp-6], bx
    mov [bp-8], bx
    xor ax, ax
    mov [bp-$22], ax
    mov [bp-$24], ax
    mov ax, [bp-$32]
    mov dx, [bp-$34]
    mov cx, word ptr RY
    call U2823_0025
    mov [bp-$26], ax
    mov [bp-$28], dx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    sar dx, 1
    rcr ax, 1
    sar dx, 1
    rcr ax, 1
    add ax, [bp-$2E]
    adc dx, [bp-$30]
    mov [bp-$1E], ax
    mov [bp-$20], dx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    mov cx, word ptr RY
    call U2823_0025
    sub [bp-$1E], ax
    sbb [bp-$20], dx
    mov bx, word ptr RY
    xor cx, cx
@L07A4:
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    sub ax, [bp-$26]
    sbb dx, [bp-$28]
    jns @L07F9
    call dword ptr [bp-$3C]
    mov cx, 1
    cmp word ptr [bp-$20], byte +0
    js @L07D9
    mov ch, 1
    dec bx
    mov ax, [bp-$26]
    mov dx, [bp-$28]
    sub ax, [bp-$32]
    sbb dx, [bp-$34]
    mov [bp-$26], ax
    mov [bp-$28], dx
    sub [bp-$1E], ax
    sbb [bp-$20], dx
@L07D9:
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    add ax, [bp-$36]
    adc dx, [bp-$38]
    mov [bp-$22], ax
    mov [bp-$24], dx
    add ax, [bp-$2E]
    adc dx, [bp-$30]
    add [bp-$1E], ax
    adc [bp-$20], dx
    jmp @L07A4
@L07F9:
    push bx
    push cx
    mov ax, [bp-$2A]
    mov dx, [bp-$2C]
    sub ax, [bp-$2E]
    sbb dx, [bp-$30]
    mov bx, ax
    mov cx, dx
    sar dx, 1
    rcr ax, 1
    add ax, bx
    adc dx, cx
    sub ax, [bp-$22]
    sbb dx, [bp-$24]
    sub ax, [bp-$26]
    sbb dx, [bp-$28]
    sar dx, 1
    rcr ax, 1
    add [bp-$1E], ax
    adc [bp-$20], dx
    pop cx
    pop bx
@L082B:
    call dword ptr [bp-$3C]
    mov cx, $100
    cmp word ptr [bp-$20], byte +0
    jns @L0851
    mov cl, 1
    mov ax, [bp-$22]
    mov dx, [bp-$24]
    add ax, [bp-$36]
    adc dx, [bp-$38]
    mov [bp-$22], ax
    mov [bp-$24], dx
    add [bp-$1E], ax
    adc [bp-$20], dx
@L0851:
    mov ax, [bp-$26]
    mov dx, [bp-$28]
    sub ax, [bp-$32]
    sbb dx, [bp-$34]
    mov [bp-$26], ax
    mov [bp-$28], dx
    sub ax, [bp-$2A]
    sbb dx, [bp-$2C]
    sub [bp-$1E], ax
    sbb [bp-$20], dx
    dec bx
    jns @L082B
    jmp @L09DE
@L0875:
    push ds
    push ax
    push bx
    push dx
    mov ax, word ptr Buf+2
    mov ds, ax
    xor bx, bx
    test ch, ch
    je @L0889
    mov bx, $140
    neg bx
@L0889:
    mov si, cx
    xor ch, ch
    xchg si, cx
    mov di, si
    add si, [bp-2]
    add si, bx
    add di, [bp-6]
    sub di, bx
    mov [bp-2], si
    mov [bp-6], di
    mov al, [si]
    mov ah, [di]
    mov es:[si], al
    mov es:[di], ah
    mov si, cx
    xor ch, ch
    xchg si, cx
    neg si
    mov di, si
    add si, [bp-4]
    add si, bx
    add di, [bp-8]
    sub di, bx
    mov [bp-4], si
    mov [bp-8], di
    mov ah, [si]
    mov al, [di]
    mov es:[si], ah
    mov es:[di], al
    pop dx
    pop bx
    pop ax
    pop ds
    retf
@L08D4:
    push ax
    push bx
    push dx
    xor bx, bx
    test ch, ch
    je @L08E2
    mov bx, $140
    neg bx
@L08E2:
    mov al, cl
    cbw
    add [bp-$E], ax
    sub [bp-$A], ax
    add [bp-$16], ax
    sub [bp-$12], ax
    mov al, ch
    cbw
    sub [bp-$10], ax
    sub [bp-$C], ax
    add [bp-$18], ax
    add [bp-$14], ax
    mov si, cx
    xor ch, ch
    xchg si, cx
    mov di, si
    add si, [bp-2]
    add si, bx
    add di, [bp-6]
    sub di, bx
    mov [bp-2], si
    mov [bp-6], di
    mov ax, [bp-$E]
    cmp ax, g_E7CC.x1
    jl @L0942
    cmp ax, g_E7CC.x2
    jg @L0942
    mov ax, [bp-$10]
    cmp ax, g_E7CC.y1
    jl @L0942
    cmp ax, g_E7CC.y2
    jg @L0942
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [si]
    mov es:[si], al
    pop ds
@L0942:
    mov ax, [bp-$16]
    cmp ax, g_E7CC.x1
    jl @L096C
    cmp ax, g_E7CC.x2
    jg @L096C
    mov ax, [bp-$18]
    cmp ax, g_E7CC.y1
    jl @L096C
    cmp ax, g_E7CC.y2
    jg @L096C
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [di]
    mov es:[di], al
    pop ds
@L096C:
    mov si, cx
    xor ch, ch
    xchg si, cx
    neg si
    mov di, si
    add si, [bp-4]
    add si, bx
    add di, [bp-8]
    sub di, bx
    mov [bp-4], si
    mov [bp-8], di
    mov ax, [bp-$A]
    cmp ax, g_E7CC.x1
    jl @L09B0
    cmp ax, g_E7CC.x2
    jg @L09B0
    mov ax, [bp-$C]
    cmp ax, g_E7CC.y1
    jl @L09B0
    cmp ax, g_E7CC.y2
    jg @L09B0
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [si]
    mov es:[si], al
    pop ds
@L09B0:
    mov ax, [bp-$12]
    cmp ax, g_E7CC.x1
    jl @L09DA
    cmp ax, g_E7CC.x2
    jg @L09DA
    mov ax, [bp-$14]
    cmp ax, g_E7CC.y1
    jl @L09DA
    cmp ax, g_E7CC.y2
    jg @L09DA
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [di]
    mov es:[di], al
    pop ds
@L09DA:
    pop dx
    pop bx
    pop ax
    retf
@L09DE:
end;

{ line (Bresenham) }
{#U2823_09E4}
procedure U2823_09E4(X1, Y1, X2, Y2: Integer; Color: Byte); assembler;
var
  Frame: array[1..6] of Byte;
asm
    mov si, $140
    mov cx, word ptr X2
    sub cx, word ptr X1
    je @L0A4C
    jns @L0A0B
    neg cx
    mov bx, word ptr X2
    xchg bx, word ptr X1
    mov word ptr X2, bx
    mov bx, word ptr Y2
    xchg bx, word ptr Y1
    mov word ptr Y2, bx
@L0A0B:
    mov bx, word ptr Y2
    sub bx, word ptr Y1
    je @L0A74
    jns @L0A19
    neg bx
    neg si
@L0A19:
    push si
    mov word ptr [bp-6], $A8B
    cmp bx, cx
    jng @L0A2A
    mov word ptr [bp-6], $AA3
    xchg bx, cx
@L0A2A:
    shl bx, 1
    mov [bp-2], bx
    sub bx, cx
    mov si, bx
    sub bx, cx
    mov [bp-4], bx
    push cx
    mov ax, word ptr Y1
    mov bx, word ptr X1
    call U2823_0015
    mov di, bx
    pop cx
    inc cx
    pop bx
    jmp word ptr [bp-6]
@L0A4C:
    mov ax, word ptr Y1
    mov bx, word ptr Y2
    mov cx, bx
    sub cx, ax
    jnl @L0A5C
    neg cx
    mov ax, bx
@L0A5C:
    inc cx
    mov bx, word ptr X1
    push cx
    call U2823_0015
    pop cx
    mov di, bx
    dec si
    mov al, byte ptr Color
@L0A6D:
    stosb
    add di, si
    loop @L0A6D
    jmp @L0ABA
@L0A74:
    push cx
    mov ax, word ptr Y1
    mov bx, word ptr X1
    call U2823_0015
    mov di, bx
    pop cx
    inc cx
    mov al, byte ptr Color
    rep stosb
    jmp @L0ABA
@L0A8B:
    mov al, byte ptr Color
@L0A8E:
    stosb
    or si, si
    jns @L0A9A
    add si, [bp-2]
    loop @L0A8E
    jmp @L0ABA
@L0A9A:
    add si, [bp-4]
    add di, bx
    loop @L0A8E
    jmp @L0ABA
@L0AA3:
    mov al, byte ptr Color
@L0AA6:
    stosb
    add di, bx
    or si, si
    jns @L0AB5
    add si, [bp-2]
    dec di
    loop @L0AA6
    jmp @L0ABA
@L0AB5:
    add si, [bp-4]
    loop @L0AA6
@L0ABA:
end;

{ line copied from buffer }
{#U2823_0AC0}
procedure U2823_0AC0(X1, Y1, X2, Y2: Integer; Buf: Pointer); assembler;
var
  Frame: array[1..6] of Byte;
asm
    mov si, $140
    mov cx, word ptr X2
    sub cx, word ptr X1
    je @L0B28
    jns @L0AE7
    neg cx
    mov bx, word ptr X2
    xchg bx, word ptr X1
    mov word ptr X2, bx
    mov bx, word ptr Y2
    xchg bx, word ptr Y1
    mov word ptr Y2, bx
@L0AE7:
    mov bx, word ptr Y2
    sub bx, word ptr Y1
    je @L0B56
    jns @L0AF5
    neg bx
    neg si
@L0AF5:
    push si
    mov word ptr [bp-6], $B75
    cmp bx, cx
    jng @L0B06
    mov word ptr [bp-6], $B93
    xchg bx, cx
@L0B06:
    shl bx, 1
    mov [bp-2], bx
    sub bx, cx
    mov si, bx
    sub bx, cx
    mov [bp-4], bx
    push cx
    mov ax, word ptr Y1
    mov bx, word ptr X1
    call U2823_0015
    mov di, bx
    pop cx
    inc cx
    pop bx
    jmp word ptr [bp-6]
@L0B28:
    mov ax, word ptr Y1
    mov bx, word ptr Y2
    mov cx, bx
    sub cx, ax
    jnl @L0B38
    neg cx
    mov ax, bx
@L0B38:
    inc cx
    mov bx, word ptr X1
    push cx
    call U2823_0015
    pop cx
    mov di, bx
    dec si
@L0B46:
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [di]
    pop ds
    stosb
    add di, si
    loop @L0B46
    jmp @L0BB0
@L0B56:
    push cx
    mov ax, word ptr Y1
    mov bx, word ptr X1
    call U2823_0015
    mov di, bx
    pop cx
    inc cx
    push si
    push ds
    mov si, di
    mov ax, word ptr Buf+2
    mov ds, ax
    rep movsb
    pop ds
    pop si
    jmp @L0BB0
@L0B75:
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [di]
    pop ds
    stosb
    or si, si
    jns @L0B8A
    add si, [bp-2]
    loop @L0B75
    jmp @L0BB0
@L0B8A:
    add si, [bp-4]
    add di, bx
    loop @L0B75
    jmp @L0BB0
@L0B93:
    push ds
    mov ax, word ptr Buf+2
    mov ds, ax
    mov al, [di]
    pop ds
    stosb
    add di, bx
    or si, si
    jns @L0BAB
    add si, [bp-2]
    dec di
    loop @L0B93
    jmp @L0BB0
@L0BAB:
    add si, [bp-4]
    loop @L0B93
@L0BB0:
end;

{ put pixel }
{#U2823_0BB6}
procedure U2823_0BB6(X, Y: Integer; Color: Byte); assembler;
asm
    mov ax, word ptr Y
    mov bx, word ptr X
    xchg ah, al
    add bx, ax
    shr ax, 1
    shr ax, 1
    add bx, ax
    mov dl, byte ptr Color
    mov ax, $A000
    mov es, ax
    mov es:[bx], dl
end;

{ copy one pixel from buffer }
{#U2823_0BD8}
procedure U2823_0BD8(X, Y: Integer; Buf: Pointer); assembler;
asm
    mov ax, word ptr Y
    mov bx, word ptr X
    xchg ah, al
    add bx, ax
    shr ax, 1
    shr ax, 1
    add bx, ax
    mov ax, word ptr Buf+2
    mov es, ax
    mov dl, es:[bx]
    mov ax, $A000
    mov es, ax
    mov es:[bx], dl
end;

{ get pixel }
{#U2823_0BFF}
function U2823_0BFF(X, Y: Integer): Byte; assembler;
asm
    mov ax, word ptr Y
    mov bx, word ptr X
    xchg ah, al
    add bx, ax
    shr ax, 1
    shr ax, 1
    add bx, ax
    mov ax, $A000
    mov es, ax
    xor ax, ax
    mov al, es:[bx]
end;

{ read DAC block (INT 10h AX=1017h) }
{#U2823_0C20}
procedure U2823_0C20(Start, Count: Integer; Buf: Pointer);
var
  R: Registers;
begin
  R.AX := $1017;
  R.BX := Start;
  R.CX := Count;
  R.ES := Seg(Buf^);
  R.DX := Ofs(Buf^);
  Intr($10, R);
end;

{ clear screen }
{#U2823_0C5A}
procedure U2823_0C5A; assembler;
asm
    push di
    cld
    mov ax, $A000
    mov es, ax
    mov ax, 0
    mov di, 0
    mov cx, $800A
    rep stosw
    pop di
end;

{ set DAC block via BIOS, wait for retrace }
{#U2823_0C6E}
procedure U2823_0C6E(Start, Count: Integer; Buf: Pointer); assembler;
asm
    push ds
    mov ax, word ptr Buf+2
    mov es, ax
    mov cx, word ptr Count
    mov bx, word ptr Start
    mov ah, $10
    mov dx, word ptr Buf
    push dx
    mov dx, $3DA
@L0C86:
    in al, dx
    test al, 8
    je @L0C86
    mov al, $12
    pop dx
    int $10
    pop ds
end;

{ set DAC block via ports, wait for retrace (8086) }
{#U2823_0C95}
procedure U2823_0C95(Start, Count: Integer; Buf: Pointer); assembler;
asm
    push ds
    mov al, byte ptr Count
    mov cl, 3
    mul cl
    mov cx, ax
    lds si, Buf
    mov dx, $3DA
@L0CA8:
    in al, dx
    test al, 8
    je @L0CA8
    cli
    mov dx, $3C8
    mov al, byte ptr Start
    out dx, al
    inc dx
@L0CB6:
    mov al, [si]
    inc si
    out dx, al
    loop @L0CB6
    sti
    pop ds
end;

{ set DAC block via ports, wait for retrace (286+: rep outsb) }
{#U2823_0CC2}
procedure U2823_0CC2(Start, Count: Integer; Buf: Pointer); assembler;
asm
    push ds
    mov cx, word ptr Count
    add cx, cx
    add cx, word ptr Count
    lds si, Buf
    cli
    cld
    mov dx, $3DA
@L0CD6:
    in al, dx
    test al, 8
    je @L0CD6
    mov dx, $3C8
    mov al, byte ptr Start
    out dx, al
    inc dx
    db $F3, $6E                { rep outsb }
    sti
    pop ds
end;

{ set DAC block via BIOS }
{#U2823_0CEB}
procedure U2823_0CEB(Start, Count: Integer; Buf: Pointer); assembler;
asm
    mov ax, word ptr Buf+2
    mov es, ax
    mov cx, word ptr Count
    mov bx, word ptr Start
    mov ah, $10
    mov dx, word ptr Buf
    push dx
    mov al, $12
    pop dx
    int $10
end;

{ set DAC block via ports (8086) }
{#U2823_0D08}
procedure U2823_0D08(Start, Count: Integer; Buf: Pointer); assembler;
asm
    push ds
    mov al, byte ptr Count
    mov cl, 3
    mul cl
    mov cx, ax
    lds si, Buf
    mov dx, $3DA
    mov dx, $3C8
    mov al, byte ptr Start
    out dx, al
    mov dx, $3C9
    cli
@L0D26:
    mov al, [si]
    inc si
    out dx, al
    loop @L0D26
    sti
    pop ds
end;

{ set DAC block via ports (286+) }
{#U2823_0D32}
procedure U2823_0D32(Start, Count: Integer; Buf: Pointer); assembler;
asm
    push ds
    mov al, byte ptr Count
    mov cl, 3
    mul cl
    mov cx, ax
    lds si, Buf
    mov dx, $3DA
    mov dx, $3C8
    mov al, byte ptr Start
    out dx, al
    mov dx, $3C9
    cli
    cld
    db $F3, $6E                { rep outsb }
    sti
    pop ds
end;

{ set one DAC register via BIOS }
{#U2823_0D59}
procedure U2823_0D59(Color, R, G, B: Integer); assembler;
asm
    mov ax, $1010
    mov bx, word ptr Color
    mov dh, byte ptr R
    mov ch, byte ptr G
    mov cl, byte ptr B
    int $10
end;

{ set one DAC register via ports, wait for retrace }
{#U2823_0D71}
procedure U2823_0D71(Color, R, G, B: Integer); assembler;
asm
    mov dx, $3DA
@L0D77:
    in al, dx
    test al, 8
    je @L0D77
    mov dx, $3C8
    mov al, byte ptr Color
    out dx, al
    mov dx, $3C9
    cli
    mov al, byte ptr R
    out dx, al
    mov al, byte ptr G
    out dx, al
    mov al, byte ptr B
    out dx, al
    sti
end;

{ set one DAC register via BIOS }
{#U2823_0D98}
procedure U2823_0D98(Color, R, G, B: Integer); assembler;
asm
    mov ax, $1010
    mov bx, word ptr Color
    mov dh, byte ptr R
    mov ch, byte ptr G
    mov cl, byte ptr B
    int $10
end;

{ set one DAC register via ports }
{#U2823_0DB0}
procedure U2823_0DB0(Color, R, G, B: Integer); assembler;
asm
    mov dx, $3C8
    mov al, byte ptr Color
    out dx, al
    mov dx, $3C9
    cli
    mov al, byte ptr R
    out dx, al
    mov al, byte ptr G
    out dx, al
    mov al, byte ptr B
    out dx, al
    sti
end;

{ select the DAC routines for this machine }
{#U2823_0DCF}
procedure U2823_0DCF(CPU: Integer; UsePorts, NoWait: Byte);
begin
  CPU := Abs(CPU);
  if (CPU = $56) or (CPU = $BA) or (CPU = $11E) or (CPU = $182) then
  begin
    g_E7DA := CPU;
    g_E7D8 := UsePorts;
    g_E7D9 := NoWait;
    if g_E7D9 = 0 then
    begin
      if g_E7D8 = 0 then
        g_E7C4 := U2823_0C6E
      else if g_E7DA >= $11E then
        g_E7C4 := U2823_0CC2
      else
        g_E7C4 := U2823_0C95;
    end
    else
    begin
      if g_E7D8 = 0 then
        g_E7C4 := U2823_0CEB
      else if g_E7DA >= $11E then
        g_E7C4 := U2823_0D32
      else
        g_E7C4 := U2823_0D08;
    end;
    if g_E7D8 = 0 then
      g_E7C0 := U2823_0CEB
    else if g_E7DA >= $11E then
      g_E7C0 := U2823_0D32
    else
      g_E7C0 := U2823_0D08;
    if g_E7D9 = 0 then
    begin
      if g_E7D8 = 0 then
        g_E7C8 := U2823_0D59
      else
        g_E7C8 := U2823_0D71;
    end
    else
    begin
      if g_E7D8 = 0 then
        g_E7C8 := U2823_0D98
      else
        g_E7C8 := U2823_0DB0;
    end;
  end;
end;

{#U2823_0F17}
begin
  U2823_0DCF($56, 0, 0);
  g_E7CC.x1 := 0;
  g_E7CC.y1 := 0;
  g_E7CC.x2 := 319;
  g_E7CC.y2 := 199;
  g_E7CC.Clip := True;
  g_E7D6 := $A000;
  U2823_0C5A;
end.
