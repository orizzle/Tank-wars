#!/usr/bin/env python3
"""Generate the initial skeleton sources (src/*.PAS) from the original EXE.

Run once.  Refuses to overwrite existing files unless --force.
"""
import sys, os, json, struct, re, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import exe, tpdis, units as U, cmp as C
from collections import defaultdict, Counter

ROOT = exe.ROOT
SRC = os.path.join(ROOT, 'src')

USER = [n for _, n in U.UNITS if n not in U.LIB and n not in ('DATA', 'STACK', 'BOMB')]
INIT_ORDER = list(reversed(USER))          # most basic first

# initialization parts (called from the main program's begin)
INITS = {'U2968': 0x00DD, 'U2918': 0x03E1, 'U2823': 0x0F17, 'U27D4': 0x04B9, 'U27D1': 0x0000,
         'U27B1': 0x01DF, 'U26D4': 0x00FB, 'U2390': 0x031D}
# linked .OBJ data at the end of a unit's code segment
OBJS = {'U0098': [(0x20FE, 'VGA256', 'BGI', 'VGA256Driver'), (0x2DD7, 'LITT', 'CHR', 'LittFont'),
                  (0x41E2, 'EURO', 'CHR', 'EuroFont'), (0x62F5, 'TINY', 'CHR', 'TinyFont')],
        'U26D4': [(0x0100, 'SINTAB', 'BIN', 'SinTable')]}
OBJ_SIZES = {'VGA256': 0x2DD7 - 0x20FE, 'LITT': 0x41E2 - 0x2DD7, 'EURO': 0x62F5 - 0x41E2,
             'TINY': 0x80 + 0x584}

# data ownership (see notes/data-layout.md)
DS_CONST = [('U23C3', 0x0002, 0x0056), ('U27D1', 0x0056, 0x3840)]  # 3840-3A89: Graph/Crt/... consts
DS_VARS = [('U27D1', 0x3ACC, 0xE7A0), ('U27D4', 0xE7A0, 0xE7C0), ('U2823', 0xE7C0, 0xE7E2),
           ('U2918', 0xE7E2, 0xE820), ('U2968', 0xE820, 0xE822)]

SOFTREAL = {0x3C19, 0x3C25, 0x3C2B, 0x3C31, 0x3C43, 0x3CF2}


def pas_bytes(bs, indent='    '):
    lines = []
    for i in range(0, len(bs), 16):
        lines.append(indent + ','.join('$%02X' % b for b in bs[i:i + 16]))
    return ',\n'.join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--force', action='store_true')
    a = ap.parse_args()
    os.makedirs(SRC, exist_ok=True)
    orig = C.orig_side()
    m = orig.m
    d = tpdis.Disasm(m).run()
    img = m.img
    info = orig.info

    # ---- who calls whom / address taken
    called_from = defaultdict(set)
    for site in m.reloc_lin:
        if site >= 3 and img[site - 3] == 0x9A and site < U.DSEG * 16:
            sv = m.w(site); off = m.w(site - 2)
            tu = U.seg_of(sv)
            su = d.unit_at(site)
            if tu and su and tu not in U.LIB:
                called_from['%s_%04X' % (tu, off)].add(su[0])
    exported = set(k for k, v in called_from.items() if any(u != k.split('_')[0] for u in v))
    for p, kinds in d.procs.items():
        if 'codeptr' in kinds or 'dsptr' in kinds:
            u = d.unit_at(p)
            if u:
                exported.add('%s_%04X' % (u[0], p - u[2]))

    # ---- per unit directive guesses
    def unit_flags(un):
        n, s, ua, ue = [b for b in d.ubounds if b[0] == un][0]
        emu = soft = io = g286 = 0
        for lin, (ln, mn, ops, e) in d.code.items():
            if not (ua <= lin < ue):
                continue
            if e:
                emu += 1
            if mn == 'lcall' and img[lin] == 0x9A:
                o = struct.unpack('<H', img[lin + 1:lin + 3])[0]
                sv = struct.unpack('<H', img[lin + 3:lin + 5])[0]
                if U.seg_of(sv) == 'SYSTEM':
                    if o in SOFTREAL:
                        soft += 1
                    if o == 0x04A9:
                        io += 1
            if mn in ('enter', 'leave', 'pusha', 'popa', 'bound') or \
               (mn == 'push' and ops.startswith('0x') or (mn == 'push' and re.match(r'^-?\d', ops))) or \
               (mn in ('shl', 'shr', 'sar', 'rol', 'ror', 'rcl', 'rcr', 'sal') and img[lin] in (0xC0, 0xC1)) or \
               (mn == 'imul' and img[lin] in (0x69, 0x6B)):
                g286 += 1
        return dict(emu=emu, soft=soft, io=io, g286=g286)

    flags = {}
    for un in USER + ['BOMB']:
        flags[un] = unit_flags(un)

    def directives(un):
        f = flags[un]
        n = 'N+,E+' if f['emu'] else 'N-,E+'
        g = 'G+' if f['g286'] else 'G-'
        i = 'I+' if f['io'] else 'I-'
        return '{$A-,B-,D+,F+,%s,%s,L+,%s,O-,R-,S-,V+,X+}' % (g, i, n)

    # ---- DS helpers
    dsacc = defaultdict(Counter)
    for off, srcs in d.dsrefs.items():
        for s_ in srcs:
            ln, mn, ops, e = d.code[s_]
            w = 'byte' if 'byte ptr' in ops else ('word' if 'word ptr' in ops else ('dword' if 'dword ptr' in ops else '?'))
            dsacc[off][w] += 1
    refoffs = set(d.dsrefs) | set(d.dsidx) | set(d.dsptr)

    def split_points(lo, hi):
        pts = sorted(set([lo] + [o for o in refoffs if lo < o < hi]))
        return [(pts[i], pts[i + 1] if i + 1 < len(pts) else hi) for i in range(len(pts))]

    def var_decls(lo, hi):
        out = []
        for s_, e_ in split_points(lo, hi):
            size = e_ - s_
            acc = dsacc.get(s_, Counter())
            w = acc.most_common(1)[0][0] if acc else '?'
            wsz = {'byte': 1, 'word': 2, 'dword': 4}.get(w, 0)
            if size == 1:
                out.append('  g_%04X: Byte;' % s_)
                continue
            if wsz and size > wsz:
                out.append('  g_%04X: %s;' % (s_, {1: 'Byte', 2: 'Word', 4: 'LongInt'}[wsz]))
                rest = size - wsz
                s2 = s_ + wsz
                out.append('  g_%04X: %s;' % (s2, 'Byte' if rest == 1 else 'array[0..%d] of Byte' % (rest - 1)))
                continue
            if size == 2 and w in ('word', '?'):
                t = 'Word'
            elif size == 4 and w in ('dword', 'word'):
                t = 'LongInt'
            else:
                t = 'array[0..%d] of Byte' % (size - 1)
            out.append('  g_%04X: %s;' % (s_, t))
        return out

    def const_decls(lo, hi):
        ds = img[U.DSEG * 16:]
        out = []
        for s_, e_ in split_points(lo, hi):
            bs = ds[s_:e_]
            if len(bs) == 1:
                out.append('  c_%04X: Byte = $%02X;' % (s_, bs[0]))
            else:
                out.append('  c_%04X: array[0..%d] of Byte = (\n%s);' % (s_, len(bs) - 1, pas_bytes(bs)))
        return out

    # ---- write OBJ payloads
    objdir = os.path.join(SRC)
    for un, objs in OBJS.items():
        base = U.seg_of  # noqa
        ua = [b for b in d.ubounds if b[0] == un][0][2]
        ue = [b for b in d.ubounds if b[0] == un][0][3]
        for i, (off, fname, ext, pub) in enumerate(objs):
            if fname in OBJ_SIZES:
                size = OBJ_SIZES[fname]
            else:
                end = objs[i + 1][0] if i + 1 < len(objs) else (ue - ua)
                size = end - off
                # strip trailing paragraph padding (zeros) only for the last blob
                if i + 1 == len(objs):
                    blob = img[ua + off:ua + off + size]
                    size = len(blob.rstrip(b'\x00')) or size
            p = os.path.join(objdir, '%s.%s' % (fname, ext))
            if not os.path.exists(p) or a.force:
                open(p, 'wb').write(img[ua + off:ua + off + size])

    # ---- write units
    for un in USER:
        path = os.path.join(SRC, un + '.PAS')
        if os.path.exists(path) and not a.force:
            print('skip', path)
            continue
        idx = INIT_ORDER.index(un)
        lower = INIT_ORDER[:idx]
        uses = ['Graph', 'Crt', 'Dos', 'Printer'] + lower
        procs = sorted((v['off'], k) for k, v in info.items() if v['unit'] == un)
        objlo = min((o for o, *_ in OBJS.get(un, [])), default=0x10000)
        procs = [(o, k) for o, k in procs if o < objlo]
        init = INITS.get(un)
        L = []
        L.append(directives(un))
        L.append('unit %s;' % un)
        L.append('')
        L.append('interface')
        L.append('')
        L.append('uses')
        L.append('  ' + ',\n  '.join(', '.join(uses[i:i + 6]) for i in range(0, len(uses), 6)) + ';')
        L.append('')
        consts = [(lo, hi) for u_, lo, hi in DS_CONST if u_ == un]
        vars_ = [(lo, hi) for u_, lo, hi in DS_VARS if u_ == un]
        if consts:
            L.append('const')
            for lo, hi in consts:
                L.append('  { DS %04X-%04X }' % (lo, hi - 1))
                L += const_decls(lo, hi)
            L.append('')
        if vars_:
            L.append('var')
            for lo, hi in vars_:
                L.append('  { DS %04X-%04X }' % (lo, hi - 1))
                L += var_decls(lo, hi)
            L.append('')
        hdr = {}
        for off, k in procs:
            if init is not None and off == init:
                continue
            ret = info[k]['end']
            # param bytes from the last retf N in the proc
            n = 0
            lin = [b for b in d.ubounds if b[0] == un][0][2]
            for l2, (ln, mn, ops, e) in d.code.items():
                if d.owner.get(l2) == lin + off and mn == 'retf' and ops:
                    n = int(ops, 16)
            params = ''
            if n:
                params = '(' + ', '.join('a%d' % (i + 1) for i in range(n // 2)) + ': Word)'
            hdr[k] = 'procedure %s%s;' % (k, params)
        for off, k in procs:
            if k in hdr:  # everything in the interface (KEEPALL needs it)
                L.append(hdr[k])
        for off, fname, ext, pub in OBJS.get(un, []):
            L.append('procedure %s;' % pub)
        L.append('')
        L.append('implementation')
        L.append('')
        for off, k in procs:
            if k not in hdr:
                continue
            L.append('{#%s}' % k)
            L.append(hdr[k])
            L.append('begin')
            L.append('end;')
            L.append('')
        for off, fname, ext, pub in OBJS.get(un, []):
            L.append('procedure %s; external; {$L %s.OBJ}' % (pub, fname))
        if OBJS.get(un):
            L.append('')
        if init is not None:
            L.append('{#%s_%04X}' % (un, init))
            L.append('begin')
        L.append('end.')
        open(path, 'w').write('\n'.join(L) + '\n')
        print('wrote', path, len(procs), 'procs', flags[un])
    print('BOMB flags', flags['BOMB'])


if __name__ == '__main__':
    main()
