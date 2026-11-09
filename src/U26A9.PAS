{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U26A9;

{ Player damage and the player's colour (palette entry 19 + player number,
  brightness proportional to the number of men left). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4;

function  ApplyDamage(Amount: Integer; Idx: Byte; var P: TPlayer): Integer;
procedure UpdatePlayerColor(var P: TPlayer);
procedure SetPlayerNum(Num: Integer; var P { TPlayer });
procedure SetPlayerMen(Men: Integer; var P: TPlayer);
procedure AddScore(Amount: Integer; var P: TPlayer);
procedure SetPlayerColor(Men: Integer; var P: TPlayer);
procedure GetPlayerRGB(var R, G, B: Integer; var P: TPlayer);

implementation

{ Take Amount of damage on Guidance[Idx] (shield etc.); what goes through
  costs men.  Returns the number of men lost. }
{#U26A9_0004}
function ApplyDamage(Amount: Integer; Idx: Byte; var P: TPlayer): Integer;
var
  Old: Integer;
begin
  P.Guidance[Idx] := P.Guidance[Idx] - Amount;
  Old := P.Men;
  if P.Guidance[Idx] < 0 then
  begin
    P.Men := P.Men + P.Guidance[Idx];
    if P.Men < 0 then
      P.Men := 0;
    if (Idx <> 1) and (P.Guidance[2] > 0) then
      if Random < -P.Guidance[Idx] / 40 then
        Dec(P.Guidance[2]);
    P.Guidance[Idx] := 0;
    UpdatePlayerColor(P);
  end;
  ApplyDamage := Old - P.Men;
end;

{ update the player's colour }
{#U26A9_014E}
procedure UpdatePlayerColor(var P: TPlayer);
begin
  SetPlayerColor(P.Men, P);
end;

{#U26A9_0165}
procedure SetPlayerNum(Num: Integer; var P { TPlayer });
begin
  { untyped: ResetPlayer passes the f00 field of a with-record }
  TPlayer(P).f00 := Num;
end;

{#U26A9_0175}
procedure SetPlayerMen(Men: Integer; var P: TPlayer);
begin
  P.Men := Men;
  UpdatePlayerColor(P);
end;

{#U26A9_018F}
procedure AddScore(Amount: Integer; var P: TPlayer);
begin
  P.Score := P.Score + Amount;
end;

{ set palette entry 19 + P.f00 according to Men }
{#U26A9_01B0}
procedure SetPlayerColor(Men: Integer; var P: TPlayer);
var
  L: Integer;
begin
  L := 63 * Men div 100;
  if Men > 0 then
    RGBHook(P.f00 + 19, L div P.f60, L div P.f62, L div P.f64)
  else
    RGBHook(P.f00 + 19, 0, 0, 0);
end;

{ the player's current RGB colour }
{#U26A9_0220}
procedure GetPlayerRGB(var R, G, B: Integer; var P: TPlayer);
var
  L: Integer;
begin
  L := 63 * Players[P.f00].Men div 100;
  R := L div Players[P.f00].f60;
  G := L div Players[P.f00].f62;
  B := L div Players[P.f00].f64;
end;

end.
