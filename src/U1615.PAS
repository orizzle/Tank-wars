{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1615;

{ Shot flight: normal shells (0209), MIRV with spread / detonation menus
  (14AE), laser beam (3550), the per-turn round loop (46C2) and the weapon
  indicator colours (0000).
  Player fields as used here: f1B = power, f1D = angle, f1F = direction (+1/-1),
  f26 = active guidance bits, f28 = guidance target, Guidance[2] = magnet. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

type
  TSetRGBProc = procedure(Color, R, G, B: Integer);
  TVGAImage = array[0..63999] of Byte;
  { one logged shot (read back by the computer players in U23C3) }
  TShot = record
    Angle, Power, Dir: Integer;       { +0 +2 +4 }
    HitX, HitY: Integer;              { +6 +8  impact point }
  end;

var
  SetRGB: TSetRGBProc absolute RGBHook;
  VGA: TVGAImage absolute $A000:0;
  ShotLog: array[0..10, 0..200] of TShot absolute ShotLogData;

procedure UpdateWeaponLamps(P: Integer);
procedure FireShell(P: Integer);
procedure FireMirv(P: Integer);
procedure FireLaser(P: Integer);
procedure PlayRound;

implementation




uses
  U1B27, U0098, U1DD4, U1F69, U20C6, U22B7,
  U2390;

{ update the weapon / accessory indicator colours of player P }
{#U1615_0000}
procedure UpdateWeaponLamps(P: Integer);
begin
  for LoopI := 0 to 17 do
  begin
    if Players[P].Ammo[LoopI] > 0 then
      SetRGB(LoopI + 100, 63, 63, 63)
    else
      SetRGB(LoopI + 100, 0, 0, 0);
    if Players[P].Weapon = LoopI then
      SetRGB(LoopI + 100, 63, 0, 0);
  end;
  if Players[P].Accessory[0] > 0 then
    SetRGB($76, 63, 63, 63)
  else
  begin
    SetRGB($76, 0, 0, 0);
    Players[P].f26 := Players[P].f26 and 2;
  end;
  if Players[P].Accessory[1] > 0 then
    SetRGB($77, 63, 63, 63)
  else
  begin
    SetRGB($77, 0, 0, 0);
    Players[P].f26 := Players[P].f26 and 1;
  end;
  if Players[P].f26 and 1 = 1 then
    SetRGB($76, 63, 0, 0);
  if Players[P].f26 and 2 = 2 then
    SetRGB($77, 63, 0, 0);
end;

{#U1615_0209}
procedure FireShell(P: Integer);
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
  HitColor := 0;
  FillChar(Buf, 10, 0);
  MinPower := Players[P].Men * 3 + $283;
  if SoundOn <> 0 then
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
  Dec(Players[P].Ammo[Players[P].Weapon]);
  if Players[P].f26 in [1, 3] then
    Dec(Players[P].Accessory[0]);
  if Players[P].f26 in [2, 3] then
    Dec(Players[P].Accessory[1]);
  Guided := False;
  HitColor := 0;
  if Random < 0.2 then
    ApplyDamage(1, 0, Players[P]);
  ShotX := Players[P].X + Players[P].f1F *
    (Cos(DegToRad(Players[P].f1D)) * 10.0);
  ShotY := Players[P].Y - Sin(DegToRad(Players[P].f1D)) * 10.0;
  ShotVX := Players[P].f1F * (Cos(DegToRad(Players[P].f1D)) *
    (Players[P].f1B / 50.0));
  ShotVY := -Sin(DegToRad(Players[P].f1D)) * (Players[P].f1B / 50.0);
  DoneFlag := 0;
  OldX := -99;
  OldY := -99;
  LoopK := ShotSpeed;
  for LoopI := 1 to NumPlayers do
    SetRGB(100 - LoopI, 32 div Players[LoopI].f60,
      32 div Players[LoopI].f62, 32 div Players[LoopI].f64);
  SetRGB(19, 63, 63, 63);
  Guided := False;
  DoneFlag2 := 1;
  AnyMagnet := False;
  for LoopI := 1 to NumPlayers do
    if (Players[LoopI].Guidance[2] > 0) and (Players[LoopI].f23 <> 0) then
      AnyMagnet := True;
  Steps := 0;
  Away := False;
  repeat
    Inc(LoopI);
    if LoopI > LoopK then
    begin
      LoopI := 0;
      Inc(Steps);
    end;
    ShotX := ShotX + ShotVX / LoopK;
    ShotY := ShotY + ShotVY / LoopK;
    ShotVY := ShotVY + 0.1 / LoopK;
    ShotVX := ShotVX + WindForce / 5000.0 / LoopK;
    X := Trunc(ShotX);
    Y := Trunc(ShotY);
    if not Away then
      if (Abs(Y - Players[P].Y) > 40) or (Abs(X - Players[P].X) > 40) then
        Away := True;
    if AnyMagnet then
      for LoopJ := 1 to NumPlayers do
        if (Players[LoopJ].f23 <> 0) and (Players[LoopJ].Guidance[2] > 0) and
           (Away or (LoopJ <> P)) then
        begin
          DY := Y - Players[LoopJ].Y;
          DX := Players[LoopJ].X - X;
          if (Abs(DX) <= 40) and (Abs(DY) <= 40) then
          begin
            Dist := Trunc(Int(DY) * DY + Int(DX) * DX);
            if Dist <= 1600 then
            begin
              VideoSeg := Seg(SaveBuf^);
              CopyLine(Players[LoopJ].X, Players[LoopJ].Y, X, Y, @VGA);
              VideoSeg := $A000;
              DrawLine(Players[LoopJ].X, Players[LoopJ].Y, X, Y, 14);
              Force := -600.0 / Dist / LoopK;
              if DX <> 0 then
              begin
                Ang := Trunc(RadToDeg(ArcTan(DY / DX)));
                if DX < 0 then
                  Ang := Ang + 180;
              end
              else if DY > 0 then
                Ang := 90
              else
                Ang := 270;
              ShotVX := ShotVX + Force * CosDeg(Ang);
              ShotVY := ShotVY - Force * SinDeg(Ang);
              CopyLine(Players[LoopJ].X, Players[LoopJ].Y, X, Y, SaveBuf);
            end;
          end;
        end;
    if Players[P].f26 > 0 then
    begin
      GuideTarget := Players[P].f28;
      Guided := False;
      DX := Players[GuideTarget].X - X;
      DY := Players[GuideTarget].Y - Y;
      if Players[P].f26 in [2, 3] then
        if Abs(DX) <= 2 then
        begin
          Guided := True;
          ShotVX := 0;
          if DY > 0 then
            ShotY := ShotY + 0.5
          else
            ShotY := ShotY - 0.5;
        end;
      if Players[P].f26 in [1, 3] then
        if (DY <= 4) and (DY > 0) then
        begin
          Guided := True;
          ShotVY := 0;
          if DX * ShotVX < 0 then
            ShotVX := ShotVX * -1.01
          else if ShotVX <> 0 then
            ShotVX := ShotVX * 1.01
          else
            ShotVX := 0.1;
        end;
      if Guided then
        SetRGB(19, 63, 0, 0);
    end;
    if (FlySound <> 0) and (SoundOn <> 0) then
      Sound(600 - Trunc(Y * 2));
    if (OldX > 11) and (OldY > 31) and (OldX < 309) then
    begin
      if InvisoBall = 0 then
        ErasePlusMark(OldX, OldY, BackBuf);
      if ShotTrail <> 0 then
        PlotScreenAndBuf(OldX, OldY, 100 - P, BackBuf);
    end;
    if (OldX >= 9) and (OldX <= 311) then
    begin
      if InvisoBall = 0 then
        PlotPixel(OldX, 29, 0);
      if InvisoBall = 0 then
        PlotPixel(OldX, 191, 0);
    end;
    if (OldY >= 29) and (OldY <= 191) then
    begin
      if InvisoBall = 0 then
        PlotPixel(9, OldY, 0);
      if InvisoBall = 0 then
        PlotPixel(311, OldY, 0);
    end;
    OldX := X;
    OldY := Y;
    if (X > 11) and (Y > 33) and (X < 309) and (Y < 187) and (DoneFlag = 0) then
    begin
      for TmpX := -1 to 1 do
        for TmpY := -1 to 1 do
          if Abs(TmpX) + Abs(TmpY) <= 1 then
          begin
            Pix := PixelAt(X + TmpX, Y + TmpY);
            if Pix = 2 then
            begin
              HitColor := Pix;
              if (Players[P].f1B < MinPower) or (LoopI = LoopK) then
                DoneFlag := 1;
              if Players[P].f1B = MinPower then
                DoneFlag := 0;
            end;
            if (Pix >= 20) and (Pix <= 29) then
            begin
              HitColor := Pix;
              DoneFlag := 1;
              if (Players[P].Weapon >= 12) and (Players[P].Weapon <= 16) then
              begin
                DoneFlag := 0;
                ShotVY := -ShotVY * 1.2;
                Players[P].f26 := 0;
                SetRGB(19, 0, 0, 63);
              end;
            end;
          end;
    end
    else if WallsBounce <> 0 then
    begin
      if (X <= 10) and (ShotVX < 0) then
      begin
        ShotVX := -ShotVX * WallBounce;
        ShotVY := ShotVY * WallBounce;
      end;
      if (X >= 310) and (ShotVX > 0) then
      begin
        ShotVX := -ShotVX * WallBounce;
        ShotVY := ShotVY * WallBounce;
      end;
      if (Y <= 30) and (ShotVY < 0) then
      begin
        ShotVY := -ShotVY * WallBounce;
        ShotVX := ShotVX * WallBounce;
      end;
      if (Y >= 188) and (ShotVY > 0) then
      begin
        ShotVX := ShotVX * WallBounce;
        ShotVY := -ShotVY * WallBounce;
        if Abs(ShotVY) < 0.1 then
        begin
          DoneFlag2 := 1;
          DoneFlag := 1;
        end;
      end;
    end
    else if WallsWrap <> 0 then
    begin
      if X <= 10 then
        ShotX := ShotX + 300.0;
      if X >= 310 then
        ShotX := ShotX - 300.0;
    end
    else if WallsBounce = 0 then
    begin
      if (X > 310) and (ShotVX > 1.0) and (WindForce > 0) and (Players[P].f26 = 0) then
        ShotY := 300;
      if (X < 10) and (ShotVX < 1.0) and (WindForce < 0) and (Players[P].f26 = 0) then
        ShotY := 300;
    end;
    if Steps > 1000 then
    begin
      DoneFlag := 1;
      DoneFlag2 := 1;
    end;
    if WallsBounce = 0 then
    begin
      if Y < -5000 then
      begin
        DoneFlag := 1;
        if SoundOn <> 0 then
        begin
          Sound(1525); Delay(15);
          Sound(4674); Delay(5);
          Sound(222); Delay(10);
          Sound(121); Delay(14);
          NoSound;
        end;
        DoneFlag2 := 0;
      end;
      if Y >= 190 then
        DoneFlag := 1;
    end;
    if (DoneFlag = 0) and (InvisoBall = 0) then
    begin
      if (X > 11) and (Y > 31) and (X < 309) then
        DrawPlusMark(X, Y);
      if (X >= 9) and (X <= 311) then
      begin
        PlotPixel(X, 29, 13);
        PlotPixel(X, 191, 13);
      end;
      if (Y >= 29) and (Y <= 191) then
      begin
        PlotPixel(9, Y, 13);
        PlotPixel(311, Y, 13);
      end;
    end;
    if DoneFlag <> 0 then
      DrawRect(9, 29, 311, 191, 0);
    if (Abs(ShotVX) > 30.0) or (Abs(ShotVY) > 30.0) then
    begin
      DoneFlag := 1;
      DoneFlag2 := 1;
    end;
  until DoneFlag = 1;
  ErasePlusMark(X, Y, BackBuf);
  ErasePlusMark(OldX, OldY, BackBuf);
  NoSound;
  if (HitColor >= 20) and (HitColor <= 29) then
    if Players[HitColor - 19].Team <> Players[P].Team then
      Inc(Players[P].f6C);
  if DoneFlag2 <> 0 then
    WeaponImpact(P, ShotX, ShotY, HitColor);
  NoSound;
end;

{ MIRV shot of player P: lets the player choose the spread pattern and the
  detonation mode, then flies the warhead; at the apex it splits into 5. }
{#U1615_14AE}
procedure FireMirv(P: Integer);
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
  SavedDelay := ExplodeSpeed;
  ExplodeSpeed := ExplodeSpeed div 5;
  NoSound;
  TVGAImage(SaveBuf^) := VGA;
Restart:
  SetTextJustify(1, 1);
  SetFillStyle(1, 0);
  SetColor(13);
  Bar(100, 65, 220, 135);
  DrawRect(100, 65, 220, 135, 13);
  DrawRect(102, 67, 218, 133, 13);
  SetColor(15);
  SetTextJustify(1, 1);
  OutTextXY(160, 75, 'MIRV Setup');
  DrawLine(102, 79, 218, 79, 13);
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
  until not (MouseBtnsDown(1) or MouseBtnsDown(2));
  KeyDown[$11C] := 0;
  KeyDown[$39] := 0;
  KeyDown[$1C] := 0;
  Mode := 0;
  PrevMode := -1;
  if Controls[P] = 1 then
    repeat
      DoneFlag2 := 0;
      if PrevMode <> Mode then
      begin
        for LoopI := 130 to 134 do
          SetRGB(LoopI, 0, 0, 44);
        SetRGB(Mode + 130, 63, 22, 22);
      end;
      PrevMode := Mode;
      if (KeyDown[$48] <> 0) and (Mode > 0) then
      begin
        Dec(Mode);
        KeyDown[$48] := 0;
      end;
      if (KeyDown[$148] <> 0) and (Mode > 0) then
      begin
        Dec(Mode);
        KeyDown[$148] := 0;
      end;
      if (KeyDown[$50] <> 0) and (Mode < 4) then
      begin
        Inc(Mode);
        KeyDown[$50] := 0;
      end;
      if (KeyDown[$150] <> 0) and (Mode < 4) then
      begin
        Inc(Mode);
        KeyDown[$150] := 0;
      end;
      if KeyDown[$1C] <> 0 then
        DoneFlag2 := 1;
      if KeyDown[$11C] <> 0 then
        DoneFlag2 := 1;
      if KeyDown[$39] <> 0 then
        DoneFlag2 := 1;
    until DoneFlag2 <> 0;
  if Controls[P] = 2 then
  begin
    ShowMouseCursor;
    repeat
      DoneFlag2 := 0;
      if Mode <> PrevMode then
      begin
        for LoopI := 130 to 134 do
          SetRGB(LoopI, 0, 0, 44);
        SetRGB(Mode + 130, 63, 22, 22);
      end;
      PrevMode := Mode;
      if MouseY < 89 then
        Mode := 0;
      if (MouseY > 91) and (MouseY < 99) then
        Mode := 1;
      if (MouseY > 101) and (MouseY < 109) then
        Mode := 2;
      if (MouseY > 111) and (MouseY < 119) then
        Mode := 3;
      if MouseY > 121 then
        Mode := 4;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
        DoneFlag2 := 1;
    until DoneFlag2 <> 0;
    HideMouseCursor;
  end;
  Bar(100, 65, 220, 135);
  DrawRect(100, 65, 220, 135, 13);
  DrawRect(102, 67, 218, 133, 13);
  SetColor(15);
  SetTextJustify(1, 1);
  OutTextXY(160, 75, 'Detonations');
  DrawLine(102, 79, 218, 79, 13);
  SetColor(130);
  OutTextXY(160, 85, 'Impact');
  SetColor(131);
  OutTextXY(160, 95, 'Simultanious');
  SetColor(132);
  OutTextXY(160, 105, 'None');
  repeat
  until not (MouseBtnsDown(1) or MouseBtnsDown(2));
  KeyDown[$11C] := 0;
  KeyDown[$39] := 0;
  KeyDown[$1C] := 0;
  Det := 0;
  PrevDet := -1;
  if Controls[P] = 1 then
    repeat
      DoneFlag2 := 0;
      if PrevDet <> Det then
      begin
        for LoopI := 130 to 134 do
          SetRGB(LoopI, 0, 0, 44);
        SetRGB(Det + 130, 63, 22, 22);
      end;
      PrevDet := Det;
      if (KeyDown[$48] <> 0) and (Det > 0) then
      begin
        Dec(Det);
        KeyDown[$48] := 0;
      end;
      if (KeyDown[$148] <> 0) and (Det > 0) then
      begin
        Dec(Det);
        KeyDown[$148] := 0;
      end;
      if (KeyDown[$50] <> 0) and (Det < 2) then
      begin
        Inc(Det);
        KeyDown[$50] := 0;
      end;
      if (KeyDown[$150] <> 0) and (Det < 2) then
      begin
        Inc(Det);
        KeyDown[$150] := 0;
      end;
      if KeyDown[$1C] <> 0 then
        DoneFlag2 := 1;
      if KeyDown[$11C] <> 0 then
        DoneFlag2 := 1;
      if KeyDown[$39] <> 0 then
        DoneFlag2 := 1;
      if KeyDown[$01] <> 0 then
      begin
        VGA := TVGAImage(SaveBuf^);
        goto Restart;
      end;
    until DoneFlag2 <> 0;
  if Controls[P] = 2 then
  begin
    ShowMouseCursor;
    repeat
      DoneFlag2 := 0;
      if Det <> PrevDet then
      begin
        for LoopI := 130 to 134 do
          SetRGB(LoopI, 0, 0, 44);
        SetRGB(Det + 130, 63, 22, 22);
      end;
      PrevDet := Det;
      if MouseY < 89 then
        Det := 0;
      if (MouseY > 91) and (MouseY < 99) then
        Det := 1;
      if MouseY > 101 then
        Det := 2;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
        DoneFlag2 := 1;
    until DoneFlag2 <> 0;
    HideMouseCursor;
  end;
  VGA := TVGAImage(SaveBuf^);
  FillChar(Hit, 12, 0);
  Split := False;
  First := 0;
  Last := 0;
  FillChar(Buf, 10, 0);
  if SoundOn <> 0 then
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
  Dec(Players[P].Ammo[Players[P].Weapon]);
  Players[P].f26 := 0;
  RX[0] := Players[P].X + Players[P].f1F *
    (Cos(DegToRad(Players[P].f1D)) * 10.0);
  RY[0] := Players[P].Y - Sin(DegToRad(Players[P].f1D)) * 10.0;
  VX[0] := Players[P].f1F * (Cos(DegToRad(Players[P].f1D)) *
    (Players[P].f1B / 50.0));
  VY[0] := -Sin(DegToRad(Players[P].f1D)) * (Players[P].f1B / 50.0);
  FillChar(Done, 6, 0);
  for LoopI := 0 to 5 do
  begin
    OldX[LoopI] := -99;
    OldY[LoopI] := -99;
    Done[LoopI] := False;
    Exploded[LoopI] := False;
  end;
  LoopK := ShotSpeed;
  for LoopI := 1 to NumPlayers do
    SetRGB(100 - LoopI, 32 div Players[LoopI].f60,
      32 div Players[LoopI].f62, 32 div Players[LoopI].f64);
  SetRGB(19, 63, 63, 63);
  DoneFlag2 := 1;
  AnyMagnet := False;
  for LoopI := 1 to NumPlayers do
    if (Players[LoopI].Guidance[2] > 0) and (Players[LoopI].f23 <> 0) then
      AnyMagnet := True;
  Split := True;
  Steps := 0;
  Away := False;
  repeat
    Split := not Split;
    repeat
      Inc(LoopI);
      if LoopI > LoopK then
      begin
        LoopI := 0;
        Inc(Steps);
      end;
      for I := First to Last do
        if not Done[I] then
        begin
          RX[I] := RX[I] + VX[I] / LoopK;
          RY[I] := RY[I] + VY[I] / LoopK;
          VY[I] := VY[I] + 0.1 / LoopK;
          VX[I] := VX[I] + WindForce / 5000.0 / LoopK;
          X[I] := Trunc(RX[I]);
          Y[I] := Trunc(RY[I]);
          if not Away then
            if (Abs(Y[I] - Players[P].Y) > 40) or (Abs(X[I] - Players[P].X) > 40) then
              Away := True;
          if AnyMagnet then
            for LoopJ := 1 to NumPlayers do
              if (Players[LoopJ].f23 <> 0) and (Players[LoopJ].Guidance[2] > 0) and
                 (Away or (LoopJ <> P)) then
              begin
                DY := Y[I] - Players[LoopJ].Y;
                DX := Players[LoopJ].X - X[I];
                if (Abs(DX) <= 40) and (Abs(DY) <= 40) then
                begin
                  Dist := Trunc(Int(DY) * DY + Int(DX) * DX);
                  if Dist <= 1600 then
                  begin
                    VideoSeg := Seg(SaveBuf^);
                    CopyLine(Players[LoopJ].X, Players[LoopJ].Y, X[I], Y[I], @VGA);
                    VideoSeg := $A000;
                    DrawLine(Players[LoopJ].X, Players[LoopJ].Y, X[I], Y[I], 14);
                    Force := -600.0 / Dist / LoopK;
                    if DX <> 0 then
                    begin
                      Ang := Trunc(RadToDeg(ArcTan(DY / DX)));
                      if DX < 0 then
                        Ang := Ang + 180;
                    end
                    else if DY > 0 then
                      Ang := 90
                    else
                      Ang := 270;
                    VX[I] := VX[I] + Force * CosDeg(Ang);
                    VY[I] := VY[I] - Force * SinDeg(Ang);
                    CopyLine(Players[LoopJ].X, Players[LoopJ].Y, X[I], Y[I], SaveBuf);
                  end;
                end;
              end;
          if (FlySound <> 0) and (SoundOn <> 0) then
            Sound(600 - Trunc(Y[I] * 2));
          if (OldX[I] > 11) and (OldY[I] > 31) and (OldX[I] < 309) then
          begin
            if InvisoBall = 0 then
              ErasePlusMark(OldX[I], OldY[I], BackBuf);
            if ShotTrail <> 0 then
              PlotScreenAndBuf(OldX[I], OldY[I], 100 - P, BackBuf);
          end;
          if (OldX[I] >= 9) and (OldX[I] <= 311) then
          begin
            if InvisoBall = 0 then
              PlotPixel(OldX[I], 29, 0);
            if InvisoBall = 0 then
              PlotPixel(OldX[I], 191, 0);
          end;
          if (OldY[I] >= 29) and (OldY[I] <= 191) then
          begin
            if InvisoBall = 0 then
              PlotPixel(9, OldY[I], 0);
            if InvisoBall = 0 then
              PlotPixel(311, OldY[I], 0);
          end;
          OldX[I] := X[I];
          OldY[I] := Y[I];
          if (X[I] > 11) and (Y[I] > 33) and (X[I] < 309) and (Y[I] < 187) and not Done[I] then
          begin
            for TmpX := -1 to 1 do
              for TmpY := -1 to 1 do
                if Abs(TmpX) + Abs(TmpY) <= 1 then
                begin
                  Pix := PixelAt(X[I] + TmpX, Y[I] + TmpY);
                  if Pix = 2 then
                  begin
                    Hit[I] := Pix;
                    Done[I] := True;
                  end;
                  if (Pix >= 20) and (Pix <= 29) then
                  begin
                    if Players[Pix - 19].Men > 0 then
                      Done[I] := True;
                    Hit[I] := Pix;
                  end;
                end;
          end
          else if WallsBounce <> 0 then
          begin
            if (X[I] <= 10) and (VX[I] < 0) then
            begin
              VX[I] := -VX[I] * WallBounce;
              VY[I] := VY[I] * WallBounce;
            end;
            if (X[I] >= 310) and (VX[I] > 0) then
            begin
              VX[I] := -VX[I] * WallBounce;
              VY[I] := VY[I] * WallBounce;
            end;
            if (Y[I] <= 30) and (VY[I] < 0) then
            begin
              VY[I] := -VY[I] * WallBounce;
              VX[I] := VX[I] * WallBounce;
            end;
            if (Y[I] >= 188) and (VY[I] > 0) then
            begin
              VX[I] := VX[I] * WallBounce;
              VY[I] := -VY[I] * WallBounce;
              if (Abs(VX[I]) < 0.1) and (Abs(VY[I]) < 0.1) then
              begin
                DoneFlag2 := 1;
                Done[I] := True;
              end;
            end;
          end
          else if WallsWrap <> 0 then
          begin
            if X[I] <= 10 then
              RX[I] := RX[I] + 300.0;
            if X[I] >= 310 then
              RX[I] := RX[I] - 300.0;
          end
          else if WallsBounce = 0 then
          begin
            if (X[I] > 310) and (VX[I] > 1.0) and (WindForce > 0) then
              RY[I] := 400;
            if (X[I] < 10) and (VX[I] < 1.0) and (WindForce < 0) then
              RY[I] := 400;
          end;
          if not Split then
            if VY[I] > 0 then
              Done[I] := True;
          if (Abs(VX[I]) > 30.0) or (Abs(VY[I]) > 30.0) then
          begin
            Done[I] := True;
            DoneFlag2 := 1;
          end;
          if WallsBounce = 0 then
          begin
            if Y[I] < -5000 then
            begin
              Done[I] := True;
              if SoundOn <> 0 then
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
          if not Done[I] and (InvisoBall = 0) then
          begin
            if (X[I] > 11) and (Y[I] > 31) and (X[I] < 309) then
              DrawPlusMark(X[I], Y[I]);
            if (X[I] >= 9) and (X[I] <= 311) then
            begin
              PlotPixel(X[I], 29, 13);
              PlotPixel(X[I], 191, 13);
            end;
            if (Y[I] >= 29) and (Y[I] <= 191) then
            begin
              PlotPixel(9, Y[I], 13);
              PlotPixel(311, Y[I], 13);
            end;
          end
          else if (X[I] > 0) and (X[I] < 320) and (Y[I] > 0) and (Y[I] < 200) then
            ErasePlusMark(X[I], Y[I], BackBuf);
          if (Det = 0) and Split and Done[I] and not Exploded[I] then
          begin
            Exploded[I] := True;
            WeaponImpact(P, RX[I], RY[I], Hit[I]);
            for LoopJ := 1 to NumPlayers do
              DrawTank(LoopJ);
          end;
        end;
      DoneFlag2 := 0;
      Alive := 0;
      for LoopJ := 0 to 5 do
        if not Done[LoopJ] then
          Inc(Alive);
      if not Split and (Alive = 5) then
        DoneFlag2 := 1;
      if Split and (Alive = 0) then
        DoneFlag2 := 1;
      if Split and (Alive > 0) then
      begin
        LoopK := ShotSpeed div Alive;
        if ShotSpeed mod Alive <> 0 then
          Inc(LoopK);
      end;
      if LoopK < 1 then
        LoopK := 1;
    until DoneFlag2 <> 0;
    if not Split then
    begin
      First := 1;
      Last := 5;
      for LoopJ := 1 to 5 do
      begin
        Done[LoopJ] := False;
        Hit[LoopJ] := 0;
        RX[LoopJ] := RX[0];
        RY[LoopJ] := RY[0];
        VX[LoopJ] := VX[0];
        VY[LoopJ] := VY[0];
        if Mode = 0 then
        begin
          VX[LoopJ] := VX[LoopJ] + Random * 6.0 - 3.0;
          VY[LoopJ] := VY[LoopJ] + Random * 6.0 - 3.0;
        end;
        if Mode = 1 then
          VX[LoopJ] := VX[LoopJ] + (LoopJ - 3) * 1.75;
        if Mode = 2 then
          VY[LoopJ] := VY[LoopJ] + (LoopJ - 3) * 1.75;
        OldX[LoopJ] := OldX[0];
        OldY[LoopJ] := OldY[0];
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
    for LoopI := 1 to 5 do
    begin
      WeaponImpact(P, RX[LoopI], RY[LoopI], Hit[LoopI]);
      for LoopJ := 1 to NumPlayers do
        DrawTank(LoopJ);
    end;
  NoSound;
  ExplodeSpeed := SavedDelay;
end;

{ laser beam of player P: charges the beam colour, then traces a straight
  beam that cuts through dirt and tanks until its energy (power) is used up }
{#U1615_3550}
procedure FireLaser(P: Integer);
var
  R, G, B: Integer;                   { bp-2, bp-4, bp-6 }
  Ang: Integer;                       { bp-8 }
  Energy: Integer;                    { bp-0A }
  StepR, StepB, StepG: Real;          { bp-10, bp-16, bp-1C }
  Color: Integer;                     { bp-1E }
  Pix: Integer;                       { bp-20 }
  Hit: array[1..10] of Boolean;       { bp-2A }
begin
  FillChar(Hit, 10, 0);
  Hit[P] := True;
  if Players[P].f1B <> 0 then
  begin
    if Players[P].f1B > Players[P].Ammo[5] then
      Players[P].f1B := Players[P].Ammo[5];
    Players[P].Ammo[5] := Players[P].Ammo[5] - Players[P].f1B;
    UpdatePlayerColor(Players[P]);
    GetPlayerRGB(R, G, B, Players[P]);
    Color := P + 19;
    SetRGB(254, R, G, B);
    DrawLine(Players[P].X, Players[P].Y,
      Players[P].X + Trunc(Cos(DegToRad(Players[P].f1D)) * 8.0) * Players[P].f1F,
      Players[P].Y - Trunc(Sin(DegToRad(Players[P].f1D)) * 8.0), 254);
    DrawTankBody(Players[P].X, Players[P].Y, Color);
    StepR := (63 - R) / 100.0;
    StepG := (63 - G) / 100.0;
    StepB := -B / 100.0;
    for LoopI := 1 to 100 do
    begin
      BlastPal[LoopI].R := Trunc(R + StepR * LoopI);
      BlastPal[LoopI].G := Trunc(G + StepG * LoopI);
      BlastPal[LoopI].B := Trunc(B + StepB * LoopI);
      if SoundOn <> 0 then
        Sound(50 * LoopI);
    end;
    for LoopJ := 1 to 2 do
    begin
      for LoopI := 1 to 100 do
      begin
        SetRGB(254, BlastPal[LoopI].R, BlastPal[LoopI].G, BlastPal[LoopI].B);
        Delay(ExplodeSpeed div LoopJ);
        if SoundOn <> 0 then
          Sound(50 * LoopI);
      end;
      for LoopI := 100 downto 1 do
      begin
        SetRGB(254, BlastPal[LoopI].R, BlastPal[LoopI].G, BlastPal[LoopI].B);
        Delay(ExplodeSpeed div LoopJ);
        if SoundOn <> 0 then
          Sound(50 * LoopI);
      end;
    end;
    for LoopI := 1 to 100 do
    begin
      SetRGB(254, BlastPal[LoopI].R, BlastPal[LoopI].G, BlastPal[LoopI].B);
      if SoundOn <> 0 then
        Sound(50 * LoopI);
      Delay(ExplodeSpeed div LoopJ);
    end;
    if SoundOn <> 0 then
    begin
      Sound(111); Delay(6);
      Sound(222); Delay(6);
      Sound(333); Delay(9);
      Sound(444); Delay(9);
      Sound(555); Delay(9);
      Sound(666); Delay(9);
      Sound(777); Delay(9);
      Sound(888); Delay(9);
      Sound(999); Delay(9);
      Sound(1111); Delay(20);
      Sound(1333); Delay(33);
      Sound(1777); Delay(33);
      Sound(2111); Delay(40);
      NoSound;
    end;
    Energy := 10 * Players[P].f1B;
    if Players[P].f1F > 0 then
      Ang := Players[P].f1D
    else
      Ang := 90 - Players[P].f1D + 90;
    HitColor := 0;
    if Random < 0.2 then
      ApplyDamage(1, 0, Players[P]);
    ShotX := Players[P].X + Players[P].f1F *
      (Cos(DegToRad(Players[P].f1D)) * 7.0);
    ShotY := Players[P].Y - Sin(DegToRad(Players[P].f1D)) * 7.0;
    ShotVX := Cos(DegToRad(Ang));
    ShotVY := -Sin(DegToRad(Ang));
    DoneFlag := 0;
    for LoopI := 1 to NumPlayers do
      SetRGB(100 - LoopI, 32 div Players[LoopI].f60,
        32 div Players[LoopI].f62, 32 div Players[LoopI].f64);
    DoneFlag2 := 1;
    LaserScale := 53.0 / (10 * Players[P].f1B);
    repeat
      ShotX := ShotX + ShotVX;
      ShotY := ShotY + ShotVY;
      Dec(Energy, 10);
      R := Trunc(Energy * LaserScale + 10.0);
      SetRGB(254, R, R, 0);
      Pix := PixelAt(Trunc(ShotX), Trunc(ShotY));
      if Pix = 2 then
        for LoopJ := 1 to 15 do
        begin
          TmpX := Trunc(ShotX - ShotVX * Random(20));
          TmpY := Trunc(ShotY - ShotVY * Random(20));
          if SoundOn <> 0 then
            Sound(Random(500 * LoopJ) + 500);
          LaserPixel := GetPixel(TmpX, TmpY);
          if (TmpX >= 11) and (TmpX <= 309) and (TmpY >= 31) and (TmpY <= 189) and
             (LaserPixel <> 254) and not ((LaserPixel >= 20) and (LaserPixel <= 29)) then
            CopyPixel(TmpX, TmpY, BackBuf);
        end;
      if (Pix > 19) and (Pix < 30) and (Players[Pix - 19].Men > 0) then
      begin
        if not Hit[Pix - 19] then
          Inc(Players[P].f6C);
        Hit[Pix - 19] := True;
        Energy := Energy - 10;
        if Players[Pix - 19].Guidance[0] <= 0 then
        begin
          for LoopJ := 1 to 15 do
          begin
            repeat
              Paths[1, LoopJ].X := Trunc(ShotX - Random(40) + 20.0);
              Paths[1, LoopJ].Y := Trunc(ShotY - Random(40) + 20.0);
              LaserPixel := GetPixel(Paths[1, LoopJ].X, Paths[1, LoopJ].Y);
            until (LaserPixel < 20) or ((LaserPixel > 29) and (LaserPixel <> 254)) or (Pix = LaserPixel);
            if SoundOn <> 0 then
              Sound(Random(500 * LoopJ) + 500);
            Delay(ShotSpeed div 5);
            B := Paths[1, LoopJ].X;
            LaserY := Paths[1, LoopJ].Y;
            if (B >= 11) and (B <= 309) and (LaserY >= 31) and (LaserY <= 189) then
              PlotPixel(B, LaserY, Pix);
          end;
          for LoopJ := 1 to 15 do
          begin
            if SoundOn <> 0 then
              Sound(Random(500 * LoopJ) + 500);
            B := Paths[1, LoopJ].X;
            LaserY := Paths[1, LoopJ].Y;
            if (B >= 11) and (B <= 309) and (LaserY >= 31) and (LaserY <= 189) then
              CopyPixel(B, LaserY, BackBuf);
          end;
        end;
        LaserPixel := Pix - 19;
        ApplyDamage(3, 0, Players[LaserPixel]);
        ShotX := ShotX - ShotVX;
        ShotY := ShotY - ShotVY;
      end;
      Delay(ShotSpeed div 2);
      if SoundOn <> 0 then
        Sound(Trunc(Random(12 * Energy) + 100));
      if Energy <= 0 then
        DoneFlag := 1;
      if WallsBounce <> 0 then
      begin
        if (ShotX <= 11) and (ShotVX < 0) then
          ShotVX := -ShotVX;
        if (ShotX >= 309) and (ShotVX > 0) then
          ShotVX := -ShotVX;
        if (ShotY <= 31) and (ShotVY < 0) then
          ShotVY := -ShotVY;
        if (ShotY >= 189) and (ShotVY > 0) then
          ShotVY := -ShotVY;
      end
      else
      begin
        if WallsWrap <> 0 then
        begin
          if ShotX <= 10 then
            ShotX := ShotX + 300.0;
          if ShotX >= 310 then
            ShotX := ShotX - 300.0;
        end
        else
        begin
          if (ShotX <= 11) and (ShotVX < 0) then
            DoneFlag := 1;
          if (ShotX >= 309) and (ShotVX > 0) then
            DoneFlag := 1;
        end;
        if (ShotY <= 31) and (ShotVY < 0) then
          DoneFlag := 1;
        if (ShotY >= 189) and (ShotVY > 0) then
          DoneFlag := 1;
      end;
      if DoneFlag = 0 then
        PlotPixel(Trunc(ShotX), Trunc(ShotY), 254);
      if Energy <= 0 then
        DoneFlag := 1;
    until DoneFlag = 1;
    SetRGB(254, 0, 0, 0);
    RestoreColorRange(254, 254, BackBuf);
    NoSound;
  end;
end;

{ play one round: choose the wind, pick the starting player, then let the
  living players fire in turn until only one team is left }
{#U1615_46C2}
procedure PlayRound;
var
  Cur: Integer;                       { bp-2 }
  Unused: array[0..5] of Byte;        { bp-8 }
begin
  EnableHotKeys;
  DisableBiosKeys;
  SetTextStyle(0, 0, 1);
  SetupRound;
  RoundWind := WindControl;
  if WindControl = 5 then
    RoundWind := Random(5);
  repeat
    case RoundWind of
      0: LoopJ := 0;
      1: LoopJ := 20;
      2: LoopJ := 100;
      3: LoopJ := 300;
      4: LoopJ := 4000;
    end;
    LoopI := Random(LoopJ);
    WindForce := LoopJ div 2 - LoopI;
  until Abs(WindForce) >= LoopJ div 10;
  if Random < 0.1 then
    WindForce := WindForce * 4;
  if Random < 0.1 then
    WindForce := WindForce * 4;
  if Random < 0.05 then
    WindForce := WindForce * 4;
  if Random < 0.05 then
    WindForce := WindForce * 4;
  if WindForce > 30000 then
    WindForce := 30000;
  if WindForce < -30000 then
    WindForce := -30000;
  SetColor(5);
  SetTextJustify(0, 2);
  OutTextXY(8, 0, 'Angle:');
  OutTextXY(8, 10, 'Power:');
  OutTextXY(216, 0, 'Direction( )');
  OutTextXY(216, 10, 'Men:');
  SetTextJustify(1, 2);
  SetColor(9);
  if WindForce >= 0 then
    LoopI := 1
  else
    LoopI := -1;
  OutTextXY(160, 10, 'Wind: ' + IntToStr(Abs(WindForce)) + ' ' + DirChars[LoopI]);
  DrawWeaponBar;
  repeat
    DoneFlag := 1;
    Cur := Random(NumPlayers);
    for LoopI := 1 to NumPlayers do
      if Players[LoopI].f72 < Players[Cur + 1].f72 then
        DoneFlag := 0;
  until DoneFlag <> 0;
  Inc(Players[Cur + 1].f72);
  TurnLap := 1;
  repeat
    repeat
      Inc(Cur);
      if Cur > NumPlayers then
      begin
        Cur := 1;
        Inc(TurnLap);
      end;
    until Players[Cur].f23 <> 0;
    CurPlayer := Cur;
    DrawTank(Cur);
    Inc(Players[Cur].f5E);
    Inc(Players[Cur].f70);
    if Players[Cur].Ammo[Players[Cur].Weapon] = 0 then
      repeat
        Inc(Players[Cur].Weapon);
        if Players[Cur].Weapon > 17 then
          Players[Cur].Weapon := 0;
      until Players[Cur].Ammo[Players[Cur].Weapon] > 0;
    UpdateWeaponLamps(Cur);
    SetFillStyle(1, 0);
    Bar(109, 0, 211, 7);
    SetColor(Cur + 19);
    SetTextJustify(1, 2);
    OutTextXY(160, 0, Players[Cur].Name);
    SetTextJustify(1, 2);
    SetColor(9);
    if WindForce >= 0 then
      LoopI := 1
    else
      LoopI := -1;
    OutTextXY(160, 10, 'Wind: ' + IntToStr(Abs(WindForce)) + ' ' + DirChars[LoopI]);
    SetTextJustify(0, 2);
    SetColor(14);
    if Players[Cur].f1B > 10 * Players[Cur].Men then
      Players[Cur].f1B := 10 * Players[Cur].Men;
    DoneFlag := 0;
    PlayerAim(Cur);
    CurPlayer := Cur;
    if Players[Cur].Weapon in [0..4, 6, 8..17] then
      FireShell(Cur);
    if Players[Cur].Weapon in [5] then
      FireLaser(Cur);
    if Players[Cur].Weapon in [7] then
      FireMirv(Cur);
    for LoopI := 1 to NumPlayers do
      DrawTank(LoopI);
    if CrumblePct > 0 then
      TryCrumbleDirt;
    if TanksFall <> 0 then
      DropTanks;
    with Players[Cur] do
    begin
      if ShotX > 32767.0 then
        ShotLog[Cur, f5E].HitX := 32767
      else
        ShotLog[Cur, f5E].HitX := Trunc(ShotX);
      ShotLog[Cur, f5E].HitY := Trunc(ShotY);
      ShotLog[Cur, f5E].Dir := Players[Cur].f1F;
      ShotLog[Cur, f5E].Power := Players[Cur].f1B;
      ShotLog[Cur, f5E].Angle := Players[Cur].f1D;
      ShotLog[Cur, f5E].HitY := Trunc(ShotY);
    end;
    UpdateWeaponLamps(Cur);
    NoSound;
    repeat
      TankDied := 0;
      for LoopI := 1 to NumPlayers do
        if (Players[LoopI].Men <= 0) and (Players[LoopI].f23 <> 0) then
        begin
          TankDied := 1;
          Players[LoopI].f23 := 0;
          DrawTank(LoopI);
          SetFillStyle(1, 0);
          Bar(109, 0, 211, 7);
          SetColor(LoopI + 19);
          SetTextJustify(1, 2);
          OutTextXY(160, 0, Players[LoopI].Name);
          LoopJ := Random(7);
          case LoopJ of
            0: TankDeathNuke(LoopI);
            1: TankDeathDebris(LoopI, 0);
            2: TankDeathFunky(LoopI);
            3: TankDeathDebris(LoopI, 1);
            4: TankDeathSparks(LoopI);
            5: TankDeathPulse(LoopI);
            6: TankDeathBlast(LoopI);
          end;
          if Players[CurPlayer].Team <> Players[LoopI].Team then
          begin
            Players[CurPlayer].Score := Players[CurPlayer].Score + 1500;
            Players[CurPlayer].f6E := Players[CurPlayer].f6E + 1;
          end
          else
            Players[CurPlayer].Score := Players[CurPlayer].Score - 1000;
          DrawPlayfieldFrame;
          TryCrumbleDirt;
          if TanksFall <> 0 then
            DropTanks;
          SetTextJustify(0, 2);
        end;
      NoSound;
      if (TankDied = 0) and (TurnLap > 10) and (TurnLap > Random(100)) then
      begin
        LightningStrike(0);
        TankDied := 1;
      end;
    until TankDied = 0;
    LoopK := 0;
    RoundOver := 1;
    for LoopI := 1 to NumPlayers do
      if Players[LoopI].f23 <> 0 then
        LoopK := Players[LoopI].Team;
    for LoopI := 1 to NumPlayers do
      if (Players[LoopI].f23 <> 0) and (LoopK <> Players[LoopI].Team) then
        RoundOver := 0;
    RoundWinner := 0;
    if RoundOver <> 0 then
    begin
      RoundWinner := LoopK;
      RoundOver := 1;
    end;
  until RoundOver <> 0;
  DisableHotKeys;
  for LoopI := 1 to NumPlayers do
  begin
    LoopJ := 100 - Players[LoopI].Men;
    if (Players[LoopI].Men > 100) or (Players[LoopI].Men < 0) then
      LoopJ := 100;
    Players[LoopI].f68 := Players[LoopI].f68 + LoopJ;
  end;
  EnableBiosKeys;
end;

end.
