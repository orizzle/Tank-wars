{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U27B1;

{ Keyboard handler: own INT 9 handler that keeps a key-down table
  (KeyDown[scancode], extended keys at +$100), optionally chains to the
  BIOS handler, and calls a per-key hook (KbdHook). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1;

procedure KeyboardIsr; interrupt;
procedure InstallKeyboard(Chain: Boolean; Hook: Pointer);
procedure RemoveKeyboard;
procedure DisableBiosKeys;
procedure EnableBiosKeys;
function  BiosKeysEnabled: Boolean;
procedure SetKeyHook(Hook: Pointer);
function  GetKeyHook: Pointer;

implementation

{ INT 9 handler (entry is at 0000: the interrupt prologue pushes) }
{#U27B1_0000}
procedure KeyboardIsr;
begin
  asm
    sti
    xor ax, ax
    in al, 60h
    cmp al, 0E0h
    jne @make
    mov word ptr [KbdExtOffset], 100h
    jmp @chain
  @make:
    test al, 80h
    jne @break
    mov bx, ax
    add bx, word ptr [KbdExtOffset]
    mov word ptr [KbdExtOffset], 0
    mov byte ptr [bx+offset KeyDown], 1
    jmp @chain
  @break:
    and al, 7Fh
    mov bx, ax
    add bx, word ptr [KbdExtOffset]
    mov word ptr [KbdExtOffset], 0
    mov byte ptr [bx+offset KeyDown], 0
  @chain:
    cmp byte ptr [KbdChainBios], 1
    jne @eoi
    pushf
    call dword ptr [OldInt9]
    jmp @done
  @eoi:
    cli
    mov al, 20h
    out 20h, al
  @done:
    sti
    cmp word ptr [KbdHook], 0
    jne @hook
    cmp word ptr [KbdHook+2], 0
    jne @hook
    jmp @end
  @hook:
    call dword ptr [KbdHook]
  @end:
  end;
end;

{ install the keyboard handler }
{#U27B1_007D}
procedure InstallKeyboard(Chain: Boolean; Hook: Pointer);
begin
  if KbdInstalled <> 0 then Exit;
  FillChar(KeyDown, $200, 0);
  GetIntVec(9, OldInt9);
  KbdChainBios := Byte(Chain);
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  SetIntVec(9, @KeyboardIsr);
  KbdInstalled := 1;
  KbdHook := Hook;
end;

{ remove the keyboard handler }
{#U27B1_00E5}
procedure RemoveKeyboard;
begin
  if KbdInstalled = 0 then Exit;
  EnableBiosKeys;
  SetIntVec(9, OldInt9);
  KbdInstalled := 0;
end;

{ stop chaining to the BIOS; flush BIOS buffer, clear shift states }
{#U27B1_010C}
procedure DisableBiosKeys;
begin
  KbdChainBios := 0;
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  Mem[$40:$17] := Mem[$40:$17] and $F0;
  Mem[$40:$18] := 0;
end;

{ flush BIOS buffer, clear shift states, chain to the BIOS again }
{#U27B1_014E}
procedure EnableBiosKeys;
begin
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  Mem[$40:$17] := Mem[$40:$17] and $F0;
  Mem[$40:$18] := 0;
  KbdChainBios := 1;
end;

{ chaining to the BIOS? }
{#U27B1_0190}
function BiosKeysEnabled: Boolean;
begin
  if KbdChainBios = 0 then
    BiosKeysEnabled := False
  else
    BiosKeysEnabled := True;
end;

{#U27B1_01AE}
procedure SetKeyHook(Hook: Pointer);
begin
  KbdHook := Hook;
end;

{#U27B1_01C2}
function GetKeyHook: Pointer;
begin
  GetKeyHook := KbdHook;
end;

{#U27B1_01DF}
begin
  KbdInstalled := 0;
  KbdHook := nil;
end.
