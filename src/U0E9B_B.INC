{ load a saved game FileName.TWS (counterpart of U0E9B_39EA) }
{#U0E9B_3E7A}
procedure U0E9B_3E7A(FileName: string);
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
  Hdr := Hdr + 'V' + Version_0056 + #13 + #10;
  Hdr := Hdr + #26;
  Buf := Hdr;
  BlockRead(F, Buf[1], Length(Hdr));
  if Buf <> Hdr then
  begin
    U0098_028C(100, 90, 220, 113, 18, 15, 17);
    SetTextJustify(1, 1);
    SetColor(14);
    OutTextXY(160, 95, 'Save File is not valid!');
    SetColor(4);
    OutTextXY(160, 105, 'Press Any Key...');
    repeat until KeyPressed or U2968_0077(1) or U2968_0077(2);
    Halt;
  end;
  BlockRead(F, g_46B2, 2);
  BlockRead(F, g_46B4, 2);
  BlockRead(F, g_46BC, 2);
  BlockRead(F, g_46BE, 2);
  BlockRead(F, g_46C0, 2);
  BlockRead(F, g_46C2, 2);
  BlockRead(F, g_46C4, 2);
  BlockRead(F, g_46C6, 2);
  BlockRead(F, g_46C8, 1);
  BlockRead(F, g_46EC, 1);
  BlockRead(F, g_46EE, 1);
  BlockRead(F, g_46EF, 1);
  BlockRead(F, g_E778, 2);
  BlockRead(F, g_E77A, 2);
  BlockRead(F, g_E77C, 2);
  BlockRead(F, g_E77E, 2);
  BlockRead(F, g_E780, 2);
  BlockRead(F, g_E782, 2);
  BlockRead(F, g_E784, 2);
  BlockRead(F, g_E787, 1);
  BlockRead(F, g_E788, 1);
  BlockRead(F, g_E789, 1);
  BlockRead(F, g_E78A, 1);
  BlockRead(F, g_E78D, 1);
  BlockRead(F, g_E78F, 1);
  BlockRead(F, g_E791, 1);
  FillChar(Tanks_3EE2, 44, 0);
  for I := 1 to g_46B4 do
  begin
    BlockRead(F, Players_3F0E[I], SizeOf(TPlayer));
    BlockRead(F, Control_E480[I], 2);
    if Control_E480[I] = 3 then
    begin
      { computer player: recreate its AI object }
      BlockRead(F, Kind, 2);
      case Kind of
        1: Tanks_3EE2[I] := New(PStupid, Init(I));
        2: Tanks_3EE2[I] := New(PLobber, Init(I));
        3: Tanks_3EE2[I] := New(PRifleman, Init(I));
        4: Tanks_3EE2[I] := New(PLobShoot, Init(I));
        5: Tanks_3EE2[I] := New(PWindless, Init(I));
        6: Tanks_3EE2[I] := New(PTwanger, Init(I));
        7: Tanks_3EE2[I] := New(PWindMaster, Init(I));
      end;
      PComputer(Tanks_3EE2[I])^.Load(F);
    end;
  end;
  BlockRead(F, Teams_4712, SizeOf(Teams_4712));
  Close(F);
end;

{ "Save game" dialog: Save / Autosave toggle / Save & Quit / New Name / Cancel }
{#U0E9B_455E}
procedure U0E9B_455E;
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
  U0098_028C(100, 65, 220, 95, 18, 15, 17);
  SetTextStyle(2, 0, 0);
  SetUserCharSize(1, 1, 1, 1);
  i := 0;
  { no name yet: pick the first free GAMEn }
  if SaveName_46FC = 'QWERTYUI' then
    repeat
      Inc(i);
      SaveName_46FC := 'GAME' + U2918_02FE(i);
      FindFirst(SaveName_46FC + '.TWS', 0, SR);
    until DosError <> 0;
  SetTextJustify(1, 1);
  SetColor(4);
  OutTextXY(160, 69, 'SAVE GAME');
  SetColor(9);
  SetTextJustify(0, 1);
  OutTextXY(105, 81, 'File Name:');
  SetColor(14);
  OutTextXY(165, 81, SaveName_46FC);
  SetTextJustify(1, 1);
  U0098_028C(135, 100, 185, 110, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 104, 'Save');
  SetColor(14);
  OutTextXY(160, 104, 'S   ');
  U0098_028C(190, 100, 260, 110, 18, 15, 17);
  U0098_028C(190, 100, 260, 110, 18, 15, 17);
  SetTextJustify(0, 1);
  SetColor(6);
  OutTextXY(192, 104, 'Autosave:' + U0728_0043(Boolean(g_46F2)));
  SetColor(14);
  OutTextXY(192, 104, 'A');
  SetTextJustify(1, 1);
  U0098_028C(60, 100, 130, 110, 18, 15, 17);
  SetColor(6);
  OutTextXY(95, 104, 'Save & Quit');
  SetColor(14);
  OutTextXY(96, 104, '       Q   ');
  U0098_028C(135, 115, 185, 125, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 119, 'New Name');
  SetColor(14);
  OutTextXY(160, 119, 'N       ');
  U0098_028C(135, 130, 185, 140, 18, 15, 17);
  SetColor(6);
  OutTextXY(160, 134, 'Cancel');
  SetColor(14);
  OutTextXY(161, 134, 'C     ');
  repeat
    Choice := 0;
    U2968_004D;
    repeat
      if KeyPressed then
      begin
        g_46C9 := UpCase(ReadKey);
        if g_46C9 = 'Q' then Choice := 5;
        if g_46C9 = 'A' then Choice := 4;
        if g_46C9 = 'C' then Choice := 3;
        if g_46C9 = 'N' then Choice := 2;
        if g_46C9 = 'S' then Choice := 1;
      end;
      MX := U2918_022A;
      MY := U2918_0256;
      if U2968_0077(1) or U2968_0077(2) then
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
        repeat until not U2968_0077(1) and not U2968_0077(2);
      end;
    until Choice <> 0;
    U2968_005A;
    if Choice = 2 then
    begin
      U0E9B_369F;
      U2823_0088(164, 76, 218, 86, 18);
      SetColor(14);
      OutTextXY(165, 81, SaveName_46FC);
    end;
    if Choice = 4 then
    begin
      Boolean(g_46F2) := not Boolean(g_46F2);
      U0098_028C(190, 100, 260, 110, 18, 15, 17);
      SetTextJustify(0, 1);
      SetColor(6);
      OutTextXY(192, 104, 'Autosave:' + U0728_0043(Boolean(g_46F2)));
      SetColor(14);
      OutTextXY(192, 104, 'A');
    end;
  until Choice in [1, 3, 5];
  if Choice = 1 then U0E9B_39EA(SaveName_46FC);
  if Choice = 5 then
  begin
    U0E9B_39EA(SaveName_46FC);
    TextMode(3);
    Halt;
  end;
  { wipe the screen from the back buffer, two columns at a time }
  for i := 0 to 319 do
  begin
    U2823_0AC0(i, 0, i, 199, SaveBuf_E496);
    Inc(i);
  end;
  for i := 319 downto 0 do
  begin
    U2823_0AC0(i, 0, i, 199, SaveBuf_E496);
    Dec(i);
  end;
  g_46F0 := 0;
end;

{ "Load game" dialog: lists *.TWS, lets the player pick one, loads it }
{#U0E9B_4B93}
procedure U0E9B_4B93;
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
    U0098_028C(100, 90, 220, 113, 18, 15, 17);
    SetTextJustify(1, 1);
    SetColor(14);
    OutTextXY(160, 95, 'No Save Files Found');
    SetColor(4);
    OutTextXY(160, 105, 'Press Any Key...');
    repeat until KeyPressed or U2968_0077(1) or U2968_0077(2);
    Halt;
  end;
  Sel := 1;
  SetTextJustify(1, 1);
  U0098_028C(100, 89, 220, 111, 18, 15, 17);
  SetColor(14);
  OutTextXY(160, 95, 'Select Game to Load:');
  SetColor(0);
  OutTextXY(160, 105, Names[Sel]);
  SetColor(9);
  SetTextJustify(1, 1);
  OutTextXY(107, 105, '<-');
  OutTextXY(213, 105, '->');
  U0098_028C(145, 116, 175, 126, 18, 15, 17);
  SetTextJustify(1, 1);
  OutTextXY(160, 120, 'OK');
  Done := False;
  SetColor(0);
  U2968_004D;
  U27B1_010C;
  repeat
    if (g_440A[$4D] <> 0) or (g_440A[$14D] <> 0) then
    begin
      Inc(Sel);
      if Sel > Count then Sel := 1;
      U2823_0088(120, 100, 210, 111, 18);
      OutTextXY(160, 105, Names[Sel]);
      repeat until g_440A[$4D] = 0;
      repeat until g_440A[$14D] = 0;
    end;
    if (g_440A[$4B] <> 0) or (g_440A[$14B] <> 0) then
    begin
      Dec(Sel);
      if Sel = 0 then Sel := Count;
      U2823_0088(120, 100, 200, 111, 18);
      OutTextXY(160, 105, Names[Sel]);
      repeat until g_440A[$4B] = 0;
      repeat until g_440A[$14B] = 0;
    end;
    if (g_440A[$1C] <> 0) or (g_440A[$11C] <> 0) or (g_440A[$39] <> 0) then
      Done := True;
    if U2968_0077(1) or U2968_0077(2) then
    begin
      MX := U2918_022A;
      MY := U2918_0256;
      U2968_005A;
      if (MX > 120) and (MX < 200) and (MY > 100) and (MY < 111) then
      begin
        if U2968_0077(1) then Dec(Sel);
        if U2968_0077(2) then Inc(Sel);
        if Sel > Count then Sel := 1;
        if Sel = 0 then Sel := Count;
        U2823_0088(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not U2968_0077(1) and not U2968_0077(2);
      end;
      if (MX > 100) and (MX < 115) and (MY < 111) and (MY > 101) then
      begin
        Dec(Sel);
        if Sel = 0 then Sel := Count;
        U2823_0088(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not U2968_0077(1) and not U2968_0077(2);
      end;
      if (MX < 220) and (MX > 205) and (MY < 111) and (MY > 101) then
      begin
        Inc(Sel);
        if Sel > Count then Sel := 1;
        U2823_0088(120, 100, 210, 111, 18);
        OutTextXY(160, 105, Names[Sel]);
        repeat until not U2968_0077(1) and not U2968_0077(2);
      end;
      if (MX > 145) and (MX < 175) and (MY > 116) and (MY < 126) then
        Done := True;
      U2968_004D;
    end;
  until Done;
  U2968_005A;
  U27B1_014E;
  SaveName_46FC := Names[Sel];
  U0E9B_3E7A(SaveName_46FC);
end;

{ "# TO ADD:" box: edit a number (max. 3 digits) and add it to g_E77C
  (number of games to play) }
procedure U0E9B_54C6;
var
  P: Pointer;
  Pos, NewPos, I: Integer;
  Done, Changed: Boolean;
  S: string;

  { draw the block cursor under character Pos (and clear the line below) }
  {#U0E9B_51F2} procedure U0E9B_51F2;
  begin
    U2823_0031((Pos - 1) * 6 + 138 - 1, 100, (Pos - 1) * 6 + 138 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 138, 101, (Pos - 1) * 6 + 138 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 138 + 1, 102, (Pos - 1) * 6 + 138 + 2, 108, 18);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + 138, 104, Copy(S, Pos, 1));
    U2823_00CC((Pos - 1) * 6 + 138 - 1, 109, (Pos - 1) * 6 + 138 + 4, 110, SaveBuf_E496);
  end;

  { erase the cursor at Pos, redraw the character }
  {#U0E9B_5336} procedure U0E9B_5336;
  begin
    U2823_0031((Pos - 1) * 6 + 138 - 1, 100, (Pos - 1) * 6 + 138 + 4, 110, 18);
    U2823_0031((Pos - 1) * 6 + 138, 101, (Pos - 1) * 6 + 138 + 3, 109, 18);
    U2823_0031((Pos - 1) * 6 + 138 + 1, 102, (Pos - 1) * 6 + 138 + 2, 108, 18);
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
  U0098_028C(130, 85, 190, 115, 18, 15, 17);
  SetTextJustify(0, 2);
  SetColor(5);
  OutTextXY(133, 85, '# TO ADD:');
  U0098_028C(135, 100, 185, 110, 18, 17, 15);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(S) do
    OutTextXY((Pos - 1) * 6 + 138, 104, Copy(S, Pos, 1));
  Inc(S[0]);
  Pos := Length(S);
  Done := False;
  repeat
    U0E9B_51F2;
    Changed := False;
    repeat
      repeat until KeyPressed;
      g_46C9 := ReadKey;
      if (g_46C9 in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        S[NewPos] := ' ';
        S[NewPos + 1] := ' ';
        Changed := True;
      end;
      if g_46C9 in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if g_46C9 in ['0'..'9'] then
      begin
        S[Pos] := UpCase(g_46C9);
        Changed := True;
        NewPos := Pos + 1;
        if Length(S) < NewPos then Inc(S[0]);
      end;
      if g_46C9 = #0 then
      begin
        g_46C9 := ReadKey;
        if g_46C9 = #$47 then                   { Home: clear }
        begin
          for Pos := Length(S) downto 1 do
          begin
            S[Pos] := ' ';
            U0E9B_51F2;
            U0E9B_5336;
          end;
          S := '  ';
          NewPos := 1;
        end;
        if g_46C9 = #$53 then                   { Del }
        begin
          S[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if g_46C9 = #$4F then                   { End }
        begin
          Changed := True;
          NewPos := Length(S);
        end;
        if (g_46C9 = KeyLt_3719) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (g_46C9 = KeyRt_3718) and (Length(S) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 3 then NewPos := 3;
    if Length(S) > 3 then S[0] := #3;
    U0E9B_5336;
    Pos := NewPos;
  until Done;
  while (S[Length(S)] in [#0, ' ']) and (Length(S) > 0) do Dec(S[0]);
  Val(S, I, g_4620);
  g_E77C := g_E77C + I;
  PutImage(128, 83, P^, 0);
  FreeMem(P, 653);
end;

{ end-of-round standings (individual players): sorted by wins, then score;
  buttons Add (more games) / Continue|Exit / Save; digit or click = player info }
{#U0E9B_5893}
procedure U0E9B_5893;
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
  SaveFlag := g_46EC;
  if g_46BC = g_E77C then g_46EC := 0;
  H := g_46B4 * 5 + 15;
  Top := 100 - H;
  Bottom := H + 100;
  I := 0;
  U0098_01BD;
  KbdHead := KbdTail;                           { flush the BIOS key buffer }
  TScreen(SaveBuf_E496^) := Screen;
  for I := 1 to g_46B4 do
    for J := 1 to g_46B4 - 1 do
      if Players_3F0E[J].Wins < Players_3F0E[J + 1].Wins then U0E9B_0000(J, J + 1);
  for I := 1 to g_46B4 do
    for J := 1 to g_46B4 - 1 do
      if (Players_3F0E[J].Wins = Players_3F0E[J + 1].Wins) and
         (Players_3F0E[J].Score < Players_3F0E[J + 1].Score) then U0E9B_0000(J, J + 1);
  g_E7D6 := $A000;
  U0728_3A10(1);
  TScreen(SaveBuf_E496^) := Screen;
  U0098_028C(45, Top, 275, Bottom, 18, 15, 17);
  U0098_028C(65, Top - 20, 255, Top - 5, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(6);
  SetTextJustify(1, 1);
  if g_46BC > 1 then S := ' Games ' else S := ' Game ';
  OutTextXY(160, Top - 13, U2918_02FE(g_46BC) + S + 'Played out of ' + U2918_02FE(g_E77C));
  for I := 1 to g_46B4 do U26A9_0175(100, Players_3F0E[I]);
  SetColor(17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(0, 2);
  U2823_09E4(50, Top + 16, 270, Top + 16, 17);
  OutTextXY(50, Top + 5, 'Player');
  J := 1;
  for I := 1 to g_46B4 do
  begin
    SetColor(I + 19);
    S := U2918_02FE(J) + '.';
    if J < 10 then S := ' ' + S;
    OutTextXY(50, Top + 10 + 10 * I, S);
    OutTextXY(72, Top + 10 + 10 * I, Players_3F0E[I].Name);
    if (I <> 10) and ((Players_3F0E[I].Score <> Players_3F0E[I + 1].Score) or
       (Players_3F0E[I].Wins <> Players_3F0E[I + 1].Wins)) then Inc(J);
  end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(270, Top + 5, 'Score');
  for I := 1 to g_46B4 do
  begin
    SetColor(I + 19);
    OutTextXY(270, Top + 10 + 10 * I, U2918_02FE(Players_3F0E[I].Score));
  end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(185, Top + 5, 'Wins');
  for I := 1 to g_46B4 do
  begin
    SetColor(I + 19);
    OutTextXY(185, Top + 10 + 10 * I, U2918_02FE(Players_3F0E[I].Wins));
  end;
  U2823_0006;
  if g_46EC = 0 then
  begin
    SetTextJustify(1, 1);
    U0098_028C(60, Bottom + 5, 110, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(85, Bottom + 9, 'Add');
    U0098_028C(210, Bottom + 5, 260, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(235, Bottom + 9, 'Save');
    U0098_028C(135, Bottom + 5, 185, Bottom + 15, 18, 15, 17);
    SetColor(0);
    if g_46BC <> g_E77C then OutTextXY(160, Bottom + 9, 'Continue')
    else OutTextXY(160, Bottom + 9, 'Exit');
    U2968_004D;
    g_462F := 0;
    repeat
      if KeyPressed then
      begin
        g_46C9 := ReadKey;
        if (g_46C9 >= '0') and (g_46C9 <= '9') then
        begin
          Val(g_46C9, I, J);
          if I = 0 then I := 10;
          if I <= g_46B4 then U0E9B_24E4(I);
        end
        else if g_46C9 in ['S', 's'] then
        begin
          g_46F0 := 1;
          g_462F := 1;
        end
        else if g_46C9 in ['A', 'a'] then
        begin
          U2968_005A;
          U0E9B_54C6;
          SetTextStyle(2, 0, 1);
          SetUserCharSize(1, 1, 1, 1);
          SetColor(6);
          SetTextJustify(1, 1);
          if g_46BC > 1 then S := ' Games ' else S := ' Game ';
          U2823_0088(76, Top - 17, 244, Top - 5, 18);
          OutTextXY(160, Top - 13, U2918_02FE(g_46BC) + S + 'Played out of ' + U2918_02FE(g_E77C));
          g_46EC := SaveFlag;
          U2968_004D;
        end
        else
          g_462F := 1;
      end;
      if U2968_0077(1) or U2968_0077(2) then
      begin
        g_4624 := U2918_022A;
        g_4626 := U2918_0256;
        if (g_4624 > 45) and (g_4624 < 275) then
          for I := 1 to g_46B4 do
            if (Top + 12 + 10 * I <= g_4626) and (Top + 12 + 10 * I + 10 > g_4626) then
            begin
              repeat until not U2968_0077(1) and not U2968_0077(2);
              U0E9B_24E4(I);
              repeat until not U2968_0077(1) and not U2968_0077(2);
              g_4624 := 0;
              g_4626 := 0;
            end;
        if (g_4624 >= 135) and (Bottom + 5 <= g_4626) and (g_4624 <= 185) and (Bottom + 15 >= g_4626) then
          g_462F := 1;
        if (g_4624 >= 60) and (Bottom + 5 <= g_4626) and (g_4624 <= 110) and (Bottom + 15 >= g_4626) then
        begin
          U2968_005A;
          U0E9B_54C6;
          SetTextStyle(2, 0, 1);
          SetUserCharSize(1, 1, 1, 1);
          SetColor(6);
          SetTextJustify(1, 1);
          if g_46BC > 1 then S := ' Games ' else S := ' Game ';
          U2823_0088(76, Top - 17, 244, Top - 5, 18);
          OutTextXY(160, Top - 13, U2918_02FE(g_46BC) + S + 'Played out of ' + U2918_02FE(g_E77C));
          g_46EC := SaveFlag;
          U2968_004D;
        end;
        if (g_4624 >= 210) and (Bottom + 5 <= g_4626) and (g_4624 <= 260) and (Bottom + 15 >= g_4626) then
        begin
          g_46F0 := 1;
          g_462F := 1;
        end;
      end;
    until g_462F <> 0;
    U2968_005A;
    U2823_0006;
  end
  else
    Delay(2000);
  { wipe back to the saved screen }
  for I := 0 to 319 do
  begin
    U2823_0AC0(0, 199, I, 0, SaveBuf_E496);
    U2823_0AC0(319, 0, 319 - I, 199, SaveBuf_E496);
  end;
  KbdHead := KbdTail;
end;

{ end-of-round standings for team play: sums the members' statistics into
  Teams_4712[], sorts by member count, average wins, score; buttons
  Continue|Exit / Save; digit or click = team info }
{#U0E9B_63ED}
procedure U0E9B_63ED;
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
  for I := 1 to g_46B4 do
    if Teams_4712[I].f0F > 0 then
    begin
      H := H + 5;
      Inc(NumTeams);
    end;
  Top := 100 - H;
  Bottom := H + 100;
  I := 0;
  U0098_01BD;
  KbdHead := KbdTail;
  for T := 1 to 10 do
  begin
    Teams_4712[T].f11 := 0;
    Teams_4712[T].f17 := 0;
    Teams_4712[T].f1D := 0;
    Teams_4712[T].f23 := 0;
    Teams_4712[T].f29 := 0;
    Teams_4712[T].f2F := 0;
    for P := 1 to g_46B4 do
      if Players_3F0E[P].Team = T then
      begin
        Teams_4712[T].f11 := Teams_4712[T].f11 + Players_3F0E[P].Score;
        Teams_4712[T].f17 := Teams_4712[T].f17 + Players_3F0E[P].f68;
        Teams_4712[T].f1D := Teams_4712[T].f1D + Players_3F0E[P].Wins;
        Teams_4712[T].f23 := Teams_4712[T].f23 + Players_3F0E[P].f6C;
        Teams_4712[T].f29 := Teams_4712[T].f29 + Players_3F0E[P].f6E;
        Teams_4712[T].f2F := Teams_4712[T].f2F + Players_3F0E[P].f70;
      end;
    Order[T] := T;
    if Teams_4712[T].f0F > 0 then
    begin
      Teams_4712[T].f17 := Teams_4712[T].f17 / Teams_4712[T].f0F;
      Teams_4712[T].f1D := Teams_4712[T].f1D / Teams_4712[T].f0F;
    end;
  end;
  { Order[0] is the swap slot }
  for I := 1 to 10 do
    for J := 1 to 9 do
      if Teams_4712[Order[J]].f0F < Teams_4712[Order[J + 1]].f0F then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  for I := 1 to 10 do
    for J := 1 to 9 do
      if Teams_4712[Order[J]].f1D < Teams_4712[Order[J + 1]].f1D then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  { (original bug: compares Teams_4712[J] instead of Teams_4712[Order[J]]) }
  for I := 1 to 10 do
    for J := 1 to 9 do
      if (Teams_4712[J].f1D = Teams_4712[J + 1].f1D) and
         (Teams_4712[J].f11 < Teams_4712[J + 1].f11) then
      begin
        Order[0] := Order[J];
        Order[J] := Order[J + 1];
        Order[J + 1] := Order[0];
      end;
  g_E7D6 := $A000;
  U0098_028C(45, Top, 275, Bottom, 18, 15, 17);
  U0098_028C(69, Top - 20, 251, Top - 5, 18, 15, 17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(6);
  SetTextJustify(1, 1);
  if g_46BC > 1 then S := ' Games ' else S := ' Game ';
  OutTextXY(160, Top - 13, U2918_02FE(g_46BC) + S + 'Played out of ' + U2918_02FE(g_E77C));
  for I := 1 to g_46B4 do U26A9_0175(100, Players_3F0E[I]);
  SetColor(17);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(0, 2);
  U2823_09E4(50, Top + 16, 270, Top + 16, 17);
  OutTextXY(50, Top + 5, 'Team');
  J := 1;
  for I := 1 to g_46B4 do
    if Teams_4712[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      S := U2918_02FE(J) + '.';
      if J < 10 then S := ' ' + S;
      OutTextXY(50, Top + 10 + 10 * I, S);
      OutTextXY(72, Top + 10 + 10 * I, Teams_4712[Order[I]].Name);
      if (I <> 10) and ((Teams_4712[Order[I]].f11 <> Teams_4712[Order[I + 1]].f11) or
         (Teams_4712[Order[I]].f1D <> Teams_4712[Order[I + 1]].f1D)) then Inc(J);
    end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(270, Top + 5, 'Score');
  for I := 1 to g_46B4 do
    if Teams_4712[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      Str(Teams_4712[Order[I]].f11:10:0, S);
      OutTextXY(270, Top + 10 + 10 * I, S);
    end;
  SetTextJustify(2, 2);
  SetColor(17);
  OutTextXY(185, Top + 5, 'Wins');
  for I := 1 to g_46B4 do
    if Teams_4712[Order[I]].f0F > 0 then
    begin
      SetColor(14);
      Str(Teams_4712[Order[I]].f1D:5:2, S);
      OutTextXY(185, Top + 10 + 10 * I, S);
    end;
  U2823_0006;
  if g_46EC = 0 then
  begin
    SetTextJustify(1, 1);
    U0098_028C(85, Bottom + 5, 135, Bottom + 15, 18, 15, 17);
    SetColor(0);
    if g_46BC <> g_E77C then OutTextXY(110, Bottom + 9, 'Continue')
    else OutTextXY(110, Bottom + 9, 'Exit');
    U0098_028C(185, Bottom + 5, 235, Bottom + 15, 18, 15, 17);
    SetColor(0);
    OutTextXY(210, Bottom + 9, 'Save');
    U2968_004D;
    g_462F := 0;
    repeat
      if KeyPressed then
      begin
        g_46C9 := ReadKey;
        if (g_46C9 >= '0') and (g_46C9 <= '9') then
        begin
          Val(g_46C9, I, J);
          if I = 0 then I := 10;
          if I <= g_46B4 then U0E9B_2B8E(Order[I]);
        end
        else if g_46C9 in ['S', 's'] then
        begin
          g_46F0 := 1;
          g_462F := 1;
        end
        else
          g_462F := 1;
      end;
      if U2968_0077(1) or U2968_0077(2) then
      begin
        g_4624 := U2918_022A;
        g_4626 := U2918_0256;
        if (g_4624 > 45) and (g_4624 < 275) then
          for I := 1 to NumTeams do
            if (Top + 12 + 10 * I <= g_4626) and (Top + 12 + 10 * I + 10 > g_4626) then
            begin
              repeat until not U2968_0077(1) and not U2968_0077(2);
              U0E9B_2B8E(Order[I]);
              repeat until not U2968_0077(1) and not U2968_0077(2);
              g_4624 := 0;
              g_4626 := 0;
            end;
        if (g_4624 >= 85) and (Bottom + 5 <= g_4626) and (g_4624 <= 135) and (Bottom + 15 >= g_4626) then
          g_462F := 1;
        if (g_4624 >= 185) and (Bottom + 5 <= g_4626) and (g_4624 <= 235) and (Bottom + 15 >= g_4626) then
        begin
          g_46F0 := 1;
          g_462F := 1;
        end;
      end;
    until g_462F <> 0;
    U2968_005A;
    U2823_0006;
  end
  else
    Delay(5000);
  { zoom back to the saved screen }
  for I := 150 downto 0 do
  begin
    U2823_0687(160, 100, I, I, SaveBuf_E496);
    U2823_0687(161, 100, I, I, SaveBuf_E496);
  end;
  KbdHead := KbdTail;
end;

{ final results in text mode (called by the main program after the games) }
{#U0E9B_7242}
procedure U0E9B_7242;
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
  if g_46BC > 2 then S := ' Games ' else S := ' Game ';
  Writeln(U2918_02FE(g_46BC - 1) + S + 'Played');
  Writeln('   And just in case you missed them:');
  Writeln('');
  TextColor(15);
  Writeln('             Results ');
  Writeln('   Name            Score   Wins');
  Writeln(' '#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196 +
          #196#196#196#196#196#196#196#196#196#196#196#196#196#196#196#196);  { ' ' + 32 x 'Ä' }
  TextColor(10);
  J := 1;
  for I := 1 to g_46B4 do
  begin
    S := U2918_02FE(J) + '.';
    if J < 10 then S := ' ' + S;
    Write(S);
    Write(' ' + Players_3F0E[I].Name);
    if (Players_3F0E[I].Score <> Players_3F0E[I + 1].Score) or
       (Players_3F0E[I].Wins <> Players_3F0E[I + 1].Wins) then Inc(J);
    GotoXY(17, WhereY);
    Write(Players_3F0E[I].Score:8);
    GotoXY(28, WhereY);
    Writeln(Players_3F0E[I].Wins:4);
  end;
  KbdHead := KbdTail;
  Writeln;
  Writeln;
end;

{ the game: allocates the screen buffers, plays g_E77C games (rounds),
  shows the standings after each one; deletes the save file at the end
  (called by the main program) }
{#U0E9B_7523}
procedure U0E9B_7523;
var
  I: Integer;
  Cnt: Integer;
  Unused6: Integer;
  FName: string;
  Regs: Registers;
begin
  GetMem(SaveBuf_E496, 64000);
  GetMem(PalPtr_DE7C, 64512);
  GetMem(BackBuf_E49A, 64000);
  g_46BA := 0;
  g_46F0 := 0;
  repeat
    if g_46F1 = 0 then
    begin
      U0E9B_23EF;
      U1615_46C2;                         { play one round }
      U27D4_003D(NoCycle_3706);
      if g_46BA <> 0 then
      begin
        { team won: bonus for its members }
        Cnt := 0;
        for I := 1 to g_46B4 do
          if Players_3F0E[I].Team = g_46BA then Inc(Cnt);
        for I := 1 to g_46B4 do
          if Players_3F0E[I].Team = g_46BA then
          begin
            if Players_3F0E[I].f23 <> 0 then Inc(Players_3F0E[I].Wins);
            Players_3F0E[I].Score := Players_3F0E[I].Score + 1000 * g_46B4 div Cnt;
          end;
      end;
    end;
    g_46F1 := 0;
    if g_46F2 <> 0 then U0E9B_39EA(SaveName_46FC);   { autosave }
    U0E9B_5893;
    if g_46F0 <> 0 then U0E9B_455E;
    if g_E791 <> 0 then U0E9B_63ED;
    if g_46F0 <> 0 then U0E9B_455E;
    if g_46BC <> g_E77C then U0E9B_0E1F;
    for I := 0 to 160 do
    begin
      U2823_09E4(160 - I, 0, 160 - I, 199, 0);
      U2823_09E4(I + 159, 0, I + 160, 199, 0);
    end;
    Inc(g_46BC);
  until g_46BC > g_E77C;
  FreeMem(BackBuf_E49A, 64000);
  FreeMem(SaveBuf_E496, 64000);
  FreeMem(PalPtr_DE7C, 64512);
  if SaveName_46FC <> 'QWERTYUI' then
  begin
    { DOS 41h: delete the save file }
    Regs.AH := $41;
    FName := SaveName_46FC + '.tws';
    Regs.DX := Ofs(FName[1]);
    Regs.DS := Seg(FName[1]);
    Intr($21, Regs);
  end;
end;

