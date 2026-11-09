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
    TODO: belong into U2823 (PalBlockHook / RGBHook) }
  TPalBlockProc = procedure(Start, Count: Word; Buf: Pointer);
  TPalRGBProc = procedure(Index, R, G, B: Word);

var
  SetPalBlock: TPalBlockProc absolute PalBlockHook;
  SetPalRGB: TPalRGBProc absolute RGBHook;

procedure WeaponImpact(P: Integer; X, Y: Real; Kind: Integer);
procedure LightningStrike(Kind: Integer);

implementation

uses
  U1F69, U0098;

{ impact of player P's current weapon at (X, Y); Kind = colour found there }
{#U1DD4_0108}
procedure WeaponImpact(P: Integer; X, Y: Real; Kind: Integer);
var
  I, J, K, TX, TY, M, Step, XI, YI, Dmg: Integer;
  D: Real;
begin
  SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  if Players[P].Weapon = 0 then
  begin
    if (Kind >= 20) and (Kind <= 29) then
    begin
      Dmg := 5;
      M := ApplyDamage(Dmg, 0, Players[Kind - 19]) * 10;
      if Players[P].Team <> Players[Kind - 19].Team then
        AddScore(M, Players[P]);
    end;
  end
  else if Players[P].Weapon in [1, 2, 3, 4, 7, 11] then
  begin
    case Players[P].Weapon of
      1: BlastSize := 10;
      2, 7: BlastSize := 15;
      3: BlastSize := 30;
      4: BlastSize := 60;
      11: BlastSize := 2;
    end;
    Step := 63 div BlastSize;
    FillChar(BlastPal, SizeOf(BlastPal), 0);
    for I := 0 to BlastSize do
      BlastPal[I].R := (BlastSize - I) * Step;
    SetPalBlock(130, BlastSize + 1, @BlastPal);
    SetViewPort(11, 31, 309, 189, True);
    FetchClipWindow;
    X := X - 11;
    Y := Y - 31;
    XI := Trunc(X);
    YI := Trunc(Y);
    for I := 0 to BlastSize do
    begin
      if SoundOn <> 0 then Sound(Trunc(Random(500)) + 500);
      DrawEllipse(XI + 1, YI, I, I, I + 130);
      DrawEllipse(XI - 1, YI, I, I, I + 130);
      DrawEllipse(XI, YI, I, I, I + 130);
    end;
    for I := 0 to BlastSize do
    begin
      for J := I to BlastSize do
      begin
        if SoundOn <> 0 then Sound(Trunc(Random(500)) + 250);
        BlastPal[J].R := (BlastSize - J + I) * Step;
      end;
      SetPalBlock(130, BlastSize + 1, @BlastPal);
      Delay(ExplodeSpeed);
    end;
    for I := 0 to BlastSize do
    begin
      for J := I downto 0 do
      begin
        if SoundOn <> 0 then Sound(Trunc(Random(500) + 3));
        BlastPal[J].R := (BlastSize - I + J) * Step;
      end;
      SetPalBlock(130, BlastSize + 1, @BlastPal);
      Delay(ExplodeSpeed);
    end;
    for I := 0 to BlastSize do
    begin
      for J := I to BlastSize do
      begin
        if SoundOn <> 0 then Sound(Trunc(Random(250) + 3));
        BlastPal[J].R := (J - I) * Step;
      end;
      SetPalBlock(130, BlastSize + 1, @BlastPal);
      Delay(ExplodeSpeed);
    end;
    NoSound;
    for I := 0 to BlastSize do
    begin
      CopyEllipse(XI + 1, YI, I, I, BackBuf);
      CopyEllipse(XI - 1, YI, I, I, BackBuf);
      CopyEllipse(XI, YI, I, I, BackBuf);
    end;
    if (Kind >= 20) and (Kind <= 29) then
    begin
      Dmg := 200;
      M := ApplyDamage(Dmg, 0, Players[Kind - 19]) * 10;
      if Players[P].Team <> Players[Kind - 19].Team then
        AddScore(M, Players[P]);
    end;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
    X := X + 11;
    Y := Y + 31;
    for I := 1 to NumPlayers do
      if Players[I].f23 <> 0 then
      begin
        Dmg := 0;
        M := Players[I].Men;
        TX := Players[I].X;
        TY := Players[I].Y;
        D := VecLength(X - TX, Y - TY);
        if D <= BlastSize * 1.5 then Dmg := Dmg + Trunc(BlastSize * 1.8 - D);
        if D < BlastSize then Dmg := Dmg + 10 + Trunc(BlastSize * 1.8 - D) * 2;
        if D < BlastSize * 0.7 then Dmg := Dmg + 150;
        M := ApplyDamage(Dmg, 0, Players[I]) * 10;
        if Players[I].Team <> Players[P].Team then
          AddScore(M, Players[P]);
      end;
  end
  else if Players[P].Weapon in [5..10] then
  begin
    if Kind in [20..29] then
    begin
      Dmg := Random(Players[P].Weapon * 6) + 1;
      M := ApplyDamage(Dmg, 0, Players[Kind - 19]) * 10;
      if Players[P].Team <> Players[Kind - 19].Team then
        AddScore(M, Players[P]);
      if SoundOn <> 0 then
      begin
        for I := 1000 to 30000 do Sound(I);
        for I := 30000 downto 1000 do Sound(I);
        NoSound;
      end;
    end
    else if Kind = 2 then
    begin
      { diggers }
      case Players[P].Weapon of
        5: BlastSize := 4;
        6: BlastSize := 4;
        7: BlastSize := 8;
        8: BlastSize := 8;
        9: BlastSize := 20;
        10: BlastSize := 20;
      end;
      TX := Trunc(X);
      TY := Trunc(Y);
      DoneFlag := 0;
      repeat
        if (PixelAt(TX, TY + 1) = 2) or (PixelAt(TX, TY - 1) = 2) or
          (PixelAt(TX + 1, TY) = 2) or (PixelAt(TX - 1, TY) = 2) then
          DoneFlag := 1
        else
          Inc(TY);
      until DoneFlag <> 0;
      for I := 1 to BlastSize do
      begin
        DiggerPts[I].X := TX;
        DiggerPts[I].Y := TY;
      end;
      repeat
        for I := 1 to BlastSize do
        begin
          FillChar(DiggerDirs, 8, 0);
          K := 0;
          for J := 1 to 8 do
            if Odd(J) then
            begin
              case J of
                1: if PixelAt(DiggerPts[I].X, DiggerPts[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 1;
                   end;
                3: if PixelAt(DiggerPts[I].X + 1, DiggerPts[I].Y) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 3;
                   end;
                5: if PixelAt(DiggerPts[I].X, DiggerPts[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 5;
                   end;
                7: if PixelAt(DiggerPts[I].X - 1, DiggerPts[I].Y) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 7;
                   end;
              end;
            end
            else if Players[P].Weapon in [6, 8, 10] then
            begin
              case J of
                2: if PixelAt(DiggerPts[I].X + 1, DiggerPts[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 2;
                   end;
                4: if PixelAt(DiggerPts[I].X + 1, DiggerPts[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 4;
                   end;
                6: if PixelAt(DiggerPts[I].X - 1, DiggerPts[I].Y + 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 6;
                   end;
                8: if PixelAt(DiggerPts[I].X - 1, DiggerPts[I].Y - 1) = 2 then
                   begin
                     Inc(K);
                     DiggerDirs[K] := 8;
                   end;
              end;
            end;
          if K > 0 then
          begin
            M := Random(K) + 1;
            case DiggerDirs[M] of
              1: Dec(DiggerPts[I].Y);
              3: Inc(DiggerPts[I].X);
              5: Inc(DiggerPts[I].Y);
              7: Dec(DiggerPts[I].X);
              2: begin
                   Dec(DiggerPts[I].Y);
                   Inc(DiggerPts[I].X);
                 end;
              4: begin
                   Inc(DiggerPts[I].X);
                   Inc(DiggerPts[I].Y);
                 end;
              6: begin
                   Inc(DiggerPts[I].Y);
                   Dec(DiggerPts[I].X);
                 end;
              8: begin
                   Dec(DiggerPts[I].X);
                   Dec(DiggerPts[I].Y);
                 end;
            end;
            if SoundOn <> 0 then Sound(Random(500) + 1);
            CopyPixel(DiggerPts[I].X, DiggerPts[I].Y, BackBuf);
          end
          else
          begin
            DiggerPts[I].X := 0;
            DiggerPts[I].Y := 0;
          end;
        end;
        K := 0;
        for I := 1 to BlastSize do
          if DiggerPts[I].X = 0 then
          begin
            Inc(K);
            TmpC := 0;
            repeat
              Inc(TmpC);
            until (TmpC = 21) or ((TmpC <> I) and (DiggerPts[TmpC].X <> 0));
            if TmpC = 21 then TmpC := I;
            DiggerPts[I].X := DiggerPts[TmpC].X;
            DiggerPts[I].Y := DiggerPts[TmpC].Y;
          end;
        if K = BlastSize then BlastSize := 0;
      until BlastSize = 0;
      NoSound;
    end;
  end
  else if Players[P].Weapon in [12] then
  begin
    DrawPlusMark(Trunc(X), Trunc(Y));
    for I := 1 to 100 do
    begin
      SetPalRGB(19, Random(64), 0, 0);
      if SoundOn <> 0 then Sound(Random(1000) + 3000);
      Delay(ExplodeSpeed);
    end;
    for I := 1 to 100 do
    begin
      SetPalRGB(19, Random(64), 0, 0);
      SetPalRGB(2, Random(32) + 32, Random(32) + 32, Random(32) + 32);
      if SoundOn <> 0 then Sound(Random(1000) + 3500);
      Delay(ExplodeSpeed);
    end;
    ErasePlusMark(Trunc(X), Trunc(Y), BackBuf);
    NoSound;
    SetPalRGB(19, 63, 63, 63);
    SetPalRGB(2, 0, 42, 0);
    DropDirt(FallList, BackBuf);
  end
  else if Players[P].Weapon in [13..16] then
  begin
    case Players[P].Weapon of
      13: BlastSize := 10;
      14: BlastSize := 15;
      15: BlastSize := 30;
      16: BlastSize := 60;
    end;
    SetColor(2);
    SetViewPort(11, 31, 309, 189, True);
    X := X - 11;
    Y := Y - 31;
    for I := 0 to BlastSize do
    begin
      Circle(Trunc(X + 1), Trunc(Y), I);
      Circle(Trunc(X - 1), Trunc(Y), I);
      Circle(Trunc(X), Trunc(Y), I);
    end;
    X := X + 11;
    Y := Y + 31;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
  end
  else if Players[P].Weapon in [17] then
  begin
    M := Random(100) + 300;
    TmpC := Random(8) + 3;
    SetViewPort(11, 31, 309, 189, True);
    X := X - 11;
    Y := Y - 31;
    for I := 1 to TmpC do
      for J := 1 to M do
      begin
        Paths[I, J].Y := Random(20 * I);
        Paths[I, J].X := Trunc(Random(Paths[I, J].Y + 1) - Paths[I, J].Y / 2);
        Paths[I, J].X := Paths[I, J].X + Trunc(X);
        Paths[I, J].Y := Trunc(Y) - Paths[I, J].Y + 2;
      end;
    for I := 1 to TmpC do
      for J := 1 to M do
      begin
        PutPixel(Paths[I, J].X, Paths[I, J].Y, 2);
        if SoundOn <> 0 then Sound(100 * I + Random(200));
      end;
    NoSound;
    X := X + 11;
    Y := Y + 31;
    SetViewPort(0, 0, GetMaxX, GetMaxY, True);
    if Random * 100 < CrumblePct * 2 then
      DropDirt(FallList, BackBuf);
  end;
end;

{ lightning strike (Kind = 0) }
{#U1DD4_1562}
procedure LightningStrike(Kind: Integer);
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
            HitColor := PixelAt(Line[Y, B], Y);
            if (HitColor >= 20) and (HitColor <= 29) then
            begin
              ApplyDamage(3, 0, Players[HitColor - 19]);
              DrawTank(HitColor - 19);
            end;
            PlotPixel(Line[Y, B], Y, 200);
            PlotPixel(Line[Y, B] + 1, Y, 201);
            PlotPixel(Line[Y, B] - 1, Y, 201);
            Off := Off + Random(7) - 3;
            Line[Y, not B] := X1 + Trunc(Slope * Y + Off * ((Y - 189) / 189));
          end;
          for Y := 31 to 189 do
          begin
            CopyPixel(Line[Y, B], Y, BackBuf);
            CopyPixel(Line[Y, B] + 1, Y, BackBuf);
            CopyPixel(Line[Y, B] - 1, Y, BackBuf);
            if SoundOn <> 0 then Sound(Random(600) + 600);
          end;
          B := not B;
          NoSound;
        end;
        Players[0].Weapon := N div 3;
        if Players[0].Weapon = 0 then Players[0].Weapon := 11;
        WeaponImpact(0, X2, 189, 0);
      end;
  end;
  for Y := 1 to NumPlayers do
    DrawTank(Y);
  if CrumblePct > 0 then TryCrumbleDirt;
  if TanksFall <> 0 then DropTanks;
end;

end.
