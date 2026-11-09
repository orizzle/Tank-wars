{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U27D4;

{ Palette cycler driven by the timer (INT 1Ch) or by the vertical retrace
  interrupt (IRQ2 = INT 0Ah, EGA/VGA CRTC vertical interrupt). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823;

type
  { parameter block of the palette cycler }
  TPalCycle = record
    First: Word;        { +0  -> g_E7A0 }
    Field2: Word;       { +2  -> g_E7A2 }
    Count: Word;        { +4  -> g_E7A4 }
    Mode: Integer;      { +6  -> g_E7A6 (1 = cycling) }
    Pos: Word;          { +8  -> g_E7AC }
    Speed: Word;        { +A  -> g_E7AF (ticks per step) }
    Pal: Pointer;       { +C  -> g_E7A8 (RGB triples) }
  end;

var
  { DS E7A0-E7BF }
  g_E7A0: Word;         { first colour }
  g_E7A2: Word;
  g_E7A4: Word;         { number of colours - 1 }
  g_E7A6: Integer;      { mode: 1 = cycling }
  g_E7A8: Pointer;      { palette data }
  g_E7AC: Word;         { current position }
  g_E7AE: Byte;         { installed }
  g_E7AF: Byte;         { speed }
  g_E7B0: Byte;         { tick counter }
  g_E7B1: Byte;
  g_E7B2: Pointer;      { old interrupt vector }
  g_E7B6: Word;         { CRTC index port }
  g_E7B8: Byte;         { CRTC register index ($11) }
  g_E7B9: Byte;         { saved CRTC register $11 }
  g_E7BA: Pointer;      { saved ExitProc }
  g_E7BE: Byte;         { direction: 1 = forward }
  g_E7BF: Byte;         { use vertical retrace IRQ instead of timer }

procedure U27D4_0000;
procedure U27D4_001E;
procedure U27D4_0027;
procedure U27D4_003D(P: TPalCycle);
procedure U27D4_008D(var P: TPalCycle);
procedure U27D4_00E3;
procedure U27D4_0195;
procedure U27D4_0244(UseRetrace: Byte);
procedure U27D4_0346;
procedure U27D4_03A7;
procedure U27D4_0428;

implementation

{ exit procedure }
{#U27D4_0000}
procedure U27D4_0000;
begin
  if g_E7AE <> 0 then U27D4_03A7;
  ExitProc := g_E7BA;
end;

{#U27D4_001E}
procedure U27D4_001E;
begin
  Dec(g_E7A6);
end;

{#U27D4_0027}
procedure U27D4_0027;
begin
  Inc(g_E7A6);
  if g_E7A6 > 1 then g_E7A6 := 1;
end;

{ set cycler parameters }
{#U27D4_003D}
procedure U27D4_003D(P: TPalCycle);
begin
  g_E7A0 := P.First;
  g_E7A2 := P.Field2;
  g_E7A4 := P.Count;
  g_E7AC := P.Pos;
  g_E7A6 := P.Mode;
  g_E7A8 := P.Pal;
  g_E7AF := P.Speed;
end;

{ get cycler parameters }
{#U27D4_008D}
procedure U27D4_008D(var P: TPalCycle);
begin
  P.First := g_E7A0;
  P.Field2 := g_E7A2;
  P.Count := g_E7A4;
  P.Pos := g_E7AC;
  P.Mode := g_E7A6;
  P.Pal := g_E7A8;
  P.Speed := g_E7AF;
end;

{ interrupt handler, cycling forward }
{#U27D4_00E3}
procedure U27D4_00E3; assembler;
asm
    cli
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    mov ax, seg @Data
    mov ds, ax
    cmp byte ptr [g_E7BF], 0
    je @timer
    mov dx, 3C2h
    in al, dx
    test al, 80h
    jne @retrace
    pushf
    call dword ptr [g_E7B2]
    jmp @exit
@retrace:
    mov dx, 3D4h
    in al, dx
    push ax
    mov al, byte ptr [g_E7B8]
    mov ah, byte ptr [g_E7B9]
    and ah, 0EFh
    out dx, ax
    jmp @eoi
@timer:
    pushf
    call dword ptr [g_E7B2]
@eoi:
    mov al, 20h
    out 20h, al
    cmp word ptr [g_E7A6], 1
    jne @done
    inc byte ptr [g_E7B0]
    mov al, byte ptr [g_E7B0]
    cmp al, byte ptr [g_E7AF]
    jb @done
    mov byte ptr [g_E7B0], 0
    mov ax, word ptr [g_E7A4]
    cmp word ptr [g_E7AC], ax
    jbe @1
    mov word ptr [g_E7AC], 0
@1:
    push word ptr [g_E7A0]
    mov ax, word ptr [g_E7A4]
    inc ax
    push ax
    mov ax, word ptr [g_E7A8]
    add ax, word ptr [g_E7AC]
    add ax, word ptr [g_E7AC]
    add ax, word ptr [g_E7AC]
    push word ptr [g_E7A8+2]
    push ax
    call dword ptr [g_E7C0]
    inc word ptr [g_E7AC]
@done:
    cmp byte ptr [g_E7BF], 0
    je @exit
    mov dx, 3D4h
    mov al, byte ptr [g_E7B8]
    mov ah, byte ptr [g_E7B9]
    and ah, 0DFh
    or ah, 10h
    out dx, ax
    pop ax
    out dx, al
@exit:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    sti
    iret
end;

{ interrupt handler, cycling backward }
{#U27D4_0195}
procedure U27D4_0195; assembler;
asm
    cli
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    mov ax, seg @Data
    mov ds, ax
    cmp byte ptr [g_E7BF], 0
    je @timer
    mov dx, 3C2h
    in al, dx
    test al, 80h
    jne @retrace
    pushf
    call dword ptr [g_E7B2]
    jmp @exit
@retrace:
    mov dx, 3D4h
    in al, dx
    push ax
    mov al, byte ptr [g_E7B8]
    mov ah, byte ptr [g_E7B9]
    and ah, 0EFh
    out dx, ax
    jmp @eoi
@timer:
    pushf
    call dword ptr [g_E7B2]
@eoi:
    mov al, 20h
    out 20h, al
    cmp word ptr [g_E7A6], 1
    jne @done
    inc byte ptr [g_E7B0]
    mov al, byte ptr [g_E7B0]
    cmp al, byte ptr [g_E7AF]
    jb @done
    mov byte ptr [g_E7B0], 0
    mov ax, word ptr [g_E7A4]
    cmp word ptr [g_E7AC], ax
    jbe @1
    mov word ptr [g_E7AC], ax
@1:
    push word ptr [g_E7A0]
    mov ax, word ptr [g_E7A4]
    inc ax
    push ax
    mov ax, word ptr [g_E7A8]
    add ax, word ptr [g_E7AC]
    add ax, word ptr [g_E7AC]
    add ax, word ptr [g_E7AC]
    push word ptr [g_E7A8+2]
    push ax
    call dword ptr [g_E7C0]
    dec word ptr [g_E7AC]
@done:
    cmp byte ptr [g_E7BF], 0
    je @exit
    mov dx, 3D4h
    mov al, byte ptr [g_E7B8]
    mov ah, byte ptr [g_E7B9]
    and ah, 0DFh
    or ah, 10h
    out dx, ax
    pop ax
    out dx, al
@exit:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    sti
    iret
end;

{ install the cycler }
{#U27D4_0244}
procedure U27D4_0244(UseRetrace: Byte);
begin
  if g_E7AE <> 0 then Exit;
  g_E7AE := 1;
  g_E7A6 := 0;
  g_E7A4 := 0;
  g_E7A0 := 0;
  g_E7A2 := 0;
  g_E7AC := 0;
  g_E7AF := 1;
  inline($FA);
  g_E7BF := UseRetrace;
  if UseRetrace <> 0 then
  begin
    g_E7B2 := Pointer(Ptr(0, $28)^);
    Pointer(Ptr(0, $28)^) := @U27D4_00E3;
    g_E7B6 := MemW[$40:$63];
    g_E7B8 := $11;
    Port[g_E7B6] := g_E7B8;
    g_E7B9 := Port[g_E7B6 + 1];
    Port[$21] := Port[$21] and $FB;
    PortW[g_E7B6] := (g_E7B9 and $EF and $DF) * 256 + $11;
    PortW[g_E7B6] := (g_E7B9 and $DF or $10) * 256 + $11;
  end
  else
  begin
    g_E7B2 := Pointer(Ptr(0, $70)^);
    Pointer(Ptr(0, $70)^) := @U27D4_00E3;
  end;
  inline($FB);
end;

{ re-arm the vertical retrace interrupt }
{#U27D4_0346}
procedure U27D4_0346;
var
  Old: Word;
begin
  g_E7B6 := MemW[$40:$63];
  g_E7B8 := $11;
  Port[g_E7B6] := g_E7B8;
  Old := Port[g_E7B6 + 1];
  Port[$21] := Port[$21] and $FB;
  PortW[g_E7B6] := (g_E7B9 and $EF and $DF) * 256 + $11;
  PortW[g_E7B6] := (g_E7B9 and $DF or $10) * 256 + $11;
end;

{ remove the cycler }
{#U27D4_03A7}
procedure U27D4_03A7;
begin
  if g_E7AE = 0 then Exit;
  g_E7A6 := 0;
  g_E7A4 := 0;
  g_E7A0 := 0;
  g_E7A2 := 0;
  g_E7AC := 0;
  g_E7AF := 1;
  inline($FA);
  if g_E7BF <> 0 then
  begin
    PortW[g_E7B6] := g_E7B9 * 256 + $11;
    Pointer(Ptr(0, $28)^) := g_E7B2;
  end
  else
    Pointer(Ptr(0, $70)^) := g_E7B2;
  inline($FB);
  g_E7AE := 0;
end;

{ reverse the cycling direction }
{#U27D4_0428}
procedure U27D4_0428;
begin
  g_E7BE := Byte(not Boolean(g_E7BE));
  if g_E7BF <> 0 then
  begin
    if g_E7BE <> 0 then
      Pointer(Ptr(0, $28)^) := @U27D4_00E3
    else
      Pointer(Ptr(0, $28)^) := @U27D4_0195;
  end
  else
  begin
    if g_E7BE <> 0 then
      Pointer(Ptr(0, $70)^) := @U27D4_00E3
    else
      Pointer(Ptr(0, $70)^) := @U27D4_0195;
  end;
end;

{#U27D4_04B9}
begin
  g_E7BE := 1;
  g_E7AE := 0;
  g_E7BA := ExitProc;
  ExitProc := @U27D4_0000;
end.
