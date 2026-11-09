{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U20C6;

{ New round: sky backgrounds, terrain generation, tank placement and the
  weapon/guidance icon bar.

  NOTE: procs calling Crt.Delay show 'diff' in cmp.py only because the
  original's CRT.Delay differs from the one in toolchain TURBO.TPL; with CRT
  fingerprints relaxed every proc here matches. }

interface

uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure DrawSky(Sky: Integer);
procedure SetupRound;
procedure DrawWeaponBar;

implementation

uses
  U22B7, U0098, U1F69;

{ Draw sky background number Sky into the back buffer and copy it to the
  playfield; also sets up the palette cycler for it. }
{#U20C6_0004}
procedure DrawSky(Sky: Integer);
var
  L: LongInt;
begin
  FillChar(BackBuf^, 64000, 0);
  VideoSeg := $A000;
  case Sky of
    1:
      begin
        { stars }
        TmpScale := 5;
        for LoopI := 0 to 9 do
        begin
          LoopK := Trunc(TmpScale * LoopI);
          RGBHook(LoopI + 30, LoopK, LoopK, LoopK);
          RGBHook(LoopI + 40, LoopK, LoopK, 0);
        end;
        for LoopI := 1 to Random(500) + 250 do
        begin
          TmpX := Random(299) + 11;
          TmpY := Random(159) + 31;
          LoopK := Random(20) + 30;
          PutPixel(TmpX, TmpY, LoopK);
        end;
        PalCycle.First := 30;
        PalCycle.Field2 := 49;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        ReadDacBlock(30, 20, @CyclePal);
        ReadDacBlock(30, 20, @CyclePal[21]);
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := (PalSpeed + 1) * 3;
      end;
    2:
      begin
        { horizontal stripes }
        RandomizeBackColors;
        for LoopI := 31 to 190 do
          DrawLine(11, LoopI, 310, LoopI, LoopI mod 30 + 30);
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    3:
      begin
        { concentric circles }
        RandomizeBackColors;
        SetViewPort(11, 31, 309, 189, True);
        FetchClipWindow;
        TmpX := ViewCenterX;
        TmpY := ViewCenterY;
        for LoopI := 0 to 170 do
        begin
          DrawEllipse(TmpX, TmpY, LoopI, LoopI, LoopI mod 30 + 30);
          DrawEllipse(TmpX + 1, TmpY, LoopI, LoopI, LoopI mod 30 + 30);
        end;
        FullViewport;
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    4:
      begin
        { rays from the centre }
        RandomizeBackColors;
        SetViewPort(11, 31, 309, 189, True);
        FetchClipWindow;
        TmpX := 160;
        TmpY := 100;
        L := 0;
        TmpN := 6;
        for LoopI := ClipView.x1 to ClipView.x2 do
        begin
          DrawLine(TmpX, TmpY, LoopI, ClipView.y1, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for LoopI := ClipView.y1 to ClipView.y2 do
        begin
          DrawLine(TmpX, TmpY, ClipView.x2, LoopI, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for LoopI := ClipView.x2 downto ClipView.x1 do
        begin
          DrawLine(TmpX, TmpY, LoopI, ClipView.y2, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for LoopI := ClipView.y2 downto ClipView.y1 do
        begin
          DrawLine(TmpX, TmpY, ClipView.x1, LoopI, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        FullViewport;
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    5:
      begin
        { static gradient }
        for LoopI := 0 to 19 do
          RGBHook(LoopI + 30, LoopI, 0, 63 - LoopI);
        for LoopI := 31 to 190 do
          DrawLine(11, LoopI, 310, LoopI, (LoopI - 30) div 8 + 30);
        PalCycle := NoPalCycle;
      end;
    6:
      begin
        { random noise }
        RandomizeBackColors;
        SetViewPort(11, 31, 309, 189, True);
        FetchClipWindow;
        for TmpX := ClipView.x1 to ClipView.x2 do
          for TmpY := ClipView.y1 to ClipView.y2 do
            PlotPixel(TmpX, TmpY, Random(30) + 30);
        FullViewport;
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    7:
      begin
        { nested rectangles }
        RandomizeBackColors;
        case Random(3) of
          0: TmpC := 80;
          1: TmpC := 150;
          2: TmpC := 159;
        end;
        for LoopI := 1 to TmpC do
          DrawRect(LoopI + 10, LoopI + 30, 310 - LoopI, 190 - LoopI,
            LoopI mod 30 + 30);
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    8:
      begin
        { tunnel }
        RandomizeBackColors;
        SetViewPort(11, 31, 309, 189, True);
        FetchClipWindow;
        for TmpX := 0 to 149 do
        begin
          DrawLine(160, 110, 160 - TmpX, 31, TmpX mod 30 + 30);
          DrawLine(160, 110, TmpX + 160, 31, TmpX mod 30 + 30);
          DrawLine(160, 110, 160 - TmpX, 189, TmpX mod 30 + 30);
          DrawLine(160, 110, TmpX + 160, 189, TmpX mod 30 + 30);
        end;
        for TmpY := 0 to 79 do
        begin
          DrawLine(160, 110, 11, 110 - TmpY, (TmpY + 70) mod 30 + 30);
          DrawLine(160, 110, 309, 110 - TmpY, (TmpY + 70) mod 30 + 30);
          DrawLine(160, 110, 11, TmpY + 110, (TmpY + 70) mod 30 + 30);
          DrawLine(160, 110, 309, TmpY + 110, (TmpY + 70) mod 30 + 30);
        end;
        FullViewport;
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
  end;
  VideoSeg := Seg(BackBuf^);
  for TmpX := 10 to 310 do
    CopyLine(TmpX, 30, TmpX, 190, Ptr($A000, 0));
  DrawRect(8, 28, 312, 192, 13);
  DrawRect(10, 30, 310, 190, 13);
  VideoSeg := $A000;
  if Random < 0.5 then ReverseCycling;
end;

{ Start a new round: wall type, sky, terrain, tanks. }
{#U20C6_099E}
procedure SetupRound;
var
  Dir, Slope, Margin: Integer;
  Falling, Landed, Fast: Boolean;
  Unused: Byte;
  P: Integer;
begin
  PalCycle := NoPalCycle;
  SetPalCycle(NoPalCycle);
  RoundWall := WallControl;
  if RoundWall = 5 then RoundWall := Random(5);
  if RoundWall in [1..3] then
    WallsBounce := 1
  else
    WallsBounce := 0;
  if RoundWall = 4 then
    WallsWrap := 1
  else
    WallsWrap := 0;
  SetAspectRatio(1, 1);
  RGBHook(19, 63, 63, 63);
  if InvisoBall <> 0 then RGBHook(19, 0, 0, 0);
  ClearDevice;
  if BackControl <= 8 then DrawSky(BackControl);
  if BackControl = 9 then DrawSky(Random(9));
  if BackControl = 10 then
  begin
    repeat
      LoopI := Random(9);
    until (1 shl LoopI) and BackMask > 0;
    DrawSky(LoopI);
  end;
  RGBHook(0, 14, 9, 10);
  SetColor(13);
  Rectangle(8, 28, 312, 192);
  Rectangle(10, 30, 310, 190);
  SetColor(6);
  SetTextStyle(SmallFont, VertDir, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(CenterText, CenterText);
  case RoundWall of
    1:
      begin
        OutTextXY(0, 100, 'STICKEY');
        WallBounce := 0.707106;
      end;
    2:
      begin
        OutTextXY(0, 100, 'ELASTIC');
        WallBounce := 1;
      end;
    3:
      begin
        OutTextXY(0, 100, 'ACCELERATE');
        WallBounce := 1.41421;
      end;
    4:
      OutTextXY(0, 100, 'WARP');
  end;
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetTextJustify(LeftText, TopText);
  SetColor(2);
  { terrain }
  TmpX := 11;
  Slope := 0;
  Dir := 1 - Trunc(Random(2) * 2);
  Margin := 60 - (NumPlayers - 2) * 7;
  LandHeight := Random(150);
  while TmpX < 310 do
  begin
    if Margin + 11 > TmpX then
      Line(TmpX, 190 - LandHeight, TmpX, 189)
    else if 309 - Margin < TmpX then
      Line(TmpX, 190 - LandHeight, TmpX, 189)
    else
    begin
      if Slope = 0 then
      begin
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
      end;
      if Abs(Slope) = 1 then
      begin
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
      end;
      if Abs(Slope) = 2 then
      begin
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
      end;
      if Abs(Slope) = 3 then
      begin
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        Inc(TmpX);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
      end;
      if Abs(Slope) = 4 then
      begin
        DrawLine(TmpX, 190 - LandHeight, TmpX, 189, 2);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
        if Slope > 0 then Inc(LandHeight) else Dec(LandHeight);
      end;
      if Random < 0.2 then Slope := Slope + Dir;
      if (Random < 0.1) or (Abs(Slope) > 4) then Dir := -Dir;
      if Slope > 4 then Slope := 4;
      if Slope < -4 then Slope := -4;
      if LandHeight <= 20 then Dir := 1;
      if LandHeight >= 140 then Dir := -1;
      if LandHeight <= 3 then Slope := 1;
      if LandHeight >= 155 then Slope := -1;
    end;
    Inc(TmpX);
  end;
  { place the tanks }
  Players[1].X := Random(28) + 16;
  Players[NumPlayers].X := 305 - Random(28);
  LoopJ := (Players[NumPlayers].X - Players[1].X) div (NumPlayers - 1);
  if NumPlayers > 2 then
    for P := 2 to NumPlayers - 1 do
      Players[P].X := (P - 1) * LoopJ + Players[1].X;
  Fast := Boolean(AllComputers);
  if AbortKeysDown then Fast := True;
  for P := 1 to NumPlayers do
  begin
    SetFillStyle(SolidFill, 0);
    Bar(109, 0, 211, 7);
    SetColor(P + 19);
    SetTextJustify(CenterText, TopText);
    OutTextXY(160, 0, Players[P].Name);
    if P in [1, NumPlayers] then
      Players[P].f1D := 75
    else
      Players[P].f1D := 90;
    Players[P].f1B := 200;
    if P = NumPlayers then
      Players[P].f1F := -1
    else
      Players[P].f1F := 1;
    SetPlayerMen(100, Players[P]);
    Players[P].f23 := 1;
    Players[P].Y := 32;
    Players[P].f5E := 0;
    UpdatePlayerColor(Players[P]);
    Falling := True;
    for LoopJ := -4 to 4 do
      if PixelAt(Players[P].X + LoopJ, Players[P].Y + 1) in [2, 13] then
        Falling := False;
    if Falling then
    begin
      Landed := False;
      repeat
        Landed := True;
        EraseTankBody(Players[P].X, Players[P].Y, BackBuf);
        Inc(Players[P].Y);
        DrawTankBody(Players[P].X, Players[P].Y, P + 19);
        if not Fast then Delay(FallSpeed);
        for LoopJ := -4 to 4 do
          if not (PixelAt(Players[P].X + LoopJ, Players[P].Y + 1) in [2, 13]) then
            Landed := False;
      until Landed;
      DrawTank(P);
      DrawPlayfieldFrame;
    end;
    if not Fast and AbortKeysDown then Fast := True;
  end;
  RoundOver := 0;
  SetPalCycle(PalCycle);
end;

{ Draw the weapon / guidance icon bar at the top of the screen and remember
  the button positions in BarButtonX. }
{#U20C6_1268}
procedure DrawWeaponBar;
var
  Base: Integer;
begin
  Base := 10;
  for LoopI := 0 to 19 do
  begin
    SetColor(LoopI + 100);
    SetFillStyle(SolidFill, LoopI + 100);
    RGBHook(LoopI + 100, 0, 0, 0);
    SetViewPort(15 * LoopI + Base, 18, Base + 15 + 15 * LoopI, 27, True);
    BarButtonX[LoopI] := 15 * LoopI + Base;
    BarButtonX[LoopI + 1] := (LoopI + 1) * 15 + Base;
    Rectangle(0, 0, 14, 10);
    case LoopI of
      0:
        PutPixel(7, 5, LoopI + 100);
      1:
        Circle(7, 5, 1);
      2:
        begin
          PutPixel(7, 5, LoopI + 100);
          Circle(7, 5, 1);
        end;
      3:
        begin
          Line(5, 4, 5, 6);
          Line(5, 5, 9, 5);
          Bar(7, 4, 8, 6);
        end;
      4:
        begin
          Line(4, 4, 4, 6);
          Line(4, 5, 10, 5);
          Bar(6, 4, 9, 6);
          Bar(7, 3, 8, 7);
        end;
      5:
        begin
          Line(2, 9, 5, 9);
          Line(3, 8, 4, 8);
          PutPixel(5, 7, LoopI + 100);
          Line(7, 5, 10, 2);
        end;
      6:
        begin
          PutPixel(7, 4, LoopI + 100);
          PutPixel(9, 5, LoopI + 100);
          PutPixel(5, 5, LoopI + 100);
          PutPixel(7, 6, LoopI + 100);
        end;
      7:
        begin
          PutPixel(7, 5, LoopI + 100);
          PutPixel(8, 4, LoopI + 100);
          PutPixel(9, 3, LoopI + 100);
          PutPixel(10, 3, LoopI + 100);
          PutPixel(11, 4, LoopI + 100);
          PutPixel(6, 4, LoopI + 100);
          PutPixel(5, 3, LoopI + 100);
          PutPixel(4, 3, LoopI + 100);
          PutPixel(3, 4, LoopI + 100);
          PutPixel(6, 5, LoopI + 100);
          PutPixel(5, 6, LoopI + 100);
          PutPixel(4, 7, LoopI + 100);
          PutPixel(4, 8, LoopI + 100);
          PutPixel(8, 5, LoopI + 100);
          PutPixel(9, 6, LoopI + 100);
          PutPixel(10, 7, LoopI + 100);
          PutPixel(10, 8, LoopI + 100);
          PutPixel(7, 6, LoopI + 100);
          PutPixel(7, 7, LoopI + 100);
          PutPixel(7, 8, LoopI + 100);
          PutPixel(7, 9, LoopI + 100);
        end;
      8:
        begin
          PutPixel(7, 4, LoopI + 100);
          PutPixel(7, 2, LoopI + 100);
          PutPixel(7, 6, LoopI + 100);
          PutPixel(7, 8, LoopI + 100);
          PutPixel(5, 3, LoopI + 100);
          PutPixel(9, 3, LoopI + 100);
          PutPixel(5, 7, LoopI + 100);
          PutPixel(9, 7, LoopI + 100);
        end;
      9:
        begin
          PutPixel(3, 2, LoopI + 100);
          PutPixel(5, 2, LoopI + 100);
          PutPixel(7, 2, LoopI + 100);
          PutPixel(9, 2, LoopI + 100);
          PutPixel(11, 2, LoopI + 100);
          PutPixel(3, 4, LoopI + 100);
          PutPixel(5, 4, LoopI + 100);
          PutPixel(7, 4, LoopI + 100);
          PutPixel(9, 4, LoopI + 100);
          PutPixel(11, 4, LoopI + 100);
          PutPixel(3, 6, LoopI + 100);
          PutPixel(5, 6, LoopI + 100);
          PutPixel(7, 6, LoopI + 100);
          PutPixel(9, 6, LoopI + 100);
          PutPixel(11, 6, LoopI + 100);
          PutPixel(3, 8, LoopI + 100);
          PutPixel(5, 8, LoopI + 100);
          PutPixel(7, 8, LoopI + 100);
          PutPixel(9, 8, LoopI + 100);
          PutPixel(11, 8, LoopI + 100);
        end;
      10:
        begin
          PutPixel(3, 2, LoopI + 100);
          PutPixel(5, 2, LoopI + 100);
          PutPixel(7, 2, LoopI + 100);
          PutPixel(9, 2, LoopI + 100);
          PutPixel(11, 2, LoopI + 100);
          PutPixel(4, 4, LoopI + 100);
          PutPixel(6, 4, LoopI + 100);
          PutPixel(8, 4, LoopI + 100);
          PutPixel(10, 4, LoopI + 100);
          PutPixel(12, 4, LoopI + 100);
          PutPixel(3, 6, LoopI + 100);
          PutPixel(5, 6, LoopI + 100);
          PutPixel(7, 6, LoopI + 100);
          PutPixel(9, 6, LoopI + 100);
          PutPixel(11, 6, LoopI + 100);
          PutPixel(4, 8, LoopI + 100);
          PutPixel(6, 8, LoopI + 100);
          PutPixel(8, 8, LoopI + 100);
          PutPixel(10, 8, LoopI + 100);
          PutPixel(12, 8, LoopI + 100);
        end;
      11:
        begin
          Bar(6, 5, 8, 7);
          Line(5, 6, 9, 6);
          Line(7, 6, 7, 3);
          Line(8, 2, 9, 2);
        end;
      12:
        begin
          Line(6, 3, 8, 5);
          Line(9, 3, 7, 5);
          Line(6, 7, 8, 5);
          Line(9, 7, 7, 5);
          Line(6, 5, 9, 5);
        end;
      13:
        begin
          Line(5, 4, 5, 6);
          Line(9, 4, 9, 6);
          Line(6, 3, 8, 3);
          Line(6, 7, 8, 7);
        end;
      14:
        begin
          Line(5, 4, 5, 6);
          Line(9, 4, 9, 6);
          Bar(6, 3, 8, 7);
        end;
      15:
        begin
          Bar(6, 4, 8, 6);
          Line(4, 5, 1, 5);
          Line(4, 5, 2, 3);
          Line(4, 5, 2, 7);
          Line(10, 5, 13, 5);
          Line(10, 5, 12, 3);
          Line(10, 5, 12, 7);
        end;
      16:
        begin
          Circle(7, 5, 1);
          PutPixel(7, 5, LoopI + 100);
          Line(4, 5, 1, 5);
          Line(4, 5, 2, 3);
          Line(4, 5, 2, 7);
          Line(10, 5, 13, 5);
          Line(10, 5, 12, 3);
          Line(10, 5, 12, 7);
          Line(7, 2, 7, -1);
          Line(7, 2, 5, 0);
          Line(7, 2, 9, 0);
          Line(7, 8, 7, 11);
          Line(7, 8, 5, 10);
          Line(7, 8, 9, 10);
        end;
      17:
        begin
          Circle(7, 7, 1);
          PutPixel(7, 7, LoopI + 100);
          Line(4, 7, 1, 7);
          Line(1, 7, 3, 5);
          Line(1, 7, 3, 9);
          Line(10, 7, 13, 7);
          Line(13, 7, 11, 5);
          Line(13, 7, 11, 9);
          Line(7, 4, 7, 1);
          Line(7, 1, 5, 3);
          Line(7, 1, 9, 3);
        end;
      18:
        begin
          SetTextJustify(1, 1);
          OutTextXY(7, 6, 'H');
        end;
      19:
        begin
          SetTextJustify(1, 1);
          OutTextXY(7, 6, 'V');
        end;
    end;
  end;
  SetTextJustify(LeftText, TopText);
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
end;

end.
