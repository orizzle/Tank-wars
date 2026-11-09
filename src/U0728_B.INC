{ ---- U0728 part B: title/background, name editor, AI selector,
  player setup screen, main driver ---- }

{ set up the background palette (DAC 30..59) and fill the screen with
  the background pattern; Kind 0 = concentric rectangles, 1 = lines }
{#U0728_3A10}
procedure U0728_3A10(Kind: Integer);
begin
  for g_461E := 30 to 59 do
    g_E7C8(g_461E, g_461E, 0, g_461E);
  case Kind of
    0:
      begin
        case Random(2) of
          0: g_462A := 100;
          1: g_462A := 160;
        end;
        for g_461E := 0 to g_462A do
          U2823_0031(g_461E, g_461E, 319 - g_461E, 199 - g_461E, g_461E mod 30 + 30);
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        U2823_0C20(30, 30, @Pal_DE80);
        U2823_0C20(30, 30, @Pal_DE80[31]);
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
    1:
      begin
        for g_461E := 0 to 199 do
          U2823_09E4(0, g_461E, 319, g_461E, g_461E mod 30 + 30);
        PalCycle_9FB8.First := 30;
        PalCycle_9FB8.Field2 := 59;
        PalCycle_9FB8.Count := PalCycle_9FB8.Field2 - PalCycle_9FB8.First;
        PalCycle_9FB8.Pos := 0;
        U2823_0C20(30, 30, @Pal_DE80);
        U2823_0C20(30, 30, @Pal_DE80[31]);
        PalCycle_9FB8.Pal := @Pal_DE80;
        PalCycle_9FB8.Mode := 1;
        PalCycle_9FB8.Speed := g_E796;
      end;
  end;
  U27D4_003D(PalCycle_9FB8);
end;

{ main driver (called from the main program): NEW = beginner game with
  default settings, otherwise title / intro screens and player setup }
{#U0728_3BC3}
procedure U0728_3BC3;
var
  X1, X2, Y1, Y2: Integer;
begin
  for g_461E := 1 to 10 do
    U0728_0216(g_461E);
  if g_E794 <> 0 then
  begin
    g_E787 := 0;
    g_E77A := 100;
    g_E780 := 0;
    g_46BC := 1;
    g_E789 := 0;
    g_E78A := 1;
    g_E77C := 5;
    g_E78D := 1;
    g_46B4 := 2;
    g_E78F := 0;
    g_E782 := 0;
    g_E77E := 1;
    SaveName_46FC := 'QWERTYUI';
    g_46F0 := 0;
    g_46F1 := 0;
    g_46F2 := 0;
    g_E794 := 0;
    g_46EC := 0;
    g_E791 := 0;
    Players_3F0E[2].Name := 'Mr. Stupid';
    Control_E480[2] := 3;
    U0728_0078(2);
  end
  else
  begin
    g_461E := 0;
    g_4620 := 0;
    GetMem(SaveBuf_E496, 64000);
    U0098_01BD;
    SetViewPort(0, 0, 319, 199, True);
    U2823_0006;
    U0728_3A10(0);
    U0728_06D1;
    TScreenBuf(SaveBuf_E496^) := TScreenBuf(Ptr($A000, 0)^);
    U0728_08E6;
    U0728_1DD5;
    U2823_0006;
    for g_461E := 35 downto 0 do
    begin
      U2823_0687(50, 150, g_461E, g_461E, SaveBuf_E496);
      U2823_0687(51, 150, g_461E, g_461E, SaveBuf_E496);
    end;
    for g_461E := 100 downto 0 do
    begin
      U2823_0687(160, 100, g_461E, g_461E, SaveBuf_E496);
      U2823_0687(161, 100, g_461E, g_461E, SaveBuf_E496);
    end;
    g_E7D6 := $A000;
    if g_46F1 <> 0 then
      U0E9B_4B93;
    if g_46F1 = 0 then
      U0728_5083;
    if (g_46F1 = 0) and (g_E791 <> 0) then
      U0728_2609;
    X1 := 0;
    X2 := 0;
    Y1 := 0;
    Y2 := 0;
    for g_461E := 0 to 520 do
    begin
      if X1 < 319 then Inc(X1) else Inc(X2);
      if Y2 < 199 then Inc(Y2) else Inc(Y1);
      U2823_0AC0(X1, X2, Y1, Y2, SaveBuf_E496);
    end;
    if (g_46F1 = 0) and (g_E791 <> 0) then
      U0728_3449;
    for g_4624 := 0 to 319 do
      U2823_09E4(g_4624, 0, 319 - g_4624, 199, 0);
    for g_4626 := 0 to 199 do
      U2823_09E4(319, g_4626, 0, 199 - g_4626, 0);
    U27D4_003D(NoCycle_3706);
    FreeMem(SaveBuf_E496, 64000);
  end;
end;

{ edit the name of player P in a small dialog box }
procedure U0728_4183(P: Word);
var
  Buf: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;

  { draw the block cursor under character Pos }
  {#U0728_3EA1} procedure U0728_3EA1;
  begin
    U2823_0031((Pos - 1) * 6 + 118 - 1, 100, (Pos - 1) * 6 + 118 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 118, 101, (Pos - 1) * 6 + 118 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 118 + 1, 102, (Pos - 1) * 6 + 118 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players_3F0E[P].Name, Pos, 1));
    U2823_00CC((Pos - 1) * 6 + 118 - 1, 109, (Pos - 1) * 6 + 118 + 4, 110, SaveBuf_E496);
  end;

  { remove the cursor again }
  {#U0728_3FEE} procedure U0728_3FEE;
  begin
    U2823_0031((Pos - 1) * 6 + 118 - 1, 100, (Pos - 1) * 6 + 118 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 118, 101, (Pos - 1) * 6 + 118 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 118 + 1, 102, (Pos - 1) * 6 + 118 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players_3F0E[P].Name, Pos, 1));
  end;

{ marker here (not above the header): the nested procedures come first in the code }
{#U0728_4183}
begin
  GetMem(Buf, $409);
  if Length(Players_3F0E[P].Name) < 19 then
    for I := Length(Players_3F0E[P].Name) + 1 to 13 do
      Players_3F0E[P].Name[I] := ' ';
  GetImage(108, 83, 212, 117, Buf^);
  U0098_028C(110, 85, 210, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(5);
  OutTextXY(113, 85, 'NAME:');
  U0098_028C(115, 100, 205, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(Players_3F0E[P].Name) do
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players_3F0E[P].Name, Pos, 1));
  Inc(Players_3F0E[P].Name[0]);
  Pos := Length(Players_3F0E[P].Name);
  Done := False;
  repeat
    U0728_3EA1;
    Changed := False;
    repeat
      repeat until KeyPressed;
      g_46C9 := ReadKey;
      if (g_46C9 in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        Players_3F0E[P].Name[NewPos] := ' ';
        Changed := True;
      end;
      if g_46C9 in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if g_46C9 in [' '..'}'] then
      begin
        Players_3F0E[P].Name[Pos] := g_46C9;
        Changed := True;
        NewPos := Pos + 1;
        if Length(Players_3F0E[P].Name) < NewPos then
          Inc(Players_3F0E[P].Name[0]);
      end;
      if g_46C9 = #0 then
      begin
        g_46C9 := ReadKey;
        if g_46C9 = #$47 then           { Home: clear }
        begin
          for Pos := Length(Players_3F0E[P].Name) downto 1 do
          begin
            Players_3F0E[P].Name[Pos] := ' ';
            U0728_3EA1;
            U0728_3FEE;
          end;
          Players_3F0E[P].Name := '  ';
          NewPos := 1;
        end;
        if g_46C9 = #$53 then           { Del }
        begin
          Players_3F0E[P].Name[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if g_46C9 = #$4F then           { End }
        begin
          Changed := True;
          NewPos := Length(Players_3F0E[P].Name);
        end;
        if (g_46C9 = KeyLt_3719) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (g_46C9 = KeyRt_3718) and (Length(Players_3F0E[P].Name) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 13 then
      NewPos := 13;
    if Length(Players_3F0E[P].Name) > 13 then
      Players_3F0E[P].Name[0] := #13;
    U0728_3FEE;
    Pos := NewPos;
  until Done;
  while (Players_3F0E[P].Name[Length(Players_3F0E[P].Name)] in [#0, ' ']) and
        (Length(Players_3F0E[P].Name) > 0) do
    Dec(Players_3F0E[P].Name[0]);
  PutImage(108, 83, Buf^, 0);
  FreeMem(Buf, $409);
end;

{ let the user pick the computer player type (AI) of player P }
{#U0728_46AC}
procedure U0728_46AC(P: Word);
var
  Buf: Pointer;
  Sel, OldSel, Choice, I: Integer;
  Done, MouseL, MouseR, Unused10, B11, B12, Picked, Unused14: Boolean;  { B11/B12 only cleared }
begin
  repeat until not U2968_0077(1) and not U2968_0077(2);
  GetMem(Buf, $8A7);
  GetImage(114, 56, 206, 144, Buf^);
  U0098_028C(116, 58, 204, 142, 18, 15, 17);
  Sel := 0;
  for I := 1 to 6 do
    if Players_3F0E[P].Name = AINames_007C[I] then
      Sel := I;
  SetColor(6);
  SetTextJustify(1, 1);
  SetUserCharSize(1, 1, 1, 1);
  MoveTo(160, 63);
  SetColor(6);  OutText('Random (  ');
  SetColor(14); OutText('        ? ');
  SetColor(6);  OutText('         )');
  MoveTo(160, 73);
  SetColor(6);  OutText('Mr.       ');
  SetColor(14); OutText('    S     ');
  SetColor(6);  OutText('     tupid');
  MoveTo(160, 83);
  SetColor(14); OutText('L     ');
  SetColor(6);  OutText(' obber');
  MoveTo(160, 93);
  SetColor(14); OutText('R       ');
  SetColor(6);  OutText(' ifleman');
  MoveTo(160, 103);
  SetColor(6);  OutText('Lob & Shoot (  ');
  SetColor(14); OutText('             B ');
  SetColor(6);  OutText('              )');
  MoveTo(160, 113);
  SetColor(14); OutText('W           ');
  SetColor(6);  OutText(' indless Wit');
  MoveTo(160, 123);
  SetColor(14); OutText('T      ');
  SetColor(6);  OutText(' wanger');
  MoveTo(160, 133);
  SetColor(6);  OutText('Wind       ');
  SetColor(14); OutText('     M     ');
  SetColor(6);  OutText('      aster');
  Choice := -1;
  Done := False;
  repeat
    MouseL := False;
    MouseR := MouseL;
    B11 := MouseL;
    B12 := MouseL;
    Picked := MouseL;
    repeat
      U0098_03A8(119, 10 * Sel + 63);
      U0098_03A8(201, 10 * Sel + 63);
      U2968_004D;
      OldSel := Sel;
      repeat
        if KeyPressed then
        begin
          g_46C9 := UpCase(ReadKey);
          if g_46C9 = #27 then Choice := 0;
          if g_46C9 in [#13, ' '] then
          begin
            Choice := Sel;
            Picked := True;
          end;
          if g_46C9 = '?' then Choice := 0;
          if g_46C9 = 'S' then Choice := 1;
          if g_46C9 = 'L' then Choice := 2;
          if g_46C9 = 'R' then Choice := 3;
          if g_46C9 = 'B' then Choice := 4;
          if g_46C9 = 'W' then Choice := 5;
          if g_46C9 = 'T' then Choice := 6;
          if g_46C9 = 'M' then Choice := 7;
          if g_46C9 in ['?', 'S', 'L', 'R', 'B', 'W', 'T', 'M'] then
            Picked := True;
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            if (g_46C9 = KeyUp_3716) and (Sel > 0) then Dec(Sel);
            if (g_46C9 = KeyDn_3717) and (Sel < 7) then Inc(Sel);
          end;
        end;
        if U2968_0077(1) or U2968_0077(2) then
        begin
          MouseL := U2968_0077(1);
          MouseR := U2968_0077(2);
          g_4624 := U2918_022A;
          g_4626 := U2918_0256;
          if (g_4624 > 116) and (g_4624 < 204) then
          begin
            if (g_4626 > 60) and (g_4626 <= 69) then Choice := 0
            else if (g_4626 > 69) and (g_4626 <= 79) then Choice := 1
            else if (g_4626 > 79) and (g_4626 <= 89) then Choice := 2
            else if (g_4626 > 89) and (g_4626 <= 99) then Choice := 3
            else if (g_4626 > 99) and (g_4626 <= 109) then Choice := 4
            else if (g_4626 > 109) and (g_4626 <= 119) then Choice := 5
            else if (g_4626 > 119) and (g_4626 <= 129) then Choice := 6
            else if (g_4626 > 129) and (g_4626 < 142) then Choice := 7
            else Choice := 0;
          end
          else
            Choice := 0;
          if Choice >= 0 then
            Sel := Choice;
          repeat until not U2968_0077(1) and not U2968_0077(2);
        end;
      until (OldSel <> Sel) or (Choice >= 0);
      U2968_005A;
      SetFillStyle(1, 18);
      Bar(118, 10 * OldSel + 63 - 1, 120, 10 * OldSel + 63 + 1);
      Bar(200, 10 * OldSel + 63 - 1, 202, 10 * OldSel + 63 + 1);
    until Choice in [0..7];
    SetColor(14);
    SetFillStyle(1, 18);
    case Choice of
      0..7:
        begin
          Players_3F0E[P].Name := AINames_007C[Choice];
          Done := True;
        end;
    end;
    Choice := -1;
  until Done;
  PutImage(114, 56, Buf^, 0);
  FreeMem(Buf, $8A7);
end;

{ player setup screen: 10 boxes, choose names and keyboard / mouse /
  computer control }
procedure U0728_5083;
var
  X1, Y1, X2, Y2: array[1..10] of Integer;
  Color, Sel, OldSel, Choice, I, J: Integer;
  KeyF, MouseF, NameF, MouseL, MouseR, Unused62, Done, Unused64: Boolean;
  DivX, MultX: Integer;

  { draw the name field of box P }
  {#U0728_4CD7} procedure U0728_4CD7(P: Integer);
  begin
    Color := 18;
    if P > g_46B4 then
      Color := 17;
    U0098_028C(X1[P] + 3, Y1[P] + 3, X2[P] - 3, Y1[P] + 12, Color, 17, 15);
    MultX := 100;
    DivX := MultX;
    U26A9_01B0(100, Players_3F0E[P]);
    SetColor(P + 19);
    if Color = 17 then
      SetColor(0);
    SetTextJustify(1, 2);
    SetUserCharSize(MultX, DivX, 1, 1);
    while TextWidth(Players_3F0E[P].Name) > 49 do
    begin
      Dec(MultX);
      SetUserCharSize(MultX, DivX, 1, 1);
    end;
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 1, Players_3F0E[P].Name);
  end;

  { draw the KEYBOARD / MOUSE / COMPUTER selector of box P }
  {#U0728_4E65} procedure U0728_4E65(P: Integer);
  begin
    if P > g_46B4 then
      Control_E480[P] := 0;
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 1);
    if Control_E480[P] = 1 then SetColor(9) else SetColor(0);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19, 'KEYBOARD');
    if Control_E480[P] = 2 then SetColor(9) else SetColor(0);
    if g_E78B = 0 then
      SetUserCharSize(1, 1, 1, 3);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19 + 10, 'MOUSE');
    SetUserCharSize(1, 1, 1, 1);
    if Control_E480[P] = 3 then SetColor(9) else SetColor(0);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19 + 10 + 10, 'COMPUTER');
  end;

{ marker here (not above the header): the nested procedures come first in the code }
{#U0728_5083}
begin
  U0728_07CE;
  X1[1] := 10;
  X2[1] := 65;
  Y1[1] := 50;
  Y2[1] := 105;
  for I := 2 to 10 do
  begin
    J := I;
    if J < 6 then
    begin
      X1[I] := X1[I - 1] + 55 + 6;
      Y1[I] := 50;
    end
    else
    begin
      X1[I] := X1[I - 5];
      Y1[I] := 111;
    end;
    X2[I] := X1[I] + 55;
    Y2[I] := Y1[I] + 55;
  end;
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  for I := 1 to 10 do
  begin
    Color := 18;
    if I > g_46B4 then
      Color := 17;
    U0098_028C(X1[I], Y1[I], X2[I], Y2[I], Color, 15, 17);
    SetColor(5);
    SetTextJustify(1, 2);
    U0728_4CD7(I);
    U0728_4E65(I);
    U0098_03F4((X1[I] + X2[I]) div 2, Y2[I] - 4, SaveBuf_E496);
    if Color = 17 then
    begin
      U2823_017D((X1[I] + X2[I]) div 2, Y2[I] - 4, 1, 1, 0);
      U2823_0BB6((X1[I] + X2[I]) div 2, Y2[I] - 4, 0);
    end;
  end;
  Sel := 0;
  Choice := -1;
  Done := False;
  repeat
    MouseL := False;
    MouseR := MouseL;
    KeyF := MouseL;
    MouseF := MouseL;
    NameF := MouseL;
    repeat
      U0098_03A8((X1[Sel + 1] + X2[Sel + 1]) div 2, Y2[Sel + 1] - 4);
      U2968_004D;
      OldSel := Sel;
      repeat
        if KeyPressed then
        begin
          g_46C9 := UpCase(ReadKey);
          if g_46C9 in [#13, ' '] then
          begin
            Choice := Sel;
            NameF := True;
          end;
          if g_46C9 = 'K' then
          begin
            Choice := Sel;
            KeyF := True;
            MouseF := False;
          end;
          if g_46C9 = 'M' then
          begin
            Choice := Sel;
            MouseF := True;
            KeyF := False;
          end;
          if g_46C9 = 'C' then
          begin
            Choice := Sel;
            MouseF := True;
            KeyF := True;
          end;
          if g_46C9 in [#27, 'G', 'P', 'S'] then
            Choice := 10;
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            if g_46C9 = KeyLt_3719 then
            begin
              Dec(Sel);
              if Sel = -1 then Sel := g_46B4 - 1;
            end;
            if g_46C9 = KeyRt_3718 then
            begin
              Inc(Sel);
              if Sel = g_46B4 then Sel := 0;
            end;
            if g_46C9 = KeyUp_3716 then
            begin
              Dec(Sel, 5);
              if Sel < 0 then Inc(Sel, 10);
              if Sel >= g_46B4 then Dec(Sel, 5);
            end;
            if g_46C9 = KeyDn_3717 then
            begin
              Inc(Sel, 5);
              if Sel > 9 then Dec(Sel, 10);
              if Sel >= g_46B4 then Dec(Sel, 5);
            end;
          end;
        end;
        if U2968_0077(1) or U2968_0077(2) then
        begin
          MouseL := U2968_0077(1);
          MouseR := U2968_0077(2);
          g_4624 := U2918_022A;
          g_4626 := U2918_0256;
          for I := 1 to g_46B4 do
          begin
            if (g_4624 > X1[I]) and (g_4624 < X2[I]) and
               (g_4626 > Y1[I]) and (g_4626 < Y2[I]) then
              Sel := I - 1;
            if (X1[I] + 3 < g_4624) and (Y1[I] + 3 < g_4626) and
               (X2[I] - 3 > g_4624) and (Y1[I] + 12 > g_4626) then
            begin
              NameF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (g_4624 > X1[I]) and (g_4624 < X2[I]) and
               (Y1[I] + 15 < g_4626) and (Y1[I] + 15 + 10 > g_4626) then
            begin
              KeyF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (g_4624 > X1[I]) and (g_4624 < X2[I]) and
               (Y1[I] + 15 + 10 < g_4626) and (Y1[I] + 15 + 20 > g_4626) then
            begin
              MouseF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (g_4624 > X1[I]) and (g_4624 < X2[I]) and
               (Y1[I] + 15 + 20 < g_4626) and (Y1[I] + 15 + 30 > g_4626) then
            begin
              MouseF := True;
              KeyF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
          end;
          if (g_4624 > 71) and (g_4624 < 249) and (g_4626 > 171) and (g_4626 < 197) then
            Choice := 10;
        end;
      until (OldSel <> Sel) or (Choice >= 0);
      U2968_005A;
      U0098_03F4((X1[OldSel + 1] + X2[OldSel + 1]) div 2, Y2[OldSel + 1] - 4, SaveBuf_E496);
    until Choice in [0..10];
    SetColor(14);
    SetFillStyle(1, 18);
    case Choice of
      0..9:
        begin
          if NameF and (Control_E480[Choice + 1] in [1, 2]) then
          begin
            U0728_4183(Choice + 1);
            U0728_4CD7(Choice + 1);
          end;
          if NameF and (Control_E480[Choice + 1] = 3) then
          begin
            U0728_46AC(Choice + 1);
            U0728_4CD7(Choice + 1);
          end;
          if KeyF and not MouseF then
          begin
            J := Control_E480[Choice + 1];
            Control_E480[Choice + 1] := 1;
            U0728_4E65(Choice + 1);
            if J = 3 then
            begin
              U0728_4183(Choice + 1);
              U0728_4CD7(Choice + 1);
            end;
          end;
          if MouseF and not KeyF then
          begin
            J := Control_E480[Choice + 1];
            Control_E480[Choice + 1] := 2;
            U0728_4E65(Choice + 1);
            if J = 3 then
            begin
              U0728_4183(Choice + 1);
              U0728_4CD7(Choice + 1);
            end;
          end;
          if MouseF and KeyF then
          begin
            J := Control_E480[Choice + 1];
            Control_E480[Choice + 1] := 3;
            U0728_4E65(Choice + 1);
            U0728_46AC(Choice + 1);
            U0728_4CD7(Choice + 1);
          end;
        end;
      10:
        Done := True;
    end;
    Choice := -1;
  until Done;
  g_46EC := 1;
  FillChar(Tanks_3EE2, 44, 0);
  for I := 1 to g_46B4 do
  begin
    if (Control_E480[I] = 3) and (Players_3F0E[I].Name = 'Random') then
      Players_3F0E[I].Name := AINames_007C[Random(7) + 1];
    U0728_0078(I);
    if Control_E480[I] <> 3 then
      g_46EC := 0;
  end;
  repeat until not U2968_0077(1) and not U2968_0077(2);
  for g_4624 := 0 to 319 do
    U2823_0AC0(0, 199, g_4624, 0, SaveBuf_E496);
  for g_4626 := 0 to 199 do
    U2823_0AC0(0, 199, 319, g_4626, SaveBuf_E496);
end;

{ program setup: defaults, read BOMB.CFG, parse the command line
  (H = help screen, DEBUG = show the current parameters) }
{#U0728_62E4}
procedure U0728_62E4;
var
  I: Integer;
  Unused03: Byte;                   { unused locals keep the frame layout }
  SR: SearchRec;
  F: File;
  UnusedAF: Byte;
  Sig: string[4];                   { BOMB.CFG signature }
begin
  g_4654 := 0;
  g_E788 := 1;
  g_E787 := 0;
  g_E77A := 10;
  g_E780 := 0;
  g_46BC := 1;
  g_E789 := 0;
  g_E78A := 0;
  g_E77C := 10;
  g_E78D := 1;
  g_46B4 := 2;
  g_E78F := 1;
  g_E782 := 0;
  g_E77E := 2;
  SaveName_46FC := 'QWERTYUI';
  g_46F0 := 0;
  g_46F1 := 0;
  g_46F2 := 0;
  g_E794 := 0;
  g_46EC := 1;
  g_E78B := 0;
  g_E790 := 0;
  g_E792 := 1;
  g_E78E := 1;
  g_E79E := 0;
  g_E786 := 1;
  g_E78C := 0;
  g_E791 := 0;
  g_E793 := 1;
  g_E79C := 0;
  g_E798 := 0;
  g_E79A := 0;
  g_E796 := 0;
  FindFirst('BOMB.CFG', AnyFile, SR);
  if DosError = 0 then
  begin
    Assign(F, 'BOMB.CFG');
    Reset(F, 1);
    Sig := 'BADx';
    BlockRead(F, Sig, 5);
    if Sig <> Version_0056 then
    begin
      TextMode(3);
      Writeln('An invalid BOMB.CFG has been found.');
      Writeln('Please run BOMBCFG to correct the situation.');
      Halt(1);
    end;
    BlockRead(F, g_E788, 1);
    BlockRead(F, g_E787, 1);
    BlockRead(F, g_E77E, 2);
    BlockRead(F, g_E77A, 2);
    BlockRead(F, g_E780, 2);
    BlockRead(F, g_E789, 1);
    BlockRead(F, g_E78A, 1);
    BlockRead(F, g_E77C, 2);
    BlockRead(F, g_E78D, 1);
    BlockRead(F, g_E782, 2);
    BlockRead(F, g_E784, 2);
    BlockRead(F, g_E790, 1);
    BlockRead(F, g_E78B, 1);
    BlockRead(F, g_E792, 1);
    BlockRead(F, g_E786, 1);
    BlockRead(F, g_E78C, 1);
    BlockRead(F, g_E796, 2);
    BlockRead(F, g_E78F, 1);
    BlockRead(F, g_E798, 2);
    BlockRead(F, g_E79C, 2);
    BlockRead(F, g_E79A, 2);
    BlockRead(F, g_E79E, 2);
    BlockRead(F, g_E793, 1);
    BlockRead(F, g_E791, 1);
    Close(F);
  end
  else
  begin
    TextMode(3);
    ClrScr;
    Writeln('A valid BOMB.CFG file was not found in the default directory.');
    Writeln('Please run BOMBCFG.EXE to create this file.');
    Halt(1);
  end;
  if ParamCount > 0 then
    for I := 1 to ParamCount do
    begin
      g_46CA := U2918_0337(ParamStr(I));
      if g_46CA[1] in ['/', '\'] then
        Delete(g_46CA, 1, 1);
      if g_46CA = 'H' then g_4654 := 1;
      if g_46CA = 'S-' then g_E788 := 0;
      if g_46CA = 'S+' then g_E788 := 1;
      if g_46CA = 'F+' then g_E787 := 1;
      if g_46CA = 'F-' then g_E787 := 0;
      if g_46CA[1] = 'G' then
        Val(Copy(g_46CA, 2, 3), g_E77C, g_4620);
      if (Copy(g_46CA, 1, 2) = 'BK') and (g_46CA[3] >= 'A') and (g_46CA[3] < 'I') then
        g_E782 := Ord(g_46CA[3]) - 64;
      if (g_46CA = 'BK-') or (g_46CA = 'BKN') then g_E782 := 0;
      if (g_46CA = 'BK+') or (g_46CA = 'BKR') then g_E782 := 9;
      if g_46CA = 'BKU' then g_E782 := 10;
      if g_46CA[1] = 'W' then
        Val(Copy(g_46CA, 2, 1), g_E77E, g_4620);
      g_E77E := g_E77E mod 6;
      if g_46CA[1] = 'R' then
        Val(Copy(g_46CA, 2, 1), g_E780, g_4620);
      g_E780 := g_E780 mod 6;
      if g_46CA = 'R+' then g_E780 := 2;
      if g_46CA = 'RR' then g_E780 := 5;
      if g_46CA = 'R-' then g_E780 := 0;
      if g_46CA[1] = 'C' then
        Val(Copy(g_46CA, 2, 3), g_E77A, g_4620);
      if g_46CA = 'C+' then g_E77A := 100;
      if g_46CA = 'C-' then g_E77A := 0;
      if g_46CA = 'I+' then g_E789 := 1;
      if g_46CA = 'I-' then g_E789 := 0;
      if g_46CA = 'T+' then g_E78A := 1;
      if g_46CA = 'T-' then g_E78A := 0;
      if g_46CA = 'D-' then g_E78D := 0;
      if g_46CA = 'D+' then g_E78D := 1;
      if Copy(g_46CA, 0, 4) = 'TEAM' then g_E791 := 1;
      if g_46CA = 'B-' then g_E78F := 0;
      if g_46CA = 'B+' then g_E78F := 1;
      if Copy(g_46CA, 1, 2) = 'TS' then
        Val(Copy(g_46CA, 3, 3), g_E798, g_4620);
      if Copy(g_46CA, 1, 2) = 'FS' then
        Val(Copy(g_46CA, 3, 3), g_E79C, g_4620);
      if Copy(g_46CA, 1, 2) = 'ES' then
        Val(Copy(g_46CA, 3, 3), g_E79A, g_4620);
      if Copy(g_46CA, 1, 2) = 'SS' then
        Val(Copy(g_46CA, 3, 3), g_E79E, g_4620);
      if g_46CA = 'M-' then
      begin
        g_E78B := 0;
        g_E790 := 1;
      end;
      if g_46CA = 'M+' then
      begin
        g_E78B := 1;
        g_E790 := 1;
      end;
      if g_46CA = 'H-' then g_E792 := 0;
      if g_46CA = 'H+' then g_E792 := 1;
      if g_46CA = 'DV+' then g_E792 := 1;
      if g_46CA = 'DV-' then g_E792 := 0;
      if g_46CA = 'CV+' then g_E78C := 1;
      if g_46CA = 'CV-' then g_E78C := 0;
      if g_46CA = 'CRUDE' then g_E78C := 1;
      if g_46CA = 'NOCRUDE' then g_E78C := 0;
      if g_46CA = 'P-' then g_E786 := 0;
      if g_46CA = 'P+' then g_E786 := 1;
      if g_46CA = 'PV' then
      begin
        g_E786 := 1;
        g_E793 := 1;
      end;
      if g_46CA = 'PT' then
      begin
        g_E786 := 1;
        g_E793 := 0;
      end;
      if g_46CA = 'SKIP' then g_E78E := 0;
      if g_46CA = 'NEW' then g_E794 := 1;
      if g_46CA = 'DEBUG' then g_E795 := 1;
    end;
  if g_4654 <> 0 then
  begin
    Writeln('Tank Wars Command Line Parameters:');
    Writeln('Game Options:');
    Writeln('  S+|-  Sound On|Off                    F+|-  Flysound On|Off');
    Writeln('  Gnn   Number of games to play         BKx   Background Selection');
    Writeln('  Wn    Wind Control   0..5, [None,Low,Normal,High,Gale,Random]');
    Writeln('  Rn    Wall Reflectivity   0..5, [None,Sticky,Elastic,Accel,Warp,Random]');
    Writeln('  Cnnn  Crumble Percentage');
    Writeln('  I+|-  Invisible Ball On|Off           T+|-  Shot Trace On|Off');
    Writeln('  D+|-  Tanks Fall Down                 B+|-  Computers Can Buy Weapons');
    Writeln('  TEAM  Activate Team Play Mode         NEW   Beginner Level Game');
    Writeln('Hardware Options:');
    Writeln('  M+|-  Enable|Disable Mouse');
    Writeln('  DV+|- Direct Video Port Access On|Off');
    Writeln('  CV+|- Crude Video Manipulation On|Off');
    Writeln('  P+|-  Palette Rotation On|Off');
    Writeln('  PV    Palette uses Video Retrace Interrupt');
    Writeln('  PT    Palette uses Timer Interrupt');
    Writeln('Speed Options:');
    Writeln('  SKIP  Skip Title Screen');
    Writeln('  ESnn  Explotion Speed                 FSnn  Fall Speed');
    Writeln('  PSnn  Projectile Speed                SSnn  Shot Speed');
    Halt;
  end;
  U2823_0DCF(g_4656, g_E792, g_E78C);
  if g_E795 <> 0 then
  begin
    ClrScr;
    TextColor(10);
    Writeln('  Current Parameters:');
    TextColor(13); Write('Effsound............................:');
    TextColor(14); Writeln(Boolean(g_E788));
    TextColor(13); Write('Flysound............................:');
    TextColor(14); Writeln(Boolean(g_E787));
    TextColor(13); Write('WindControl.........................:');
    TextColor(14); Writeln(g_E77E);
    TextColor(13); Write('Crumbper............................:');
    TextColor(14); Writeln(g_E77A);
    TextColor(13); Write('Wallcontrol.........................:');
    TextColor(14); Writeln(g_E780);
    TextColor(13); Write('Inviso..............................:');
    TextColor(14); Writeln(Boolean(g_E789));
    TextColor(13); Write('Trail...............................:');
    TextColor(14); Writeln(Boolean(g_E78A));
    TextColor(13); Write('GamesToPlay.........................:');
    TextColor(14); Writeln(g_E77C);
    TextColor(13); Write('FallDown............................:');
    TextColor(14); Writeln(Boolean(g_E78D));
    TextColor(13); Write('BackControl.........................:');
    TextColor(14); Writeln(g_E782);
    TextColor(13); Write('ForceMouse..........................:');
    TextColor(14); Writeln(Boolean(g_E790));
    TextColor(13); Write('Mousein.............................:');
    TextColor(14); Writeln(Boolean(g_E78B));
    TextColor(13); Write('Fastpal.............................:');
    TextColor(14); Writeln(Boolean(g_E792));
    TextColor(13); Write('CrudeCycle..........................:');
    TextColor(14); Writeln(Boolean(g_E78C));
    TextColor(13); Write('Palette.............................:');
    TextColor(14); Writeln(Boolean(g_E786));
    TextColor(13); Write('Pspeed..............................:');
    TextColor(14); Writeln(g_E796);
    TextColor(13); Write('CompuBuy............................:');
    TextColor(14); Writeln(Boolean(g_E78F));
    U2918_01A1;
    ClrScr;
    TextColor(10);
    Writeln('  Current Parameters:');
    TextColor(13); Write('TurretSpeed.........................:');
    TextColor(14); Writeln(g_E798);
    TextColor(13); Write('FallSpeed...........................:');
    TextColor(14); Writeln(g_E79C);
    TextColor(13); Write('ExplodeSpeed........................:');
    TextColor(14); Writeln(g_E79A);
    TextColor(13); Write('ShotSpeed...........................:');
    TextColor(14); Writeln(g_E79E);
    TextColor(13); Write('CPU.................................:');
    TextColor(14); Writeln(g_4656);
    TextColor(13); Write('Range Checking...$R.................:');
    TextColor(14); Writeln('OFF');
    TextColor(13); Write('Stack Checking...$S.................:');
    TextColor(14); Writeln('OFF');
    TextColor(13); Write('I/O Checking.....$I.................:');
    TextColor(14); Writeln('OFF');
    TextColor(13); Write('286 Code.........$G.................:');
    TextColor(14); Writeln('OFF');
    TextColor(13); Write('80x87 Emulation..$E.................:');
    TextColor(14); Writeln('ON');
    TextColor(13); Write('80x87 Support....$N.................:');
    TextColor(14); Writeln('ON');
    TextColor(13); Write('Overlay Configuration...............:');
    TextColor(14); Writeln('OFF');
    TextColor(13); Write('Video Interrupt.....................:');
    TextColor(14); Writeln(Boolean(g_E793));
    TextColor(13); Write('Team Play...........................:');
    TextColor(14); Writeln(Boolean(g_E791));
    U2918_01A1;
  end;
end;
