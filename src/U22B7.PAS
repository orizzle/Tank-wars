{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U22B7;

{ Player info popup and guidance target selection. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure U22B7_0040(P, Wait: Integer);
procedure U22B7_08EC(Kind, P: Integer);

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
procedure U22B7_0040(P, Wait: Integer);
var
  Y, I, V, Unused, W, H, Top, Bottom, Right, Left: Integer;
  MouseWasOn: Boolean;
  Unused2: Byte;
  S: string;
begin
  MouseWasOn := U27B1_0190;
  U27B1_014E;
  if P = 0 then P := 10;
  W := 260;
  H := 60;
  if (g_E791 <> 0) and
     (Players_3F0E[P].Name <> Teams_4712[Players_3F0E[P].Team].Name) then
    H := H + 12;
  for I := 0 to 17 do
    if Players_3F0E[P].Ammo[I] > 0 then H := H + 12;
  for I := 0 to 1 do
    if Players_3F0E[P].Accessory[I] > 0 then H := H + 12;
  for I := 0 to 2 do
    if Players_3F0E[P].Guidance[I] > 0 then H := H + 12;
  Top := 100 - H div 2;
  Bottom := H div 2 + 100;
  Right := W div 2 + 160;
  Left := 160 - W div 2;
  if P > g_46B4 then Exit;
  PScreen(SaveBuf_E496)^ := Screen;
  SetTextJustify(CenterText, TopText);
  SetColor(13);
  SetFillStyle(SolidFill, 0);
  Bar(Left - 2, Top - 2, Right + 2, Bottom + 2);
  Rectangle(Left - 2, Top - 2, Right + 2, Bottom + 2);
  Rectangle(Left, Top, Right, Bottom);
  SetColor(P + 19);
  U26A9_01B0(100, Players_3F0E[P]);
  OutTextXY(160, Top + 4, Players_3F0E[P].Name);
  if (g_E791 <> 0) and
     (Players_3F0E[P].Name <> Teams_4712[Players_3F0E[P].Team].Name) then
  begin
    Top := Top + 12;
    OutTextXY(160, Top + 4, Teams_4712[Players_3F0E[P].Team].Name);
  end;
  SetTextJustify(LeftText, TopText);
  SetColor(5);
  OutTextXY(Left + 4, Top + 16, 'Men:');
  SetColor(14);
  S := U2918_02FE(Players_3F0E[P].Men);
  if Players_3F0E[P].Men <= 0 then S := 'XXX';
  OutTextXY(Left + 4 + 32, Top + 16, S);
  SetColor(5);
  OutTextXY(184, Top + 16, 'Wins:');
  SetColor(14);
  OutTextXY(224, Top + 16, U2918_02FE(Players_3F0E[P].Wins));
  S := U2918_02FE(10 * Players_3F0E[P].Men);
  if Players_3F0E[P].Men <= 0 then S := 'XXX';
  SetColor(5);
  OutTextXY(Left + 4, Top + 28, 'Maximum Power:');
  SetColor(14);
  OutTextXY(Left + 4 + 112, Top + 28, S);
  SetColor(5);
  OutTextXY(184, Top + 28, 'Score:');
  SetColor(14);
  OutTextXY(232, Top + 28, U2918_02FE(Players_3F0E[P].Score));
  SetColor(5);
  OutTextXY(184, Top + 40, 'Cash:');
  SetColor(14);
  OutTextXY(224, Top + 40,
    U2918_02FE(Players_3F0E[P].Score - Players_3F0E[P].Spent));
  SetColor(5);
  OutTextXY(Left + 4, Top + 40, 'Accesories:');
  Y := 40;
  for I := 0 to 17 do
    if Players_3F0E[P].Ammo[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(5);
      if Players_3F0E[P].Weapon = I then SetColor(4);
      MoveTo(Left + 4, Top + Y);
      OutText(WeaponName_087C[I] + ':');
      if Players_3F0E[P].Weapon <> I then SetColor(14);
      OutText(U2918_02FE(Players_3F0E[P].Ammo[I]));
    end;
  for I := 0 to 1 do
    if Players_3F0E[P].Accessory[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(2);
      MoveTo(Left + 4, Top + Y);
      OutText(GuidName_2CE8[I] + ':');
      SetColor(14);
      OutText(U2918_02FE(Players_3F0E[P].Accessory[I]));
    end;
  for I := 0 to 2 do
    if Players_3F0E[P].Guidance[I] > 0 then
    begin
      Y := Y + 12;
      SetColor(1);
      MoveTo(Left + 4, Top + Y);
      OutText(ShieldName_30F4[I] + ':');
      SetColor(14);
      V := Players_3F0E[P].Guidance[I];
      S := U2918_02FE(V);
      if I = 0 then
      begin
        if V <= 1000 then S := U2918_02FE(V div 10) + '%';
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
    repeat until U2968_0077(1) or U2968_0077(2);
  if not MouseWasOn then U27B1_010C;
  U26A9_014E(Players_3F0E[P]);
  Screen := PScreen(SaveBuf_E496)^;
  SetTextJustify(LeftText, TopText);
end;

{ Let player P choose the target for his guidance system.
  Kind = 1: keyboard, 2: mouse, 3: computer player (tank object decides). }
{#U22B7_08EC}
procedure U22B7_08EC(Kind, P: Integer);
var
  MouseWasOn: Boolean;
  Unused: Byte;
begin
  MouseWasOn := U27B1_0190;
  U27B1_014E;
  PScreen(SaveBuf_E496)^ := Screen;
  case Kind of
    1:
      begin
        while (Players_3F0E[P].f28 < 1) or (Players_3F0E[P].f28 > g_46B4) or
              (Players_3F0E[Players_3F0E[P].f28].f23 = 0) or
              (Players_3F0E[P].f28 = P) do
        begin
          Inc(Players_3F0E[P].f28);
          if Players_3F0E[P].f28 > g_46B4 then Players_3F0E[P].f28 := 1;
          if Players_3F0E[P].f28 < 1 then Players_3F0E[P].f28 := g_46B4;
        end;
        SetFillStyle(SolidFill, 0);
        Bar(0, 0, 320, 27);
        SetColor(13);
        Rectangle(0, 0, 319, 28);
        SetTextJustify(CenterText, TopText);
        SetColor(P + 19);
        OutTextXY(160, 4, Players_3F0E[P].Name + ': Guidance Type ' +
          U2918_02FE(Players_3F0E[P].f26));
        SetTextJustify(LeftText, TopText);
        KbdHead := KbdTail;            { flush keyboard buffer }
        repeat
          SetColor(P + 19);
          OutTextXY(70, 15, 'Current Target:');
          Bar(198, 15, 317, 23);
          SetColor(Players_3F0E[P].f28 + 19);
          OutTextXY(198, 15, Players_3F0E[Players_3F0E[P].f28].Name);
          repeat until KeyPressed;
          g_46C9 := UpCase(ReadKey);
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            repeat
              if g_46C9 = KeyRt_3718 then Inc(Players_3F0E[P].f28);
              if g_46C9 = KeyLt_3719 then Dec(Players_3F0E[P].f28);
              if Players_3F0E[P].f28 > g_46B4 then Players_3F0E[P].f28 := 1;
              if Players_3F0E[P].f28 < 1 then Players_3F0E[P].f28 := g_46B4;
            until (Players_3F0E[P].f28 <> P) and
                  (Players_3F0E[Players_3F0E[P].f28].f23 <> 0);
          end;
        until g_46C9 in [#13, ' '];
      end;
    2:
      begin
        SetFillStyle(SolidFill, 0);
        Bar(0, 0, 320, 27);
        SetColor(13);
        Rectangle(0, 0, 319, 28);
        SetTextJustify(CenterText, TopText);
        SetColor(P + 19);
        OutTextXY(160, 4, Players_3F0E[P].Name + ': Guidance Type ' +
          U2918_02FE(Players_3F0E[P].f26));
        OutTextXY(160, 15, 'Please click on target');
        SetTextJustify(LeftText, TopText);
        U2968_004D;
        g_462F := 0;
        repeat
          if U2968_0077(1) or U2968_0077(2) then
          begin
            g_4624 := U2918_022A;
            g_4626 := U2918_0256;
            U2968_005A;
            g_4628 := U2823_0BFF(g_4624, g_4626);
            U2968_004D;
            if (g_4628 in [20..g_46B4 + 19]) and
               (Players_3F0E[g_4628 - 19].f23 <> 0) then
            begin
              Players_3F0E[P].f28 := g_4628 - 19;
              g_462F := 1;
            end;
          end;
        until g_462F <> 0;
        U2968_005A;
      end;
    3:
      Players_3F0E[P].f28 := PComputer(Tanks_3EE2[P])^.GetTarget;
  end;
  Screen := PScreen(SaveBuf_E496)^;
  if not MouseWasOn then U27B1_010C;
end;

end.
