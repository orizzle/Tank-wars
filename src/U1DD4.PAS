{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1DD4;

{ Weapon impact effects (explosions, diggers, napalm-ish circles, ...) and
  the lightning strike. }

interface

uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

type
  { palette procedure variables installed by U2823 (driver dependent);
    TODO: belong into U2823 (g_E7C4 / g_E7C8) }
  TPalBlockProc = procedure(Start, Count: Word; Buf: Pointer);
  TPalRGBProc = procedure(Index, R, G, B: Word);

var
  SetPalBlock: TPalBlockProc absolute g_E7C4;
  SetPalRGB: TPalRGBProc absolute g_E7C8;

procedure U1DD4_0108(P: Integer; X, Y: Real; Kind: Integer);
procedure U1DD4_1562(Kind: Integer);

implementation

uses
  U1F69, U0098;

{ impact of player P's current weapon at (X, Y); Kind = colour found there }
{#U1DD4_0108}
procedure U1DD4_0108(P: Integer; X, Y: Real; Kind: Integer);
var
  I, J, K, TX, TY, M, Step, XI, YI, Dmg: Integer;
  D: Real;
begin
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  if Players_3F0E[P].Weapon = 0 then
  begin
    if (Kind >= 20) and (Kind <= 29) then
    begin
      Dmg := 5;
      M := U26A9_0004(Dmg, 0, Players_3F0E[Kind - 19]) * 10;
      if Players_3F0E[P].Team <> Players_3F0E[Kind - 19].Team then
        U26A9_018F(M, Players_3F0E[P]);
    end;
  end
  else if Players_3F0E[P].Weapon in [1, 2, 3, 4, 7, 11] then
  begin
    case Players_3F0E[P].Weapon of
      1: g_46B2 := 10;
      2, 7: g_46B2 := 15;
      3: g_46B2 := 30;
      4: g_46B2 := 60;
      11: g_46B2 := 2;
    end;
    Step := 63 div g_46B2;
    FillChar(Pal_E49E, SizeOf(Pal_E49E), 0);
    for I := 0 to g_46B2 do
      Pal_E49E[I].R := (g_46B2 - I) * Step;
    SetPalBlock(130, g_46B2 + 1, @Pal_E49E);
    SetViewPort(11, 31, 309, 189, True);
    U2823_0006;
    X := X - 11;
    Y := Y - 31;
    XI := Trunc(X);
    YI := Trunc(Y);
    for I := 0 to g_46B2 do
    begin
      if g_E788 <> 0 then Sound(Trunc(Random(500)) + 500);
      U2823_0351(XI + 1, YI, I, I, I + 130);
      U2823_0351(XI - 1, YI, I, I, I + 130);
      U2823_0351(XI, YI, I, I, I + 130);
    end;
    for I := 0 to g_46B2 do
    begin
      for J := I to g_46B2 do
      begin
        if g_E788 <> 0 then Sound(Trunc(Random(500)) + 250);
        Pal_E49E[J].R := (g_46B2 - J + I) * Step;
      end;
      SetPalBlock(130, g_46B2 + 1, @Pal_E49E);
      Delay(g_E79A);
    end;
    for I := 0 to g_46B2 do
    begin
      for J := I downto 0 do
      begin
        if g_E788 <> 0 then Sound(Trunc(Random(500) + 3));
        Pal_E49E[J].R := (g_46B2 - I + J) * Step;
      end;
      SetPalBlock(130, g_46B2 + 1, @Pal_E49E);
      Delay(g_E79A);
    end;
    for I := 0 to g_46B2 do
    begin
      for J := I to g_46B2 do
      begin
        if g_E788 <> 0 then Sound(Trunc(Random(250) + 3));
        Pal_E49E[J].R := (J - I) * Step;
      end;
      SetPalBlock(130, g_46B2 + 1, @Pal_E49E);
      Delay(g_E79A);
    end;
    NoSound;
    for I := 0 to g_46B2 do
    begin
      U2823_0687(XI + 1, YI, I, I, BackBuf_E49A);
      U2823_0687(XI - 1, YI, I, I, BackBuf_E49A);
      U2823_0687(XI, YI, I, I, BackBuf_E49A);
    end;
    if (Kind >= 20) and (Kind <= 29) then
    begin
      Dmg := 200;
      M := U26A9_0004(Dmg, 0, Players_3F0E[Kind - 19]) * 10;
      if Players_3F0E[P].Team <> Players_3F0E[Kind - 19].Team then
        U26A9_018F(M, Players_3F0E[P]);
    end;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
    X := X + 11;
    Y := Y + 31;
    for I := 1 to g_46B4 do
      if Players_3F0E[I].f23 <> 0 then
      begin
        Dmg := 0;
        M := Players_3F0E[I].Men;
        TX := Players_3F0E[I].X;
        TY := Players_3F0E[I].Y;
        D := U2918_008F(X - TX, Y - TY);
        if D <= g_46B2 * 1.5 then Dmg := Dmg + Trunc(g_46B2 * 1.8 - D);
        if D < g_46B2 then Dmg := Dmg + 10 + Trunc(g_46B2 * 1.8 - D) * 2;
        if D < g_46B2 * 0.7 then Dmg := Dmg + 150;
        M := U26A9_0004(Dmg, 0, Players_3F0E[I]) * 10;
        if Players_3F0E[I].Team <> Players_3F0E[P].Team then
          U26A9_018F(M, Players_3F0E[P]);
      end;
  end
  else if Players_3F0E[P].Weapon in [5..10] then
  begin
    if Kind in [20..29] then
    begin
      Dmg := Random(Players_3F0E[P].Weapon * 6) + 1;
      M := U26A9_0004(Dmg, 0, Players_3F0E[Kind - 19]) * 10;
      if Players_3F0E[P].Team <> Players_3F0E[Kind - 19].Team then
        U26A9_018F(M, Players_3F0E[P]);
      if g_E788 <> 0 then
      begin
        for I := 1000 to 30000 do Sound(I);
        for I := 30000 downto 1000 do Sound(I);
        NoSound;
      end;
    end
    else if Kind = 2 then
    begin
      { diggers }
      case Players_3F0E[P].Weapon of
        5: g_46B2 := 4;
        6: g_46B2 := 4;
        7: g_46B2 := 8;
        8: g_46B2 := 8;
        9: g_46B2 := 20;
        10: g_46B2 := 20;
      end;
      TX := Trunc(X);
      TY := Trunc(Y);
      g_462F := 0;
      repeat
        if (U2823_0BFF(TX, TY + 1) = 2) or (U2823_0BFF(TX, TY - 1) = 2) or
          (U2823_0BFF(TX + 1, TY) = 2) or (U2823_0BFF(TX - 1, TY) = 2) then
          g_462F := 1
        else
          Inc(TY);
      until g_462F <> 0;
      for I := 1 to g_46B2 do
      begin
        Pts_E6FA[I].X := TX;
        Pts_E6FA[I].Y := TY;
      end;
      repeat
        for I := 1 to g_46B2 do
        begin
          FillChar(Dirs_DE48, 8, 0);
          K := 0;
          for J := 1 to 8 do
            if Odd(J) then
            begin
              case J of
                1: if U2823_0BFF(Pts_E6FA[I].X, Pts_E6FA[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 1;
                   end;
                3: if U2823_0BFF(Pts_E6FA[I].X + 1, Pts_E6FA[I].Y) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 3;
                   end;
                5: if U2823_0BFF(Pts_E6FA[I].X, Pts_E6FA[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 5;
                   end;
                7: if U2823_0BFF(Pts_E6FA[I].X - 1, Pts_E6FA[I].Y) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 7;
                   end;
              end;
            end
            else if Players_3F0E[P].Weapon in [6, 8, 10] then
            begin
              case J of
                2: if U2823_0BFF(Pts_E6FA[I].X + 1, Pts_E6FA[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 2;
                   end;
                4: if U2823_0BFF(Pts_E6FA[I].X + 1, Pts_E6FA[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 4;
                   end;
                6: if U2823_0BFF(Pts_E6FA[I].X - 1, Pts_E6FA[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 6;
                   end;
                8: if U2823_0BFF(Pts_E6FA[I].X - 1, Pts_E6FA[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     Dirs_DE48[K] := 8;
                   end;
              end;
            end;
          if K > 0 then
          begin
            M := Random(K) + 1;
            case Dirs_DE48[M] of
              1: Dec(Pts_E6FA[I].Y);
              3: Inc(Pts_E6FA[I].X);
              5: Inc(Pts_E6FA[I].Y);
              7: Dec(Pts_E6FA[I].X);
              2: begin
                   Dec(Pts_E6FA[I].Y);
                   Inc(Pts_E6FA[I].X);
                 end;
              4: begin
                   Inc(Pts_E6FA[I].X);
                   Inc(Pts_E6FA[I].Y);
                 end;
              6: begin
                   Inc(Pts_E6FA[I].Y);
                   Dec(Pts_E6FA[I].X);
                 end;
              8: begin
                   Dec(Pts_E6FA[I].X);
                   Dec(Pts_E6FA[I].Y);
                 end;
            end;
            if g_E788 <> 0 then Sound(Random(500) + 1);
            U2823_0BD8(Pts_E6FA[I].X, Pts_E6FA[I].Y, BackBuf_E49A);
          end
          else
          begin
            Pts_E6FA[I].X := 0;
            Pts_E6FA[I].Y := 0;
          end;
        end;
        K := 0;
        for I := 1 to g_46B2 do
          if Pts_E6FA[I].X = 0 then
          begin
            Inc(K);
            g_462A := 0;
            repeat
              Inc(g_462A);
            until (g_462A = 21) or ((g_462A <> I) and (Pts_E6FA[g_462A].X <> 0));
            if g_462A = 21 then g_462A := I;
            Pts_E6FA[I].X := Pts_E6FA[g_462A].X;
            Pts_E6FA[I].Y := Pts_E6FA[g_462A].Y;
          end;
        if K = g_46B2 then g_46B2 := 0;
      until g_46B2 = 0;
      NoSound;
    end;
  end
  else if Players_3F0E[P].Weapon in [12] then
  begin
    U0098_03A8(Trunc(X), Trunc(Y));
    for I := 1 to 100 do
    begin
      SetPalRGB(19, Random(64), 0, 0);
      if g_E788 <> 0 then Sound(Random(1000) + 3000);
      Delay(g_E79A);
    end;
    for I := 1 to 100 do
    begin
      SetPalRGB(19, Random(64), 0, 0);
      SetPalRGB(2, Random(32) + 32, Random(32) + 32, Random(32) + 32);
      if g_E788 <> 0 then Sound(Random(1000) + 3500);
      Delay(g_E79A);
    end;
    U0098_03F4(Trunc(X), Trunc(Y), BackBuf_E49A);
    NoSound;
    SetPalRGB(19, 63, 63, 63);
    SetPalRGB(2, 0, 42, 0);
    U0098_047B(PalPtr_DE7C, BackBuf_E49A);
  end
  else if Players_3F0E[P].Weapon in [13..16] then
  begin
    case Players_3F0E[P].Weapon of
      13: g_46B2 := 10;
      14: g_46B2 := 15;
      15: g_46B2 := 30;
      16: g_46B2 := 60;
    end;
    SetColor(2);
    SetViewPort(11, 31, 309, 189, True);
    X := X - 11;
    Y := Y - 31;
    for I := 0 to g_46B2 do
    begin
      Circle(Trunc(X + 1), Trunc(Y), I);
      Circle(Trunc(X - 1), Trunc(Y), I);
      Circle(Trunc(X), Trunc(Y), I);
    end;
    X := X + 11;
    Y := Y + 31;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  end
  else if Players_3F0E[P].Weapon in [17] then
  begin
    M := Random(100) + 300;
    g_462A := Random(8) + 3;
    SetViewPort(11, 31, 309, 189, True);
    X := X - 11;
    Y := Y - 31;
    for I := 1 to g_462A do
      for J := 1 to M do
      begin
        Paths_9FC8[I, J].Y := Random(20 * I);
        Paths_9FC8[I, J].X := Trunc(Random(Paths_9FC8[I, J].Y + 1) - Paths_9FC8[I, J].Y / 2);
        Paths_9FC8[I, J].X := Paths_9FC8[I, J].X + Trunc(X);
        Paths_9FC8[I, J].Y := Trunc(Y) - Paths_9FC8[I, J].Y + 2;
      end;
    for I := 1 to g_462A do
      for J := 1 to M do
      begin
        PutPixel(Paths_9FC8[I, J].X, Paths_9FC8[I, J].Y, 2);
        if g_E788 <> 0 then Sound(100 * I + Random(200));
      end;
    NoSound;
    X := X + 11;
    Y := Y + 31;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
    if Random * 100 < g_E77A * 2 then
      U0098_047B(PalPtr_DE7C, BackBuf_E49A);
  end;
end;

{ lightning strike (Kind = 0) }
{#U1DD4_1562}
procedure U1DD4_1562(Kind: Integer);
var
  Y, K, N, X1, U1, X2, U2: Integer;
  B, U3: Boolean;
  Line: array[30..189, Boolean] of Integer;
  Off: Integer;
  Slope: Real;
  U4, U5: Real;
begin
  case Kind of
    0:
      begin
        FillChar(Line, SizeOf(Line), 0);
        SetPalRGB(200, 63, 63, 63);
        SetPalRGB(201, 0, 0, 50);
        X1 := Random(300) + 10;
        X2 := Random(300) + 10;
        Off := 0;
        B := True;
        Slope := (X2 - X1) / 189;
        for Y := 31 to 189 do
        begin
          Off := Off + Random(7) - 3;
          Line[Y, B] := X1 + Trunc(Y * Slope + (Y - 189) * Off / 189);
        end;
        N := Random(8) + 1;
        for K := 1 to N do
        begin
          Off := 0;
          for Y := 31 to 189 do
          begin
            g_46B8 := U2823_0BFF(Line[Y, B], Y);
            if (g_46B8 >= 20) and (g_46B8 <= 29) then
            begin
              U26A9_0004(3, 0, Players_3F0E[g_46B8 - 19]);
              U0098_07A3(g_46B8 - 19);
            end;
            U2823_0BB6(Line[Y, B], Y, 200);
            U2823_0BB6(Line[Y, B] + 1, Y, 201);
            U2823_0BB6(Line[Y, B] - 1, Y, 201);
            Off := Off + Random(7) - 3;
            Line[Y, not B] := X1 + Trunc(Slope * Y + Off * ((Y - 189) / 189));
          end;
          for Y := 31 to 189 do
          begin
            U2823_0BD8(Line[Y, B], Y, BackBuf_E49A);
            U2823_0BD8(Line[Y, B] + 1, Y, BackBuf_E49A);
            U2823_0BD8(Line[Y, B] - 1, Y, BackBuf_E49A);
            if g_E788 <> 0 then Sound(Random(600) + 600);
          end;
          B := not B;
          NoSound;
        end;
        Players_3F0E[0].Weapon := N div 3;
        if Players_3F0E[0].Weapon = 0 then Players_3F0E[0].Weapon := 11;
        U1DD4_0108(0, X2, 189, 0);
      end;
  end;
  for Y := 1 to g_46B4 do
    U0098_07A3(Y);
  if g_E77A > 0 then U1F69_03C7;
  if g_E78D <> 0 then U1F69_0024;
end;

end.
