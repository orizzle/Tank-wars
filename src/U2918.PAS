{$A+,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2918;

{ NOTE: this unit needs $A+ (the 9-byte ViewPortType locals in ViewCenterX/0066
  sit at [bp-0Ch], i.e. word aligned). }

{ Misc. helpers: PIC mask save/restore, viewport helpers, software Real
  maths (this unit is compiled $N-), key/mouse waiting, string helpers,
  graphics driver/font registration and a CPU type detection. }

interface




uses
  Graph, Crt, Dos, Printer, U2968;

var
  { DS E7E2-E81F }
  FontEuro: Integer;      { DS:E7E2  font id EURO }
  FontLcom: Integer;      { DS:E7E4  font id LCOM }
  FontScri: Integer;      { DS:E7E6  font id SCRI }
  FontSimp: Integer;      { DS:E7E8  font id SIMP }
  FontTscr: Integer;      { DS:E7EA  font id TSCR }
  FontTiny: Integer;      { DS:E7EC  font id TINY }
  DriverVga256: Integer;      { DS:E7EE  driver id vga256 }
  UnusedE7F0: array[0..40] of Byte;  { DS:E7F0 }
  SavedPicMask: Byte;         { DS:E819  saved PIC1 mask }
  SavedPort81: Byte;         { DS:E81A  saved port 81h }
  UnusedE81B: Byte;  { DS:E81B }
  MiscOldExitProc: Pointer;      { DS:E81C  saved ExitProc }

procedure SavePicMasks;
procedure RestorePicMasks;
procedure FullViewport;
function  ViewCenterX: Integer;
function  ViewCenterY: Integer;
function  VecLength(A, B: Real): Real;
function  DegToRad(R: Real): Real;
function  RadToDeg(R: Real): Real;
function  DetectVga256: Integer;
function  WaitKey: Char;
procedure WaitKeyOrMouse;
function  MouseX: Integer;
function  MouseY: Integer;
procedure CheckGraphError;
function  IntPower(A, B: Real): Integer;
function  IntToStr(L: LongInt): string;
function  UpperStr(S: string): string;
procedure MiscExitProc;
function  CpuType: Integer;

implementation

{ save interrupt masks }
{#U2918_0000}
procedure SavePicMasks;
begin
  SavedPicMask := Port[$21];
  SavedPort81 := Port[$81];
end;

{ restore interrupt masks }
{#U2918_000F}
procedure RestorePicMasks;
begin
  Port[$21] := SavedPicMask;
  Port[$81] := SavedPort81;
end;

{ full screen viewport }
{#U2918_001E}
procedure FullViewport;
begin
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
end;

{ horizontal centre of the viewport (viewport relative) }
{#U2918_003D}
function ViewCenterX: Integer;
var
  VP: ViewPortType;
begin
  GetViewSettings(VP);
  ViewCenterX := (VP.x1 + VP.x2) div 2 - VP.x1;
end;

{ vertical centre of the viewport (viewport relative) }
{#U2918_0066}
function ViewCenterY: Integer;
var
  VP: ViewPortType;
begin
  GetViewSettings(VP);
  ViewCenterY := (VP.y1 + VP.y2) div 2 - VP.y1;
end;

{ length of vector (A, B) }
{#U2918_008F}
function VecLength(A, B: Real): Real;
begin
  VecLength := Sqrt(Sqr(A) + Sqr(B));
end;

{ degrees -> radians }
{#U2918_00D9}
function DegToRad(R: Real): Real;
begin
  DegToRad := R / 180 * Pi;
end;

{ radians -> degrees }
{#U2918_011B}
function RadToDeg(R: Real): Real;
begin
  RadToDeg := R / Pi * 180;
end;

{ detect function for InstallUserDriver }
{#U2918_015D}
function DetectVga256: Integer;
begin
  DetectVga256 := 1;
end;

{ wait for a key; Esc quits }
{#U2918_016F}
function WaitKey: Char;
var
  C: Char;
begin
  repeat until KeyPressed;
  C := ReadKey;
  if C = #27 then Halt(10);
  WaitKey := C;
end;

{ wait for a key or mouse button; Esc / right button quits }
{#U2918_01A1}
procedure WaitKeyOrMouse;
var
  C: Char;
begin
  C := #0;
  if MouseEnabled = 0 then
  begin
    repeat until KeyPressed;
    C := ReadKey;
    if C = #27 then Halt(10);
  end
  else
  begin
    repeat until KeyPressed or MouseBtnsDown(1) or MouseBtnsDown(2);
    if MouseBtnsDown(2) then C := #27;
    if KeyPressed then C := ReadKey;
    if C = #27 then Halt(10);
  end;
end;

{ mouse x scaled to 320 }
{#U2918_022A}
function MouseX: Integer;
begin
  MouseX := Trunc(Integer(MouseRawX) / 2);
end;

{ mouse y }
{#U2918_0256}
function MouseY: Integer;
begin
  MouseY := MouseRawY;
end;

{ abort on graphics error }
{#U2918_0286}
procedure CheckGraphError;
var
  Err: Integer;
begin
  Err := GraphResult;
  if Err <> 0 then
  begin
    TextMode(CO80);
    Writeln('Graphics Error:');
    Writeln(GraphErrorMsg(Err));
    Writeln('Aborting..');
    Halt(1);
  end;
end;

{ A to the power of B (truncated).  Only BOMBCFG.EXE uses it (smart-linked
  out of BOMB.EXE), so its marker carries its offset in BOMBCFG.EXE. }
{#U2918_00A5}
function IntPower(A, B: Real): Integer;
begin
  IntPower := Trunc(Exp(Ln(A) * B));
end;

{ LongInt -> string }
{#U2918_02FE}
function IntToStr(L: LongInt): string;
var
  S: string;
begin
  Str(L, S);
  IntToStr := S;
end;

{ upper-case a string }
{#U2918_0337}
function UpperStr(S: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    S[I] := UpCase(S[I]);
  UpperStr := S;
end;

{ exit procedure }
{#U2918_03A9}
procedure MiscExitProc;
begin
  ExitProc := MiscOldExitProc;
end;

{ CPU type detection.  Returns $56 (8086), $BA (80186), $11E (80286),
  $182 (80386), negated when running in protected/V86 mode.
  In the original this routine follows the unit's initialization code,
  so it was an external .OBJ (assembled with MASM/TASM: 8B-form reg-reg
  moves, "jmp short + nop").  Its 80 bytes (no fixups) are linked from
  CPUID.BIN via BINOBJ.  Equivalent source:

    pushf; push cx; push bp
    mov ax,sp; push sp; pop cx; cmp ax,cx     ; 8086/186 push sp quirk
    je @286
    mov ax,0BAh; mov cl,20h; shl ax,cl        ; 186 masks shift count
    jne @exit
    mov ax,56h; jmp @exit
  @286:
    pushf; mov cx,sp; popf; inc cx; inc cx; cmp cx,ax
    jne @386
    sub sp,6; mov bp,sp; sgdt [bp]; add sp,4; pop ax
    inc ah; jne @386b                          ; 286 stores FFh in byte 5
    mov ax,11Eh; jmp short @prot; nop
  @386:  db 66h,0B8h,82h,01h,0EBh,03h          ; (mov eax,...) unreachable
  @386b: mov ax,182h
  @prot: smsw cx; ror cx,1; jae @exit; neg ax
  @exit: pop bp; pop cx; popf; retf
}
{#U2918_04A3}
function CpuType: Integer; external; {$L CPUID.OBJ}

{#U2918_03E1}
begin
  DriverVga256 := 0;
  DriverVga256 := InstallUserDriver('vga256', @DetectVga256);
  CheckGraphError;
  FontEuro := 0;
  FontEuro := InstallUserFont('EURO');
  CheckGraphError;
  FontLcom := 0;
  FontLcom := InstallUserFont('LCOM');
  CheckGraphError;
  FontScri := 0;
  FontScri := InstallUserFont('SCRI');
  CheckGraphError;
  FontSimp := 0;
  FontSimp := InstallUserFont('SIMP');
  CheckGraphError;
  FontTscr := 0;
  FontTscr := InstallUserFont('TSCR');
  CheckGraphError;
  FontTiny := 0;
  FontTiny := InstallUserFont('TINY');
  CheckGraphError;
  MiscOldExitProc := ExitProc;
  ExitProc := @MiscExitProc;
end.
