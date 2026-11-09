{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U1F69;

{ A player's turn: falling tanks, the status bar, aiming/power/weapon
  selection by keyboard, mouse or computer player.

  NOTE: procs calling Crt.Delay show 'diff' in cmp.py only because the
  original's CRT.Delay differs from the one in toolchain TURBO.TPL; with CRT
  fingerprints relaxed every proc here matches. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure DropTanks;
procedure DrawPlayfieldFrame;
procedure TryCrumbleDirt;
procedure PlayerAim(P: Integer);
function  ControlAction(Ctrl, P: Integer): Integer;

implementation




uses
  U20C6, U0098, U1615, U22B7, U2390;

var
  KbdHead: Word absolute $40:$1A;   { BIOS keyboard buffer pointers }
  KbdTail: Word absolute $40:$1C;

{ Let tanks that lost the ground under them fall down. }
{#U1F69_0024}
procedure DropTanks;
var
  Falling, Landed: Boolean;
  P, X, Y: Integer;
begin
  DrawPlayfieldFrame;
  for P := 1 to NumPlayers do
  begin
    Falling := Boolean(Players[P].f23);
    for LoopJ := -3 to 3 do
      if PixelAt(Players[P].X + LoopJ, Players[P].Y + 1) in [2, 13] then
        Falling := False;
    if (PixelAt(Players[P].X + 4, Players[P].Y + 1) in [2, 13]) and
       (PixelAt(Players[P].X - 4, Players[P].Y + 1) in [2, 13]) then
      Falling := False;
    if Falling then
    begin
      Landed := False;
      SetColor(0);
      X := Players[P].X;
      Y := Players[P].Y;
      CopyLine(X, Y,
        X + Trunc(Cos(DegToRad(Players[P].f1D)) * 8) * Players[P].f1F,
        Y - Trunc(Sin(DegToRad(Players[P].f1D)) * 8),
        BackBuf);
      repeat
        X := Players[P].X;
        Y := Players[P].Y;
        DrawTankBody(X, Y, P + 19);
        UpdatePlayerColor(Players[P]);
        Landed := True;
        Inc(Players[P].Y);
        if PixelAt(Players[P].X + 4, Players[P].Y + 1) in [2, 13] then
          Dec(Players[P].X);
        if PixelAt(Players[P].X - 4, Players[P].Y + 1) in [2, 13] then
          Inc(Players[P].X);
        for LoopJ := -4 to 4 do
          if not (PixelAt(Players[P].X + LoopJ, Players[P].Y + 1) in [2, 13]) then
            Landed := False;
        ApplyDamage(Random(3) + 1, 1, Players[P]);
        Delay(FallSpeed);
        EraseTankBody(X, Y, BackBuf);
      until Landed;
    end;
    DrawTank(P);
  end;
end;

{ Draw the playfield frame. }
{#U1F69_0366}
procedure DrawPlayfieldFrame;
begin
  DrawRect(8, 28, 312, 192, 13);
  DrawRect(10, 30, 310, 190, 13);
  if not (RoundWall in [1..3]) then
    DrawLine(11, 189, 309, 189, 2);
end;

{#U1F69_03C7}
procedure TryCrumbleDirt;
var
  Unused: Extended;               { 10 bytes of unused locals in the original }
begin
  DrawPlayfieldFrame;
  if Random * 100 <= CrumblePct then
    DropDirt(FallList, BackBuf);
end;

{ Player P's turn: read controls until he fires. }
{#U1F69_040D}
procedure PlayerAim(P: Integer);
var
  Key: Integer;
  Ok: Boolean;
  Unused: Byte;
begin
  DoneFlag := 0;
  UpdateWeaponLamps(P);
  DrawPlayfieldFrame;
  SetColor(14);
  SetFillStyle(SolidFill, 0);
  SetTextJustify(LeftText, TopText);
  Bar(56, 0, 70, 7);
  OutTextXY(56, 0, IntToStr(Players[P].f1D));
  Bar(56, 10, 86, 17);
  OutTextXY(56, 10, IntToStr(Players[P].f1B));
  Bar(296, 0, 302, 7);
  OutTextXY(296, 0, DirChars[Players[P].f1F]);
  Bar(248, 10, 270, 17);
  OutTextXY(248, 10, IntToStr(Players[P].Men));
  SetColor(15);
  repeat
    Key := 0;
    repeat
      Key := ControlAction(Controls[P], P);
    until Key <> 0;
    if (Key = 7) or (Key = 8) then
    begin
      { previous / next weapon }
      TmpR := Players[P].Weapon;
      Ok := False;
      repeat
        if Key = 7 then Dec(Players[P].Weapon);
        if Key = 8 then Inc(Players[P].Weapon);
        if Players[P].Weapon < 0 then Players[P].Weapon := 17;
        if Players[P].Weapon > 17 then Players[P].Weapon := 0;
        if Players[P].Ammo[Players[P].Weapon] > 0 then Ok := True;
        if (Players[P].Weapon = 5) and
           (Players[P].Ammo[Players[P].Weapon] < 100) then Ok := False;
      until Ok;
      for TmpC := 0 to 63 do
      begin
        Inc(TmpC);
        Inc(TmpC);
        Inc(TmpC);
        RGBHook(TmpR + 100, 63, TmpC, TmpC);
        RGBHook(Players[P].Weapon + 100, 63, 63 - TmpC, 63 - TmpC);
      end;
    end
    else if (Key = 9) or (Key = 10) then
    begin
      { toggle guidance systems }
      if (Key = 9) and (Players[P].Accessory[0] > 0) then
        Players[P].f26 := Players[P].f26 xor 1;
      if (Key = 10) and (Players[P].Accessory[1] > 0) then
        Players[P].f26 := Players[P].f26 xor 2;
      if Players[P].Accessory[0] > 0 then
        RGBHook(118, 63, 63, 63)
      else
        RGBHook(118, 0, 0, 0);
      if Players[P].Accessory[1] > 0 then
        RGBHook(119, 63, 63, 63)
      else
        RGBHook(119, 0, 0, 0);
      if Players[P].f26 and 1 = 1 then RGBHook(118, 63, 0, 0);
      if Players[P].f26 and 2 = 2 then RGBHook(119, 63, 0, 0);
    end
    else if (Key = 1) or (Key = 2) then
    begin
      { turn the turret }
      SetColor(0);
      CopyLine(Players[P].X, Players[P].Y,
        Players[P].X + Trunc(Cos(DegToRad(Players[P].f1D)) * 8) * Players[P].f1F,
        Players[P].Y - Trunc(Sin(DegToRad(Players[P].f1D)) * 8),
        BackBuf);
      if Key = 2 then Players[P].f1D := Players[P].f1D - Players[P].f1F;
      if Key = 1 then Players[P].f1D := Players[P].f1D + Players[P].f1F;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      if Players[P].f1D > 90 then
      begin
        Players[P].f1F := -Players[P].f1F;
        Players[P].f1D := 180 - Players[P].f1D;
        Bar(296, 0, 302, 7);
        OutTextXY(296, 0, DirChars[Players[P].f1F]);
      end;
      if Players[P].f1D < 0 then
      begin
        Players[P].f1F := -Players[P].f1F;
        Players[P].f1D := Abs(Players[P].f1D);
        Bar(296, 0, 302, 7);
        OutTextXY(296, 0, DirChars[Players[P].f1F]);
      end;
      DrawTank(P);
      if SoundOn <> 0 then
        if Key = 1 then
        begin
          Sound(1750);
          Delay(10);
          NoSound;
        end
        else
        begin
          Sound(2000);
          Delay(10);
          NoSound;
        end;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      Bar(56, 0, 70, 7);
      OutTextXY(56, 0, IntToStr(Players[P].f1D));
      SetColor(15);
    end;
    if (Key = 3) or (Key = 4) then
    begin
      { power }
      if Key = 4 then Players[P].f1B := Players[P].f1B + 1;
      if Key = 3 then Players[P].f1B := Players[P].f1B - 1;
      if Players[P].f1B > 10 * Players[P].Men then
        Players[P].f1B := 10 * Players[P].Men;
      if Players[P].f1B < 0 then Players[P].f1B := 0;
      if SoundOn <> 0 then
        if Key = 3 then
        begin
          Sound(1500);
          Delay(10);
          NoSound;
        end
        else
        begin
          Sound(2500);
          Delay(10);
          NoSound;
        end;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      Bar(56, 10, 86, 17);
      OutTextXY(56, 10, IntToStr(Players[P].f1B));
      SetColor(15);
    end;
    if (Players[P].Weapon = 5) and
       (Players[P].f1B > Players[P].Ammo[5]) then
    begin
      Players[P].f1B := Players[P].Ammo[5];
      if SoundOn <> 0 then
      begin
        Sound(1500);
        Delay(10);
        Sound(2500);
        Delay(10);
        NoSound;
      end;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      Bar(56, 10, 86, 17);
      OutTextXY(56, 10, IntToStr(Players[P].f1B));
      SetColor(15);
    end;
    if Key = 6 then
    begin
      { flip direction }
      SetColor(0);
      CopyLine(Players[P].X, Players[P].Y,
        Players[P].X + Trunc(Cos(DegToRad(Players[P].f1D)) * 8) * Players[P].f1F,
        Players[P].Y - Trunc(Sin(DegToRad(Players[P].f1D)) * 8),
        BackBuf);
      Players[P].f1F := -Players[P].f1F;
      DrawTank(P);
      if SoundOn <> 0 then
      begin
        Sound(1750);
        Delay(5);
        Sound(2000);
        Delay(5);
        Sound(1500);
        Delay(5);
        Sound(1250);
        Delay(5);
        NoSound;
      end;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      Bar(296, 0, 302, 7);
      OutTextXY(296, 0, DirChars[Players[P].f1F]);
      SetColor(15);
    end;
    if Key = 5 then DoneFlag := 1;
  until DoneFlag <> 0;
  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
  if Players[P].f26 > 0 then
    ChooseGuideTarget(Controls[P], P);
end;

{ Read one control action for player P from controller Ctrl
  (1 = keyboard, 2 = mouse, 3 = computer).  Returns
  1/2 turn turret, 3/4 power down/up, 5 fire, 6 flip direction,
  7/8 previous/next weapon, 9/10 toggle guidance system, 0 = nothing. }
{#U1F69_0EF4}
function ControlAction(Ctrl, P: Integer): Integer;
var
  MX, MY, Key: Integer;
  B1, B2: Boolean;
  I: Integer;
begin
  Key := 0;
  if Players[P].Ammo[Players[P].Weapon] <= 0 then
  begin
    ControlAction := 8;
    Exit;
  end;
  if (Players[P].Ammo[Players[P].Weapon] <= 100) and
     (Players[P].Weapon = 5) then
  begin
    ControlAction := 8;
    Exit;
  end;
  Key := 0;
  if Ctrl = 1 then
  begin
    Key := 0;
    if (KeyDown[$53] <> 0) and (KeyDown[$52] <> 0) then
    begin
      { Ins+Del: cheat mode until Ins+Del or Space }
      KbdHead := KbdTail;
      KeyDown[$53] := 0;
      KeyDown[$52] := 0;
      repeat
        if KeyDown[$2E] <> 0 then RestoreColorRange(2, 2, BackBuf);
        if KeyDown[$11] <> 0 then
          for I := 0 to 17 do Players[P].Ammo[I] := 999;
        if KeyDown[$22] <> 0 then
          for I := 0 to 1 do Players[P].Accessory[I] := 10;
        if KeyDown[$20] <> 0 then
          for I := 0 to 2 do Players[P].Guidance[I] := 1000;
      until (KeyDown[$53] <> 0) and (KeyDown[$52] <> 0) or (KeyDown[$39] <> 0);
      KbdHead := KbdTail;
      KeyDown[$39] := 0;
      KeyDown[$53] := 0;
      KeyDown[$52] := 0;
    end;
    if KeyDown[$17] <> 0 then
    begin
      Key := 6;
      repeat until KeyDown[$17] = 0;
    end;
    if KeyDown[$23] <> 0 then
    begin
      Key := 9;
      repeat until KeyDown[$23] = 0;
    end;
    if KeyDown[$2F] <> 0 then
    begin
      Key := 10;
      repeat until KeyDown[$2F] = 0;
    end;
    if (KeyDown[$0F] <> 0) and ((KeyDown[$2A] <> 0) or (KeyDown[$36] <> 0)) then
    begin
      Key := 7;
      repeat until KeyDown[$0F] = 0;
    end;
    if KeyDown[$0F] <> 0 then
    begin
      Key := 8;
      repeat until KeyDown[$0F] = 0;
    end;
    if KeyDown[$17] <> 0 then
    begin
      Key := 6;
      repeat until KeyDown[$17] = 0;
    end;
    if (KeyDown[$39] <> 0) or (KeyDown[$1C] <> 0) or (KeyDown[$11C] <> 0) then
      Key := 5;
    if KeyDown[$0B] <> 0 then ShowPlayerInventory(0, Ctrl);
    if KeyDown[$02] <> 0 then ShowPlayerInventory(1, Ctrl);
    if KeyDown[$03] <> 0 then ShowPlayerInventory(2, Ctrl);
    if KeyDown[$04] <> 0 then ShowPlayerInventory(3, Ctrl);
    if KeyDown[$05] <> 0 then ShowPlayerInventory(4, Ctrl);
    if KeyDown[$06] <> 0 then ShowPlayerInventory(5, Ctrl);
    if KeyDown[$07] <> 0 then ShowPlayerInventory(6, Ctrl);
    if KeyDown[$08] <> 0 then ShowPlayerInventory(7, Ctrl);
    if KeyDown[$09] <> 0 then ShowPlayerInventory(8, Ctrl);
    if KeyDown[$0A] <> 0 then ShowPlayerInventory(9, Ctrl);
    if (KeyDown[$4B] <> 0) or (KeyDown[$14B] <> 0) then
    begin
      Key := 1;
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$4B] = 0) and (KeyDown[$14B] = 0);
    end;
    if (KeyDown[$4D] <> 0) or (KeyDown[$14D] <> 0) then
    begin
      Key := 2;
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$4D] = 0) and (KeyDown[$14D] = 0);
    end;
    if (KeyDown[$50] <> 0) or (KeyDown[$150] <> 0) then
    begin
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$50] = 0) and (KeyDown[$150] = 0);
      Key := 3;
    end;
    if (KeyDown[$48] <> 0) or (KeyDown[$148] <> 0) then
    begin
      Key := 4;
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$48] = 0) and (KeyDown[$148] = 0);
    end;
    if (KeyDown[$49] <> 0) or (KeyDown[$149] <> 0) then
    begin
      Key := 4;
      Players[P].f1B := Players[P].f1B + 99;
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$49] = 0) and (KeyDown[$149] = 0);
    end;
    if (KeyDown[$51] <> 0) or (KeyDown[$151] <> 0) then
    begin
      Key := 3;
      Players[P].f1B := Players[P].f1B - 99;
      if (KeyDown[$38] <> 0) or (KeyDown[$138] <> 0) then
        repeat until (KeyDown[$51] = 0) and (KeyDown[$151] = 0);
    end;
  end;
  if Ctrl = 2 then
  begin
    ShowMouseCursor;
    B1 := MouseBtnsDown(1);
    B2 := MouseBtnsDown(2);
    if not B1 and not B2 then
    begin
      ControlAction := 0;
      Exit;
    end;
    MX := MouseX;
    MY := MouseY;
    HideMouseCursor;
    if PixelAt(MX, MY) in [20..29] then
      ShowPlayerInventory(PixelAt(MX, MY) - 19, 2);
    if (MY >= 18) and (MY <= 27) and (MX >= BarButtonX[0]) and (MX < BarButtonX[18]) then
    begin
      if B1 then Key := 7;
      if B2 then Key := 8;
      repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
    end;
    if (MY >= 18) and (MY <= 27) and (MX >= BarButtonX[18]) and (MX < BarButtonX[19]) then
    begin
      Key := 9;
      repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
    end;
    if (MY >= 18) and (MY <= 27) and (MX >= BarButtonX[19]) and (MX < BarButtonX[20]) then
    begin
      Key := 10;
      repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
    end;
    if (MX >= 56) and (MY >= 0) and (MX <= 70) and (MY <= 7) then
    begin
      if B1 then Key := 1;
      if B2 then Key := 2;
    end;
    if (MX >= 56) and (MY >= 10) and (MX <= 86) and (MY <= 17) then
    begin
      if B1 then Key := 3;
      if B2 then Key := 4;
    end;
    if (MX >= 8) and (MY >= 10) and (MX <= 54) and (MY <= 17) then
    begin
      if B1 then
      begin
        Key := 3;
        Players[P].f1B := Players[P].f1B - 99;
      end;
      if B2 then
      begin
        Key := 4;
        Players[P].f1B := Players[P].f1B + 99;
      end;
    end;
    if (MX >= 296) and (MY >= 0) and (MX <= 302) and (MY <= 7) then
    begin
      Key := 6;
      repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
    end;
    if B1 and B2 then Key := 5;
  end;
  if Ctrl = 3 then
    Key := PComputer(Tanks[P])^.Think;
  if Ctrl <> 3 then
    Delay(TurretSpeed);
  ControlAction := Key;
end;

end.
