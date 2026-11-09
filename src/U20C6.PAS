{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U20C6;

{ New round: sky backgrounds, terrain generation, tank placement and the
  weapon/guidance icon bar. }

interface

uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3, U2390, U22B7;

procedure U20C6_0004(Sky: Integer);
procedure U20C6_099E;
procedure U20C6_1268;

implementation

uses
  U0098, U1F69;

{ Draw sky background number Sky into the back buffer and copy it to the
  playfield; also sets up the palette cycler for it. }
{#U20C6_0004}
procedure U20C6_0004(Sky: Integer);
var
  L: LongInt;
begin
  FillChar(BackBuf_E49A^, 64000, 0);
  g_E7D6 := $A000;
  case Sky of
    1:
      begin
        { stars }
        g_469A := 5;
        for g_461E := 0 to 9 do
        begin
          g_4622 := Trunc(g_469A * g_461E);
          g_E7C8(g_461E + 30, g_4622, g_4622, g_4622);
          g_E7C8(g_461E + 40, g_4622, g_4622, 0);
        end;
        for g_461E := 1 to Random(500) + 250 do
        begin
          g_4624 := Random(299) + 11;
          g_4626 := Random(159) + 31;
          g_4622 := Random(20) + 30;
          PutPixel(g_4624, g_4626, g_4622);
        end;
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 49;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        U2823_0C20(30, 20, @Pal_DE80);
        U2823_0C20(30, 20, @Pal_DE80[21]);
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := (g_E796 + 1) * 3;
      end;
    2:
      begin
        { horizontal stripes }
        U0098_0010;
        for g_461E := 31 to 190 do
          U2823_09E4(11, g_461E, 310, g_461E, g_461E mod 30 + 30);
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    3:
      begin
        { concentric circles }
        U0098_0010;
        SetViewPort(11, 31, 309, 189, True);
        U2823_0006;
        g_4624 := U2918_003D;
        g_4626 := U2918_0066;
        for g_461E := 0 to 170 do
        begin
          U2823_0351(g_4624, g_4626, g_461E, g_461E, g_461E mod 30 + 30);
          U2823_0351(g_4624 + 1, g_4626, g_461E, g_461E, g_461E mod 30 + 30);
        end;
        U2918_001E;
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    4:
      begin
        { rays from the centre }
        U0098_0010;
        SetViewPort(11, 31, 309, 189, True);
        U2823_0006;
        g_4624 := 160;
        g_4626 := 100;
        L := 0;
        g_462C := 6;
        for g_461E := g_E7CC.x1 to g_E7CC.x2 do
        begin
          U2823_09E4(g_4624, g_4626, g_461E, g_E7CC.y1, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for g_461E := g_E7CC.y1 to g_E7CC.y2 do
        begin
          U2823_09E4(g_4624, g_4626, g_E7CC.x2, g_461E, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for g_461E := g_E7CC.x2 downto g_E7CC.x1 do
        begin
          U2823_09E4(g_4624, g_4626, g_461E, g_E7CC.y2, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        for g_461E := g_E7CC.y2 downto g_E7CC.y1 do
        begin
          U2823_09E4(g_4624, g_4626, g_E7CC.x1, g_461E, (L mod 15) * 2 + 30);
          Inc(L);
        end;
        U2918_001E;
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    5:
      begin
        { static gradient }
        for g_461E := 0 to 19 do
          g_E7C8(g_461E + 30, g_461E, 0, 63 - g_461E);
        for g_461E := 31 to 190 do
          U2823_09E4(11, g_461E, 310, g_461E, (g_461E - 30) div 8 + 30);
        PalCycle_9FB8 := NoCycle_3706;
      end;
    6:
      begin
        { random noise }
        U0098_0010;
        SetViewPort(11, 31, 309, 189, True);
        U2823_0006;
        for g_4624 := g_E7CC.x1 to g_E7CC.x2 do
          for g_4626 := g_E7CC.y1 to g_E7CC.y2 do
            U2823_0BB6(g_4624, g_4626, Random(30) + 30);
        U2918_001E;
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    7:
      begin
        { nested rectangles }
        U0098_0010;
        case Random(3) of
          0: g_462A := 80;
          1: g_462A := 150;
          2: g_462A := 159;
        end;
        for g_461E := 1 to g_462A do
          U2823_0031(g_461E + 10, g_461E + 30, 310 - g_461E, 190 - g_461E,
            g_461E mod 30 + 30);
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    8:
      begin
        { tunnel }
        U0098_0010;
        SetViewPort(11, 31, 309, 189, True);
        U2823_0006;
        for g_4624 := 0 to 149 do
        begin
          U2823_09E4(160, 110, 160 - g_4624, 31, g_4624 mod 30 + 30);
          U2823_09E4(160, 110, g_4624 + 160, 31, g_4624 mod 30 + 30);
          U2823_09E4(160, 110, 160 - g_4624, 189, g_4624 mod 30 + 30);
          U2823_09E4(160, 110, g_4624 + 160, 189, g_4624 mod 30 + 30);
        end;
        for g_4626 := 0 to 79 do
        begin
          U2823_09E4(160, 110, 11, 110 - g_4626, (g_4626 + 70) mod 30 + 30);
          U2823_09E4(160, 110, 309, 110 - g_4626, (g_4626 + 70) mod 30 + 30);
          U2823_09E4(160, 110, 11, g_4626 + 110, (g_4626 + 70) mod 30 + 30);
          U2823_09E4(160, 110, 309, g_4626 + 110, (g_4626 + 70) mod 30 + 30);
        end;
        U2918_001E;
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
  end;
  g_E7D6 := Seg(BackBuf_E49A^);
  for g_4624 := 10 to 310 do
    U2823_0AC0(g_4624, 30, g_4624, 190, Ptr($A000, 0));
  U2823_0031(8, 28, 312, 192, 13);
  U2823_0031(10, 30, 310, 190, 13);
  g_E7D6 := $A000;
  if Random < 0.5 then U27D4_0428;
end;

{ Start a new round: wall type, sky, terrain, tanks. }
{#U20C6_099E}
procedure U20C6_099E;
var
  Dir, Slope, Margin: Integer;
  Falling, Landed, Fast: Boolean;
  Unused: Byte;
  P: Integer;
begin
  PalCycle_9FB8 := NoCycle_3706;
  U27D4_003D(NoCycle_3706);
  g_46C6 := g_E780;
  if g_46C6 = 5 then g_46C6 := Random(5);
  if g_46C6 in [1..3] then
    g_46EE := 1
  else
    g_46EE := 0;
  if g_46C6 = 4 then
    g_46EF := 1
  else
    g_46EF := 0;
  SetAspectRatio(1, 1);
  g_E7C8(19, 63, 63, 63);
  if g_E789 <> 0 then g_E7C8(19, 0, 0, 0);
  ClearDevice;
  if g_E782 <= 8 then U20C6_0004(g_E782);
  if g_E782 = 9 then U20C6_0004(Random(9));
  if g_E782 = 10 then
  begin
    repeat
      g_461E := Random(9);
    until (1 shl g_461E) and g_E784 > 0;
    U20C6_0004(g_461E);
  end;
  g_E7C8(0, 14, 9, 10);
  SetColor(13);
  Rectangle(8, 28, 312, 192);
  Rectangle(10, 30, 310, 190);
  SetColor(6);
  SetTextStyle(SmallFont, VertDir, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(CenterText, CenterText);
  case g_46C6 of
    1:
      begin
        OutTextXY(0, 100, 'STICKEY');
        g_46AC := 0.707106;
      end;
    2:
      begin
        OutTextXY(0, 100, 'ELASTIC');
        g_46AC := 1;
      end;
    3:
      begin
        OutTextXY(0, 100, 'ACCELERATE');
        g_46AC := 1.41421;
      end;
    4:
      OutTextXY(0, 100, 'WARP');
  end;
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetTextJustify(LeftText, TopText);
  SetColor(2);
  { terrain }
  g_4624 := 11;
  Slope := 0;
  Dir := 1 - Trunc(Random(2) * 2);
  Margin := 60 - (g_46B4 - 2) * 7;
  g_461C := Random(150);
  while g_4624 < 310 do
  begin
    if Margin + 11 > g_4624 then
      Line(g_4624, 190 - g_461C, g_4624, 189)
    else if 309 - Margin < g_4624 then
      Line(g_4624, 190 - g_461C, g_4624, 189)
    else
    begin
      if Slope = 0 then
      begin
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
      end;
      if Abs(Slope) = 1 then
      begin
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
      end;
      if Abs(Slope) = 2 then
      begin
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
      end;
      if Abs(Slope) = 3 then
      begin
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        Inc(g_4624);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
      end;
      if Abs(Slope) = 4 then
      begin
        U2823_09E4(g_4624, 190 - g_461C, g_4624, 189, 2);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
        if Slope > 0 then Inc(g_461C) else Dec(g_461C);
      end;
      if Random < 0.2 then Slope := Slope + Dir;
      if (Random < 0.1) or (Abs(Slope) > 4) then Dir := -Dir;
      if Slope > 4 then Slope := 4;
      if Slope < -4 then Slope := -4;
      if g_461C <= 20 then Dir := 1;
      if g_461C >= 140 then Dir := -1;
      if g_461C <= 3 then Slope := 1;
      if g_461C >= 155 then Slope := -1;
    end;
    Inc(g_4624);
  end;
  { place the tanks }
  Players_3F0E[1].X := Random(28) + 16;
  Players_3F0E[g_46B4].X := 305 - Random(28);
  g_4620 := (Players_3F0E[g_46B4].X - Players_3F0E[1].X) div (g_46B4 - 1);
  if g_46B4 > 2 then
    for P := 2 to g_46B4 - 1 do
      Players_3F0E[P].X := (P - 1) * g_4620 + Players_3F0E[1].X;
  Fast := Boolean(g_46EC);
  if U0098_09B2 then Fast := True;
  for P := 1 to g_46B4 do
  begin
    SetFillStyle(SolidFill, 0);
    Bar(109, 0, 211, 7);
    SetColor(P + 19);
    SetTextJustify(CenterText, TopText);
    OutTextXY(160, 0, Players_3F0E[P].Name);
    if P in [1, g_46B4] then
      Players_3F0E[P].f1D := 75
    else
      Players_3F0E[P].f1D := 90;
    Players_3F0E[P].f1B := 200;
    if P = g_46B4 then
      Players_3F0E[P].f1F := -1
    else
      Players_3F0E[P].f1F := 1;
    U26A9_0175(100, Players_3F0E[P]);
    Players_3F0E[P].f23 := 1;
    Players_3F0E[P].Y := 32;
    Players_3F0E[P].f5E := 0;
    U26A9_014E(Players_3F0E[P]);
    Falling := True;
    for g_4620 := -4 to 4 do
      if U2823_0BFF(Players_3F0E[P].X + g_4620, Players_3F0E[P].Y + 1) in [2, 13] then
        Falling := False;
    if Falling then
    begin
      Landed := False;
      repeat
        Landed := True;
        U0098_066A(Players_3F0E[P].X, Players_3F0E[P].Y, BackBuf_E49A);
        Inc(Players_3F0E[P].Y);
        U0098_05D2(Players_3F0E[P].X, Players_3F0E[P].Y, P + 19);
        if not Fast then Delay(g_E79C);
        for g_4620 := -4 to 4 do
          if not (U2823_0BFF(Players_3F0E[P].X + g_4620, Players_3F0E[P].Y + 1) in [2, 13]) then
            Landed := False;
      until Landed;
      U0098_07A3(P);
      U1F69_0366;
    end;
    if not Fast and U0098_09B2 then Fast := True;
  end;
  g_46ED := 0;
  U27D4_003D(PalCycle_9FB8);
end;

{ Draw the weapon / guidance icon bar at the top of the screen and remember
  the button positions in ButtonX_E74E. }
{#U20C6_1268}
procedure U20C6_1268;
var
  Base: Integer;
begin
  Base := 10;
  for g_461E := 0 to 19 do
  begin
    SetColor(g_461E + 100);
    SetFillStyle(SolidFill, g_461E + 100);
    g_E7C8(g_461E + 100, 0, 0, 0);
    SetViewPort(15 * g_461E + Base, 18, Base + 15 + 15 * g_461E, 27, True);
    ButtonX_E74E[g_461E] := 15 * g_461E + Base;
    ButtonX_E74E[g_461E + 1] := (g_461E + 1) * 15 + Base;
    Rectangle(0, 0, 14, 10);
    case g_461E of
      0:
        PutPixel(7, 5, g_461E + 100);
      1:
        Circle(7, 5, 1);
      2:
        begin
          PutPixel(7, 5, g_461E + 100);
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
          PutPixel(5, 7, g_461E + 100);
          Line(7, 5, 10, 2);
        end;
      6:
        begin
          PutPixel(7, 4, g_461E + 100);
          PutPixel(9, 5, g_461E + 100);
          PutPixel(5, 5, g_461E + 100);
          PutPixel(7, 6, g_461E + 100);
        end;
      7:
        begin
          PutPixel(7, 5, g_461E + 100);
          PutPixel(8, 4, g_461E + 100);
          PutPixel(9, 3, g_461E + 100);
          PutPixel(10, 3, g_461E + 100);
          PutPixel(11, 4, g_461E + 100);
          PutPixel(6, 4, g_461E + 100);
          PutPixel(5, 3, g_461E + 100);
          PutPixel(4, 3, g_461E + 100);
          PutPixel(3, 4, g_461E + 100);
          PutPixel(6, 5, g_461E + 100);
          PutPixel(5, 6, g_461E + 100);
          PutPixel(4, 7, g_461E + 100);
          PutPixel(4, 8, g_461E + 100);
          PutPixel(8, 5, g_461E + 100);
          PutPixel(9, 6, g_461E + 100);
          PutPixel(10, 7, g_461E + 100);
          PutPixel(10, 8, g_461E + 100);
          PutPixel(7, 6, g_461E + 100);
          PutPixel(7, 7, g_461E + 100);
          PutPixel(7, 8, g_461E + 100);
          PutPixel(7, 9, g_461E + 100);
        end;
      8:
        begin
          PutPixel(7, 4, g_461E + 100);
          PutPixel(7, 2, g_461E + 100);
          PutPixel(7, 6, g_461E + 100);
          PutPixel(7, 8, g_461E + 100);
          PutPixel(5, 3, g_461E + 100);
          PutPixel(9, 3, g_461E + 100);
          PutPixel(5, 7, g_461E + 100);
          PutPixel(9, 7, g_461E + 100);
        end;
      9:
        begin
          PutPixel(3, 2, g_461E + 100);
          PutPixel(5, 2, g_461E + 100);
          PutPixel(7, 2, g_461E + 100);
          PutPixel(9, 2, g_461E + 100);
          PutPixel(11, 2, g_461E + 100);
          PutPixel(3, 4, g_461E + 100);
          PutPixel(5, 4, g_461E + 100);
          PutPixel(7, 4, g_461E + 100);
          PutPixel(9, 4, g_461E + 100);
          PutPixel(11, 4, g_461E + 100);
          PutPixel(3, 6, g_461E + 100);
          PutPixel(5, 6, g_461E + 100);
          PutPixel(7, 6, g_461E + 100);
          PutPixel(9, 6, g_461E + 100);
          PutPixel(11, 6, g_461E + 100);
          PutPixel(3, 8, g_461E + 100);
          PutPixel(5, 8, g_461E + 100);
          PutPixel(7, 8, g_461E + 100);
          PutPixel(9, 8, g_461E + 100);
          PutPixel(11, 8, g_461E + 100);
        end;
      10:
        begin
          PutPixel(3, 2, g_461E + 100);
          PutPixel(5, 2, g_461E + 100);
          PutPixel(7, 2, g_461E + 100);
          PutPixel(9, 2, g_461E + 100);
          PutPixel(11, 2, g_461E + 100);
          PutPixel(4, 4, g_461E + 100);
          PutPixel(6, 4, g_461E + 100);
          PutPixel(8, 4, g_461E + 100);
          PutPixel(10, 4, g_461E + 100);
          PutPixel(12, 4, g_461E + 100);
          PutPixel(3, 6, g_461E + 100);
          PutPixel(5, 6, g_461E + 100);
          PutPixel(7, 6, g_461E + 100);
          PutPixel(9, 6, g_461E + 100);
          PutPixel(11, 6, g_461E + 100);
          PutPixel(4, 8, g_461E + 100);
          PutPixel(6, 8, g_461E + 100);
          PutPixel(8, 8, g_461E + 100);
          PutPixel(10, 8, g_461E + 100);
          PutPixel(12, 8, g_461E + 100);
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
          PutPixel(7, 5, g_461E + 100);
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
          PutPixel(7, 7, g_461E + 100);
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
