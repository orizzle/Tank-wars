{$A+,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U2918;

{ NOTE: this unit needs $A+ (the 9-byte ViewPortType locals in U2918_003D/0066
  sit at [bp-0Ch], i.e. word aligned). }

{ Misc. helpers: PIC mask save/restore, viewport helpers, software Real
  maths (this unit is compiled $N-), key/mouse waiting, string helpers,
  graphics driver/font registration and a CPU type detection. }

interface




uses
  Graph, Crt, Dos, Printer, U2968;

var
  { DS E7E2-E81F }
  g_E7E2: Integer;      { font id EURO }
  g_E7E4: Integer;      { font id LCOM }
  g_E7E6: Integer;      { font id SCRI }
  g_E7E8: Integer;      { font id SIMP }
  g_E7EA: Integer;      { font id TSCR }
  g_E7EC: Integer;      { font id TINY }
  g_E7EE: Integer;      { driver id vga256 }
  g_E7F0: array[0..40] of Byte;
  g_E819: Byte;         { saved PIC1 mask }
  g_E81A: Byte;         { saved port 81h }
  g_E81B: Byte;
  g_E81C: Pointer;      { saved ExitProc }

procedure U2918_0000;
procedure U2918_000F;
procedure U2918_001E;
function  U2918_003D: Integer;
function  U2918_0066: Integer;
function  U2918_008F(A, B: Real): Real;
function  U2918_00D9(R: Real): Real;
function  U2918_011B(R: Real): Real;
function  U2918_015D: Integer;
function  U2918_016F: Char;
procedure U2918_01A1;
function  U2918_022A: Integer;
function  U2918_0256: Integer;
procedure U2918_0286;
function  U2918_02FE(L: LongInt): string;
function  U2918_0337(S: string): string;
procedure U2918_03A9;
function  U2918_04A3: Integer;

implementation

{ save interrupt masks }
{#U2918_0000}
procedure U2918_0000;
begin
  g_E819 := Port[$21];
  g_E81A := Port[$81];
end;

{ restore interrupt masks }
{#U2918_000F}
procedure U2918_000F;
begin
  Port[$21] := g_E819;
  Port[$81] := g_E81A;
end;

{ full screen viewport }
{#U2918_001E}
procedure U2918_001E;
begin
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
end;

{ horizontal centre of the viewport (viewport relative) }
{#U2918_003D}
function U2918_003D: Integer;
var
  VP: ViewPortType;
begin
  GetViewSettings(VP);
  U2918_003D := (VP.x1 + VP.x2) div 2 - VP.x1;
end;

{ vertical centre of the viewport (viewport relative) }
{#U2918_0066}
function U2918_0066: Integer;
var
  VP: ViewPortType;
begin
  GetViewSettings(VP);
  U2918_0066 := (VP.y1 + VP.y2) div 2 - VP.y1;
end;

{ length of vector (A, B) }
{#U2918_008F}
function U2918_008F(A, B: Real): Real;
begin
  U2918_008F := Sqrt(Sqr(A) + Sqr(B));
end;

{ degrees -> radians }
{#U2918_00D9}
function U2918_00D9(R: Real): Real;
begin
  U2918_00D9 := R / 180 * Pi;
end;

{ radians -> degrees }
{#U2918_011B}
function U2918_011B(R: Real): Real;
begin
  U2918_011B := R / Pi * 180;
end;

{ detect function for InstallUserDriver }
{#U2918_015D}
function U2918_015D: Integer;
begin
  U2918_015D := 1;
end;

{ wait for a key; Esc quits }
{#U2918_016F}
function U2918_016F: Char;
var
  C: Char;
begin
  repeat until KeyPressed;
  C := ReadKey;
  if C = #27 then Halt(10);
  U2918_016F := C;
end;

{ wait for a key or mouse button; Esc / right button quits }
{#U2918_01A1}
procedure U2918_01A1;
var
  C: Char;
begin
  C := #0;
  if g_E820 = 0 then
  begin
    repeat until KeyPressed;
    C := ReadKey;
    if C = #27 then Halt(10);
  end
  else
  begin
    repeat until KeyPressed or U2968_0077(1) or U2968_0077(2);
    if U2968_0077(2) then C := #27;
    if KeyPressed then C := ReadKey;
    if C = #27 then Halt(10);
  end;
end;

{ mouse x scaled to 320 }
{#U2918_022A}
function U2918_022A: Integer;
begin
  U2918_022A := Trunc(Integer(U2968_0067) / 2);
end;

{ mouse y }
{#U2918_0256}
function U2918_0256: Integer;
begin
  U2918_0256 := U2968_006F;
end;

{ abort on graphics error }
{#U2918_0286}
procedure U2918_0286;
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

{ LongInt -> string }
{#U2918_02FE}
function U2918_02FE(L: LongInt): string;
var
  S: string;
begin
  Str(L, S);
  U2918_02FE := S;
end;

{ upper-case a string }
{#U2918_0337}
function U2918_0337(S: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    S[I] := UpCase(S[I]);
  U2918_0337 := S;
end;

{ exit procedure }
{#U2918_03A9}
procedure U2918_03A9;
begin
  ExitProc := g_E81C;
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
function U2918_04A3: Integer; external; {$L CPUID.OBJ}

{#U2918_03E1}
begin
  g_E7EE := 0;
  g_E7EE := InstallUserDriver('vga256', @U2918_015D);
  U2918_0286;
  g_E7E2 := 0;
  g_E7E2 := InstallUserFont('EURO');
  U2918_0286;
  g_E7E4 := 0;
  g_E7E4 := InstallUserFont('LCOM');
  U2918_0286;
  g_E7E6 := 0;
  g_E7E6 := InstallUserFont('SCRI');
  U2918_0286;
  g_E7E8 := 0;
  g_E7E8 := InstallUserFont('SIMP');
  U2918_0286;
  g_E7EA := 0;
  g_E7EA := InstallUserFont('TSCR');
  U2918_0286;
  g_E7EC := 0;
  g_E7EC := InstallUserFont('TINY');
  U2918_0286;
  g_E81C := ExitProc;
  ExitProc := @U2918_03A9;
end.
