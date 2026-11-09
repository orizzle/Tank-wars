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
  AINames_007C: array[0..7] of String absolute c_007C;

type
  { per-player block of $7DA bytes, cleared by U0728_0216 (structure unknown;
    array[1..10] at DS 5134, indexed from 0 at DS 495A) }
  T7DA = array[0..$7D9] of Byte;

var
  Rec_495A: array[0..10] of T7DA absolute g_495A;

function U0728_0007(B: Boolean): string;
function U0728_0043(B: Boolean): string;
procedure U0728_0078(I: Integer);
procedure U0728_0216(I: Integer);
procedure U0728_04D0;
procedure U0728_05D8;
procedure U0728_06B1;
procedure U0728_06D1;
procedure U0728_07CE;
procedure U0728_08E6;
procedure U0728_09B5;
function U0728_0DEF(N: Integer): string;
function U0728_0F3B(N: Integer): string;
function U0728_0FFC(N: Integer): string;
procedure U0728_1186;
procedure U0728_1DD5;
procedure U0728_2609;
procedure U0728_302C(T: Integer);
procedure U0728_3449;
procedure U0728_3A10(Kind: Integer);
procedure U0728_3BC3;
procedure U0728_4183(P: Word);
procedure U0728_46AC(P: Word);
procedure U0728_5083;
procedure U0728_62E4;

implementation




uses
  U0E9B, U0098, U1615, U1B27, U1DD4, U1F69,
  U20C6, U22B7, U2390;

{$I U0728_A.INC}
{$I U0728_B.INC}

end.
