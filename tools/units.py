"""Segment -> unit table for the ORIGINAL BOMB.EXE (paragraph values)."""
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
