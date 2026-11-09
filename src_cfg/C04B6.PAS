{$A+,B+,D+,F+,G-,I-,L+,N-,E+,O+,R-,S-,V+,X+}
unit C04B6;

{ Turbo Vision on-line help: the HELPFILE unit of Borland's Turbo Vision 1.0
  demo programs (TVDEMOS\HELPFILE.PAS of Turbo Pascal 6.0), compiled into
  BOMBCFG.  Help topics (paragraphs + cross references), the help file
  index, the help file object (a stream of topics), the help viewer (a
  scroller) and the help window.
  Compiled $O+ (string constants passed as value parameters are first
  copied to the stack) and $B+ (complete boolean evaluation). }

interface

uses Objects, Drivers, Views;

type

{ TParagraph }

  PParagraph = ^TParagraph;
  TParagraph = record
    Next: PParagraph;
    Wrap: Boolean;
    Size: Word;
    Text: record end;
  end;

{ TCrossRef }

  TCrossRef = record
    Ref: Word;
    Offset: Integer;
    Length: Byte;
  end;

  PCrossRefs = ^TCrossRefs;
  TCrossRefs = array[1..10000] of TCrossRef;
  TCrossRefHandler = procedure (var S: TStream; XRefValue: Integer);

{ THelpTopic }

  PHelpTopic = ^THelpTopic;
  THelpTopic = object(TObject)
    Paragraphs: PParagraph;
    NumRefs: Integer;
    CrossRefs: PCrossRefs;
    Width: Integer;
    LastOffset: Integer;
    LastLine: Integer;
    LastParagraph: PParagraph;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure AddCrossRef(Ref: TCrossRef);
    procedure AddParagraph(P: PParagraph);
    procedure GetCrossRef(I: Integer; var Loc: TPoint; var Length: Byte; var Ref: Word);
    function GetLine(Line: Integer): String;
    function GetNumCrossRefs: Integer;
    function NumLines: Integer;
    procedure SetCrossRef(I: Integer; var Ref: TCrossRef);
    procedure SetNumCrossRefs(I: Integer);
    procedure SetWidth(AWidth: Integer);
    procedure Store(var S: TStream);
    function WrapText(var Text; Size: Integer; var Offset: Integer;
      Wrap: Boolean): String;
  end;

{ THelpIndex }

  PIndexArray = ^TIndexArray;
  TIndexArray = array[0..16380] of LongInt;

  PHelpIndex = ^THelpIndex;
  THelpIndex = object(TObject)
    Size: Word;
    Index: PIndexArray;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function Position(I: Integer): Longint;
    procedure Add(I: Integer; Val: Longint);
    procedure Store(var S: TStream);
  end;

{ THelpFile }

  PHelpFile = ^THelpFile;
  THelpFile = object(TObject)
    Stream: PStream;
    Modified: Boolean;
    Index: PHelpIndex;
    IndexPos: Longint;
    constructor Init(S: PStream);
    destructor Done; virtual;
    function GetTopic(I: Integer): PHelpTopic;
    function InvalidTopic: PHelpTopic;
    procedure RecordPositionInIndex(I: Integer);
    procedure PutTopic(Topic: PHelpTopic);
  end;

{ THelpViewer }

  PHelpViewer = ^THelpViewer;
  THelpViewer = object(TScroller)
    HFile: PHelpFile;
    Topic: PHelpTopic;
    Selected: Integer;
    constructor Init(var Bounds: TRect; AHScrollBar,
      AVScrollBar: PScrollBar; AHelpFile: PHelpFile; Context: Word);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

{ THelpWindow }

  PHelpWindow = ^THelpWindow;
  THelpWindow = object(TWindow)
    constructor Init(HFile: PHelpFile; Context: Word);
  end;

const
  RHelpTopic: TStreamRec = (
     ObjType: 10000;
     VmtLink: Ofs(TypeOf(THelpTopic)^);
     Load:    @THelpTopic.Load;
     Store:   @THelpTopic.Store
  );

const
  RHelpIndex: TStreamRec = (
     ObjType: 10001;
     VmtLink: Ofs(TypeOf(THelpIndex)^);
     Load:    @THelpIndex.Load;
     Store:   @THelpIndex.Store
  );

procedure RegisterHelpFile;

procedure NotAssigned(var S: TStream; Value: Integer);

const
  CrossRefHandler: TCrossRefHandler = NotAssigned;

implementation

{ THelpTopic }

{#C04B6_0000}
constructor THelpTopic.Init;
begin
  TObject.Init;
  LastLine := MaxInt;
end;

constructor THelpTopic.Load(var S: TStream);

{#C04B6_002B} procedure ReadParagraphs;
  var
    I, Size: Integer;
    PP: ^PParagraph;
  begin
    S.Read(I, SizeOf(I));
    PP := @Paragraphs;
    while I > 0 do
    begin
      S.Read(Size, SizeOf(Size));
      GetMem(PP^, SizeOf(PP^^) + Size);
      PP^^.Size := Size;
      S.Read(PP^^.Wrap, SizeOf(Boolean));
      S.Read(PP^^.Text, Size);
      PP := @PP^^.Next;
      Dec(I);
    end;
    PP^ := nil;
  end;

{#C04B6_0105} procedure ReadCrossRefs;
  begin
    S.Read(NumRefs, SizeOf(Integer));
    GetMem(CrossRefs, SizeOf(TCrossRef) * NumRefs);
    S.Read(CrossRefs^, SizeOf(TCrossRef) * NumRefs);
  end;

{#C04B6_0184}
begin
  ReadParagraphs;
  ReadCrossRefs;
  Width := 0;
  LastLine := MaxInt;
end;

destructor THelpTopic.Done;

{#C04B6_01B5} procedure DisposeParagraphs;
  var
    P, T: PParagraph;
  begin
    P := Paragraphs;
    while P <> nil do
    begin
      T := P;
      P := P^.Next;
      FreeMem(T, SizeOf(T^) + T^.Size);
    end;
  end;

{#C04B6_0212}
begin
  DisposeParagraphs;
  FreeMem(CrossRefs, SizeOf(TCrossRef) * NumRefs);
  TObject.Done;
end;

{ not linked into BOMBCFG }
procedure THelpTopic.AddCrossRef(Ref: TCrossRef);
var
  P: PCrossRefs;
begin
  GetMem(P, (NumRefs+1) * SizeOf(TCrossRef));
  if NumRefs > 0 then
  begin
    Move(CrossRefs^, P^, NumRefs * SizeOf(TCrossRef));
    FreeMem(CrossRefs, NumRefs * SizeOf(TCrossRef));
  end;
  CrossRefs := P;
  Inc(NumRefs);
  CrossRefs^[NumRefs] := Ref;
end;

{#C04B6_0252}
procedure THelpTopic.AddParagraph(P: PParagraph);
var
  PP: ^PParagraph;
begin
  PP := @Paragraphs;
  while PP^ <> nil do
    PP := @PP^^.Next;
  PP^ := P;
  P^.Next := nil;
end;

{#C04B6_02A7}
procedure THelpTopic.GetCrossRef(I: Integer; var Loc: TPoint;
  var Length: Byte; var Ref: Word);
var
  OldOffset, CurOffset, Offset, ParaOffset: Integer;
  P: PParagraph;
  Line: Integer;
begin
  ParaOffset := 0;
  CurOffset := 0;
  OldOffset := 0;
  Line := 0;
  Offset := CrossRefs^[I].Offset;
  P := Paragraphs;
  while ParaOffset+CurOffset < Offset do
  begin
    OldOffset := ParaOffset + CurOffset;
    WrapText(P^.Text, P^.Size, CurOffset, P^.Wrap);
    Inc(Line);
    if CurOffset >= P^.Size then
    begin
      Inc(ParaOffset, P^.Size);
      P := P^.Next;
      CurOffset := 0;
    end;
  end;
  Loc.X := Offset - OldOffset - 1;
  Loc.Y := Line;
  Length := CrossRefs^[I].Length;
  Ref := CrossRefs^[I].Ref;
end;

{#C04B6_03CA}
function THelpTopic.GetLine(Line: Integer): String;
var
  Offset, I: Integer;
  P: PParagraph;
begin
  if LastLine < Line then
  begin
    I := Line;
    Dec(Line, LastLine);
    LastLine := I;
    Offset := LastOffset;
    P := LastParagraph;
  end
  else
  begin
    P := Paragraphs;
    Offset := 0;
    LastLine := Line;
  end;
  GetLine := '';
  while (P <> nil) do
  begin
    while Offset < P^.Size do
    begin
      Dec(Line);
      GetLine := WrapText(P^.Text, P^.Size, Offset, P^.Wrap);
      if Line = 0 then
      begin
        LastOffset := Offset;
        LastParagraph := P;
        Exit;
      end;
    end;
    P := P^.Next;
    Offset := 0;
  end;
  GetLine := '';
end;

{#C04B6_04E8}
function THelpTopic.GetNumCrossRefs: Integer;
begin
  GetNumCrossRefs := NumRefs;
end;

{#C04B6_0501}
function THelpTopic.NumLines: Integer;
var
  Offset, Lines: Integer;
  P: PParagraph;
begin
  Offset := 0;
  Lines := 0;
  P := Paragraphs;
  while P <> nil do
  begin
    Offset := 0;
    while Offset < P^.Size do
    begin
      Inc(Lines);
      WrapText(P^.Text, P^.Size, Offset, P^.Wrap);
    end;
    P := P^.Next;
  end;
  NumLines := Lines;
end;

{ not linked into BOMBCFG }
procedure THelpTopic.SetCrossRef(I: Integer; var Ref: TCrossRef);
begin
  if I <= NumRefs then CrossRefs^[I] := Ref;
end;

{ not linked into BOMBCFG }
procedure THelpTopic.SetNumCrossRefs(I: Integer);
var
  P: PCrossRefs;
begin
  if NumRefs = I then Exit;
  GetMem(P, I * SizeOf(TCrossRef));
  if NumRefs > 0 then
  begin
    if I > NumRefs then Move(CrossRefs^, P^, NumRefs * SizeOf(TCrossRef))
    else Move(CrossRefs^, P^, I * SizeOf(TCrossRef));
    FreeMem(CrossRefs, NumRefs * SizeOf(TCrossRef));
  end;
  CrossRefs := P;
  NumRefs := I;
end;

{#C04B6_05A0}
procedure THelpTopic.SetWidth(AWidth: Integer);
begin
  Width := AWidth;
end;

procedure THelpTopic.Store(var S: TStream);

{#C04B6_05B1} procedure WriteParagraphs;
  var
    I: Integer;
    P: PParagraph;
  begin
    P := Paragraphs;
    I := 0;
    while P <> nil do
    begin
      Inc(I);
      P := P^.Next;
    end;
    S.Write(I, SizeOf(I));
    P := Paragraphs;
    while P <> nil do
    begin
      S.Write(P^.Size, SizeOf(Integer));
      S.Write(P^.Wrap, SizeOf(Boolean));
      S.Write(P^.Text, P^.Size);
      P := P^.Next;
    end;
  end;

{#C04B6_0692} procedure WriteCrossRefs;
  var
    I: Integer;
  begin
    S.Write(NumRefs, SizeOf(Integer));
    if @CrossRefHandler = @NotAssigned then
      S.Write(CrossRefs^, SizeOf(TCrossRef) * NumRefs)
    else
      for I := 1 to NumRefs do
      begin
        CrossRefHandler(S, CrossRefs^[I].Ref);
        S.Write(CrossRefs^[I].Offset, SizeOf(Integer) + SizeOf(Byte));
      end;
  end;

{#C04B6_0783}
begin
  WriteParagraphs;
  WriteCrossRefs;
end;

function THelpTopic.WrapText(var Text; Size: Integer;
  var Offset: Integer; Wrap: Boolean): String;
type
  PCArray = ^CArray;
  CArray = array[0..32767] of Char;
var
  Line: String;
  I, P: Integer;

{#C04B6_0794} function IsBlank(Ch: Char): Boolean;
  begin
    IsBlank := (Ch = ' ') or (Ch = #13) or (Ch = #10);
  end;

{#C04B6_07C9} function Scan(var P; Offset: Integer; C: Char): Integer; assembler;
  asm
        CLD
        LES     DI,P
        ADD     DI,&Offset
        MOV     CX,256
        MOV     AL,C
        REPNE   SCASB
        SUB     CX,256
        NEG     CX
        XCHG    AX,CX
  end;

{#C04B6_07E6} procedure TextToLine(var Text; Offset, Length: Integer; var Line: String);
    assembler;
  asm
        CLD
        PUSH    DS
        LDS     SI,Text
        ADD     SI,&Offset
        LES     DI,Line
        MOV     AX,Length
        STOSB
        XCHG    AX,CX
        REP     MOVSB
        POP     DS
  end;

{#C04B6_0800}
begin
  I := Scan(Text, Offset, #13);
  if (I + Offset > Size) then I := Size - Offset;
  if (I >= Width) and Wrap then
  begin
    I := Offset + Width;
    if I > Size then I := Size
    else
    begin
      while (I > Offset) and not IsBlank(CArray(Text)[I]) do Dec(I);
      if I = Offset then I := Offset + Width
      else Inc(I);
    end;
    if I = Offset then I := Offset + Width;
    Dec(I, Offset);
  end;
  TextToLine(Text, Offset, I, Line);
  if Line[Length(Line)] = #13 then Dec(Line[0]);
  Inc(Offset, I);
  WrapText := Line;
end;

{ THelpIndex }

{#C04B6_0948}
constructor THelpIndex.Init;
begin
  TObject.Init;
  Size := 0;
  Index := nil;
end;

{#C04B6_0980}
constructor THelpIndex.Load(var S: TStream);
begin
  S.Read(Size, SizeOf(Size));
  if Size = 0 then Index := nil
  else
  begin
    GetMem(Index, SizeOf(LongInt) * Size);
    S.Read(Index^, SizeOf(LongInt) * Size);
  end;
end;

{#C04B6_0A02}
destructor THelpIndex.Done;
begin
  FreeMem(Index, SizeOf(LongInt) * Size);
  TObject.Done;
end;

{#C04B6_0A39}
function THelpIndex.Position(I: Integer): Longint;
begin
  if I < Size then Position := Index^[I]
  else Position := -1;
end;

{ not linked into BOMBCFG }
procedure THelpIndex.Add(I: Integer; Val: Longint);
const
  Delta = 10;
var
  P: PIndexArray;
  NewSize: Integer;
begin
  if I >= Size then
  begin
    NewSize := (I + Delta) div Delta * Delta;
    GetMem(P, NewSize * SizeOf(LongInt));
    if P <> nil then
    begin
      Move(Index^, P^, Size * SizeOf(LongInt));
      FillChar(P^[Size], (NewSize - Size) * SizeOf(Longint), $FF);
    end;
    if Size > 0 then FreeMem(Index, Size * SizeOf(LongInt));
    Index := P;
    Size := NewSize;
  end;
  Index^[I] := Val;
end;

{#C04B6_0A8F}
procedure THelpIndex.Store(var S: TStream);
begin
  S.Write(Size, SizeOf(Size));
  S.Write(Index^, SizeOf(LongInt) * Size);
end;

{ THelpFile }

const
  MagicHeader = $46484246; {'FBHF'}

{#C04B6_0ACE}
constructor THelpFile.Init(S: PStream);
var
  Magic: Longint;
begin
  Magic := 0;
  S^.Seek(0);
  if S^.GetSize > SizeOf(Magic) then
    S^.Read(Magic, SizeOf(Magic));
  if Magic <> MagicHeader then
  begin
    IndexPos := 12;
    S^.Seek(IndexPos);
    Index := New(PHelpIndex, Init);
    Modified := True;
  end
  else
  begin
    S^.Seek(8);
    S^.Read(IndexPos, SizeOf(IndexPos));
    S^.Seek(IndexPos);
    Index := PHelpIndex(S^.Get);
    Modified := False;
  end;
  Stream := S;
end;

{#C04B6_0BF1}
destructor THelpFile.Done;
var
  Magic, Size: Longint;
begin
  if Modified then
  begin
    Stream^.Seek(IndexPos);
    Stream^.Put(Index);
    Stream^.Seek(0);
    Magic := MagicHeader;
    Size := Stream^.GetSize - 8;
    Stream^.Write(Magic, SizeOf(Magic));
    Stream^.Write(Size, SizeOf(Size));
    Stream^.Write(IndexPos, SizeOf(IndexPos));
  end;
  Dispose(Stream, Done);
  Dispose(Index, Done);
end;

{#C04B6_0CEE}
function THelpFile.GetTopic(I: Integer): PHelpTopic;
var
  Pos: Longint;
begin
  Pos := Index^.Position(I);
  if Pos > 0 then
  begin
    Stream^.Seek(Pos);
    GetTopic := PHelpTopic(Stream^.Get);
  end
  else GetTopic := InvalidTopic;
end;

{#C04B6_0D5E}
function THelpFile.InvalidTopic: PHelpTopic;
const
  InvalidText: array[1..36] of Char = #13' No help available in this context.';
var
  Topic: PHelpTopic;
  Para: PParagraph;
begin
  Topic := New(PHelpTopic, Init);
  GetMem(Para, SizeOf(Para^) + SizeOf(InvalidText));
  Para^.Size := SizeOf(InvalidText);
  Para^.Wrap := False;
  Para^.Next := nil;
  Move(InvalidText, Para^.Text, SizeOf(InvalidText));
  Topic^.AddParagraph(Para);
  InvalidTopic := Topic;
end;

{ not linked into BOMBCFG }
procedure THelpFile.RecordPositionInIndex(I: Integer);
begin
  Index^.Add(I, IndexPos);
  Modified := True;
end;

{ not linked into BOMBCFG }
procedure THelpFile.PutTopic(Topic: PHelpTopic);
begin
  Stream^.Seek(IndexPos);
  Stream^.Put(Topic);
  IndexPos := Stream^.GetPos;
  Modified := True;
end;

{ THelpViewer }

{#C04B6_0DE0}
constructor THelpViewer.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AHelpFile: PHelpFile; Context: Word);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or ofSelectable;
  GrowMode := gfGrowHiX + gfGrowHiY;
  HFile := AHelpFile;
  Topic := AHelpFile^.GetTopic(Context);
  Topic^.SetWidth(Size.X);
  SetLimit(78, Topic^.NumLines);
  Selected := 1;
end;

{#C04B6_0E90}
destructor THelpViewer.Done;
begin
  TScroller.Done;
  Dispose(HFile, Done);
  Dispose(Topic, Done);
end;

{#C04B6_0ECF}
procedure THelpViewer.ChangeBounds(var Bounds: TRect);
begin
  TScroller.ChangeBounds(Bounds);
  Topic^.SetWidth(Size.X);
  SetLimit(Limit.X, Topic^.NumLines);
end;

{#C04B6_0F18}
procedure THelpViewer.Draw;
var
  B: TDrawBuffer;
  Line: String;
  I, J, L: Integer;
  KeyCount: Integer;
  Normal, Keyword, SelKeyword, C: Byte;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Word;
begin
  Normal := GetColor(1);
  Keyword := GetColor(2);
  SelKeyword := GetColor(3);
  KeyCount := 0;
  KeyPoint.X := 0;
  KeyPoint.Y := 0;
  Topic^.SetWidth(Size.X);
  if Topic^.GetNumCrossRefs > 0 then
    repeat
      Inc(KeyCount);
      Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
    until (KeyCount >= Topic^.GetNumCrossRefs) or (KeyPoint.Y > Delta.Y);
  for I := 1 to Size.Y do
  begin
    MoveChar(B, ' ', Normal, Size.X);
    Line := Topic^.GetLine(I + Delta.Y);
    MoveStr(B, Copy(Line, Delta.X+1, Size.X), Normal);
    while I + Delta.Y = KeyPoint.Y do
    begin
      L := KeyLength;
      if KeyPoint.X < Delta.X then
      begin
        Dec(L, Delta.X - KeyPoint.X);
        KeyPoint.X := Delta.X;
      end;
      if KeyCount = Selected then C := SelKeyword
      else C := Keyword;
      for J := 0 to L-1 do
        WordRec(B[KeyPoint.X - Delta.X + J]).Hi := C;
      Inc(KeyCount);
      if KeyCount <= Topic^.GetNumCrossRefs then
        Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef)
      else KeyPoint.Y := 0;
    end;
    WriteLine(0, I-1, Size.X, 1, B);
  end;
end;

procedure THelpViewer.HandleEvent(var Event: TEvent);
var
  KeyPoint, Mouse: TPoint;
  KeyLength: Byte;
  KeyRef: Word;
  KeyCount: Integer;

{#C04B6_119B} procedure MakeSelectVisible;
var
  D: TPoint;
begin
  Topic^.GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
  D := Delta;
  if KeyPoint.X < D.X then D.X := KeyPoint.X;
  if KeyPoint.X > D.X + Size.X then D.X := KeyPoint.X - Size.X;
  if KeyPoint.Y < D.Y then D.Y := KeyPoint.Y;
  if KeyPoint.Y > D.Y + Size.Y then D.Y := KeyPoint.Y - Size.Y;
  if (D.X <> Delta.X) or (D.Y <> Delta.Y) then ScrollTo(D.X, D.Y);
end;

{#C04B6_12B9} procedure SwitchToTopic(KeyRef: Integer);
begin
  if Topic <> nil then Dispose(Topic, Done);
  Topic := HFile^.GetTopic(KeyRef);
  Topic^.SetWidth(Size.X);
  ScrollTo(0, 0);
  SetLimit(Limit.X, Topic^.NumLines);
  Selected := 1;
  DrawView;
end;

{#C04B6_1380}
begin
  TScroller.HandleEvent(Event);
  case Event.What of
    evKeyDown:
      begin
        case Event.KeyCode of
          kbTab:
            begin
              Inc(Selected);
              if Selected > Topic^.GetNumCrossRefs then Selected := 1;
              MakeSelectVisible;
            end;
          kbShiftTab:
            begin
              Dec(Selected);
              if Selected = 0 then Selected := Topic^.GetNumCrossRefs;
              MakeSelectVisible;
            end;
          kbEnter:
            begin
              if Selected <= Topic^.GetNumCrossRefs then
              begin
                Topic^.GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
                SwitchToTopic(KeyRef);
              end;
            end;
          kbEsc:
            begin
              Event.What := evCommand;
              Event.Command := cmClose;
              PutEvent(Event);
            end;
        else
          Exit;
        end;
        DrawView;
        ClearEvent(Event);
      end;
    evMouseDown:
      begin
        MakeLocal(Event.Where, Mouse);
        Inc(Mouse.X, Delta.X);
        Inc(Mouse.Y, Delta.Y);
        KeyCount := 0;
        repeat
          Inc(KeyCount);
          if KeyCount > Topic^.GetNumCrossRefs then Exit;
          Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
        until (KeyPoint.Y = Mouse.Y+1) and (Mouse.X >= KeyPoint.X) and
          (Mouse.X < KeyPoint.X + KeyLength);
        Selected := KeyCount;
        DrawView;
        if Event.Double then SwitchToTopic(KeyRef);
        ClearEvent(Event);
      end;
    evCommand:
      if (Event.Command = cmClose) and (Owner^.State and sfModal <> 0) then
      begin
        EndModal(cmClose);
        ClearEvent(Event);
      end;
  end;
end;

{ THelpWindow }

{#C04B6_15D1}
constructor THelpWindow.Init(HFile: PHelpFile; Context: Word);
var
  R: TRect;
begin
  R.Assign(0, 0, 50, 18);
  TWindow.Init(R, 'Help', wnNoNumber);
  Options := Options or ofCentered;
  R.Grow(-2,-1);
  Insert(New(PHelpViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard), HFile, Context)));
end;

{#C04B6_1693}
procedure RegisterHelpFile;
begin
  RegisterType(RHelpTopic);
  RegisterType(RHelpIndex);
end;

{#C04B6_16AC}
procedure NotAssigned(var S: TStream; Value: Integer);
begin
end;

end.
