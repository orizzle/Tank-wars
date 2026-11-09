{$A+,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit C0453;

{ Numeric input line for the BOMBCFG dialogs: a TInputLine that accepts
  only digits (and editing keys) and, when the dialog is closed, checks
  that the number lies between Min and Max; if not, an "Entry Error"
  box is shown. }

interface

uses Objects, Drivers, Views, Dialogs, App, U2918;

type
  PNumInputLine = ^TNumInputLine;
  TNumInputLine = object(TInputLine)
    Max, Min: LongInt;
    constructor Init(var Bounds: TRect; AMaxLen: Integer; AMin, AMax: LongInt);
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Command: Word): Boolean; virtual;
    procedure RangeError;
  end;

implementation

{ swallow every key that cannot be part of a number }
{#C0453_0020}
procedure TNumInputLine.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and
     not (Event.CharCode in [#0, #8, #9, #13, #27, '0'..'9']) then
    ClearEvent(Event);
  TInputLine.HandleEvent(Event);
end;

{#C0453_0062}
constructor TNumInputLine.Init(var Bounds: TRect; AMaxLen: Integer; AMin, AMax: LongInt);
begin
  TInputLine.Init(Bounds, AMaxLen);
  Max := AMax;
  Min := AMin;
end;

{ NOTE: the result is left undefined unless the value is out of range }
{#C0453_00AE}
function TNumInputLine.Valid(Command: Word): Boolean;
var
  Value: Integer;
  Code: Integer;
begin
  TInputLine.Valid(Command);
  if Command <> cmQuit then
  begin
    Val(Data^, Value, Code);
    if (Value < Min) or (Value > Max) then
    begin
      RangeError;
      Valid := False;
    end;
  end;
end;

{#C0453_01A9}
procedure TNumInputLine.RangeError;
var
  D: PDialog;
  R: TRect;
  C: Word;
  B: PView;
begin
  R.Assign(0, 0, 40, 11);
  D := New(PDialog, Init(R, 'Entry Error'));
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
      ^C'  You must enter a numeric integer between ' + IntToStr(Min) +
      ' and ' + IntToStr(Max) + '.' +
      '  Failure to do so will result in this annoying box appearing again!')));
  end;
  C := DeskTop^.ExecView(D);
  Dispose(D, Done);
end;

end.
