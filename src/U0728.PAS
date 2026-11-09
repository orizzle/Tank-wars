{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U0728;

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

type
  TScreenBuf = array[0..63999] of Byte;   { 320x200 VGA screen image }

var
  { names of the computer players: typed constant array in GLOBALS
    (DS 007C..087B, only partly typed there yet) }
  AINames: array[0..7] of String absolute AIName0;  { DS:007C }

type
  { per-player block of $7DA bytes, cleared by ResetPlayer (structure unknown;
    array[1..10] at DS 5134, indexed from 0 at DS 495A) }
  T7DA = array[0..$7D9] of Byte;

var
  ShotLogRecs: array[0..10] of T7DA absolute ShotLogData;  { DS:495A }

function YesNoStr(B: Boolean): string;
function OnOffStr(B: Boolean): string;
procedure CreateAIPlayer(I: Integer);
procedure ResetPlayer(I: Integer);
procedure CheckMouse;
procedure ShowCpuType;
procedure InitMouseCursor;
procedure DrawTitleBox;
procedure DrawStartButton;
procedure DrawMainMenuHeader;
procedure SoundOptionsDialog;
function BackgroundName(N: Integer): string;
function WallTypeName(N: Integer): string;
function WindForceName(N: Integer): string;
procedure GameOptionsDialog;
procedure RunMainMenu;
procedure TeamSetupScreen;
procedure EditTeamName(T: Integer);
procedure BuildTeams;
procedure DrawMenuBackground(Kind: Integer);
procedure SetupGame;
procedure EditPlayerName(P: Word);
procedure SelectAIType(P: Word);
procedure PlayerSetupScreen;
procedure LoadSettings;

implementation




uses
  U0E9B, U0098, U1615, U1B27, U1DD4, U1F69,
  U20C6, U22B7, U2390;

{$I U0728_A.INC}
{$I U0728_B.INC}

end.
