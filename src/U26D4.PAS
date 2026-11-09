{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U26D4;

{ Integer-degree trigonometry using a precomputed table of 6-byte Reals
  (SinTable, linked from SINTAB.OBJ; entry n = sin(n degrees), n = 0..90). }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1;

function U26D4_0000(Deg: Integer): Real;
function U26D4_005A(Deg: Integer): Real;
function U26D4_00BD(Deg: Integer): Real;
procedure SinTable;

implementation

{ Sin(Deg), Deg in degrees }
{#U26D4_0000}
function U26D4_0000(Deg: Integer): Real; assembler;
var
  Sign: Byte;
asm
        mov     Sign, 0
        cmp     Deg, 0
        jge     @1
        neg     Deg
        mov     Sign, 80h
@1:     cmp     Deg, 180
        jle     @2
        xor     Sign, 80h
        sub     Deg, 180
        jmp     @1
@2:     cmp     Deg, 90
        jbe     @3
        mov     ax, 180
        xchg    Deg, ax
        sub     Deg, ax
@3:     mov     ax, Deg
        mov     bx, 6
        mul     bl
        mov     bx, ax
        mov     ax, word ptr cs:[bx+offset SinTable]
        mov     dx, word ptr cs:[bx+offset SinTable+4]
        mov     bx, word ptr cs:[bx+offset SinTable+2]
        xor     dh, Sign
end;

{ Cos(Deg) = Sin(90 - Deg) }
{#U26D4_005A}
function U26D4_005A(Deg: Integer): Real; assembler;
var
  Sign: Byte;
asm
        mov     ax, 90
        sub     ax, Deg
        mov     Deg, ax
        mov     Sign, 0
        cmp     Deg, 0
        jge     @1
        neg     Deg
        mov     Sign, 80h
@1:     cmp     Deg, 180
        jle     @2
        xor     Sign, 80h
        sub     Deg, 180
        jmp     @1
@2:     cmp     Deg, 90
        jbe     @3
        mov     ax, 180
        xchg    Deg, ax
        sub     Deg, ax
@3:     mov     ax, Deg
        mov     bx, 6
        mul     bl
        mov     bx, ax
        mov     ax, word ptr cs:[bx+offset SinTable]
        mov     dx, word ptr cs:[bx+offset SinTable+4]
        mov     bx, word ptr cs:[bx+offset SinTable+2]
        xor     dh, Sign
end;

{ Tan(Deg) }
{#U26D4_00BD}
function U26D4_00BD(Deg: Integer): Real;
begin
  U26D4_00BD := U26D4_0000(Deg) / U26D4_005A(Deg);
end;

procedure SinTable; external; {$L SINTAB.OBJ}

{#U26D4_00FB}
begin
end.
