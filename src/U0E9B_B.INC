{ load a saved game FileName.TWS (counterpart of SaveGame) }
{#U0E9B_3E7A}
procedure LoadGame(FileName: string);
var
  F: File;
  I: Integer;
  Unused: array[0..5] of Byte;
  Buf: string;
  Hdr: string;
  Kind: Integer;
begin
  Assign(F, FileName + '.TWS');
  Reset(F, 1);
  Hdr := '';
  Hdr := Hdr + 'Tank Wars Saved Game' + #13 + #10;
  Hdr := Hdr + 'V' + GameVersion + #13 + #10;
  Hdr := Hdr + #26;
  Buf := Hdr;
  BlockRead(F, Buf[1], Length(Hdr));
  if Buf <> Hdr then
  begin
    DrawPanel3D(100, 90, 220, 113, 18, 15, 17);
    SetTextJustify(1, 1);
    SetColor(14);
    OutTextXY(160, 95, 'Save File is not valid!');
    SetColor(4);
    OutTextXY(160, 105, 'Press Any Key...');
    repeat until KeyPressed or MouseBtnsDown(1) or MouseBtnsDown(2);
    Halt;
  end;
  BlockRead(F, BlastSize, 2);
  BlockRead(F, NumPlayers, 2);
  BlockRead(F, GameNo, 2);
  BlockRead(F, RoundWind, 2);
  BlockRead(F, GuideTarget, 2);
  BlockRead(F, SavedUnused46C2, 2);
  BlockRead(F, TurnLap, 2);
  BlockRead(F, RoundWall, 2);
  BlockRead(F, CurPlayer, 1);
  BlockRead(F, AllComputers, 1);
  BlockRead(F, WallsBounce, 1);
  BlockRead(F, WallsWrap, 1);
  BlockRead(F, WindForce, 2);
  BlockRead(F, CrumblePct, 2);
  BlockRead(F, GamesToPlay, 2);
  BlockRead(F, WindControl, 2);
  BlockRead(F, WallControl, 2);
  BlockRead(F, BackControl, 2);
  BlockRead(F, BackMask, 2);
  BlockRead(F, FlySound, 1);
  BlockRead(F, SoundOn, 1);
  BlockRead(F, InvisoBall, 1);
  BlockRead(F, ShotTrail, 1);
  BlockRead(F, TanksFall, 1);
  BlockRead(F, CompuBuy, 1);
  BlockRead(F, TeamPlay, 1);
  FillChar(Tanks, 44, 0);
  for I := 1 to NumPlayers do
  begin
    BlockRead(F, Players[I], SizeOf(TPlayer));
    BlockRead(F, Controls[I], 2);
    if Controls[I] = 3 then
    begin
      { computer player: recreate its AI object }
      BlockRead(F, Kind, 2);
      case Kind of
        1: Tanks[I] := New(PStupid, Init(I));
        2: Tanks[I] := New(PLobber, Init(I));
        3: Tanks[I] := New(PRifleman, Init(I));
        4: Tanks[I] := New(PLobShoot, Init(I));
        5: Tanks[I] := New(PWindless, Init(I));
        6: Tanks[I] := New(PTwanger, Init(I));
        7: Tanks[I] := New(PWindMaster, Init(I));
      end;
      PComputer(Tanks[I])^.Load(F);
    end;
  end;
  BlockRead(F, Teams, SizeOf(Teams));
  Close(F);
end;

{ "Save game" dialog: Save / Autosave toggle / Save & Quit / New Name / Cancel }
{#U0E9B_455E}
procedure SaveGameDialog;
var
  Choice: Integer;
  i: Integer;
  Unused6, Unused8: Integer;
  MX, MY: Integer;
  UnusedD: Byte;
  SR: SearchRec;
  Unused39: Boolean;
  Unused139: string;
  Unused13A: Byte;
begin
  DrawPanel3D(100, 65, 220, 95, 18, 15, 17);
  SetTextStyle(2, 0, 0);
  SetUserCharSize(1, 1, 1, 1);
  i := 0;
  { no name yet: pick the first free GAMEn }
  if SaveName = 'QWERTYUI' then
    repeat
      Inc(i);
      SaveName := 'GAME' + IntToStr(i);
      FindFirst(SaveName + '.TWS', 0, SR);
    until DosError <> 0;
  SetTextJustify(1, 1);
  SetColor(4);
  OutTextXY(160, 69, 'SAVE GAME');
  SetColor(9);
  SetTextJustify(0, 1);
  OutTextXY(105, 81, 'File Name:');
  SetColor(14);
  OutTextXY(165, 81, SaveName);
  SetTextJustify(1, 1);
  DrawPanel3D(135, 100, 185, 110, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 104, 'Save');
  SetColor(14);
  OutTextXY(160, 104, 'S   ');
  DrawPanel3D(190, 100, 260, 110, 18, 15, 17);
  DrawPanel3D(190, 100, 260, 110, 18, 15, 17);
  SetTextJustify(0, 1);
  SetColor(6);
  OutTextXY(192, 104, 'Autosave:' + OnOffStr(Boolean(AutoSave)));
  SetColor(14);
  OutTextXY(192, 104, 'A');
  SetTextJustify(1, 1);
  DrawPanel3D(60, 100, 130, 110, 18, 15, 17);
  SetColor(6);
  OutTextXY(95, 104, 'Save & Quit');
  SetColor(14);
  OutTextXY(96, 104, '       Q   ');
  DrawPanel3D(135, 115, 185, 125, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 119, 'New Name');
  SetColor(14);
  OutTextXY(160, 119, 'N       ');
  DrawPanel3D(135, 130, 185, 140, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 134, 'Cancel');
  SetColor(14);
  OutTextXY(161, 134, 'C     ');
  repeat
    Choice := 0;
    ShowMouseCursor;
    repeat
      if KeyPressed then
      begin
        KeyChar := UpCase(ReadKey);
        if KeyChar = 'Q' then Choice := 5;
        if KeyChar = 'A' then Choice := 4;
        if KeyChar = 'C' then Choice := 3;
        if KeyChar = 'N' then Choice := 2;
        if KeyChar = 'S' then Choice := 1;
      end;
      MX := MouseX;
      MY := MouseY;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
      begin
        if (MX > 135) and (MX < 185) then
        begin
          if (MY > 100) and (MY < 110) then Choice := 1;
          if (MY > 115) and (MY < 125) then Choice := 2;
          if (MY > 130) and (MY < 140) then Choice := 3;
        end;
        if (MY < 110) and (MY > 100) then
        begin
          if (MX > 190) and (MX < 260) then Choice := 4;
          if (MX > 60) and (MX < 130) then Choice := 5;
        end;
        repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
      end;
    until Choice <> 0;
    HideMouseCursor;
    if Choice = 2 then
    begin
      EditSaveName;
      FillBar(164, 76, 218, 86, 18);
      SetColor(14);
      OutTextXY(165, 81, SaveName);
    end;
    if Choice = 4 then
    begin
      Boolean(AutoSave) := not Boolean(AutoSave);
      DrawPanel3D(190, 100, 260, 110, 18, 15, 17);
      SetTextJustify(0, 1);
      SetColor(6);
      OutTextXY(192, 104, 'Autosave:' + OnOffStr(Boolean(AutoSave)));
      SetColor(14);
      OutTextXY(192, 104, 'A');
    end;
  until Choice in [1, 3, 5];
  if Choice = 1 then SaveGame(SaveName);
  if Choice = 5 then
  begin
    SaveGame(SaveName);
    TextMode(3);
    Halt;
  end;
  { wipe the screen from the back buffer, two columns at a time }
  for i := 0 to 319 do
  begin
    CopyLine(i, 0, i, 199, SaveBuf);
    Inc(i);
  end;
  for i := 319 downto 0 do
  begin
    CopyLine(i, 0, i, 199, SaveBuf);
    Dec(i);
  end;
  SaveRequested := 0;
end;

{ "Load game" dialog: lists *.TWS, lets the player pick one, loads it }
{#U0E9B_4B93}
procedure LoadGameDialog;
var
  Unused2: Integer;
  i: Integer;
  Unused6, Unused8: Integer;
  MX, MY: Integer;
  UnusedD: Byte;
  SR: SearchRec;
  Done: Boolean;
  Unused3E: array[0..4] of Byte;
  Names: array[0..123] of string[10];
  Count: Integer;
  Sel: Integer;
begin
  SetTextStyle(2, 0, 0);
  SetUserCharSize(1, 1, 1, 1);
  i := 0;
  Count := 0;
  FindFirst('*.TWS', 0, SR);
  if DosError = 0 then
  begin
    Inc(Count);
    Names[Count] := Copy(SR.Name, 1, Pos('.', SR.Name) - 1);
    FindNext(SR);
    if DosError = 0 then
      repeat
        Inc(Count);
        Names[Count] := Copy(SR.Name, 1, Pos('.', SR.Name) - 1);
        FindNext(SR);
      until DosError <> 0;
  end;
  { bubble sort, Names[0] is the swap slot }
  repeat
    Done := True;
    i := 1;
    while i < Count do
    begin
      if Names[i] > Names[i + 1] then
      begin
        Done := False;
        Names[0] := Names[i];
        Names[i] := Names[i + 1];
        Names[i + 1] := Names[0];
      end;
      Inc(i);
    end;
  until Done;
  if Count = 0 then
  begin
    DrawPanel3D(100, 90, 220, 113, 18, 15, 17);
    SetTextJustify(1, 1);
    SetColor(14);
    OutTextXY(160, 95, 'No Save Files Found');
    SetColor(4);
    OutTextXY(160, 105, 'Press Any Key...');
    repeat until KeyPressed or MouseBtnsDown(1) or MouseBtnsDown(2);
    Halt;
  end;
  Sel := 1;
  SetTextJustify(1, 1);
  DrawPanel3D(100, 89, 220, 111, 18, 15, 17);
  SetColor(14);
  OutTextXY(160, 95, 'Select Game to Load:');
  SetColor(0);
  OutTextXY(160, 105, Names[Sel]);
  SetColor(9);
  SetTextJustify(1, 1);
  OutTextXY(107, 105, '<-');
  OutTextXY(213, 105, '->');
  DrawPanel3D(145, 116, 175, 126, 18, 15, 17);
  SetTextJustify(1, 1);
  OutTextXY(160, 120, 'OK');
  Done := False;
  SetColor(0);
  ShowMouseCursor;
  DisableBiosKeys;
  repeat
    if (KeyDown[$4D] <> 0) or (KeyDown[$14D] <> 0) then
    begin
      Inc(Sel);
      if Sel > Count then Sel := 1;
      FillBar(120, 100, 210, 111, 18);
      OutTextXY(160, 105, Names[Sel]);
      repeat until KeyDown[$4D] = 0;
      repeat until KeyDown[$14D] = 0;
    end;
    if (KeyDown[$4B] <> 0) or (KeyDown[$14B] <> 0) then
    begin
      Dec(Sel);
      if Sel = 0 then Sel := Count;
      FillBar(120, 100, 200, 111, 18);
      OutTextXY(160, 105, Names[Sel]);
      repeat until KeyDown[$4B] = 0;
      repeat until KeyDown[$14B] = 0;
    end;
    if (KeyDown[$1C] <> 0) or (KeyDown[$11C] <> 0) or (KeyDown[$39] <> 0) then
      Done := True;
    if MouseBtnsDown(1) or MouseBtnsDown(2) then
    begin
      MX := MouseX;
      MY := MouseY;
      HideMouseCursor;
      if (MX > 120) and (MX < 200) and (MY > 100) and (MY < 111) then
      begin
        if MouseBtnsDown(1) then Dec(Sel);
        if MouseBtnsDown(2) then Inc(Sel);
        if Sel > Count then Sel := 1;
        if Sel = 0 then Sel := Count;
        FillBar(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
      end;
      if (MX > 100) and (MX < 115) and (MY < 111) and (MY > 101) then
      begin
        Dec(Sel);
        if Sel = 0 then Sel := Count;
        FillBar(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
      end;
      if (MX < 220) and (MX > 205) and (MY < 111) and (MY > 101) then
      begin
        Inc(Sel);
        if Sel > Count then Sel := 1;
        FillBar(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
      end;
      if (MX > 145) and (MX < 175) and (MY > 116) and (MY < 126) then
        Done := True;
      ShowMouseCursor;
    end;
  until Done;
  HideMouseCursor;
  EnableBiosKeys;
  SaveName := Names[Sel];
  LoadGame(SaveName);
end;

{ "# TO ADD:" box: edit a number (max. 3 digits) and add it to GamesToPlay
  (number of games to play) }
procedure AddGamesDialog;
var
  P: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;
  S: string;

  { draw the block cursor under character Pos (and clear the line below) }
  {#U0E9B_51F2} procedure DrawAddCursor;
  begin
    DrawRect((Pos - 1) * 6 + 138 - 1, 100, (Pos - 1) * 6 + 138 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 138, 101, (Pos - 1) * 6 + 138 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 138 + 1, 102, (Pos - 1) * 6 + 138 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 138, 104, Copy(S, Pos, 1));
    CopyBar((Pos - 1) * 6 + 138 - 1, 109, (Pos - 1) * 6 + 138 + 4, 110, SaveBuf);
  end;

  { erase the cursor at Pos, redraw the character }
  {#U0E9B_5336} procedure EraseAddCursor;
  begin
    DrawRect((Pos - 1) * 6 + 138 - 1, 100, (Pos - 1) * 6 + 138 + 4, 110, 18);
    DrawRect((Pos - 1) * 6 + 138, 101, (Pos - 1) * 6 + 138 + 3, 109, 18);
    DrawRect((Pos - 1) * 6 + 138 + 1, 102, (Pos - 1) * 6 + 138 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 138, 104, Copy(S, Pos, 1));
  end;

{#U0E9B_54C6}
begin
  S := '';
  GetMem(P, 653);
  if Length(S) < 3 then
    for I := Length(S) + 1 to 3 do S[I] := ' ';
  GetImage(128, 83, 192, 117, P^);
  DrawPanel3D(130, 85, 190, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetColor(5);
  OutTextXY(133, 85, '# TO ADD:');
  DrawPanel3D(135, 100, 185, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(S) do
    OutTextXY((Pos - 1) * 6 + 138, 104, Copy(S, Pos, 1));
  Inc(S[0]);
  Pos := Length(S);
  Done := False;
  repeat
    DrawAddCursor;
    Changed := False;
    repeat
      repeat until KeyPressed;
      KeyChar := ReadKey;
      if (KeyChar in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        S[NewPos] := ' ';
        S[NewPos + 1] := ' ';
        Changed := True;
      end;
      if KeyChar in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if KeyChar in ['0'..'9'] then
      begin
        S[Pos] := UpCase(KeyChar);
        Changed := True;
        NewPos := Pos + 1;
        if Length(S) < NewPos then Inc(S[0]);
      end;
      if KeyChar = #0 then
      begin
        KeyChar := ReadKey;
        if KeyChar = #$47 then                   { Home: clear }
        begin
          for Pos := Length(S) downto 1 do
          begin
            S[Pos] := ' ';
            DrawAddCursor;
            EraseAddCursor;
          end;
          S := '  ';
          NewPos := 1;
        end;
        if KeyChar = #$53 then                   { Del }
        begin
          S[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if KeyChar = #$4F then                   { End }
        begin
          Changed := True;
          NewPos := Length(S);
        end;
        if (KeyChar = ScanLeft) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (KeyChar = ScanRight) and (Length(S) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 3 then NewPos := 3;
    if Length(S) > 3 then S[0] := #3;
    EraseAddCursor;
    Pos := NewPos;
  until Done;
  while (S[Length(S)] in [#0, ' ']) and (Length(S) > 0) do Dec(S[0]);
  Val(S, I, LoopJ);
  GamesToPlay := GamesToPlay + I;
  PutImage(128, 83, P^, 0);
  FreeMem(P, 653);
end;

{ end-of-round standings (individual players): sorted by wins, then score;
  buttons Add (more games) / Continue|Exit / Save; digit or click = player info }
{#U0E9B_5893}
procedure ShowStandings;
var
  Unused2: Integer;
  H: Integer;
  Bottom, Top: Integer;
  I, J: Integer;
  UnusedE: Integer;
  S: string;
  SaveFlag: Byte;
  Unused110: Byte;
  KbdHead: Word absolute $0040:$001A;   { BIOS keyboard buffer head/tail }
  KbdTail: Word absolute $0040:$001C;
  Screen: TScreen absolute $A000:0;
begin
  SaveFlag := AllComputers;
  if GameNo = GamesToPlay then AllComputers := 0;
  H := NumPlayers * 5 + 15;
  Top := 100 - H;
  Bottom := H + 100;
  I := 0;
  InitPanelGreys;
  KbdHead := KbdTail;                           { flush the BIOS key buffer }
  TScreen(SaveBuf^) := Screen;
  for I := 1 to NumPlayers do
    for J := 1 to NumPlayers - 1 do
      if Players[J].Wins < Players[J + 1].Wins then SwapPlayers(J, J + 1);
  for I := 1 to NumPlayers do
    for J := 1 to NumPlayers - 1 do
      if (Players[J].Wins = Players[J + 1].Wins) and
         (Players[J].Score < Players[J + 1].Score) then SwapPlayers(J, J + 1);
  VideoSeg := $A000;
  DrawMenuBackground(1);
  TScreen(SaveBuf^) := Screen;
  DrawPanel3D(45, Top, 275, Bottom, 18, 15, 17);
  DrawPanel3D(65, Top - 20, 255, Top - 5, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(6);
  SetTextJustify(1, 1);
  if GameNo > 1 then S := ' Games ' else S := ' Game ';
  OutTextXY(160, Top - 13, IntToStr(GameNo) + S + 'Played out of ' + IntToStr(GamesToPlay));
  for I := 1 to NumPlayers do SetPlayerMen(100, Players[I]);
  SetColor(17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(0, 2);
  DrawLine(50, Top + 16, 270, Top + 16, 17);
  OutTextXY(50, Top + 5, 'Player');
  J := 1;
  for I := 1 to NumPlayers do
  begin
    SetColor(I + 19);
    S := IntToStr(J) + '.';
    if J < 10 then S := ' ' + S;
    OutTextXY(50, Top + 10 + 10 * I, S);
    OutTextXY(72, Top + 10 + 10 * I, Players[I].Name);
    if (I <> 10) and ((Players[I].Score <> Players[I + 1].Score) or
       (Players[I].Wins <> Players[I + 1].Wins)) then Inc(J);
  end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(270, Top + 5, 'Score');
  for I := 1 to NumPlayers do
  begin
    SetColor(I + 19);
    OutTextXY(270, Top + 10 + 10 * I, IntToStr(Players[I].Score));
  end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(185, Top + 5, 'Wins');
  for I := 1 to NumPlayers do
  begin
    SetColor(I + 19);
    OutTextXY(185, Top + 10 + 10 * I, IntToStr(Players[I].Wins));
  end;
  FetchClipWindow;
  if AllComputers = 0 then
  begin
    SetTextJustify(1, 1);
    DrawPanel3D(60, Bottom + 5, 110, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(85, Bottom + 9, 'Add');
    DrawPanel3D(210, Bottom + 5, 260, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(235, Bottom + 9, 'Save');
    DrawPanel3D(135, Bottom + 5, 185, Bottom + 15, 18, 15, 17);
    SetColor(0);
    if GameNo <> GamesToPlay then OutTextXY(160, Bottom + 9, 'Continue')
    else OutTextXY(160, Bottom + 9, 'Exit');
    ShowMouseCursor;
    DoneFlag := 0;
    repeat
      if KeyPressed then
      begin
        KeyChar := ReadKey;
        if (KeyChar >= '0') and (KeyChar <= '9') then
        begin
          Val(KeyChar, I, J);
          if I = 0 then I := 10;
          if I <= NumPlayers then ShowPlayerStats(I);
        end
        else if KeyChar in ['S', 's'] then
        begin
          SaveRequested := 1;
          DoneFlag := 1;
        end
        else if KeyChar in ['A', 'a'] then
        begin
          HideMouseCursor;
          AddGamesDialog;
          SetTextStyle(2, 0, 1);
          SetUserCharSize(1, 1, 1, 1);
          SetColor(6);
          SetTextJustify(1, 1);
          if GameNo > 1 then S := ' Games ' else S := ' Game ';
          FillBar(76, Top - 17, 244, Top - 5, 18);
          OutTextXY(160, Top - 13, IntToStr(GameNo) + S + 'Played out of ' + IntToStr(GamesToPlay));
          AllComputers := SaveFlag;
          ShowMouseCursor;
        end
        else
          DoneFlag := 1;
      end;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
      begin
        TmpX := MouseX;
        TmpY := MouseY;
        if (TmpX > 45) and (TmpX < 275) then
          for I := 1 to NumPlayers do
            if (Top + 12 + 10 * I <= TmpY) and (Top + 12 + 10 * I + 10 > TmpY) then
            begin
              repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
              ShowPlayerStats(I);
              repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
              TmpX := 0;
              TmpY := 0;
            end;
        if (TmpX >= 135) and (Bottom + 5 <= TmpY) and (TmpX <= 185) and (Bottom + 15 >= TmpY) then
          DoneFlag := 1;
        if (TmpX >= 60) and (Bottom + 5 <= TmpY) and (TmpX <= 110) and (Bottom + 15 >= TmpY) then
        begin
          HideMouseCursor;
          AddGamesDialog;
          SetTextStyle(2, 0, 1);
          SetUserCharSize(1, 1, 1, 1);
          SetColor(6);
          SetTextJustify(1, 1);
          if GameNo > 1 then S := ' Games ' else S := ' Game ';
          FillBar(76, Top - 17, 244, Top - 5, 18);
          OutTextXY(160, Top - 13, IntToStr(GameNo) + S + 'Played out of ' + IntToStr(GamesToPlay));
          AllComputers := SaveFlag;
          ShowMouseCursor;
        end;
        if (TmpX >= 210) and (Bottom + 5 <= TmpY) and (TmpX <= 260) and (Bottom + 15 >= TmpY) then
        begin
          SaveRequested := 1;
          DoneFlag := 1;
        end;
      end;
    until DoneFlag <> 0;
    HideMouseCursor;
    FetchClipWindow;
  end
  else
    Delay(2000);
  { wipe back to the saved screen }
  for I := 0 to 319 do
  begin
    CopyLine(0, 199, I, 0, SaveBuf);
    CopyLine(319, 0, 319 - I, 199, SaveBuf);
  end;
  KbdHead := KbdTail;
end;

{ end-of-round standings for team play: sums the members' statistics into
  Teams[], sorts by member count, average wins, score; buttons
  Continue|Exit / Save; digit or click = team info }
{#U0E9B_63ED}
procedure ShowTeamStandings;
var
  P: Integer;
  T: Integer;
  H: Integer;
  Bottom, Top: Integer;
  I, J: Integer;
  Unused10: Integer;
  S: string;
  Order: array[0..10] of Integer;
  NumTeams: Integer;
  KbdHead: Word absolute $0040:$001A;
  KbdTail: Word absolute $0040:$001C;
begin
  H := 15;
  NumTeams := 0;
  for I := 1 to NumPlayers do
    if Teams[I].f0F > 0 then
    begin
      H := H + 5;
      Inc(NumTeams);
    end;
  Top := 100 - H;
  Bottom := H + 100;
  I := 0;
  InitPanelGreys;
  KbdHead := KbdTail;
  for T := 1 to 10 do
  begin
    Teams[T].f11 := 0;
    Teams[T].f17 := 0;
    Teams[T].f1D := 0;
    Teams[T].f23 := 0;
    Teams[T].f29 := 0;
    Teams[T].f2F := 0;
    for P := 1 to NumPlayers do
      if Players[P].Team = T then
      begin
        Teams[T].f11 := Teams[T].f11 + Players[P].Score;
        Teams[T].f17 := Teams[T].f17 + Players[P].f68;
        Teams[T].f1D := Teams[T].f1D + Players[P].Wins;
        Teams[T].f23 := Teams[T].f23 + Players[P].f6C;
        Teams[T].f29 := Teams[T].f29 + Players[P].f6E;
        Teams[T].f2F := Teams[T].f2F + Players[P].f70;
      end;
    Order[T] := T;
    if Teams[T].f0F > 0 then
    begin
      Teams[T].f17 := Teams[T].f17 / Teams[T].f0F;
      Teams[T].f1D := Teams[T].f1D / Teams[T].f0F;
    end;
  end;
  { Order[0] is the swap slot }
  for I := 1 to 10 do
    for J := 1 to 9 do
      if Teams[Order[J]].f0F < Teams[Order[J + 1]].f0F then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  for I := 1 to 10 do
    for J := 1 to 9 do
      if Teams[Order[J]].f1D < Teams[Order[J + 1]].f1D then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  { (original bug: compares Teams[J] instead of Teams[Order[J]]) }
  for I := 1 to 10 do
    for J := 1 to 9 do
      if (Teams[J].f1D = Teams[J + 1].f1D) and
         (Teams[J].f11 < Teams[J + 1].f11) then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  VideoSeg := $A000;
  DrawPanel3D(45, Top, 275, Bottom, 18, 15, 17);
  DrawPanel3D(69, Top - 20, 251, Top - 5, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(6);
  SetTextJustify(1, 1);
  if GameNo > 1 then S := ' Games ' else S := ' Game ';
  OutTextXY(160, Top - 13, IntToStr(GameNo) + S + 'Played out of ' + IntToStr(GamesToPlay));
  for I := 1 to NumPlayers do SetPlayerMen(100, Players[I]);
  SetColor(17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(0, 2);
  DrawLine(50, Top + 16, 270, Top + 16, 17);
  OutTextXY(50, Top + 5, 'Team');
  J := 1;
  for I := 1 to NumPlayers do
    if Teams[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      S := IntToStr(J) + '.';
      if J < 10 then S := ' ' + S;
      OutTextXY(50, Top + 10 + 10 * I, S);
      OutTextXY(72, Top + 10 + 10 * I, Teams[Order[I]].Name);
      if (I <> 10) and ((Teams[Order[I]].f11 <> Teams[Order[I + 1]].f11) or
         (Teams[Order[I]].f1D <> Teams[Order[I + 1]].f1D)) then Inc(J);
    end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(270, Top + 5, 'Score');
  for I := 1 to NumPlayers do
    if Teams[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      Str(Teams[Order[I]].f11:10:0, S);
      OutTextXY(270, Top + 10 + 10 * I, S);
    end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(185, Top + 5, 'Wins');
  for I := 1 to NumPlayers do
    if Teams[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      Str(Teams[Order[I]].f1D:5:2, S);
      OutTextXY(185, Top + 10 + 10 * I, S);
    end;
  FetchClipWindow;
  if AllComputers = 0 then
  begin
    SetTextJustify(1, 1);
    DrawPanel3D(85, Bottom + 5, 135, Bottom + 15, 18, 15, 17);
    SetColor(0);
    if GameNo <> GamesToPlay then OutTextXY(110, Bottom + 9, 'Continue')
    else OutTextXY(110, Bottom + 9, 'Exit');
    DrawPanel3D(185, Bottom + 5, 235, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(210, Bottom + 9, 'Save');
    ShowMouseCursor;
    DoneFlag := 0;
    repeat
      if KeyPressed then
      begin
        KeyChar := ReadKey;
        if (KeyChar >= '0') and (KeyChar <= '9') then
        begin
          Val(KeyChar, I, J);
          if I = 0 then I := 10;
          if I <= NumPlayers then ShowTeamStats(Order[I]);
        end
        else if KeyChar in ['S', 's'] then
        begin
          SaveRequested := 1;
          DoneFlag := 1;
        end
        else
          DoneFlag := 1;
      end;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
      begin
        TmpX := MouseX;
        TmpY := MouseY;
        if (TmpX > 45) and (TmpX < 275) then
          for I := 1 to NumTeams do
            if (Top + 12 + 10 * I <= TmpY) and (Top + 12 + 10 * I + 10 > TmpY) then
            begin
              repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
              ShowTeamStats(Order[I]);
              repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
              TmpX := 0;
              TmpY := 0;
            end;
        if (TmpX >= 85) and (Bottom + 5 <= TmpY) and (TmpX <= 135) and (Bottom + 15 >= TmpY) then
          DoneFlag := 1;
        if (TmpX >= 185) and (Bottom + 5 <= TmpY) and (TmpX <= 235) and (Bottom + 15 >= TmpY) then
        begin
          SaveRequested := 1;
          DoneFlag := 1;
        end;
      end;
    until DoneFlag <> 0;
    HideMouseCursor;
    FetchClipWindow;
  end
  else
    Delay(5000);
  { zoom back to the saved screen }
  for I := 150 downto 0 do
  begin
    CopyEllipse(160, 100, I, I, SaveBuf);
    CopyEllipse(161, 100, I, I, SaveBuf);
  end;
  KbdHead := KbdTail;
end;

{ final results in text mode (called by the main program after the games) }
{#U0E9B_7242}
procedure PrintFinalResults;
var
  Unused2, Unused4, Unused6, Unused8: Integer;
  I, J: Integer;
  UnusedE: Integer;
  S: string;
  KbdHead: Word absolute $0040:$001A;
  KbdTail: Word absolute $0040:$001C;
begin
  TextColor(15);
  TextBackground(0);
  ClrScr;
  I := 0;
  KbdHead := KbdTail;
  TextColor(6);
  if GameNo > 2 then S := ' Games ' else S := ' Game ';
  Writeln(IntToStr(GameNo - 1) + S + 'Played');
  Writeln('   And just in case you missed them:');
  Writeln('');
  TextColor(15);
  Writeln('             Results ');
  Writeln('   Name            Score   Wins');
  Writeln(' '#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196 +
          #196#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196);  { ' ' + 32 x 'Ä' }
  TextColor(10);
  J := 1;
  for I := 1 to NumPlayers do
  begin
    S := IntToStr(J) + '.';
    if J < 10 then S := ' ' + S;
    Write(S);
    Write(' ' + Players[I].Name);
    if (Players[I].Score <> Players[I + 1].Score) or
       (Players[I].Wins <> Players[I + 1].Wins) then Inc(J);
    GotoXY(17, WhereY);
    Write(Players[I].Score:8);
    GotoXY(28, WhereY);
    Writeln(Players[I].Wins:4);
  end;
  KbdHead := KbdTail;
  Writeln;
  Writeln;
end;

{ the game: allocates the screen buffers, plays GamesToPlay games (rounds),
  shows the standings after each one; deletes the save file at the end
  (called by the main program) }
{#U0E9B_7523}
procedure PlayGames;
var
  I: Integer;
  Cnt: Integer;
  Unused6: Integer;
  FName: string;
  Regs: Registers;
begin
  GetMem(SaveBuf, 64000);
  GetMem(FallList, 64512);
  GetMem(BackBuf, 64000);
  RoundWinner := 0;
  SaveRequested := 0;
  repeat
    if LoadRequested = 0 then
    begin
      ShufflePlayers;
      PlayRound;                         { play one round }
      SetPalCycle(NoPalCycle);
      if RoundWinner <> 0 then
      begin
        { team won: bonus for its members }
        Cnt := 0;
        for I := 1 to NumPlayers do
          if Players[I].Team = RoundWinner then Inc(Cnt);
        for I := 1 to NumPlayers do
          if Players[I].Team = RoundWinner then
          begin
            if Players[I].f23 <> 0 then Inc(Players[I].Wins);
            Players[I].Score := Players[I].Score + 1000 * NumPlayers div Cnt;
          end;
      end;
    end;
    LoadRequested := 0;
    if AutoSave <> 0 then SaveGame(SaveName);   { autosave }
    ShowStandings;
    if SaveRequested <> 0 then SaveGameDialog;
    if TeamPlay <> 0 then ShowTeamStandings;
    if SaveRequested <> 0 then SaveGameDialog;
    if GameNo <> GamesToPlay then RunShop;
    for I := 0 to 160 do
    begin
      DrawLine(160 - I, 0, 160 - I, 199, 0);
      DrawLine(I + 159, 0, I + 160, 199, 0);
    end;
    Inc(GameNo);
  until GameNo > GamesToPlay;
  FreeMem(BackBuf, 64000);
  FreeMem(SaveBuf, 64000);
  FreeMem(FallList, 64512);
  if SaveName <> 'QWERTYUI' then
  begin
    { DOS 41h: delete the save file }
    Regs.AH := $41;
    FName := SaveName + '.tws';
    Regs.DX := Ofs(FName[1]);
    Regs.DS := Seg(FName[1]);
    Intr($21, Regs);
  end;
end;

