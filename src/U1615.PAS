{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1615;

{ Projectile flight: shot animation, guidance (MIRV / Horizontal / Vertical),
  impact handling. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

type
  TSetRGBProc = procedure(Color, R, G, B: Integer);
  TVGAImage = array[0..63999] of Byte;

var
  SetRGB: TSetRGBProc absolute g_E7C8;
  VGA: TVGAImage absolute $A000:0;

procedure U1615_0000(P: Integer);
procedure U1615_0209(P: Integer);
procedure U1615_14AE(P: Integer);
procedure U1615_3550(P: Integer);
procedure U1615_46C2;

implementation




uses
  U1B27, U0098, U1DD4, U1F69, U20C6, U22B7,
  U2390;

{ update the weapon / accessory indicator colours of player P }
{#U1615_0000}
procedure U1615_0000(P: Integer);
begin
  for g_461E := 0 to 17 do
  begin
    if Players_3F0E[P].Ammo[g_461E] > 0 then
      SetRGB(g_461E + 100, 63, 63, 63)
    else
      SetRGB(g_461E + 100, 0, 0, 0);
    if Players_3F0E[P].Weapon = g_461E then
      SetRGB(g_461E + 100, 63, 0, 0);
  end;
  if Players_3F0E[P].Accessory[0] > 0 then
    SetRGB($76, 63, 63, 63)
  else
  begin
    SetRGB($76, 0, 0, 0);
    Players_3F0E[P].f26 := Players_3F0E[P].f26 and 2;
  end;
  if Players_3F0E[P].Accessory[1] > 0 then
    SetRGB($77, 63, 63, 63)
  else
  begin
    SetRGB($77, 0, 0, 0);
    Players_3F0E[P].f26 := Players_3F0E[P].f26 and 1;
  end;
  if Players_3F0E[P].f26 and 1 = 1 then
    SetRGB($76, 63, 0, 0);
  if Players_3F0E[P].f26 and 2 = 2 then
    SetRGB($77, 63, 0, 0);
end;

{#U1615_0209}
procedure U1615_0209(P: Integer);
var
  MinPower: Integer;            { bp-2 }
  Guided: Boolean;              { bp-3 }
  AnyMagnet: Boolean;           { bp-4 }
  Pix: Integer;                 { bp-6 }
  Away: Boolean;                { bp-7 }
  Unused8: Byte;                { bp-8 }
  Buf: array[0..9] of Byte;     { bp-12 }
  OldX, OldY: Integer;          { bp-14, bp-16 }
  X, Y: Integer;                { bp-18, bp-1A }
  DX, DY: Integer;              { bp-1C, bp-1E }
  Dist: LongInt;                { bp-22 }
  Ang: Integer;                 { bp-24 }
  Force: Real;                  { bp-2A }
  Steps: LongInt;               { bp-2E }
begin
  g_46B8 := 0;
  FillChar(Buf, 10, 0);
  MinPower := Players_3F0E[P].Men * 3 + $283;
  if g_E788 <> 0 then
  begin
    Sound(111); Delay(3);
    Sound(222); Delay(3);
    Sound(333); Delay(5);
    Sound(444); Delay(5);
    Sound(555); Delay(5);
    Sound(666); Delay(5);
    Sound(777); Delay(5);
    Sound(888); Delay(5);
    Sound(999); Delay(5);
    Sound(1111); Delay(9);
    Sound(1333); Delay(13);
    Sound(1777); Delay(17);
    Sound(2111); Delay(20);
    NoSound;
  end;
  Dec(Players_3F0E[P].Ammo[Players_3F0E[P].Weapon]);
  if Players_3F0E[P].f26 in [1, 3] then
    Dec(Players_3F0E[P].Accessory[0]);
  if Players_3F0E[P].f26 in [2, 3] then
    Dec(Players_3F0E[P].Accessory[1]);
  Guided := False;
  g_46B8 := 0;
  if Random < 0.2 then
    U26A9_0004(1, 0, Players_3F0E[P]);
  g_4670 := Players_3F0E[P].X + Players_3F0E[P].f1F *
    (Cos(U2918_00D9(Players_3F0E[P].f1D)) * 10.0);
  g_4676 := Players_3F0E[P].Y - Sin(U2918_00D9(Players_3F0E[P].f1D)) * 10.0;
  g_467C := Players_3F0E[P].f1F * (Cos(U2918_00D9(Players_3F0E[P].f1D)) *
    (Players_3F0E[P].f1B / 50.0));
  g_4682 := -Sin(U2918_00D9(Players_3F0E[P].f1D)) * (Players_3F0E[P].f1B / 50.0);
  g_462F := 0;
  OldX := -99;
  OldY := -99;
  g_4622 := g_E79E;
  for g_461E := 1 to g_46B4 do
    SetRGB(100 - g_461E, 32 div Players_3F0E[g_461E].f60,
      32 div Players_3F0E[g_461E].f62, 32 div Players_3F0E[g_461E].f64);
  SetRGB(19, 63, 63, 63);
  Guided := False;
  g_462E := 1;
  AnyMagnet := False;
  for g_461E := 1 to g_46B4 do
    if (Players_3F0E[g_461E].Guidance[2] > 0) and (Players_3F0E[g_461E].f23 <> 0) then
      AnyMagnet := True;
  Steps := 0;
  Away := False;
  repeat
    Inc(g_461E);
    if g_461E > g_4622 then
    begin
      g_461E := 0;
      Inc(Steps);
    end;
    g_4670 := g_4670 + g_467C / g_4622;
    g_4676 := g_4676 + g_4682 / g_4622;
    g_4682 := g_4682 + 0.1 / g_4622;
    g_467C := g_467C + g_E778 / 5000.0 / g_4622;
    X := Trunc(g_4670);
    Y := Trunc(g_4676);
    if not Away then
      if (Abs(Y - Players_3F0E[P].Y) > 40) or (Abs(X - Players_3F0E[P].X) > 40) then
        Away := True;
    if AnyMagnet then
      for g_4620 := 1 to g_46B4 do
        if (Players_3F0E[g_4620].f23 <> 0) and (Players_3F0E[g_4620].Guidance[2] > 0) and
           (Away or (g_4620 <> P)) then
        begin
          DY := Y - Players_3F0E[g_4620].Y;
          DX := Players_3F0E[g_4620].X - X;
          if (Abs(DX) <= 40) and (Abs(DY) <= 40) then
          begin
            Dist := Trunc(Int(DY) * DY + Int(DX) * DX);
            if Dist <= 1600 then
            begin
              g_E7D6 := Seg(SaveBuf_E496^);
              U2823_0AC0(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X, Y, @VGA);
              g_E7D6 := $A000;
              U2823_09E4(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X, Y, 14);
              Force := -600.0 / Dist / g_4622;
              if DX <> 0 then
              begin
                Ang := Trunc(U2918_011B(ArcTan(DY / DX)));
                if DX < 0 then
                  Ang := Ang + 180;
              end
              else if DY > 0 then
                Ang := 90
              else
                Ang := 270;
              g_467C := g_467C + Force * U26D4_005A(Ang);
              g_4682 := g_4682 - Force * U26D4_0000(Ang);
              U2823_0AC0(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X, Y, SaveBuf_E496);
            end;
          end;
        end;
    if Players_3F0E[P].f26 > 0 then
    begin
      g_46C0 := Players_3F0E[P].f28;
      Guided := False;
      DX := Players_3F0E[g_46C0].X - X;
      DY := Players_3F0E[g_46C0].Y - Y;
      if Players_3F0E[P].f26 in [2, 3] then
        if Abs(DX) <= 2 then
        begin
          Guided := True;
          g_467C := 0;
          if DY > 0 then
            g_4676 := g_4676 + 0.5
          else
            g_4676 := g_4676 - 0.5;
        end;
      if Players_3F0E[P].f26 in [1, 3] then
        if (DY <= 4) and (DY > 0) then
        begin
          Guided := True;
          g_4682 := 0;
          if DX * g_467C < 0 then
            g_467C := g_467C * -1.01
          else if g_467C <> 0 then
            g_467C := g_467C * 1.01
          else
            g_467C := 0.1;
        end;
      if Guided then
        SetRGB(19, 63, 0, 0);
    end;
    if (g_E787 <> 0) and (g_E788 <> 0) then
      Sound(600 - Trunc(Y * 2));
    if (OldX > 11) and (OldY > 31) and (OldX < 309) then
    begin
      if g_E789 = 0 then
        U0098_03F4(OldX, OldY, BackBuf_E49A);
      if g_E78A <> 0 then
        U0098_0552(OldX, OldY, 100 - P, BackBuf_E49A);
    end;
    if (OldX >= 9) and (OldX <= 311) then
    begin
      if g_E789 = 0 then
        U2823_0BB6(OldX, 29, 0);
      if g_E789 = 0 then
        U2823_0BB6(OldX, 191, 0);
    end;
    if (OldY >= 29) and (OldY <= 191) then
    begin
      if g_E789 = 0 then
        U2823_0BB6(9, OldY, 0);
      if g_E789 = 0 then
        U2823_0BB6(311, OldY, 0);
    end;
    OldX := X;
    OldY := Y;
    if (X > 11) and (Y > 33) and (X < 309) and (Y < 187) and (g_462F = 0) then
    begin
      for g_4624 := -1 to 1 do
        for g_4626 := -1 to 1 do
          if Abs(g_4624) + Abs(g_4626) <= 1 then
          begin
            Pix := U2823_0BFF(X + g_4624, Y + g_4626);
            if Pix = 2 then
            begin
              g_46B8 := Pix;
              if (Players_3F0E[P].f1B < MinPower) or (g_461E = g_4622) then
                g_462F := 1;
              if Players_3F0E[P].f1B = MinPower then
                g_462F := 0;
            end;
            if (Pix >= 20) and (Pix <= 29) then
            begin
              g_46B8 := Pix;
              g_462F := 1;
              if (Players_3F0E[P].Weapon >= 12) and (Players_3F0E[P].Weapon <= 16) then
              begin
                g_462F := 0;
                g_4682 := -g_4682 * 1.2;
                Players_3F0E[P].f26 := 0;
                SetRGB(19, 0, 0, 63);
              end;
            end;
          end;
    end
    else if g_46EE <> 0 then
    begin
      if (X <= 10) and (g_467C < 0) then
      begin
        g_467C := -g_467C * g_46AC;
        g_4682 := g_4682 * g_46AC;
      end;
      if (X >= 310) and (g_467C > 0) then
      begin
        g_467C := -g_467C * g_46AC;
        g_4682 := g_4682 * g_46AC;
      end;
      if (Y <= 30) and (g_4682 < 0) then
      begin
        g_4682 := -g_4682 * g_46AC;
        g_467C := g_467C * g_46AC;
      end;
      if (Y >= 188) and (g_4682 > 0) then
      begin
        g_467C := g_467C * g_46AC;
        g_4682 := -g_4682 * g_46AC;
        if Abs(g_4682) < 0.1 then
        begin
          g_462E := 1;
          g_462F := 1;
        end;
      end;
    end
    else if g_46EF <> 0 then
    begin
      if X <= 10 then
        g_4670 := g_4670 + 300.0;
      if X >= 310 then
        g_4670 := g_4670 - 300.0;
    end
    else if g_46EE = 0 then
    begin
      if (X > 310) and (g_467C > 1.0) and (g_E778 > 0) and (Players_3F0E[P].f26 = 0) then
        g_4676 := 300;
      if (X < 10) and (g_467C < 1.0) and (g_E778 < 0) and (Players_3F0E[P].f26 = 0) then
        g_4676 := 300;
    end;
    if Steps > 1000 then
    begin
      g_462F := 1;
      g_462E := 1;
    end;
    if g_46EE = 0 then
    begin
      if Y < -5000 then
      begin
        g_462F := 1;
        if g_E788 <> 0 then
        begin
          Sound(1525); Delay(15);
          Sound(4674); Delay(5);
          Sound(222); Delay(10);
          Sound(121); Delay(14);
          NoSound;
        end;
        g_462E := 0;
      end;
      if Y >= 190 then
        g_462F := 1;
    end;
    if (g_462F = 0) and (g_E789 = 0) then
    begin
      if (X > 11) and (Y > 31) and (X < 309) then
        U0098_03A8(X, Y);
      if (X >= 9) and (X <= 311) then
      begin
        U2823_0BB6(X, 29, 13);
        U2823_0BB6(X, 191, 13);
      end;
      if (Y >= 29) and (Y <= 191) then
      begin
        U2823_0BB6(9, Y, 13);
        U2823_0BB6(311, Y, 13);
      end;
    end;
    if g_462F <> 0 then
      U2823_0031(9, 29, 311, 191, 0);
    if (Abs(g_467C) > 30.0) or (Abs(g_4682) > 30.0) then
    begin
      g_462F := 1;
      g_462E := 1;
    end;
  until g_462F = 1;
  U0098_03F4(X, Y, BackBuf_E49A);
  U0098_03F4(OldX, OldY, BackBuf_E49A);
  NoSound;
  if (g_46B8 >= 20) and (g_46B8 <= 29) then
    if Players_3F0E[g_46B8 - 19].Team <> Players_3F0E[P].Team then
      Inc(Players_3F0E[P].f6C);
  if g_462E <> 0 then
    U1DD4_0108(P, g_4670, g_4676, g_46B8);
  NoSound;
end;

{ MIRV shot of player P: lets the player choose the spread pattern and the
  detonation mode, then flies the warhead; at the apex it splits into 5. }
{#U1615_14AE}
procedure U1615_14AE(P: Integer);
label
  Restart;
var
  AnyMagnet: Boolean;                 { bp-1 }
  Unused2: Byte;                      { bp-2 }
  Pix: Integer;                       { bp-4 }
  Buf: array[0..9] of Byte;           { bp-0E }
  Hit: array[0..5] of Integer;        { bp-1A }
  OldX: array[0..5] of Integer;       { bp-26 }
  OldY: array[0..5] of Integer;       { bp-32 }
  X: array[0..5] of Integer;          { bp-3E }
  Y: array[0..5] of Integer;          { bp-4A }
  RX: array[0..5] of Real;            { bp-6E }
  RY: array[0..5] of Real;            { bp-92 }
  VX: array[0..5] of Real;            { bp-B6 }
  VY: array[0..5] of Real;            { bp-DA }
  Split: Boolean;                     { bp-DB }
  UnusedDC: Byte;                     { bp-DC }
  First: Integer;                     { bp-DE }
  Last: Integer;                      { bp-E0 }
  DX: Integer;                        { bp-E2 }
  DY: Integer;                        { bp-E4 }
  I: Integer;                         { bp-E6 }
  Dist: LongInt;                      { bp-EA }
  Exploded: array[0..5] of Boolean;   { bp-F0 }
  Done: array[0..5] of Boolean;       { bp-F6 }
  Force: Real;                        { bp-FC }
  UnusedFE: Integer;                  { bp-FE }
  Ang: Integer;                       { bp-100 }
  Mode: Integer;                      { bp-102 }
  PrevMode: Integer;                  { bp-104 }
  Alive: Integer;                     { bp-106 }
  Det: Integer;                       { bp-108 }
  PrevDet: Integer;                   { bp-10A }
  Away: Boolean;                      { bp-10B }
  Unused10C: Byte;                    { bp-10C }
  Steps: LongInt;                     { bp-110 }
  SavedDelay: Integer;                { bp-112 }
begin
  SavedDelay := g_E79A;
  g_E79A := g_E79A div 5;
  NoSound;
  TVGAImage(SaveBuf_E496^) := VGA;
Restart:
  SetTextJustify(1, 1);
  SetFillStyle(1, 0);
  SetColor(13);
  Bar(100, 65, 220, 135);
  U2823_0031(100, 65, 220, 135, 13);
  U2823_0031(102, 67, 218, 133, 13);
  SetColor(15);
  SetTextJustify(1, 1);
  OutTextXY(160, 75, 'MIRV Setup');
  U2823_09E4(102, 79, 218, 79, 13);
  SetColor(130);
  OutTextXY(160, 85, 'Random');
  SetColor(131);
  OutTextXY(160, 95, 'Horizontal');
  SetColor(132);
  OutTextXY(160, 105, 'Vertical');
  SetColor(133);
  OutTextXY(160, 115, '+ 4 Way');
  SetColor(134);
  OutTextXY(160, 125, 'X 4 Way');
  repeat
  until not (U2968_0077(1) or U2968_0077(2));
  g_440A[$11C] := 0;
  g_440A[$39] := 0;
  g_440A[$1C] := 0;
  Mode := 0;
  PrevMode := -1;
  if Control_E480[P] = 1 then
    repeat
      g_462E := 0;
      if PrevMode <> Mode then
      begin
        for g_461E := 130 to 134 do
          SetRGB(g_461E, 0, 0, 44);
        SetRGB(Mode + 130, 63, 22, 22);
      end;
      PrevMode := Mode;
      if (g_440A[$48] <> 0) and (Mode > 0) then
      begin
        Dec(Mode);
        g_440A[$48] := 0;
      end;
      if (g_440A[$148] <> 0) and (Mode > 0) then
      begin
        Dec(Mode);
        g_440A[$148] := 0;
      end;
      if (g_440A[$50] <> 0) and (Mode < 4) then
      begin
        Inc(Mode);
        g_440A[$50] := 0;
      end;
      if (g_440A[$150] <> 0) and (Mode < 4) then
      begin
        Inc(Mode);
        g_440A[$150] := 0;
      end;
      if g_440A[$1C] <> 0 then
        g_462E := 1;
      if g_440A[$11C] <> 0 then
        g_462E := 1;
      if g_440A[$39] <> 0 then
        g_462E := 1;
    until g_462E <> 0;
  if Control_E480[P] = 2 then
  begin
    U2968_004D;
    repeat
      g_462E := 0;
      if Mode <> PrevMode then
      begin
        for g_461E := 130 to 134 do
          SetRGB(g_461E, 0, 0, 44);
        SetRGB(Mode + 130, 63, 22, 22);
      end;
      PrevMode := Mode;
      if U2918_0256 < 89 then
        Mode := 0;
      if (U2918_0256 > 91) and (U2918_0256 < 99) then
        Mode := 1;
      if (U2918_0256 > 101) and (U2918_0256 < 109) then
        Mode := 2;
      if (U2918_0256 > 111) and (U2918_0256 < 119) then
        Mode := 3;
      if U2918_0256 > 121 then
        Mode := 4;
      if U2968_0077(1) or U2968_0077(2) then
        g_462E := 1;
    until g_462E <> 0;
    U2968_005A;
  end;
  Bar(100, 65, 220, 135);
  U2823_0031(100, 65, 220, 135, 13);
  U2823_0031(102, 67, 218, 133, 13);
  SetColor(15);
  SetTextJustify(1, 1);
  OutTextXY(160, 75, 'Detonations');
  U2823_09E4(102, 79, 218, 79, 13);
  SetColor(130);
  OutTextXY(160, 85, 'Impact');
  SetColor(131);
  OutTextXY(160, 95, 'Simultanious');
  SetColor(132);
  OutTextXY(160, 105, 'None');
  repeat
  until not (U2968_0077(1) or U2968_0077(2));
  g_440A[$11C] := 0;
  g_440A[$39] := 0;
  g_440A[$1C] := 0;
  Det := 0;
  PrevDet := -1;
  if Control_E480[P] = 1 then
    repeat
      g_462E := 0;
      if PrevDet <> Det then
      begin
        for g_461E := 130 to 134 do
          SetRGB(g_461E, 0, 0, 44);
        SetRGB(Det + 130, 63, 22, 22);
      end;
      PrevDet := Det;
      if (g_440A[$48] <> 0) and (Det > 0) then
      begin
        Dec(Det);
        g_440A[$48] := 0;
      end;
      if (g_440A[$148] <> 0) and (Det > 0) then
      begin
        Dec(Det);
        g_440A[$148] := 0;
      end;
      if (g_440A[$50] <> 0) and (Det < 2) then
      begin
        Inc(Det);
        g_440A[$50] := 0;
      end;
      if (g_440A[$150] <> 0) and (Det < 2) then
      begin
        Inc(Det);
        g_440A[$150] := 0;
      end;
      if g_440A[$1C] <> 0 then
        g_462E := 1;
      if g_440A[$11C] <> 0 then
        g_462E := 1;
      if g_440A[$39] <> 0 then
        g_462E := 1;
      if g_440A[$01] <> 0 then
      begin
        VGA := TVGAImage(SaveBuf_E496^);
        goto Restart;
      end;
    until g_462E <> 0;
  if Control_E480[P] = 2 then
  begin
    U2968_004D;
    repeat
      g_462E := 0;
      if Det <> PrevDet then
      begin
        for g_461E := 130 to 134 do
          SetRGB(g_461E, 0, 0, 44);
        SetRGB(Det + 130, 63, 22, 22);
      end;
      PrevDet := Det;
      if U2918_0256 < 89 then
        Det := 0;
      if (U2918_0256 > 91) and (U2918_0256 < 99) then
        Det := 1;
      if U2918_0256 > 101 then
        Det := 2;
      if U2968_0077(1) or U2968_0077(2) then
        g_462E := 1;
    until g_462E <> 0;
    U2968_005A;
  end;
  VGA := TVGAImage(SaveBuf_E496^);
  FillChar(Hit, 12, 0);
  Split := False;
  First := 0;
  Last := 0;
  FillChar(Buf, 10, 0);
  if g_E788 <> 0 then
  begin
    Sound(111); Delay(3);
    Sound(222); Delay(3);
    Sound(333); Delay(5);
    Sound(444); Delay(5);
    Sound(555); Delay(5);
    Sound(666); Delay(5);
    Sound(777); Delay(5);
    Sound(888); Delay(5);
    Sound(999); Delay(5);
    Sound(1111); Delay(9);
    Sound(1333); Delay(13);
    Sound(1777); Delay(17);
    Sound(2111); Delay(20);
    NoSound;
  end;
  Dec(Players_3F0E[P].Ammo[Players_3F0E[P].Weapon]);
  Players_3F0E[P].f26 := 0;
  RX[0] := Players_3F0E[P].X + Players_3F0E[P].f1F *
    (Cos(U2918_00D9(Players_3F0E[P].f1D)) * 10.0);
  RY[0] := Players_3F0E[P].Y - Sin(U2918_00D9(Players_3F0E[P].f1D)) * 10.0;
  VX[0] := Players_3F0E[P].f1F * (Cos(U2918_00D9(Players_3F0E[P].f1D)) *
    (Players_3F0E[P].f1B / 50.0));
  VY[0] := -Sin(U2918_00D9(Players_3F0E[P].f1D)) * (Players_3F0E[P].f1B / 50.0);
  FillChar(Done, 6, 0);
  for g_461E := 0 to 5 do
  begin
    OldX[g_461E] := -99;
    OldY[g_461E] := -99;
    Done[g_461E] := False;
    Exploded[g_461E] := False;
  end;
  g_4622 := g_E79E;
  for g_461E := 1 to g_46B4 do
    SetRGB(100 - g_461E, 32 div Players_3F0E[g_461E].f60,
      32 div Players_3F0E[g_461E].f62, 32 div Players_3F0E[g_461E].f64);
  SetRGB(19, 63, 63, 63);
  g_462E := 1;
  AnyMagnet := False;
  for g_461E := 1 to g_46B4 do
    if (Players_3F0E[g_461E].Guidance[2] > 0) and (Players_3F0E[g_461E].f23 <> 0) then
      AnyMagnet := True;
  Split := True;
  Steps := 0;
  Away := False;
  repeat
    Split := not Split;
    repeat
      Inc(g_461E);
      if g_461E > g_4622 then
      begin
        g_461E := 0;
        Inc(Steps);
      end;
      for I := First to Last do
        if not Done[I] then
        begin
          RX[I] := RX[I] + VX[I] / g_4622;
          RY[I] := RY[I] + VY[I] / g_4622;
          VY[I] := VY[I] + 0.1 / g_4622;
          VX[I] := VX[I] + g_E778 / 5000.0 / g_4622;
          X[I] := Trunc(RX[I]);
          Y[I] := Trunc(RY[I]);
          if not Away then
            if (Abs(Y[I] - Players_3F0E[P].Y) > 40) or (Abs(X[I] - Players_3F0E[P].X) > 40) then
              Away := True;
          if AnyMagnet then
            for g_4620 := 1 to g_46B4 do
              if (Players_3F0E[g_4620].f23 <> 0) and (Players_3F0E[g_4620].Guidance[2] > 0) and
                 (Away or (g_4620 <> P)) then
              begin
                DY := Y[I] - Players_3F0E[g_4620].Y;
                DX := Players_3F0E[g_4620].X - X[I];
                if (Abs(DX) <= 40) and (Abs(DY) <= 40) then
                begin
                  Dist := Trunc(Int(DY) * DY + Int(DX) * DX);
                  if Dist <= 1600 then
                  begin
                    g_E7D6 := Seg(SaveBuf_E496^);
                    U2823_0AC0(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X[I], Y[I], @VGA);
                    g_E7D6 := $A000;
                    U2823_09E4(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X[I], Y[I], 14);
                    Force := -600.0 / Dist / g_4622;
                    if DX <> 0 then
                    begin
                      Ang := Trunc(U2918_011B(ArcTan(DY / DX)));
                      if DX < 0 then
                        Ang := Ang + 180;
                    end
                    else if DY > 0 then
                      Ang := 90
                    else
                      Ang := 270;
                    VX[I] := VX[I] + Force * U26D4_005A(Ang);
                    VY[I] := VY[I] - Force * U26D4_0000(Ang);
                    U2823_0AC0(Players_3F0E[g_4620].X, Players_3F0E[g_4620].Y, X[I], Y[I], SaveBuf_E496);
                  end;
                end;
              end;
          if (g_E787 <> 0) and (g_E788 <> 0) then
            Sound(600 - Trunc(Y[I] * 2));
          if (OldX[I] > 11) and (OldY[I] > 31) and (OldX[I] < 309) then
          begin
            if g_E789 = 0 then
              U0098_03F4(OldX[I], OldY[I], BackBuf_E49A);
            if g_E78A <> 0 then
              U0098_0552(OldX[I], OldY[I], 100 - P, BackBuf_E49A);
          end;
          if (OldX[I] >= 9) and (OldX[I] <= 311) then
          begin
            if g_E789 = 0 then
              U2823_0BB6(OldX[I], 29, 0);
            if g_E789 = 0 then
              U2823_0BB6(OldX[I], 191, 0);
          end;
          if (OldY[I] >= 29) and (OldY[I] <= 191) then
          begin
            if g_E789 = 0 then
              U2823_0BB6(9, OldY[I], 0);
            if g_E789 = 0 then
              U2823_0BB6(311, OldY[I], 0);
          end;
          OldX[I] := X[I];
          OldY[I] := Y[I];
          if (X[I] > 11) and (Y[I] > 33) and (X[I] < 309) and (Y[I] < 187) and not Done[I] then
          begin
            for g_4624 := -1 to 1 do
              for g_4626 := -1 to 1 do
                if Abs(g_4624) + Abs(g_4626) <= 1 then
                begin
                  Pix := U2823_0BFF(X[I] + g_4624, Y[I] + g_4626);
                  if Pix = 2 then
                  begin
                    Hit[I] := Pix;
                    Done[I] := True;
                  end;
                  if (Pix >= 20) and (Pix <= 29) then
                  begin
                    if Players_3F0E[Pix - 19].Men > 0 then
                      Done[I] := True;
                    Hit[I] := Pix;
                  end;
                end;
          end
          else if g_46EE <> 0 then
          begin
            if (X[I] <= 10) and (VX[I] < 0) then
            begin
              VX[I] := -VX[I] * g_46AC;
              VY[I] := VY[I] * g_46AC;
            end;
            if (X[I] >= 310) and (VX[I] > 0) then
            begin
              VX[I] := -VX[I] * g_46AC;
              VY[I] := VY[I] * g_46AC;
            end;
            if (Y[I] <= 30) and (VY[I] < 0) then
            begin
              VY[I] := -VY[I] * g_46AC;
              VX[I] := VX[I] * g_46AC;
            end;
            if (Y[I] >= 188) and (VY[I] > 0) then
            begin
              VX[I] := VX[I] * g_46AC;
              VY[I] := -VY[I] * g_46AC;
              if (Abs(VX[I]) < 0.1) and (Abs(VY[I]) < 0.1) then
              begin
                g_462E := 1;
                Done[I] := True;
              end;
            end;
          end
          else if g_46EF <> 0 then
          begin
            if X[I] <= 10 then
              RX[I] := RX[I] + 300.0;
            if X[I] >= 310 then
              RX[I] := RX[I] - 300.0;
          end
          else if g_46EE = 0 then
          begin
            if (X[I] > 310) and (VX[I] > 1.0) and (g_E778 > 0) then
              RY[I] := 400;
            if (X[I] < 10) and (VX[I] < 1.0) and (g_E778 < 0) then
              RY[I] := 400;
          end;
          if not Split then
            if VY[I] > 0 then
              Done[I] := True;
          if (Abs(VX[I]) > 30.0) or (Abs(VY[I]) > 30.0) then
          begin
            Done[I] := True;
            g_462E := 1;
          end;
          if g_46EE = 0 then
          begin
            if Y[I] < -5000 then
            begin
              Done[I] := True;
              if g_E788 <> 0 then
              begin
                Sound(1525); Delay(15);
                Sound(4674); Delay(5);
                Sound(222); Delay(10);
                Sound(121); Delay(14);
                NoSound;
              end;
            end;
            if Y[I] >= 190 then
              Done[I] := True;
          end;
          if Steps > 1000 then
            Done[I] := True;
          if not Done[I] and (g_E789 = 0) then
          begin
            if (X[I] > 11) and (Y[I] > 31) and (X[I] < 309) then
              U0098_03A8(X[I], Y[I]);
            if (X[I] >= 9) and (X[I] <= 311) then
            begin
              U2823_0BB6(X[I], 29, 13);
              U2823_0BB6(X[I], 191, 13);
            end;
            if (Y[I] >= 29) and (Y[I] <= 191) then
            begin
              U2823_0BB6(9, Y[I], 13);
              U2823_0BB6(311, Y[I], 13);
            end;
          end
          else if (X[I] > 0) and (X[I] < 320) and (Y[I] > 0) and (Y[I] < 200) then
            U0098_03F4(X[I], Y[I], BackBuf_E49A);
          if (Det = 0) and Split and Done[I] and not Exploded[I] then
          begin
            Exploded[I] := True;
            U1DD4_0108(P, RX[I], RY[I], Hit[I]);
            for g_4620 := 1 to g_46B4 do
              U0098_07A3(g_4620);
          end;
        end;
      g_462E := 0;
      Alive := 0;
      for g_4620 := 0 to 5 do
        if not Done[g_4620] then
          Inc(Alive);
      if not Split and (Alive = 5) then
        g_462E := 1;
      if Split and (Alive = 0) then
        g_462E := 1;
      if Split and (Alive > 0) then
      begin
        g_4622 := g_E79E div Alive;
        if g_E79E mod Alive <> 0 then
          Inc(g_4622);
      end;
      if g_4622 < 1 then
        g_4622 := 1;
    until g_462E <> 0;
    if not Split then
    begin
      First := 1;
      Last := 5;
      for g_4620 := 1 to 5 do
      begin
        Done[g_4620] := False;
        Hit[g_4620] := 0;
        RX[g_4620] := RX[0];
        RY[g_4620] := RY[0];
        VX[g_4620] := VX[0];
        VY[g_4620] := VY[0];
        if Mode = 0 then
        begin
          VX[g_4620] := VX[g_4620] + Random * 6.0 - 3.0;
          VY[g_4620] := VY[g_4620] + Random * 6.0 - 3.0;
        end;
        if Mode = 1 then
          VX[g_4620] := VX[g_4620] + (g_4620 - 3) * 1.75;
        if Mode = 2 then
          VY[g_4620] := VY[g_4620] + (g_4620 - 3) * 1.75;
        OldX[g_4620] := OldX[0];
        OldY[g_4620] := OldY[0];
      end;
      if Mode = 3 then
      begin
        VX[1] := VX[1] + 1.75;
        VX[2] := VX[2] - 1.75;
        VY[3] := VY[3] - 1.75;
        VY[4] := VY[4] + 1.75;
      end;
      if Mode = 4 then
      begin
        VX[1] := VX[1] + 1.75;
        VY[1] := VY[1] + 1.75;
        VX[2] := VX[2] - 1.75;
        VY[2] := VY[2] - 1.75;
        VX[3] := VX[3] + 1.75;
        VY[3] := VY[3] - 1.75;
        VX[4] := VX[4] - 1.75;
        VY[4] := VY[4] + 1.75;
      end;
    end;
  until Split;
  if Det = 1 then
    for g_461E := 1 to 5 do
    begin
      U1DD4_0108(P, RX[g_461E], RY[g_461E], Hit[g_461E]);
      for g_4620 := 1 to g_46B4 do
        U0098_07A3(g_4620);
    end;
  NoSound;
  g_E79A := SavedDelay;
end;

{#U1615_3550}
procedure U1615_3550(P: Integer);
begin
end;

{#U1615_46C2}
procedure U1615_46C2;
begin
end;

end.
