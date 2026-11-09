{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U0040;

{ Title screen: shows BOMB2.RAW (optionally BOMB1.RAW as background, raw
  320x200x256 picture followed by its 768-byte palette), reveals it colour
  by colour, then cycles palette entries 135..154 until a key or mouse
  button is pressed. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

type
  TScreen = array[0..63999] of Byte;
  TRawPicture = record
    Pixels: TScreen;
    Pal: array[0..767] of Byte;
  end;
  PRawPicture = ^TRawPicture;
  TRGB = record
    R, G, B: Byte;
  end;
  TCycle = array[1..40] of TRGB;
  PCycle = ^TCycle;

var
  Screen: TScreen absolute $A000:0;
  KbdHead: Word absolute $40:$1A;   { BIOS keyboard buffer pointers }
  KbdTail: Word absolute $40:$1C;

procedure U0040_0014;

implementation




uses
  U0098, U0728, U0E9B, U1615, U1B27, U1DD4,
  U1F69, U20C6, U22B7, U2390;

{#U0040_0014}
procedure U0040_0014;
label
  Abort;
var
  Back, Pic: PRawPicture;
  F: file of TRawPicture;
  Red, Blue, Green: PCycle;
  Have1, Have2: Boolean;
  Unused: Byte;
  SR: SearchRec;
  SavePal: Pointer;
begin
  GetMem(Back, SizeOf(TRawPicture));
  GetMem(Pic, SizeOf(TRawPicture));
  GetMem(Red, SizeOf(TCycle));
  GetMem(Blue, SizeOf(TCycle));
  GetMem(Green, SizeOf(TCycle));
  GetMem(SavePal, 768);
  U2823_0C20(0, 255, SavePal);

  { colour ramps for the palette cycling }
  FillChar(Red^, SizeOf(TCycle), 0);
  g_469A := 6.3;
  for g_461E := 1 to 40 do
    Red^[g_461E].R := Trunc((g_461E mod 20) * g_469A);
  FillChar(Blue^, SizeOf(TCycle), 0);
  g_469A := 6.3;
  for g_461E := 1 to 40 do
    Blue^[g_461E].B := Trunc((g_461E mod 10) * g_469A);
  FillChar(Green^, SizeOf(TCycle), 0);
  g_469A := 6.3;
  for g_461E := 1 to 40 do
    Green^[g_461E].G := Trunc((g_461E mod 10) * g_469A);

  Have1 := False;
  Have2 := False;
  FindFirst('bomb1.raw', 0, SR);
  if DosError = 0 then
    Have1 := True;
  FindFirst('bomb2.raw', 0, SR);
  if DosError = 0 then
    Have2 := True;
  if Have1 then
  begin
    Assign(F, 'bomb1.raw');
    Reset(F);
    Read(F, Back^);
    Close(F);
  end
  else if Have2 then
    FillChar(Back^, SizeOf(TRawPicture), 0);
  if Have2 then
  begin
    Assign(F, 'bomb2.raw');
    Reset(F);
    Read(F, Pic^);
    Close(F);
  end;

  if Have2 then
  begin
    FillChar(Back^.Pal, 768, 0);
    g_461E := 0;
    g_4620 := 0;
    if Have2 then
      g_E7C4(0, 255, @Back^.Pal);
    Screen := Back^.Pixels;
    g_E7C4(0, 255, @Pic^.Pal);
    if U0098_09B2 then goto Abort;
    for g_461E := 135 to 154 do
    begin
      U0098_0455(@Pic^, @Screen, g_461E);
      if U0098_09B2 then goto Abort;
    end;
    for g_461E := 16 to 20 do
    begin
      U0098_0455(@Pic^, @Screen, g_461E);
      if U0098_09B2 then goto Abort;
    end;
    for g_461E := 115 to 124 do
    begin
      U0098_0455(@Pic^, @Screen, g_461E);
      if U0098_09B2 then goto Abort;
    end;
    for g_461E := 155 to 164 do
    begin
      U0098_0455(@Pic^, @Screen, g_461E);
      U0098_0455(@Pic^, @Screen, g_461E + 20);
      if U0098_09B2 then goto Abort;
    end;
    if U0098_09B2 then goto Abort;
    { flush the BIOS keyboard buffer }
    KbdHead := KbdTail;
    g_461E := 0;
    g_462F := 0;
    repeat
      Inc(g_461E);
      if g_461E = 21 then
        g_461E := 1;
      g_E7C4(135, 20, @Red^[g_461E]);
      Delay(60);
      if KeyPressed then
        g_462F := 1;
      if U2968_0077(1) or U2968_0077(2) then
        g_462F := 1;
    until g_462F <> 0;
  Abort:
    KbdHead := KbdTail;
  end;
  g_E7C4(0, 255, SavePal);
  FreeMem(SavePal, 768);
  FreeMem(Back, SizeOf(TRawPicture));
  FreeMem(Pic, SizeOf(TRawPicture));
  FreeMem(Red, SizeOf(TCycle));
  FreeMem(Blue, SizeOf(TCycle));
  FreeMem(Green, SizeOf(TCycle));
end;

end.
