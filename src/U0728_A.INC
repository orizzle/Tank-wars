
{ 'YES' / 'NO' }
{#U0728_0007}
function YesNoStr(B: Boolean): string;
begin
  if B then YesNoStr := 'YES' else YesNoStr := 'NO';
end;

{ 'ON' / 'OFF' }
{#U0728_0043}
function OnOffStr(B: Boolean): string;
begin
  if B then OnOffStr := 'ON' else OnOffStr := 'OFF';
end;

{ create the AI object for player I according to its name }
{#U0728_0078}
procedure CreateAIPlayer(I: Integer);
begin
  if Players[I].Name = AINames[1] then Tanks[I] := New(PStupid, Init(I));
  if Players[I].Name = AINames[2] then Tanks[I] := New(PLobber, Init(I));
  if Players[I].Name = AINames[3] then Tanks[I] := New(PRifleman, Init(I));
  if Players[I].Name = AINames[4] then Tanks[I] := New(PLobShoot, Init(I));
  if Players[I].Name = AINames[5] then Tanks[I] := New(PWindless, Init(I));
  if Players[I].Name = AINames[6] then Tanks[I] := New(PTwanger, Init(I));
  if Players[I].Name = AINames[7] then Tanks[I] := New(PWindMaster, Init(I));
end;

{ reset player I to defaults }
{#U0728_0216}
procedure ResetPlayer(I: Integer);
var
  J: Integer;
begin
  FillChar(Players[I], SizeOf(TPlayer), 0);
  FillChar(ShotLogRecs[I], SizeOf(T7DA), 0);
  with Players[I] do
  begin
    SetPlayerNum(I, f00);
    Name := 'Player ' + IntToStr(I);
    Weapon := 1;
    f26 := 0;
    Ammo[0] := 100;
    Ammo[1] := GamesToPlay * 3;
    Ammo[11] := 10 * GamesToPlay;
    if Ammo[11] > 999 then Ammo[11] := 999;
    if I > NumPlayers then Men := 0 else Men := 100;
    f1D := 90;
    f1F := 1;
    f23 := 1;
    Team := I;
    case I of
      1: begin f60 := 1; f62 := $7FFF; f64 := $7FFF; end;
      2: begin f60 := $7FFF; f62 := 1; f64 := $7FFF; end;
      3: begin f60 := $7FFF; f62 := $7FFF; f64 := 1; end;
      4: begin f60 := 1; f62 := 1; f64 := $7FFF; end;
      5: begin f60 := $7FFF; f62 := 1; f64 := 1; end;
      6: begin f60 := 1; f62 := $7FFF; f64 := 1; end;
      7: begin f60 := 1; f62 := 1; f64 := 1; end;
      8: begin f60 := 1; f62 := 2; f64 := $7FFF; end;
      9: begin f60 := 1; f62 := $7FFF; f64 := 2; end;
      10: begin f60 := 1; f62 := 2; f64 := 2; end;
    end;
  end;
  Controls[I] := 1;
end;

{ mouse check at startup }
{#U0728_04D0}
procedure CheckMouse;
begin
  TextColor(14);
  Writeln('  Checking for Microsoft Compatible Mouse....');
  MouseIn := DetectMouse;
end;

{ CPU detection message }
{#U0728_05D8}
procedure ShowCpuType;
var
  Dummy: Integer;
begin
  TextMode(3);
  TextColor(9);
  CpuKind := CpuType;
  case CpuKind of
    $56: Writeln('8088/86 Processor Detected. Extended graphics disabled.');
    $BA: Writeln('80186 Detected (What a unique computer!)');
    $11E: Writeln('80286 Detected.');
    $182: Writeln('80386 (or better) detected.');
    -$11E: Writeln('80286 in protected mode detected');
    -$182: Writeln('80386 (or better) in protected mode detected.');
  end;
end;

{ init mouse cursor }
{#U0728_06B1}
procedure InitMouseCursor;
begin
  MouseSoftReset;
  SetMouseCursor(MouseCursors[0]);
end;

{ title box }
{#U0728_06D1}
procedure DrawTitleBox;
begin
  DrawPanel3D(10, 6, $136, $2A, $12, $0F, $11);
  SetColor(14);
  SetTextStyle(FontEuro, 0, 1);
  SetTextJustify(1, 1);
  OutTextXY($A3, $17, 'TANK WARS  ' + GameVersion);
  OutTextXY($A2, $16, 'TANK WARS  ' + GameVersion);
  OutTextXY($A1, $15, 'TANK WARS  ' + GameVersion);
  SetColor(12);
  OutTextXY($A0, $14, 'TANK WARS  ' + GameVersion);
end;

{ START button }
{#U0728_07CE}
procedure DrawStartButton;
begin
  DrawPanel3D($47, $AB, $F8, $C5, $12, $0F, $11);
  SetColor(14);
  SetTextStyle(FontEuro, 0, 1);
  SetTextJustify(1, 1);
  SetUserCharSize(1, 1, 3, 10);
  for LoopI := 1 to 5 do
  begin
    OutTextXY(LoopI + $A0 + 3, LoopI + $B8 + (-2), 'START');
    OutTextXY(LoopI + $A0 + 3, $B8 - LoopI + (-2), 'START');
    OutTextXY($A0 - LoopI + 3, LoopI + $B8 + (-2), 'START');
    OutTextXY($A0 - LoopI + 3, $B8 - LoopI + (-2), 'START');
  end;
  SetColor(12);
  OutTextXY($A3, $B6, 'START');
end;

{ 'Main Menu' header }
{#U0728_08E6}
procedure DrawMainMenuHeader;
begin
  DrawPanel3D($76, $3F, $CA, $4D, $12, $0F, $11);
  SetColor(1);
  SetTextStyle(0, 0, 1);
  SetTextJustify(1, 1);
  OutTextXY($A0, $46, 'Main Menu');
end;

{ "Effect / Flying" ON/OFF box }
{#U0728_09B5}
procedure SoundOptionsDialog;
var
  Buf: Pointer;
  Sel, Old, Hit: Integer;
  Done, MB1, MB2, Unused, KLt, KRt, KTog, Unused2: Boolean;
begin
  GetMem(Buf, $2EC);
  GetImage($21, $35, $6B, $57, Buf^);
  DrawPanel3D($23, $37, $69, $55, $12, $0F, $11);
  SetColor(0);
  SetTextJustify(0, 1);
  OutTextXY($28, $3E, 'Effect: ');
  OutTextXY($28, $4C, 'Flying: ');
  SetColor(14);
  OutTextXY($55, $3E, OnOffStr(Boolean(SoundOn)));
  OutTextXY($55, $4C, OnOffStr(Boolean(FlySound)));
  Sel := 0;
  Hit := -1;
  Done := False;
  repeat
    MB1 := False;
    MB2 := MB1;
    KLt := MB1;
    KRt := MB1;
    KTog := MB1;
    repeat
      DrawPlusMark($1D, 14 * Sel + $3E);
      DrawPlusMark($6F, 14 * Sel + $3E);
      ShowMouseCursor;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          KeyChar := ReadKey;
          if KeyChar in [' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if KeyChar in [#13, #27] then Hit := 2;
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            if (KeyChar = ScanUp) and (Sel = 1) then Dec(Sel);
            if (KeyChar = ScanDown) and (Sel = 0) then Inc(Sel);
            if KeyChar = ScanRight then
            begin
              Hit := Sel;
              KRt := True;
            end;
            if KeyChar = ScanLeft then
            begin
              Hit := Sel;
              KLt := True;
            end;
          end;
        end;
        if MouseBtnsDown(1) or MouseBtnsDown(2) then
        begin
          MB1 := MouseBtnsDown(1);
          MB2 := MouseBtnsDown(2);
          TmpX := MouseX;
          TmpY := MouseY;
          if (TmpX > $23) and (TmpX < $69) then
          begin
            if (TmpY > $39) and (TmpY <= $46) then Hit := 0
            else if (TmpY > $46) and (TmpY < $53) then Hit := 1
            else Hit := 2;
          end
          else Hit := 2;
          repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0);
      HideMouseCursor;
      ErasePlusMark($1D, 14 * Old + $3E, SaveBuf);
      ErasePlusMark($6F, 14 * Old + $3E, SaveBuf);
    until Hit in [0..2];
    SetFillStyle(1, $12);
    case Hit of
      0: begin
           if KRt or MB2 then SoundOn := 1;
           if KLt or MB1 then SoundOn := 0;
           if KTog then SoundOn := Byte(SoundOn = 0);
           Bar($55, $3A, $65, $42);
           OutTextXY($55, $3E, OnOffStr(Boolean(SoundOn)));
         end;
      1: begin
           if KRt or MB2 then FlySound := 1;
           if KLt or MB1 then FlySound := 0;
           if KTog then FlySound := Byte(FlySound = 0);
           Bar($55, $48, $65, $50);
           OutTextXY($55, $4C, OnOffStr(Boolean(FlySound)));
         end;
      2: Done := True;
    end;
    Hit := -1;
  until Done;
  PutImage($21, $35, Buf^, 0);
  FreeMem(Buf, $2EC);
end;

{ background type name }
{#U0728_0DEF}
function BackgroundName(N: Integer): string;
begin
  case N of
    0: BackgroundName := 'None';
    1: BackgroundName := 'Stars';
    2: BackgroundName := 'Bars';
    3: BackgroundName := 'Circles';
    4: BackgroundName := 'Spread';
    5: BackgroundName := 'Sky';
    6: BackgroundName := 'Static';
    7: BackgroundName := 'Rectangle';
    8: BackgroundName := 'Asterisk';
    9: BackgroundName := 'RND';
    10: BackgroundName := 'USER';
  end;
end;

{ wall type name }
{#U0728_0F3B}
function WallTypeName(N: Integer): string;
begin
  case N of
    0: WallTypeName := 'NO';
    1: WallTypeName := 'STICK';
    2: WallTypeName := 'ELASTIC';
    3: WallTypeName := 'ACCEL';
    4: WallTypeName := 'WARP';
    5: WallTypeName := 'RND';
  end;
end;

{ wind force name }
{#U0728_0FFC}
function WindForceName(N: Integer): string;
begin
  case N of
    0: WindForceName := 'None';
    1: WindForceName := 'Low';
    2: WindForceName := 'Norm';
    3: WindForceName := 'High';
    4: WindForceName := 'Gale';
    5: WindForceName := 'RND';
  end;
end;

{ "Game Options" box: 10 settings, changed with cursor keys / space / mouse }
{#U0728_1186}
procedure GameOptionsDialog;
var
  Buf: Pointer;
  Sel, Old, Hit: Integer;
  Done, MB1, MB2, Unused, KLt, KRt, KTog, Unused2: Boolean;
  OldVal, NewVal: Integer;
begin
  GetMem(Buf, $F64);
  GetImage($5D, $2D, $E3, $9B, Buf^);
  DrawPanel3D($5F, $2F, $E1, $99, $12, $0F, $11);
  SetColor(0);
  SetTextJustify(0, 1);
  OutTextXY($64, $34, 'Crumble Percent:');
  OutTextXY($64, $3E, 'Walls:');
  OutTextXY($64, $48, 'Trail Visible:');
  OutTextXY($64, $52, 'Ball Visible:');
  OutTextXY($64, $5C, 'Tanks Fall:');
  OutTextXY($64, $66, 'Computer Can Buy:');
  OutTextXY($64, $70, 'Background:');
  OutTextXY($64, $7A, 'Cycle Delay:');
  OutTextXY($64, $84, 'Wind Force:');
  OutTextXY($64, $8E, 'Team Play:');
  SetTextJustify(2, 1);
  SetColor(14);
  OutTextXY($DF, $34, IntToStr(CrumblePct) + '%');
  OutTextXY($DF, $3E, WallTypeName(WallControl));
  OutTextXY($DF, $48, YesNoStr(Boolean(ShotTrail)));
  OutTextXY($DF, $52, YesNoStr(InvisoBall = 0));
  OutTextXY($DF, $5C, YesNoStr(Boolean(TanksFall)));
  OutTextXY($DF, $66, YesNoStr(Boolean(CompuBuy)));
  OutTextXY($DF, $70, BackgroundName(BackControl));
  OutTextXY($DF, $7A, IntToStr(PalSpeed));
  OutTextXY($DF, $84, WindForceName(WindControl));
  OutTextXY($DF, $8E, YesNoStr(Boolean(TeamPlay)));
  Sel := 0;
  Hit := -1;
  Done := False;
  repeat
    MB1 := False;
    MB2 := MB1;
    KLt := MB1;
    KRt := MB1;
    KTog := MB1;
    repeat
      DrawPlusMark($59, 10 * Sel + $34);
      DrawPlusMark($E7, 10 * Sel + $34);
      ShowMouseCursor;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          KeyChar := ReadKey;
          if KeyChar in [' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if KeyChar in [#13, #27] then Hit := 10;
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            if (KeyChar = ScanUp) and (Sel > 0) then Dec(Sel);
            if (KeyChar = ScanDown) and (Sel < 9) then Inc(Sel);
            if KeyChar = ScanRight then
            begin
              Hit := Sel;
              KRt := True;
            end;
            if KeyChar = ScanLeft then
            begin
              Hit := Sel;
              KLt := True;
            end;
          end;
        end;
        if MouseBtnsDown(1) or MouseBtnsDown(2) then
        begin
          MB1 := MouseBtnsDown(1);
          MB2 := MouseBtnsDown(2);
          TmpX := MouseX;
          TmpY := MouseY;
          if (TmpX > $5F) and (TmpX < $E1) then
          begin
            if (TmpY > $31) and (TmpY <= $3A) then Hit := 0
            else if (TmpY > $3A) and (TmpY <= $44) then Hit := 1
            else if (TmpY > $44) and (TmpY <= $4E) then Hit := 2
            else if (TmpY > $4E) and (TmpY <= $58) then Hit := 3
            else if (TmpY > $58) and (TmpY <= $62) then Hit := 4
            else if (TmpY > $62) and (TmpY <= $6C) then Hit := 5
            else if (TmpY > $6C) and (TmpY <= $76) then Hit := 6
            else if (TmpY > $76) and (TmpY <= $80) then Hit := 7
            else if (TmpY > $80) and (TmpY <= $8A) then Hit := 8
            else if (TmpY > $8A) and (TmpY < $99) then Hit := 9
            else Hit := 10;
          end
          else Hit := 10;
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0);
      HideMouseCursor;
      ErasePlusMark($59, 10 * Old + $34, SaveBuf);
      ErasePlusMark($E7, 10 * Old + $34, SaveBuf);
    until Hit in [0..10];
    SetColor(14);
    SetFillStyle(1, $12);
    OldVal := 0;
    NewVal := 0;
    case Hit of
      0: begin
           OldVal := CrumblePct;
           if (KRt or MB2) and (CrumblePct < 100) then Inc(CrumblePct);
           if (KLt or MB1) and (CrumblePct > 0) then Dec(CrumblePct);
           if KTog then CrumblePct := CrumblePct + 5;
           if CrumblePct > 100 then CrumblePct := CrumblePct - 100;
           Bar($C3, $30, $E1, $38);
           OutTextXY($DF, $34, IntToStr(CrumblePct) + '%');
           NewVal := CrumblePct;
         end;
      1: begin
           OldVal := WallControl;
           if (KRt or MB2) and (WallControl < 5) then Inc(WallControl);
           if (KLt or MB1) and (WallControl > 0) then Dec(WallControl);
           if KTog then WallControl := (WallControl + 1) mod 6;
           Bar($AF, $3A, $E1, $42);
           OutTextXY($DF, $3E, WallTypeName(WallControl));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := WallControl;
         end;
      2: begin
           OldVal := ShotTrail;
           if KRt or MB2 then ShotTrail := 1;
           if KLt or MB1 then ShotTrail := 0;
           if KTog then ShotTrail := Byte(ShotTrail = 0);
           Bar($C3, $44, $E1, $4C);
           OutTextXY($DF, $48, YesNoStr(Boolean(ShotTrail)));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := ShotTrail;
         end;
      3: begin
           OldVal := Byte(InvisoBall = 0);
           if KRt or MB2 then InvisoBall := 0;
           if KLt or MB1 then InvisoBall := 1;
           if KTog then InvisoBall := Byte(InvisoBall = 0);
           Bar($C3, $4E, $E1, $56);
           OutTextXY($DF, $52, YesNoStr(InvisoBall = 0));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := Byte(InvisoBall = 0);
         end;
      4: begin
           OldVal := TanksFall;
           if KRt or MB2 then TanksFall := 1;
           if KLt or MB1 then TanksFall := 0;
           if KTog then TanksFall := Byte(TanksFall = 0);
           Bar($C3, $58, $E1, $60);
           OutTextXY($DF, $5C, YesNoStr(Boolean(TanksFall)));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := TanksFall;
         end;
      5: begin
           OldVal := CompuBuy;
           if KRt or MB2 then CompuBuy := 1;
           if KLt or MB1 then CompuBuy := 0;
           if KTog then CompuBuy := Byte(CompuBuy = 0);
           Bar($C3, $62, $E1, $6A);
           OutTextXY($DF, $66, YesNoStr(Boolean(CompuBuy)));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := CompuBuy;
         end;
      6: begin
           OldVal := BackControl;
           if (KRt or MB2) and (BackControl < 10) then Inc(BackControl);
           if (KLt or MB1) and (BackControl > 0) then Dec(BackControl);
           if KTog then BackControl := (BackControl + 1) mod 11;
           Bar($A5, $6C, $E1, $76);
           OutTextXY($DF, $70, BackgroundName(BackControl));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := BackControl;
         end;
      7: begin
           OldVal := PalSpeed;
           if (KRt or MB2) and (PalSpeed < 250) then Inc(PalSpeed);
           if (KLt or MB1) and (PalSpeed > 0) then Dec(PalSpeed);
           if KTog then
             if PalSpeed > 0 then PalSpeed := 0 else PalSpeed := 1;
           GetPalCycle(PalCycle);
           PalCycle.Speed := PalSpeed;
           SetPalCycle(PalCycle);
           Bar($C3, $76, $E1, $7E);
           OutTextXY($DF, $7A, IntToStr(PalSpeed));
           NewVal := PalSpeed;
         end;
      8: begin
           OldVal := WindControl;
           if (KRt or MB2) and (WindControl < 5) then Inc(WindControl);
           if (KLt or MB1) and (WindControl > 0) then Dec(WindControl);
           if KTog then Inc(WindControl);
           if WindControl > 5 then WindControl := 0;
           Bar($C3, $80, $E1, $8A);
           OutTextXY($DF, $84, WindForceName(WindControl));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := WindControl;
         end;
      9: begin
           OldVal := TeamPlay;
           if KRt or MB2 then TeamPlay := 1;
           if KLt or MB1 then TeamPlay := 0;
           if KTog then TeamPlay := Byte(TeamPlay = 0);
           Bar($C3, $8A, $E1, $92);
           OutTextXY($DF, $8E, YesNoStr(Boolean(TeamPlay)));
           repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
           NewVal := TeamPlay;
         end;
      10: Done := True;
    end;
    Hit := -1;
  until Done;
  PutImage($5D, $2D, Buf^, 0);
  FreeMem(Buf, $F64);
end;

{ main menu: Sound Options / Game Options / Players / Games / START,
  plus the "Load Game" button (sets LoadRequested) }
{#U0728_1DD5}
procedure RunMainMenu;
var
  Sel, Old, OldVal, Hit: Integer;
  KLt, KRt, KTog, MB1, MB2, Done: Boolean;
begin
  DrawPanel3D($76, $55, $CA, $BB, $12, $0F, $11);
  SetColor(10);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  DrawPanel3D($7A, $5B, $C6, $65, 2, $11, $0F);
  CopyBar($7A, $5B, $C6, $65, SaveBuf);
  SetTextJustify(1, 1);
  OutTextXY($A0, $5F, 'Sound Options');
  DrawPanel3D($7A, $6F, $C6, $79, 2, $11, $0F);
  CopyBar($7A, $6F, $C6, $79, SaveBuf);
  SetTextJustify(1, 1);
  OutTextXY($A0, $73, 'Game Options');
  DrawPanel3D($7A, $83, $C6, $8D, 2, $11, $0F);
  CopyBar($7A, $83, $C6, $8D, SaveBuf);
  SetTextJustify(1, 1);
  OutTextXY($A0, $87, 'Players: ');
  SetColor(14);
  OutTextXY(TextWidth('Players: ') div 2 + $A0, $87, IntToStr(NumPlayers));
  DrawPanel3D($7A, $97, $C6, $A1, 2, $11, $0F);
  CopyBar($7A, $97, $C6, $A1, SaveBuf);
  SetTextJustify(1, 1);
  SetColor(10);
  OutTextXY($A0, $9B, 'Games: ');
  SetColor(14);
  OutTextXY(TextWidth('Games: ') div 2 + $A0, $9B, IntToStr(GamesToPlay));
  DrawPanel3D($7A, $AB, $C6, $B5, 2, $11, $0F);
  CopyBar($7A, $AB, $C6, $B5, SaveBuf);
  SetTextJustify(1, 1);
  SetColor(13);
  OutTextXY($A0, $AF, 'START');
  SetTextJustify(1, 1);
  DrawPanel3D($14, $91, $50, $9B, $12, $0F, $11);
  SetColor(10);
  OutTextXY($32, $95, 'Load Game');
  SetColor(12);
  OutTextXY($32, $95, 'L        ');
  Sel := 0;
  Old := 0;
  Hit := -1;
  Done := False;
  repeat
    MB1 := False;
    MB2 := MB1;
    KLt := MB1;
    KRt := MB1;
    KTog := MB1;
    repeat
      DrawPlusMark($70, 20 * Sel + $5F);
      DrawPlusMark($D0, 20 * Sel + $5F);
      ShowMouseCursor;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          KeyChar := ReadKey;
          if KeyChar in [#13, ' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if KeyChar in ['L', 'l'] then LoadRequested := 1;
          if KeyChar = #0 then
          begin
            KeyChar := ReadKey;
            if (KeyChar = ScanUp) and (Sel > 0) then Dec(Sel);
            if (KeyChar = ScanDown) and (Sel < 4) then Inc(Sel);
            if KeyChar = ScanRight then
            begin
              KRt := True;
              Hit := Sel;
            end;
            if KeyChar = ScanLeft then
            begin
              KLt := True;
              Hit := Sel;
            end;
          end;
        end;
        if MouseBtnsDown(1) or MouseBtnsDown(2) then
        begin
          TmpX := MouseX;
          TmpY := MouseY;
          MB1 := MouseBtnsDown(1);
          MB2 := MouseBtnsDown(2);
          if (TmpX > $7A) and (TmpX < $C6) then
          begin
            if (TmpY >= $5B) and (TmpY <= $65) then Hit := 0;
            if (TmpY >= $6F) and (TmpY <= $79) then Hit := 1;
            if (TmpY >= $83) and (TmpY <= $8D) then Hit := 2;
            if (TmpY >= $97) and (TmpY <= $A1) then Hit := 3;
            if (TmpY >= $AB) and (TmpY <= $B5) then Hit := 4;
            repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
          end;
          if (TmpX > $14) and (TmpX < $50) and (TmpY > $91) and (TmpY < $9B) then
            LoadRequested := 1;
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0) or (LoadRequested <> 0);
      HideMouseCursor;
      ErasePlusMark($70, 20 * Old + $5F, SaveBuf);
      ErasePlusMark($D0, 20 * Old + $5F, SaveBuf);
    until (Hit in [0..4]) or (LoadRequested <> 0);
    SetColor(14);
    if LoadRequested = 0 then
      case Hit of
        0: if KTog or MB1 or MB2 then SoundOptionsDialog;
        1: if KTog or MB1 or MB2 then GameOptionsDialog;
        2: begin
             OldVal := NumPlayers;
             if (KRt or MB2) and (NumPlayers < 10) then Inc(NumPlayers);
             if (KLt or MB1) and (NumPlayers > 2) then Dec(NumPlayers);
             if KTog then Inc(NumPlayers);
             if NumPlayers > 10 then NumPlayers := 2;
             SetTextJustify(1, 1);
             CopyBar(TextWidth('Players: ') div 2 + $A0 - 4, $85,
                        TextWidth('Players: ') div 2 + $A0 + 10, $8B, SaveBuf);
             OutTextXY(TextWidth('Players: ') div 2 + $A0, $87, IntToStr(NumPlayers));
           end;
        3: begin
             OldVal := GamesToPlay;
             if KRt and (GamesToPlay < 99) then Inc(GamesToPlay);
             if MB2 and (GamesToPlay < 99) then Inc(GamesToPlay, 5);
             if KLt and (GamesToPlay > 1) then Dec(GamesToPlay);
             if MB1 and (GamesToPlay > 1) then Dec(GamesToPlay, 5);
             if GamesToPlay > 99 then GamesToPlay := 99;
             if GamesToPlay < 1 then GamesToPlay := 1;
             if KTog then Inc(GamesToPlay, 5);
             if GamesToPlay > 99 then Dec(GamesToPlay, 99);
             SetTextJustify(1, 1);
             CopyBar(TextWidth('Games: ') div 2 + $A0 - 5, $99,
                        TextWidth('Games: ') div 2 + $A0 + 15, $9F, SaveBuf);
             OutTextXY(TextWidth('Games: ') div 2 + $A0, $9B, IntToStr(GamesToPlay));
           end;
        4: Done := True;
      end;
    Hit := -1;
  until Done or (LoadRequested <> 0);
end;

{ "Team Setup" screen: assign each player to a team (1..number of players);
  cancels team play (TeamPlay := 0) unless at least one team has 2+ members }
{#U0728_2609}
procedure TeamSetupScreen;
var
  Sel, Old: Integer;
  Down, Up: Boolean;
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
begin
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 0);
  DrawPanel3D($3C, $3E, $104, $B6, $12, $0F, $11);
  DrawPanel3D($82, $2F, $BE, $39, $12, $0F, $11);
  SetColor(10);
  OutTextXY($A0, $37, 'Team Setup');
  DrawPanel3D($82, $BB, $BE, $C5, $12, $0F, $11);
  SetColor(5);
  SetTextJustify(1, 2);
  OutTextXY($A0, $BA, '-- Done --');
  SetTextJustify(0, 2);
  SetColor(14);
  OutTextXY($40, $3E, 'Team # -->');
  SetTextJustify(1, 2);
  for LoopI := 1 to 10 do
  begin
    if LoopI > NumPlayers then SetColor(0);
    OutTextXY(10 * LoopI + $8C, $3E, IntToStr(LoopI));
    for LoopJ := 1 to NumPlayers do
      if Players[LoopJ].Team = LoopI then
      begin
        Players[LoopJ].X := 10 * LoopI + $8C;
        Players[LoopJ].Y := 10 * LoopJ + $47;
        Players[LoopJ].Men := 100;
        DrawTank(LoopJ);
      end;
  end;
  SetTextJustify(0, 2);
  for LoopI := 1 to 10 do
  begin
    SetPlayerColor(100, Players[LoopI]);
    if LoopI > NumPlayers then SetColor(0) else SetColor(LoopI + 19);
    OutTextXY($40, 10 * LoopI + $3E, Players[LoopI].Name);
  end;
  Sel := 1;
  DoneFlag := 0;
  RGBHook(19, 63, 63, 63);
  repeat
    DrawPlusMark($37, 10 * Sel + $44);
    Old := Sel;
    ShowMouseCursor;
    Down := False;
    Up := False;
    repeat
      if KeyPressed then
      begin
        KeyChar := UpCase(ReadKey);
        if KeyChar in [#13, #27, 'D'] then
        begin
          Sel := 11;
          Down := True;
        end;
        if KeyChar = #0 then
        begin
          KeyChar := ReadKey;
          if (KeyChar = ScanUp) and (Sel > 1) then Dec(Sel);
          if (KeyChar = ScanDown) and (Sel < NumPlayers) then Inc(Sel);
          if KeyChar = ScanRight then Up := True;
          if KeyChar = ScanLeft then Down := True;
        end;
      end;
      if MouseBtnsDown(1) or MouseBtnsDown(2) then
      begin
        TmpX := MouseX;
        TmpY := MouseY;
        if (TmpX > $3C) and (TmpX < $104) then
          for LoopI := 1 to NumPlayers do
            if (10 * LoopI + $47 >= TmpY) and (10 * LoopI + $40 <= TmpY) then
            begin
              Sel := LoopI;
              if MouseBtnsDown(1) then Down := True;
              if MouseBtnsDown(2) then Up := True;
              Delay(40);
            end;
        if (TmpX > $82) and (TmpX < $BE) and (TmpY > $BB) and (TmpY < $C5) then
        begin
          Sel := 11;
          Down := True;
        end;
      end;
    until (Old <> Sel) or Down or Up;
    HideMouseCursor;
    ErasePlusMark($37, 10 * Old + $44, SaveBuf);
    if Down or Up then
      case Sel of
        1..10:
          begin
            FillBar(10 * Players[Sel].Team + $8C - 5, 10 * Sel + $47,
                       10 * Players[Sel].Team + $8C + 5, 10 * Sel + $3F, $12);
            if Down and (Players[Sel].Team > 1) then Dec(Players[Sel].Team);
            if Up and (Players[Sel].Team < NumPlayers) then Inc(Players[Sel].Team);
            Players[Sel].X := 10 * Players[Sel].Team + $8C;
            Players[Sel].Y := 10 * Sel + $47;
            DrawTank(Sel);
          end;
        11: DoneFlag := 1;
      end;
  until DoneFlag <> 0;
  DoneFlag := 0;
  for LoopI := 1 to NumPlayers do
    if Players[LoopI].Team <> Players[1].Team then DoneFlag := 1;
  TmpR := 0;
  for LoopI := 1 to NumPlayers do
  begin
    LoopK := 0;
    for LoopJ := 1 to NumPlayers do
      if Players[LoopJ].Team = LoopI then Inc(LoopK);
    if LoopK > TmpR then TmpR := LoopK;
  end;
  if TmpR < 2 then DoneFlag := 0;
  if DoneFlag = 0 then
  begin
    repeat until not MouseBtnsDown(1) and not MouseBtnsDown(2);
    SetColor(6);
    DrawPanel3D($5A, $72, $E6, $8E, $12, $0F, $11);
    SetTextJustify(1, 2);
    OutTextXY($A0, $70, 'Team play canceled due');
    OutTextXY($A0, $7A, 'to extreme stupidity.');
    SetTextStyle(FontTiny, 0, 1);
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 2);
    SetColor(4);
    OutTextXY($A0, $81, 'PRESS ANY KEY TO CONTINUE...');
    repeat until KeyPressed or MouseBtnsDown(1) or MouseBtnsDown(2);
    KbdHead := KbdTail;   { flush BIOS keyboard buffer }
    TeamPlay := 0;
    for LoopI := 1 to 10 do Players[LoopI].Team := LoopI;
  end;
  if DoneFlag <> 0 then ;
end;

{ edit the name of team T in a small dialog box }
procedure EditTeamName(T: Integer);
var
  Pos, NewPos, J, Unused1, Unused2: Integer;
  Done, Changed: Boolean;

  { draw the block cursor under character Pos }
  {#U0728_2D41} procedure DrawTeamNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + $8F - 1, $64, (Pos - 1) * 6 + $8F + 4, $6E, $12);
    DrawRect((Pos - 1) * 6 + $8F, $65, (Pos - 1) * 6 + $8F + 3, $6D, $12);
    DrawRect((Pos - 1) * 6 + $8F + 1, $66, (Pos - 1) * 6 + $8F + 2, $6C, $12);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + $8F, $68, Copy(Teams[T].Name, Pos, 1));
    CopyBar((Pos - 1) * 6 + $8F - 1, $6D, (Pos - 1) * 6 + $8F + 4, $6E, SaveBuf);
  end;

  { remove the cursor again }
  {#U0728_2E8E} procedure HideTeamNameCursor;
  begin
    DrawRect((Pos - 1) * 6 + $8F - 1, $64, (Pos - 1) * 6 + $8F + 4, $6E, $12);
    DrawRect((Pos - 1) * 6 + $8F, $65, (Pos - 1) * 6 + $8F + 3, $6D, $12);
    DrawRect((Pos - 1) * 6 + $8F + 1, $66, (Pos - 1) * 6 + $8F + 2, $6C, $12);
    SetColor(0);
    OutTextXY((Pos - 1) * 6 + $8F, $68, Copy(Teams[T].Name, Pos, 1));
  end;

{#U0728_302C}
begin
  if Length(Teams[T].Name) < 19 then
    for J := Length(Teams[T].Name) + 1 to 13 do Teams[T].Name[J] := ' ';
  DrawPanel3D($87, $55, $EB, $73, $12, $0F, $11);
  SetTextJustify(0, 2);
  SetUserCharSize(1, 1, 1, 1);
  SetColor(5);
  OutTextXY($8A, $55, 'New Team Name:');
  DrawPanel3D($8C, $64, $E6, $6E, $12, $11, $0F);
  SetTextJustify(0, 1);
  SetColor(0);
  for Pos := 1 to Length(Teams[T].Name) do
    OutTextXY((Pos - 1) * 6 + $8F, $68, Copy(Teams[T].Name, Pos, 1));
  Inc(Teams[T].Name[0]);
  Pos := Length(Teams[T].Name);
  Done := False;
  repeat
    DrawTeamNameCursor;
    Changed := False;
    repeat
      repeat until KeyPressed;
      KeyChar := ReadKey;
      if (KeyChar in [#8]) and (Pos > 1) then
      begin
        NewPos := Pos - 1;
        Teams[T].Name[NewPos] := ' ';
        Changed := True;
      end;
      if KeyChar in [#13, #27] then
      begin
        Done := True;
        Changed := True;
      end;
      if KeyChar in [' '..'}'] then
      begin
        Teams[T].Name[Pos] := KeyChar;
        Changed := True;
        NewPos := Pos + 1;
        if Length(Teams[T].Name) < NewPos then Inc(Teams[T].Name[0]);
      end;
      if KeyChar = #0 then
      begin
        KeyChar := ReadKey;
        if KeyChar = 'G' then            { Home: clear }
        begin
          for Pos := Length(Teams[T].Name) downto 1 do
          begin
            Teams[T].Name[Pos] := ' ';
            DrawTeamNameCursor;
            HideTeamNameCursor;
          end;
          Teams[T].Name := '  ';
          NewPos := 1;
        end;
        if KeyChar = 'S' then            { Del }
        begin
          Teams[T].Name[Pos] := ' ';
          Changed := True;
          NewPos := Pos;
        end;
        if KeyChar = 'O' then            { End }
        begin
          Changed := True;
          NewPos := Length(Teams[T].Name);
        end;
        if (KeyChar = ScanLeft) and (Pos > 1) then
        begin
          NewPos := Pos - 1;
          Changed := True;
        end;
        if (KeyChar = ScanRight) and (Length(Teams[T].Name) > Pos) then
        begin
          NewPos := Pos + 1;
          Changed := True;
        end;
      end;
    until Changed = True;
    if NewPos > 13 then NewPos := 13;
    if Length(Teams[T].Name) > 13 then Teams[T].Name[0] := #13;
    HideTeamNameCursor;
    Pos := NewPos;
  until Done;
  while (Teams[T].Name[Length(Teams[T].Name)] in [#0, ' ']) and
        (Length(Teams[T].Name) > 0) do
    Dec(Teams[T].Name[0]);
end;

{ build the team table from the players' team numbers; show each team,
  let humans name their team, give computer-only teams a random name }
{#U0728_3449}
procedure BuildTeams;
var
  T, P: Integer;
begin
  FillChar(Teams, SizeOf(Teams), 0);
  LoopK := 0;
  for LoopI := 1 to NumPlayers do
  begin
    Teams[LoopI].f0E := 1;
    for LoopJ := 1 to NumPlayers do
      if Players[LoopJ].Team = LoopI then
      begin
        Inc(Teams[LoopI].f0F);
        if Controls[LoopJ] <> 3 then Teams[LoopI].f0E := 0;
      end;
    if Teams[LoopI].f0F <> 0 then Inc(LoopK);
    Teams[LoopI].Name := 'Team ' + IntToStr(LoopK);
    if Teams[LoopI].f0F = 1 then
      for LoopJ := 1 to NumPlayers do
        if Players[LoopJ].Team = LoopI then
          Teams[LoopI].Name := Players[LoopJ].Name;
  end;
  for T := 1 to NumPlayers do
    if Teams[T].f0F > 0 then
    begin
      DrawPanel3D($0A, $32, $6E, $3C, $12, $0F, $11);
      SetTextStyle(2, 0, 4);
      SetUserCharSize(1, 1, 1, 1);
      SetTextJustify(0, 2);
      SetColor(6);
      OutTextXY($0F, $32, 'Team #' + IntToStr(T) + ':');
      SetTextJustify(0, 2);
      LoopK := 0;
      for P := 1 to NumPlayers do
        if Players[P].Team = T then
        begin
          Inc(LoopK);
          SetColor(P + 19);
          DrawPanel3D($14, 15 * LoopK + $34, $78, 15 * LoopK + $34 + 10, $12, $0F, $11);
          OutTextXY($19, 15 * LoopK + $33, Players[P].Name);
        end;
      if Teams[T].f0E = 0 then
        EditTeamName(T)
      else if Teams[T].f0F > 1 then
        repeat
          DoneFlag2 := 1;
          case Random(11) of
            0: Teams[T].Name := 'Bushwackers';
            1: Teams[T].Name := 'Crazy CPUs';
            2: Teams[T].Name := 'Tank Trashers';
            3: Teams[T].Name := 'Studs';
            4: Teams[T].Name := 'Human Mashers';
            5: Teams[T].Name := 'Crackshots';
            6: Teams[T].Name := 'Dungheaps';
            7: Teams[T].Name := 'Ugly Ducks';
            8: Teams[T].Name := 'Martians';
            9: Teams[T].Name := 'Gravy';
            10: Teams[T].Name := 'Boneheads';
          end;
          for LoopJ := 1 to NumPlayers do
            if (Teams[T].Name = Teams[LoopJ].Name) and (T <> LoopJ) then
              DoneFlag2 := 0;
        until DoneFlag2 <> 0;
      LoopK := 0;
      for P := 1 to NumPlayers do
        if Players[P].Team = T then
        begin
          Inc(LoopK);
          CopyBar($12, 15 * LoopK + $34 - 2, $7A, 15 * LoopK + $34 + 10 + 2, SaveBuf);
        end;
    end;
  for TmpX := $67 to $FA do
    CopyLine(TmpX, 0, TmpX, $C7, SaveBuf);
end;


