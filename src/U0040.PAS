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

procedure ShowTitleScreen;

implementation




uses
  U0098, U0728, U0E9B, U1615, U1B27, U1DD4,
  U1F69, U20C6, U22B7, U2390;

{#U0040_0014}
procedure ShowTitleScreen;
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
  ReadDacBlock(0, 255, SavePal);

  { colour ramps for the palette cycling }
  FillChar(Red^, SizeOf(TCycle), 0);
  TmpScale := 6.3;
  for LoopI := 1 to 40 do
    Red^[LoopI].R := Trunc((LoopI mod 20) * TmpScale);
  FillChar(Blue^, SizeOf(TCycle), 0);
  TmpScale := 6.3;
  for LoopI := 1 to 40 do
    Blue^[LoopI].B := Trunc((LoopI mod 10) * TmpScale);
  FillChar(Green^, SizeOf(TCycle), 0);
  TmpScale := 6.3;
  for LoopI := 1 to 40 do
    Green^[LoopI].G := Trunc((LoopI mod 10) * TmpScale);

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
    LoopI := 0;
    LoopJ := 0;
    if Have2 then
      PalBlockHook(0, 255, @Back^.Pal);
    Screen := Back^.Pixels;
    PalBlockHook(0, 255, @Pic^.Pal);
    if AbortKeysDown then goto Abort;
    for LoopI := 135 to 154 do
    begin
      CopyColorPixels(@Pic^, @Screen, LoopI);
      if AbortKeysDown then goto Abort;
    end;
    for LoopI := 16 to 20 do
    begin
      CopyColorPixels(@Pic^, @Screen, LoopI);
      if AbortKeysDown then goto Abort;
    end;
    for LoopI := 115 to 124 do
    begin
      CopyColorPixels(@Pic^, @Screen, LoopI);
      if AbortKeysDown then goto Abort;
    end;
    for LoopI := 155 to 164 do
    begin
      CopyColorPixels(@Pic^, @Screen, LoopI);
      CopyColorPixels(@Pic^, @Screen, LoopI + 20);
      if AbortKeysDown then goto Abort;
    end;
    if AbortKeysDown then goto Abort;
    { flush the BIOS keyboard buffer }
    KbdHead := KbdTail;
    LoopI := 0;
    DoneFlag := 0;
    repeat
      Inc(LoopI);
      if LoopI = 21 then
        LoopI := 1;
      PalBlockHook(135, 20, @Red^[LoopI]);
      Delay(60);
      if KeyPressed then
        DoneFlag := 1;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
        DoneFlag := 1;
    until DoneFlag <> 0;
  Abort:
    KbdHead := KbdTail;
  end;
  PalBlockHook(0, 255, SavePal);
  FreeMem(SavePal, 768);
  FreeMem(Back, SizeOf(TRawPicture));
  FreeMem(Pic, SizeOf(TRawPicture));
  FreeMem(Red, SizeOf(TCycle));
  FreeMem(Blue, SizeOf(TCycle));
  FreeMem(Green, SizeOf(TCycle));
end;

end.
