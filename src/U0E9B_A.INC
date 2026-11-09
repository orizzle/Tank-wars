
{ swap players A and B (record, tank object pointer and control type);
  index 0 is used as the temporary }
{#U0E9B_0000}
procedure U0E9B_0000(A, B: Integer);
begin
  Players_3F0E[0] := Players_3F0E[A];
  Players_3F0E[A] := Players_3F0E[B];
  Players_3F0E[B] := Players_3F0E[0];
  U26A9_0165(A, Players_3F0E[A]);
  U26A9_0165(B, Players_3F0E[B]);
  Tanks_3EE2[0] := Tanks_3EE2[A];
  Tanks_3EE2[A] := Tanks_3EE2[B];
  Tanks_3EE2[B] := Tanks_3EE2[0];
  PComputer(Tanks_3EE2[B])^.SetPlayer(B);
  PComputer(Tanks_3EE2[A])^.SetPlayer(A);
  Control_E480[0] := Control_E480[A];
  Control_E480[A] := Control_E480[B];
  Control_E480[B] := Control_E480[0];
end;

{ shop: build and draw the item buttons for player PNum }
{#U0E9B_015B}
procedure U0E9B_015B(PNum: Integer);
begin
  SetTextStyle(2, 0, 1);
  SetUserCharSize(8, 8, 8, 8);
  with Players_3F0E[PNum] do
  begin
    g_4624 := 5;
    g_4626 := 40;
    SetColor(4);
    SetTextJustify(1, 1);
    NumButtons_3E8C := 0;
    for g_461E := 0 to 17 do
      if ((Ammo[g_461E] > 0) or (Score - g_3E96 >= WeaponPrice_2C7C[g_461E]))
        and (WeaponQty_2CC4[g_461E] <> 0) then
      begin
        Inc(NumButtons_3E8C);
        with Buttons_3ACC[NumButtons_3E8C] do
        begin
          X1 := g_4624;
          Y1 := g_4626;
          X2 := g_4624 + 99;
          Y2 := g_4626 + 13;
          Count := 0;
          TextX := (X2 + X1) div 2 - 7;
          Kind := 0;
          Item := g_461E;
          U0098_028C(g_4624, g_4626, g_4624 + 99, g_4626 + 13, 18, 15, 17);
          OutTextXY(TextX, g_4626 + 3, WeaponShort_1A7C[g_461E]);
        end;
        Inc(g_4626, 18);
        if g_4626 + 13 > 197 then
        begin
          g_4626 := 40;
          Inc(g_4624, 104);
        end;
      end;
    SetColor(10);
    for g_461E := 0 to 1 do
      if (Accessory[g_461E] > 0) or
         ((Score - g_3E96 >= GuidPrice_30E8[g_461E]) and (GuidQty_30F0[g_461E] <> 0)) then
      begin
        Inc(NumButtons_3E8C);
        with Buttons_3ACC[NumButtons_3E8C] do
        begin
          X1 := g_4624;
          Y1 := g_4626;
          X2 := g_4624 + 99;
          Y2 := g_4626 + 13;
          TextX := (X2 + X1) div 2 - 7;
          Count := 0;
          Kind := 1;
          Item := g_461E;
          U0098_028C(g_4624, g_4626, g_4624 + 99, g_4626 + 13, 18, 15, 17);
          OutTextXY(TextX, g_4626 + 3, GuidShort_2EE8[g_461E]);
        end;
        Inc(g_4626, 18);
        if g_4626 + 13 > 197 then
        begin
          g_4626 := 40;
          Inc(g_4624, 104);
        end;
      end;
    SetColor(9);
    for g_461E := 0 to 2 do
      if (Guidance[g_461E] > 0) or
         ((Score - g_3E96 >= ShieldPrice_36F4[g_461E]) and (ShieldQty_3700[g_461E] <> 0)) then
      begin
        Inc(NumButtons_3E8C);
        with Buttons_3ACC[NumButtons_3E8C] do
        begin
          X1 := g_4624;
          Y1 := g_4626;
          X2 := g_4624 + 99;
          Y2 := g_4626 + 13;
          TextX := (X2 + X1) div 2 - 7;
          Count := 0;
          Kind := 2;
          Item := g_461E;
          U0098_028C(g_4624, g_4626, g_4624 + 99, g_4626 + 13, 18, 15, 17);
          OutTextXY(TextX, g_4626 + 3, ShieldShort_33F4[g_461E]);
        end;
        Inc(g_4626, 18);
        if g_4626 + 13 > 197 then
        begin
          g_4626 := 40;
          Inc(g_4624, 104);
        end;
      end;
    U2823_0006;
    SetColor(14);
    SetTextStyle(g_E7EC, 0, 4);
    SetTextJustify(2, 0);
    { colour the price lamps: red = affordable }
    for g_461E := 1 to NumButtons_3E8C do
      with Buttons_3ACC[g_461E] do
      begin
        if Kind = 0 then
          if Score - g_3E96 - g_3E8E < WeaponPrice_2C7C[Item] then
            g_E7C8(g_461E + 100, 0, 0, 0)
          else
            g_E7C8(g_461E + 100, 63, 0, 0);
        if Kind = 1 then
          if Score - g_3E96 - g_3E8E < GuidPrice_30E8[Item] then
            g_E7C8(g_461E + 100, 0, 0, 0)
          else
            g_E7C8(g_461E + 100, 63, 0, 0);
        if Kind = 2 then
          if Score - g_3E96 - g_3E8E < ShieldPrice_36F4[Item] then
            g_E7C8(g_461E + 100, 0, 0, 0)
          else
            g_E7C8(g_461E + 100, 63, 0, 0);
        U2823_017D(X2 - 40, Y2 - 2, 1, 1, g_461E + 100);
        U2823_0BB6(X2 - 40, Y2 - 2, g_461E + 100);
      end;
    { amount owned }
    for g_461E := 1 to NumButtons_3E8C do
      with Buttons_3ACC[g_461E] do
      begin
        if Kind = 0 then g_4620 := Ammo[Item];
        if Kind = 1 then g_4620 := Accessory[Item];
        if Kind = 2 then g_4620 := Guidance[Item];
        g_46CA := U2918_02FE(g_4620);
        if (Kind = 2) and (Item = 0) then
        begin
          g_46CA := U2918_02FE(g_4620 div 10) + '%';
          if g_4620 > 1000 then g_46CA := '100%';
        end;
        if (Kind = 2) and (Item = 1) then
        begin
          g_46CA := g_46CA + '%';
          if g_4620 > 100 then g_46CA := '100%';
        end;
        if g_4620 > 0 then OutTextXY(X2 - 13, Y2, g_46CA);
      end;
    SetColor(0);
    SetTextStyle(g_E7EC, 0, 4);
    SetTextJustify(0, 0);
    { "<qty> FOR <price>" }
    for g_461E := 1 to NumButtons_3E8C do
      with Buttons_3ACC[g_461E] do
      begin
        if Kind = 0 then g_46CA := U2918_02FE(WeaponQty_2CC4[Item]);
        if Kind = 1 then g_46CA := U2918_02FE(GuidQty_30F0[Item]);
        if Kind = 2 then g_46CA := U2918_02FE(ShieldQty_3700[Item]);
        if (Kind = 2) and (Item in [0, 1]) then g_46CA := '100%';
        g_46CA := g_46CA + ' FOR ';
        if Kind = 0 then g_46CA := g_46CA + U2918_02FE(WeaponPrice_2C7C[Item]);
        if Kind = 1 then g_46CA := g_46CA + U2918_02FE(GuidPrice_30E8[Item]);
        if Kind = 2 then g_46CA := g_46CA + U2918_02FE(ShieldPrice_36F4[Item]);
        OutTextXY(X1 + 2, Y2, g_46CA);
      end;
    SetColor(6);
    SetTextJustify(1, 1);
    for g_461E := 1 to NumButtons_3E8C do
      with Buttons_3ACC[g_461E] do
        U0098_028C(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3, 18, 17, 15);
  end;
end;

{ shop: every player that can afford something buys weapons/guidance/shields
  (keyboard, mouse, or computer players by their AI type) }
{#U0E9B_0E1F}
procedure U0E9B_0E1F;
var
  Color: Integer;
  Clicked: Integer;
  OldSel: Integer;
  MinPrice: Integer;
  J: Integer;
  I: Integer;
  Sel: Integer;
  Unused10: Integer;
  MX, MY: Integer;
  Unused15, Minus, Plus, Unused18, LeftBtn, Unused1A, RightBtn, Unused1C: Boolean;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  J := 0;
  KbdHead := KbdTail;                   { flush the BIOS keyboard buffer }
  MinPrice := $7FFF;
  for J := 0 to 17 do
    if (MinPrice > WeaponPrice_2C7C[J]) and (WeaponQty_2CC4[J] <> 0) then
      MinPrice := WeaponPrice_2C7C[J];
  for J := 0 to 1 do
    if (MinPrice > GuidPrice_30E8[J]) and (GuidQty_30F0[J] <> 0) then
      MinPrice := GuidPrice_30E8[J];
  for J := 0 to 2 do
    if (MinPrice > ShieldPrice_36F4[J]) and (ShieldQty_3700[J] <> 0) then
      MinPrice := ShieldPrice_36F4[J];
  for I := 1 to g_46B4 do
    with Players_3F0E[I] do
      if ((Control_E480[I] <> 3) or ((PComputer(Tanks_3EE2[I])^.GetF0E <> 0) and (g_E78F <> 0)))
        and (Score - Spent >= MinPrice) then
      begin
        U0098_01BD;
        SetTextStyle(g_E7E2, 0, 4);
        SetUserCharSize(1, 2, 1, 2);
        SetTextJustify(1, 2);
        U0098_028C(5, 5, 314, 35, 18, 15, 17);
        SetColor(I + 19);
        U26A9_014E(Players_3F0E[I]);
        OutTextXY(160, 3, Players_3F0E[I].Name);
        SetTextStyle(2, 0, 4);
        SetTextJustify(0, 2);
        U0098_028C(10, 16, 59, 24, 18, 15, 17);
        SetColor(17);
        OutTextXY(11, 14, 'Purchase');
        U0098_028C(284, 16, 310, 24, 18, 15, 17);
        SetColor(17);
        OutTextXY(285, 14, 'Done');
        SetColor(6);
        SetTextStyle(g_E7EC, 0, 4);
        SetTextJustify(0, 2);
        g_3E8E := 0;
        g_3E96 := Spent;
        OutTextXY(11, 0, 'YOU HAVE UNALLOCATED:');
        OutTextXY(11, 21, U2918_02FE(Score - Spent - g_3E8E) + ' DOLLARS');
        SetTextJustify(2, 2);
        SetColor(14);
        OutTextXY(309, 0, 'YOU CURRENTLY HAVE:');
        OutTextXY(309, 21, U2918_02FE(Score - g_3E96) + ' DOLLARS');
        U2823_00CC(0, 38, 319, 199, SaveBuf_E496);
        U0E9B_015B(I);
        g_462F := 0;
        Sel := 1;
        repeat
          Clicked := 0;
          LeftBtn := False;
          RightBtn := False;
          Minus := False;
          Plus := False;
          Unused18 := False;
          repeat
            { frame of the selected button: black if not affordable }
            Color := 11;
            if (Buttons_3ACC[Sel].Kind = 0) and
               (WeaponPrice_2C7C[Buttons_3ACC[Sel].Item] > Score - g_3E96 - g_3E8E) then Color := 0;
            if (Buttons_3ACC[Sel].Kind = 1) and
               (GuidPrice_30E8[Buttons_3ACC[Sel].Item] > Score - g_3E96 - g_3E8E) then Color := 0;
            if (Buttons_3ACC[Sel].Kind = 2) and
               (ShieldPrice_36F4[Buttons_3ACC[Sel].Item] > Score - g_3E96 - g_3E8E) then Color := 0;
            U2823_0031(Buttons_3ACC[Sel].X2 - 9, Buttons_3ACC[Sel].Y1 + 3,
              Buttons_3ACC[Sel].X2 - 3, Buttons_3ACC[Sel].Y2 - 3, Color);
            if Control_E480[I] = 2 then U2968_004D;
            OldSel := Sel;
            repeat
              { keyboard player }
              if Control_E480[I] = 1 then
                if KeyPressed then
                begin
                  g_46C9 := UpCase(ReadKey);
                  if g_46C9 = ' ' then Plus := True;
                  if g_46C9 in [#13, 'P'] then Clicked := NumButtons_3E8C + 1;
                  if g_46C9 in [#27, 'D'] then Clicked := NumButtons_3E8C + 2;
                  if g_46C9 = '+' then Plus := True;
                  if g_46C9 = '-' then Minus := True;
                  if g_46C9 = '=' then Plus := True;
                  if Minus or Plus then Clicked := Sel;
                  if g_46C9 = #0 then
                  begin
                    g_46C9 := ReadKey;
                    if (g_46C9 = KeyUp_3716) and (Sel > 1) then Dec(Sel);
                    if (g_46C9 = KeyDn_3717) and (NumButtons_3E8C > Sel) then Inc(Sel);
                    if (g_46C9 = KeyRt_3718) and (Sel + 9 <= NumButtons_3E8C) then Inc(Sel, 9);
                    if (g_46C9 = KeyLt_3719) and (Sel - 9 >= 1) then Dec(Sel, 9);
                  end;
                end;
              { mouse player }
              if Control_E480[I] = 2 then
                if U2968_0077(1) or U2968_0077(2) then
                begin
                  MX := U2918_022A;
                  MY := U2918_0256;
                  LeftBtn := U2968_0077(1);
                  RightBtn := U2968_0077(2);
                  for J := 1 to NumButtons_3E8C do
                    with Buttons_3ACC[J] do
                      if (MY >= Y1) and (MY <= Y2) and (MX <= X2) and (MX >= X1) then
                        Clicked := J;
                  if (MY >= 16) and (MY <= 24) and (MX <= 59) and (MX >= 10) then
                    Clicked := NumButtons_3E8C + 1;
                  if (MY >= 16) and (MY <= 24) and (MX <= 310) and (MX >= 284) then
                    Clicked := NumButtons_3E8C + 2;
                  repeat until not U2968_0077(1) and not U2968_0077(2);
                  if (Clicked > 0) and (NumButtons_3E8C >= Clicked) then Sel := Clicked;
                end;
              { computer players: buy the most expensive affordable things }
              if Control_E480[I] = 3 then
                if PComputer(Tanks_3EE2[I])^.GetF0E = 1 then
                begin
                  for J := NumButtons_3E8C downto 1 do
                    if (Buttons_3ACC[J].Item in [1..4]) and (Buttons_3ACC[J].Kind = 0) and
                       (Players_3F0E[I].Ammo[Buttons_3ACC[J].Item] +
                         Buttons_3ACC[J].Count * WeaponQty_2CC4[Buttons_3ACC[J].Item] < 20) and
                       (Score - g_3E96 - g_3E8E >= WeaponPrice_2C7C[Buttons_3ACC[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Plus <> True then Clicked := NumButtons_3E8C + 2;
                end;
              if Control_E480[I] = 3 then
                if PComputer(Tanks_3EE2[I])^.GetF0E = 2 then
                begin
                  for J := 1 to NumButtons_3E8C do
                    if (Buttons_3ACC[J].Item in [1..4]) and (Buttons_3ACC[J].Kind = 0) and
                       (Score - g_3E96 - g_3E8E >= WeaponPrice_2C7C[Buttons_3ACC[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players_3F0E[I].Ammo[1] + WeaponQty_2CC4[1] * Buttons_3ACC[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumButtons_3E8C + 2;
                end;
              if Control_E480[I] = 3 then
                if PComputer(Tanks_3EE2[I])^.GetF0E = 3 then
                begin
                  for J := 1 to NumButtons_3E8C do
                    if (Buttons_3ACC[J].Item in [1..5]) and (Buttons_3ACC[J].Kind = 0) and
                       (Score - g_3E96 - g_3E8E >= WeaponPrice_2C7C[Buttons_3ACC[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players_3F0E[I].Ammo[1] + WeaponQty_2CC4[1] * Buttons_3ACC[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumButtons_3E8C + 2;
                end;
              if Control_E480[I] = 3 then
                if PComputer(Tanks_3EE2[I])^.GetF0E = 4 then
                begin
                  for J := NumButtons_3E8C downto 1 do
                    if (Buttons_3ACC[J].Item in [0..2]) and (Buttons_3ACC[J].Kind = 2) and
                       (Score - g_3E96 - g_3E8E >= ShieldPrice_36F4[Buttons_3ACC[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players_3F0E[I].Ammo[1] + WeaponQty_2CC4[1] * Buttons_3ACC[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumButtons_3E8C + 2;
                end;
            until (OldSel <> Sel) or (Clicked > 0);
            if Control_E480[I] = 2 then U2968_005A;
            U2823_0031(Buttons_3ACC[OldSel].X2 - 9, Buttons_3ACC[OldSel].Y1 + 3,
              Buttons_3ACC[OldSel].X2 - 3, Buttons_3ACC[OldSel].Y2 - 3, 18);
          until Clicked in [1..NumButtons_3E8C + 2];
          g_3E92 := g_3E8E;
          g_3E9A := g_3E96;
          with Buttons_3ACC[Clicked] do
          begin
            if (Clicked > 0) and (NumButtons_3E8C >= Clicked) then
              begin
                { sell back one unit }
                if Minus or LeftBtn then
                  if Count > 0 then
                  begin
                    Dec(Buttons_3ACC[Clicked].Count);
                    if Kind = 0 then Dec(g_3E8E, WeaponPrice_2C7C[Item]);
                    if Kind = 1 then Dec(g_3E8E, GuidPrice_30E8[Item]);
                    if Kind = 2 then Dec(g_3E8E, ShieldPrice_36F4[Item]);
                    SetFillStyle(1, 18);
                    Bar(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3);
                    if Count > 0 then
                    begin
                      SetTextStyle(g_E7EC, 0, 4);
                      SetTextJustify(1, 1);
                      SetColor(6);
                      OutTextXY((X2 - 13 + X2) div 2 + 1, (Y1 + Y2) div 2 - 2, U2918_02FE(Count));
                    end;
                  end;
                { buy one more unit }
                if Plus or RightBtn then
                  if Count < 9 then
                  begin
                    if Kind = 0 then g_4620 := WeaponPrice_2C7C[Item];
                    if Kind = 1 then g_4620 := GuidPrice_30E8[Item];
                    if Kind = 2 then g_4620 := ShieldPrice_36F4[Item];
                    if g_4620 <= Score - g_3E96 - g_3E8E then
                    begin
                      Inc(g_3E8E, g_4620);
                      Inc(Count);
                      SetFillStyle(1, 18);
                      Bar(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3);
                      SetTextStyle(g_E7EC, 0, 4);
                      SetTextJustify(1, 1);
                      SetColor(6);
                      OutTextXY((X2 - 13 + X2) div 2 + 1, (Y1 + Y2) div 2 - 2, U2918_02FE(Count));
                    end;
                  end;
                for J := 1 to NumButtons_3E8C do
                begin
                  if Buttons_3ACC[J].Kind = 0 then
                    if WeaponPrice_2C7C[Buttons_3ACC[J].Item] > Score - g_3E96 - g_3E8E then
                      g_E7C8(J + 100, 0, 0, 0)
                    else
                      g_E7C8(J + 100, 63, 0, 0);
                  if Buttons_3ACC[J].Kind = 1 then
                    if GuidPrice_30E8[Buttons_3ACC[J].Item] > Score - g_3E96 - g_3E8E then
                      g_E7C8(J + 100, 0, 0, 0)
                    else
                      g_E7C8(J + 100, 63, 0, 0);
                  if Buttons_3ACC[J].Kind = 2 then
                    if ShieldPrice_36F4[Buttons_3ACC[J].Item] > Score - g_3E96 - g_3E8E then
                      g_E7C8(J + 100, 0, 0, 0)
                    else
                      g_E7C8(J + 100, 63, 0, 0);
                end;
              end;
            { "Done" = purchase and leave }
            if NumButtons_3E8C + 2 = Clicked then
            begin
              Clicked := NumButtons_3E8C + 1;
              g_462F := 1;
            end;
            { "Purchase": take the selected amounts }
            if NumButtons_3E8C + 1 = Clicked then
            begin
              g_4622 := 0;
              g_3E8E := 0;
              g_3E92 := 1;
              for J := 1 to NumButtons_3E8C do
                with Buttons_3ACC[J] do
                begin
                  if Kind = 0 then g_4620 := WeaponPrice_2C7C[Item];
                  if Kind = 1 then g_4620 := GuidPrice_30E8[Item];
                  if Kind = 2 then g_4620 := ShieldPrice_36F4[Item];
                  if Count > 0 then
                  begin
                    Inc(g_3E96, g_4620 * Count);
                    if Kind = 0 then Inc(Ammo[Item], WeaponQty_2CC4[Item] * Count);
                    if Kind = 1 then Inc(Accessory[Item], GuidQty_30F0[Item] * Count);
                    if Kind = 2 then Inc(Guidance[Item], ShieldQty_3700[Item] * Count);
                    Inc(g_4622, Count);
                  end;
                end;
              if (g_4622 <> 0) and (g_462F = 0) then
              begin
                U2823_00CC(0, 38, 319, 199, SaveBuf_E496);
                OldSel := Sel;
                U0E9B_015B(I);
                if NumButtons_3E8C < Sel then Sel := NumButtons_3E8C;
              end;
            end;
          end;
          if g_3E92 <> g_3E8E then
          begin
            SetColor(6);
            SetTextStyle(g_E7EC, 0, 4);
            SetTextJustify(0, 2);
            SetFillStyle(1, 18);
            Bar(11, 27, 80, 35);
            OutTextXY(11, 21, U2918_02FE(Score - g_3E96 - g_3E8E) + ' DOLLARS');
          end;
          if g_3E9A <> g_3E96 then
          begin
            SetColor(14);
            SetTextStyle(g_E7EC, 0, 4);
            SetTextJustify(2, 2);
            SetFillStyle(1, 18);
            Bar(309, 27, 239, 35);
            OutTextXY(309, 21, U2918_02FE(Score - g_3E96 - g_3E8E) + ' DOLLARS');
          end;
        until g_462F <> 0;
        Spent := g_3E96;
      end;
  { close the shop screen }
  for J := 0 to 120 do
    U2823_011A(J, J, 319 - J, 199 - J, SaveBuf_E496);
end;

{ shuffle the player order }
{#U0E9B_23EF}
procedure U0E9B_23EF;
var
  I, A, B: Integer;
begin
  for I := 1 to Random(20) + 10 do
  begin
    A := Random(g_46B4) + 1;
    repeat
      B := Random(g_46B4) + 1;
    until A <> B;
    U0E9B_0000(A, B);
  end;
end;

{ statistics window of player P (waits for a key / mouse click) }
{#U0E9B_24E4}
procedure U0E9B_24E4(P: Integer);
var
  Buf: Pointer;
  S: string;
  Unused: LongInt;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  U2968_005A;
  GetMem(Buf, 6223);
  GetImage(78, 28, 242, 172, Buf^);
  U26A9_01B0(100, Players_3F0E[P]);
  if g_E791 <> 0 then
  begin
    SetTextStyle(2, 0, 1);
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 2);
    SetColor(P + 19);
    U0098_028C(2, 180, 84, 195, 18, 15, 17);
    OutTextXY(42, 181, Teams_4712[Players_3F0E[P].Team].Name);
  end;
  U0098_028C(80, 30, 240, 170, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  SetColor(P + 19);
  OutTextXY(160, 33, Players_3F0E[P].Name);
  U2823_09E4(80, 47, 240, 47, 0);
  SetColor(0);
  SetTextJustify(0, 2);
  OutTextXY(84, 46, 'Type:');
  OutTextXY(84, 56, 'Score:');
  OutTextXY(84, 66, 'Cash:');
  OutTextXY(84, 76, 'Wins:');
  OutTextXY(84, 86, 'Hits:');
  OutTextXY(84, 96, 'Kills:');
  OutTextXY(84, 106, 'Shots:');
  OutTextXY(84, 116, 'Accuracy:');
  OutTextXY(84, 126, 'Kills per Round:');
  OutTextXY(84, 136, 'Kill Rate:');
  OutTextXY(84, 146, 'Fatalties:');
  OutTextXY(84, 156, '  per Round:');
  SetTextJustify(2, 2);
  SetColor(14);
  with Players_3F0E[P] do
  begin
    case Control_E480[P] of
      1: S := 'Human (K)';
      2: S := 'Human (M)';
      3: S := 'Computer';
    end;
    OutTextXY(236, 46, S);
    OutTextXY(236, 56, U2918_02FE(Score));
    OutTextXY(236, 66, U2918_02FE(Score - Spent));
    OutTextXY(236, 76, U2918_02FE(Wins));
    OutTextXY(236, 86, U2918_02FE(f6C));
    OutTextXY(236, 96, U2918_02FE(f6E));
    OutTextXY(236, 106, U2918_02FE(f70));
    if f70 = 0 then
      S := 'Undefined'
    else
      S := U2918_02FE(Trunc(f6C / f70 * 100)) + '%';
    OutTextXY(236, 116, S);
    Str(f6E / g_46BC:5:2, S);
    OutTextXY(236, 126, S);
    if f70 = 0 then
      S := 'Undefined'
    else
    begin
      Str(f6E / f70 * 100:3:0, S);
      S := S + '%';
    end;
    OutTextXY(236, 136, S);
    SetColor(4);
    OutTextXY(236, 146, U2918_02FE(f68));
    Str(f68 / g_46BC:5:1, S);
    OutTextXY(236, 156, S);
  end;
  U2968_004D;
  repeat until U2968_0077(1) or U2968_0077(2) or KeyPressed;
  repeat until not U2968_0077(1) and not U2968_0077(2);
  KbdHead := KbdTail;
  U2968_005A;
  U2823_00CC(0, 178, 86, 197, SaveBuf_E496);
  PutImage(78, 28, Buf^, 0);
  FreeMem(Buf, 6223);
  U2968_004D;
end;

{ statistics window of team T (member names along the top/bottom edge) }
{#U0E9B_2B8E}
procedure U0E9B_2B8E(T: Integer);
var
  Buf: Pointer;
  S: string;
  I, X, Y, N: Integer;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  U2968_005A;
  GetMem(Buf, 6223);
  GetImage(78, 28, 242, 172, Buf^);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  N := -1;
  for I := 1 to g_46B4 do
    if Players_3F0E[I].Team = T then
    begin
      U26A9_01B0(100, Players_3F0E[I]);
      Inc(N);
      X := N * 64 + 32;
      Y := 3;
      if N > 4 then
      begin
        X := X - 320;
        Y := 181;
      end;
      SetColor(I + 19);
      S := Players_3F0E[I].Name;
      while TextWidth(S) >= 60 do Dec(S[0]);
      U0098_028C(X - 29, Y, X + 29, Y + 15, 18, 15, 17);
      OutTextXY(X, Y + 1, S);
    end;
  U0098_028C(80, 30, 240, 170, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  SetColor(10);
  OutTextXY(160, 33, Teams_4712[T].Name);
  U2823_09E4(80, 47, 240, 47, 0);
  SetColor(0);
  SetTextJustify(0, 2);
  OutTextXY(84, 46, 'Players:');
  OutTextXY(84, 56, 'Score:');
  OutTextXY(84, 66, 'Computer:');
  OutTextXY(84, 76, 'Wins:');
  OutTextXY(84, 86, 'Hits:');
  OutTextXY(84, 96, 'Kills:');
  OutTextXY(84, 106, 'Shots:');
  OutTextXY(84, 116, 'Accuracy:');
  OutTextXY(84, 126, 'Kills per Round:');
  OutTextXY(84, 136, 'Kill Rate:');
  OutTextXY(84, 146, 'Fatalties:');
  OutTextXY(84, 156, '  per Round:');
  SetTextJustify(2, 2);
  SetColor(14);
  with Teams_4712[T] do
  begin
    OutTextXY(236, 46, U2918_02FE(f0F));
    OutTextXY(236, 56, U2918_02FE(Trunc(f11)));
    if f0E <> 0 then S := 'YES' else S := 'NO';
    OutTextXY(236, 66, S);
    Str(f1D:3:1, S);
    OutTextXY(236, 76, S);
    Str(f23:3:0, S);
    OutTextXY(236, 86, S);
    Str(f29:3:0, S);
    OutTextXY(236, 96, S);
    Str(f2F:3:0, S);
    OutTextXY(236, 106, S);
    if f2F = 0 then
      S := 'Undefined'
    else
      S := U2918_02FE(Trunc(f23 / f2F * 100)) + '%';
    OutTextXY(236, 116, S);
    Str(f29 / g_46BC:5:2, S);
    OutTextXY(236, 126, S);
    if f2F = 0 then
      S := 'Undefined'
    else
    begin
      Str(f29 / f2F * 100:3:0, S);
      S := S + '%';
    end;
    OutTextXY(236, 136, S);
    SetColor(4);
    Str(f17:5:1, S);
    OutTextXY(236, 146, S);
    Str(f17 / g_46BC:5:1, S);
    OutTextXY(236, 156, S);
  end;
  U2968_004D;
  repeat until U2968_0077(1) or U2968_0077(2) or KeyPressed;
  repeat until not U2968_0077(1) and not U2968_0077(2);
  KbdHead := KbdTail;
  U2968_005A;
  N := -1;
  for I := 1 to g_46B4 do
    if Players_3F0E[I].Team = T then
    begin
      Inc(N);
      X := N * 64 + 32;
      Y := 3;
      if N > 4 then
      begin
        X := X - 320;
        Y := 181;
      end;
      U2823_00CC(X - 32, Y - 2, X + 32, Y + 17, SaveBuf_E496);
    end;
  PutImage(78, 28, Buf^, 0);
  FreeMem(Buf, 6223);
  U2968_004D;
end;

{ input box for the save game file name (SaveName_46FC, max. 8 chars);
  the marker of the procedure itself is in front of its main body }
procedure U0E9B_369F;
var
  Buf: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;

  { draw the cursor box at Pos and the character under it }
  {#U0E9B_33D2} procedure U0E9B_33D2;
  begin
    U2823_0031((Pos - 1) * 6 + 133 - 1, 100, (Pos - 1) * 6 + 133 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 133, 101, (Pos - 1) * 6 + 133 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 133 + 1, 102, (Pos - 1) * 6 + 133 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName_46FC, Pos, 1));
    U2823_00CC((Pos - 1) * 6 + 133 - 1, 109, (Pos - 1) * 6 + 133 + 4, 110, SaveBuf_E496);
  end;

  { remove the cursor box at Pos }
  {#U0E9B_3512} procedure U0E9B_3512;
  begin
    U2823_0031((Pos - 1) * 6 + 133 - 1, 100, (Pos - 1) * 6 + 133 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 133, 101, (Pos - 1) * 6 + 133 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 133 + 1, 102, (Pos - 1) * 6 + 133 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName_46FC, Pos, 1));
  end;

{#U0E9B_369F}
begin
  GetMem(Buf, 748);
  if Length(SaveName_46FC) < 8 then
    for I := Length(SaveName_46FC) + 1 to 8 do SaveName_46FC[I] := ' ';
  GetImage(123, 83, 197, 117, Buf^);
  U0098_028C(125, 85, 195, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(5);
  OutTextXY(128, 85, 'FILE NAME:');
  U0098_028C(130, 100, 190, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(SaveName_46FC) do
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName_46FC, Pos, 1));
  Inc(SaveName_46FC[0]);
  Pos := Length(SaveName_46FC);
  Done := False;
  repeat
    U0E9B_33D2;
    Changed := False;
    repeat
      repeat until KeyPressed;
      g_46C9 := ReadKey;
      if (g_46C9 in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        SaveName_46FC[NewPos] := ' ';
        SaveName_46FC[NewPos + 1] := ' ';
        Changed := True;
      end;
      if g_46C9 in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if g_46C9 in ['0'..'9', 'A'..'Z', 'a'..'z'] then
      begin
        SaveName_46FC[Pos] := UpCase(g_46C9);
        Changed := True;
        NewPos := Pos + 1;
        if Length(SaveName_46FC) < NewPos then Inc(SaveName_46FC[0]);
      end;
      if g_46C9 = #0 then
      begin
        g_46C9 := ReadKey;
        if g_46C9 = 'G' then                    { Home: clear }
        begin
          for Pos := Length(SaveName_46FC) downto 1 do
          begin
            SaveName_46FC[Pos] := ' ';
            U0E9B_33D2;
            U0E9B_3512;
          end;
          SaveName_46FC := '  ';
          NewPos := 1;
        end;
        if g_46C9 = 'S' then                    { Del }
        begin
          SaveName_46FC[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if g_46C9 = 'O' then                    { End }
        begin
          Changed := True;
          NewPos := Length(SaveName_46FC);
        end;
        if (g_46C9 = KeyLt_3719) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (g_46C9 = KeyRt_3718) and (Length(SaveName_46FC) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 8 then NewPos := 8;
    if Length(SaveName_46FC) > 8 then SaveName_46FC[0] := #8;
    U0E9B_3512;
    Pos := NewPos;
  until Done;
  while (SaveName_46FC[Length(SaveName_46FC)] in [#0, ' ']) and (Length(SaveName_46FC) > 0) do
    Dec(SaveName_46FC[0]);
  PutImage(123, 83, Buf^, 0);
  FreeMem(Buf, 748);
end;

{ save the game to FileName + '.TWS' }
{#U0E9B_39EA}
procedure U0E9B_39EA(FileName: string);
var
  F: File;
  I: Integer;
  Unused: Real;
  Header: string;
begin
  Assign(F, FileName + '.TWS');
  Rewrite(F, 1);
  Header := '';
  Header := Header + 'Tank Wars Saved Game' + #13 + #10;
  Header := Header + 'V' + Version_0056 + #13 + #10;
  Header := Header + #26;
  BlockWrite(F, Header[1], Length(Header));
  BlockWrite(F, g_46B2, 2);
  BlockWrite(F, g_46B4, 2);
  BlockWrite(F, g_46BC, 2);
  BlockWrite(F, g_46BE, 2);
  BlockWrite(F, g_46C0, 2);
  BlockWrite(F, g_46C2, 2);
  BlockWrite(F, g_46C4, 2);
  BlockWrite(F, g_46C6, 2);
  BlockWrite(F, g_46C8, 1);
  BlockWrite(F, g_46EC, 1);
  BlockWrite(F, g_46EE, 1);
  BlockWrite(F, g_46EF, 1);
  BlockWrite(F, g_E778, 2);
  BlockWrite(F, g_E77A, 2);
  BlockWrite(F, g_E77C, 2);
  BlockWrite(F, g_E77E, 2);
  BlockWrite(F, g_E780, 2);
  BlockWrite(F, g_E782, 2);
  BlockWrite(F, g_E784, 2);
  BlockWrite(F, g_E787, 1);
  BlockWrite(F, g_E788, 1);
  BlockWrite(F, g_E789, 1);
  BlockWrite(F, g_E78A, 1);
  BlockWrite(F, g_E78D, 1);
  BlockWrite(F, g_E78F, 1);
  BlockWrite(F, g_E791, 1);
  for I := 1 to g_46B4 do
  begin
    BlockWrite(F, Players_3F0E[I], 116);
    BlockWrite(F, Control_E480[I], 2);
    if Control_E480[I] = 3 then PComputer(Tanks_3EE2[I])^.Save(F);
  end;
  BlockWrite(F, Teams_4712, 583);
  Close(F);
end;

