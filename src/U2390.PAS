{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2390;

{ Hot keys: the boss key (F10) and the keyboard hook that dispatches the
  game's hot keys (installed by the main program via InstallKeyboard). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure BossKey;
procedure HotKeyHook;

implementation




uses
  U0098, U0E9B;

type
  TDACBlock = procedure(Start, Count: Integer; Buf: Pointer);

var
  { U2823's "set a block of DAC registers" hook }
  SetDACBlock: TDACBlock absolute PalBlockHook;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;

{ F10 boss key: save the VGA screen, palette and mouse state, show a fake
  DOS prompt until Space is pressed (Esc saves the game to BOSS and exits),
  then restore everything }
{#U2390_0009}
procedure BossKey;
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
  SaveHook := GetKeyHook;
  SetKeyHook(nil);
  SaveMode := CycMode;
  PauseCycling;
  MouseSize := MouseStateSize;
  GetMem(MouseBuf, MouseSize);
  SaveMouseState(MouseBuf);
  ScreenSize := MaxAvail - 128;
  if ScreenSize > 64000 then ScreenSize := 64000;
  GetMem(ScreenBuf, ScreenSize);
  HideMouseCursor;
  NoSound;
  ReadDacBlock(0, 255, @Pal);
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
    if KeyDown[$01] <> 0 then        { Esc: save the game and quit }
    begin
      SaveGame('BOSS');
      Halt;
    end;
  until KeyDown[$39] <> 0;          { Space }
  KeyDown[$39] := 0;
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
  RestoreMouseState(MouseBuf);
  FreeMem(ScreenBuf, ScreenSize);
  FreeMem(MouseBuf, MouseSize);
  RearmRetraceIrq;
  CycMode := SaveMode;
  KbdHead := KbdTail;              { flush the BIOS keyboard buffer }
  SetKeyHook(SaveHook);
end;

{ keyboard hook: dispatch the hot keys (only while HotKeysOn is set) }
{#U2390_021B}
procedure HotKeyHook; assembler;
asm
  cmp byte ptr KeyDown[$44], 1      { F10: boss key }
  jne @1
  mov byte ptr KeyDown[$44], 0
  mov al, HotKeysOn
  push ax
  call DisableHotKeys
  call BossKey
  pop ax
  mov HotKeysOn, al
  jmp @done
@1:
  cmp HotKeysOn, 0
  jne @2
  jmp @exit
@2:
  call DisableHotKeys
  cmp byte ptr KeyDown[$3B], 1      { F1: control list }
  jne @3
  mov byte ptr KeyDown[$3B], 0
  call ShowControlList
  jmp @done
@3:
  cmp byte ptr KeyDown[$3D], 1      { F3: background speed down }
  jne @4
  cmp PalSpeed, 100
  jae @4
  inc PalSpeed
  mov ax, PalSpeed
  mov CycSpeed, al
  jmp @done
@4:
  cmp byte ptr KeyDown[$3E], 1      { F4: background speed up }
  jne @5
  cmp PalSpeed, 0
  je @5
  dec PalSpeed
  mov ax, PalSpeed
  mov CycSpeed, al
  jmp @done
@5:
  cmp byte ptr KeyDown[$1D], 1      { Ctrl }
  je @6
  cmp byte ptr KeyDown[$11D], 1     { right Ctrl }
  je @6
  jmp @done
@6:
  cmp byte ptr KeyDown[$1F], 1      { Ctrl-S: sound on/off }
  jne @8
  mov byte ptr KeyDown[$1F], 0
  cmp SoundOn, 0
  je @7
  mov SoundOn, 0
  call NoSound
  jmp @done
@7:
  mov SoundOn, 1
  jmp @done
@8:
  cmp byte ptr KeyDown[$32], 1      { Ctrl-M: mass kill }
  jne @9
  mov byte ptr KeyDown[$32], 0
  call MassKillDialog
  jmp @done
@9:
  cmp byte ptr KeyDown[$10], 1      { Ctrl-Q: quit }
  jne @10
  mov byte ptr KeyDown[$10], 0
  call QuitDialog
  jmp @done
@10:
  cmp byte ptr KeyDown[$19], 1      { Ctrl-P: game status }
  jne @11
  mov byte ptr KeyDown[$19], 0
  call ShowGameStatus
  jmp @done
@11:
  cmp byte ptr KeyDown[$13], 1      { Ctrl-R: random background colours }
  jne @done
  mov byte ptr KeyDown[$13], 0
  call RandomizeBackColors
  jmp @done
@done:
  call EnableHotKeys
@exit:
end;

{#U2390_031D}
begin
  HotKeysOn := 0;
end.
