
type
  T7DA = array[0..$7D9] of Byte;

var
  Rec_495A: array[0..10] of T7DA absolute g_495A;

{ 'YES' / 'NO' }
{#U0728_0007}
function U0728_0007(B: Boolean): string;
begin
  if B then U0728_0007 := 'YES' else U0728_0007 := 'NO';
end;

{ 'ON' / 'OFF' }
{#U0728_0043}
function U0728_0043(B: Boolean): string;
begin
  if B then U0728_0043 := 'ON' else U0728_0043 := 'OFF';
end;

{ create the AI object for player I according to its name }
{#U0728_0078}
procedure U0728_0078(I: Integer);
begin
  if Players_3F0E[I].Name = AINames_007C[1] then Tanks_3EE2[I] := New(PStupid, Init(I));
  if Players_3F0E[I].Name = AINames_007C[2] then Tanks_3EE2[I] := New(PLobber, Init(I));
  if Players_3F0E[I].Name = AINames_007C[3] then Tanks_3EE2[I] := New(PRifleman, Init(I));
  if Players_3F0E[I].Name = AINames_007C[4] then Tanks_3EE2[I] := New(PLobShoot, Init(I));
  if Players_3F0E[I].Name = AINames_007C[5] then Tanks_3EE2[I] := New(PWindless, Init(I));
  if Players_3F0E[I].Name = AINames_007C[6] then Tanks_3EE2[I] := New(PTwanger, Init(I));
  if Players_3F0E[I].Name = AINames_007C[7] then Tanks_3EE2[I] := New(PWindMaster, Init(I));
end;

{ reset player I to defaults }
{#U0728_0216}
procedure U0728_0216(I: Integer);
var
  J: Integer;
begin
  FillChar(Players_3F0E[I], SizeOf(TPlayer), 0);
  FillChar(Rec_495A[I], SizeOf(T7DA), 0);
  with Players_3F0E[I] do
  begin
    U26A9_0165(I, f00);
    Name := 'Player ' + U2918_02FE(I);
    Weapon := 1;
    f26 := 0;
    Ammo[0] := 100;
    Ammo[1] := g_E77C * 3;
    Ammo[11] := 10 * g_E77C;
    if Ammo[11] > 999 then Ammo[11] := 999;
    if I > g_46B4 then Men := 0 else Men := 100;
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
  Control_E480[I] := 1;
end;

{ mouse check at startup }
{#U0728_04D0}
procedure U0728_04D0;
begin
  TextColor(14);
  Writeln('  Checking for Microsoft Compatible Mouse....');
  g_E78B := U2968_003B;
end;

{ CPU detection message }
{#U0728_05D8}
procedure U0728_05D8;
var
  Dummy: Integer;
begin
  TextMode(3);
  TextColor(9);
  g_4656 := U2918_04A3;
  case g_4656 of
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
procedure U0728_06B1;
begin
  U2968_00D7;
  U2968_0000(MouseCursors_3730[0]);
end;

{ title box }
{#U0728_06D1}
procedure U0728_06D1;
begin
  U0098_028C(10, 6, $136, $2A, $12, $0F, $11);
  SetColor(14);
  SetTextStyle(g_E7E2, 0, 1);
  SetTextJustify(1, 1);
  OutTextXY($A3, $17, 'TANK WARS  ' + Version_0056);
  OutTextXY($A2, $16, 'TANK WARS  ' + Version_0056);
  OutTextXY($A1, $15, 'TANK WARS  ' + Version_0056);
  SetColor(12);
  OutTextXY($A0, $14, 'TANK WARS  ' + Version_0056);
end;

{ START button }
{#U0728_07CE}
procedure U0728_07CE;
begin
  U0098_028C($47, $AB, $F8, $C5, $12, $0F, $11);
  SetColor(14);
  SetTextStyle(g_E7E2, 0, 1);
  SetTextJustify(1, 1);
  SetUserCharSize(1, 1, 3, 10);
  for g_461E := 1 to 5 do
  begin
    OutTextXY(g_461E + $A0 + 3, g_461E + $B8 + (-2), 'START');
    OutTextXY(g_461E + $A0 + 3, $B8 - g_461E + (-2), 'START');
    OutTextXY($A0 - g_461E + 3, g_461E + $B8 + (-2), 'START');
    OutTextXY($A0 - g_461E + 3, $B8 - g_461E + (-2), 'START');
  end;
  SetColor(12);
  OutTextXY($A3, $B6, 'START');
end;

{ 'Main Menu' header }
{#U0728_08E6}
procedure U0728_08E6;
begin
  U0098_028C($76, $3F, $CA, $4D, $12, $0F, $11);
  SetColor(1);
  SetTextStyle(0, 0, 1);
  SetTextJustify(1, 1);
  OutTextXY($A0, $46, 'Main Menu');
end;

{ "Effect / Flying" ON/OFF box }
{#U0728_09B5}
procedure U0728_09B5;
var
  Buf: Pointer;
  Sel, Old, Hit: Integer;
  Done, MB1, MB2, Unused, KLt, KRt, KTog, Unused2: Boolean;
begin
  GetMem(Buf, $2EC);
  GetImage($21, $35, $6B, $57, Buf^);
  U0098_028C($23, $37, $69, $55, $12, $0F, $11);
  SetColor(0);
  SetTextJustify(0, 1);
  OutTextXY($28, $3E, 'Effect: ');
  OutTextXY($28, $4C, 'Flying: ');
  SetColor(14);
  OutTextXY($55, $3E, U0728_0043(Boolean(g_E788)));
  OutTextXY($55, $4C, U0728_0043(Boolean(g_E787)));
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
      U0098_03A8($1D, 14 * Sel + $3E);
      U0098_03A8($6F, 14 * Sel + $3E);
      U2968_004D;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          g_46C9 := ReadKey;
          if g_46C9 in [' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if g_46C9 in [#13, #27] then Hit := 2;
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            if (g_46C9 = KeyUp_3716) and (Sel = 1) then Dec(Sel);
            if (g_46C9 = KeyDn_3717) and (Sel = 0) then Inc(Sel);
            if g_46C9 = KeyRt_3718 then
            begin
              Hit := Sel;
              KRt := True;
            end;
            if g_46C9 = KeyLt_3719 then
            begin
              Hit := Sel;
              KLt := True;
            end;
          end;
        end;
        if U2968_0077(1) or U2968_0077(2) then
        begin
          MB1 := U2968_0077(1);
          MB2 := U2968_0077(2);
          g_4624 := U2918_022A;
          g_4626 := U2918_0256;
          if (g_4624 > $23) and (g_4624 < $69) then
          begin
            if (g_4626 > $39) and (g_4626 <= $46) then Hit := 0
            else if (g_4626 > $46) and (g_4626 < $53) then Hit := 1
            else Hit := 2;
          end
          else Hit := 2;
          repeat until not U2968_0077(1) and not U2968_0077(2);
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0);
      U2968_005A;
      U0098_03F4($1D, 14 * Old + $3E, SaveBuf_E496);
      U0098_03F4($6F, 14 * Old + $3E, SaveBuf_E496);
    until Hit in [0..2];
    SetFillStyle(1, $12);
    case Hit of
      0: begin
           if KRt or MB2 then g_E788 := 1;
           if KLt or MB1 then g_E788 := 0;
           if KTog then g_E788 := Byte(g_E788 = 0);
           Bar($55, $3A, $65, $42);
           OutTextXY($55, $3E, U0728_0043(Boolean(g_E788)));
         end;
      1: begin
           if KRt or MB2 then g_E787 := 1;
           if KLt or MB1 then g_E787 := 0;
           if KTog then g_E787 := Byte(g_E787 = 0);
           Bar($55, $48, $65, $50);
           OutTextXY($55, $4C, U0728_0043(Boolean(g_E787)));
         end;
      2: Done := True;
    end;
    Hit := -1;
  until Done;
  PutImage($21, $35, Buf^, 0);
  FreeMem(Buf, $2EC);
end;

{#U0728_0DEF}
function U0728_0DEF(N: Integer): string;
begin
  case N of
    0: U0728_0DEF := 'None';
    1: U0728_0DEF := 'Stars';
    2: U0728_0DEF := 'Bars';
    3: U0728_0DEF := 'Circles';
    4: U0728_0DEF := 'Spread';
    5: U0728_0DEF := 'Sky';
    6: U0728_0DEF := 'Static';
    7: U0728_0DEF := 'Rectangle';
    8: U0728_0DEF := 'Asterisk';
    9: U0728_0DEF := 'RND';
    10: U0728_0DEF := 'USER';
  end;
end;

{ wall type name }
{#U0728_0F3B}
function U0728_0F3B(N: Integer): string;
begin
  case N of
    0: U0728_0F3B := 'NO';
    1: U0728_0F3B := 'STICK';
    2: U0728_0F3B := 'ELASTIC';
    3: U0728_0F3B := 'ACCEL';
    4: U0728_0F3B := 'WARP';
    5: U0728_0F3B := 'RND';
  end;
end;

{ wind force name }
{#U0728_0FFC}
function U0728_0FFC(N: Integer): string;
begin
  case N of
    0: U0728_0FFC := 'None';
    1: U0728_0FFC := 'Low';
    2: U0728_0FFC := 'Norm';
    3: U0728_0FFC := 'High';
    4: U0728_0FFC := 'Gale';
    5: U0728_0FFC := 'RND';
  end;
end;

{#U0728_1186}
procedure U0728_1186;
var
  Buf: Pointer;
  Sel, Old, Hit: Integer;
  Done, MB1, MB2, Unused, KLt, KRt, KTog, Unused2: Boolean;
  OldVal, NewVal: Integer;
begin
  GetMem(Buf, $F64);
  GetImage($5D, $2D, $E3, $9B, Buf^);
  U0098_028C($5F, $2F, $E1, $99, $12, $0F, $11);
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
  OutTextXY($DF, $34, U2918_02FE(g_E77A) + '%');
  OutTextXY($DF, $3E, U0728_0F3B(g_E780));
  OutTextXY($DF, $48, U0728_0007(Boolean(g_E78A)));
  OutTextXY($DF, $52, U0728_0007(g_E789 = 0));
  OutTextXY($DF, $5C, U0728_0007(Boolean(g_E78D)));
  OutTextXY($DF, $66, U0728_0007(Boolean(g_E78F)));
  OutTextXY($DF, $70, U0728_0DEF(g_E782));
  OutTextXY($DF, $7A, U2918_02FE(g_E796));
  OutTextXY($DF, $84, U0728_0FFC(g_E77E));
  OutTextXY($DF, $8E, U0728_0007(Boolean(g_E791)));
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
      U0098_03A8($59, 10 * Sel + $34);
      U0098_03A8($E7, 10 * Sel + $34);
      U2968_004D;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          g_46C9 := ReadKey;
          if g_46C9 in [' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if g_46C9 in [#13, #27] then Hit := 10;
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            if (g_46C9 = KeyUp_3716) and (Sel > 0) then Dec(Sel);
            if (g_46C9 = KeyDn_3717) and (Sel < 9) then Inc(Sel);
            if g_46C9 = KeyRt_3718 then
            begin
              Hit := Sel;
              KRt := True;
            end;
            if g_46C9 = KeyLt_3719 then
            begin
              Hit := Sel;
              KLt := True;
            end;
          end;
        end;
        if U2968_0077(1) or U2968_0077(2) then
        begin
          MB1 := U2968_0077(1);
          MB2 := U2968_0077(2);
          g_4624 := U2918_022A;
          g_4626 := U2918_0256;
          if (g_4624 > $5F) and (g_4624 < $E1) then
          begin
            if (g_4626 > $31) and (g_4626 <= $3A) then Hit := 0
            else if (g_4626 > $3A) and (g_4626 <= $44) then Hit := 1
            else if (g_4626 > $44) and (g_4626 <= $4E) then Hit := 2
            else if (g_4626 > $4E) and (g_4626 <= $58) then Hit := 3
            else if (g_4626 > $58) and (g_4626 <= $62) then Hit := 4
            else if (g_4626 > $62) and (g_4626 <= $6C) then Hit := 5
            else if (g_4626 > $6C) and (g_4626 <= $76) then Hit := 6
            else if (g_4626 > $76) and (g_4626 <= $80) then Hit := 7
            else if (g_4626 > $80) and (g_4626 <= $8A) then Hit := 8
            else if (g_4626 > $8A) and (g_4626 < $99) then Hit := 9
            else Hit := 10;
          end
          else Hit := 10;
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0);
      U2968_005A;
      U0098_03F4($59, 10 * Old + $34, SaveBuf_E496);
      U0098_03F4($E7, 10 * Old + $34, SaveBuf_E496);
    until Hit in [0..10];
    SetColor(14);
    SetFillStyle(1, $12);
    OldVal := 0;
    NewVal := 0;
    case Hit of
      0: begin
           OldVal := g_E77A;
           if (KRt or MB2) and (g_E77A < 100) then Inc(g_E77A);
           if (KLt or MB1) and (g_E77A > 0) then Dec(g_E77A);
           if KTog then g_E77A := g_E77A + 5;
           if g_E77A > 100 then g_E77A := g_E77A - 100;
           Bar($C3, $30, $E1, $38);
           OutTextXY($DF, $34, U2918_02FE(g_E77A) + '%');
           NewVal := g_E77A;
         end;
      1: begin
           OldVal := g_E780;
           if (KRt or MB2) and (g_E780 < 5) then Inc(g_E780);
           if (KLt or MB1) and (g_E780 > 0) then Dec(g_E780);
           if KTog then g_E780 := (g_E780 + 1) mod 6;
           Bar($AF, $3A, $E1, $42);
           OutTextXY($DF, $3E, U0728_0F3B(g_E780));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E780;
         end;
      2: begin
           OldVal := g_E78A;
           if KRt or MB2 then g_E78A := 1;
           if KLt or MB1 then g_E78A := 0;
           if KTog then g_E78A := Byte(g_E78A = 0);
           Bar($C3, $44, $E1, $4C);
           OutTextXY($DF, $48, U0728_0007(Boolean(g_E78A)));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E78A;
         end;
      3: begin
           OldVal := Byte(g_E789 = 0);
           if KRt or MB2 then g_E789 := 0;
           if KLt or MB1 then g_E789 := 1;
           if KTog then g_E789 := Byte(g_E789 = 0);
           Bar($C3, $4E, $E1, $56);
           OutTextXY($DF, $52, U0728_0007(g_E789 = 0));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := Byte(g_E789 = 0);
         end;
      4: begin
           OldVal := g_E78D;
           if KRt or MB2 then g_E78D := 1;
           if KLt or MB1 then g_E78D := 0;
           if KTog then g_E78D := Byte(g_E78D = 0);
           Bar($C3, $58, $E1, $60);
           OutTextXY($DF, $5C, U0728_0007(Boolean(g_E78D)));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E78D;
         end;
      5: begin
           OldVal := g_E78F;
           if KRt or MB2 then g_E78F := 1;
           if KLt or MB1 then g_E78F := 0;
           if KTog then g_E78F := Byte(g_E78F = 0);
           Bar($C3, $62, $E1, $6A);
           OutTextXY($DF, $66, U0728_0007(Boolean(g_E78F)));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E78F;
         end;
      6: begin
           OldVal := g_E782;
           if (KRt or MB2) and (g_E782 < 10) then Inc(g_E782);
           if (KLt or MB1) and (g_E782 > 0) then Dec(g_E782);
           if KTog then g_E782 := (g_E782 + 1) mod 11;
           Bar($A5, $6C, $E1, $76);
           OutTextXY($DF, $70, U0728_0DEF(g_E782));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E782;
         end;
      7: begin
           OldVal := g_E796;
           if (KRt or MB2) and (g_E796 < 250) then Inc(g_E796);
           if (KLt or MB1) and (g_E796 > 0) then Dec(g_E796);
           if KTog then
             if g_E796 > 0 then g_E796 := 0 else g_E796 := 1;
           U27D4_008D(PalCycle_9FB8);
           PalCycle_9FB8.Speed := g_E796;
           U27D4_003D(PalCycle_9FB8);
           Bar($C3, $76, $E1, $7E);
           OutTextXY($DF, $7A, U2918_02FE(g_E796));
           NewVal := g_E796;
         end;
      8: begin
           OldVal := g_E77E;
           if (KRt or MB2) and (g_E77E < 5) then Inc(g_E77E);
           if (KLt or MB1) and (g_E77E > 0) then Dec(g_E77E);
           if KTog then Inc(g_E77E);
           if g_E77E > 5 then g_E77E := 0;
           Bar($C3, $80, $E1, $8A);
           OutTextXY($DF, $84, U0728_0FFC(g_E77E));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E77E;
         end;
      9: begin
           OldVal := g_E791;
           if KRt or MB2 then g_E791 := 1;
           if KLt or MB1 then g_E791 := 0;
           if KTog then g_E791 := Byte(g_E791 = 0);
           Bar($C3, $8A, $E1, $92);
           OutTextXY($DF, $8E, U0728_0007(Boolean(g_E791)));
           repeat until not U2968_0077(1) and not U2968_0077(2);
           NewVal := g_E791;
         end;
      10: Done := True;
    end;
    Hit := -1;
  until Done;
  PutImage($5D, $2D, Buf^, 0);
  FreeMem(Buf, $F64);
end;

{#U0728_1DD5}
procedure U0728_1DD5;
var
  Sel, Old, OldVal, Hit: Integer;
  KLt, KRt, KTog, MB1, MB2, Done: Boolean;
begin
  U0098_028C($76, $55, $CA, $BB, $12, $0F, $11);
  SetColor(10);
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  U0098_028C($7A, $5B, $C6, $65, 2, $11, $0F);
  U2823_00CC($7A, $5B, $C6, $65, SaveBuf_E496);
  SetTextJustify(1, 1);
  OutTextXY($A0, $5F, 'Sound Options');
  U0098_028C($7A, $6F, $C6, $79, 2, $11, $0F);
  U2823_00CC($7A, $6F, $C6, $79, SaveBuf_E496);
  SetTextJustify(1, 1);
  OutTextXY($A0, $73, 'Game Options');
  U0098_028C($7A, $83, $C6, $8D, 2, $11, $0F);
  U2823_00CC($7A, $83, $C6, $8D, SaveBuf_E496);
  SetTextJustify(1, 1);
  OutTextXY($A0, $87, 'Players: ');
  SetColor(14);
  OutTextXY(TextWidth('Players: ') div 2 + $A0, $87, U2918_02FE(g_46B4));
  U0098_028C($7A, $97, $C6, $A1, 2, $11, $0F);
  U2823_00CC($7A, $97, $C6, $A1, SaveBuf_E496);
  SetTextJustify(1, 1);
  SetColor(10);
  OutTextXY($A0, $9B, 'Games: ');
  SetColor(14);
  OutTextXY(TextWidth('Games: ') div 2 + $A0, $9B, U2918_02FE(g_E77C));
  U0098_028C($7A, $AB, $C6, $B5, 2, $11, $0F);
  U2823_00CC($7A, $AB, $C6, $B5, SaveBuf_E496);
  SetTextJustify(1, 1);
  SetColor(13);
  OutTextXY($A0, $AF, 'START');
  SetTextJustify(1, 1);
  U0098_028C($14, $91, $50, $9B, $12, $0F, $11);
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
      U0098_03A8($70, 20 * Sel + $5F);
      U0098_03A8($D0, 20 * Sel + $5F);
      U2968_004D;
      Old := Sel;
      repeat
        if KeyPressed then
        begin
          g_46C9 := ReadKey;
          if g_46C9 in [#13, ' '] then
          begin
            Hit := Sel;
            KTog := True;
          end;
          if g_46C9 in ['L', 'l'] then g_46F1 := 1;
          if g_46C9 = #0 then
          begin
            g_46C9 := ReadKey;
            if (g_46C9 = KeyUp_3716) and (Sel > 0) then Dec(Sel);
            if (g_46C9 = KeyDn_3717) and (Sel < 4) then Inc(Sel);
            if g_46C9 = KeyRt_3718 then
            begin
              KRt := True;
              Hit := Sel;
            end;
            if g_46C9 = KeyLt_3719 then
            begin
              KLt := True;
              Hit := Sel;
            end;
          end;
        end;
        if U2968_0077(1) or U2968_0077(2) then
        begin
          g_4624 := U2918_022A;
          g_4626 := U2918_0256;
          MB1 := U2968_0077(1);
          MB2 := U2968_0077(2);
          if (g_4624 > $7A) and (g_4624 < $C6) then
          begin
            if (g_4626 >= $5B) and (g_4626 <= $65) then Hit := 0;
            if (g_4626 >= $6F) and (g_4626 <= $79) then Hit := 1;
            if (g_4626 >= $83) and (g_4626 <= $8D) then Hit := 2;
            if (g_4626 >= $97) and (g_4626 <= $A1) then Hit := 3;
            if (g_4626 >= $AB) and (g_4626 <= $B5) then Hit := 4;
            repeat until not U2968_0077(1) and not U2968_0077(2);
          end;
          if (g_4624 > $14) and (g_4624 < $50) and (g_4626 > $91) and (g_4626 < $9B) then
            g_46F1 := 1;
          if Hit >= 0 then Sel := Hit;
        end;
      until (Old <> Sel) or (Hit >= 0) or (g_46F1 <> 0);
      U2968_005A;
      U0098_03F4($70, 20 * Old + $5F, SaveBuf_E496);
      U0098_03F4($D0, 20 * Old + $5F, SaveBuf_E496);
    until (Hit in [0..4]) or (g_46F1 <> 0);
    SetColor(14);
    if g_46F1 = 0 then
      case Hit of
        0: if KTog or MB1 or MB2 then U0728_09B5;
        1: if KTog or MB1 or MB2 then U0728_1186;
        2: begin
             OldVal := g_46B4;
             if (KRt or MB2) and (g_46B4 < 10) then Inc(g_46B4);
             if (KLt or MB1) and (g_46B4 > 2) then Dec(g_46B4);
             if KTog then Inc(g_46B4);
             if g_46B4 > 10 then g_46B4 := 2;
             SetTextJustify(1, 1);
             U2823_00CC(TextWidth('Players: ') div 2 + $A0 - 4, $85,
                        TextWidth('Players: ') div 2 + $A0 + 10, $8B, SaveBuf_E496);
             OutTextXY(TextWidth('Players: ') div 2 + $A0, $87, U2918_02FE(g_46B4));
           end;
        3: begin
             OldVal := g_E77C;
             if KRt and (g_E77C < 99) then Inc(g_E77C);
             if MB2 and (g_E77C < 99) then Inc(g_E77C, 5);
             if KLt and (g_E77C > 1) then Dec(g_E77C);
             if MB1 and (g_E77C > 1) then Dec(g_E77C, 5);
             if g_E77C > 99 then g_E77C := 99;
             if g_E77C < 1 then g_E77C := 1;
             if KTog then Inc(g_E77C, 5);
             if g_E77C > 99 then Dec(g_E77C, 99);
             SetTextJustify(1, 1);
             U2823_00CC(TextWidth('Games: ') div 2 + $A0 - 5, $99,
                        TextWidth('Games: ') div 2 + $A0 + 15, $9F, SaveBuf_E496);
             OutTextXY(TextWidth('Games: ') div 2 + $A0, $9B, U2918_02FE(g_E77C));
           end;
        4: Done := True;
      end;
    Hit := -1;
  until Done or (g_46F1 <> 0);
end;

{#U0728_2609}
procedure U0728_2609;
var
  Sel, Old: Integer;
  Down, Up: Boolean;
begin
  SetTextStyle(2, 0, 1);
  SetUserCharSize(1, 1, 1, 1);
  SetTextJustify(1, 0);
  U0098_028C($3C, $3E, $104, $B6, $12, $0F, $11);
  U0098_028C($82, $2F, $BE, $39, $12, $0F, $11);
  SetColor(10);
  OutTextXY($A0, $37, 'Team Setup');
  U0098_028C($82, $BB, $BE, $C5, $12, $0F, $11);
  SetColor(5);
  SetTextJustify(1, 2);
  OutTextXY($A0, $BA, '-- Done --');
  SetTextJustify(0, 2);
  SetColor(14);
  OutTextXY($40, $3E, 'Team # -->');
  SetTextJustify(1, 2);
  for g_461E := 1 to 10 do
  begin
    if g_461E > g_46B4 then SetColor(0);
    OutTextXY(10 * g_461E + $8C, $3E, U2918_02FE(g_461E));
    for g_4620 := 1 to g_46B4 do
      if Players_3F0E[g_4620].Team = g_461E then
      begin
        Players_3F0E[g_4620].X := 10 * g_461E + $8C;
        Players_3F0E[g_4620].Y := 10 * g_4620 + $47;
        Players_3F0E[g_4620].Men := 100;
        U0098_07A3(g_4620);
      end;
  end;
  SetTextJustify(0, 2);
  for g_461E := 1 to 10 do
  begin
    U26A9_01B0(100, Players_3F0E[g_461E]);
    if g_461E > g_46B4 then SetColor(0) else SetColor(g_461E + 19);
    OutTextXY($40, 10 * g_461E + $3E, Players_3F0E[g_461E].Name);
  end;
  Sel := 1;
  g_462F := 0;
  g_E7C8(19, 63, 63, 63);
  repeat
    U0098_03A8($37, 10 * Sel + $44);
    Old := Sel;
    U2968_004D;
    Down := False;
    Up := False;
    repeat
      if KeyPressed then
      begin
        g_46C9 := UpCase(ReadKey);
        if g_46C9 in [#13, #27, 'D'] then
        begin
          Sel := 11;
          Down := True;
        end;
        if g_46C9 = #0 then
        begin
          g_46C9 := ReadKey;
          if (g_46C9 = KeyUp_3716) and (Sel > 1) then Dec(Sel);
          if (g_46C9 = KeyDn_3717) and (Sel < g_46B4) then Inc(Sel);
          if g_46C9 = KeyRt_3718 then Up := True;
          if g_46C9 = KeyLt_3719 then Down := True;
        end;
      end;
      if U2968_0077(1) or U2968_0077(2) then
      begin
        g_4624 := U2918_022A;
        g_4626 := U2918_0256;
        if (g_4624 > $3C) and (g_4624 < $104) then
          for g_461E := 1 to g_46B4 do
            if (10 * g_461E + $47 >= g_4626) and (10 * g_461E + $40 <= g_4626) then
            begin
              Sel := g_461E;
              if U2968_0077(1) then Down := True;
              if U2968_0077(2) then Up := True;
              Delay(40);
            end;
        if (g_4624 > $82) and (g_4624 < $BE) and (g_4626 > $BB) and (g_4626 < $C5) then
        begin
          Sel := 11;
          Down := True;
        end;
      end;
    until (Old <> Sel) or Down or Up;
    U2968_005A;
    U0098_03F4($37, 10 * Old + $44, SaveBuf_E496);
    if Down or Up then
      case Sel of
        1..10:
          begin
            U2823_0088(10 * Players_3F0E[Sel].Team + $8C - 5, 10 * Sel + $47,
                       10 * Players_3F0E[Sel].Team + $8C + 5, 10 * Sel + $3F, $12);
            if Down and (Players_3F0E[Sel].Team > 1) then Dec(Players_3F0E[Sel].Team);
            if Up and (Players_3F0E[Sel].Team < g_46B4) then Inc(Players_3F0E[Sel].Team);
            Players_3F0E[Sel].X := 10 * Players_3F0E[Sel].Team + $8C;
            Players_3F0E[Sel].Y := 10 * Sel + $47;
            U0098_07A3(Sel);
          end;
        11: g_462F := 1;
      end;
  until g_462F <> 0;
  g_462F := 0;
  for g_461E := 1 to g_46B4 do
    if Players_3F0E[g_461E].Team <> Players_3F0E[1].Team then g_462F := 1;
  g_4628 := 0;
  for g_461E := 1 to g_46B4 do
  begin
    g_4622 := 0;
    for g_4620 := 1 to g_46B4 do
      if Players_3F0E[g_4620].Team = g_461E then Inc(g_4622);
    if g_4622 > g_4628 then g_4628 := g_4622;
  end;
  if g_4628 < 2 then g_462F := 0;
  if g_462F = 0 then
  begin
    repeat until not U2968_0077(1) and not U2968_0077(2);
    SetColor(6);
    U0098_028C($5A, $72, $E6, $8E, $12, $0F, $11);
    SetTextJustify(1, 2);
    OutTextXY($A0, $70, 'Team play canceled due');
    OutTextXY($A0, $7A, 'to extreme stupidity.');
    SetTextStyle(g_E7EC, 0, 1);
    SetUserCharSize(1, 1, 1, 1);
    SetTextJustify(1, 2);
    SetColor(4);
    OutTextXY($A0, $81, 'PRESS ANY KEY TO CONTINUE...');
    repeat until KeyPressed or U2968_0077(1) or U2968_0077(2);
    MemW[$40:$1A] := MemW[$40:$1C];   { flush BIOS keyboard buffer }
    g_E791 := 0;
    for g_461E := 1 to 10 do Players_3F0E[g_461E].Team := g_461E;
  end;
  if g_462F <> 0 then ;
end;

{#U0728_2D41}
procedure U0728_2D41(a1: Word);
begin
end;

{#U0728_2E8E}
procedure U0728_2E8E(a1: Word);
begin
end;

{#U0728_302C}
procedure U0728_302C(a1: Word);
begin
end;

{#U0728_3449}
procedure U0728_3449;
begin
end;

