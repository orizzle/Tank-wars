{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U22B7;

{ Player info popup and guidance target selection. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure ShowPlayerInventory(P, Wait: Integer);
procedure ChooseGuideTarget(Kind, P: Integer);

implementation




uses
  U2390;

type
  TScreen = array[0..63999] of Byte;
  PScreen = ^TScreen;

var
  Screen: TScreen absolute $A000:0;
  KbdHead: Word absolute $40:$1A;   { BIOS keyboard buffer pointers }
  KbdTail: Word absolute $40:$1C;

{ Show a box with the inventory/status of player P (0 = player 10).
  Wait = 1: wait for a key, 2: wait for a mouse button. }
{#U22B7_0040}
procedure ShowPlayerInventory(P, Wait: Integer);
var
  Y, I, V, Unused, W, H, Top, Bottom, Right, Left: Integer;
  MouseWasOn: Boolean;
  Unused2: Byte;
  S: string;
begin
  MouseWasOn := BiosKeysEnabled;
  EnableBiosKeys;
  if P = 0 then P := 10;
  W := 260;
  H := 60;
  if (TeamPlay <> 0) and
     (Players[P].Name <> Teams[Players[P].Team].Name) then
    H := H + 12;
  for I := 0 to 17 do
    if Players[P].Ammo[I] > 0 then H := H + 12;
  for I := 0 to 1 do
    if Players[P].Accessory[I] > 0 then H := H + 12;
  for I := 0 to 2 do
    if Players[P].Guidance[I] > 0 then H := H + 12;
  Top := 100 - H div 2;
  Bottom := H div 2 + 100;
  Right := W div 2 + 160;
  Left := 160 - W div 2;
  if P > NumPlayers then Exit;
  PScreen(SaveBuf)^ := Screen;
  SetTextJustify(CenterText, TopText);
  SetColor(13);
  SetFillStyle(SolidFill, 0);
  Bar(Left - 2, Top - 2, Right + 2, Bottom + 2);
  Rectangle(Left - 2, Top - 2, Right + 2, Bottom + 2);
  Rectangle(Left, Top, Right, Bottom);
  SetColor(P + 19);
  SetPlayerColor(100, Players[P]);
  OutTextXY(160, Top + 4, Players[P].Name);
  if (TeamPlay <> 0) and
     (Players[P].Name <> Teams[Players[P].Team].Name) then
  begin
    Top := Top + 12;
    OutTextXY(160, Top + 4, Teams[Players[P].Team].Name);
  end;
  SetTextJustify(LeftText, TopText);
  SetColor(5);
  OutTextXY(Left + 4, Top + 16, 'Men:');
  SetColor(14);
  S := IntToStr(Players[P].Men);
  if Players[P].Men <= 0 then S := 'XXX';
  OutTextXY(Left + 4 + 32, Top + 16, S);
  SetColor(5);
  OutTextXY(184, Top + 16, 'Wins:');
  SetColor(14);
  OutTextXY(224, Top + 16, IntToStr(Players[P].Wins));
  S := IntToStr(10 * Players[P].Men);
  if Players[P].Men <= 0 then S := 'XXX';
  SetColor(5);
  OutTextXY(Left + 4, Top + 28, 'Maximum Power:');
  SetColor(14);
  OutTextXY(Left + 4 + 112, Top + 28, S);
  SetColor(5);
  OutTextXY(184, Top + 28, 'Score:');
  SetColor(14);
  OutTextXY(232, Top + 28, IntToStr(Players[P].Score));
  SetColor(5);
  OutTextXY(184, Top + 40, 'Cash:');
  SetColor(14);
  OutTextXY(224, Top + 40,
    IntToStr(Players[P].Score - Players[P].Spent));
  SetColor(5);
  OutTextXY(Left + 4, Top + 40, 'Accesories:');
  Y := 40;
  for I := 0 to 17 do
    if Players[P].Ammo[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(5);
      if Players[P].Weapon = I then SetColor(4);
      MoveTo(Left + 4, Top + Y);
      OutText(WeaponNames[I] + ':');
      if Players[P].Weapon <> I then SetColor(14);
      OutText(IntToStr(Players[P].Ammo[I]));
    end;
  for I := 0 to 1 do
    if Players[P].Accessory[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(2);
      MoveTo(Left + 4, Top + Y);
      OutText(GuideNames[I] + ':');
      SetColor(14);
      OutText(IntToStr(Players[P].Accessory[I]));
    end;
  for I := 0 to 2 do
    if Players[P].Guidance[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(1);
      MoveTo(Left + 4, Top + Y);
      OutText(ShieldNames[I] + ':');
      SetColor(14);
      V := Players[P].Guidance[I];
      S := IntToStr(V);
      if I = 0 then
      begin
        if V <= 1000 then S := IntToStr(V div 10) + '%';
        if V > 1000 then S := '100%';
      end;
      if I = 1 then
      begin
        if V <= 100 then S := S + '%';
        if V > 100 then S := '100%';
      end;
      OutText(S);
    end;
  if Wait = 1 then
    repeat until KeyPressed;
  if Wait = 2 then
    repeat until MouseBtnsDown(1) or MouseBtnsDown(2);
  if not MouseWasOn then DisableBiosKeys;
  UpdatePlayerColor(Players[P]);
  Screen := PScreen(SaveBuf)^;
  SetTextJustify(LeftText, TopText);
end;

{ Let player P choose the target for his guidance system.
  Kind = 1: keyboard, 2: mouse, 3: computer player (tank object decides). }
{#U22B7_08EC}
procedure ChooseGuideTarget(Kind, P: Integer);
var
  MouseWasOn: Boolean;
  Unused: Byte;
begin
  MouseWasOn := BiosKeysEnabled;
  EnableBiosKeys;
  PScreen(SaveBuf)^ := Screen;
  case Kind of
    1:
      begin
        while (Players[P].f28 < 1) or (Players[P].f28 > NumPlayers) or
              (Players[Players[P].f28].f23 = 0) or
              (Players[P].f28 = P) do
        begin
          Inc(Players[P].f28);
          if Players[P].f28 > NumPlayers then Players[P].f28 := 1;
          if Players[P].f28 < 1 then Players[P].f28 := NumPlayers;
        end;
        SetFillStyle(SolidFill, 0);
        Bar(0, 0, 320, 27);
        SetColor(13);
        Rectangle(0, 0, 319, 28);
        SetTextJustify(CenterText, TopText);
        SetColor(P + 19);
        OutTextXY(160, 4, Players[P].Name + ': Guidance Type ' +
          IntToStr(Players[P].f26));
        SetTextJustify(LeftText, TopText);
        KbdHead := KbdTail;            { flush keyboard buffer }
        repeat
          SetColor(P + 19);
          OutTextXY(70, 15, 'Current Target:');
          Bar(198, 15, 317, 23);
          SetColor(Players[P].f28 + 19);
          OutTextXY(198, 15, Players[Players[P].f28].Name);
          repeat until KeyPressed;
          KeyChar := UpCase(ReadKey);
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            repeat
              if KeyChar = ScanRight then Inc(Players[P].f28);
              if KeyChar = ScanLeft then Dec(Players[P].f28);
              if Players[P].f28 > NumPlayers then Players[P].f28 := 1;
              if Players[P].f28 < 1 then Players[P].f28 := NumPlayers;
            until (Players[P].f28 <> P) and
                  (Players[Players[P].f28].f23 <> 0);
          end;
        until KeyChar in [#13, ' '];
      end;
    2:
      begin
        SetFillStyle(SolidFill, 0);
        Bar(0, 0, 320, 27);
        SetColor(13);
        Rectangle(0, 0, 319, 28);
        SetTextJustify(CenterText, TopText);
        SetColor(P + 19);
        OutTextXY(160, 4, Players[P].Name + ': Guidance Type ' +
          IntToStr(Players[P].f26));
        OutTextXY(160, 15, 'Please click on target');
        SetTextJustify(LeftText, TopText);
        ShowMouseCursor;
        DoneFlag := 0;
        repeat
          if MouseBtnsDown(1) or MouseBtnsDown(2) then
          begin
            TmpX := MouseX;
            TmpY := MouseY;
            HideMouseCursor;
            TmpR := PixelAt(TmpX, TmpY);
            ShowMouseCursor;
            if (TmpR in [20..NumPlayers + 19]) and
               (Players[TmpR - 19].f23 <> 0) then
            begin
              Players[P].f28 := TmpR - 19;
              DoneFlag := 1;
            end;
          end;
        until DoneFlag <> 0;
        HideMouseCursor;
      end;
    3:
      Players[P].f28 := PComputer(Tanks[P])^.GetTarget;
  end;
  Screen := PScreen(SaveBuf)^;
  if not MouseWasOn then DisableBiosKeys;
end;

end.
