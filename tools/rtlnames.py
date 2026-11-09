#!/usr/bin/env python3
"""Derive names for library (SYSTEM/GRAPH/CRT/DOS/PRINTER) entry points used by
BOMB.EXE, by matching code against probe/PROBE.EXE (built from generated
probe source where each construct sits in its own procedure).

Writes tools/rtl_names.json : {"SYSTEM:35CA": "s:=s2 [sy_strassign#0]", ...}
"""
import sys, os, json, re, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import exe, units as U

ROOT = exe.ROOT
PDIR = os.path.join(ROOT, 'probe')


def masked(m, lin, n):
    b = bytearray(m.img[lin:lin + n])
    for i in range(n - 1):
        if lin + i in m.reloc_set:
            b[i] = b[i + 1] = 0xEE
    # mask near call/jmp rel16 displacements (smart linking moves targets)
    i = 0
    while i < n - 2:
        if b[i] in (0xE8, 0xE9):
            b[i + 1] = b[i + 2] = 0xEE
            i += 3
        else:
            i += 1
    return bytes(b)


def probe_names(base):
    pm = exe.MZ(os.path.join(PDIR, base + '.EXE'))
    mp = exe.load_map(os.path.join(PDIR, base + '.MAP'))
    segs = {name: start >> 4 for start, stop, name, cls in mp['segments']}
    seg2name = {v: k for k, v in segs.items()}
    src = open(os.path.join(PDIR, base + '.PAS')).read().split('\n')
    procline = {}
    for i, l in enumerate(src):
        mm = re.match(r'(?:procedure|constructor|destructor) ([\w.]+);(.*)$', l)
        if mm:
            if 'begin' in mm.group(2):
                procline[i + 1] = (mm.group(1), mm.group(2))
            else:
                procline[i + 2] = (mm.group(1), src[i + 1].strip())
    lines = sorted((ln, off) for ln, sg, off in mp['lines'][base] if sg == 0)
    starts = sorted((off, procline[ln]) for ln, off in lines if ln in procline)
    names = {}
    for k, (off, (nm, body)) in enumerate(starts):
        end = starts[k + 1][0] if k + 1 < len(starts) else off + 0x200
        lin = off
        idx = 0
        while lin < end:
            if pm.img[lin] == 0x9A and (lin + 3) in pm.reloc_set:
                o = struct.unpack('<H', pm.img[lin + 1:lin + 3])[0]
                sv = struct.unpack('<H', pm.img[lin + 3:lin + 5])[0]
                un = seg2name.get(sv)
                if un and un != base:
                    body2 = body.replace('begin', '').replace('end;', '').strip().rstrip(';')
                    names.setdefault((un, o), []).append('%s#%d' % (body2, idx))
                    idx += 1
                lin += 5
            else:
                lin += 1
    return pm, segs, names


def main():
    allp = [probe_names(b) for b in ('PROBE', 'PROBE2')]
    # match into BOMB: for each BOMB lib far-call target pick the most similar probe entry
    bm = exe.MZ(os.path.join(ROOT, 'orig', 'BOMB.EXE'))
    bsegs = {n: s for s, n in U.UNITS}
    targets = set()
    for site in bm.reloc_lin:
        if bm.img[site - 3] == 0x9A:
            sv = bm.w(site); o = bm.w(site - 2)
            un = U.seg_of(sv)
            if un in U.LIB:
                targets.add((un, o))
    out = {}
    unmatched = []
    N = 40
    for un, o in sorted(targets):
        bb = masked(bm, bsegs[un] * 16 + o, N)
        best = []
        for pm, segs, names in allp:
            for (pu, po), labs in names.items():
                if pu != un:
                    continue
                pb = masked(pm, segs[pu] * 16 + po, N)
                sc = sum(1 for x, y in zip(bb, pb) if x == y)
                best.append((sc, po, labs))
        # merge identical-score duplicates of the same labels set
        dedup = {}
        for sc, po, labs in best:
            key = tuple(labs)
            if key not in dedup or dedup[key][0] < sc:
                dedup[key] = (sc, po, labs)
        best = list(dedup.values())
        best.sort(key=lambda t: -t[0])
        if len(best) > 1 and best[0][0] >= N - 4 and best[1][0] == best[0][0]:
            top = [b for b in best if b[0] == best[0][0]]
            merged = []
            for b in top:
                merged += b[2]
            best = [(best[0][0], best[0][1], merged)] + [b for b in best if b[0] < best[0][0]]
        if best and ((best[0][0] >= N - 6 and (len(best) == 1 or best[1][0] < best[0][0])) or (best[0][0] >= 20 and (len(best) == 1 or best[1][0] <= best[0][0] - 8))):
            labs = best[0][2]
            out['%s:%04X' % (un, o)] = '; '.join(sorted(set(labs), key=labs.index)[:4])
        else:
            unmatched.append((un, o, best[:2]))
    manual = {'SYSTEM:0000': 'System init', 'SYSTEM:0A81': '8087 emulator init', 'CRT:0000': 'Crt init',
              'GRAPH:193E': 'Graph init', 'PRINTER:0005': 'Printer init', 'DOS:00FF': 'SetIntVec',
              'GRAPH:105F': 'GetMaxX or GetX?', 'GRAPH:1072': 'GetMaxY or GetY?', 'GRAPH:1028': 'GetFillPattern/GetLineSettings?'}
    for k, v in manual.items():
        out.setdefault(k, v)
    for u in unmatched:
        print('unmatched', u[0], hex(u[1]), [(b[0], b[2][:2]) for b in u[2]])
    json.dump(out, open(os.path.join(ROOT, 'tools', 'rtl_names.json'), 'w'), indent=1, sort_keys=True)
    print('matched', len(out), 'unmatched', len(unmatched))
    # which BOMB lib targets lack names
    return out


if __name__ == '__main__':
    main()
