{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U26A9;

{ Player damage and the player's colour (palette entry 19 + player number,
  brightness proportional to the number of men left). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4;

function  U26A9_0004(Amount: Integer; Idx: Byte; var P: TPlayer): Integer;
procedure U26A9_014E(var P: TPlayer);
procedure U26A9_0165(Num: Integer; var P { TPlayer });
procedure U26A9_0175(Men: Integer; var P: TPlayer);
procedure U26A9_018F(Amount: Integer; var P: TPlayer);
procedure U26A9_01B0(Men: Integer; var P: TPlayer);
procedure U26A9_0220(var R, G, B: Integer; var P: TPlayer);

implementation

{ Take Amount of damage on Guidance[Idx] (shield etc.); what goes through
  costs men.  Returns the number of men lost. }
{#U26A9_0004}
function U26A9_0004(Amount: Integer; Idx: Byte; var P: TPlayer): Integer;
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
    U26A9_014E(P);
  end;
  U26A9_0004 := Old - P.Men;
end;

{ update the player's colour }
{#U26A9_014E}
procedure U26A9_014E(var P: TPlayer);
begin
  U26A9_01B0(P.Men, P);
end;

{#U26A9_0165}
procedure U26A9_0165(Num: Integer; var P { TPlayer });
begin
  { untyped: U0728_0216 passes the f00 field of a with-record }
  TPlayer(P).f00 := Num;
end;

{#U26A9_0175}
procedure U26A9_0175(Men: Integer; var P: TPlayer);
begin
  P.Men := Men;
  U26A9_014E(P);
end;

{#U26A9_018F}
procedure U26A9_018F(Amount: Integer; var P: TPlayer);
begin
  P.Score := P.Score + Amount;
end;

{ set palette entry 19 + P.f00 according to Men }
{#U26A9_01B0}
procedure U26A9_01B0(Men: Integer; var P: TPlayer);
var
  L: Integer;
begin
  L := 63 * Men div 100;
  if Men > 0 then
    g_E7C8(P.f00 + 19, L div P.f60, L div P.f62, L div P.f64)
  else
    g_E7C8(P.f00 + 19, 0, 0, 0);
end;

{ the player's current RGB colour }
{#U26A9_0220}
procedure U26A9_0220(var R, G, B: Integer; var P: TPlayer);
var
  L: Integer;
begin
  L := 63 * Players_3F0E[P.f00].Men div 100;
  R := L div Players_3F0E[P.f00].f60;
  G := L div Players_3F0E[P.f00].f62;
  B := L div Players_3F0E[P.f00].f64;
end;

end.
