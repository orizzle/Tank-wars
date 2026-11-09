{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U0098;

{ Misc. game helpers: hot-key enable flag, background colour randomizer,
  debug trace, 3-D panel, direct VGA pixel helpers (crosshair, tank,
  falling dirt), turret drawing, and the hot-key screens (mass kill, quit,
  game status, control list).  The unit's code segment also carries the
  linked VGA256 BGI driver and the LITT/EURO/TINY fonts. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure U0098_0000;
procedure U0098_0006;
procedure U0098_0010;
procedure U0098_01BD;
procedure U0098_0226(S: string);
procedure U0098_028C(X1, Y1, X2, Y2: Integer; Fill, Light, Dark: Word);
procedure U0098_03A8(X, Y: Integer);
procedure U0098_03F4(X, Y: Integer; Buf: Pointer);
procedure U0098_0455(Src, Dst: Pointer; Color: Byte);
procedure U0098_047B(List, Buf: Pointer);
procedure U0098_0552(X, Y: Integer; Color: Byte; Buf: Pointer);
procedure U0098_0579(Lo, Hi: Byte; Buf: Pointer);
procedure U0098_05A9(Color: Byte; Buf: Pointer);
procedure U0098_05D2(X, Y: Integer; Color: Byte);
procedure U0098_066A(X, Y: Integer; Buf: Pointer);
procedure U0098_07A3(P: Integer);
procedure U0098_08C2(P: Integer);
function  U0098_09B2: Boolean;
procedure U0098_09ED;
procedure U0098_0A58;
procedure U0098_0C03;
procedure U0098_0C63;
procedure U0098_0ED2;
procedure U0098_18B2;
procedure VGA256Driver;
procedure LittFont;
procedure EuroFont;
procedure TinyFont;

implementation




uses
  U0728, U0E9B, U1615, U1B27, U1DD4, U1F69,
  U20C6, U22B7, U2390;

type
  TSetRGB = procedure(Index, R, G, B: Integer);

var
  { U2823's "set one DAC register" hook }
  SetRGB: TSetRGB absolute g_E7C8;
  Screen: TScreen absolute $A000:0;
  KbdFlags: Byte absolute $40:$17;

{ disable the hot-key handler (U2390_021B) }
{#U0098_0000}
procedure U0098_0000; assembler;
asm
  mov g_4644, 0
end;

{ enable the hot-key handler }
{#U0098_0006}
procedure U0098_0006; assembler;
asm
  mov g_4644, 1
end;

{ Ctrl-R: pick 3 random colours and fade between them in the 30 cycling
  background colours (DAC 30..59) }
{#U0098_0010}
procedure U0098_0010;
var
  C: array[0..2, 0..2] of Integer;
  I, J, K: Integer;
  RGB: array[0..2] of Integer;
begin
  for I := 0 to 2 do
    for J := 0 to 2 do
      C[I, J] := Random(64);
  for I := 0 to 2 do
    for J := 0 to 9 do
    begin
      for K := 0 to 2 do
        RGB[K] := Trunc((C[(I + 1) mod 3, K] - C[I, K]) / 10 * J + C[I, K]);
      Pal_DE80[10 * I + 1 + J].R := RGB[0];
      Pal_DE80[10 * I + 31 + J].R := RGB[0];
      Pal_DE80[10 * I + 1 + J].G := RGB[1];
      Pal_DE80[10 * I + 31 + J].G := RGB[1];
      Pal_DE80[10 * I + 1 + J].B := RGB[2];
      Pal_DE80[10 * I + 31 + J].B := RGB[2];
      SetRGB(10 * I + 30 + J, RGB[0], RGB[1], RGB[2]);
    end;
end;

{ set the three panel grey levels (17..19) and init the line style }
{#U0098_01BD}
procedure U0098_01BD;
begin
  SetRGB(17, 21, 21, 21);
  SetRGB(18, 42, 42, 42);
  SetRGB(19, 63, 63, 63);
  U2823_0006;
  g_E7D6 := $A000;
end;

{ debug trace: print S and wait for a key }
{#U0098_0226}
procedure U0098_0226(S: string);
var
  SaveDV: Boolean;
  Unused: Byte;                { unused; keeps the frame layout }
begin
  SaveDV := DirectVideo;
  DirectVideo := False;
  Writeln(S + ' - Press any key to continue');
  DirectVideo := SaveDV;
  U2918_016F;
end;

{ 3-D panel: filled bar with a 2-pixel bevel }
{#U0098_028C}
procedure U0098_028C(X1, Y1, X2, Y2: Integer; Fill, Light, Dark: Word);
begin
  SetFillStyle(SolidFill, Fill);
  Bar(X1, Y1, X2, Y2);
  U2823_09E4(X2 + 1, Y1 - 1, X2 + 1, Y2 + 1, Dark);
  U2823_09E4(X2 + 2, Y1 - 2, X2 + 2, Y2 + 2, Dark);
  U2823_09E4(X1 - 1, Y2 + 1, X2 + 1, Y2 + 1, Dark);
  U2823_09E4(X1 - 2, Y2 + 2, X2 + 2, Y2 + 2, Dark);
  U2823_09E4(X1 - 1, Y1 - 1, X1 - 1, Y2 + 1, Light);
  U2823_09E4(X1 - 2, Y1 - 2, X1 - 2, Y2 + 2, Light);
  U2823_09E4(X1 - 1, Y1 - 1, X2 + 1, Y1 - 1, Light);
  U2823_09E4(X1 - 2, Y1 - 2, X2 + 2, Y1 - 2, Light);
end;

{ draw a small '+' (colour 19) directly into VGA memory }
{#U0098_03A8}
procedure U0098_03A8(X, Y: Integer);
begin
  if (X <= 0) or (X >= 320) or (Y <= 0) or (Y >= 199) then Exit;
  asm
    push ds
    mov ax, Y
    mov bx, 320
    mul bx
    mov bx, X
    add bx, ax
    mov ax, 0A000h
    mov ds, ax
    mov byte ptr [bx], 13h
    mov byte ptr [bx+320], 13h
    mov byte ptr [bx-320], 13h
    mov byte ptr [bx+1], 13h
    mov byte ptr [bx-1], 13h
    pop ds
  end;
end;

{ erase the '+' again by copying the pixels from Buf (segment only) }
{#U0098_03F4}
procedure U0098_03F4(X, Y: Integer; Buf: Pointer);
begin
  if (X <= 0) or (X >= 320) or (Y <= 0) or (Y >= 199) then Exit;
  asm
    push ds
    mov ax, Y
    mov bx, 320
    mul bx
    mov bx, X
    add bx, ax
    mov ax, 0A000h
    mov ds, ax
    mov ax, word ptr Buf+2
    mov es, ax
    mov cl, es:[bx]
    mov [bx], cl
    mov cl, es:[bx+320]
    mov [bx+320], cl
    mov cl, es:[bx-320]
    mov [bx-320], cl
    mov cl, es:[bx+1]
    mov [bx+1], cl
    mov cl, es:[bx-1]
    mov [bx-1], cl
    pop ds
  end;
end;

{ copy every pixel of colour Color from Src to Dst (64000-byte screens,
  segments only) }
{#U0098_0455}
procedure U0098_0455(Src, Dst: Pointer; Color: Byte); assembler;
asm
  push ds
  mov dl, Color
  mov ax, word ptr Dst+2
  mov es, ax
  mov ax, word ptr Src+2
  mov ds, ax
  mov cx, 64000
@1:
  mov bx, cx
  mov al, [bx]
  cmp al, dl
  jne @2
  mov es:[bx], al
@2:
  loop @1
  pop ds
end;

{ let the dirt fall: List^ is a work list of screen offsets (terminated by
  $FFFF), Buf the background image (segment only); colour 2 = dirt }
{#U0098_047B}
procedure U0098_047B(List, Buf: Pointer); assembler;
asm
  push ds
  push si
  push di
  cld
  les di, List
  mov cx, 10
  mov ax, 0
  rep stosw
  mov ax, 0A000h
  mov es, ax
  mov di, 64000
  mov cx, 64000
  std
  lds si, List
@1:
  mov ax, 2
  repne scasb
  cmp di, 0
  je @3
  cmp byte ptr es:[di+321], 0
  je @2
  cmp byte ptr es:[di+321], 30
  jb @1
  cmp byte ptr es:[di+321], 99
  ja @1
@2:
  inc di
  mov [si], di
  mov ax, 320
  add [si], ax
  inc si
  inc si
  push ds
  push si
  lds si, Buf
  mov al, 2
  mov es:[di+320], al
  mov al, [di]
  mov es:[di], al
  pop si
  pop ds
  dec di
  jmp @1
@3:
  mov word ptr [si], 0FFFFh
  mov cx, si
  lds si, List
  mov bx, si
@4:
  cld
  push es
  push ds
  pop es
  push cx
  mov cx, 0FFFFh
  mov di, bx
  mov ax, 0
  repe scasw
  pop cx
  pop es
  dec di
  dec di
  cmp word ptr [di], 0FFFFh
  je @9
  mov bx, di
  mov si, bx
  dec si
  dec si
@5:
  inc si
  inc si
  cmp word ptr [si], 0FFFFh
  je @4
  mov di, [si]
  cmp di, 0
  je @5
  mov al, es:[di+320]
  cmp al, 0
  je @7
  cmp al, 30
  jb @6
  cmp al, 99
  ja @6
  jmp @7
@6:
  mov word ptr [si], 0
  jmp @5
@7:
  mov al, 2
  mov es:[di+320], al
  push ds
  mov ax, word ptr Buf+2
  mov ds, ax
  mov al, [di]
  pop ds
  mov es:[di], al
  add di, 320
  mov [si], di
  jmp @5
@9:
  pop di
  pop si
  pop ds
end;

{ plot a pixel both on the screen and into Buf (segment only) }
{#U0098_0552}
procedure U0098_0552(X, Y: Integer; Color: Byte; Buf: Pointer); assembler;
asm
  push ds
  mov ax, Y
  mov bx, 320
  mul bx
  mov bx, X
  add bx, ax
  mov dl, Color
  mov ax, 0A000h
  mov ds, ax
  mov [bx], dl
  mov ax, word ptr Buf+2
  mov ds, ax
  mov [bx], dl
  pop ds
end;

{ restore every screen pixel with a colour in Lo..Hi from Buf }
{#U0098_0579}
procedure U0098_0579(Lo, Hi: Byte; Buf: Pointer); assembler;
asm
  push ds
  mov dh, Hi
  mov dl, Lo
  mov ax, 0A000h
  mov es, ax
  mov ax, word ptr Buf+2
  mov ds, ax
  mov cx, 64000
@1:
  mov bx, cx
  mov al, es:[bx]
  cmp al, dl
  jb @2
  cmp al, dh
  ja @2
  mov al, [bx]
  mov es:[bx], al
@2:
  loop @1
  pop ds
end;

{ restore every screen pixel of colour Color from Buf }
{#U0098_05A9}
procedure U0098_05A9(Color: Byte; Buf: Pointer); assembler;
asm
  push ds
  mov dl, Color
  mov ax, 0A000h
  mov es, ax
  mov ax, word ptr Buf+2
  mov ds, ax
  mov cx, 64000
@1:
  mov bx, cx
  mov al, es:[bx]
  cmp al, dl
  jne @2
  mov al, [bx]
  mov es:[bx], al
@2:
  loop @1
  pop ds
end;

{ draw the tank body (a small dome) at X,Y in colour Color }
{#U0098_05D2}
procedure U0098_05D2(X, Y: Integer; Color: Byte); assembler;
asm
  push ds
  mov ax, Y
  mov bx, 320
  mul bx
  mov bx, X
  add bx, ax
  mov dl, Color
  mov ax, 0A000h
  mov ds, ax
  mov [bx], dl
  mov [bx+1], dl
  mov [bx+2], dl
  mov [bx+3], dl
  mov [bx+4], dl
  mov [bx-1], dl
  mov [bx-2], dl
  mov [bx-3], dl
  mov [bx-4], dl
  mov [bx-320], dl
  mov [bx-322], dl
  mov [bx-323], dl
  mov [bx-324], dl
  mov [bx-318], dl
  mov [bx-317], dl
  mov [bx-316], dl
  mov [bx-640], dl
  mov [bx-641], dl
  mov [bx-642], dl
  mov [bx-643], dl
  mov [bx-639], dl
  mov [bx-638], dl
  mov [bx-637], dl
  mov [bx-960], dl
  mov [bx-961], dl
  mov [bx-962], dl
  mov [bx-963], dl
  mov [bx-959], dl
  mov [bx-958], dl
  mov [bx-957], dl
  mov [bx-1280], dl
  mov [bx-1281], dl
  mov [bx-1279], dl
  pop ds
end;

{ erase the tank body at X,Y by copying the same pixels from Buf }
{#U0098_066A}
procedure U0098_066A(X, Y: Integer; Buf: Pointer); assembler;
asm
  push ds
  mov ax, Y
  mov bx, 320
  mul bx
  mov bx, X
  add bx, ax
  mov ax, 0A000h
  mov ds, ax
  mov ax, word ptr Buf+2
  mov es, ax
  mov dl, es:[bx]
  mov [bx], dl
  mov dl, es:[bx+1]
  mov [bx+1], dl
  mov dl, es:[bx+2]
  mov [bx+2], dl
  mov dl, es:[bx+3]
  mov [bx+3], dl
  mov dl, es:[bx+4]
  mov [bx+4], dl
  mov dl, es:[bx-1]
  mov [bx-1], dl
  mov dl, es:[bx-2]
  mov [bx-2], dl
  mov dl, es:[bx-3]
  mov [bx-3], dl
  mov dl, es:[bx-4]
  mov [bx-4], dl
  mov dl, es:[bx-320]
  mov [bx-320], dl
  mov dl, es:[bx-322]
  mov [bx-322], dl
  mov dl, es:[bx-323]
  mov [bx-323], dl
  mov dl, es:[bx-324]
  mov [bx-324], dl
  mov dl, es:[bx-318]
  mov [bx-318], dl
  mov dl, es:[bx-317]
  mov [bx-317], dl
  mov dl, es:[bx-316]
  mov [bx-316], dl
  mov dl, es:[bx-640]
  mov [bx-640], dl
  mov dl, es:[bx-641]
  mov [bx-641], dl
  mov dl, es:[bx-642]
  mov [bx-642], dl
  mov dl, es:[bx-643]
  mov [bx-643], dl
  mov dl, es:[bx-639]
  mov [bx-639], dl
  mov dl, es:[bx-638]
  mov [bx-638], dl
  mov dl, es:[bx-637]
  mov [bx-637], dl
  mov dl, es:[bx-960]
  mov [bx-960], dl
  mov dl, es:[bx-961]
  mov [bx-961], dl
  mov dl, es:[bx-962]
  mov [bx-962], dl
  mov dl, es:[bx-963]
  mov [bx-963], dl
  mov dl, es:[bx-959]
  mov [bx-959], dl
  mov dl, es:[bx-958]
  mov [bx-958], dl
  mov dl, es:[bx-957]
  mov [bx-957], dl
  mov dl, es:[bx-1280]
  mov [bx-1280], dl
  mov dl, es:[bx-1281]
  mov [bx-1281], dl
  mov dl, es:[bx-1279]
  mov [bx-1279], dl
  pop ds
end;

{ draw tank P (body + turret) if it is alive }
{#U0098_07A3}
procedure U0098_07A3(P: Integer);
var
  Color: Integer;
begin
  if Players_3F0E[P].f23 <> 0 then
  begin
    U26A9_014E(Players_3F0E[P]);
    Color := P + 19;
    U0098_05D2(Players_3F0E[P].X, Players_3F0E[P].Y, Color);
    U2823_09E4(Players_3F0E[P].X, Players_3F0E[P].Y,
      Players_3F0E[P].X + Trunc(Cos(U2918_00D9(Players_3F0E[P].f1D)) * 8) * Players_3F0E[P].f1F,
      Players_3F0E[P].Y - Trunc(Sin(U2918_00D9(Players_3F0E[P].f1D)) * 8),
      Color);
  end;
end;

{ erase tank P (body + turret) from the background buffer }
{#U0098_08C2}
procedure U0098_08C2(P: Integer);
begin
  U0098_066A(Players_3F0E[P].X, Players_3F0E[P].Y, BackBuf_E49A);
  U2823_0AC0(Players_3F0E[P].X, Players_3F0E[P].Y,
    Players_3F0E[P].X + Trunc(Cos(U2918_00D9(Players_3F0E[P].f1D)) * 8) * Players_3F0E[P].f1F,
    Players_3F0E[P].Y - Trunc(Sin(U2918_00D9(Players_3F0E[P].f1D)) * 8),
    BackBuf_E49A);
end;

{ both shift keys or both mouse buttons pressed? }
{#U0098_09B2}
function U0098_09B2: Boolean;
var
  B: Boolean;
  Dummy: Integer;              { unused; keeps the frame layout }
begin
  B := False;
  if KbdFlags and 3 = 3 then B := True;  { both shift keys }
  if U2968_0077(3) then B := True;
  U0098_09B2 := B;
end;

{ kill all tanks }
{#U0098_09ED}
procedure U0098_09ED;
var
  I: Integer;
begin
  for I := 1 to g_46B4 do
    Players_3F0E[I].f23 := 0;
end;

{ Ctrl-M: mass kill (with Y/N confirmation) }
{#U0098_0A58}
procedure U0098_0A58;
var
  Color: Word;
  TS: TextSettingsType;
  FS: FillSettingsType;
  Done: Boolean;
  VP: ViewPortType;
begin
  U2968_005A;
  NoSound;
  SaveBuf_E496^ := Screen;
  Color := GetColor;
  GetTextSettings(TS);
  GetFillSettings(FS);
  GetViewSettings(VP);
  SetViewPort(0, 0, 319, 199, True);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  SetFillStyle(SolidFill, 0);
  SetColor(13);
  Bar(85, 75, 235, 125);
  U2823_0031(85, 75, 235, 125, 13);
  U2823_0031(87, 77, 233, 123, 13);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY(160, 84, '! WARNING !');
  OutTextXY(160, 100, '! MASS KILL SELECTED !');
  OutTextXY(160, 116, 'ARE YOU SURE (Y/N)');
  Done := False;
  repeat
    if g_440A[$15] <> 0 then          { Y }
    begin
      Done := True;
      U0098_09ED;
    end;
    if g_440A[$31] <> 0 then Done := True;   { N }
  until Done;
  SetTextJustify(TS.Horiz, TS.Vert);
  SetFillStyle(FS.Color, FS.Pattern);    { sic }
  SetColor(Color);
  SetViewPort(VP.x1, VP.y1, VP.x2, VP.y2, VP.Clip);
  Screen := SaveBuf_E496^;
  U2968_004D;
end;

{ quit to DOS }
{#U0098_0C03}
procedure U0098_0C03;
begin
  CloseGraph;
  NoSound;
  U27B1_00E5;
  TextMode(CO80);
  Writeln('  Game Aborted......');
  Halt(1);
end;

{ Ctrl-Q: quit game (with Y/N confirmation) }
{#U0098_0C63}
procedure U0098_0C63;
var
  Color: Word;
  TS: TextSettingsType;
  FS: FillSettingsType;
  Done: Boolean;
  VP: ViewPortType;
begin
  U2968_005A;
  NoSound;
  SaveBuf_E496^ := Screen;
  Color := GetColor;
  GetTextSettings(TS);
  GetFillSettings(FS);
  GetViewSettings(VP);
  SetViewPort(0, 0, 319, 199, True);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  SetFillStyle(SolidFill, 0);
  SetColor(13);
  Bar(85, 88, 235, 112);
  U2823_0031(85, 88, 235, 112, 13);
  U2823_0031(87, 90, 233, 110, 13);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY(160, 96, 'ARE YOU SURE YOU');
  OutTextXY(160, 105, 'WISH TO QUIT (Y/N)');
  Done := False;
  repeat
    if g_440A[$15] <> 0 then          { Y }
    begin
      Done := True;
      U0098_0C03;
    end;
    if g_440A[$31] <> 0 then Done := True;   { N }
  until Done;
  SetTextJustify(TS.Horiz, TS.Vert);
  SetFillStyle(FS.Color, FS.Pattern);    { sic }
  SetColor(Color);
  SetViewPort(VP.x1, VP.y1, VP.x2, VP.y2, VP.Clip);
  Screen := SaveBuf_E496^;
  U2968_004D;
end;

{ Ctrl-P: game status / pause }
{#U0098_0ED2}
procedure U0098_0ED2;
var
  Color: Word;
  TS: TextSettingsType;
  FS: FillSettingsType;
  Done: Boolean;
  VP: ViewPortType;
  X, Y: Integer;               { Y unused }
begin
  U2968_005A;
  NoSound;
  SaveBuf_E496^ := Screen;
  Color := GetColor;
  GetTextSettings(TS);
  GetFillSettings(FS);
  GetViewSettings(VP);
  SetViewPort(0, 0, 319, 199, True);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  SetFillStyle(SolidFill, 0);
  SetColor(13);
  Bar(10, 25, 310, 175);
  U2823_0031(10, 25, 310, 175, 13);
  U2823_0031(12, 27, 308, 173, 13);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY(160, 35, 'Game Status');
  SetTextJustify(LeftText, CenterText);

  MoveTo(20, 45);
  SetColor(1);  OutText('Sound: ');
  SetColor(5);  OutText('Effect (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E788)));
  SetColor(5);  OutText(')   Fly (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E787)));
  SetColor(5);  OutText(')');

  MoveTo(20, 55);
  SetColor(1);  OutText('Ground: ');
  SetColor(5);  OutText('Crumbles (');
  SetColor(14); OutText(U2918_02FE(g_E77A) + '%');
  SetColor(5);  OutText(')');

  MoveTo(20, 65);
  SetColor(1);  OutText('The Walls: ');
  SetColor(5);  X := GetX;
  OutText('Rebound (');
  SetColor(14); OutText(U0728_0F3B(g_E780));
  SetColor(5);  OutText(')');
  MoveTo(X, 75);
  OutText('This Round (');
  SetColor(14); OutText(U0728_0F3B(g_46C6));
  SetColor(5);  OutText(')');

  MoveTo(20, 85);
  SetColor(1);  OutText('The Shot: ');
  SetColor(5);  X := GetX;
  OutText('Invisible (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E789)));
  SetColor(5);  OutText(')');
  MoveTo(X, 95);
  OutText('Trail (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E78A)));
  SetColor(5);  OutText(')');

  MoveTo(20, 105);
  SetColor(1);  OutText('Game: ');
  SetColor(5);  OutText('Number (');
  SetColor(14); OutText(U2918_02FE(g_46BC));
  SetColor(5);  OutText(') of (');
  SetColor(14); OutText(U2918_02FE(g_E77C));
  SetColor(5);  OutText(')');

  MoveTo(20, 115);
  SetColor(1);  OutText('Tanks: ');
  SetColor(5);  OutText('Fall (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E78D)));
  SetColor(5);  OutText(')');

  MoveTo(20, 135);
  SetColor(1);  OutText('Computers: ');
  SetColor(5);  OutText('Buy Weapons (');
  SetColor(14); OutText(U0728_0007(Boolean(g_E78F)));
  SetColor(5);  OutText(')');

  MoveTo(20, 145);
  SetColor(1);  OutText('Screen: ');
  SetColor(5);  OutText('Backgound (');
  SetColor(14); OutText(U0728_0DEF(g_E782));
  SetColor(5);  OutText(')');

  MoveTo(20, 155);
  SetColor(1);  OutText('The Wind: ');
  SetColor(5);  X := GetX;
  OutText('Control (');
  SetColor(14); OutText(U0728_0FFC(g_E77E));
  SetColor(5);  OutText(')');
  MoveTo(X, 165);
  OutText('This Round (');
  SetColor(14); OutText(U0728_0FFC(g_46BE));
  SetColor(5);  OutText(')');

  { wait for a key / button press, then for its release }
  Done := False;
  repeat
    if U2968_0077(1) or U2968_0077(2) then Done := True;
    if g_440A[$39] <> 0 then Done := True;   { Space }
    if g_440A[$1C] <> 0 then Done := True;   { Enter }
    if g_440A[$01] <> 0 then Done := True;   { Esc }
  until Done;
  repeat
    Done := False;
    if U2968_0077(1) or U2968_0077(2) then Done := True;
    if g_440A[$39] <> 0 then Done := True;
    if g_440A[$1C] <> 0 then Done := True;
    if g_440A[$01] <> 0 then Done := True;
  until not Done;

  SetTextJustify(TS.Horiz, TS.Vert);
  SetFillStyle(FS.Color, FS.Pattern);    { sic }
  SetColor(Color);
  SetViewPort(VP.x1, VP.y1, VP.x2, VP.y2, VP.Clip);
  Screen := SaveBuf_E496^;
  U2968_004D;
end;

{ F1: control list (help) }
{#U0098_18B2}
procedure U0098_18B2;
var
  Color: Word;
  TS: TextSettingsType;
  FS: FillSettingsType;
  Done: Boolean;
  VP: ViewPortType;
  X, Y, Z: Integer;            { X = indent of the "Any Time" list; Y, Z unused }
begin
  U27D4_001E;
  U2968_005A;
  NoSound;
  SaveBuf_E496^ := Screen;
  Color := GetColor;
  GetTextSettings(TS);
  GetFillSettings(FS);
  GetViewSettings(VP);
  SetViewPort(0, 0, 319, 199, True);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  SetFillStyle(SolidFill, 0);
  SetColor(13);
  Bar(1, 1, 319, 199);
  U2823_0031(1, 1, 319, 199, 13);
  U2823_0031(3, 3, 317, 197, 13);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY(160, 11, 'Control List');
  SetTextJustify(LeftText, CenterText);
  X := 32;

  if Control_E480[g_46C8] = 1 then
  begin
    MoveTo(11, 21);
    SetColor(1); OutText('Keyboard:');
    MoveTo(43, 31);
    SetColor(2); OutText('Fire:');
    SetColor(4); OutText('Space Bar');
    MoveTo(43, 41);
    SetColor(2); OutText('Increase Power:');
    SetColor(4); OutText('Cursor Up');
    MoveTo(43, 51);
    SetColor(2); OutText('Decrease Power:');
    SetColor(4); OutText('Cursor Down');
    MoveTo(43, 61);
    SetColor(2); OutText('Fast Increase Power:');
    SetColor(4); OutText('Page Up');
    MoveTo(43, 71);
    SetColor(2); OutText('Fast Decrease Power:');
    SetColor(4); OutText('Page Down');
    MoveTo(43, 81);
    SetColor(2); OutText('Turret Left:');
    SetColor(4); OutText('Cursor Left');
    MoveTo(43, 91);
    SetColor(2); OutText('Turret Right:');
    SetColor(4); OutText('Cursor Right');
    MoveTo(43, 101);
    SetColor(2); OutText('Change Weapon:');
    SetColor(4); OutText('Tab/Shift-Tab');
    MoveTo(43, 111);
    SetColor(2); OutText('Activate Guidace System:');
    SetColor(4); OutText('H or V');
    MoveTo(43, 121);
    SetColor(2); OutText('Player Status:');
    SetColor(4); OutText('Press player number');
  end;

  if Control_E480[g_46C8] = 2 then
  begin
    X := 8;
    MoveTo(11, 21);
    SetColor(1); OutText('Mouse:');
    MoveTo(19, 31);
    SetColor(2); OutText('Fire:');
    SetColor(4); OutText('Both Buttons');
    MoveTo(19, 41);
    SetColor(2); OutText('Increase Power:');
    SetColor(4); OutText('Right Button on Power #');
    MoveTo(19, 51);
    SetColor(2); OutText('Decrease Power:');
    SetColor(4); OutText('Left Button on Power #');
    MoveTo(19, 61);
    SetColor(2); OutText('Fast Inc Power:');
    SetColor(4); OutText('Right Button on POWER');
    MoveTo(19, 71);
    SetColor(2); OutText('Fast Dec Power:');
    SetColor(4); OutText('Left Button on POWER');
    MoveTo(19, 81);
    SetColor(2); OutText('Turret Left:');
    SetColor(4); OutText('Left Button on Angle #');
    MoveTo(19, 91);
    SetColor(2); OutText('Turret Right:');
    SetColor(4); OutText('Right Button on Angle #');
    MoveTo(19, 101);
    SetColor(2); OutText('Weapon:');
    SetColor(4); OutText('Left/Right Button on Bar');
    MoveTo(19, 111);
    SetColor(2); OutText('Guidance System:');
    SetColor(4); OutText('Click on H or V');
    MoveTo(19, 121);
    SetColor(2); OutText('Player Status:');
    SetColor(4); OutText('Click on Desired Tank');
  end;

  if Control_E480[g_46C8] = 3 then
  begin
    MoveTo(11, 21);
    SetColor(1); OutText('Computer:');
    MoveTo(43, 31);
    SetColor(2); OutText('You Have No Control');
  end;

  MoveTo(11, 131);
  SetColor(1); OutText('Any Time:');
  MoveTo(X + 11, 141);
  SetColor(2); OutText('BOSS Screen:');
  SetColor(4); OutText('F10');
  MoveTo(X + 11, 151);
  SetColor(2); OutText('Decrease Background Speed:');
  SetColor(4); OutText('F3');
  MoveTo(X + 11, 161);
  SetColor(2); OutText('Increase Background Speed:');
  SetColor(4); OutText('F4');
  MoveTo(X + 11, 171);
  SetColor(2); OutText('Quit Game:');
  SetColor(4); OutText('Ctrl-Q');
  MoveTo(X + 11, 181);
  SetColor(2); OutText('Game Status/Pause Game:');
  SetColor(4); OutText('Ctrl-P');
  MoveTo(X + 11, 191);
  SetColor(2); OutText('Randomize Background Colors:');
  SetColor(4); OutText('Ctrl-R');
  MoveTo(X + 11, 201);
  SetColor(2); OutText('Mass Kill:');
  SetColor(4); OutText('Ctrl-M');

  Done := False;
  repeat
    if U2968_0077(1) or U2968_0077(2) then Done := True;
    if g_440A[$39] <> 0 then Done := True;
    if g_440A[$1C] <> 0 then Done := True;
    if g_440A[$01] <> 0 then Done := True;
  until Done;
  repeat
    Done := False;
    if U2968_0077(1) or U2968_0077(2) then Done := True;
    if g_440A[$39] <> 0 then Done := True;
    if g_440A[$1C] <> 0 then Done := True;
    if g_440A[$01] <> 0 then Done := True;
  until not Done;

  SetTextJustify(TS.Horiz, TS.Vert);
  SetFillStyle(FS.Color, FS.Pattern);    { sic }
  SetColor(Color);
  SetViewPort(VP.x1, VP.y1, VP.x2, VP.y2, VP.Clip);
  Screen := SaveBuf_E496^;
  U2968_004D;
  U27D4_0027;
end;

procedure VGA256Driver; external; {$L VGA256.OBJ}
procedure LittFont; external; {$L LITT.OBJ}
procedure EuroFont; external; {$L EURO.OBJ}
procedure TinyFont; external; {$L TINY.OBJ}

end.
