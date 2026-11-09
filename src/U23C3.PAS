{$A-,B-,D+,F+,G-,I-,L+,N+,E+,O-,R-,S-,V+,X+}
unit U23C3;

{ Computer players.  Each AI type is an object; instances live in
  Tanks[] (U27D1) and are created by CreateAIPlayer according to the
  player's name ('Mr. Stupid', 'Lobber', ...).  Think is called once per
  frame and returns the next "key" to press:
    1/2 = turn turret, 3/4 = power down/up, 5 = fire, 6 = flip direction,
    8 = select weapon. }

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4, U27D1, U27B1, U26D4, U26A9;

type
  TByteSet = set of Byte;

  PComputer = ^TComputer;
  TComputer = object
    Kind: Integer;              { +00  1..7, saved first }
    Ready: Boolean;             { +02  shot planned }
    Power: Integer;             { +03  wanted power }
    Angle: Integer;             { +05  wanted turret angle }
    Dir: Integer;               { +07  wanted direction (-1/1) }
    Weapon: Integer;            { +09  wanted weapon }
    f0B: Byte;                  { +0B }
    Target: Integer;            { +0C  player aimed at, -1 = none }
    f0E: Integer;               { +0E }
    Player: Integer;            { +10  own player index }
    constructor Init(Allowed: TByteSet);
    function Think: Integer; virtual;
    destructor Done; virtual;
    procedure Save(var F: File);
    procedure Load(var F: File);
    function BuyStrategy: Integer;
    function GetTarget: Integer;
    procedure SetPlayer(APlayer: Integer);
    function Steer: Integer;
  end;

  PStupid = ^TStupid;
  TStupid = object(TComputer)   { 'Mr. Stupid' }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PLobber = ^TLobber;
  TLobber = object(TComputer)   { 'Lobber' }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PRifleman = ^TRifleman;
  TRifleman = object(TComputer) { 'Rifleman' }
    Score: array[0..10] of Integer;   { +14  how good a target each player is }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PLobShoot = ^TLobShoot;
  TLobShoot = object(TComputer) { 'Lob & Shoot' }
    Score: array[0..10] of Integer;   { +14 }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PWindless = ^TWindless;
  TWindless = object(TComputer) { 'Windless Wit' }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PWindMaster = ^TWindMaster;
  TWindMaster = object(TComputer) { 'Wind Master' }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

  PTwanger = ^TTwanger;
  TTwanger = object(TComputer)  { 'Twanger' }
    Score: array[0..10] of Integer;   { +14 }
    Rank: array[0..10] of Integer;    { +2A }
    constructor Init(APlayer: Integer);
    function Think: Integer; virtual;
  end;

procedure FreeComputers;

implementation

type
  TScreen = array[0..63999] of Byte;
  { one logged shot (filled in by U1615) }
  TShot = record
    Angle, Power, Dir: Integer;   { +0 +2 +4 }
    HitX, HitY: Integer;          { +6 +8  impact point }
  end;

var
  Screen: TScreen absolute $A000:0;
  ShotLog: array[0..10] of array[0..200] of TShot absolute ShotLogData;

{#U23C3_0000}
constructor TComputer.Init(Allowed: TByteSet);
begin
  Ready := False;
  Power := 0;
  Weapon := 0;
  Angle := 0;
  Dir := 0;
  f0B := 0;
  Target := -1;
  AIUnknown4688 := -1;
  AIUnknown468E := -1;
  repeat
    f0E := Random(4) + 1;
  until f0E in Allowed;
end;

{ never instantiated; the smart linker drops it together with the VMT }
function TComputer.Think: Integer;
begin
end;

{#U23C3_00B7}
destructor TComputer.Done;
begin
end;

{#U23C3_00C6}
procedure TComputer.Save(var F: File);
begin
  BlockWrite(F, Kind, 2);
  BlockWrite(F, f0B, 1);
  BlockWrite(F, f0E, 2);
  BlockWrite(F, Player, 2);
end;

{ Kind has already been read by the caller }
{#U23C3_0135}
procedure TComputer.Load(var F: File);
begin
  BlockRead(F, f0B, 1);
  BlockRead(F, f0E, 2);
  BlockRead(F, Player, 2);
end;

{#U23C3_018D}
function TComputer.BuyStrategy: Integer;
begin
  BuyStrategy := f0E;
end;

{#U23C3_01A6}
function TComputer.GetTarget: Integer;
begin
  GetTarget := Target;
end;

{#U23C3_01BF}
procedure TComputer.SetPlayer(APlayer: Integer);
begin
  Player := APlayer;
end;

{ compare the planned shot with the tank's current state and return the
  key that brings it closer (5 = fire when everything matches) }
{#U23C3_01D4}
function TComputer.Steer: Integer;
var
  Key: Integer;
begin
  while Players[Player].Ammo[Weapon] < 1 do
  begin
    Dec(Weapon);
    if Weapon < 0 then
      Weapon := 12;
  end;
  if 10 * Players[Player].Men < Power then
    Power := 10 * Players[Player].Men;
  if (Weapon = 5) and (Players[Player].Ammo[5] < Power) then
    Power := Players[Player].Ammo[5];
  if Power < 0 then
    Power := 0;
  Key := 5;
  if Players[Player].f1D < Angle then
    Key := 1 - Trunc((Players[Player].f1F - 1) / 2);
  if Players[Player].f1D > Angle then
    Key := Trunc((Players[Player].f1F - 1) / 2) + 2;
  if Players[Player].f1B > Power then
    Key := 3;
  if Players[Player].f1B < Power then
    Key := 4;
  if Players[Player].f1F <> Dir then
    Key := 6;
  if Players[Player].Weapon <> Weapon then
    Key := 8;
  if (Key = 3) and (Players[Player].f1B - Power > 99) then
    Players[Player].f1B := Players[Player].f1B - 90;
  if (Key = 3) and (Players[Player].f1B - Power > 9) then
    Players[Player].f1B := Players[Player].f1B - 9;
  if (Key = 4) and (Power - Players[Player].f1B > 99) then
    Players[Player].f1B := Players[Player].f1B + 90;
  if (Key = 4) and (Power - Players[Player].f1B > 9) then
    Players[Player].f1B := Players[Player].f1B + 9;
  if Key = 5 then
    Ready := False;
  Steer := Key;
end;

{ ---- Mr. Stupid ---- }

{#U23C3_050C}
constructor TStupid.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 4]);
  SetPlayer(APlayer);
  Kind := 1;
end;

{#U23C3_0567}
function TStupid.Think: Integer;
var
  a, b: Integer;
  i: Integer;
  pad: array[0..17] of Byte;
begin
  if not Ready then
  begin
    Weapon := 11;
    for i := 1 to 4 do
      if Players[Player].Ammo[i] > 0 then
        Weapon := i;
    Angle := Random(90);
    if RoundWall in [1, 2, 3] then
    begin
      repeat
        Dir := Trunc(Random(3)) - 1;
      until Abs(Dir) = 1;
      Power := Random(5000) + 20;
    end
    else
    begin
      if NumPlayers div 2 >= Player then
        Dir := 1
      else
        Dir := -1;
      Power := Random(300) + 20;
    end;
    Ready := True;
  end;
  Think := Steer;
end;

{#U23C3_069C}
constructor TLobber.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 4]);
  SetPlayer(APlayer);
  Kind := 2;
end;

{#U23C3_06DB}
function TLobber.Think: Integer;
var
  i, j: Integer;
  dX: Integer;
  L: LongInt;
  Dist: LongInt;
  Z: LongInt;
  R: Real;
begin
  if not Ready then
  begin
    Target := Player;
    Weapon := 1;
    L := $7FFF;
    if Abs(Dir) <> 1 then
      Dir := 1;
    j := Dir;
    if (Players[Player].f5E = 1) and (Random <= 0.5) then
      j := -j;
    if Players[Player].f5E < 3 then
    begin
      repeat
        Target := Target + j;
        if Target > NumPlayers then
          Target := 1;
        if Target < 1 then
          Target := NumPlayers;
      until (Players[Target].f23 <> 0) and (Player <> Target) and
            (Players[Player].Team <> Players[Target].Team);
    end
    else
      for i := 1 to NumPlayers do
        if (Abs(ShotLog[Player][Players[Player].f5E - 1].HitX - Players[i].X) < L) and
           (i <> Player) and (Players[i].f23 <> 0) and
           (Players[Player].Team <> Players[i].Team) then
        begin
          Target := i;
          L := Abs(ShotLog[Player][Players[Player].f5E - 1].HitX - Players[i].X);
        end;
  end;
  if Target > NumPlayers then
    Target := 1;
  if ((Target > Player) and (Dir = -1)) or ((Target < Player) and (Dir = 1)) then
    Players[Player].f5E := 1;
  if Target > Player then
    Dir := 1
  else
    Dir := -1;
  if (Players[Player].f5E = 1) and not Ready then
  begin
    Angle := 75;
    Power := Random(100) + 100;
    Ready := True;
  end;
  if (Players[Player].f5E = 2) and not Ready then
  begin
    Angle := 75;
    Power := Random(200) + 200;
    Ready := True;
  end;
  if (Players[Player].f5E > 2) and not Ready then
  begin
    TScreen(SaveBuf^) := Screen;
    Z := 0;
    SetColor(Player + 19);
    Circle(Players[Target].X, Players[Target].Y - 2, 7);
    for i := 1 to Players[Player].f5E - 2 do
      for j := i + 1 to Players[Player].f5E - 1 do
      begin
        Line(ShotLog[Player][i].HitX - 5, ShotLog[Player][i].HitY - 5,
             ShotLog[Player][i].HitX + 5, ShotLog[Player][i].HitY + 5);
        Line(ShotLog[Player][i].HitX - 5, ShotLog[Player][i].HitY + 5,
             ShotLog[Player][i].HitX + 5, ShotLog[Player][i].HitY - 5);
        dX := ShotLog[Player][j].HitX - ShotLog[Player][i].HitX;
        if dX = 0 then
          dX := 1;
        L := ShotLog[Player][j].Power - ShotLog[Player][i].Power;
        if L = 0 then
          L := 1;
        R := L / dX;
        Dist := Players[Target].X - ShotLog[Player][i].HitX;
        L := Trunc(R * Dist) mod $7FFF;
        Ready := True;
      end;
    Power := ShotLog[Player][i].Power + L;
    if Power < 0 then
      Power := -Power * 2;
    if Players[Player].f5E > 2 then
    begin
      if Abs(Dist) > 5 then
        Weapon := 2;
      if Abs(Dist) > 15 then
        Weapon := 3;
      if Abs(Dist) > 30 then
        Weapon := 4;
    end;
    while Players[Player].Ammo[Weapon] < 1 do
      case Weapon of
        11: Weapon := 0;
        1: Weapon := 11;
        2: Weapon := 1;
        3: Weapon := 2;
        4: Weapon := 3;
      end;
    Screen := TScreen(SaveBuf^);
  end;
  Think := Steer;
end;

{#U23C3_0E72}
constructor TRifleman.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 3, 4]);
  SetPlayer(APlayer);
  Kind := 3;
end;

{ shoots straight at the best visible target }
{#U23C3_0ECD}
function TRifleman.Think: Integer;
var
  i, u6, k: Integer;
  dX, dY: Integer;
  C: Integer;
  Range: Integer;
  u12, u14, u16, u18: Integer;
  px, py: Integer;
  u1E: Integer;
  R: Real;
begin
  if not Ready then
  begin
    TScreen(SaveBuf^) := Screen;
    SetColor(Player + 19);
    Weapon := 1;
    for i := 1 to NumPlayers do
    begin
      Score[i] := 1000;
      if Players[i].Y > Players[Player].Y + 3 then
        Score[i] := Score[i] div 10;
      if (Players[i].f23 = 0) or (i = Player) or
         (Players[i].Team = Players[Player].Team) then
        Score[i] := 0;
      if Score[i] > 0 then
      begin
        dX := Players[i].X - Players[Player].X;
        dY := Players[i].Y - Players[Player].Y;
        R := VecLength(dX, dY);
        { walk along the line of sight; every pixel of colour 2 (dirt) on
          the way makes the target less attractive }
        for k := 1 to Trunc(R) do
        begin
          px := Players[Player].X + Trunc(dX / R * k);
          py := Players[Player].Y + Trunc(dY / R * k);
          C := PixelAt(px, py);
          if C = 2 then
            Dec(Score[i]);
          PlotPixel(px, py, i + 19);
        end;
      end;
    end;
    C := -32767;
    Target := 0;
    for i := 1 to NumPlayers do
      if Score[i] > C then
      begin
        C := Score[i];
        Target := i;
      end;
    dX := Players[Target].X - Players[Player].X;
    dY := Players[Player].Y - Players[Target].Y + 4;
    if dX = 0 then
      Inc(dX);
    if dY = 0 then
      Inc(dY);
    if Score[Target] > 990 then
      for k := 2 to 4 do
      begin
        case k of
          2: Range := 15;
          3: Range := 30;
          4: Range := 60;
        end;
        if (Players[Player].Ammo[k] > 0) and (VecLength(dX, dY) > Range) then
          Weapon := k;
      end;
    if (Score[Target] <= 990) and (Players[Player].Ammo[5] > 100) then
      Weapon := 5;
    Power := 1000;
    Angle := Trunc(RadToDeg(ArcTan(dY / dX)));
    if Target < Player then
      Dir := -1
    else
      Dir := 1;
    if Angle < 0 then
      Angle := Abs(Angle);
    if Players[Target].Y - 4 > Players[Player].Y then
    begin
      Angle := Random(70) + 10;
      if not (RoundWall in [1, 2, 3]) then
      begin
        Power := Random(280) + 20;
        Angle := 45;
      end;
      Weapon := 1;
    end;
    Screen := TScreen(SaveBuf^);
    Ready := True;
  end;
  Think := Steer;
end;

{#U23C3_140A}
constructor TLobShoot.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 4]);
  SetPlayer(APlayer);
  Kind := 4;
end;

{ plays like a Rifleman when there is no wind (or only constant wind),
  otherwise like a Lobber, by running a temporary instance of that type }
{#U23C3_1465}
function TLobShoot.Think: Integer;
var
  Unused: array[0..23] of Byte;
  P: PComputer;
begin
  if not Ready then
    if RoundWall in [1, 2, 3] then
    begin
      P := New(PRifleman, Init(Player));
      P^ := PComputer(Tanks[Player])^;
      P^.Think;
      PComputer(Tanks[Player])^ := P^;
      Dispose(P, Done);
    end
    else
    begin
      P := New(PLobber, Init(Player));
      P^ := PComputer(Tanks[Player])^;
      P^.Think;
      PComputer(Tanks[Player])^ := P^;
      Dispose(P, Done);
    end;
  Think := Steer;
end;

{#U23C3_15A3}
constructor TWindless.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 4]);
  SetPlayer(APlayer);
  Kind := 5;
end;

{ picks a random enemy and computes a ballistic shot ignoring wind }
{#U23C3_15F0}
function TWindless.Think: Integer;
var
  dX, dY: Integer;
  u8: Integer;
  i, j: Integer;
  Tries: Integer;
  Unused: array[0..11] of Byte;
  V: Real;
  H: Real;
  Ok: Boolean;
  u28: Byte;
begin
  if not Ready then
  begin
    FetchClipWindow;
    Tries := 0;
    Ok := True;
    TScreen(SaveBuf^) := Screen;
    repeat
      Target := Random(NumPlayers) + 1;
    until (Players[Target].f23 <> 0) and (Target <> Player) and
          (Players[Target].Team <> Players[Player].Team);
    { flash a cross-hair ellipse around the target }
    SetColor(Player + 19);
    for i := 1 to 2 do
      for j := -15 to 15 do
      begin
        DrawEllipseNoClip(Players[Target].X, Players[Target].Y, 15, Abs(j), Player + 19);
        DrawEllipseNoClip(Players[Target].X, Players[Target].Y, Abs(j), 15, Player + 19);
        CopyEllipse(Players[Target].X, Players[Target].Y, 15, Abs(j), SaveBuf);
        CopyEllipse(Players[Target].X, Players[Target].Y, Abs(j), 15, SaveBuf);
      end;
    Screen := TScreen(SaveBuf^);
    repeat
      Ok := True;
      Inc(Tries);
      dX := Players[Target].X - Players[Player].X;
      dY := Players[Target].Y - Players[Player].Y;
      if dX > 0 then
        Dir := 1
      else
        Dir := -1;
      Angle := Random(90);
      { offset of the muzzle (barrel length 8) }
      dX := Trunc(dX - Dir * (CosDeg(Angle) * 8));
      dY := Trunc(dY + SinDeg(Angle) * 8) - 1;
      V := dX * 0.05 * dX / (dY + TanDeg(Angle) * Abs(dX));
      V := Sqrt(Abs(V));
      H := TanDeg(Angle) * V;
      Power := Trunc(VecLength(H * 50, V * 50));
      if (TanDeg(Angle) < Abs(dY / dX)) and (dY < 0) then
        Ok := False;
      if 10 * Players[Player].Men < Power then
        Ok := False;
    until Ok or (Tries > 40);
    Weapon := 11;
    for j := 1 to 4 do
      if Players[Player].Ammo[j] > 0 then
        Weapon := j;
    Ready := True;
  end;
  Think := Steer;
end;

{#U23C3_1A6B}
constructor TWindMaster.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 4]);
  SetPlayer(APlayer);
  Kind := 7;
end;

{ random enemy; solves the ballistic equations including the wind }
{#U23C3_1AC2}
function TWindMaster.Think: Integer;
var
  dX, dY: Integer;
  u8: Integer;
  i, j: Integer;
  Tries: Integer;
  G: Real;          { gravity }
  W: Real;          { wind acceleration }
  X, Y: Real;
  S, C: Real;       { sin / cos of the angle }
  T: Real;
  V: Real;
  Ok: Boolean;
  u40: Byte;
begin
  if not Ready then
  begin
    FetchClipWindow;
    Tries := 0;
    Ok := True;
    TScreen(SaveBuf^) := Screen;
    repeat
      Target := Random(NumPlayers) + 1;
    until (Players[Target].f23 <> 0) and (Target <> Player) and
          (Players[Target].Team <> Players[Player].Team);
    SetColor(Player + 19);
    for i := 1 to 10 do
      for j := -15 to 15 do
      begin
        DrawEllipseNoClip(Players[Target].X, Players[Target].Y, 15, Abs(j), Player + 19);
        DrawEllipseNoClip(Players[Target].X, Players[Target].Y, Abs(j), 15, Player + 19);
        CopyEllipse(Players[Target].X, Players[Target].Y, 15, Abs(j), SaveBuf);
        CopyEllipse(Players[Target].X, Players[Target].Y, Abs(j), 15, SaveBuf);
      end;
    dX := Players[Target].X;
    dY := Players[Target].Y;
    repeat
      V := 1000;
      Ok := True;
      Inc(Tries);
      dX := Players[Target].X - Players[Player].X;
      dY := Players[Target].Y - Players[Player].Y;
      Angle := Random(180);
      dX := Trunc(dX - CosDeg(Angle) * 8);
      dY := Trunc(dY + SinDeg(Angle) * 8) - 1;
      G := -0.05;
      X := dX;
      Y := -dY;
      S := SinDeg(Angle);
      C := CosDeg(Angle);
      W := WindForce * 0.5 / 5000;
      if S = 0 then
        Ok := False;
      if C = 0 then
        Ok := False;
      if W * S - G * C = 0 then
        Ok := False;
      if Ok then
      begin
        T := (X * S - Y * C) / (W * S - G * C);
        if T <= 0 then
          Ok := False;
        if Ok then
          V := (X - W * T) / (Sqrt(T) * C);
      end;
      V := V * 50;
      if V > 32767 then
        V := 32767;
      if V < -32767 then
        V := -32767;
      Power := Trunc(V);
      Dir := 1;
      if Angle > 90 then
      begin
        Angle := 180 - Angle;
        Dir := -1;
      end;
      if Power < 0 then
        Ok := False;
      if 10 * Players[Player].Men < Power then
        Ok := False;
    until Ok or (Tries > 40);
    Weapon := 11;
    for j := 1 to 4 do
      if Players[Player].Ammo[j] > 0 then
        Weapon := j;
    Ready := True;
  end;
  Think := Steer;
end;

{#U23C3_2126}
constructor TTwanger.Init(APlayer: Integer);
begin
  TComputer.Init([1, 2, 3, 4]);
  SetPlayer(APlayer);
  Kind := 6;
end;

{ like a Rifleman, but bounces its shot off the ceiling: aims at the
  mirror image of the target 28 pixels below the top and checks the two
  legs of the path for dirt }
{#U23C3_2181}
function TTwanger.Think: Integer;
var
  i, k, w: Integer;
  dX, dY: Integer;
  mx, my: Integer;
  H: Integer;
  Best: Integer;
  Range: Integer;
  Level: Integer;
  uR: Real;
  A: Real;
  px, py: Integer;
  Col: Integer;
  R: Real;
  P: PComputer;
begin
  if not Ready then
    if RoundWall in [1, 2, 3] then
    begin
      TScreen(SaveBuf^) := Screen;
      SetColor(Player + 19);
      Weapon := 1;
      for i := 1 to NumPlayers do
      begin
        Score[i] := 1000;
        if Player = i then
          Score[i] := -1;
        if Players[i].f23 = 0 then
          Score[i] := -1;
        if Players[i].Team = Players[Player].Team then
          Score[i] := -1;
        if Score[i] <> -1 then
        begin
          dX := Players[i].X - Players[Player].X;
          dY := Players[Player].Y - Players[i].Y;
          H := Players[i].Y - 28;
          A := ArcTan(Abs((dY + H + H) / dX));
          if dX < 0 then
            Dir := -1
          else
            Dir := 1;
          TmpY := Players[Player].Y - 28;
          TmpX := Trunc(Dir * TmpY / (Sin(A) / Cos(A)));
          R := VecLength(TmpX, TmpY);
          Col := i + 19;
          for k := 1 to Trunc(R) do
          begin
            px := Trunc(Players[Player].X + TmpX / R * k);
            py := Trunc(Players[Player].Y - TmpY / R * k);
            if PixelAt(px, py) = 2 then
              Score[i] := Score[i] - 3;
            PlotPixel(px, py, Col);
          end;
          mx := Players[Player].X + TmpX;
          my := Players[Player].Y - TmpY;
          TmpY := Players[i].Y - my;
          TmpX := Players[i].X - mx;
          R := VecLength(TmpX, TmpY);
          for k := 1 to Trunc(R) do
          begin
            px := Trunc(mx + TmpX / R * k);
            py := Trunc(my + TmpY / R * k);
            if PixelAt(px, py) = 2 then
              Dec(Score[i]);
            PlotPixel(px, py, Col);
          end;
        end;
      end;
      { rank the scores; keep only the best rank }
      Best := 0;
      Level := 1;
      Target := 0;
      FillChar(Rank, SizeOf(Rank), 0);
      for i := 1 to NumPlayers do
        if Score[i] > Best then
        begin
          Inc(Level);
          Best := Score[i];
          Rank[i] := Level;
        end
        else if Score[i] = Best then
          Rank[i] := Level;
      Best := 0;
      for i := 1 to NumPlayers do
        if Rank[i] >= Best then
          Best := Rank[i];
      for i := 1 to NumPlayers do
        if Rank[i] < Best then
          Rank[i] := 0;
      Target := 0;
      FillChar(Score, SizeOf(Score), 0);
      for i := 1 to NumPlayers do
        if Rank[i] <> 0 then
          Score[i] := 1000 - Trunc(VecLength(Players[Player].X - Players[i].X,
                                              Players[Player].Y - Players[i].Y));
      Best := 0;
      for i := 1 to NumPlayers do
        if Score[i] > Best then
        begin
          Best := Score[i];
          Target := i;
        end;
      { trace the path to the chosen target once more }
      i := Target;
      Screen := TScreen(SaveBuf^);
      Score[i] := 1000;
      dX := Players[i].X - Players[Player].X;
      dY := Players[Player].Y - Players[i].Y;
      H := Players[i].Y - 28;
      A := ArcTan(Abs((dY + H + H) / dX));
      if i < Player then
        Dir := -1
      else
        Dir := 1;
      TmpY := Players[Player].Y - 28;
      TmpX := Trunc(Dir * TmpY / (Sin(A) / Cos(A)));
      R := VecLength(TmpX, TmpY);
      Col := i + 19;
      for k := 1 to Trunc(R) do
      begin
        px := Trunc(Players[Player].X + TmpX / R * k);
        py := Trunc(Players[Player].Y - TmpY / R * k);
        if PixelAt(px, py) = 2 then
          Score[i] := Score[i] - 3;
        PlotPixel(px, py, Col);
      end;
      mx := Players[Player].X + TmpX;
      my := Players[Player].Y - TmpY;
      TmpY := Players[i].Y - my;
      TmpX := Players[i].X - mx;
      R := VecLength(TmpX, TmpY);
      for k := 1 to Trunc(R) do
      begin
        px := Trunc(mx + TmpX / R * k);
        py := Trunc(my + TmpY / R * k);
        if PixelAt(px, py) = 2 then
          Dec(Score[i]);
        PlotPixel(px, py, Col);
      end;
      dX := Players[Target].X - Players[Player].X;
      dY := Players[Player].Y - Players[Target].Y;
      H := Players[Target].Y - 28;
      Power := Random(51) + 950;
      Angle := Trunc(RadToDeg(ArcTan(Abs((dY + H + H) / dX))));
      if dX < 0 then
        Dir := -1
      else
        Dir := 1;
      if Angle < 0 then
        Angle := Abs(Angle);
      Screen := TScreen(SaveBuf^);
      Weapon := 1;
      if Score[Target] > 990 then
        for w := 2 to 4 do
        begin
          case w of
            2: Range := 15;
            3: Range := 30;
            4: Range := 60;
          end;
          if (Players[Player].Ammo[w] > 0) and (VecLength(dX, dY) > Range) then
            Weapon := w;
        end;
      if (Score[Target] <= 990) and (Players[Player].Ammo[5] > 100) then
        Weapon := 5;
      Ready := True;
    end
    else
    begin
      P := New(PRifleman, Init(Player));
      P^ := PComputer(Tanks[Player])^;
      P^.Think;
      PComputer(Tanks[Player])^ := P^;
      Dispose(P, Done);
    end;
  Think := Steer;
end;

{ free all computer players }
{#U23C3_2E0B}
procedure FreeComputers;
begin
  for LoopI := 1 to 10 do
  begin
    if Tanks[LoopI] <> nil then
      Dispose(PComputer(Tanks[LoopI]), Done);
    Tanks[LoopI] := nil;
  end;
end;

end.
