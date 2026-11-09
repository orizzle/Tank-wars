{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U27B1;

{ Keyboard handler: own INT 9 handler that keeps a key-down table
  (g_440A[scancode], extended keys at +$100), optionally chains to the
  BIOS handler, and calls a per-key hook (g_4614). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1;

procedure U27B1_0000; interrupt;
procedure U27B1_007D(Chain: Boolean; Hook: Pointer);
procedure U27B1_00E5;
procedure U27B1_010C;
procedure U27B1_014E;
function  U27B1_0190: Boolean;
procedure U27B1_01AE(Hook: Pointer);
function  U27B1_01C2: Pointer;

implementation

{ INT 9 handler (entry is at 0000: the interrupt prologue pushes) }
{#U27B1_0000}
procedure U27B1_0000;
begin
  asm
    sti
    xor ax, ax
    in al, 60h
    cmp al, 0E0h
    jne @make
    mov word ptr [g_4612], 100h
    jmp @chain
  @make:
    test al, 80h
    jne @break
    mov bx, ax
    add bx, word ptr [g_4612]
    mov word ptr [g_4612], 0
    mov byte ptr [bx+offset g_440A], 1
    jmp @chain
  @break:
    and al, 7Fh
    mov bx, ax
    add bx, word ptr [g_4612]
    mov word ptr [g_4612], 0
    mov byte ptr [bx+offset g_440A], 0
  @chain:
    cmp byte ptr [g_4610], 1
    jne @eoi
    pushf
    call dword ptr [g_460C]
    jmp @done
  @eoi:
    cli
    mov al, 20h
    out 20h, al
  @done:
    sti
    cmp word ptr [g_4614], 0
    jne @hook
    cmp word ptr [g_4614+2], 0
    jne @hook
    jmp @end
  @hook:
    call dword ptr [g_4614]
  @end:
  end;
end;

{ install the keyboard handler }
{#U27B1_007D}
procedure U27B1_007D(Chain: Boolean; Hook: Pointer);
begin
  if g_460A <> 0 then Exit;
  FillChar(g_440A, $200, 0);
  GetIntVec(9, g_460C);
  g_4610 := Byte(Chain);
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  SetIntVec(9, @U27B1_0000);
  g_460A := 1;
  g_4614 := Hook;
end;

{ remove the keyboard handler }
{#U27B1_00E5}
procedure U27B1_00E5;
begin
  if g_460A = 0 then Exit;
  U27B1_014E;
  SetIntVec(9, g_460C);
  g_460A := 0;
end;

{ stop chaining to the BIOS; flush BIOS buffer, clear shift states }
{#U27B1_010C}
procedure U27B1_010C;
begin
  g_4610 := 0;
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  Mem[$40:$17] := Mem[$40:$17] and $F0;
  Mem[$40:$18] := 0;
end;

{ flush BIOS buffer, clear shift states, chain to the BIOS again }
{#U27B1_014E}
procedure U27B1_014E;
begin
  Word(Ptr($40, $1A)^) := Word(Ptr($40, $1C)^);
  Mem[$40:$17] := Mem[$40:$17] and $F0;
  Mem[$40:$18] := 0;
  g_4610 := 1;
end;

{ chaining to the BIOS? }
{#U27B1_0190}
function U27B1_0190: Boolean;
begin
  if g_4610 = 0 then
    U27B1_0190 := False
  else
    U27B1_0190 := True;
end;

{#U27B1_01AE}
procedure U27B1_01AE(Hook: Pointer);
begin
  g_4614 := Hook;
end;

{#U27B1_01C2}
function U27B1_01C2: Pointer;
begin
  U27B1_01C2 := g_4614;
end;

{#U27B1_01DF}
begin
  g_460A := 0;
  g_4614 := nil;
end.
