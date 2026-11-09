"""Segment -> unit table for the ORIGINAL executable (paragraph values).

Target selection: environment variable TW_TARGET = BOMB (default) or BOMBCFG.
"""
import os
TARGET = os.environ.get('TW_TARGET', 'BOMB').upper()
MAIN = TARGET
_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(_ROOT, 'orig', TARGET + '.EXE')
# Order is memory order. Names for user units are ours (unit names are not
# stored in the EXE).  Library units are identified by content.
UNITS = [
    (0x0000, 'BOMB'),      # main program
    (0x0040, 'U0040'),
    (0x0098, 'U0098'),
    (0x0728, 'U0728'),
    (0x0E9B, 'U0E9B'),
    (0x1615, 'U1615'),
    (0x1B27, 'U1B27'),
    (0x1DD4, 'U1DD4'),
    (0x1F69, 'U1F69'),
    (0x20C6, 'U20C6'),
    (0x22B7, 'U22B7'),
    (0x2390, 'U2390'),
    (0x23C3, 'U23C3'),
    (0x26A9, 'U26A9'),
    (0x26D4, 'U26D4'),
    (0x27B1, 'U27B1'),
    (0x27D1, 'U27D1'),
    (0x27D4, 'U27D4'),
    (0x2823, 'U2823'),
    (0x2918, 'U2918'),
    (0x2968, 'U2968'),
    (0x2977, 'PRINTER'),
    (0x297B, 'DOS'),
    (0x298D, 'CRT'),
    (0x29EF, 'GRAPH'),
    (0x2DAF, 'SYSTEM'),
    (0x328D, 'DATA'),
    (0x4165, 'STACK'),
]
LIB = {'PRINTER', 'DOS', 'CRT', 'GRAPH', 'SYSTEM'}
DSEG = 0x328D
SRCDIRS = ['src']
# original procedure names to rename / drop when reading the original EXE (see BOMBCFG)
PROC_ALIAS = {}
PROC_DROP = set()
# markers that dev builds must NOT reference via KEEPALL ({unit: set(markers)} = keep only these)
KEEPALL_SKIP = {'U2918_00A5'}      # BOMBCFG-only function of U2918 (smart-linked out of BOMB.EXE)
KEEPALL_ONLY = {}
# --layout: names carrying another target's DS offset: [(lo, hi, delta)] -> expected = name + delta
LAYOUT_REMAP = []

if TARGET == 'BOMBCFG':
    UNITS = [
        (0x0000, 'BOMBCFG'),   # main program (Turbo Vision application)
        (0x0453, 'C0453'),
        (0x0489, 'MSGBOX'),
        (0x04B6, 'C04B6'),
        (0x0622, 'U2918'),     # shared with BOMB.EXE
        (0x0643, 'U2968'),     # shared with BOMB.EXE (only its init part is linked)
        (0x0644, 'PRINTER'),
        (0x0648, 'GRAPH'),
        (0x0752, 'CRT'),
        (0x07B4, 'DIALOGS'),
        (0x09E8, 'APP'),
        (0x0A5B, 'MENUS'),
        (0x0C51, 'VIEWS'),
        (0x116F, 'HISTLIST'),
        (0x1174, 'MEMORY'),
        (0x1187, 'DRIVERS'),
        (0x1232, 'OBJECTS'),
        (0x12D4, 'DOS'),
        (0x12DC, 'SYSTEM'),
        (0x146F, 'DATA'),
        (0x15E5, 'STACK'),
    ]
    LIB = {'PRINTER', 'DOS', 'CRT', 'GRAPH', 'SYSTEM', 'MSGBOX', 'DIALOGS', 'APP', 'MENUS', 'VIEWS',
           'HISTLIST', 'MEMORY', 'DRIVERS', 'OBJECTS'}
    DSEG = 0x146F
    SRCDIRS = ['src', 'src_cfg']    # src_cfg overrides / adds to src
    # The shared units keep the marker names of BOMB.EXE (src/U2918.PAS, src/U2968.PAS),
    # so the BOMBCFG procedures of those units are renamed to their BOMB names.
    # U2918_00A5 (BOMBCFG offset) is a function that BOMB.EXE does not link.
    PROC_ALIAS = {'U2918_0000': 'U2918_015D', 'U2918_002D': 'U2918_0286', 'U2918_00DD': 'U2918_02FE',
                  'U2918_0116': 'U2918_03A9', 'U2918_014E': 'U2918_03E1', 'U2968_0000': 'U2968_00DD'}
    PROC_DROP = {'U2918_0129'}      # strings of U2918's init part, misdetected as a procedure
    KEEPALL_SKIP = set()
    # U2918/U2968 globals are named by their BOMB.EXE offsets (E7E2-E821); in BOMBCFG
    # their var blocks are at 1120-115F
    LAYOUT_REMAP = [(0xE7E2, 0xE822, 0x1120 - 0xE7E2)]
    KEEPALL_ONLY = {'U2918': {'U2918_015D', 'U2918_0286', 'U2918_00A5', 'U2918_02FE', 'U2918_03A9'},
                    'U2968': set()}
IMG_END_PARA = None  # filled by tools


def seg_of(para):
    for s, n in UNITS:
        if s == para:
            return n
    return None


def unit_bounds(img_len):
    out = []
    for i, (s, n) in enumerate(UNITS):
        if n in ('DATA', 'STACK'):
            break
        e = UNITS[i + 1][0]
        out.append((n, s, s * 16, e * 16))
    return out
