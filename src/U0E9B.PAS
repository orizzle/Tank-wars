{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U0E9B;

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9,
  U23C3;

procedure SwapPlayers(A, B: Integer);
procedure DrawShopButtons(PNum: Integer);
procedure RunShop;
procedure ShufflePlayers;
procedure ShowPlayerStats(P: Integer);
procedure ShowTeamStats(T: Integer);
procedure EditSaveName;
procedure SaveGame(FileName: string);
procedure LoadGame(FileName: string);
procedure SaveGameDialog;
procedure LoadGameDialog;
procedure AddGamesDialog;
procedure ShowStandings;
procedure ShowTeamStandings;
procedure PrintFinalResults;
procedure PlayGames;

implementation




uses
  U1615, U0098, U0728, U1B27, U1DD4, U1F69,
  U20C6, U22B7, U2390;

{$I U0E9B_A.INC}
{$I U0E9B_B.INC}

end.
