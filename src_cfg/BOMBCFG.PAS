{$A+,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
{$M 26384,0,655360}
program BombCfg;

{ Tank Wars 3.0 configuration program (BOMBCFG.EXE) - Kenneth Morse, 1991-1992.
  A Turbo Vision application.  SKELETON: procedure bodies still to do. }

uses
  Dos, Objects, Drivers, Memory, HistList, Views, Menus, App, Dialogs,
  Crt, Graph, Printer, U2968, U2918, C04B6, MsgBox, C0453;

type
  PMyApp = ^TMyApp;
  TMyApp = object(TApplication)
    constructor Init;
    procedure InitStatusLine; virtual;
    procedure Idle; virtual;
    procedure InitMenuBar; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure M0776;
    procedure M099B;
    procedure M0CC2;
    procedure M12BA;
    procedure M1681;
    procedure M18D0;
    procedure M1B0F;
    procedure M1D45;
    procedure M208F;
    procedure M2587;
    procedure M28D7;
    procedure M2C9E;
    procedure M2EC9(a1, a2: Word);
    procedure M30B1;
    procedure M3E34;
    procedure M3F1C;
    procedure M4319;
    procedure M43E5(a1, a2, a3, a4: Word);
  end;

  PMyCheckBoxes = ^TMyCheckBoxes;
  TMyCheckBoxes = object(TCheckBoxes)
    function GetHelpCtx: Word; virtual;
  end;

  PMyRadioButtons = ^TMyRadioButtons;
  TMyRadioButtons = object(TRadioButtons)
    function GetHelpCtx: Word; virtual;
  end;

const
  { DS 011E-0125 }
  c_011E: string[5] = '3.0'#0;
  c_0124: Boolean = False;
  c_0125: Byte = 0;

var
  { DS 0FB0-111F }
  MyApp_0FB0: TMyApp;
  g_0FE8: Word;
  g_0FEA: array[0..3] of Byte;
  g_0FEE: Word;
  g_0FF0: Word;
  g_0FF2: Word;
  g_0FF4: Word;
  g_0FF6: array[0..3] of Byte;
  g_0FFA: Word;
  g_0FFC: Word;
  g_0FFE: Word;
  g_1000: Word;
  g_1002: Word;
  g_1004: Word;
  g_1006: array[0..3] of Byte;
  g_100A: array[0..3] of Byte;
  g_100E: array[0..3] of Byte;
  g_1012: array[0..3] of Byte;
  g_1016: array[0..3] of Byte;
  g_101A: string;
  g_111A: array[0..5] of Byte;

{#BOMBCFG_0000}
function TMyCheckBoxes.GetHelpCtx: Word;
begin
  GetHelpCtx := HelpCtx;
end;

{#BOMBCFG_0019}
function TMyRadioButtons.GetHelpCtx: Word;
begin
  GetHelpCtx := HelpCtx;
end;

{#BOMBCFG_0032}
constructor TMyApp.Init;
begin
  TApplication.Init;
  RegisterHelpFile;
  M1D45;
  M3E34;
end;

{#BOMBCFG_00A3}
procedure TMyApp.InitStatusLine;
begin
end;

{#BOMBCFG_0148}
procedure TMyApp.Idle;
begin
end;

{#BOMBCFG_022F}
procedure TMyApp.InitMenuBar;
begin
end;

{#BOMBCFG_0453}
procedure TMyApp.HandleEvent(var Event: TEvent);
begin
end;

{#BOMBCFG_05C8}
procedure TMyApp.GetEvent(var Event: TEvent);
begin
end;

{#BOMBCFG_0776}
procedure TMyApp.M0776;
begin
end;

{#BOMBCFG_099B}
procedure TMyApp.M099B;
begin
end;

{#BOMBCFG_0CC2}
procedure TMyApp.M0CC2;
begin
end;

{#BOMBCFG_12BA}
procedure TMyApp.M12BA;
begin
end;

{#BOMBCFG_1681}
procedure TMyApp.M1681;
begin
end;

{#BOMBCFG_18D0}
procedure TMyApp.M18D0;
begin
end;

{#BOMBCFG_1B0F}
procedure TMyApp.M1B0F;
begin
end;

{#BOMBCFG_1D45}
procedure TMyApp.M1D45;
begin
end;

{#BOMBCFG_208F}
procedure TMyApp.M208F;
begin
end;

{#BOMBCFG_2587}
procedure TMyApp.M2587;
begin
end;

{#BOMBCFG_28D7}
procedure TMyApp.M28D7;
begin
end;

{#BOMBCFG_2C9E}
procedure TMyApp.M2C9E;
begin
end;

{#BOMBCFG_2EC9}
procedure TMyApp.M2EC9(a1, a2: Word);
begin
end;

{#BOMBCFG_30B1}
procedure TMyApp.M30B1;
begin
end;

procedure TMyApp.M3E34;

{#BOMBCFG_320F} procedure P320F;
  begin
  end;

{#BOMBCFG_3762} procedure P3762;
  begin
  end;

{#BOMBCFG_3E34}
begin
  P320F;
  P3762;
end;

{#BOMBCFG_3F1C}
procedure TMyApp.M3F1C;
begin
end;

{#BOMBCFG_4319}
procedure TMyApp.M4319;
begin
end;

{#BOMBCFG_43E5}
procedure TMyApp.M43E5(a1, a2, a3, a4: Word);
begin
end;

{$IFDEF KEEPALL}
{ dev builds only: link the library objects (VMTs, typed constants) that the
  finished program uses, so that the data segment layout is already right
  while procedure bodies are still missing.  Remove when everything is done. }
procedure LibRefs;
var
  R: TRect;
  P: PView;
begin
  MessageBox('', nil, 0);
  P := New(PMyCheckBoxes, Init(R, nil));
  P := New(PMyRadioButtons, Init(R, nil));
  P := New(PNumInputLine, Init(R, 0, 0, 0));
  P := New(PLabel, Init(R, '', nil));
  P := New(PMenuBar, Init(R, nil));
  P := New(PStatusLine, Init(R, nil));
  P := New(PHelpWindow, Init(New(PHelpFile, Init(New(PDosStream, Init('', 0)))), 0));
  c_0124 := c_011E = '';
  if DosError = 0 then ;
end;

{$I KEEPALL.INC}
{$ENDIF}

{#BOMBCFG_44AE}
begin
  {$IFDEF KEEPALL} if ParamCount = 9999 then KeepAll; {$ENDIF}
  g_101A := 'TANK WARS Configuration Copyright 1991, 1992 Kenneth Morse';
  g_101A := 'All Rights Reserved.';
  MyApp_0FB0.Init;
  MyApp_0FB0.Run;
  MyApp_0FB0.Done;
end.
