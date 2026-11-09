{$A+,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
{$M 26384,0,655360}
program BombCfg;

{ Tank Wars 3.0 configuration program (BOMBCFG.EXE) - Kenneth Morse, 1991-1992.
  A Turbo Vision application: a menu bar with one dialog per group of
  options; the settings are read from / written to BOMB.CFG (version 3.0,
  version 2.5 files are converted).  Help: BOMBCFG.HLP (unit C04B6). }

uses
  Dos, Objects, Drivers, Memory, HistList, Views, Menus, App, Dialogs,
  Crt, Graph, Printer, U2968, U2918, C04B6, MsgBox, C0453;

type
  TVerStr = string[4];

  PMyApp = ^TMyApp;
  TMyApp = object(TApplication)
    constructor Init;
    procedure Idle; virtual;
    procedure InitStatusLine; virtual;
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
    procedure M2EC9(FileVer: TVerStr);
    procedure M30B1;
    procedure M3E34;
    procedure M3F1C;
    procedure M4319;
    procedure M43E5(var X: Word; Bit: Word; Value: Boolean);
  end;

  PMyRadioButtons = ^TMyRadioButtons;
  TMyRadioButtons = object(TRadioButtons)
    function GetHelpCtx: Word; virtual;
  end;

  PMyCheckBoxes = ^TMyCheckBoxes;
  TMyCheckBoxes = object(TCheckBoxes)
    function GetHelpCtx: Word; virtual;
  end;

const
  { commands }
  cmSave        = 100;
  cmSound       = 101;
  cmGames       = 102;
  cmBackground  = 103;
  cmEnvironment = 104;
  cmShot        = 105;
  cmTank        = 106;
  cmComputers   = 107;
  cmHardware    = 108;
  cmLoad        = 109;
  cmDefaults    = 110;
  cmHelp        = 111;
  cmSpeed       = 112;
  cmSaveExit    = 113;
  cmPalette     = 114;

const
  { DS 011E-0125 }
  Version_011E: string[5] = '3.0'#0;
  HelpInUse_0124: Boolean = False;
  c_0125: Byte = 0;                     { not referenced }

var
  { DS 0FB0-111F }
  MyApp_0FB0: TMyApp;
  SoundData_0FE8: Word;                 { check boxes: standard, flying }
  GamesData_0FEA: string[2];            { number of games }
  BackData_0FEE: record                 { background }
    Which: Word;                        { radio buttons }
    UserSet: Word;                      { check boxes }
  end;
  EnvData_0FF2: record                  { environment }
    Wind: Word;
    Wall: Word;
    Crumble: string[3];
  end;
  ShotData_0FFA: Word;                  { check boxes: visible, trail }
  TankData_0FFC: Word;                  { check boxes: -, fall, team }
  CompData_0FFE: Word;                  { check box: computers buy }
  HwData_1000: record                   { hardware }
    Flags: Word;                        { check boxes: direct video, -, crude palette }
    Mouse: Word;                        { radio buttons }
  end;
  PalData_1004: record                  { palette }
    Iface: Word;                        { radio buttons }
    Speed: string[3];
  end;
  SpeedData_100A: record                { delays }
    Turret, Fall, Explosion, Projectile: string[3];
  end;
  Copyright_101A: string;
  Unused_111A: array[0..5] of Byte;   { not referenced }

{#BOMBCFG_0000}
function TMyRadioButtons.GetHelpCtx: Word;
begin
  GetHelpCtx := HelpCtx;
end;

{#BOMBCFG_0019}
function TMyCheckBoxes.GetHelpCtx: Word;
begin
  GetHelpCtx := HelpCtx;
end;

{#BOMBCFG_0032}
constructor TMyApp.Init;
var
  R: TRect;                     { unused }
  D: PDialog;
  B: PView;
  C, I: Word;
begin
  TApplication.Init;
  RegisterHelpFile;
  M1D45;
  M3E34;
end;

{#BOMBCFG_00A3}
procedure TMyApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F1~ Help', kbF1, cmHelp,
      NewStatusKey('~F2~ Save', kbF2, cmSave,
      NewStatusKey('~F10~ Save & Exit', kbF10, cmSaveExit,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      nil)))),
    nil)));
end;

{#BOMBCFG_0148}
procedure TMyApp.Idle;
begin
  TApplication.Idle;
end;

{#BOMBCFG_022F}
procedure TMyApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~S~etup', hcNoContext, NewMenu(
      NewItem('~R~estore Defaults', '', kbNoKey, cmDefaults, 1011,
      NewItem('~S~ound', '', kbNoKey, cmSound, 1000,
      NewItem('~N~umber of games', '', kbNoKey, cmGames, 1001,
      NewItem('~B~ackground', '', kbNoKey, cmBackground, 1002,
      nil))))),
    NewSubMenu('~O~ptions', hcNoContext, NewMenu(
      NewItem('~E~nvironment', '', kbNoKey, cmEnvironment, 1003,
      NewItem('~S~hot Control', '', kbNoKey, cmShot, 1004,
      NewItem('~T~ank Control', '', kbNoKey, cmTank, 1005,
      NewItem('~C~omputers', '', kbNoKey, cmComputers, 1006,
      NewItem('S~p~eed Controls', '', kbNoKey, cmSpeed, 1007,
      NewItem('~H~ardware', '', kbNoKey, cmHardware, 1008,
      NewItem('~P~alette Control', '', kbNoKey, cmPalette, 1009,
      nil)))))))),
    NewSubMenu('~D~one', hcNoContext, NewMenu(
      NewItem('Sa~v~e', '', kbNoKey, cmSave, 1013,
      NewItem('~S~ave & Exit', '', kbNoKey, cmSaveExit, 1012,
      NewItem('E~x~it', '', kbNoKey, cmQuit, 1010,
      nil)))),
    nil))))));
end;

{#BOMBCFG_0453}
procedure TMyApp.HandleEvent(var Event: TEvent);
var
  E: TEvent;
begin
  TApplication.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmSound: M0776;
      cmGames: M099B;
      cmBackground: M0CC2;
      cmEnvironment: M12BA;
      cmShot: M1681;
      cmTank: M18D0;
      cmComputers: M1B0F;
      cmHardware: M2587;
      cmSpeed: M208F;
      cmPalette: M28D7;
      cmLoad: M3E34;
      cmSave: M3F1C;
      cmSaveExit:
        begin
          M3F1C;
          E.What := evCommand;
          E.Command := cmQuit;
          E.InfoPtr := @Self;
          PutEvent(E);
        end;
      cmDefaults: M30B1;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

{#BOMBCFG_05C8}
procedure TMyApp.GetEvent(var Event: TEvent);
var
  W: PWindow;
  HFile: PHelpFile;
  HelpStrm: PDosStream;
begin
  TApplication.GetEvent(Event);
  case Event.What of
    evCommand:
      if (Event.Command = cmHelp) and not HelpInUse_0124 then
      begin
        HelpInUse_0124 := True;
        HelpStrm := New(PDosStream, Init('BOMBCFG.HLP', stOpenRead));
        HFile := New(PHelpFile, Init(HelpStrm));
        if HelpStrm^.Status <> stOk then
        begin
          MessageBox('Could not open help file.', nil, mfError + mfOkButton);
          Dispose(HFile, Done);
        end
        else
        begin
          W := New(PHelpWindow, Init(HFile, GetHelpCtx));
          if ValidView(W) <> nil then
          begin
            ExecView(W);
            Dispose(W, Done);
          end;
          ClearEvent(Event);
        end;
        HelpInUse_0124 := False;
      end;
    evMouseDown:
      if Event.Buttons = mbRightButton then
      begin
        Event.What := evCommand;
        Event.InfoPtr := @Self;
        Event.Command := cmHelp;
        PutEvent(Event);
        ClearEvent(Event);
      end;
  end;
end;

{ Setup/Sound: two check boxes }
{#BOMBCFG_0776}
procedure TMyApp.M0776;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 40, 7);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Sound Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1000;
    R.Assign(27, 2, 37, 4);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(27, 4, 37, 6);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(3, 3, 25, 5);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('~S~tandard Sound',
      NewSItem('~F~lying Sound',
      nil))));
    Insert(B);
    R.Assign(3, 2, 25, 3);
    B := New(PLabel, Init(R, 'Sound Toggles', B));
    Insert(B);
    SetData(SoundData_0FE8);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(SoundData_0FE8);
  Dispose(D, Done);
end;

{ Setup/Number of games: a numeric input line 1..99 }
{#BOMBCFG_099B}
procedure TMyApp.M099B;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 30, 7);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Number of Games'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1001;
    R.Assign(4, 4, 10, 6);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(14, 4, 25, 6);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(24, 2, 28, 3);
    B := New(PNumInputLine, Init(R, 2, 1, 99));
    Insert(B);
    R.Assign(2, 2, 23, 3);
    B := New(PLabel, Init(R, 'Type Desired Number:', B));
    Insert(B);
    SetData(GamesData_0FEA);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(GamesData_0FEA);
  Dispose(D, Done);
end;

{ Setup/Background: one of the backgrounds (radio buttons), and for
  "User Defined" the set to choose from (check boxes) }
{#BOMBCFG_0CC2}
procedure TMyApp.M0CC2;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
  I: Integer;
  N: Integer;
begin
  R.Assign(0, 0, 54, 18);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Select Background'));
  D^.Options := D^.Options or ofCentered;
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1002;
    R.Assign(10, 15, 16, 17);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(32, 15, 43, 17);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(2, 3, 26, 14);
    B := New(PMyRadioButtons, Init(R,
      NewSItem('~N~one',
      NewSItem('~A~-Starry Scene',
      NewSItem('~B~-Color Bars',
      NewSItem('~C~-Circles',
      NewSItem('~D~-Spreading Colors',
      NewSItem('~E~-Blue Sky',
      NewSItem('~F~-Static',
      NewSItem('~G~-Rectangles',
      NewSItem('~H~-Asterisk',
      NewSItem('~R~andom',
      NewSItem('~U~ser Defined',
      nil)))))))))))));
    Insert(B);
    R.Assign(2, 2, 23, 3);
    B := New(PLabel, Init(R, 'Select Background:', B));
    Insert(B);
    R.Assign(28, 3, 52, 12);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('~N~one',
      NewSItem('~A~-Starry Scene',
      NewSItem('~B~-Color Bars',
      NewSItem('~C~-Circles',
      NewSItem('~D~-Spreading Colors',
      NewSItem('~E~-Blue Sky',
      NewSItem('~F~-Static',
      NewSItem('~G~-Rectangles',
      NewSItem('~H~-Asterisk',
      nil)))))))))));
    Insert(B);
    R.Assign(28, 2, 48, 3);
    B := New(PLabel, Init(R, 'User Defined:', B));
    Insert(B);
    SelectNext(False);
    SetData(BackData_0FEE);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(BackData_0FEE);
  Dispose(D, Done);
  if BackData_0FEE.Which = 10 then
  begin
    N := 0;
    for I := 0 to 8 do
      if BackData_0FEE.UserSet and (1 shl I) > 0 then Inc(N);
    if N = 0 then
    begin
      R.Assign(0, 0, 40, 9);
      D := New(PDialog, Init(R, 'Setup Error'));
      with D^ do
      begin
        Options := Options or ofCentered;
        Flags := Flags and not wfClose;
        GetExtent(R);
        R.A.Y := R.B.Y - 3;
        R.B.Y := R.B.Y - 1;
        R.B.X := 13;
        B := New(PButton, Init(R, 'RETRY', cmOK, bfDefault));
        B^.Options := B^.Options or ofCenterX;
        Insert(B);
        GetExtent(R);
        R.Grow(-3, -3);
        R.Move(0, -1);
        Insert(New(PStaticText, Init(R,
          ^C'  If you choose User Set you must select at least one background from the righthand set.')));
      end;
      C := DeskTop^.ExecView(D);
      Dispose(D, Done);
      M0CC2;
    end;
  end;
end;

{ Options/Environment: wind, walls, crumbling percentage }
{#BOMBCFG_12BA}
procedure TMyApp.M12BA;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 50, 15);
  D := New(PDialog, Init(R, 'Setup Environment'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1003;
    R.Assign(15, 12, 21, 14);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(25, 12, 35, 14);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(2, 3, 21, 9);
    B := New(PMyRadioButtons, Init(R,
      NewSItem('~N~one',
      NewSItem('~L~ow',
      NewSItem('~S~tandard',
      NewSItem('~H~igh',
      NewSItem('~G~ale',
      NewSItem('~R~andom',
      nil))))))));
    Insert(B);
    R.Assign(2, 2, 21, 3);
    B := New(PLabel, Init(R, 'Select Wind Level:', B));
    Insert(B);
    R.Assign(23, 3, 47, 9);
    B := New(PMyRadioButtons, Init(R,
      NewSItem('~N~on Existant',
      NewSItem('~S~tickey (50%)',
      NewSItem('~E~lastic (100%)',
      NewSItem('~A~ccelerating (150%)',
      NewSItem('~W~arping ('#27#26')',
      NewSItem('~R~andom',
      nil))))))));
    Insert(B);
    R.Assign(28, 2, 47, 3);
    B := New(PLabel, Init(R, 'Select Wall:', B));
    Insert(B);
    R.Assign(35, 10, 40, 11);
    B := New(PNumInputLine, Init(R, 3, 0, 100));
    Insert(B);
    R.Assign(2, 10, 35, 11);
    B := New(PLabel, Init(R, 'Type Desired Crumble Percentage:', B));
    Insert(B);
    SetData(EnvData_0FF2);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(EnvData_0FF2);
  Dispose(D, Done);
end;

{ Options/Shot Control: two check boxes }
{#BOMBCFG_1681}
procedure TMyApp.M1681;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 35, 7);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Shot Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1004;
    R.Assign(22, 2, 32, 4);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(22, 4, 32, 6);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(3, 3, 20, 5);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('~V~isible',
      NewSItem('~T~rail',
      nil))));
    Insert(B);
    R.Assign(3, 2, 20, 3);
    B := New(PLabel, Init(R, 'Shot Toggles', B));
    Insert(B);
    SetData(ShotData_0FFA);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(ShotData_0FFA);
  Dispose(D, Done);
end;

{ Options/Tank Control: three check boxes }
{#BOMBCFG_18D0}
procedure TMyApp.M18D0;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 33, 10);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Tank Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1005;
    R.Assign(3, 7, 9, 9);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(13, 7, 23, 9);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(3, 3, 30, 6);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('X-X-X-X-X-X-X-X-X-X-X',
      NewSItem('~F~all Down Cliffs',
      NewSItem('~T~eam Play',
      nil)))));
    Insert(B);
    R.Assign(3, 2, 20, 3);
    B := New(PLabel, Init(R, 'Tank Toggles', B));
    Insert(B);
    SetData(TankData_0FFC);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(TankData_0FFC);
  Dispose(D, Done);
end;

{ Options/Computers: one check box }
{#BOMBCFG_1B0F}
procedure TMyApp.M1B0F;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 33, 8);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Computer Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1006;
    R.Assign(3, 5, 9, 7);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(13, 5, 23, 7);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(3, 3, 30, 4);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('~C~an Buy Weapons',
      nil)));
    Insert(B);
    R.Assign(3, 2, 20, 3);
    B := New(PLabel, Init(R, 'Computer Toggle', B));
    Insert(B);
    SetData(CompData_0FFE);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(CompData_0FFE);
  Dispose(D, Done);
end;

{ the About box }
{#BOMBCFG_1D45}
procedure TMyApp.M1D45;
var
  D: PDialog;
  Dummy: Pointer;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 33, 13);
  R.Move(10, 5);
  D := New(PDialog, Init(R, ''));
  with D^ do
  begin
    Options := Options or ofCentered;
    R.Assign(0, 0, 10, 2);
    R.Move(0, 10);
    B := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    GetExtent(R);
    R.Grow(-1, 0);
    R.B.Y := R.A.Y + 1;
    R.Move(0, 2);
    B := New(PStaticText, Init(R, ^C'Tank Wars Configuration'));
    Insert(B);
    GetExtent(R);
    R.Grow(-1, 0);
    R.B.Y := R.A.Y + 1;
    R.Move(0, 4);
    B := New(PStaticText, Init(R, ^C'Version ' + Version_011E));
    Insert(B);
    GetExtent(R);
    R.Grow(-1, 0);
    R.B.Y := R.A.Y + 1;
    R.Move(0, 6);
    B := New(PStaticText, Init(R, ^C'Copyright 1991, 1992'));
    Insert(B);
    GetExtent(R);
    R.Grow(-1, 0);
    R.B.Y := R.A.Y + 1;
    R.Move(0, 8);
    B := New(PStaticText, Init(R, ^C'Kenneth Morse'));
    Insert(B);
  end;
  C := DeskTop^.ExecView(D);
  Dispose(D, Done);
end;

{ Options/Speed Controls: four delays (numeric input lines) }
{#BOMBCFG_208F}
procedure TMyApp.M208F;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 45, 13);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Speed Contol'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1007;
    R.Assign(0, 1, 25, 2);
    B := New(PLabel, Init(R, 'Reminder: Small is Fast!', nil));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    R.Assign(30, 3, 35, 4);
    B := New(PNumInputLine, Init(R, 3, 0, 999));
    Insert(B);
    R.Assign(2, 3, 30, 4);
    B := New(PLabel, Init(R, 'Turret Speed.............: ', B));
    Insert(B);
    R.Assign(30, 4, 35, 5);
    B := New(PNumInputLine, Init(R, 3, 0, 999));
    Insert(B);
    R.Assign(2, 4, 30, 5);
    B := New(PLabel, Init(R, 'Fall Speed...............: ', B));
    Insert(B);
    R.Assign(30, 5, 35, 6);
    B := New(PNumInputLine, Init(R, 3, 0, 999));
    Insert(B);
    R.Assign(2, 5, 30, 6);
    B := New(PLabel, Init(R, 'Explotion Speed..........: ', B));
    Insert(B);
    R.Assign(30, 6, 35, 7);
    B := New(PNumInputLine, Init(R, 3, 1, 999));
    Insert(B);
    R.Assign(2, 6, 30, 7);
    B := New(PLabel, Init(R, 'Projectile Speed.........: ', B));
    Insert(B);
    R.Assign(22, 8, 28, 10);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(30, 8, 40, 10);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    SelectNext(False);
    SetData(SpeedData_100A);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(SpeedData_100A);
  Dispose(D, Done);
end;

{ Options/Hardware: video/palette check boxes, mouse radio buttons }
{#BOMBCFG_2587}
procedure TMyApp.M2587;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 65, 10);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Hardware Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1008;
    R.Assign(26, 7, 32, 9);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(34, 7, 44, 9);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(2, 3, 38, 6);
    B := New(PMyCheckBoxes, Init(R,
      NewSItem('~D~irect Video Port Manipulation',
      NewSItem('-X-X-X-X-X-X-X-X-X-X-X-X',
      NewSItem('~C~rude Palette I/O',
      nil)))));
    Insert(B);
    R.Assign(2, 2, 23, 3);
    B := New(PLabel, Init(R, 'Check all that Apply', B));
    Insert(B);
    R.Assign(40, 3, 63, 6);
    B := New(PMyRadioButtons, Init(R,
      NewSItem('~Y~es, Mouse Exists',
      NewSItem('~N~o Mice Here',
      NewSItem('~C~heck Upon Loadup',
      nil)))));
    Insert(B);
    R.Assign(40, 2, 55, 3);
    B := New(PLabel, Init(R, 'Mouse Options:', B));
    Insert(B);
    SetData(HwData_1000);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(HwData_1000);
  Dispose(D, Done);
end;

{ Options/Palette Control: palette interface and speed }
{#BOMBCFG_28D7}
procedure TMyApp.M28D7;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
  L: PView;
begin
  R.Assign(0, 0, 38, 14);
  R.Move(10, 5);
  D := New(PDialog, Init(R, 'Palette Options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := 1009;
    R.Assign(8, 7, 14, 9);
    Insert(New(PButton, Init(R, '~O~k', cmOK, bfDefault)));
    R.Assign(25, 7, 35, 9);
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    R.Assign(2, 3, 33, 6);
    B := New(PMyRadioButtons, Init(R,
      NewSItem('~V~ideo Retrace Interrupt',
      NewSItem('~T~imer Interrupt',
      NewSItem('~N~ot Active',
      nil)))));
    Insert(B);
    R.Assign(2, 2, 33, 3);
    B := New(PLabel, Init(R, 'Select Palette Interface:', B));
    Insert(B);
    R.Assign(43, 11, 48, 12);
    B := New(PNumInputLine, Init(R, 3, 0, 999));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    L := B;
    R.Assign(0, 9, 21, 10);
    B := New(PLabel, Init(R, 'Type Desired Palette', B));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    R.Assign(0, 10, 19, 11);
    B := New(PLabel, Init(R, 'Speed (0 Fastest):', L));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    SetData(PalData_1004);
  end;
  C := DeskTop^.ExecView(D);
  if C <> cmCancel then D^.GetData(PalData_1004);
  Dispose(D, Done);
end;

{ "BOMB.CFG not found" message }
{#BOMBCFG_2C9E}
procedure TMyApp.M2C9E;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 40, 11);
  D := New(PDialog, Init(R, 'File Error'));
  with D^ do
  begin
    Options := Options or ofCentered;
    Flags := Flags and not wfClose;
    GetExtent(R);
    R.A.Y := R.B.Y - 3;
    R.B.Y := R.B.Y - 1;
    R.B.X := 10;
    B := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    GetExtent(R);
    R.Grow(-3, -3);
    R.Move(0, -1);
    Insert(New(PStaticText, Init(R,
      ^C'A valid BOMB.CFG was not found in the current directory.  '#13 +
      ^C'All options will be set to default and a new file will be created upon saveing.')));
  end;
  C := DeskTop^.ExecView(D);
  Dispose(D, Done);
end;

{ "BOMB.CFG has another version" message }
{#BOMBCFG_2EC9}
procedure TMyApp.M2EC9(FileVer: TVerStr);
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 60, 13);
  D := New(PDialog, Init(R, 'File Error'));
  with D^ do
  begin
    Options := Options or ofCentered;
    Flags := Flags and not wfClose;
    GetExtent(R);
    R.A.Y := R.B.Y - 3;
    R.B.Y := R.B.Y - 1;
    R.B.X := 10;
    B := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    GetExtent(R);
    R.Grow(-3, -3);
    R.Move(0, -1);
    Insert(New(PStaticText, Init(R,
      ^C'Program Version: ' + Version_011E + #13 + ^C + 'BOMB.CFG Version: ' +
      FileVer + #13 + #13 +
      '  The located configuration file does not match this version of Tank Wars.  ' +
      'All possible data will be loaded from the file, and it will be rewritten' +
      ' upon saveing.')));
  end;
  C := DeskTop^.ExecView(D);
  Dispose(D, Done);
end;

{ Setup/Restore Defaults }
{#BOMBCFG_30B1}
procedure TMyApp.M30B1;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 30, 7);
  D := New(PDialog, Init(R, ''));
  with D^ do
  begin
    HelpCtx := 1011;
    Options := Options or ofCentered;
    Flags := Flags and not wfClose;
    GetExtent(R);
    R.A.Y := R.B.Y - 3;
    R.B.Y := R.B.Y - 1;
    R.B.X := 10;
    B := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
    B^.Options := B^.Options or ofCenterX;
    Insert(B);
    GetExtent(R);
    R.Grow(-3, -3);
    R.Move(0, -1);
    Insert(New(PStaticText, Init(R, ^C'Defaults Restored')));
  end;
  C := DeskTop^.ExecView(D);
  Dispose(D, Done);
  M4319;
end;

{ load BOMB.CFG (after setting the defaults) }
procedure TMyApp.M3E34;
var
  F: File;
  SR: SearchRec;
  V: TVerStr;
  B: Boolean;
  W: Word;
  N: Word;

  { a file of version 2.5 }
{#BOMBCFG_320F} procedure Load25;
  begin
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(SoundData_0FE8, 1, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(SoundData_0FE8, 2, B);
    BlockRead(F, EnvData_0FF2.Wind, 2, N);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, EnvData_0FF2.Crumble);
    BlockRead(F, EnvData_0FF2.Wall, 2, N);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(ShotData_0FFA, 1, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(ShotData_0FFA, 2, B);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, GamesData_0FEA);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(TankData_0FFC, 1, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(TankData_0FFC, 2, B);
    BlockRead(F, BackData_0FEE.Which, 2, N);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Mouse, 2, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Mouse, 1, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 1, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 2, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 3, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 4, B);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, PalData_1004.Speed);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(CompData_0FFE, 1, B);
  end;

  { a file of version 3.0 }
{#BOMBCFG_3762} procedure Load30;
  begin
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(SoundData_0FE8, 1, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(SoundData_0FE8, 2, B);
    BlockRead(F, EnvData_0FF2.Wind, 2, N);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, EnvData_0FF2.Crumble);
    BlockRead(F, EnvData_0FF2.Wall, 2, N);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(ShotData_0FFA, 1, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(ShotData_0FFA, 2, B);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, GamesData_0FEA);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(TankData_0FFC, 2, B);
    BlockRead(F, BackData_0FEE.Which, 2, N);
    BlockRead(F, BackData_0FEE.UserSet, 2, N);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Mouse, 2, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Mouse, 1, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 1, B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(PalData_1004.Iface, 2, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(HwData_1000.Flags, 4, B);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, PalData_1004.Speed);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(CompData_0FFE, 1, B);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, SpeedData_100A.Turret);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, SpeedData_100A.Fall);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, SpeedData_100A.Explosion);
    BlockRead(F, W, 2, N);
    if N = 2 then Str(W, SpeedData_100A.Projectile);
    BlockRead(F, B, 1, N);
    if (N = 1) and (PalData_1004.Iface <> 2) then M43E5(PalData_1004.Iface, 1, not B);
    BlockRead(F, B, 1, N);
    if N = 1 then M43E5(TankData_0FFC, 3, B);
  end;

{#BOMBCFG_3E34}
begin
  M4319;
  FindFirst('BOMB.CFG', AnyFile, SR);
  if DosError <> 0 then
    M2C9E
  else
  begin
    Assign(F, 'bomb.cfg');
    Reset(F, 1);
    V := 'BADx';
    BlockRead(F, V, 5);
    if V <> Version_011E then M2EC9(V);
    if V = '2.5'#0 then Load25;
    if V = Version_011E then Load30;
    Close(F);
  end;
end;

{ save BOMB.CFG }
{#BOMBCFG_3F1C}
procedure TMyApp.M3F1C;
var
  F: File;
  R: TRect;                     { unused }
  B: Boolean;
  W: Integer;
  Code: Integer;
begin
  Assign(F, 'bomb.cfg');
  Rewrite(F, 1);
  BlockWrite(F, Version_011E, 5);
  B := SoundData_0FE8 and 1 = 1;
  BlockWrite(F, B, 1);
  B := SoundData_0FE8 and 2 = 2;
  BlockWrite(F, B, 1);
  BlockWrite(F, EnvData_0FF2.Wind, 2);
  Val(EnvData_0FF2.Crumble, W, Code);
  BlockWrite(F, W, 2);
  BlockWrite(F, EnvData_0FF2.Wall, 2);
  B := ShotData_0FFA and 1 <> 1;
  BlockWrite(F, B, 1);
  B := ShotData_0FFA and 2 = 2;
  BlockWrite(F, B, 1);
  Val(GamesData_0FEA, W, Code);
  BlockWrite(F, W, 2);
  B := TankData_0FFC and 2 = 2;
  BlockWrite(F, B, 1);
  BlockWrite(F, BackData_0FEE.Which, 2);
  BlockWrite(F, BackData_0FEE.UserSet, 2);
  B := HwData_1000.Mouse <> 2;
  BlockWrite(F, B, 1);
  B := HwData_1000.Mouse and 1 <> 1;
  BlockWrite(F, B, 1);
  B := HwData_1000.Flags and 1 = 1;
  BlockWrite(F, B, 1);
  B := PalData_1004.Iface <> 2;
  BlockWrite(F, B, 1);
  B := HwData_1000.Flags and 8 = 8;
  BlockWrite(F, B, 1);
  Val(PalData_1004.Speed, W, Code);
  BlockWrite(F, W, 2);
  B := CompData_0FFE and 1 = 1;
  BlockWrite(F, B, 1);
  Val(SpeedData_100A.Turret, W, Code);
  BlockWrite(F, W, 2);
  Val(SpeedData_100A.Fall, W, Code);
  BlockWrite(F, W, 2);
  Val(SpeedData_100A.Explosion, W, Code);
  BlockWrite(F, W, 2);
  Val(SpeedData_100A.Projectile, W, Code);
  BlockWrite(F, W, 2);
  B := PalData_1004.Iface = 0;
  BlockWrite(F, B, 1);
  B := TankData_0FFC and 4 = 4;
  BlockWrite(F, B, 1);
  Close(F);
end;

{ default settings }
{#BOMBCFG_4319}
procedure TMyApp.M4319;
begin
  SoundData_0FE8 := 1;
  GamesData_0FEA := '10';
  BackData_0FEE.Which := 9;
  BackData_0FEE.UserSet := $FFFF;
  EnvData_0FF2.Wall := 0;
  EnvData_0FF2.Wind := 2;
  EnvData_0FF2.Crumble := '75';
  ShotData_0FFA := 3;
  TankData_0FFC := 3;
  CompData_0FFE := 1;
  HwData_1000.Mouse := 2;
  HwData_1000.Flags := 15;
  PalData_1004.Speed := '0';
  PalData_1004.Iface := 0;
  SpeedData_100A.Turret := '8';
  SpeedData_100A.Fall := '5';
  SpeedData_100A.Explosion := '8';
  SpeedData_100A.Projectile := '10';
end;

{ set (Value) or clear bit number Bit (1 = lowest) of X }
{#BOMBCFG_43E5}
procedure TMyApp.M43E5(var X: Word; Bit: Word; Value: Boolean);
begin
  if Value then
    X := X or U2918_00A5(2, Bit - 1)
  else
    X := X and not U2918_00A5(2, Bit - 1);
end;

{$IFDEF KEEPALL}
{$I KEEPALL.INC}
{$ENDIF}

{#BOMBCFG_44AE}
begin
  {$IFDEF KEEPALL} if ParamCount = 9999 then KeepAll; {$ENDIF}
  Copyright_101A := 'TANK WARS Configuration Copyright 1991, 1992 Kenneth Morse';
  Copyright_101A := 'All Rights Reserved.';
  MyApp_0FB0.Init;
  MyApp_0FB0.Run;
  MyApp_0FB0.Done;
end.
