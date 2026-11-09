{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2390;

{ Hot keys: the boss key (F10) and the keyboard hook that dispatches the
  game's hot keys (installed by the main program via U27B1_007D). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure U2390_0009;
procedure U2390_021B;

implementation




uses
  U0098, U0E9B;

type
  TDACBlock = procedure(Start, Count: Integer; Buf: Pointer);

var
  { U2823's "set a block of DAC registers" hook }
  SetDACBlock: TDACBlock absolute g_E7C4;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;

{ F10 boss key: save the VGA screen, palette and mouse state, show a fake
  DOS prompt until Space is pressed (Esc saves the game to BOSS and exits),
  then restore everything }
{#U2390_0009}
procedure U2390_0009;
var
  Regs: Registers;
  Pal: array[0..767] of Byte;
  SaveMode: Integer;
  MouseSize: LongInt;
  ScreenSize: LongInt;
  SaveHook: Pointer;
  MouseBuf: Pointer;
  ScreenBuf: Pointer;
  OldDir: string;
  CurDir: string;
begin
  SaveHook := U27B1_01C2;
  U27B1_01AE(nil);
  SaveMode := g_E7A6;
  U27D4_001E;
  MouseSize := U2968_00B1;
  GetMem(MouseBuf, MouseSize);
  U2968_00B9(MouseBuf);
  ScreenSize := MaxAvail - 128;
  if ScreenSize > 64000 then ScreenSize := 64000;
  GetMem(ScreenBuf, ScreenSize);
  U2968_005A;
  NoSound;
  U2823_0C20(0, 255, @Pal);
  asm
    push di
    push si
    mov cx, word ptr ScreenSize
    les di, ScreenBuf
    xor si, si
    push ds
    mov ax, 0A000h
    mov ds, ax
    rep movsb
    pop ds
    pop si
    pop di
  end;
  Regs.AX := 3;
  Intr($10, Regs);
  TextColor(LightGray);
  GotoXY(1, 2);
  GetDir(0, OldDir);
  ChDir('/');
  GetDir(0, CurDir);
  Write(CurDir + '>');
  repeat
    if g_440A[$01] <> 0 then        { Esc: save the game and quit }
    begin
      U0E9B_39EA('BOSS');
      Halt;
    end;
  until g_440A[$39] <> 0;          { Space }
  g_440A[$39] := 0;
  Regs.AX := $93;                  { mode 13h, keep video memory }
  Intr($10, Regs);
  asm
    push di
    push si
    push ds
    mov cx, word ptr ScreenSize
    lds si, ScreenBuf
    xor di, di
    mov ax, 0A000h
    mov es, ax
    rep movsb
    pop ds
    pop si
    pop di
  end;
  ChDir(OldDir);
  SetDACBlock(0, 255, @Pal);
  U2968_00C8(MouseBuf);
  FreeMem(ScreenBuf, ScreenSize);
  FreeMem(MouseBuf, MouseSize);
  U27D4_0346;
  g_E7A6 := SaveMode;
  KbdHead := KbdTail;              { flush the BIOS keyboard buffer }
  U27B1_01AE(SaveHook);
end;

{ keyboard hook: dispatch the hot keys (only while g_4644 is set) }
{#U2390_021B}
procedure U2390_021B; assembler;
asm
  cmp byte ptr g_440A[$44], 1      { F10: boss key }
  jne @1
  mov byte ptr g_440A[$44], 0
  mov al, g_4644
  push ax
  call U0098_0000
  call U2390_0009
  pop ax
  mov g_4644, al
  jmp @done
@1:
  cmp g_4644, 0
  jne @2
  jmp @exit
@2:
  call U0098_0000
  cmp byte ptr g_440A[$3B], 1      { F1: control list }
  jne @3
  mov byte ptr g_440A[$3B], 0
  call U0098_18B2
  jmp @done
@3:
  cmp byte ptr g_440A[$3D], 1      { F3: background speed down }
  jne @4
  cmp g_E796, 100
  jae @4
  inc g_E796
  mov ax, g_E796
  mov g_E7AF, al
  jmp @done
@4:
  cmp byte ptr g_440A[$3E], 1      { F4: background speed up }
  jne @5
  cmp g_E796, 0
  je @5
  dec g_E796
  mov ax, g_E796
  mov g_E7AF, al
  jmp @done
@5:
  cmp byte ptr g_440A[$1D], 1      { Ctrl }
  je @6
  cmp byte ptr g_440A[$11D], 1     { right Ctrl }
  je @6
  jmp @done
@6:
  cmp byte ptr g_440A[$1F], 1      { Ctrl-S: sound on/off }
  jne @8
  mov byte ptr g_440A[$1F], 0
  cmp g_E788, 0
  je @7
  mov g_E788, 0
  call NoSound
  jmp @done
@7:
  mov g_E788, 1
  jmp @done
@8:
  cmp byte ptr g_440A[$32], 1      { Ctrl-M: mass kill }
  jne @9
  mov byte ptr g_440A[$32], 0
  call U0098_0A58
  jmp @done
@9:
  cmp byte ptr g_440A[$10], 1      { Ctrl-Q: quit }
  jne @10
  mov byte ptr g_440A[$10], 0
  call U0098_0C63
  jmp @done
@10:
  cmp byte ptr g_440A[$19], 1      { Ctrl-P: game status }
  jne @11
  mov byte ptr g_440A[$19], 0
  call U0098_0ED2
  jmp @done
@11:
  cmp byte ptr g_440A[$13], 1      { Ctrl-R: random background colours }
  jne @done
  mov byte ptr g_440A[$13], 0
  call U0098_0010
  jmp @done
@done:
  call U0098_0006
@exit:
end;

{#U2390_031D}
begin
  g_4644 := 0;
end.
