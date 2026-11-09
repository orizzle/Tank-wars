{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
{$M 16384,0,655360}
program Bomb;

{ Tank Wars 3.0 (working title BOMB) - Kenneth Morse, 1990-1992.
  Main program: installs the exit handler, the BGI driver and fonts,
  the keyboard handler and the mouse, then runs the game. }

uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3, U0040, U0098, U0728, U0E9B, U1615,
  U1B27, U1DD4, U1F69, U20C6, U22B7, U2390;

{$IFDEF KEEPALL}
{$I KEEPALL.INC}
{$ENDIF}

{#BOMB_0000}
procedure BombExit;
begin
  if g_E7AE <> 0 then U27D4_03A7;
  if g_460A <> 0 then U27B1_00E5;
  if g_E78B <> 0 then
  begin
    U0728_06B1;
    g_462F := U2968_003B;
  end;
  U2918_000F;
  ExitProc := g_46F8;
end;

{#BOMB_0102}
begin
  {$IFDEF KEEPALL} if ParamCount = 9999 then KeepAll; {$ENDIF}
  g_46CA := 'TANK WARS Copyright 1990, 1991, 1992 Kenneth Morse';
  g_46CA := 'All Rights Reserved.';
  g_E795 := 0;
  U0728_05D8;
  U0728_62E4;
  U2918_0000;
  Randomize;
  TextMode(CO80);
  TextBackground(Black);
  TextColor(Yellow);
  ClrScr;
  if g_E795 <> 0 then U0098_0226('EXITPROC INSTALL');
  g_46F8 := ExitProc;
  ExitProc := @BombExit;
  if g_E795 <> 0 then U0098_0226('REGISTER DRIVER');
  if RegisterBGIdriver(@VGA256Driver) < 0 then
  begin
    Writeln('Error registering driver: ', GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  if g_E795 <> 0 then U0098_0226('REGISTER FONTS');
  if RegisterBGIfont(@EuroFont) < 0 then
  begin
    Writeln(GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  if RegisterBGIfont(@LittFont) < 0 then
  begin
    Writeln(GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  if RegisterBGIfont(@TinyFont) < 0 then
  begin
    Writeln(GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  FillChar(g_440A, $200, 0);
  if g_E795 <> 0 then U0098_0226('INSTALL XKEY');
  U27B1_007D(True, @U2390_021B);
  if g_E795 <> 0 then U0098_0226('MOUSE');
  if g_E790 <> 0 then
  begin
    U2968_002E(g_E78B);
    if g_E78B <> 0 then U2968_0047;
  end
  else
    U0728_04D0;
  if g_E78B <> 0 then U0728_06B1;
  if g_E795 <> 0 then U0098_0226('INITGRAPH');
  g_461E := Detect;
  InitGraph(g_461E, g_461E, '');
  U2823_0000;
  if g_E795 <> 0 then U0098_0226('CYCLER');
  if g_E786 <> 0 then U27D4_0244(g_E793);
  if g_E795 <> 0 then U0098_0226('TITLE');
  if (g_E78E <> 0) or (g_E794 <> 0) then U0040_0014;
  U0728_3BC3;
  U0E9B_7523;
  U23C3_2E0B;
  CloseGraph;
  U0E9B_7242;
end.
