{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1B27;

{ Special tank death animations (chosen at random by U1615). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure U1B27_0000(Color: Integer);
procedure U1B27_0047(P: Integer);
procedure U1B27_09EF(N: Integer; var A: TPaths);
procedure U1B27_0C6F(N: Integer; var A: TPaths);
procedure U1B27_0DAB(P, Kind: Integer);
procedure U1B27_1B69(P: Integer);
procedure U1B27_25D9(P: Integer);
procedure U1B27_2840(P: Integer);
procedure U1B27_2902(P: Integer);

implementation

uses
  U0098, U1DD4;

{ flash palette entry Color with 3 random bytes from low memory }
{#U1B27_0000}
procedure U1B27_0000(Color: Integer);
begin
  SetPalBlock(Color, 1, Ptr(0, Random($FFFF)));
end;

{ "nuke": fireballs flying off the tank, then a growing mushroom }
{#U1B27_0047}
procedure U1B27_0047(P: Integer);
var
  Color, X, Y, L: Integer;
begin
  Color := P + 19;
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 130, Trunc((1 - g_4620 / 4) * 63), 0, 0);
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 140, 0, Trunc((1 - g_4620 / 4) * 63), 0);
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 150, 0, 0, Trunc((1 - g_4620 / 4) * 63));
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 100 do
  begin
    if g_E788 <> 0 then Sound(Random(500));
    U1B27_0000(Color);
    Delay(g_E79A);
  end;
  NoSound;
  SetViewPort(11, 31, 309, 189, True);
  U2823_0006;
  Players_3F0E[P].X := Players_3F0E[P].X - 11;
  Players_3F0E[P].Y := Players_3F0E[P].Y - 31;
  for g_4620 := 0 to 10 do
  begin
    if g_E788 <> 0 then Sound(Random(500));
    g_4670 := Players_3F0E[P].X;
    g_4676 := Players_3F0E[P].Y;
    g_467C := 0.5 - Random;
    g_4682 := 0.1 - Random;
    g_462F := 0;
    repeat
      g_4670 := g_4670 + g_467C;
      g_4676 := g_4676 + g_4682;
      g_4682 := g_4682 + 0.007;
      g_467C := g_467C + g_E778 / 5000;
      X := Trunc(g_4670);
      Y := Trunc(g_4676);
      g_462A := GetPixel(X, Y);
      if (g_462A = 2) or (g_462A = 13) then g_462F := 1;
      if (g_462A >= 20) and (g_462A <= 29) then
        U26A9_0004(Random(10) + 5, 0, Players_3F0E[g_462A - 19]);
      if (X > 320) or (X < 0) or (Y > 200) or (Y < 0) then g_462F := 1;
      if g_E788 <> 0 then Sound(Trunc((Players_3F0E[P].Y - Y) * 5 + 1500));
      U1B27_0000(Color);
      PutPixel(X, Y, Color);
    until g_462F <> 0;
    DebX_3E9E[g_4620] := X;
    DebY_3EB4[g_4620] := Y;
    g_4624 := X;
    g_4626 := Y;
    g_4622 := (Trunc(Random(3)) + 3) * 10;
    X := Random(10);
    case X of
      0, 1, 2: Y := 1;
      3, 4, 5: Y := 2;
      6, 7: Y := 3;
      8: Y := 4;
      9: Y := 5;
    end;
    DebS_3ECA[g_4620] := Y;
    NoSound;
    for g_4628 := 0 to Y * 4 do
    begin
      if g_E788 <> 0 then Sound(Random(2500));
      X := g_4622 + 100 + g_4628 div Y;
      U2823_0351(g_4624, g_4626, g_4628, g_4628, X);
      U2823_0351(g_4624 + 1, g_4626, g_4628, g_4628, X);
      Delay(g_E79A);
      U1B27_0000(Color);
    end;
    SetColor(0);
    for g_4628 := Y * 4 downto 0 do
    begin
      if g_E788 <> 0 then Sound(Random(2500));
      U2823_0687(g_4624, g_4626, g_4628, g_4628, BackBuf_E49A);
      U2823_0687(g_4624 + 1, g_4626, g_4628, g_4628, BackBuf_E49A);
      U1B27_0000(Color);
      Delay(g_E79A);
    end;
  end;
  g_4628 := 0;
  for g_4620 := 0 to 4 do
    for g_4622 := 3 to 5 do
    begin
      Inc(g_4628);
      g_3EE0 := 10 * g_4622 + 100 + g_4620;
      U2823_0351(Players_3F0E[P].X, Players_3F0E[P].Y, g_4628, g_4628, g_3EE0);
      U2823_0351(Players_3F0E[P].X + 1, Players_3F0E[P].Y, g_4628, g_4628, g_3EE0);
      for g_462A := 0 to 4 do
      begin
        if g_E788 <> 0 then Sound(Random(1300 - 40 * g_4628));
        U1B27_0000(Color);
      end;
      U2823_0351(Players_3F0E[P].X, Players_3F0E[P].Y, g_4628 + 1, g_4628 + 1, g_3EE0);
      U2823_0351(Players_3F0E[P].X + 1, Players_3F0E[P].Y, g_4628 + 1, g_4628 + 1, g_3EE0);
      for g_462A := 0 to 4 do
      begin
        if g_E788 <> 0 then Sound(Random(1300 - 40 * g_4628));
        U1B27_0000(Color);
      end;
      Inc(g_4628);
      Delay(g_E79A);
    end;
  g_4628 := 16;
  for g_4620 := 4 downto 0 do
    for g_4622 := 4 - g_4620 downto 0 do
    begin
      Dec(g_4628);
      if g_E788 <> 0 then Sound(Random(100 * g_4622 + 600));
      SetPalRGB(Color, g_4628 * Random(63) div 16, g_4628 * Random(63) div 16,
        g_4628 * Random(63) div 16);
      L := 63 * g_4622 div 4;
      SetPalRGB(g_4620 + 130, L, 0, 0);
      NoSound;
      SetPalRGB(g_4620 + 140, 0, L, 0);
      SetPalRGB(g_4620 + 150, 0, 0, L);
      Delay(g_E79A);
    end;
  for g_4620 := 30 downto 0 do
  begin
    U2823_0687(Players_3F0E[P].X, Players_3F0E[P].Y, g_4620, g_4620, BackBuf_E49A);
    U2823_0687(Players_3F0E[P].X + 1, Players_3F0E[P].Y, g_4620, g_4620, BackBuf_E49A);
  end;
  NoSound;
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  Players_3F0E[P].X := Players_3F0E[P].X + 11;
  Players_3F0E[P].Y := Players_3F0E[P].Y + 31;
  for Color := 1 to g_46B4 do
    U0098_07A3(Color);
  U0098_05A9(P + 19, BackBuf_E49A);
  U0098_0579($82, $9F, BackBuf_E49A);
end;

{#U1B27_09EF}
procedure U1B27_09EF(N: Integer; var A: TPaths);
var
  J, I, K, L, C, U1, U2, U3: Integer;
begin
  for I := 1 to N do
  begin
    if g_E788 <> 0 then Sound(Random(500) + 100);
    NoSound;
    C := U2823_0BFF(A[1, I].X, A[1, I].Y);
    if (C >= 20) and (C <= 29) then
      U26A9_0004(Random(3) + 1, 0, Players_3F0E[C - 19]);
    U2823_0BB6(A[1, I].X, A[1, I].Y, Random(14) + 1);
  end;
  for J := 2 to 5 do
    for I := 1 to N do
    begin
      if g_E788 <> 0 then Sound(Random(500 * J) + 100);
      NoSound;
      C := U2823_0BFF(A[J, I].X, A[J, I].Y);
      if (C >= 20) and (C <= 29) then
        U26A9_0004(Random(3) + 1, 0, Players_3F0E[C - 19]);
      U2823_0BB6(A[J, I].X, A[J, I].Y, Random(14) + 1);
      U2823_0BD8(A[J - 1, I].X, A[J - 1, I].Y, BackBuf_E49A);
    end;
  for I := 1 to N do
    U2823_0BD8(A[5, I].X, A[5, I].Y, BackBuf_E49A);
end;

{ debris variant: paint the paths with random colours 201..214 (202 -> 2) }
{#U1B27_0C6F}
procedure U1B27_0C6F(N: Integer; var A: TPaths);
var
  J, I, K, L, C, T, U1, U2, Col: Integer;
begin
  for J := 1 to 5 do
    for I := 1 to N do
    begin
      if g_E788 <> 0 then Sound(Random(500 * J) + 100);
      NoSound;
      C := U2823_0BFF(A[J, I].X, A[J, I].Y);
      T := C - 19;
      if (C >= 20) and (C <= 29) then
        U26A9_0004(Random(3) + 1, 0, Players_3F0E[T]);
      Col := Random(14) + 201;
      if Col = 202 then Col := 2;
      U2823_0BB6(A[J, I].X, A[J, I].Y, Col);
    end;
end;

{ random debris bursts around the tank }
{#U1B27_0DAB}
procedure U1B27_0DAB(P, Kind: Integer);
var
  J, I, K, Len, Dir, R, U1, U2: Integer;
begin
  U2823_0C20(0, 16, PalPtr_DE7C);
  SetPalBlock(200, 16, PalPtr_DE7C);
  FillChar(Paths_9FC8, SizeOf(Paths_9FC8), 0);
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
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y - Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X;
          end;
        end;
      2:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y + Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X;
          end;
        end;
      3:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].X := Random(R);
            Paths_9FC8[J, I].Y := Trunc(Random(Paths_9FC8[J, I].X + 10) - Paths_9FC8[J, I].X / 2 - 5);
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y - Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X;
          end;
        end;
      4:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].X := Random(R);
            Paths_9FC8[J, I].Y := Trunc(Random(Paths_9FC8[J, I].X + 10) - Paths_9FC8[J, I].X / 2 - 5);
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y - Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].X := Players_3F0E[P].X - Paths_9FC8[J, I].X;
          end;
        end;
      5:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X + Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y - Paths_9FC8[J, I].Y;
          end;
        end;
      6:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X - Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y - Paths_9FC8[J, I].Y;
          end;
        end;
      7:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X + Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y + Paths_9FC8[J, I].Y;
          end;
        end;
      8:
        for J := 1 to 5 do
        begin
          R := 10 * J;
          for I := 1 to Len do
          begin
            Paths_9FC8[J, I].Y := Random(R);
            Paths_9FC8[J, I].X := Trunc(Random(Paths_9FC8[J, I].Y + 10) - Paths_9FC8[J, I].Y / 2 - 5);
            Paths_9FC8[J, I].X := Players_3F0E[P].X + Paths_9FC8[J, I].X - Paths_9FC8[J, I].Y;
            Paths_9FC8[J, I].Y := Players_3F0E[P].Y + Paths_9FC8[J, I].Y;
          end;
        end;
    end;
    for J := 1 to 5 do
      for I := 1 to Len do
      begin
        if Paths_9FC8[J, I].X > 309 then Paths_9FC8[J, I].X := 618 - Paths_9FC8[J, I].X;
        if Paths_9FC8[J, I].Y > 189 then Paths_9FC8[J, I].Y := 378 - Paths_9FC8[J, I].Y;
        if Paths_9FC8[J, I].Y < 31 then Paths_9FC8[J, I].Y := 62 - Paths_9FC8[J, I].Y;
        if Paths_9FC8[J, I].X < 11 then Paths_9FC8[J, I].X := 22 - Paths_9FC8[J, I].X;
      end;
    case Kind of
      0: U1B27_09EF(Len, Paths_9FC8);
      1: U1B27_0C6F(Len, Paths_9FC8);
    end;
  end;
  for R := 1 to g_46B4 do
    U0098_07A3(R);
  U0098_08C2(P);
  U0098_0579($C9, $DC, BackBuf_E49A);
end;

{ "funky bomb" style: 11 fireballs at once, each ending in a fireball }
{#U1B27_1B69}
procedure U1B27_1B69(P: Integer);
var
  Color, X, Y, L: Integer;
  PX, PY, VX, VY: array[0..10] of Real;
  Done: array[0..11] of Boolean;   { one more than needed (frame layout) }
begin
  Color := P + 19;
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 130, Trunc((1 - g_4620 / 4) * 63), 0, 0);
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 140, 0, Trunc((1 - g_4620 / 4) * 63), 0);
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 4 do
    SetPalRGB(g_4620 + 150, 0, 0, Trunc((1 - g_4620 / 4) * 63));
  if g_E788 <> 0 then Sound(Random(500));
  U1B27_0000(Color);
  for g_4620 := 0 to 100 do
  begin
    if g_E788 <> 0 then Sound(Random(500));
    U1B27_0000(Color);
    Delay(g_E79A);
  end;
  NoSound;
  SetViewPort(11, 31, 309, 189, True);
  U2823_0006;
  Players_3F0E[P].X := Players_3F0E[P].X - 11;
  Players_3F0E[P].Y := Players_3F0E[P].Y - 31;
  for g_4620 := 0 to 10 do
  begin
    if g_E788 <> 0 then Sound(Random(500));
    PX[g_4620] := Players_3F0E[P].X;
    PY[g_4620] := Players_3F0E[P].Y;
    VX[g_4620] := 0.5 - Random;
    VY[g_4620] := 0.1 - Random;
    Done[g_4620] := False;
  end;
  repeat
    g_462F := 1;
    U1B27_0000(Color);
    for g_4620 := 0 to 10 do
      if not Done[g_4620] then
      begin
        PX[g_4620] := PX[g_4620] + VX[g_4620];
        PY[g_4620] := PY[g_4620] + VY[g_4620];
        VY[g_4620] := VY[g_4620] + 0.007;
        VX[g_4620] := VX[g_4620] + g_E778 / 5000;
        X := Trunc(PX[g_4620]);
        Y := Trunc(PY[g_4620]);
        g_462F := 0;
        g_462A := GetPixel(X, Y);
        if (g_462A = 2) or (g_462A = 13) then Done[g_4620] := True;
        if (g_462A >= 20) and (g_462A <= 29) then
          U26A9_0004(Random(10) + 10, 0, Players_3F0E[g_462A - 19]);
        if (X > 298) or (X < 0) or (Y > 158) or (Y < 0) then Done[g_4620] := True;
        if g_E788 <> 0 then Sound(Trunc((Players_3F0E[P].Y - Y) * 5 + 1500));
        PutPixel(X, Y, Color);
        if Done[g_4620] then
        begin
          DebX_3E9E[g_4620] := X;
          DebY_3EB4[g_4620] := Y;
        end;
      end;
  until g_462F <> 0;
  for g_4620 := 0 to 10 do
  begin
    g_4624 := DebX_3E9E[g_4620];
    g_4626 := DebY_3EB4[g_4620];
    g_4622 := (Trunc(Random(3)) + 3) * 10;
    g_462A := Random(10);
    case g_462A of
      0, 1, 2: g_462C := 1;
      3, 4, 5: g_462C := 2;
      6, 7: g_462C := 3;
      8: g_462C := 4;
      9: g_462C := 5;
    end;
    for g_4628 := 0 to g_462C * 4 do
    begin
      if g_E788 <> 0 then Sound(Random(2500));
      U1B27_0000(Color);
      g_3EE0 := g_4622 + 100 + g_4628 div g_462C;
      U2823_0351(g_4624, g_4626, g_4628, g_4628, g_3EE0);
      U2823_0351(g_4624 + 1, g_4626, g_4628, g_4628, g_3EE0);
      Delay(g_E79A);
    end;
    for g_4628 := g_462C * 4 downto 0 do
    begin
      if g_E788 <> 0 then Sound(Random(2500));
      U1B27_0000(Color);
      U2823_0687(g_4624, g_4626, g_4628, g_4628, BackBuf_E49A);
      U2823_0687(g_4624 + 1, g_4626, g_4628, g_4628, BackBuf_E49A);
      Delay(g_E79A);
    end;
  end;
  g_4628 := 0;
  for g_4620 := 0 to 4 do
    for g_4622 := 3 to 5 do
    begin
      Inc(g_4628);
      g_3EE0 := 10 * g_4622 + 100 + g_4620;
      U2823_0351(Players_3F0E[P].X, Players_3F0E[P].Y, g_4628, g_4628, g_3EE0);
      for g_462A := 0 to 4 do
      begin
        if g_E788 <> 0 then Sound(Random(1300 - 40 * g_4628));
        U1B27_0000(Color);
      end;
      U2823_0351(Players_3F0E[P].X, Players_3F0E[P].Y, g_4628 + 1, g_4628 + 1, g_3EE0);
      for g_462A := 0 to 4 do
      begin
        if g_E788 <> 0 then Sound(Random(1300 - 40 * g_4628));
        U1B27_0000(Color);
      end;
      Delay(g_E79A);
      Inc(g_4628);
    end;
  g_4628 := 16;
  for g_4620 := 4 downto 0 do
    for g_4622 := 4 - g_4620 downto 0 do
    begin
      Dec(g_4628);
      if g_E788 <> 0 then Sound(Random(200));
      SetPalRGB(Color, g_4628 * Random(63) div 16, g_4628 * Random(63) div 16,
        g_4628 * Random(63) div 16);
      L := 63 * g_4622 div 4;
      SetPalRGB(g_4620 + 130, L, 0, 0);
      NoSound;
      SetPalRGB(g_4620 + 140, 0, L, 0);
      SetPalRGB(g_4620 + 150, 0, 0, L);
      Delay(g_E79A);
    end;
  for g_4620 := 30 downto 0 do
  begin
    U2823_0687(Players_3F0E[P].X, Players_3F0E[P].Y, g_4620, g_4620, BackBuf_E49A);
    U2823_0687(Players_3F0E[P].X + 1, Players_3F0E[P].Y, g_4620, g_4620, BackBuf_E49A);
  end;
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  Players_3F0E[P].X := Players_3F0E[P].X + 11;
  Players_3F0E[P].Y := Players_3F0E[P].Y + 31;
  for Color := 1 to g_46B4 do
    U0098_07A3(Color);
  U0098_05A9(P + 19, BackBuf_E49A);
  U0098_0579($82, $9A, BackBuf_E49A);
end;

{ sparks: 30..59 rings of random dirt pixels (colour 2) around the tank }
{#U1B27_25D9}
procedure U1B27_25D9(P: Integer);
var
  R, U1, U2, K, I, U3: Integer;
begin
  for g_462A := 1 to Random(30) + 30 do
  begin
    R := 10 * g_462A;
    for I := 1 to Random(400) do
    begin
      Paths_9FC8[1, I].Y := Random(R);
      Paths_9FC8[1, I].X := Trunc(Random(Paths_9FC8[1, I].Y + 10) - Paths_9FC8[1, I].Y / 2 - 5);
      Paths_9FC8[1, I].Y := Players_3F0E[P].Y - Paths_9FC8[1, I].Y;
      Paths_9FC8[1, I].X := Players_3F0E[P].X + Paths_9FC8[1, I].X;
      while (Paths_9FC8[1, I].X > 309) or (Paths_9FC8[1, I].Y < 31) or
        (Paths_9FC8[1, I].X < 11) or (Paths_9FC8[1, I].Y > 189) do
      begin
        if Paths_9FC8[1, I].X > 309 then Paths_9FC8[1, I].X := 618 - Paths_9FC8[1, I].X;
        if Paths_9FC8[1, I].Y > 189 then Paths_9FC8[1, I].Y := 378 - Paths_9FC8[1, I].Y;
        if Paths_9FC8[1, I].Y < 31 then Paths_9FC8[1, I].Y := 62 - Paths_9FC8[1, I].Y;
        if Paths_9FC8[1, I].X < 11 then Paths_9FC8[1, I].X := 22 - Paths_9FC8[1, I].X;
      end;
      U2823_0BB6(Paths_9FC8[1, I].X, Paths_9FC8[1, I].Y, 2);
      if g_E788 <> 0 then Sound(100 * g_462A + Random(1000));
    end;
  end;
  NoSound;
  for K := 1 to g_46B4 do
    U0098_07A3(K);
  U0098_08C2(P);
end;

{ the tank's men count up to 100 and back down to 0, then it is gone }
{#U1B27_2840}
procedure U1B27_2840(P: Integer);
var
  U1, U2, U3, U4, U5, U6, I, U7, U8: Integer;
begin
  U0098_07A3(P);
  for I := 0 to 100 do
  begin
    U26A9_0175(I, Players_3F0E[P]);
    if g_E788 <> 0 then Sound(100 * I + 2000);
    Delay(g_E79A);
  end;
  for I := 100 downto 0 do
  begin
    U26A9_0175(I, Players_3F0E[P]);
    if g_E788 <> 0 then Sound(100 * I + 2000);
    Delay(g_E79A);
  end;
  NoSound;
  U26A9_0175(-1, Players_3F0E[P]);
  U0098_08C2(P);
end;

{ like 2840, then 1..4 explosions of weapon 1..4 at the tank's position
  (fired by the dummy player 0) }
{#U1B27_2902}
procedure U1B27_2902(P: Integer);
var
  U1, U2, U3, U4, U5, U6, I, J, K, D: Integer;
begin
  D := g_E79A;
  if Random(2) = 1 then D := 0;
  U0098_07A3(P);
  for J := 1 to 3 do
    for I := 0 to 100 do
    begin
      U26A9_0175(I, Players_3F0E[P]);
      if g_E788 <> 0 then Sound(100 * I + 2000);
      Delay(D);
    end;
  for I := 100 downto 1 do
  begin
    U26A9_0175(I, Players_3F0E[P]);
    if g_E788 <> 0 then Sound(100 * I + 2000);
    Delay(D);
  end;
  Players_3F0E[0] := Players_3F0E[P];
  g_4628 := Random(10);
  case g_4628 of
    0..1: g_462A := 1;
    2..4: g_462A := 2;
    5..7: g_462A := 3;
    8..9: g_462A := 4;
  end;
  for K := 1 to g_462A do
  begin
    Players_3F0E[0].Weapon := K;
    U1DD4_0108(0, Players_3F0E[0].X, Players_3F0E[0].Y, 2);
    for I := 1 to g_46B4 do
      U0098_07A3(I);
  end;
  NoSound;
  U26A9_0175(-1, Players_3F0E[P]);
end;

end.
