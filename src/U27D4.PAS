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
    First: Word;        { +0  -> CycFirst }
    Field2: Word;       { +2  -> CycField2 }
    Count: Word;        { +4  -> CycCount }
    Mode: Integer;      { +6  -> CycMode (1 = cycling) }
    Pos: Word;          { +8  -> CycPos }
    Speed: Word;        { +A  -> CycSpeed (ticks per step) }
    Pal: Pointer;       { +C  -> CycPal (RGB triples) }
  end;

var
  { DS E7A0-E7BF }
  CycFirst: Word;         { DS:E7A0  first colour }
  CycField2: Word;  { DS:E7A2 }
  CycCount: Word;         { DS:E7A4  number of colours - 1 }
  CycMode: Integer;      { DS:E7A6  mode: 1 = cycling }
  CycPal: Pointer;      { DS:E7A8  palette data }
  CycPos: Word;         { DS:E7AC  current position }
  CycInstalled: Byte;         { DS:E7AE  installed }
  CycSpeed: Byte;         { DS:E7AF  speed }
  CycTicks: Byte;         { DS:E7B0  tick counter }
  UnusedE7B1: Byte;  { DS:E7B1 }
  CycOldVec: Pointer;      { DS:E7B2  old interrupt vector }
  CycCrtcPort: Word;         { DS:E7B6  CRTC index port }
  CycCrtcReg: Byte;         { DS:E7B8  CRTC register index ($11) }
  CycCrtcSaved: Byte;         { DS:E7B9  saved CRTC register $11 }
  CycOldExitProc: Pointer;      { DS:E7BA  saved ExitProc }
  CycForward: Byte;         { DS:E7BE  direction: 1 = forward }
  CycUseRetrace: Byte;         { DS:E7BF  use vertical retrace IRQ instead of timer }

procedure PalCycleExitProc;
procedure PauseCycling;
procedure ResumeCycling;
procedure SetPalCycle(P: TPalCycle);
procedure GetPalCycle(var P: TPalCycle);
procedure CycleIsrForward;
procedure CycleIsrBackward;
procedure InstallPalCycler(UseRetrace: Byte);
procedure RearmRetraceIrq;
procedure RemovePalCycler;
procedure ReverseCycling;

implementation

{ exit procedure }
{#U27D4_0000}
procedure PalCycleExitProc;
begin
  if CycInstalled <> 0 then RemovePalCycler;
  ExitProc := CycOldExitProc;
end;

{#U27D4_001E}
procedure PauseCycling;
begin
  Dec(CycMode);
end;

{#U27D4_0027}
procedure ResumeCycling;
begin
  Inc(CycMode);
  if CycMode > 1 then CycMode := 1;
end;

{ set cycler parameters }
{#U27D4_003D}
procedure SetPalCycle(P: TPalCycle);
begin
  CycFirst := P.First;
  CycField2 := P.Field2;
  CycCount := P.Count;
  CycPos := P.Pos;
  CycMode := P.Mode;
  CycPal := P.Pal;
  CycSpeed := P.Speed;
end;

{ get cycler parameters }
{#U27D4_008D}
procedure GetPalCycle(var P: TPalCycle);
begin
  P.First := CycFirst;
  P.Field2 := CycField2;
  P.Count := CycCount;
  P.Pos := CycPos;
  P.Mode := CycMode;
  P.Pal := CycPal;
  P.Speed := CycSpeed;
end;

{ interrupt handler, cycling forward }
{#U27D4_00E3}
procedure CycleIsrForward; assembler;
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
    cmp byte ptr [CycUseRetrace], 0
    je @timer
    mov dx, 3C2h
    in al, dx
    test al, 80h
    jne @retrace
    pushf
    call dword ptr [CycOldVec]
    jmp @exit
@retrace:
    mov dx, 3D4h
    in al, dx
    push ax
    mov al, byte ptr [CycCrtcReg]
    mov ah, byte ptr [CycCrtcSaved]
    and ah, 0EFh
    out dx, ax
    jmp @eoi
@timer:
    pushf
    call dword ptr [CycOldVec]
@eoi:
    mov al, 20h
    out 20h, al
    cmp word ptr [CycMode], 1
    jne @done
    inc byte ptr [CycTicks]
    mov al, byte ptr [CycTicks]
    cmp al, byte ptr [CycSpeed]
    jb @done
    mov byte ptr [CycTicks], 0
    mov ax, word ptr [CycCount]
    cmp word ptr [CycPos], ax
    jbe @1
    mov word ptr [CycPos], 0
@1:
    push word ptr [CycFirst]
    mov ax, word ptr [CycCount]
    inc ax
    push ax
    mov ax, word ptr [CycPal]
    add ax, word ptr [CycPos]
    add ax, word ptr [CycPos]
    add ax, word ptr [CycPos]
    push word ptr [CycPal+2]
    push ax
    call dword ptr [PalBlockNoWaitHook]
    inc word ptr [CycPos]
@done:
    cmp byte ptr [CycUseRetrace], 0
    je @exit
    mov dx, 3D4h
    mov al, byte ptr [CycCrtcReg]
    mov ah, byte ptr [CycCrtcSaved]
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
procedure CycleIsrBackward; assembler;
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
    cmp byte ptr [CycUseRetrace], 0
    je @timer
    mov dx, 3C2h
    in al, dx
    test al, 80h
    jne @retrace
    pushf
    call dword ptr [CycOldVec]
    jmp @exit
@retrace:
    mov dx, 3D4h
    in al, dx
    push ax
    mov al, byte ptr [CycCrtcReg]
    mov ah, byte ptr [CycCrtcSaved]
    and ah, 0EFh
    out dx, ax
    jmp @eoi
@timer:
    pushf
    call dword ptr [CycOldVec]
@eoi:
    mov al, 20h
    out 20h, al
    cmp word ptr [CycMode], 1
    jne @done
    inc byte ptr [CycTicks]
    mov al, byte ptr [CycTicks]
    cmp al, byte ptr [CycSpeed]
    jb @done
    mov byte ptr [CycTicks], 0
    mov ax, word ptr [CycCount]
    cmp word ptr [CycPos], ax
    jbe @1
    mov word ptr [CycPos], ax
@1:
    push word ptr [CycFirst]
    mov ax, word ptr [CycCount]
    inc ax
    push ax
    mov ax, word ptr [CycPal]
    add ax, word ptr [CycPos]
    add ax, word ptr [CycPos]
    add ax, word ptr [CycPos]
    push word ptr [CycPal+2]
    push ax
    call dword ptr [PalBlockNoWaitHook]
    dec word ptr [CycPos]
@done:
    cmp byte ptr [CycUseRetrace], 0
    je @exit
    mov dx, 3D4h
    mov al, byte ptr [CycCrtcReg]
    mov ah, byte ptr [CycCrtcSaved]
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
procedure InstallPalCycler(UseRetrace: Byte);
begin
  if CycInstalled <> 0 then Exit;
  CycInstalled := 1;
  CycMode := 0;
  CycCount := 0;
  CycFirst := 0;
  CycField2 := 0;
  CycPos := 0;
  CycSpeed := 1;
  inline($FA);
  CycUseRetrace := UseRetrace;
  if UseRetrace <> 0 then
  begin
    CycOldVec := Pointer(Ptr(0, $28)^);
    Pointer(Ptr(0, $28)^) := @CycleIsrForward;
    CycCrtcPort := MemW[$40:$63];
    CycCrtcReg := $11;
    Port[CycCrtcPort] := CycCrtcReg;
    CycCrtcSaved := Port[CycCrtcPort + 1];
    Port[$21] := Port[$21] and $FB;
    PortW[CycCrtcPort] := (CycCrtcSaved and $EF and $DF) * 256 + $11;
    PortW[CycCrtcPort] := (CycCrtcSaved and $DF or $10) * 256 + $11;
  end
  else
  begin
    CycOldVec := Pointer(Ptr(0, $70)^);
    Pointer(Ptr(0, $70)^) := @CycleIsrForward;
  end;
  inline($FB);
end;

{ re-arm the vertical retrace interrupt }
{#U27D4_0346}
procedure RearmRetraceIrq;
var
  Old: Word;
begin
  CycCrtcPort := MemW[$40:$63];
  CycCrtcReg := $11;
  Port[CycCrtcPort] := CycCrtcReg;
  Old := Port[CycCrtcPort + 1];
  Port[$21] := Port[$21] and $FB;
  PortW[CycCrtcPort] := (CycCrtcSaved and $EF and $DF) * 256 + $11;
  PortW[CycCrtcPort] := (CycCrtcSaved and $DF or $10) * 256 + $11;
end;

{ remove the cycler }
{#U27D4_03A7}
procedure RemovePalCycler;
begin
  if CycInstalled = 0 then Exit;
  CycMode := 0;
  CycCount := 0;
  CycFirst := 0;
  CycField2 := 0;
  CycPos := 0;
  CycSpeed := 1;
  inline($FA);
  if CycUseRetrace <> 0 then
  begin
    PortW[CycCrtcPort] := CycCrtcSaved * 256 + $11;
    Pointer(Ptr(0, $28)^) := CycOldVec;
  end
  else
    Pointer(Ptr(0, $70)^) := CycOldVec;
  inline($FB);
  CycInstalled := 0;
end;

{ reverse the cycling direction }
{#U27D4_0428}
procedure ReverseCycling;
begin
  CycForward := Byte(not Boolean(CycForward));
  if CycUseRetrace <> 0 then
  begin
    if CycForward <> 0 then
      Pointer(Ptr(0, $28)^) := @CycleIsrForward
    else
      Pointer(Ptr(0, $28)^) := @CycleIsrBackward;
  end
  else
  begin
    if CycForward <> 0 then
      Pointer(Ptr(0, $70)^) := @CycleIsrForward
    else
      Pointer(Ptr(0, $70)^) := @CycleIsrBackward;
  end;
end;

{#U27D4_04B9}
begin
  CycForward := 1;
  CycInstalled := 0;
  CycOldExitProc := ExitProc;
  ExitProc := @PalCycleExitProc;
end.
