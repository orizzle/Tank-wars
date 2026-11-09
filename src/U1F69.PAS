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

procedure U1F69_0024;
procedure U1F69_0366;
procedure U1F69_03C7;
procedure U1F69_040D(P: Integer);
function  U1F69_0EF4(Ctrl, P: Integer): Integer;

implementation




uses
  U20C6, U0098, U1615, U22B7, U2390;

var
  KbdHead: Word absolute $40:$1A;   { BIOS keyboard buffer pointers }
  KbdTail: Word absolute $40:$1C;

{ Let tanks that lost the ground under them fall down. }
{#U1F69_0024}
procedure U1F69_0024;
var
  Falling, Landed: Boolean;
  P, X, Y: Integer;
begin
  U1F69_0366;
  for P := 1 to g_46B4 do
  begin
    Falling := Boolean(Players_3F0E[P].f23);
    for g_4620 := -3 to 3 do
      if U2823_0BFF(Players_3F0E[P].X + g_4620, Players_3F0E[P].Y + 1) in [2, 13] then
        Falling := False;
    if (U2823_0BFF(Players_3F0E[P].X + 4, Players_3F0E[P].Y + 1) in [2, 13]) and
       (U2823_0BFF(Players_3F0E[P].X - 4, Players_3F0E[P].Y + 1) in [2, 13]) then
      Falling := False;
    if Falling then
    begin
      Landed := False;
      SetColor(0);
      X := Players_3F0E[P].X;
      Y := Players_3F0E[P].Y;
      U2823_0AC0(X, Y,
        X + Trunc(Cos(U2918_00D9(Players_3F0E[P].f1D)) * 8) * Players_3F0E[P].f1F,
        Y - Trunc(Sin(U2918_00D9(Players_3F0E[P].f1D)) * 8),
        BackBuf_E49A);
      repeat
        X := Players_3F0E[P].X;
        Y := Players_3F0E[P].Y;
        U0098_05D2(X, Y, P + 19);
        U26A9_014E(Players_3F0E[P]);
        Landed := True;
        Inc(Players_3F0E[P].Y);
        if U2823_0BFF(Players_3F0E[P].X + 4, Players_3F0E[P].Y + 1) in [2, 13] then
          Dec(Players_3F0E[P].X);
        if U2823_0BFF(Players_3F0E[P].X - 4, Players_3F0E[P].Y + 1) in [2, 13] then
          Inc(Players_3F0E[P].X);
        for g_4620 := -4 to 4 do
          if not (U2823_0BFF(Players_3F0E[P].X + g_4620, Players_3F0E[P].Y + 1) in [2, 13]) then
            Landed := False;
        U26A9_0004(Random(3) + 1, 1, Players_3F0E[P]);
        Delay(g_E79C);
        U0098_066A(X, Y, BackBuf_E49A);
      until Landed;
    end;
    U0098_07A3(P);
  end;
end;

{ Draw the playfield frame. }
{#U1F69_0366}
procedure U1F69_0366;
begin
  U2823_0031(8, 28, 312, 192, 13);
  U2823_0031(10, 30, 310, 190, 13);
  if not (g_46C6 in [1..3]) then
    U2823_09E4(11, 189, 309, 189, 2);
end;

{#U1F69_03C7}
procedure U1F69_03C7;
var
  Unused: Extended;               { 10 bytes of unused locals in the original }
begin
  U1F69_0366;
  if Random * 100 <= g_E77A then
    U0098_047B(PalPtr_DE7C, BackBuf_E49A);
end;

{ Player P's turn: read controls until he fires. }
{#U1F69_040D}
procedure U1F69_040D(P: Integer);
var
  Key: Integer;
  Ok: Boolean;
  Unused: Byte;
begin
  g_462F := 0;
  U1615_0000(P);
  U1F69_0366;
  SetColor(14);
  SetFillStyle(SolidFill, 0);
  SetTextJustify(LeftText, TopText);
  Bar(56, 0, 70, 7);
  OutTextXY(56, 0, U2918_02FE(Players_3F0E[P].f1D));
  Bar(56, 10, 86, 17);
  OutTextXY(56, 10, U2918_02FE(Players_3F0E[P].f1B));
  Bar(296, 0, 302, 7);
  OutTextXY(296, 0, DirChar_0064[Players_3F0E[P].f1F]);
  Bar(248, 10, 270, 17);
  OutTextXY(248, 10, U2918_02FE(Players_3F0E[P].Men));
  SetColor(15);
  repeat
    Key := 0;
    repeat
      Key := U1F69_0EF4(Control_E480[P], P);
    until Key <> 0;
    if (Key = 7) or (Key = 8) then
    begin
      { previous / next weapon }
      g_4628 := Players_3F0E[P].Weapon;
      Ok := False;
      repeat
        if Key = 7 then Dec(Players_3F0E[P].Weapon);
        if Key = 8 then Inc(Players_3F0E[P].Weapon);
        if Players_3F0E[P].Weapon < 0 then Players_3F0E[P].Weapon := 17;
        if Players_3F0E[P].Weapon > 17 then Players_3F0E[P].Weapon := 0;
        if Players_3F0E[P].Ammo[Players_3F0E[P].Weapon] > 0 then Ok := True;
        if (Players_3F0E[P].Weapon = 5) and
           (Players_3F0E[P].Ammo[Players_3F0E[P].Weapon] < 100) then Ok := False;
      until Ok;
      for g_462A := 0 to 63 do
      begin
        Inc(g_462A);
        Inc(g_462A);
        Inc(g_462A);
        g_E7C8(g_4628 + 100, 63, g_462A, g_462A);
        g_E7C8(Players_3F0E[P].Weapon + 100, 63, 63 - g_462A, 63 - g_462A);
      end;
    end
    else if (Key = 9) or (Key = 10) then
    begin
      { toggle guidance systems }
      if (Key = 9) and (Players_3F0E[P].Accessory[0] > 0) then
        Players_3F0E[P].f26 := Players_3F0E[P].f26 xor 1;
      if (Key = 10) and (Players_3F0E[P].Accessory[1] > 0) then
        Players_3F0E[P].f26 := Players_3F0E[P].f26 xor 2;
      if Players_3F0E[P].Accessory[0] > 0 then
        g_E7C8(118, 63, 63, 63)
      else
        g_E7C8(118, 0, 0, 0);
      if Players_3F0E[P].Accessory[1] > 0 then
        g_E7C8(119, 63, 63, 63)
      else
        g_E7C8(119, 0, 0, 0);
      if Players_3F0E[P].f26 and 1 = 1 then g_E7C8(118, 63, 0, 0);
      if Players_3F0E[P].f26 and 2 = 2 then g_E7C8(119, 63, 0, 0);
    end
    else if (Key = 1) or (Key = 2) then
    begin
      { turn the turret }
      SetColor(0);
      U2823_0AC0(Players_3F0E[P].X, Players_3F0E[P].Y,
        Players_3F0E[P].X + Trunc(Cos(U2918_00D9(Players_3F0E[P].f1D)) * 8) * Players_3F0E[P].f1F,
        Players_3F0E[P].Y - Trunc(Sin(U2918_00D9(Players_3F0E[P].f1D)) * 8),
        BackBuf_E49A);
      if Key = 2 then Players_3F0E[P].f1D := Players_3F0E[P].f1D - Players_3F0E[P].f1F;
      if Key = 1 then Players_3F0E[P].f1D := Players_3F0E[P].f1D + Players_3F0E[P].f1F;
      SetColor(14);
      SetFillStyle(SolidFill, 0);
      if Players_3F0E[P].f1D > 90 then
      begin
        Players_3F0E[P].f1F := -Players_3F0E[P].f1F;
        Players_3F0E[P].f1D := 180 - Players_3F0E[P].f1D;
        Bar(296, 0, 302, 7);
        OutTextXY(296, 0, DirChar_0064[Players_3F0E[P].f1F]);
      end;
      if Players_3F0E[P].f1D < 0 then
      begin
        Players_3F0E[P].f1F := -Players_3F0E[P].f1F;
        Players_3F0E[P].f1D := Abs(Players_3F0E[P].f1D);
        Bar(296, 0, 302, 7);
        OutTextXY(296, 0, DirChar_0064[Players_3F0E[P].f1F]);
      end;
      U0098_07A3(P);
      if g_E788 <> 0 then
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
      OutTextXY(56, 0, U2918_02FE(Players_3F0E[P].f1D));
      SetColor(15);
    end;
    if (Key = 3) or (Key = 4) then
    begin
      { power }
      if Key = 4 then Players_3F0E[P].f1B := Players_3F0E[P].f1B + 1;
      if Key = 3 then Players_3F0E[P].f1B := Players_3F0E[P].f1B - 1;
      if Players_3F0E[P].f1B > 10 * Players_3F0E[P].Men then
        Players_3F0E[P].f1B := 10 * Players_3F0E[P].Men;
      if Players_3F0E[P].f1B < 0 then Players_3F0E[P].f1B := 0;
      if g_E788 <> 0 then
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
      OutTextXY(56, 10, U2918_02FE(Players_3F0E[P].f1B));
      SetColor(15);
    end;
    if (Players_3F0E[P].Weapon = 5) and
       (Players_3F0E[P].f1B > Players_3F0E[P].Ammo[5]) then
    begin
      Players_3F0E[P].f1B := Players_3F0E[P].Ammo[5];
      if g_E788 <> 0 then
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
      OutTextXY(56, 10, U2918_02FE(Players_3F0E[P].f1B));
      SetColor(15);
    end;
    if Key = 6 then
    begin
      { flip direction }
      SetColor(0);
      U2823_0AC0(Players_3F0E[P].X, Players_3F0E[P].Y,
        Players_3F0E[P].X + Trunc(Cos(U2918_00D9(Players_3F0E[P].f1D)) * 8) * Players_3F0E[P].f1F,
        Players_3F0E[P].Y - Trunc(Sin(U2918_00D9(Players_3F0E[P].f1D)) * 8),
        BackBuf_E49A);
      Players_3F0E[P].f1F := -Players_3F0E[P].f1F;
      U0098_07A3(P);
      if g_E788 <> 0 then
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
      OutTextXY(296, 0, DirChar_0064[Players_3F0E[P].f1F]);
      SetColor(15);
    end;
    if Key = 5 then g_462F := 1;
  until g_462F <> 0;
  repeat until not U2968_0077(1) and not U2968_0077(2);
  if Players_3F0E[P].f26 > 0 then
    U22B7_08EC(Control_E480[P], P);
end;

{ Read one control action for player P from controller Ctrl
  (1 = keyboard, 2 = mouse, 3 = computer).  Returns
  1/2 turn turret, 3/4 power down/up, 5 fire, 6 flip direction,
  7/8 previous/next weapon, 9/10 toggle guidance system, 0 = nothing. }
{#U1F69_0EF4}
function U1F69_0EF4(Ctrl, P: Integer): Integer;
var
  MX, MY, Key: Integer;
  B1, B2: Boolean;
  I: Integer;
begin
  Key := 0;
  if Players_3F0E[P].Ammo[Players_3F0E[P].Weapon] <= 0 then
  begin
    U1F69_0EF4 := 8;
    Exit;
  end;
  if (Players_3F0E[P].Ammo[Players_3F0E[P].Weapon] <= 100) and
     (Players_3F0E[P].Weapon = 5) then
  begin
    U1F69_0EF4 := 8;
    Exit;
  end;
  Key := 0;
  if Ctrl = 1 then
  begin
    Key := 0;
    if (g_440A[$53] <> 0) and (g_440A[$52] <> 0) then
    begin
      { Ins+Del: cheat mode until Ins+Del or Space }
      KbdHead := KbdTail;
      g_440A[$53] := 0;
      g_440A[$52] := 0;
      repeat
        if g_440A[$2E] <> 0 then U0098_0579(2, 2, BackBuf_E49A);
        if g_440A[$11] <> 0 then
          for I := 0 to 17 do Players_3F0E[P].Ammo[I] := 999;
        if g_440A[$22] <> 0 then
          for I := 0 to 1 do Players_3F0E[P].Accessory[I] := 10;
        if g_440A[$20] <> 0 then
          for I := 0 to 2 do Players_3F0E[P].Guidance[I] := 1000;
      until (g_440A[$53] <> 0) and (g_440A[$52] <> 0) or (g_440A[$39] <> 0);
      KbdHead := KbdTail;
      g_440A[$39] := 0;
      g_440A[$53] := 0;
      g_440A[$52] := 0;
    end;
    if g_440A[$17] <> 0 then
    begin
      Key := 6;
      repeat until g_440A[$17] = 0;
    end;
    if g_440A[$23] <> 0 then
    begin
      Key := 9;
      repeat until g_440A[$23] = 0;
    end;
    if g_440A[$2F] <> 0 then
    begin
      Key := 10;
      repeat until g_440A[$2F] = 0;
    end;
    if (g_440A[$0F] <> 0) and ((g_440A[$2A] <> 0) or (g_440A[$36] <> 0)) then
    begin
      Key := 7;
      repeat until g_440A[$0F] = 0;
    end;
    if g_440A[$0F] <> 0 then
    begin
      Key := 8;
      repeat until g_440A[$0F] = 0;
    end;
    if g_440A[$17] <> 0 then
    begin
      Key := 6;
      repeat until g_440A[$17] = 0;
    end;
    if (g_440A[$39] <> 0) or (g_440A[$1C] <> 0) or (g_440A[$11C] <> 0) then
      Key := 5;
    if g_440A[$0B] <> 0 then U22B7_0040(0, Ctrl);
    if g_440A[$02] <> 0 then U22B7_0040(1, Ctrl);
    if g_440A[$03] <> 0 then U22B7_0040(2, Ctrl);
    if g_440A[$04] <> 0 then U22B7_0040(3, Ctrl);
    if g_440A[$05] <> 0 then U22B7_0040(4, Ctrl);
    if g_440A[$06] <> 0 then U22B7_0040(5, Ctrl);
    if g_440A[$07] <> 0 then U22B7_0040(6, Ctrl);
    if g_440A[$08] <> 0 then U22B7_0040(7, Ctrl);
    if g_440A[$09] <> 0 then U22B7_0040(8, Ctrl);
    if g_440A[$0A] <> 0 then U22B7_0040(9, Ctrl);
    if (g_440A[$4B] <> 0) or (g_440A[$14B] <> 0) then
    begin
      Key := 1;
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$4B] = 0) and (g_440A[$14B] = 0);
    end;
    if (g_440A[$4D] <> 0) or (g_440A[$14D] <> 0) then
    begin
      Key := 2;
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$4D] = 0) and (g_440A[$14D] = 0);
    end;
    if (g_440A[$50] <> 0) or (g_440A[$150] <> 0) then
    begin
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$50] = 0) and (g_440A[$150] = 0);
      Key := 3;
    end;
    if (g_440A[$48] <> 0) or (g_440A[$148] <> 0) then
    begin
      Key := 4;
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$48] = 0) and (g_440A[$148] = 0);
    end;
    if (g_440A[$49] <> 0) or (g_440A[$149] <> 0) then
    begin
      Key := 4;
      Players_3F0E[P].f1B := Players_3F0E[P].f1B + 99;
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$49] = 0) and (g_440A[$149] = 0);
    end;
    if (g_440A[$51] <> 0) or (g_440A[$151] <> 0) then
    begin
      Key := 3;
      Players_3F0E[P].f1B := Players_3F0E[P].f1B - 99;
      if (g_440A[$38] <> 0) or (g_440A[$138] <> 0) then
        repeat until (g_440A[$51] = 0) and (g_440A[$151] = 0);
    end;
  end;
  if Ctrl = 2 then
  begin
    U2968_004D;
    B1 := U2968_0077(1);
    B2 := U2968_0077(2);
    if not B1 and not B2 then
    begin
      U1F69_0EF4 := 0;
      Exit;
    end;
    MX := U2918_022A;
    MY := U2918_0256;
    U2968_005A;
    if U2823_0BFF(MX, MY) in [20..29] then
      U22B7_0040(U2823_0BFF(MX, MY) - 19, 2);
    if (MY >= 18) and (MY <= 27) and (MX >= ButtonX_E74E[0]) and (MX < ButtonX_E74E[18]) then
    begin
      if B1 then Key := 7;
      if B2 then Key := 8;
      repeat until not U2968_0077(1) and not U2968_0077(2);
    end;
    if (MY >= 18) and (MY <= 27) and (MX >= ButtonX_E74E[18]) and (MX < ButtonX_E74E[19]) then
    begin
      Key := 9;
      repeat until not U2968_0077(1) and not U2968_0077(2);
    end;
    if (MY >= 18) and (MY <= 27) and (MX >= ButtonX_E74E[19]) and (MX < ButtonX_E74E[20]) then
    begin
      Key := 10;
      repeat until not U2968_0077(1) and not U2968_0077(2);
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
        Players_3F0E[P].f1B := Players_3F0E[P].f1B - 99;
      end;
      if B2 then
      begin
        Key := 4;
        Players_3F0E[P].f1B := Players_3F0E[P].f1B + 99;
      end;
    end;
    if (MX >= 296) and (MY >= 0) and (MX <= 302) and (MY <= 7) then
    begin
      Key := 6;
      repeat until not U2968_0077(1) and not U2968_0077(2);
    end;
    if B1 and B2 then Key := 5;
  end;
  if Ctrl = 3 then
    Key := PComputer(Tanks_3EE2[P])^.Think;
  if Ctrl <> 3 then
    Delay(g_E798);
  U1F69_0EF4 := Key;
end;

end.
