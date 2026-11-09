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

{#BOMB_0000}
procedure BombExit;
begin
  if CycInstalled <> 0 then RemovePalCycler;
  if KbdInstalled <> 0 then RemoveKeyboard;
  if MouseIn <> 0 then
  begin
    InitMouseCursor;
    DoneFlag := DetectMouse;
  end;
  RestorePicMasks;
  ExitProc := BombOldExitProc;
end;

{$IFDEF KEEPALL}
{$I KEEPALL.INC}
{$ENDIF}

{#BOMB_0102}
begin
  {$IFDEF KEEPALL} if ParamCount = 9999 then KeepAll; {$ENDIF}
  TmpStr := 'TANK WARS Copyright 1990, 1991, 1992 Kenneth Morse';
  TmpStr := 'All Rights Reserved.';
  DebugMode := 0;
  ShowCpuType;
  LoadSettings;
  SavePicMasks;
  Randomize;
  TextMode(CO80);
  TextBackground(Black);
  TextColor(Yellow);
  ClrScr;
  if DebugMode <> 0 then DebugTrace('EXITPROC INSTALL');
  BombOldExitProc := ExitProc;
  ExitProc := @BombExit;
  if DebugMode <> 0 then DebugTrace('REGISTER DRIVER');
  if RegisterBGIdriver(@VGA256Driver) < 0 then
  begin
    Writeln('Error registering driver: ', GraphErrorMsg(GraphResult));
    Halt(1);
  end;
  if DebugMode <> 0 then DebugTrace('REGISTER FONTS');
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
  FillChar(KeyDown, $200, 0);
  if DebugMode <> 0 then DebugTrace('INSTALL XKEY');
  InstallKeyboard(True, @HotKeyHook);
  if DebugMode <> 0 then DebugTrace('MOUSE');
  if ForceMouse <> 0 then
  begin
    SetMouseEnabled(MouseIn);
    if MouseIn <> 0 then ResetMouse;
  end
  else
    CheckMouse;
  if MouseIn <> 0 then InitMouseCursor;
  if DebugMode <> 0 then DebugTrace('INITGRAPH');
  LoopI := Detect;
  InitGraph(LoopI, LoopI, '');
  SetMode13h;
  if DebugMode <> 0 then DebugTrace('CYCLER');
  if PaletteOn <> 0 then InstallPalCycler(PalUseRetrace);
  if DebugMode <> 0 then DebugTrace('TITLE');
  if (ShowTitle <> 0) or (BeginnerGame <> 0) then ShowTitleScreen;
  SetupGame;
  PlayGames;
  FreeComputers;
  CloseGraph;
  PrintFinalResults;
end.
