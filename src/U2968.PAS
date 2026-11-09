{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2968;

{ Microsoft mouse driver interface (INT 33h). }

interface

uses
  Graph, Crt, Dos, Printer;

type
  TMouseCursor = record
    Mask: array[0..31] of Word;     { screen mask + cursor mask }
    HotX, HotY: Integer;
  end;

var
  { DS E820-E821 }
  g_E820: Byte;                     { mouse enabled }
  g_E821: Byte;

procedure U2968_0000(C: TMouseCursor);
procedure U2968_002E(B: Byte);
function  U2968_003B: Byte;
procedure U2968_0047;
procedure U2968_004D;
procedure U2968_005A;
function  U2968_0067: Word;
function  U2968_006F: Word;
function  U2968_0077(Buttons: Word): Boolean;
procedure U2968_009C(HotX, HotY: Integer; var Mask);
function  U2968_00B1: Word;
procedure U2968_00B9(Buf: Pointer);
procedure U2968_00C8(Buf: Pointer);
procedure U2968_00D7;

implementation

{ set graphics cursor shape }
{#U2968_0000}
procedure U2968_0000(C: TMouseCursor);
begin
  U2968_009C(C.HotX, C.HotY, C.Mask);
end;

{#U2968_002E}
procedure U2968_002E(B: Byte);
begin
  g_E820 := B;
end;

{ reset driver; returns 1 if a mouse is installed }
{#U2968_003B}
function U2968_003B: Byte; assembler;
asm
  mov ax, 0
  int 33h
  and ax, 1
  mov byte ptr [g_E820], al
end;

{#U2968_0047}
procedure U2968_0047; assembler;
asm
  mov ax, 0
  int 33h
end;

{ show cursor }
{#U2968_004D}
procedure U2968_004D; assembler;
asm
  cmp byte ptr [g_E820], 1
  jne @1
  mov ax, 1
  int 33h
@1:
end;

{ hide cursor }
{#U2968_005A}
procedure U2968_005A; assembler;
asm
  cmp byte ptr [g_E820], 1
  jne @1
  mov ax, 2
  int 33h
@1:
end;

{ mouse x }
{#U2968_0067}
function U2968_0067: Word; assembler;
asm
  mov ax, 3
  int 33h
  mov ax, cx
end;

{ mouse y }
{#U2968_006F}
function U2968_006F: Word; assembler;
asm
  mov ax, 3
  int 33h
  mov ax, dx
end;

{ are all of the given buttons pressed? }
{#U2968_0077}
function U2968_0077(Buttons: Word): Boolean; assembler;
asm
  cmp byte ptr [g_E820], 1
  mov ax, 0
  jne @1
  mov ax, 3
  int 33h
  mov dx, Buttons
  mov ax, 0
  and bx, dx
  cmp bx, dx
  jne @1
  mov ax, 1
@1:
end;

{#U2968_009C}
procedure U2968_009C(HotX, HotY: Integer; var Mask); assembler;
asm
  mov ax, 9
  les dx, Mask
  mov bx, HotX
  mov cx, HotY
  int 33h
end;

{ size of driver state buffer }
{#U2968_00B1}
function U2968_00B1: Word; assembler;
asm
  mov ax, 15h
  int 33h
  mov ax, bx
end;

{ save driver state }
{#U2968_00B9}
procedure U2968_00B9(Buf: Pointer); assembler;
asm
  mov ax, 16h
  les dx, Buf
  int 33h
end;

{ restore driver state }
{#U2968_00C8}
procedure U2968_00C8(Buf: Pointer); assembler;
asm
  mov ax, 17h
  les dx, Buf
  int 33h
end;

{ software reset }
{#U2968_00D7}
procedure U2968_00D7; assembler;
asm
  mov ax, 21h
  int 33h
end;

{#U2968_00DD}
begin
  g_E820 := 0;
end.
