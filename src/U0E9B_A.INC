
{ swap players A and B (record, tank object pointer and control type);
  index 0 is used as the temporary }
{#U0E9B_0000}
procedure SwapPlayers(A, B: Integer);
begin
  Players[0] := Players[A];
  Players[A] := Players[B];
  Players[B] := Players[0];
  SetPlayerNum(A, Players[A]);
  SetPlayerNum(B, Players[B]);
  Tanks[0] := Tanks[A];
  Tanks[A] := Tanks[B];
  Tanks[B] := Tanks[0];
  PComputer(Tanks[B])^.SetPlayer(B);
  PComputer(Tanks[A])^.SetPlayer(A);
  Controls[0] := Controls[A];
  Controls[A] := Controls[B];
  Controls[B] := Controls[0];
end;

{ shop: build and draw the item buttons for player PNum }
{#U0E9B_015B}
procedure DrawShopButtons(PNum: Integer);
begin
  SetTextStyle(2, 0, 1);
  SetUserCharSize(8, 8, 8, 8);
  with Players[PNum] do
  begin
    TmpX := 5;
    TmpY := 40;
    SetColor(4);
    SetTextJustify(1, 1);
    NumShopButtons := 0;
    for LoopI := 0 to 17 do
      if ((Ammo[LoopI] > 0) or (Score - ShopSpent >= WeaponPrices[LoopI]))
        and (WeaponBundles[LoopI] <> 0) then
      begin
        Inc(NumShopButtons);
        with ShopButtons[NumShopButtons] do
        begin
          X1 := TmpX;
          Y1 := TmpY;
          X2 := TmpX + 99;
          Y2 := TmpY + 13;
          Count := 0;
          TextX := (X2 + X1) div 2 - 7;
          Kind := 0;
          Item := LoopI;
          DrawPanel3D(TmpX, TmpY, TmpX + 99, TmpY + 13, 18, 15, 17);
          OutTextXY(TextX, TmpY + 3, WeaponShortNames[LoopI]);
        end;
        Inc(TmpY, 18);
        if TmpY + 13 > 197 then
        begin
          TmpY := 40;
          Inc(TmpX, 104);
        end;
      end;
    SetColor(10);
    for LoopI := 0 to 1 do
      if (Accessory[LoopI] > 0) or
         ((Score - ShopSpent >= GuidePrices[LoopI]) and (GuideBundles[LoopI] <> 0)) then
      begin
        Inc(NumShopButtons);
        with ShopButtons[NumShopButtons] do
        begin
          X1 := TmpX;
          Y1 := TmpY;
          X2 := TmpX + 99;
          Y2 := TmpY + 13;
          TextX := (X2 + X1) div 2 - 7;
          Count := 0;
          Kind := 1;
          Item := LoopI;
          DrawPanel3D(TmpX, TmpY, TmpX + 99, TmpY + 13, 18, 15, 17);
          OutTextXY(TextX, TmpY + 3, GuideShortNames[LoopI]);
        end;
        Inc(TmpY, 18);
        if TmpY + 13 > 197 then
        begin
          TmpY := 40;
          Inc(TmpX, 104);
        end;
      end;
    SetColor(9);
    for LoopI := 0 to 2 do
      if (Guidance[LoopI] > 0) or
         ((Score - ShopSpent >= ShieldPrices[LoopI]) and (ShieldBundles[LoopI] <> 0)) then
      begin
        Inc(NumShopButtons);
        with ShopButtons[NumShopButtons] do
        begin
          X1 := TmpX;
          Y1 := TmpY;
          X2 := TmpX + 99;
          Y2 := TmpY + 13;
          TextX := (X2 + X1) div 2 - 7;
          Count := 0;
          Kind := 2;
          Item := LoopI;
          DrawPanel3D(TmpX, TmpY, TmpX + 99, TmpY + 13, 18, 15, 17);
          OutTextXY(TextX, TmpY + 3, ShieldShortNames[LoopI]);
        end;
        Inc(TmpY, 18);
        if TmpY + 13 > 197 then
        begin
          TmpY := 40;
          Inc(TmpX, 104);
        end;
      end;
    FetchClipWindow;
    SetColor(14);
    SetTextStyle(FontTiny, 0, 4);
    SetTextJustify(2, 0);
    { colour the price lamps: red = affordable }
    for LoopI := 1 to NumShopButtons do
      with ShopButtons[LoopI] do
      begin
        if Kind = 0 then
          if Score - ShopSpent - ShopCartCost < WeaponPrices[Item] then
            RGBHook(LoopI + 100, 0, 0, 0)
          else
            RGBHook(LoopI + 100, 63, 0, 0);
        if Kind = 1 then
          if Score - ShopSpent - ShopCartCost < GuidePrices[Item] then
            RGBHook(LoopI + 100, 0, 0, 0)
          else
            RGBHook(LoopI + 100, 63, 0, 0);
        if Kind = 2 then
          if Score - ShopSpent - ShopCartCost < ShieldPrices[Item] then
            RGBHook(LoopI + 100, 0, 0, 0)
          else
            RGBHook(LoopI + 100, 63, 0, 0);
        DrawEllipseNoClip(X2 - 40, Y2 - 2, 1, 1, LoopI + 100);
        PlotPixel(X2 - 40, Y2 - 2, LoopI + 100);
      end;
    { amount owned }
    for LoopI := 1 to NumShopButtons do
      with ShopButtons[LoopI] do
      begin
        if Kind = 0 then LoopJ := Ammo[Item];
        if Kind = 1 then LoopJ := Accessory[Item];
        if Kind = 2 then LoopJ := Guidance[Item];
        TmpStr := IntToStr(LoopJ);
        if (Kind = 2) and (Item = 0) then
        begin
          TmpStr := IntToStr(LoopJ div 10) + '%';
          if LoopJ > 1000 then TmpStr := '100%';
        end;
        if (Kind = 2) and (Item = 1) then
        begin
          TmpStr := TmpStr + '%';
          if LoopJ > 100 then TmpStr := '100%';
        end;
        if LoopJ > 0 then OutTextXY(X2 - 13, Y2, TmpStr);
      end;
    SetColor(0);
    SetTextStyle(FontTiny, 0, 4);
    SetTextJustify(0, 0);
    { "<qty> FOR <price>" }
    for LoopI := 1 to NumShopButtons do
      with ShopButtons[LoopI] do
      begin
        if Kind = 0 then TmpStr := IntToStr(WeaponBundles[Item]);
        if Kind = 1 then TmpStr := IntToStr(GuideBundles[Item]);
        if Kind = 2 then TmpStr := IntToStr(ShieldBundles[Item]);
        if (Kind = 2) and (Item in [0, 1]) then TmpStr := '100%';
        TmpStr := TmpStr + ' FOR ';
        if Kind = 0 then TmpStr := TmpStr + IntToStr(WeaponPrices[Item]);
        if Kind = 1 then TmpStr := TmpStr + IntToStr(GuidePrices[Item]);
        if Kind = 2 then TmpStr := TmpStr + IntToStr(ShieldPrices[Item]);
        OutTextXY(X1 + 2, Y2, TmpStr);
      end;
    SetColor(6);
    SetTextJustify(1, 1);
    for LoopI := 1 to NumShopButtons do
      with ShopButtons[LoopI] do
        DrawPanel3D(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3, 18, 17, 15);
  end;
end;

{ shop: every player that can afford something buys weapons/guidance/shields
  (keyboard, mouse, or computer players by their AI type) }
{#U0E9B_0E1F}
procedure RunShop;
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
    if (MinPrice > WeaponPrices[J]) and (WeaponBundles[J] <> 0) then
      MinPrice := WeaponPrices[J];
  for J := 0 to 1 do
    if (MinPrice > GuidePrices[J]) and (GuideBundles[J] <> 0) then
      MinPrice := GuidePrices[J];
  for J := 0 to 2 do
    if (MinPrice > ShieldPrices[J]) and (ShieldBundles[J] <> 0) then
      MinPrice := ShieldPrices[J];
  for I := 1 to NumPlayers do
    with Players[I] do
      if ((Controls[I] <> 3) or ((PComputer(Tanks[I])^.BuyStrategy <> 0) and (CompuBuy <> 0)))
        and (Score - Spent >= MinPrice) then
      begin
        InitPanelGreys;
        SetTextStyle(FontEuro, 0, 4);
        SetUserCharSize(1, 2, 1, 2);
        SetTextJustify(1, 2);
        DrawPanel3D(5, 5, 314, 35, 18, 15, 17);
        SetColor(I + 19);
        UpdatePlayerColor(Players[I]);
        OutTextXY(160, 3, Players[I].Name);
        SetTextStyle(2, 0, 4);
        SetTextJustify(0, 2);
        DrawPanel3D(10, 16, 59, 24, 18, 15, 17);
        SetColor(17);
        OutTextXY(11, 14, 'Purchase');
        DrawPanel3D(284, 16, 310, 24, 18, 15, 17);
        SetColor(17);
        OutTextXY(285, 14, 'Done');
        SetColor(6);
        SetTextStyle(FontTiny, 0, 4);
        SetTextJustify(0, 2);
        ShopCartCost := 0;
        ShopSpent := Spent;
        OutTextXY(11, 0, 'YOU HAVE UNALLOCATED:');
        OutTextXY(11, 21, IntToStr(Score - Spent - ShopCartCost) + ' DOLLARS');
        SetTextJustify(2, 2);
        SetColor(14);
        OutTextXY(309, 0, 'YOU CURRENTLY HAVE:');
        OutTextXY(309, 21, IntToStr(Score - ShopSpent) + ' DOLLARS');
        CopyBar(0, 38, 319, 199, SaveBuf);
        DrawShopButtons(I);
        DoneFlag := 0;
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
            if (ShopButtons[Sel].Kind = 0) and
               (WeaponPrices[ShopButtons[Sel].Item] > Score - ShopSpent - ShopCartCost) then Color := 0;
            if (ShopButtons[Sel].Kind = 1) and
               (GuidePrices[ShopButtons[Sel].Item] > Score - ShopSpent - ShopCartCost) then Color := 0;
            if (ShopButtons[Sel].Kind = 2) and
               (ShieldPrices[ShopButtons[Sel].Item] > Score - ShopSpent - ShopCartCost) then Color := 0;
            DrawRect(ShopButtons[Sel].X2 - 9, ShopButtons[Sel].Y1 + 3,
              ShopButtons[Sel].X2 - 3, ShopButtons[Sel].Y2 - 3, Color);
            if Controls[I] = 2 then ShowMouseCursor;
            OldSel := Sel;
            repeat
              { keyboard player }
              if Controls[I] = 1 then
                if KeyPressed then
                begin
                  KeyChar := UpCase(ReadKey);
                  if KeyChar = ' ' then Plus := True;
                  if KeyChar in [#13, 'P'] then Clicked := NumShopButtons + 1;
                  if KeyChar in [#27, 'D'] then Clicked := NumShopButtons + 2;
                  if KeyChar = '+' then Plus := True;
                  if KeyChar = '-' then Minus := True;
                  if KeyChar = '=' then Plus := True;
                  if Minus or Plus then Clicked := Sel;
                  if KeyChar = #0 then
                  begin
                    KeyChar := ReadKey;
                    if (KeyChar = ScanUp) and (Sel > 1) then Dec(Sel);
                    if (KeyChar = ScanDown) and (NumShopButtons > Sel) then Inc(Sel);
                    if (KeyChar = ScanRight) and (Sel + 9 <= NumShopButtons) then Inc(Sel, 9);
                    if (KeyChar = ScanLeft) and (Sel - 9 >= 1) then Dec(Sel, 9);
                  end;
                end;
              { mouse player }
              if Controls[I] = 2 then
                if MouseBtnsDown(1) or MouseBtnsDown(2) then
                begin
                  MX := MouseX;
                  MY := MouseY;
                  LeftBtn := MouseBtnsDown(1);
                  RightBtn := MouseBtnsDown(2);
                  for J := 1 to NumShopButtons do
                    with ShopButtons[J] do
                      if (MY >= Y1) and (MY <= Y2) and (MX <= X2) and (MX >= X1) then
                        Clicked := J;
                  if (MY >= 16) and (MY <= 24) and (MX <= 59) and (MX >= 10) then
                    Clicked := NumShopButtons + 1;
                  if (MY >= 16) and (MY <= 24) and (MX <= 310) and (MX >= 284) then
                    Clicked := NumShopButtons + 2;
                  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
                  if (Clicked > 0) and (NumShopButtons >= Clicked) then Sel := Clicked;
                end;
              { computer players: buy the most expensive affordable things }
              if Controls[I] = 3 then
                if PComputer(Tanks[I])^.BuyStrategy = 1 then
                begin
                  for J := NumShopButtons downto 1 do
                    if (ShopButtons[J].Item in [1..4]) and (ShopButtons[J].Kind = 0) and
                       (Players[I].Ammo[ShopButtons[J].Item] +
                         ShopButtons[J].Count * WeaponBundles[ShopButtons[J].Item] < 20) and
                       (Score - ShopSpent - ShopCartCost >= WeaponPrices[ShopButtons[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Plus <> True then Clicked := NumShopButtons + 2;
                end;
              if Controls[I] = 3 then
                if PComputer(Tanks[I])^.BuyStrategy = 2 then
                begin
                  for J := 1 to NumShopButtons do
                    if (ShopButtons[J].Item in [1..4]) and (ShopButtons[J].Kind = 0) and
                       (Score - ShopSpent - ShopCartCost >= WeaponPrices[ShopButtons[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players[I].Ammo[1] + WeaponBundles[1] * ShopButtons[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumShopButtons + 2;
                end;
              if Controls[I] = 3 then
                if PComputer(Tanks[I])^.BuyStrategy = 3 then
                begin
                  for J := 1 to NumShopButtons do
                    if (ShopButtons[J].Item in [1..5]) and (ShopButtons[J].Kind = 0) and
                       (Score - ShopSpent - ShopCartCost >= WeaponPrices[ShopButtons[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players[I].Ammo[1] + WeaponBundles[1] * ShopButtons[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumShopButtons + 2;
                end;
              if Controls[I] = 3 then
                if PComputer(Tanks[I])^.BuyStrategy = 4 then
                begin
                  for J := NumShopButtons downto 1 do
                    if (ShopButtons[J].Item in [0..2]) and (ShopButtons[J].Kind = 2) and
                       (Score - ShopSpent - ShopCartCost >= ShieldPrices[ShopButtons[J].Item]) then
                    begin
                      Sel := J;
                      Clicked := J;
                      Plus := True;
                    end;
                  if Players[I].Ammo[1] + WeaponBundles[1] * ShopButtons[1].Count < 20 then
                  begin
                    Sel := 1;
                    Clicked := 1;
                    Plus := True;
                  end;
                  if Plus <> True then Clicked := NumShopButtons + 2;
                end;
            until (OldSel <> Sel) or (Clicked > 0);
            if Controls[I] = 2 then HideMouseCursor;
            DrawRect(ShopButtons[OldSel].X2 - 9, ShopButtons[OldSel].Y1 + 3,
              ShopButtons[OldSel].X2 - 3, ShopButtons[OldSel].Y2 - 3, 18);
          until Clicked in [1..NumShopButtons + 2];
          OldCartCost := ShopCartCost;
          OldShopSpent := ShopSpent;
          with ShopButtons[Clicked] do
          begin
            if (Clicked > 0) and (NumShopButtons >= Clicked) then
              begin
                { sell back one unit }
                if Minus or LeftBtn then
                  if Count > 0 then
                  begin
                    Dec(ShopButtons[Clicked].Count);
                    if Kind = 0 then Dec(ShopCartCost, WeaponPrices[Item]);
                    if Kind = 1 then Dec(ShopCartCost, GuidePrices[Item]);
                    if Kind = 2 then Dec(ShopCartCost, ShieldPrices[Item]);
                    SetFillStyle(1, 18);
                    Bar(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3);
                    if Count > 0 then
                    begin
                      SetTextStyle(FontTiny, 0, 4);
                      SetTextJustify(1, 1);
                      SetColor(6);
                      OutTextXY((X2 - 13 + X2) div 2 + 1, (Y1 + Y2) div 2 - 2, IntToStr(Count));
                    end;
                  end;
                { buy one more unit }
                if Plus or RightBtn then
                  if Count < 9 then
                  begin
                    if Kind = 0 then LoopJ := WeaponPrices[Item];
                    if Kind = 1 then LoopJ := GuidePrices[Item];
                    if Kind = 2 then LoopJ := ShieldPrices[Item];
                    if LoopJ <= Score - ShopSpent - ShopCartCost then
                    begin
                      Inc(ShopCartCost, LoopJ);
                      Inc(Count);
                      SetFillStyle(1, 18);
                      Bar(X2 - 9, Y1 + 3, X2 - 3, Y2 - 3);
                      SetTextStyle(FontTiny, 0, 4);
                      SetTextJustify(1, 1);
                      SetColor(6);
                      OutTextXY((X2 - 13 + X2) div 2 + 1, (Y1 + Y2) div 2 - 2, IntToStr(Count));
                    end;
                  end;
                for J := 1 to NumShopButtons do
                begin
                  if ShopButtons[J].Kind = 0 then
                    if WeaponPrices[ShopButtons[J].Item] > Score - ShopSpent - ShopCartCost then
                      RGBHook(J + 100, 0, 0, 0)
                    else
                      RGBHook(J + 100, 63, 0, 0);
                  if ShopButtons[J].Kind = 1 then
                    if GuidePrices[ShopButtons[J].Item] > Score - ShopSpent - ShopCartCost then
                      RGBHook(J + 100, 0, 0, 0)
                    else
                      RGBHook(J + 100, 63, 0, 0);
                  if ShopButtons[J].Kind = 2 then
                    if ShieldPrices[ShopButtons[J].Item] > Score - ShopSpent - ShopCartCost then
                      RGBHook(J + 100, 0, 0, 0)
                    else
                      RGBHook(J + 100, 63, 0, 0);
                end;
              end;
            { "Done" = purchase and leave }
            if NumShopButtons + 2 = Clicked then
            begin
              Clicked := NumShopButtons + 1;
              DoneFlag := 1;
            end;
            { "Purchase": take the selected amounts }
            if NumShopButtons + 1 = Clicked then
            begin
              LoopK := 0;
              ShopCartCost := 0;
              OldCartCost := 1;
              for J := 1 to NumShopButtons do
                with ShopButtons[J] do
                begin
                  if Kind = 0 then LoopJ := WeaponPrices[Item];
                  if Kind = 1 then LoopJ := GuidePrices[Item];
                  if Kind = 2 then LoopJ := ShieldPrices[Item];
                  if Count > 0 then
                  begin
                    Inc(ShopSpent, LoopJ * Count);
                    if Kind = 0 then Inc(Ammo[Item], WeaponBundles[Item] * Count);
                    if Kind = 1 then Inc(Accessory[Item], GuideBundles[Item] * Count);
                    if Kind = 2 then Inc(Guidance[Item], ShieldBundles[Item] * Count);
                    Inc(LoopK, Count);
                  end;
                end;
              if (LoopK <> 0) and (DoneFlag = 0) then
              begin
                CopyBar(0, 38, 319, 199, SaveBuf);
                OldSel := Sel;
                DrawShopButtons(I);
                if NumShopButtons < Sel then Sel := NumShopButtons;
              end;
            end;
          end;
          if OldCartCost <> ShopCartCost then
          begin
            SetColor(6);
            SetTextStyle(FontTiny, 0, 4);
            SetTextJustify(0, 2);
            SetFillStyle(1, 18);
            Bar(11, 27, 80, 35);
            OutTextXY(11, 21, IntToStr(Score - ShopSpent - ShopCartCost) + ' DOLLARS');
          end;
          if OldShopSpent <> ShopSpent then
          begin
            SetColor(14);
            SetTextStyle(FontTiny, 0, 4);
            SetTextJustify(2, 2);
            SetFillStyle(1, 18);
            Bar(309, 27, 239, 35);
            OutTextXY(309, 21, IntToStr(Score - ShopSpent - ShopCartCost) + ' DOLLARS');
          end;
        until DoneFlag <> 0;
        Spent := ShopSpent;
      end;
  { close the shop screen }
  for J := 0 to 120 do
    CopyRect(J, J, 319 - J, 199 - J, SaveBuf);
end;

{ shuffle the player order }
{#U0E9B_23EF}
procedure ShufflePlayers;
var
  I, A, B: Integer;
begin
  for I := 1 to Random(20) + 10 do
  begin
    A := Random(NumPlayers) + 1;
    repeat
      B := Random(NumPlayers) + 1;
    until A <> B;
    SwapPlayers(A, B);
  end;
end;

{ statistics window of player P (waits for a key / mouse click) }
{#U0E9B_24E4}
procedure ShowPlayerStats(P: Integer);
var
  Buf: Pointer;
  S: string;
  Unused: LongInt;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  HideMouseCursor;
  GetMem(Buf, 6223);
  GetImage(78, 28, 242, 172, Buf^);
  SetPlayerColor(100, Players[P]);
  if TeamPlay <> 0 then
  begin
    SetTextStyle(2, 0, 1);
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 2);
    SetColor(P + 19);
    DrawPanel3D(2, 180, 84, 195, 18, 15, 17);
    OutTextXY(42, 181, Teams[Players[P].Team].Name);
  end;
  DrawPanel3D(80, 30, 240, 170, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  SetColor(P + 19);
  OutTextXY(160, 33, Players[P].Name);
  DrawLine(80, 47, 240, 47, 0);
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
  with Players[P] do
  begin
    case Controls[P] of
      1: S := 'Human (K)';
      2: S := 'Human (M)';
      3: S := 'Computer';
    end;
    OutTextXY(236, 46, S);
    OutTextXY(236, 56, IntToStr(Score));
    OutTextXY(236, 66, IntToStr(Score - Spent));
    OutTextXY(236, 76, IntToStr(Wins));
    OutTextXY(236, 86, IntToStr(f6C));
    OutTextXY(236, 96, IntToStr(f6E));
    OutTextXY(236, 106, IntToStr(f70));
    if f70 = 0 then
      S := 'Undefined'
    else
      S := IntToStr(Trunc(f6C / f70 * 100)) + '%';
    OutTextXY(236, 116, S);
    Str(f6E / GameNo:5:2, S);
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
    OutTextXY(236, 146, IntToStr(f68));
    Str(f68 / GameNo:5:1, S);
    OutTextXY(236, 156, S);
  end;
  ShowMouseCursor;
  repeat until MouseBtnsDown(1) or MouseBtnsDown(2) or KeyPressed;
  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
  KbdHead := KbdTail;
  HideMouseCursor;
  CopyBar(0, 178, 86, 197, SaveBuf);
  PutImage(78, 28, Buf^, 0);
  FreeMem(Buf, 6223);
  ShowMouseCursor;
end;

{ statistics window of team T (member names along the top/bottom edge) }
{#U0E9B_2B8E}
procedure ShowTeamStats(T: Integer);
var
  Buf: Pointer;
  S: string;
  I, X, Y, N: Integer;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  HideMouseCursor;
  GetMem(Buf, 6223);
  GetImage(78, 28, 242, 172, Buf^);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  N := -1;
  for I := 1 to NumPlayers do
    if Players[I].Team = T then
    begin
      SetPlayerColor(100, Players[I]);
      Inc(N);
      X := N * 64 + 32;
      Y := 3;
      if N > 4 then
      begin
        X := X - 320;
        Y := 181;
      end;
      SetColor(I + 19);
      S := Players[I].Name;
      while TextWidth(S) >= 60 do Dec(S[0]);
      DrawPanel3D(X - 29, Y, X + 29, Y + 15, 18, 15, 17);
      OutTextXY(X, Y + 1, S);
    end;
  DrawPanel3D(80, 30, 240, 170, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 2);
  SetColor(10);
  OutTextXY(160, 33, Teams[T].Name);
  DrawLine(80, 47, 240, 47, 0);
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
  with Teams[T] do
  begin
    OutTextXY(236, 46, IntToStr(f0F));
    OutTextXY(236, 56, IntToStr(Trunc(f11)));
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
      S := IntToStr(Trunc(f23 / f2F * 100)) + '%';
    OutTextXY(236, 116, S);
    Str(f29 / GameNo:5:2, S);
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
    Str(f17 / GameNo:5:1, S);
    OutTextXY(236, 156, S);
  end;
  ShowMouseCursor;
  repeat until MouseBtnsDown(1) or MouseBtnsDown(2) or KeyPressed;
  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
  KbdHead := KbdTail;
  HideMouseCursor;
  N := -1;
  for I := 1 to NumPlayers do
    if Players[I].Team = T then
    begin
      Inc(N);
      X := N * 64 + 32;
      Y := 3;
      if N > 4 then
      begin
        X := X - 320;
        Y := 181;
      end;
      CopyBar(X - 32, Y - 2, X + 32, Y + 17, SaveBuf);
    end;
  PutImage(78, 28, Buf^, 0);
  FreeMem(Buf, 6223);
  ShowMouseCursor;
end;

{ input box for the save game file name (SaveName, max. 8 chars);
  the marker of the procedure itself is in front of its main body }
procedure EditSaveName;
var
  Buf: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;

  { draw the cursor box at Pos and the character under it }
  {#U0E9B_33D2} procedure DrawNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + 133 - 1, 100, (Pos - 1) * 6 + 133 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 133, 101, (Pos - 1) * 6 + 133 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 133 + 1, 102, (Pos - 1) * 6 + 133 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName, Pos, 1));
    CopyBar((Pos - 1) * 6 + 133 - 1, 109, (Pos - 1) * 6 + 133 + 4, 110, SaveBuf);
  end;

  { remove the cursor box at Pos }
  {#U0E9B_3512} procedure EraseNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + 133 - 1, 100, (Pos - 1) * 6 + 133 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 133, 101, (Pos - 1) * 6 + 133 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 133 + 1, 102, (Pos - 1) * 6 + 133 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName, Pos, 1));
  end;

{#U0E9B_369F}
begin
  GetMem(Buf, 748);
  if Length(SaveName) < 8 then
    for I := Length(SaveName) + 1 to 8 do SaveName[I] := ' ';
  GetImage(123, 83, 197, 117, Buf^);
  DrawPanel3D(125, 85, 195, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(5);
  OutTextXY(128, 85, 'FILE NAME:');
  DrawPanel3D(130, 100, 190, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(SaveName) do
    OutTextXY((Pos - 1) * 6 + 133, 104, Copy(SaveName, Pos, 1));
  Inc(SaveName[0]);
  Pos := Length(SaveName);
  Done := False;
  repeat
    DrawNameCursor;
    Changed := False;
    repeat
      repeat until KeyPressed;
      KeyChar := ReadKey;
      if (KeyChar in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        SaveName[NewPos] := ' ';
        SaveName[NewPos + 1] := ' ';
        Changed := True;
      end;
      if KeyChar in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if KeyChar in ['0'..'9', 'A'..'Z', 'a'..'z'] then
      begin
        SaveName[Pos] := UpCase(KeyChar);
        Changed := True;
        NewPos := Pos + 1;
        if Length(SaveName) < NewPos then Inc(SaveName[0]);
      end;
      if KeyChar = #0 then
      begin
        KeyChar := ReadKey;
        if KeyChar = 'G' then                    { Home: clear }
        begin
          for Pos := Length(SaveName) downto 1 do
          begin
            SaveName[Pos] := ' ';
            DrawNameCursor;
            EraseNameCursor;
          end;
          SaveName := '  ';
          NewPos := 1;
        end;
        if KeyChar = 'S' then                    { Del }
        begin
          SaveName[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if KeyChar = 'O' then                    { End }
        begin
          Changed := True;
          NewPos := Length(SaveName);
        end;
        if (KeyChar = ScanLeft) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (KeyChar = ScanRight) and (Length(SaveName) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 8 then NewPos := 8;
    if Length(SaveName) > 8 then SaveName[0] := #8;
    EraseNameCursor;
    Pos := NewPos;
  until Done;
  while (SaveName[Length(SaveName)] in [#0, ' ']) and (Length(SaveName) > 0) do
    Dec(SaveName[0]);
  PutImage(123, 83, Buf^, 0);
  FreeMem(Buf, 748);
end;

{ save the game to FileName + '.TWS' }
{#U0E9B_39EA}
procedure SaveGame(FileName: string);
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
  Header := Header + 'V' + GameVersion + #13 + #10;
  Header := Header + #26;
  BlockWrite(F, Header[1], Length(Header));
  BlockWrite(F, BlastSize, 2);
  BlockWrite(F, NumPlayers, 2);
  BlockWrite(F, GameNo, 2);
  BlockWrite(F, RoundWind, 2);
  BlockWrite(F, GuideTarget, 2);
  BlockWrite(F, SavedUnused46C2, 2);
  BlockWrite(F, TurnLap, 2);
  BlockWrite(F, RoundWall, 2);
  BlockWrite(F, CurPlayer, 1);
  BlockWrite(F, AllComputers, 1);
  BlockWrite(F, WallsBounce, 1);
  BlockWrite(F, WallsWrap, 1);
  BlockWrite(F, WindForce, 2);
  BlockWrite(F, CrumblePct, 2);
  BlockWrite(F, GamesToPlay, 2);
  BlockWrite(F, WindControl, 2);
  BlockWrite(F, WallControl, 2);
  BlockWrite(F, BackControl, 2);
  BlockWrite(F, BackMask, 2);
  BlockWrite(F, FlySound, 1);
  BlockWrite(F, SoundOn, 1);
  BlockWrite(F, InvisoBall, 1);
  BlockWrite(F, ShotTrail, 1);
  BlockWrite(F, TanksFall, 1);
  BlockWrite(F, CompuBuy, 1);
  BlockWrite(F, TeamPlay, 1);
  for I := 1 to NumPlayers do
  begin
    BlockWrite(F, Players[I], 116);
    BlockWrite(F, Controls[I], 2);
    if Controls[I] = 3 then PComputer(Tanks[I])^.Save(F);
  end;
  BlockWrite(F, Teams, 583);
  Close(F);
end;

