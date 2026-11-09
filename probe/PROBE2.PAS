{$N-,F+,S-,R-,I+,X+}
program Probe2;
type
  PObj = ^TObj;
  TObj = object
    x: integer;
    constructor Init;
    destructor Done; virtual;
    procedure Show; virtual;
  end;
var r,r2: real; i: integer; l: longint; b: boolean; o: TObj; p: PObj; s: string;
constructor TObj.Init; begin x := 1; end;
destructor TObj.Done; begin end;
procedure TObj.Show; begin end;
procedure sy_radd; begin r:=r+r2; end;
procedure sy_rsub; begin r:=r-r2; end;
procedure sy_rmul; begin r:=r*r2; end;
procedure sy_rdiv; begin r:=r/r2; end;
procedure sy_rcmp; begin b:=r<r2; end;
procedure sy_rint2real; begin r:=i; end;
procedure sy_rlong2real; begin r:=l; end;
procedure sy_rtrunc; begin l:=Trunc(r); end;
procedure sy_rround; begin l:=Round(r); end;
procedure sy_rsin; begin r:=Sin(r); end;
procedure sy_rcos; begin r:=Cos(r); end;
procedure sy_rsqrt; begin r:=Sqrt(r); end;
procedure sy_rarctan; begin r:=ArcTan(r); end;
procedure sy_rln; begin r:=Ln(r); end;
procedure sy_rexp; begin r:=Exp(r); end;
procedure sy_rsqr; begin r:=Sqr(r); end;
procedure sy_rint; begin r:=Int(r); end;
procedure sy_rfrac; begin r:=Frac(r); end;
procedure sy_rneg; begin r:=-r; end;
procedure sy_rabs; begin r:=Abs(r); end;
procedure sy_rstr; begin Str(r:5:2,s); end;
procedure sy_rwrite; begin Write(r:5:2); end;
procedure sy_rrandom; begin r:=Random; end;
procedure sy_objinit; begin o.Init; end;
procedure sy_objshow; begin o.Show; end;
procedure sy_newobj; begin New(p, Init); end;
procedure sy_dispobj; begin Dispose(p, Done); end;
procedure sy_pshow; begin p^.Show; end;
procedure sy_readln; begin Readln(s); end;
procedure sy_readint; begin Readln(i); end;
procedure sy_readlnplain; begin Readln; end;
begin
  sy_radd; sy_rsub; sy_rmul; sy_rdiv; sy_rcmp; sy_rint2real; sy_rlong2real; sy_rtrunc; sy_rround;
  sy_rsin; sy_rcos; sy_rsqrt; sy_rarctan; sy_rln; sy_rexp; sy_rsqr; sy_rint; sy_rfrac; sy_rneg; sy_rabs;
  sy_rstr; sy_rwrite; sy_rrandom; sy_objinit; sy_objshow; sy_newobj; sy_dispobj; sy_pshow;
  sy_readln; sy_readint; sy_readlnplain;
end.
