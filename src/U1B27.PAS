{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1B27;

{ Special tank death animations (chosen at random by U1615).

  Note: procedures calling Crt.Delay only show as 'diff' in cmp.py because
  the original was linked with a patched CRT (Delay reloads DelayCnt via BX,
  2 bytes longer); the generated code itself is identical. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure FlashRandomColor(Color: Integer);
procedure TankDeathNuke(P: Integer);
procedure AnimDebrisPaths(N: Integer; var A: TPaths);
procedure PaintDebrisPaths(N: Integer; var A: TPaths);
procedure TankDeathDebris(P, Kind: Integer);
procedure TankDeathFunky(P: Integer);
procedure TankDeathSparks(P: Integer);
procedure TankDeathPulse(P: Integer);
procedure TankDeathBlast(P: Integer);

implementation

uses
  U1DD4, U0098;

{ flash palette entry Color with 3 random bytes from low memory }
{#U1B27_0000}
procedure FlashRandomColor(Color: Integer);
begin
  SetPalBlock(Color, 1, Ptr(0, Random($FFFF)));
end;

{ "nuke": fireballs flying off the tank, then a growing mushroom }
{#U1B27_0047}
procedure TankDeathNuke(P: Integer);
var
  Color, X, Y, L: Integer;
begin
  Color := P + 19;
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 130, Trunc((1 - LoopJ / 4) * 63), 0, 0);
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 140, 0, Trunc((1 - LoopJ / 4) * 63), 0);
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 150, 0, 0, Trunc((1 - LoopJ / 4) * 63));
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 100 do
  begin
    if SoundOn <> 0 then Sound(Random(500));
    FlashRandomColor(Color);
    Delay(ExplodeSpeed);
  end;
  NoSound;
  SetViewPort(11, 31, 309, 189, True);
  FetchClipWindow;
  Players[P].X := Players[P].X - 11;
  Players[P].Y := Players[P].Y - 31;
  for LoopJ := 0 to 10 do
  begin
    if SoundOn <> 0 then Sound(Random(500));
    ShotX := Players[P].X;
    ShotY := Players[P].Y;
    ShotVX := 0.5 - Random;
    ShotVY := 0.1 - Random;
    DoneFlag := 0;
    repeat
      ShotX := ShotX + ShotVX;
      ShotY := ShotY + ShotVY;
      ShotVY := ShotVY + 0.007;
      ShotVX := ShotVX + WindForce / 5000;
      X := Trunc(ShotX);
      Y := Trunc(ShotY);
      TmpC := GetPixel(X, Y);
      if (TmpC = 2) or (TmpC = 13) then DoneFlag := 1;
      if (TmpC >= 20) and (TmpC <= 29) then
        ApplyDamage(Random(10) + 5, 0, Players[TmpC - 19]);
      if (X > 320) or (X < 0) or (Y > 200) or (Y < 0) then DoneFlag := 1;
      if SoundOn <> 0 then Sound(Trunc((Players[P].Y - Y) * 5 + 1500));
      FlashRandomColor(Color);
      PutPixel(X, Y, Color);
    until DoneFlag <> 0;
    DebrisX[LoopJ] := X;
    DebrisY[LoopJ] := Y;
    TmpX := X;
    TmpY := Y;
    LoopK := (Trunc(Random(3)) + 3) * 10;
    X := Random(10);
    case X of
      0, 1, 2: Y := 1;
      3, 4, 5: Y := 2;
      6, 7: Y := 3;
      8: Y := 4;
      9: Y := 5;
    end;
    DebrisSize[LoopJ] := Y;
    NoSound;
    for TmpR := 0 to Y * 4 do
    begin
      if SoundOn <> 0 then Sound(Random(2500));
      X := LoopK + 100 + TmpR div Y;
      DrawEllipse(TmpX, TmpY, TmpR, TmpR, X);
      DrawEllipse(TmpX + 1, TmpY, TmpR, TmpR, X);
      Delay(ExplodeSpeed);
      FlashRandomColor(Color);
    end;
    SetColor(0);
    for TmpR := Y * 4 downto 0 do
    begin
      if SoundOn <> 0 then Sound(Random(2500));
      CopyEllipse(TmpX, TmpY, TmpR, TmpR, BackBuf);
      CopyEllipse(TmpX + 1, TmpY, TmpR, TmpR, BackBuf);
      FlashRandomColor(Color);
      Delay(ExplodeSpeed);
    end;
  end;
  TmpR := 0;
  for LoopJ := 0 to 4 do
    for LoopK := 3 to 5 do
    begin
      Inc(TmpR);
      ExplColor := 10 * LoopK + 100 + LoopJ;
      DrawEllipse(Players[P].X, Players[P].Y, TmpR, TmpR, ExplColor);
      DrawEllipse(Players[P].X + 1, Players[P].Y, TmpR, TmpR, ExplColor);
      for TmpC := 0 to 4 do
      begin
        if SoundOn <> 0 then Sound(Random(1300 - 40 * TmpR));
        FlashRandomColor(Color);
      end;
      DrawEllipse(Players[P].X, Players[P].Y, TmpR + 1, TmpR + 1, ExplColor);
      DrawEllipse(Players[P].X + 1, Players[P].Y, TmpR + 1, TmpR + 1, ExplColor);
      for TmpC := 0 to 4 do
      begin
        if SoundOn <> 0 then Sound(Random(1300 - 40 * TmpR));
        FlashRandomColor(Color);
      end;
      Inc(TmpR);
      Delay(ExplodeSpeed);
    end;
  TmpR := 16;
  for LoopJ := 4 downto 0 do
    for LoopK := 4 - LoopJ downto 0 do
    begin
      Dec(TmpR);
      if SoundOn <> 0 then Sound(Random(100 * LoopK + 600));
      SetPalRGB(Color, TmpR * Random(63) div 16, TmpR * Random(63) div 16,
        TmpR * Random(63) div 16);
      L := 63 * LoopK div 4;
      SetPalRGB(LoopJ + 130, L, 0, 0);
      NoSound;
      SetPalRGB(LoopJ + 140, 0, L, 0);
      SetPalRGB(LoopJ + 150, 0, 0, L);
      Delay(ExplodeSpeed);
    end;
  for LoopJ := 30 downto 0 do
  begin
    CopyEllipse(Players[P].X, Players[P].Y, LoopJ, LoopJ, BackBuf);
    CopyEllipse(Players[P].X + 1, Players[P].Y, LoopJ, LoopJ, BackBuf);
  end;
  NoSound;
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  Players[P].X := Players[P].X + 11;
  Players[P].Y := Players[P].Y + 31;
  for Color := 1 to NumPlayers do
    DrawTank(Color);
  RestoreColorPixels(P + 19, BackBuf);
  RestoreColorRange($82, $9F, BackBuf);
end;

{ debris pass: walk the N points of the 5 paths, damage tanks hit, plot
  random colours and restore the previous step from the background buffer }
{#U1B27_09EF}
procedure AnimDebrisPaths(N: Integer; var A: TPaths);
var
  J, I, K, L, C, U1, U2, U3: Integer;
begin
  for I := 1 to N do
  begin
    if SoundOn <> 0 then Sound(Random(500) + 100);
    NoSound;
    C := PixelAt(A[1, I].X, A[1, I].Y);
    if (C >= 20) and (C <= 29) then
      ApplyDamage(Random(3) + 1, 0, Players[C - 19]);
    PlotPixel(A[1, I].X, A[1, I].Y, Random(14) + 1);
  end;
  for J := 2 to 5 do
    for I := 1 to N do
    begin
      if SoundOn <> 0 then Sound(Random(500 * J) + 100);
      NoSound;
      C := PixelAt(A[J, I].X, A[J, I].Y);
      if (C >= 20) and (C <= 29) then
        ApplyDamage(Random(3) + 1, 0, Players[C - 19]);
      PlotPixel(A[J, I].X, A[J, I].Y, Random(14) + 1);
      CopyPixel(A[J - 1, I].X, A[J - 1, I].Y, BackBuf);
    end;
  for I := 1 to N do
    CopyPixel(A[5, I].X, A[5, I].Y, BackBuf);
end;

{ debris variant: paint the paths with random colours 201..214 (202 -> 2) }
{#U1B27_0C6F}
procedure PaintDebrisPaths(N: Integer; var A: TPaths);
var
  J, I, K, L, C, T, U1, U2, Col: Integer;
begin
  for J := 1 to 5 do
    for I := 1 to N do
    begin
      if SoundOn <> 0 then Sound(Random(500 * J) + 100);
      NoSound;
      C := PixelAt(A[J, I].X, A[J, I].Y);
      T := C - 19;
      if (C >= 20) and (C <= 29) then
        ApplyDamage(Random(3) + 1, 0, Players[T]);
      Col := Random(14) + 201;
      if Col = 202 then Col := 2;
      PlotPixel(A[J, I].X, A[J, I].Y, Col);
    end;
end;

{ random debris bursts around the tank }
{#U1B27_0DAB}
procedure TankDeathDebris(P, Kind: Integer);
var
  J, I, K, Len, Dir, R, U1, U2: Integer;
begin
  ReadDacBlock(0, 16, FallList);
  SetPalBlock(200, 16, FallList);
  FillChar(Paths, SizeOf(Paths), 0);
  for K := 1 to Random(5) + 5 do
  begin
    Len := Random(390) + 2;
    Dir := Random(8) + 1;
    case Dir of
      1:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].Y := Players[P].Y - Paths[J, I].Y;
            Paths[J, I].X := Players[P].X + Paths[J, I].X;
          end;
        end;
      2:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].Y := Players[P].Y + Paths[J, I].Y;
            Paths[J, I].X := Players[P].X + Paths[J, I].X;
          end;
        end;
      3:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].X := Random(R);
            Paths[J, I].Y := Trunc(Random(Paths[J, I].X + 10) - Paths[J, I].X / 2 - 5);
            Paths[J, I].Y := Players[P].Y - Paths[J, I].Y;
            Paths[J, I].X := Players[P].X + Paths[J, I].X;
          end;
        end;
      4:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].X := Random(R);
            Paths[J, I].Y := Trunc(Random(Paths[J, I].X + 10) - Paths[J, I].X / 2 - 5);
            Paths[J, I].Y := Players[P].Y - Paths[J, I].Y;
            Paths[J, I].X := Players[P].X - Paths[J, I].X;
          end;
        end;
      5:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].X := Players[P].X + Paths[J, I].X + Paths[J, I].Y;
            Paths[J, I].Y := Players[P].Y - Paths[J, I].Y;
          end;
        end;
      6:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].X := Players[P].X + Paths[J, I].X - Paths[J, I].Y;
            Paths[J, I].Y := Players[P].Y - Paths[J, I].Y;
          end;
        end;
      7:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].X := Players[P].X + Paths[J, I].X + Paths[J, I].Y;
            Paths[J, I].Y := Players[P].Y + Paths[J, I].Y;
          end;
        end;
      8:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths[J, I].Y := Random(R);
            Paths[J, I].X := Trunc(Random(Paths[J, I].Y + 10) - Paths[J, I].Y / 2 - 5);
            Paths[J, I].X := Players[P].X + Paths[J, I].X - Paths[J, I].Y;
            Paths[J, I].Y := Players[P].Y + Paths[J, I].Y;
          end;
        end;
    end;
    for J := 1 to 5 do
      for I := 1 to Len do
      begin
        if Paths[J, I].X > 309 then Paths[J, I].X := 618 - Paths[J, I].X;
        if Paths[J, I].Y > 189 then Paths[J, I].Y := 378 - Paths[J, I].Y;
        if Paths[J, I].Y < 31 then Paths[J, I].Y := 62 - Paths[J, I].Y;
        if Paths[J, I].X < 11 then Paths[J, I].X := 22 - Paths[J, I].X;
      end;
    case Kind of
      0: AnimDebrisPaths(Len, Paths);
      1: PaintDebrisPaths(Len, Paths);
    end;
  end;
  for R := 1 to NumPlayers do
    DrawTank(R);
  EraseTank(P);
  RestoreColorRange($C9, $DC, BackBuf);
end;

{ "funky bomb" style: 11 fireballs at once, each ending in a fireball }
{#U1B27_1B69}
procedure TankDeathFunky(P: Integer);
var
  Color, X, Y, L: Integer;
  PX, PY, VX, VY: array[0..10] of Real;
  Done: array[0..11] of Boolean;   { one more than needed (frame layout) }
begin
  Color := P + 19;
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 130, Trunc((1 - LoopJ / 4) * 63), 0, 0);
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 140, 0, Trunc((1 - LoopJ / 4) * 63), 0);
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 4 do
    SetPalRGB(LoopJ + 150, 0, 0, Trunc((1 - LoopJ / 4) * 63));
  if SoundOn <> 0 then Sound(Random(500));
  FlashRandomColor(Color);
  for LoopJ := 0 to 100 do
  begin
    if SoundOn <> 0 then Sound(Random(500));
    FlashRandomColor(Color);
    Delay(ExplodeSpeed);
  end;
  NoSound;
  SetViewPort(11, 31, 309, 189, True);
  FetchClipWindow;
  Players[P].X := Players[P].X - 11;
  Players[P].Y := Players[P].Y - 31;
  for LoopJ := 0 to 10 do
  begin
    if SoundOn <> 0 then Sound(Random(500));
    PX[LoopJ] := Players[P].X;
    PY[LoopJ] := Players[P].Y;
    VX[LoopJ] := 0.5 - Random;
    VY[LoopJ] := 0.1 - Random;
    Done[LoopJ] := False;
  end;
  repeat
    DoneFlag := 1;
    FlashRandomColor(Color);
    for LoopJ := 0 to 10 do
      if not Done[LoopJ] then
      begin
        PX[LoopJ] := PX[LoopJ] + VX[LoopJ];
        PY[LoopJ] := PY[LoopJ] + VY[LoopJ];
        VY[LoopJ] := VY[LoopJ] + 0.007;
        VX[LoopJ] := VX[LoopJ] + WindForce / 5000;
        X := Trunc(PX[LoopJ]);
        Y := Trunc(PY[LoopJ]);
        DoneFlag := 0;
        TmpC := GetPixel(X, Y);
        if (TmpC = 2) or (TmpC = 13) then Done[LoopJ] := True;
        if (TmpC >= 20) and (TmpC <= 29) then
          ApplyDamage(Random(10) + 10, 0, Players[TmpC - 19]);
        if (X > 298) or (X < 0) or (Y > 158) or (Y < 0) then Done[LoopJ] := True;
        if SoundOn <> 0 then Sound(Trunc((Players[P].Y - Y) * 5 + 1500));
        PutPixel(X, Y, Color);
        if Done[LoopJ] then
        begin
          DebrisX[LoopJ] := X;
          DebrisY[LoopJ] := Y;
        end;
      end;
  until DoneFlag <> 0;
  for LoopJ := 0 to 10 do
  begin
    TmpX := DebrisX[LoopJ];
    TmpY := DebrisY[LoopJ];
    LoopK := (Trunc(Random(3)) + 3) * 10;
    TmpC := Random(10);
    case TmpC of
      0, 1, 2: TmpN := 1;
      3, 4, 5: TmpN := 2;
      6, 7: TmpN := 3;
      8: TmpN := 4;
      9: TmpN := 5;
    end;
    for TmpR := 0 to TmpN * 4 do
    begin
      if SoundOn <> 0 then Sound(Random(2500));
      FlashRandomColor(Color);
      ExplColor := LoopK + 100 + TmpR div TmpN;
      DrawEllipse(TmpX, TmpY, TmpR, TmpR, ExplColor);
      DrawEllipse(TmpX + 1, TmpY, TmpR, TmpR, ExplColor);
      Delay(ExplodeSpeed);
    end;
    for TmpR := TmpN * 4 downto 0 do
    begin
      if SoundOn <> 0 then Sound(Random(2500));
      FlashRandomColor(Color);
      CopyEllipse(TmpX, TmpY, TmpR, TmpR, BackBuf);
      CopyEllipse(TmpX + 1, TmpY, TmpR, TmpR, BackBuf);
      Delay(ExplodeSpeed);
    end;
  end;
  TmpR := 0;
  for LoopJ := 0 to 4 do
    for LoopK := 3 to 5 do
    begin
      Inc(TmpR);
      ExplColor := 10 * LoopK + 100 + LoopJ;
      DrawEllipse(Players[P].X, Players[P].Y, TmpR, TmpR, ExplColor);
      for TmpC := 0 to 4 do
      begin
        if SoundOn <> 0 then Sound(Random(1300 - 40 * TmpR));
        FlashRandomColor(Color);
      end;
      DrawEllipse(Players[P].X, Players[P].Y, TmpR + 1, TmpR + 1, ExplColor);
      for TmpC := 0 to 4 do
      begin
        if SoundOn <> 0 then Sound(Random(1300 - 40 * TmpR));
        FlashRandomColor(Color);
      end;
      Delay(ExplodeSpeed);
      Inc(TmpR);
    end;
  TmpR := 16;
  for LoopJ := 4 downto 0 do
    for LoopK := 4 - LoopJ downto 0 do
    begin
      Dec(TmpR);
      if SoundOn <> 0 then Sound(Random(200));
      SetPalRGB(Color, TmpR * Random(63) div 16, TmpR * Random(63) div 16,
        TmpR * Random(63) div 16);
      L := 63 * LoopK div 4;
      SetPalRGB(LoopJ + 130, L, 0, 0);
      NoSound;
      SetPalRGB(LoopJ + 140, 0, L, 0);
      SetPalRGB(LoopJ + 150, 0, 0, L);
      Delay(ExplodeSpeed);
    end;
  for LoopJ := 30 downto 0 do
  begin
    CopyEllipse(Players[P].X, Players[P].Y, LoopJ, LoopJ, BackBuf);
    CopyEllipse(Players[P].X + 1, Players[P].Y, LoopJ, LoopJ, BackBuf);
  end;
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  Players[P].X := Players[P].X + 11;
  Players[P].Y := Players[P].Y + 31;
  for Color := 1 to NumPlayers do
    DrawTank(Color);
  RestoreColorPixels(P + 19, BackBuf);
  RestoreColorRange($82, $9A, BackBuf);
end;

{ sparks: 30..59 rings of random dirt pixels (colour 2) around the tank }
{#U1B27_25D9}
procedure TankDeathSparks(P: Integer);
var
  R, U1, U2, K, I, U3: Integer;
begin
  for TmpC := 1 to Random(30) + 30 do
  begin
    R := 10 * TmpC;
    for I := 1 to Random(400) do
    begin
      Paths[1, I].Y := Random(R);
      Paths[1, I].X := Trunc(Random(Paths[1, I].Y + 10) - Paths[1, I].Y / 2 - 5);
      Paths[1, I].Y := Players[P].Y - Paths[1, I].Y;
      Paths[1, I].X := Players[P].X + Paths[1, I].X;
      while (Paths[1, I].X > 309) or (Paths[1, I].Y < 31) or
        (Paths[1, I].X < 11) or (Paths[1, I].Y > 189) do
      begin
        if Paths[1, I].X > 309 then Paths[1, I].X := 618 - Paths[1, I].X;
        if Paths[1, I].Y > 189 then Paths[1, I].Y := 378 - Paths[1, I].Y;
        if Paths[1, I].Y < 31 then Paths[1, I].Y := 62 - Paths[1, I].Y;
        if Paths[1, I].X < 11 then Paths[1, I].X := 22 - Paths[1, I].X;
      end;
      PlotPixel(Paths[1, I].X, Paths[1, I].Y, 2);
      if SoundOn <> 0 then Sound(100 * TmpC + Random(1000));
    end;
  end;
  NoSound;
  for K := 1 to NumPlayers do
    DrawTank(K);
  EraseTank(P);
end;

{ SetPlayerMen counted 0..100..0 with a rising/falling tone, then -1 }
{#U1B27_2840}
procedure TankDeathPulse(P: Integer);
var
  U1, U2, U3, U4, U5, U6, I, U7, U8: Integer;
begin
  DrawTank(P);
  for I := 0 to 100 do
  begin
    SetPlayerMen(I, Players[P]);
    if SoundOn <> 0 then Sound(100 * I + 2000);
    Delay(ExplodeSpeed);
  end;
  for I := 100 downto 0 do
  begin
    SetPlayerMen(I, Players[P]);
    if SoundOn <> 0 then Sound(100 * I + 2000);
    Delay(ExplodeSpeed);
  end;
  NoSound;
  SetPlayerMen(-1, Players[P]);
  EraseTank(P);
end;

{ like 2840, then 1..4 explosions of weapon 1..4 at the tank's position
  (fired by the dummy player 0) }
{#U1B27_2902}
procedure TankDeathBlast(P: Integer);
var
  U1, U2, U3, U4, U5, U6, I, J, K, D: Integer;
begin
  D := ExplodeSpeed;
  if Random(2) = 1 then D := 0;
  DrawTank(P);
  for J := 1 to 3 do
    for I := 0 to 100 do
    begin
      SetPlayerMen(I, Players[P]);
      if SoundOn <> 0 then Sound(100 * I + 2000);
      Delay(D);
    end;
  for I := 100 downto 1 do
  begin
    SetPlayerMen(I, Players[P]);
    if SoundOn <> 0 then Sound(100 * I + 2000);
    Delay(D);
  end;
  Players[0] := Players[P];
  TmpR := Random(10);
  case TmpR of
    0..1: TmpC := 1;
    2..4: TmpC := 2;
    5..7: TmpC := 3;
    8..9: TmpC := 4;
  end;
  for K := 1 to TmpC do
  begin
    Players[0].Weapon := K;
    WeaponImpact(0, Players[0].X, Players[0].Y, 2);
    for I := 1 to NumPlayers do
      DrawTank(I);
  end;
  NoSound;
  SetPlayerMen(-1, Players[P]);
end;

end.
