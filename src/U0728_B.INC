{ ---- U0728 part B: title/background, name editor, AI selector,
  player setup screen, main driver ---- }

{ set up the background palette (DAC 30..59) and fill the screen with
  the background pattern; Kind 0 = concentric rectangles, 1 = lines }
{#U0728_3A10}
procedure DrawMenuBackground(Kind: Integer);
begin
  for LoopI := 30 to 59 do
    RGBHook(LoopI, LoopI, 0, LoopI);
  case Kind of
    0:
      begin
        case Random(2) of
          0: TmpC := 100;
          1: TmpC := 160;
        end;
        for LoopI := 0 to TmpC do
          DrawRect(LoopI, LoopI, 319 - LoopI, 199 - LoopI, LoopI mod 30 + 30);
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        ReadDacBlock(30, 30, @CyclePal);
        ReadDacBlock(30, 30, @CyclePal[31]);
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
    1:
      begin
        for LoopI := 0 to 199 do
          DrawLine(0, LoopI, 319, LoopI, LoopI mod 30 + 30);
        PalCycle.First := 30;
        PalCycle.Field2 := 59;
        PalCycle.Count := PalCycle.Field2 - PalCycle.First;
        PalCycle.Pos := 0;
        ReadDacBlock(30, 30, @CyclePal);
        ReadDacBlock(30, 30, @CyclePal[31]);
        PalCycle.Pal := @CyclePal;
        PalCycle.Mode := 1;
        PalCycle.Speed := PalSpeed;
      end;
  end;
  SetPalCycle(PalCycle);
end;

{ main driver (called from the main program): NEW = beginner game with
  default settings, otherwise title / intro screens and player setup }
{#U0728_3BC3}
procedure SetupGame;
var
  X1, X2, Y1, Y2: Integer;
begin
  for LoopI := 1 to 10 do
    ResetPlayer(LoopI);
  if BeginnerGame <> 0 then
  begin
    FlySound := 0;
    CrumblePct := 100;
    WallControl := 0;
    GameNo := 1;
    InvisoBall := 0;
    ShotTrail := 1;
    GamesToPlay := 5;
    TanksFall := 1;
    NumPlayers := 2;
    CompuBuy := 0;
    BackControl := 0;
    WindControl := 1;
    SaveName := 'QWERTYUI';
    SaveRequested := 0;
    LoadRequested := 0;
    AutoSave := 0;
    BeginnerGame := 0;
    AllComputers := 0;
    TeamPlay := 0;
    Players[2].Name := 'Mr. Stupid';
    Controls[2] := 3;
    CreateAIPlayer(2);
  end
  else
  begin
    LoopI := 0;
    LoopJ := 0;
    GetMem(SaveBuf, 64000);
    InitPanelGreys;
    SetViewPort(0, 0, 319, 199, True);
    FetchClipWindow;
    DrawMenuBackground(0);
    DrawTitleBox;
    TScreenBuf(SaveBuf^) := TScreenBuf(Ptr($A000, 0)^);
    DrawMainMenuHeader;
    RunMainMenu;
    FetchClipWindow;
    for LoopI := 35 downto 0 do
    begin
      CopyEllipse(50, 150, LoopI, LoopI, SaveBuf);
      CopyEllipse(51, 150, LoopI, LoopI, SaveBuf);
    end;
    for LoopI := 100 downto 0 do
    begin
      CopyEllipse(160, 100, LoopI, LoopI, SaveBuf);
      CopyEllipse(161, 100, LoopI, LoopI, SaveBuf);
    end;
    VideoSeg := $A000;
    if LoadRequested <> 0 then
      LoadGameDialog;
    if LoadRequested = 0 then
      PlayerSetupScreen;
    if (LoadRequested = 0) and (TeamPlay <> 0) then
      TeamSetupScreen;
    X1 := 0;
    X2 := 0;
    Y1 := 0;
    Y2 := 0;
    for LoopI := 0 to 520 do
    begin
      if X1 < 319 then Inc(X1) else Inc(X2);
      if Y2 < 199 then Inc(Y2) else Inc(Y1);
      CopyLine(X1, X2, Y1, Y2, SaveBuf);
    end;
    if (LoadRequested = 0) and (TeamPlay <> 0) then
      BuildTeams;
    for TmpX := 0 to 319 do
      DrawLine(TmpX, 0, 319 - TmpX, 199, 0);
    for TmpY := 0 to 199 do
      DrawLine(319, TmpY, 0, 199 - TmpY, 0);
    SetPalCycle(NoPalCycle);
    FreeMem(SaveBuf, 64000);
  end;
end;

{ edit the name of player P in a small dialog box }
procedure EditPlayerName(P: Word);
var
  Buf: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;

  { draw the block cursor under character Pos }
  {#U0728_3EA1} procedure DrawPlayerNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + 118 - 1, 100, (Pos - 1) * 6 + 118 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 118, 101, (Pos - 1) * 6 + 118 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 118 + 1, 102, (Pos - 1) * 6 + 118 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players[P].Name, Pos, 1));
    CopyBar((Pos - 1) * 6 + 118 - 1, 109, (Pos - 1) * 6 + 118 + 4, 110, SaveBuf);
  end;

  { remove the cursor again }
  {#U0728_3FEE} procedure HidePlayerNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + 118 - 1, 100, (Pos - 1) * 6 + 118 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 118, 101, (Pos - 1) * 6 + 118 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 118 + 1, 102, (Pos - 1) * 6 + 118 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players[P].Name, Pos, 1));
  end;

{ marker here (not above the header): the nested procedures come first in the code }
{#U0728_4183}
begin
  GetMem(Buf, $409);
  if Length(Players[P].Name) < 19 then
    for I := Length(Players[P].Name) + 1 to 13 do
      Players[P].Name[I] := ' ';
  GetImage(108, 83, 212, 117, Buf^);
  DrawPanel3D(110, 85, 210, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(5);
  OutTextXY(113, 85, 'NAME:');
  DrawPanel3D(115, 100, 205, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(Players[P].Name) do
    OutTextXY((Pos - 1) * 6 + 118, 104, Copy(Players[P].Name, Pos, 1));
  Inc(Players[P].Name[0]);
  Pos := Length(Players[P].Name);
  Done := False;
  repeat
    DrawPlayerNameCursor;
    Changed := False;
    repeat
      repeat until KeyPressed;
      KeyChar := ReadKey;
      if (KeyChar in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        Players[P].Name[NewPos] := ' ';
        Changed := True;
      end;
      if KeyChar in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if KeyChar in [' '..'}'] then
      begin
        Players[P].Name[Pos] := KeyChar;
        Changed := True;
        NewPos := Pos + 1;
        if Length(Players[P].Name) < NewPos then
          Inc(Players[P].Name[0]);
      end;
      if KeyChar = #0 then
      begin
        KeyChar := ReadKey;
        if KeyChar = #$47 then           { Home: clear }
        begin
          for Pos := Length(Players[P].Name) downto 1 do
          begin
            Players[P].Name[Pos] := ' ';
            DrawPlayerNameCursor;
            HidePlayerNameCursor;
          end;
          Players[P].Name := '  ';
          NewPos := 1;
        end;
        if KeyChar = #$53 then           { Del }
        begin
          Players[P].Name[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if KeyChar = #$4F then           { End }
        begin
          Changed := True;
          NewPos := Length(Players[P].Name);
        end;
        if (KeyChar = ScanLeft) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (KeyChar = ScanRight) and (Length(Players[P].Name) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 13 then
      NewPos := 13;
    if Length(Players[P].Name) > 13 then
      Players[P].Name[0] := #13;
    HidePlayerNameCursor;
    Pos := NewPos;
  until Done;
  while (Players[P].Name[Length(Players[P].Name)] in [#0, ' ']) and
        (Length(Players[P].Name) > 0) do
    Dec(Players[P].Name[0]);
  PutImage(108, 83, Buf^, 0);
  FreeMem(Buf, $409);
end;

{ let the user pick the computer player type (AI) of player P }
{#U0728_46AC}
procedure SelectAIType(P: Word);
var
  Buf: Pointer;
  Sel, OldSel, Choice, I: Integer;
  Done, MouseL, MouseR, Unused10, B11, B12, Picked, Unused14: Boolean;  { B11/B12 only cleared }
begin
  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
  GetMem(Buf, $8A7);
  GetImage(114, 56, 206, 144, Buf^);
  DrawPanel3D(116, 58, 204, 142, 18, 15, 17);
  Sel := 0;
  for I := 1 to 6 do
    if Players[P].Name = AINames[I] then
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
      DrawPlusMark(119, 10 * Sel + 63);
      DrawPlusMark(201, 10 * Sel + 63);
      ShowMouseCursor;
      OldSel := Sel;
      repeat
        if KeyPressed then
        begin
          KeyChar := UpCase(ReadKey);
          if KeyChar = #27 then Choice := 0;
          if KeyChar in [#13, ' '] then
          begin
            Choice := Sel;
            Picked := True;
          end;
          if KeyChar = '?' then Choice := 0;
          if KeyChar = 'S' then Choice := 1;
          if KeyChar = 'L' then Choice := 2;
          if KeyChar = 'R' then Choice := 3;
          if KeyChar = 'B' then Choice := 4;
          if KeyChar = 'W' then Choice := 5;
          if KeyChar = 'T' then Choice := 6;
          if KeyChar = 'M' then Choice := 7;
          if KeyChar in ['?', 'S', 'L', 'R', 'B', 'W', 'T', 'M'] then
            Picked := True;
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            if (KeyChar = ScanUp) and (Sel > 0) then Dec(Sel);
            if (KeyChar = ScanDown) and (Sel < 7) then Inc(Sel);
          end;
        end;
        if MouseBtnsDown(1) or MouseBtnsDown(2) then
        begin
          MouseL := MouseBtnsDown(1);
          MouseR := MouseBtnsDown(2);
          TmpX := MouseX;
          TmpY := MouseY;
          if (TmpX > 116) and (TmpX < 204) then
          begin
            if (TmpY > 60) and (TmpY <= 69) then Choice := 0
            else if (TmpY > 69) and (TmpY <= 79) then Choice := 1
            else if (TmpY > 79) and (TmpY <= 89) then Choice := 2
            else if (TmpY > 89) and (TmpY <= 99) then Choice := 3
            else if (TmpY > 99) and (TmpY <= 109) then Choice := 4
            else if (TmpY > 109) and (TmpY <= 119) then Choice := 5
            else if (TmpY > 119) and (TmpY <= 129) then Choice := 6
            else if (TmpY > 129) and (TmpY < 142) then Choice := 7
            else Choice := 0;
          end
          else
            Choice := 0;
          if Choice >= 0 then
            Sel := Choice;
          repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
        end;
      until (OldSel <> Sel) or (Choice >= 0);
      HideMouseCursor;
      SetFillStyle(1, 18);
      Bar(118, 10 * OldSel + 63 - 1, 120, 10 * OldSel + 63 + 1);
      Bar(200, 10 * OldSel + 63 - 1, 202, 10 * OldSel + 63 + 1);
    until Choice in [0..7];
    SetColor(14);
    SetFillStyle(1, 18);
    case Choice of
      0..7:
        begin
          Players[P].Name := AINames[Choice];
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
procedure PlayerSetupScreen;
var
  X1, Y1, X2, Y2: array[1..10] of Integer;
  Color, Sel, OldSel, Choice, I, J: Integer;
  KeyF, MouseF, NameF, MouseL, MouseR, Unused62, Done, Unused64: Boolean;
  DivX, MultX: Integer;

  { draw the name field of box P }
  {#U0728_4CD7} procedure DrawSetupBoxName(P: Integer);
  begin
    Color := 18;
    if P > NumPlayers then
      Color := 17;
    DrawPanel3D(X1[P] + 3, Y1[P] + 3, X2[P] - 3, Y1[P] + 12, Color, 17, 15);
    MultX := 100;
    DivX := MultX;
    SetPlayerColor(100, Players[P]);
    SetColor(P + 19);
    if Color = 17 then
      SetColor(0);
    SetTextJustify(1, 2);
    SetUserCharSize(MultX, DivX, 1, 1);
    while TextWidth(Players[P].Name) > 49 do
    begin
      Dec(MultX);
      SetUserCharSize(MultX, DivX, 1, 1);
    end;
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 1, Players[P].Name);
  end;

  { draw the KEYBOARD / MOUSE / COMPUTER selector of box P }
  {#U0728_4E65} procedure DrawSetupBoxControl(P: Integer);
  begin
    if P > NumPlayers then
      Controls[P] := 0;
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 1);
    if Controls[P] = 1 then SetColor(9) else SetColor(0);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19, 'KEYBOARD');
    if Controls[P] = 2 then SetColor(9) else SetColor(0);
    if MouseIn = 0 then
      SetUserCharSize(1, 1, 1, 3);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19 + 10, 'MOUSE');
    SetUserCharSize(1, 1, 1, 1);
    if Controls[P] = 3 then SetColor(9) else SetColor(0);
    OutTextXY((X1[P] + X2[P]) div 2, Y1[P] + 19 + 10 + 10, 'COMPUTER');
  end;

{ marker here (not above the header): the nested procedures come first in the code }
{#U0728_5083}
begin
  DrawStartButton;
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
    if I > NumPlayers then
      Color := 17;
    DrawPanel3D(X1[I], Y1[I], X2[I], Y2[I], Color, 15, 17);
    SetColor(5);
    SetTextJustify(1, 2);
    DrawSetupBoxName(I);
    DrawSetupBoxControl(I);
    ErasePlusMark((X1[I] + X2[I]) div 2, Y2[I] - 4, SaveBuf);
    if Color = 17 then
    begin
      DrawEllipseNoClip((X1[I] + X2[I]) div 2, Y2[I] - 4, 1, 1, 0);
      PlotPixel((X1[I] + X2[I]) div 2, Y2[I] - 4, 0);
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
      DrawPlusMark((X1[Sel + 1] + X2[Sel + 1]) div 2, Y2[Sel + 1] - 4);
      ShowMouseCursor;
      OldSel := Sel;
      repeat
        if KeyPressed then
        begin
          KeyChar := UpCase(ReadKey);
          if KeyChar in [#13, ' '] then
          begin
            Choice := Sel;
            NameF := True;
          end;
          if KeyChar = 'K' then
          begin
            Choice := Sel;
            KeyF := True;
            MouseF := False;
          end;
          if KeyChar = 'M' then
          begin
            Choice := Sel;
            MouseF := True;
            KeyF := False;
          end;
          if KeyChar = 'C' then
          begin
            Choice := Sel;
            MouseF := True;
            KeyF := True;
          end;
          if KeyChar in [#27, 'G', 'P', 'S'] then
            Choice := 10;
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            if KeyChar = ScanLeft then
            begin
              Dec(Sel);
              if Sel = -1 then Sel := NumPlayers - 1;
            end;
            if KeyChar = ScanRight then
            begin
              Inc(Sel);
              if Sel = NumPlayers then Sel := 0;
            end;
            if KeyChar = ScanUp then
            begin
              Dec(Sel, 5);
              if Sel < 0 then Inc(Sel, 10);
              if Sel >= NumPlayers then Dec(Sel, 5);
            end;
            if KeyChar = ScanDown then
            begin
              Inc(Sel, 5);
              if Sel > 9 then Dec(Sel, 10);
              if Sel >= NumPlayers then Dec(Sel, 5);
            end;
          end;
        end;
        if MouseBtnsDown(1) or MouseBtnsDown(2) then
        begin
          MouseL := MouseBtnsDown(1);
          MouseR := MouseBtnsDown(2);
          TmpX := MouseX;
          TmpY := MouseY;
          for I := 1 to NumPlayers do
          begin
            if (TmpX > X1[I]) and (TmpX < X2[I]) and
               (TmpY > Y1[I]) and (TmpY < Y2[I]) then
              Sel := I - 1;
            if (X1[I] + 3 < TmpX) and (Y1[I] + 3 < TmpY) and
               (X2[I] - 3 > TmpX) and (Y1[I] + 12 > TmpY) then
            begin
              NameF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (TmpX > X1[I]) and (TmpX < X2[I]) and
               (Y1[I] + 15 < TmpY) and (Y1[I] + 15 + 10 > TmpY) then
            begin
              KeyF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (TmpX > X1[I]) and (TmpX < X2[I]) and
               (Y1[I] + 15 + 10 < TmpY) and (Y1[I] + 15 + 20 > TmpY) then
            begin
              MouseF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
            if (TmpX > X1[I]) and (TmpX < X2[I]) and
               (Y1[I] + 15 + 20 < TmpY) and (Y1[I] + 15 + 30 > TmpY) then
            begin
              MouseF := True;
              KeyF := True;
              Sel := I - 1;
              Choice := I - 1;
            end;
          end;
          if (TmpX > 71) and (TmpX < 249) and (TmpY > 171) and (TmpY < 197) then
            Choice := 10;
        end;
      until (OldSel <> Sel) or (Choice >= 0);
      HideMouseCursor;
      ErasePlusMark((X1[OldSel + 1] + X2[OldSel + 1]) div 2, Y2[OldSel + 1] - 4, SaveBuf);
    until Choice in [0..10];
    SetColor(14);
    SetFillStyle(1, 18);
    case Choice of
      0..9:
        begin
          if NameF and (Controls[Choice + 1] in [1, 2]) then
          begin
            EditPlayerName(Choice + 1);
            DrawSetupBoxName(Choice + 1);
          end;
          if NameF and (Controls[Choice + 1] = 3) then
          begin
            SelectAIType(Choice + 1);
            DrawSetupBoxName(Choice + 1);
          end;
          if KeyF and not MouseF then
          begin
            J := Controls[Choice + 1];
            Controls[Choice + 1] := 1;
            DrawSetupBoxControl(Choice + 1);
            if J = 3 then
            begin
              EditPlayerName(Choice + 1);
              DrawSetupBoxName(Choice + 1);
            end;
          end;
          if MouseF and not KeyF then
          begin
            J := Controls[Choice + 1];
            Controls[Choice + 1] := 2;
            DrawSetupBoxControl(Choice + 1);
            if J = 3 then
            begin
              EditPlayerName(Choice + 1);
              DrawSetupBoxName(Choice + 1);
            end;
          end;
          if MouseF and KeyF then
          begin
            J := Controls[Choice + 1];
            Controls[Choice + 1] := 3;
            DrawSetupBoxControl(Choice + 1);
            SelectAIType(Choice + 1);
            DrawSetupBoxName(Choice + 1);
          end;
        end;
      10:
        Done := True;
    end;
    Choice := -1;
  until Done;
  AllComputers := 1;
  FillChar(Tanks, 44, 0);
  for I := 1 to NumPlayers do
  begin
    if (Controls[I] = 3) and (Players[I].Name = 'Random') then
      Players[I].Name := AINames[Random(7) + 1];
    CreateAIPlayer(I);
    if Controls[I] <> 3 then
      AllComputers := 0;
  end;
  repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
  for TmpX := 0 to 319 do
    CopyLine(0, 199, TmpX, 0, SaveBuf);
  for TmpY := 0 to 199 do
    CopyLine(0, 199, 319, TmpY, SaveBuf);
end;

{ program setup: defaults, read BOMB.CFG, parse the command line
  (H = help screen, DEBUG = show the current parameters) }
{#U0728_62E4}
procedure LoadSettings;
var
  I: Integer;
  Unused03: Byte;                   { unused locals keep the frame layout }
  SR: SearchRec;
  F: File;
  UnusedAF: Byte;
  Sig: string[4];                   { BOMB.CFG signature }
begin
  ShowHelp := 0;
  SoundOn := 1;
  FlySound := 0;
  CrumblePct := 10;
  WallControl := 0;
  GameNo := 1;
  InvisoBall := 0;
  ShotTrail := 0;
  GamesToPlay := 10;
  TanksFall := 1;
  NumPlayers := 2;
  CompuBuy := 1;
  BackControl := 0;
  WindControl := 2;
  SaveName := 'QWERTYUI';
  SaveRequested := 0;
  LoadRequested := 0;
  AutoSave := 0;
  BeginnerGame := 0;
  AllComputers := 1;
  MouseIn := 0;
  ForceMouse := 0;
  DirectPorts := 1;
  ShowTitle := 1;
  ShotSpeed := 0;
  PaletteOn := 1;
  CrudeVideo := 0;
  TeamPlay := 0;
  PalUseRetrace := 1;
  FallSpeed := 0;
  TurretSpeed := 0;
  ExplodeSpeed := 0;
  PalSpeed := 0;
  FindFirst('BOMB.CFG', AnyFile, SR);
  if DosError = 0 then
  begin
    Assign(F, 'BOMB.CFG');
    Reset(F, 1);
    Sig := 'BADx';
    BlockRead(F, Sig, 5);
    if Sig <> GameVersion then
    begin
      TextMode(3);
      Writeln('An invalid BOMB.CFG has been found.');
      Writeln('Please run BOMBCFG to correct the situation.');
      Halt(1);
    end;
    BlockRead(F, SoundOn, 1);
    BlockRead(F, FlySound, 1);
    BlockRead(F, WindControl, 2);
    BlockRead(F, CrumblePct, 2);
    BlockRead(F, WallControl, 2);
    BlockRead(F, InvisoBall, 1);
    BlockRead(F, ShotTrail, 1);
    BlockRead(F, GamesToPlay, 2);
    BlockRead(F, TanksFall, 1);
    BlockRead(F, BackControl, 2);
    BlockRead(F, BackMask, 2);
    BlockRead(F, ForceMouse, 1);
    BlockRead(F, MouseIn, 1);
    BlockRead(F, DirectPorts, 1);
    BlockRead(F, PaletteOn, 1);
    BlockRead(F, CrudeVideo, 1);
    BlockRead(F, PalSpeed, 2);
    BlockRead(F, CompuBuy, 1);
    BlockRead(F, TurretSpeed, 2);
    BlockRead(F, FallSpeed, 2);
    BlockRead(F, ExplodeSpeed, 2);
    BlockRead(F, ShotSpeed, 2);
    BlockRead(F, PalUseRetrace, 1);
    BlockRead(F, TeamPlay, 1);
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
      TmpStr := UpperStr(ParamStr(I));
      if TmpStr[1] in ['/', '\'] then
        Delete(TmpStr, 1, 1);
      if TmpStr = 'H' then ShowHelp := 1;
      if TmpStr = 'S-' then SoundOn := 0;
      if TmpStr = 'S+' then SoundOn := 1;
      if TmpStr = 'F+' then FlySound := 1;
      if TmpStr = 'F-' then FlySound := 0;
      if TmpStr[1] = 'G' then
        Val(Copy(TmpStr, 2, 3), GamesToPlay, LoopJ);
      if (Copy(TmpStr, 1, 2) = 'BK') and (TmpStr[3] >= 'A') and (TmpStr[3] < 'I') then
        BackControl := Ord(TmpStr[3]) - 64;
      if (TmpStr = 'BK-') or (TmpStr = 'BKN') then BackControl := 0;
      if (TmpStr = 'BK+') or (TmpStr = 'BKR') then BackControl := 9;
      if TmpStr = 'BKU' then BackControl := 10;
      if TmpStr[1] = 'W' then
        Val(Copy(TmpStr, 2, 1), WindControl, LoopJ);
      WindControl := WindControl mod 6;
      if TmpStr[1] = 'R' then
        Val(Copy(TmpStr, 2, 1), WallControl, LoopJ);
      WallControl := WallControl mod 6;
      if TmpStr = 'R+' then WallControl := 2;
      if TmpStr = 'RR' then WallControl := 5;
      if TmpStr = 'R-' then WallControl := 0;
      if TmpStr[1] = 'C' then
        Val(Copy(TmpStr, 2, 3), CrumblePct, LoopJ);
      if TmpStr = 'C+' then CrumblePct := 100;
      if TmpStr = 'C-' then CrumblePct := 0;
      if TmpStr = 'I+' then InvisoBall := 1;
      if TmpStr = 'I-' then InvisoBall := 0;
      if TmpStr = 'T+' then ShotTrail := 1;
      if TmpStr = 'T-' then ShotTrail := 0;
      if TmpStr = 'D-' then TanksFall := 0;
      if TmpStr = 'D+' then TanksFall := 1;
      if Copy(TmpStr, 0, 4) = 'TEAM' then TeamPlay := 1;
      if TmpStr = 'B-' then CompuBuy := 0;
      if TmpStr = 'B+' then CompuBuy := 1;
      if Copy(TmpStr, 1, 2) = 'TS' then
        Val(Copy(TmpStr, 3, 3), TurretSpeed, LoopJ);
      if Copy(TmpStr, 1, 2) = 'FS' then
        Val(Copy(TmpStr, 3, 3), FallSpeed, LoopJ);
      if Copy(TmpStr, 1, 2) = 'ES' then
        Val(Copy(TmpStr, 3, 3), ExplodeSpeed, LoopJ);
      if Copy(TmpStr, 1, 2) = 'SS' then
        Val(Copy(TmpStr, 3, 3), ShotSpeed, LoopJ);
      if TmpStr = 'M-' then
      begin
        MouseIn := 0;
        ForceMouse := 1;
      end;
      if TmpStr = 'M+' then
      begin
        MouseIn := 1;
        ForceMouse := 1;
      end;
      if TmpStr = 'H-' then DirectPorts := 0;
      if TmpStr = 'H+' then DirectPorts := 1;
      if TmpStr = 'DV+' then DirectPorts := 1;
      if TmpStr = 'DV-' then DirectPorts := 0;
      if TmpStr = 'CV+' then CrudeVideo := 1;
      if TmpStr = 'CV-' then CrudeVideo := 0;
      if TmpStr = 'CRUDE' then CrudeVideo := 1;
      if TmpStr = 'NOCRUDE' then CrudeVideo := 0;
      if TmpStr = 'P-' then PaletteOn := 0;
      if TmpStr = 'P+' then PaletteOn := 1;
      if TmpStr = 'PV' then
      begin
        PaletteOn := 1;
        PalUseRetrace := 1;
      end;
      if TmpStr = 'PT' then
      begin
        PaletteOn := 1;
        PalUseRetrace := 0;
      end;
      if TmpStr = 'SKIP' then ShowTitle := 0;
      if TmpStr = 'NEW' then BeginnerGame := 1;
      if TmpStr = 'DEBUG' then DebugMode := 1;
    end;
  if ShowHelp <> 0 then
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
  SelectDacRoutines(CpuKind, DirectPorts, CrudeVideo);
  if DebugMode <> 0 then
  begin
    ClrScr;
    TextColor(10);
    Writeln('  Current Parameters:');
    TextColor(13); Write('Effsound............................:');
    TextColor(14); Writeln(Boolean(SoundOn));
    TextColor(13); Write('Flysound............................:');
    TextColor(14); Writeln(Boolean(FlySound));
    TextColor(13); Write('WindControl.........................:');
    TextColor(14); Writeln(WindControl);
    TextColor(13); Write('Crumbper............................:');
    TextColor(14); Writeln(CrumblePct);
    TextColor(13); Write('Wallcontrol.........................:');
    TextColor(14); Writeln(WallControl);
    TextColor(13); Write('Inviso..............................:');
    TextColor(14); Writeln(Boolean(InvisoBall));
    TextColor(13); Write('Trail...............................:');
    TextColor(14); Writeln(Boolean(ShotTrail));
    TextColor(13); Write('GamesToPlay.........................:');
    TextColor(14); Writeln(GamesToPlay);
    TextColor(13); Write('FallDown............................:');
    TextColor(14); Writeln(Boolean(TanksFall));
    TextColor(13); Write('BackControl.........................:');
    TextColor(14); Writeln(BackControl);
    TextColor(13); Write('ForceMouse..........................:');
    TextColor(14); Writeln(Boolean(ForceMouse));
    TextColor(13); Write('Mousein.............................:');
    TextColor(14); Writeln(Boolean(MouseIn));
    TextColor(13); Write('Fastpal.............................:');
    TextColor(14); Writeln(Boolean(DirectPorts));
    TextColor(13); Write('CrudeCycle..........................:');
    TextColor(14); Writeln(Boolean(CrudeVideo));
    TextColor(13); Write('Palette.............................:');
    TextColor(14); Writeln(Boolean(PaletteOn));
    TextColor(13); Write('Pspeed..............................:');
    TextColor(14); Writeln(PalSpeed);
    TextColor(13); Write('CompuBuy............................:');
    TextColor(14); Writeln(Boolean(CompuBuy));
    WaitKeyOrMouse;
    ClrScr;
    TextColor(10);
    Writeln('  Current Parameters:');
    TextColor(13); Write('TurretSpeed.........................:');
    TextColor(14); Writeln(TurretSpeed);
    TextColor(13); Write('FallSpeed...........................:');
    TextColor(14); Writeln(FallSpeed);
    TextColor(13); Write('ExplodeSpeed........................:');
    TextColor(14); Writeln(ExplodeSpeed);
    TextColor(13); Write('ShotSpeed...........................:');
    TextColor(14); Writeln(ShotSpeed);
    TextColor(13); Write('CPU.................................:');
    TextColor(14); Writeln(CpuKind);
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
    TextColor(14); Writeln(Boolean(PalUseRetrace));
    TextColor(13); Write('Team Play...........................:');
    TextColor(14); Writeln(Boolean(TeamPlay));
    WaitKeyOrMouse;
  end;
end;
