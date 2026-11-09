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
  MouseEnabled: Byte;                     { DS:E820  mouse enabled }
  UnusedE821: Byte;  { DS:E821 }

procedure SetMouseCursor(C: TMouseCursor);
procedure SetMouseEnabled(B: Byte);
function  DetectMouse: Byte;
procedure ResetMouse;
procedure ShowMouseCursor;
procedure HideMouseCursor;
function  MouseRawX: Integer;
function  MouseRawY: Integer;
function  MouseBtnsDown(Buttons: Word): Boolean;
procedure SetMouseShape(HotX, HotY: Integer; var Mask);
function  MouseStateSize: Integer;
procedure SaveMouseState(Buf: Pointer);
procedure RestoreMouseState(Buf: Pointer);
procedure MouseSoftReset;

implementation

{ set graphics cursor shape }
{#U2968_0000}
procedure SetMouseCursor(C: TMouseCursor);
begin
  SetMouseShape(C.HotX, C.HotY, C.Mask);
end;

{#U2968_002E}
procedure SetMouseEnabled(B: Byte);
begin
  MouseEnabled := B;
end;

{ reset driver; returns 1 if a mouse is installed }
{#U2968_003B}
function DetectMouse: Byte; assembler;
asm
  mov ax, 0
  int 33h
  and ax, 1
  mov byte ptr [MouseEnabled], al
end;

{#U2968_0047}
procedure ResetMouse; assembler;
asm
  mov ax, 0
  int 33h
end;

{ show cursor }
{#U2968_004D}
procedure ShowMouseCursor; assembler;
asm
  cmp byte ptr [MouseEnabled], 1
  jne @1
  mov ax, 1
  int 33h
@1:
end;

{ hide cursor }
{#U2968_005A}
procedure HideMouseCursor; assembler;
asm
  cmp byte ptr [MouseEnabled], 1
  jne @1
  mov ax, 2
  int 33h
@1:
end;

{ mouse x }
{#U2968_0067}
function MouseRawX: Integer; assembler;
asm
  mov ax, 3
  int 33h
  mov ax, cx
end;

{ mouse y }
{#U2968_006F}
function MouseRawY: Integer; assembler;
asm
  mov ax, 3
  int 33h
  mov ax, dx
end;

{ are all of the given buttons pressed? }
{#U2968_0077}
function MouseBtnsDown(Buttons: Word): Boolean; assembler;
asm
  cmp byte ptr [MouseEnabled], 1
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
procedure SetMouseShape(HotX, HotY: Integer; var Mask); assembler;
asm
  mov ax, 9
  les dx, Mask
  mov bx, HotX
  mov cx, HotY
  int 33h
end;

{ size of driver state buffer }
{#U2968_00B1}
function MouseStateSize: Integer; assembler;
asm
  mov ax, 15h
  int 33h
  mov ax, bx
end;

{ save driver state }
{#U2968_00B9}
procedure SaveMouseState(Buf: Pointer); assembler;
asm
  mov ax, 16h
  les dx, Buf
  int 33h
end;

{ restore driver state }
{#U2968_00C8}
procedure RestoreMouseState(Buf: Pointer); assembler;
asm
  mov ax, 17h
  les dx, Buf
  int 33h
end;

{ software reset }
{#U2968_00D7}
procedure MouseSoftReset; assembler;
asm
  mov ax, 21h
  int 33h
end;

{#U2968_00DD}
begin
  MouseEnabled := 0;
end.
