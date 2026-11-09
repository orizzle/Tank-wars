{$A-,B-,D+,F+,G-,I-,L+,N-,E+,O-,R-,S-,V+,X+}
unit U27D1;

interface




uses
  Graph, Crt, Dos, Printer, U2968, U2918,
  U2823, U27D4;

type
  { player / tank record, Players: array[0..10] (index 10 = ?) }
  TPlayer = record
    f00: Byte;                       { +00 }
    Name: string[13];                { +01 }
    X, Y: Integer;                   { +0F, +11 }
    Score: LongInt;                  { +13 }
    Spent: LongInt;                  { +17  cash = Score - Spent }
    f1B, f1D, f1F: Integer;          { +1B }
    Men: Integer;                    { +21 }
    f23: Byte;                       { +23 }
    Weapon: Integer;                 { +24  selected weapon }
    f26, f28: Integer;               { +26 }
    Accessory: array[0..1] of Integer; { +2A  guidance systems }
    Ammo: array[0..17] of Integer;   { +2E }
    Guidance: array[0..2] of LongInt; { +52  shields (name kept, others use it) }
    f5E, f60, f62, f64: Integer;     { +5E }
    Team: Word;                      { +66  (Word: ShowTeamStats compares it zero-extended) }
    f68: Integer;                    { +68 }
    Wins: Integer;                   { +6A }
    f6C, f6E, f70, f72: Integer;     { +6C }
  end;

  { team record, Teams: array[0..10] }
  TTeam = record
    Name: string[13];                { +00 }
    f0E: Byte;                       { +0E }
    f0F: Integer;                    { +0F  number of members }
    f11, f17, f1D, f23, f29, f2F: Real; { +11 score, deaths, wins, hits, kills, shots }
  end;

  { shop screen button (U0E9B), ShopButtons: array[1..30] }
  TShopButton = record
    Item: LongInt;                   { +00 index within its class }
    Kind: LongInt;                   { +04 0 = weapon, 1 = guidance, 2 = shield }
    X1, Y1, X2, Y2: LongInt;         { +08 }
    TextX: LongInt;                  { +18 }
    Count: LongInt;                  { +1C units selected but not yet paid }
  end;

  { a 320x200x256 VGA screen }
  TScreen = array[0..63999] of Byte;
  PScreen = ^TScreen;

  { one VGA DAC entry }
  TRGB = record
    R, G, B: Byte;
  end;

  TPoint = record
    X, Y: Integer;
  end;

  { explosion debris paths (U1B27/U1DD4): Paths }
  TPaths = array[1..10, 1..400] of TPoint;

const
  { DS 0056-383F }
  GameVersion: string[4] = '3.0'#0;  { DS:0056 }
  Unused005B: array[0..8] of Byte = (  { DS:005B }
    $00,$0B,$00,$1F,$00,$35,$01,$BD,$00);
  DirChars: array[-1..1] of Char = (#27, #24, #26);  { DS:0064  tank direction arrows }
  Unused0067: array[0..13] of Byte = (  { DS:0067 }
    $00,$0A,$32,$0A,$32,$0A,$32,$0A,$32,$0A,$32,$07,$07,$0B);
  Unused0075: array[0..6] of Byte = (  { DS:0075 }
    $0B,$0F,$0F,$13,$13,$17,$17);
  { AINames: array[0..7] of String overlays 007C..087B (see U0728) }
  AIName0: array[0..195] of Byte = (  { DS:007C }
    $06,$52,$61,$6E,$64,$6F,$6D,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName0Part2: array[0..59] of Byte = (  { DS:0140 }
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName1: array[0..255] of Byte = (  { DS:017C }
    $0A,$4D,$72,$2E,$20,$53,$74,$75,$70,$69,$64,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName2: array[0..147] of Byte = (  { DS:027C }
    $06,$4C,$6F,$62,$62,$65,$72,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00);
  AIName2Part2: array[0..15] of Byte = (  { DS:0310 }
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName2Part3: array[0..58] of Byte = (  { DS:0320 }
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName2Part4: array[0..1] of Byte = (  { DS:035B }
    $00,$00);
  AIName2Part5: array[0..1] of Byte = (  { DS:035D }
    $00,$00);
  AIName2Part6: array[0..1] of Byte = (  { DS:035F }
    $00,$00);
  AIName2Part7: array[0..1] of Byte = (  { DS:0361 }
    $00,$00);
  AIName2Part8: array[0..24] of Byte = (  { DS:0363 }
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName3: array[0..255] of Byte = (  { DS:037C }
    $08,$52,$69,$66,$6C,$65,$6D,$61,$6E,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName4: array[0..255] of Byte = (  { DS:047C }
    $0B,$4C,$6F,$62,$20,$26,$20,$53,$68,$6F,$6F,$74,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName5: array[0..255] of Byte = (  { DS:057C }
    $0C,$57,$69,$6E,$64,$6C,$65,$73,$73,$20,$57,$69,$74,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName6: array[0..255] of Byte = (  { DS:067C }
    $07,$54,$77,$61,$6E,$67,$65,$72,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
  AIName7: string = 'Wind Master';  { DS:077C }
  WeaponNames: array[0..17] of string = (  { DS:087C }
    'Lead Ball',
    'Incinerator',
    'Mark II Incinerator',
    '20 Kiloton Nuke',
    '5 Megaton Nuke',
    'Laser Blaster',
    'Chain Reaction Inducer 4/D',
    'MIRV (5 Mark IIs inside)',
    'Chain Reaction Inducer 8/D',
    'Chain Reaction Inducer 20/ND',
    'Chain Reaction Inducer 20/D',
    'Hand Grenade',
    'Sonic Blaster',
    'Ball o Dirt',
    'Ball o Dirt Mark II',
    'Ball o Compresed Dirt',
    'Ball o Super-Compressed Dirt',
    'Explosive Dirt');
  { shop: weapons (short names, prices, bundle sizes) }
  WeaponShortNames: array[0..17] of string = (  { DS:1A7C }
    'Lead Ball',
    'Incinerator',
    'Mark II Incin.',
    '20 Kilo Nuke',
    '5 Meg Nuke',
    'Laser',
    'CRI 4/D',
    'MIRV',
    'CRI 8/D',
    'CRI 20/ND',
    'CRI 20/D',
    'Hand Grenade',
    'Sonic Blaster',
    'Ball ''O'' Dirt',
    'Mark II Dirt',
    'Pressured Dirt',
    'High Pres. Dirt',
    'Xplosive Dirt');
  { -1 = not for sale }
  WeaponPrices: array[0..17] of LongInt = (  { DS:2C7C }
    -1, 3000, 4000, 7000, 10000, 10000, 5000, 8500, 10000, 10000, 15000, -1, 4500, 4000, 6000, 8000, 10000, 4500);
  { units per purchase }
  WeaponBundles: array[0..17] of Integer = (  { DS:2CC4 }
    0, 100, 10, 2, 1, 1000, 5, 3, 3, 3, 1, 0, 10, 10, 7, 3, 1, 10);
  { shop: guidance systems (Player.Accessory[]) }
  GuideNames: array[0..1] of string = (  { DS:2CE8 }
    'Herb''s Guidance System',
    'Vick''s Guidance System');
  { short names }
  GuideShortNames: array[0..1] of string = (  { DS:2EE8 }
    'Herb''s Guide',
    'Vick''s Guide');
  { prices }
  GuidePrices: array[0..1] of LongInt = (  { DS:30E8 }
    20000, 20000);
  { units per purchase }
  GuideBundles: array[0..1] of Integer = (  { DS:30F0 }
    5, 5);
  { shop: shields (Player.Guidance[] LongInt) }
  ShieldNames: array[0..2] of string = (  { DS:30F4 }
    'Energy Absorbtion Shield',
    'Inertia Dampener',
    'Repulser');
  { short names }
  ShieldShortNames: array[0..2] of string = (  { DS:33F4 }
    'Energy Shield',
    'Inertia Damp.',
    'Repulser');
  { prices }
  ShieldPrices: array[0..2] of LongInt = (  { DS:36F4 }
    20000, 10000, 15000);
  { units per purchase }
  ShieldBundles: array[0..2] of Integer = (  { DS:3700 }
    1000, 100, 1);
  NoPalCycle: TPalCycle = (           { DS:3706  palette cycler off }
    First: 0; Field2: 0; Count: 0; Mode: 0; Pos: 0; Speed: 1; Pal: nil);
  ScanUp: Char = #$48;            { DS:3716  cursor key scan codes }
  ScanDown: Char = #$50;  { DS:3717 }
  ScanRight: Char = #$4D;  { DS:3718 }
  ScanLeft: Char = #$4B;  { DS:3719 }
  MoreScanCodes: array[0..21] of Byte = (  { DS:371A }
    $49,$51,$47,$4F,$10,$00,$0C,$0A,$0E,$31,$15,$23,$07,$0F,$24,
    $12,$36,$09,$2D,$1B,$3F,$00);
  MouseCursors: array[0..3] of TMouseCursor = (  { DS:3730 }
    (Mask: ($3FFF,$1FFF,$0FFF,$07FF,$03FF,$01FF,$00FF,$007F,
             $003F,$001F,$01FF,$10FF,$30FF,$F87F,$F87F,$FC7F,
             $0000,$4000,$6000,$7000,$7800,$7C00,$7E00,$7F00,
             $7F80,$7C00,$6C00,$4600,$0600,$0300,$0300,$0000);
     HotX: 0; HotY: 0),
    (Mask: ($0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
             $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
             $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
             $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000);
     HotX: 0; HotY: 0),
    (Mask: ($F99F,$F99F,$F99F,$F99F,$F99F,$0180,$0180,$FFFF,
             $FFFF,$0180,$0180,$F99F,$F99F,$F99F,$F99F,$F99F,
             $0240,$0240,$0240,$0240,$0240,$0240,$FE7F,$0000,
             $0000,$FE7F,$0240,$0240,$0240,$0240,$0240,$0240);
     HotX: 14; HotY: 7),
    (Mask: ($FFFF,$FFFF,$F93F,$F93F,$F93F,$C107,$C107,$FFFF,
             $C107,$C107,$F93F,$F93F,$F93F,$FFFF,$FFFF,$FFFF,
             $0000,$0000,$0280,$0280,$0280,$0280,$3EF8,$0000,
             $3EF8,$0280,$0280,$0280,$0280,$0000,$0000,$0000);
     HotX: 14; HotY: 7));

var
  { DS 3ACC-E79F }
  ShopButtons: array[1..30] of TShopButton;  { DS:3ACC }
  NumShopButtons: Byte;  { DS:3E8C }
  Unused3E8D: Byte;  { DS:3E8D }
  ShopCartCost: LongInt;  { DS:3E8E }
  OldCartCost: LongInt;  { DS:3E92 }
  ShopSpent: LongInt;  { DS:3E96 }
  OldShopSpent: LongInt;  { DS:3E9A }
  DebrisX: array[0..10] of Integer;  { DS:3E9E }
  DebrisY: array[0..10] of Integer;  { DS:3EB4 }
  DebrisSize: array[0..10] of Integer;  { DS:3ECA }
  ExplColor: Integer;  { DS:3EE0 }
  Tanks: array[0..10] of Pointer;  { DS:3EE2  tank objects (U23C3) }
  Players: array[0..10] of TPlayer;  { DS:3F0E }
  KeyDown: array[0..511] of Byte;  { DS:440A }
  KbdInstalled: Byte;  { DS:460A }
  Unused460B: Byte;  { DS:460B }
  OldInt9: Pointer;  { DS:460C }
  KbdChainBios: Byte;  { DS:4610 }
  Unused4611: Byte;  { DS:4611 }
  KbdExtOffset: Word;  { DS:4612 }
  KbdHook: Pointer;  { DS:4614 }
  Unused4618: array[0..3] of Byte;  { DS:4618 }
  LandHeight: Integer;  { DS:461C }
  LoopI: Integer;  { DS:461E }
  LoopJ: Integer;  { DS:4620 }
  LoopK: Integer;  { DS:4622 }
  TmpX: Integer;  { DS:4624 }
  TmpY: Integer;  { DS:4626 }
  TmpR: Integer;  { DS:4628 }
  TmpC: Integer;  { DS:462A }
  TmpN: Integer;  { DS:462C }
  DoneFlag2: Byte;  { DS:462E }
  DoneFlag: Byte;  { DS:462F }
  Unused4630: array[0..19] of Byte;  { DS:4630 }
  HotKeysOn: Byte;  { DS:4644 }
  Unused4645: Byte;  { DS:4645 }
  Unknown4646: Word;  { DS:4646 }
  StartMemAvail: LongInt;  { DS:4648 }
  Unknown464C: LongInt;  { DS:464C }
  Unknown4650: LongInt;  { DS:4650 }
  ShowHelp: Byte;  { DS:4654 }
  Unused4655: Byte;  { DS:4655 }
  CpuKind: Integer;  { DS:4656 }
  LaserPixel: LongInt;  { DS:4658 }
  Unused465C: array[0..3] of Byte;  { DS:465C }
  LaserY: LongInt;  { DS:4660 }
  Unused4664: array[0..11] of Byte;  { DS:4664 }
  ShotX: Real;  { DS:4670 }
  ShotY: Real;  { DS:4676 }
  ShotVX: Real;  { DS:467C }
  ShotVY: Real;  { DS:4682 }
  AIUnknown4688: Real;  { DS:4688 }
  AIUnknown468E: Real;  { DS:468E }
  Unused4694: array[0..5] of Byte;  { DS:4694 }
  TmpScale: Real;  { DS:469A }
  LaserScale: Real;  { DS:46A0 }
  Unused46A6: array[0..5] of Byte;  { DS:46A6 }
  WallBounce: Real;  { DS:46AC }
  BlastSize: Integer;  { DS:46B2 }
  NumPlayers: Integer;  { DS:46B4 }
  Unused46B6: array[0..1] of Byte;  { DS:46B6 }
  HitColor: Integer;  { DS:46B8 }
  RoundWinner: Integer;           { DS:46BA  winning team of the round (0 = none) }
  GameNo: Integer;           { DS:46BC  games played so far }
  RoundWind: Word;  { DS:46BE }
  GuideTarget: Word;  { DS:46C0 }
  SavedUnused46C2: Word;  { DS:46C2 }
  TurnLap: Integer;  { DS:46C4 }
  RoundWall: Word;  { DS:46C6 }
  CurPlayer: Byte;  { DS:46C8 }
  KeyChar: Char;  { DS:46C9 }
  TmpStr: string[30];  { DS:46CA }
  TankDied: Byte;  { DS:46E9 }
  Unused46EA: array[0..1] of Byte;  { DS:46EA }
  AllComputers: Byte;  { DS:46EC }
  RoundOver: Byte;  { DS:46ED }
  WallsBounce: Byte;  { DS:46EE }
  WallsWrap: Byte;  { DS:46EF }
  SaveRequested: Byte;  { DS:46F0 }
  LoadRequested: Byte;  { DS:46F1 }
  AutoSave: Byte;  { DS:46F2 }
  Unused46F3: array[0..4] of Byte;  { DS:46F3 }
  BombOldExitProc: Pointer;  { DS:46F8 }
  SaveName: string[20]; Unused4711: Byte;  { DS:46FC }
  Teams: array[0..10] of TTeam; Unused4959: Byte;  { DS:4712 }
  ShotLogData: Word;  { DS:495A }
  ShotLog495C: Word;  { DS:495C }
  ShotLog495E: Word;  { DS:495E }
  ShotLog4960: Word;  { DS:4960 }
  ShotLog4962: array[0..20513] of Byte;  { DS:4962 }
  ShotLog9984: Word;  { DS:9984 }
  ShotLog9986: array[0..1585] of Byte;  { DS:9986 }
  PalCycle: TPalCycle;    { DS:9FB8  palette cycler block (U27D4) }
  Paths: TPaths;  { DS:9FC8 }
  DiggerDirs: array[1..8] of Byte;  { DS:DE48 }
  UnusedDE50: array[0..43] of Byte;  { DS:DE50 }
  FallList: Pointer;  { DS:DE7C }
  CyclePal: array[1..60] of TRGB;  { DS:DE80  2 x 30 cycling colours (DAC 30..59) }
  UnusedDF34: array[0..1355] of Byte;  { DS:DF34 }
  Controls: array[0..10] of Integer;  { DS:E480 }
  SaveBuf: PScreen;           { DS:E496  copy of the screen behind pop-ups }
  BackBuf: Pointer;  { DS:E49A }
  BlastPal: array[0..200] of TRGB; UnusedE6F9: Byte;  { DS:E49E }
  DiggerPts: array[0..20] of TPoint;  { DS:E6FA }
  BarButtonX: array[0..20] of Integer;  { DS:E74E  left edges of the 21 status bar buttons (U20C6) }
  WindForce: Integer;  { DS:E778 }
  CrumblePct: Integer;  { DS:E77A }
  GamesToPlay: Integer;           { DS:E77C  number of games to play }
  WindControl: Integer;  { DS:E77E }
  WallControl: Integer;  { DS:E780 }
  BackControl: Integer;  { DS:E782 }
  BackMask: Integer;  { DS:E784 }
  PaletteOn: Byte;  { DS:E786 }
  FlySound: Byte;  { DS:E787 }
  SoundOn: Byte;  { DS:E788 }
  InvisoBall: Byte;  { DS:E789 }
  ShotTrail: Byte;  { DS:E78A }
  MouseIn: Byte;  { DS:E78B }
  CrudeVideo: Byte;  { DS:E78C }
  TanksFall: Byte;  { DS:E78D }
  ShowTitle: Byte;  { DS:E78E }
  CompuBuy: Byte;  { DS:E78F }
  ForceMouse: Byte;  { DS:E790 }
  TeamPlay: Byte;  { DS:E791 }
  DirectPorts: Byte;  { DS:E792 }
  PalUseRetrace: Byte;  { DS:E793 }
  BeginnerGame: Byte;  { DS:E794 }
  DebugMode: Byte;  { DS:E795 }
  PalSpeed: Integer;  { DS:E796 }
  TurretSpeed: Integer;  { DS:E798 }
  ExplodeSpeed: Integer;  { DS:E79A }
  FallSpeed: Integer;  { DS:E79C }
  ShotSpeed: Integer;  { DS:E79E }


implementation

{#U27D1_0000}
begin
  StartMemAvail := MemAvail;
  Unknown4646 := 0;
  Unknown464C := 0;
  Unknown4650 := 0;
end.
