#!/usr/bin/env python3
"""Compare a build of the Pascal sources against the original BOMB.EXE.

usage:
  cmp.py [--work DIR] [UNIT ...]           per-procedure match summary
  cmp.py [--work DIR] --proc U0728_05D8     side-by-side diff of one procedure
  cmp.py [--work DIR] --full                byte-exact whole-EXE comparison
  cmp.py [--work DIR] --data                compare initialized DS image

Procedures are identified by markers in the sources: a comment {#U0728_05D8}
placed on its own line directly before the procedure/function header (or
before the 'begin' of a unit initialization part / main program).  The name
encodes the unit and the offset of the procedure entry in the ORIGINAL exe.

Normalisation (so that a unit can be matched while others are unfinished):
  * far call targets are compared by procedure name (marker) where possible
  * relocated segment words are compared by unit name
  * CS-relative constant offsets (mov di,imm / push cs; cs: overrides; FPU
    emulator CS loads) are compared relative to the procedure entry
DS offsets are compared raw: the data layout has to be exact.
"""
import sys, os, re, json, struct, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import exe, tpdis, units as U

ROOT = exe.ROOT
ORIG = U.ORIG
CACHE = os.path.join(ROOT, 'build', 'orig_procs%s.json' % ('' if U.TARGET == 'BOMB' else '_' + U.TARGET))


class Side:
    """One executable + its unit table + procedure table."""

    def __init__(self, m, unit_table, dseg, procs):
        self.m = m
        self.img = m.img
        self.units = unit_table          # [(para, name)] memory order, incl DATA
        self.para2unit = {p: n for p, n in unit_table}
        self.unitbase = {n: p * 16 for p, n in unit_table}
        self.dseg = dseg
        self.procs = procs               # name -> (unit, entry_off)
        self.byaddr = {}
        for nm, (un, off) in procs.items():
            self.byaddr[(un, off)] = nm
        self.dis = tpdis.Disasm(m, unit_table, dseg)
        self._libfp = {}
        self._librank = None

    def libfp(self, un, off):
        key = (un, off)
        if key in self._libfp:
            return self._libfp[key]
        base = self.unitbase[un]
        o = off
        fp = []
        for _ in range(10):
            ln, mn, ops, ins, emu = self.dis.decode(base + o, base)
            if mn == 'lcall':
                fp.append('lcall')
            else:
                fp.append(mn + ' ' + re.sub(r'0x[0-9a-f]{3,4}', '#', ops))
            o += ln
            if mn in ('ret', 'retf', 'jmp', 'ljmp', 'iret'):
                break
        fp = '|'.join(fp)
        self._libfp[key] = fp
        return fp

    def libid(self, un, off):
        if self._librank is None:
            groups = {}
            for site in self.m.reloc_lin:
                if site >= 3 and self.img[site - 3] == 0x9A:
                    sv = self.m.w(site)
                    u2 = self.para2unit.get(sv)
                    if u2 in U.LIB:
                        o2 = self.m.w(site - 2)
                        groups.setdefault((u2, self.libfp(u2, o2)), set()).add(o2)
            self._librank = {}
            for (u2, fp), offs in groups.items():
                for r, o2 in enumerate(sorted(offs)):
                    self._librank[(u2, o2)] = (fp, r)
        return self._librank.get((un, off), (self.libfp(un, off), 0))


def orig_side():
    m = exe.MZ(ORIG)
    if os.path.exists(CACHE) and os.path.getmtime(CACHE) > os.path.getmtime(os.path.join(ROOT, 'tools', 'tpdis.py')):
        info = json.load(open(CACHE))
    else:
        d = tpdis.Disasm(m).run()
        info = {}
        for p in sorted(d.procs):
            u = d.unit_at(p)
            if not u or u[0] in U.LIB:
                continue
            info['%s_%04X' % (u[0], p - u[2])] = dict(unit=u[0], off=p - u[2],
                                                      end=d.code_end.get(p, p) - u[2])
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        json.dump(info, open(CACHE, 'w'), indent=0)
    info = {U.PROC_ALIAS.get(k, k): v for k, v in info.items() if k not in U.PROC_DROP}
    procs = {k: (v['unit'], v['off']) for k, v in info.items()}
    s = Side(m, U.UNITS, U.DSEG, procs)
    s.info = info
    return s


def find_markers(work):
    """-> {marker: (file, line)}"""
    out = {}
    for f in os.listdir(work):
        if not f.upper().endswith(('.PAS', '.INC')):
            continue
        for i, l in enumerate(open(os.path.join(work, f), 'rb').read().decode('latin1').split('\n')):
            for mm in re.finditer(r'\{#([A-Z0-9]+_[0-9A-F]{4})\}', l):
                out[mm.group(1)] = (f.upper(), i + 1)
    return out


def new_side(work):
    m = exe.MZ(os.path.join(work, U.MAIN + '.EXE'))
    mp = exe.load_map(os.path.join(work, U.MAIN + '.MAP'))
    table = []
    dseg = None
    for start, stop, name, cls in mp['segments']:
        if cls == 'CODE':
            table.append((start >> 4, name))
        elif name == 'DATA':
            dseg = start >> 4
            table.append((start >> 4, 'DATA'))
        elif name == 'STACK':
            table.append((start >> 4, 'STACK'))
    # line tables: file name -> list(line, seg, off).  load_map keys by unit name;
    # re-parse to keep the file name too.
    lines = {}
    cur = None
    for ln in open(os.path.join(work, U.MAIN + '.MAP'), 'r', errors='replace'):
        s = ln.strip()
        mm = re.match(r'Line numbers for (\w+)\(([^)]+)\) segment (\w+)', s)
        if mm:
            cur = (mm.group(2).upper(), mm.group(3).upper())
            lines.setdefault(cur, [])
            continue
        if cur and re.match(r'^\d+ [0-9A-F]{4}:[0-9A-F]{4}', s):
            p = s.split()
            for i in range(0, len(p) - 1, 2):
                sg, of = p[i + 1].split(':')
                lines[cur].append((int(p[i]), int(sg, 16), int(of, 16)))
        elif cur and s and not re.match(r'^\d', s):
            cur = None
    markers = find_markers(work)
    procs = {}
    segbase = {n: p for p, n in table}
    for nm, (f, line) in markers.items():
        best = None
        for (fn, segname), ents in lines.items():
            if fn != f:
                continue
            for l, sg, of in ents:
                if l > line and (best is None or l < best[0] or (l == best[0] and of < best[2])):
                    best = (l, segname, of, sg)
        if best:
            un = best[1]
            procs[nm] = (un, best[2])
    # procedures without line numbers (external .OBJ code): use map publics
    pubs = {}
    for sg, of, pn in mp['publics']:
        pubs[pn.upper()] = (sg, of)
    para2name = {p: n for p, n in table}
    for nm in markers:
        if nm not in procs and nm in pubs:
            sg, of = pubs[nm]
            if sg in para2name:
                procs[nm] = (para2name[sg], of)
    # also externals declared without markers but named like Uxxxx_OOOO
    for pn, (sg, of) in pubs.items():
        if re.match(r'^U[0-9A-F]{4}_[0-9A-F]{4}$', pn) and pn not in procs and sg in para2name:
            procs[pn] = (para2name[sg], of)
    s = Side(m, table, dseg, procs)
    s.map = mp
    return s


# ---------------------------------------------------------------- tokens
def tokens(side, unit, start, end, entry):
    """normalised token list for [start,end) of unit (offsets in segment);
    entry = proc entry offset (for CS-relative normalisation).  Data before
    'entry' is compared raw; code from entry on is decoded."""
    base = side.unitbase[unit]
    img = side.img
    m = side.m
    out = []
    # constants before entry: raw bytes
    for o in range(start, min(entry, end)):
        out.append((o, ('b', img[base + o])))
    o = max(entry, start)
    d = side.dis
    while o < end:
        lin = base + o
        ln, mn, ops, ins, emu = d.decode(lin, base)
        if o + ln > end:
            ln = end - o
            for k in range(ln):
                out.append((o + k, ('b', img[lin + k])))
            break
        raw = img[lin:lin + ln]
        tok = None
        if raw[0] == 0x9A and ln == 5 and (lin + 3) in m.reloc_set:
            off = struct.unpack('<H', raw[1:3])[0]
            segv = struct.unpack('<H', raw[3:5])[0]
            un = side.para2unit.get(segv, '?%04X' % segv)
            nm = side.byaddr.get((un, off))
            if un in U.LIB:
                tok = ('libcall', un) + side.libid(un, off)
            else:
                tok = ('farcall', un, nm if nm else ('off', off))
        elif raw[0] == 0xE8 and ln == 3:
            tgt = (o + 3 + struct.unpack('<h', raw[1:3])[0]) & 0xFFFF
            nm = side.byaddr.get((unit, tgt))
            tok = ('nearcall', nm if nm else ('rel', tgt - entry))
        else:
            b = bytearray(raw)
            parts = []
            # relocated words
            for k in range(ln - 1):
                if lin + k in m.reloc_set:
                    segv = struct.unpack('<H', raw[k:k + 2])[0]
                    parts.append((k, ('seg', side.para2unit.get(segv, '?'))))
                    b[k] = b[k + 1] = 0
            # mov r16,imm followed by push cs  -> CS-relative constant
            nxt = img[lin + ln] if lin + ln < len(img) else None
            if ln == 3 and 0xB8 <= raw[0] <= 0xBF and nxt == 0x0E:
                imm = struct.unpack('<H', raw[1:3])[0]
                parts.append((1, ('csrel', imm - entry)))
                b[1] = b[2] = 0
            # mov r16,imm followed by a relocated mov (far pointer to code)
            if ln == 3 and 0xB8 <= raw[0] <= 0xBF and (lin + ln + 1) in m.reloc_set:
                imm = struct.unpack('<H', raw[1:3])[0]
                segv = m.w(lin + ln + 1)
                un2 = side.para2unit.get(segv)
                nm = side.byaddr.get((un2, imm))
                parts.append((1, ('ptr', un2, nm if nm else (imm - entry if un2 == unit else imm))))
                b[1] = b[2] = 0
            # cs: override memory operands / FPU emulator with CS segment
            if ins is not None:
                csov = (raw[0] == 0x2E) or (emu == 'emu3c' and (img[lin + 2] >> 6) == 1)
                if csov:
                    try:
                        for op in ins.operands:
                            if op.type == tpdis.X.X86_OP_MEM:
                                disp = op.mem.disp & 0xFFFF
                                # locate disp bytes at the end of the instruction (before imm)
                                db_ = struct.pack('<H', disp)
                                k = bytes(b).rfind(db_)
                                if k > 0:
                                    parts.append((k, ('csrel', disp - entry)))
                                    b[k] = b[k + 1] = 0
                    except Exception:
                        pass
            tok = ('i', bytes(b), tuple(parts))
        out.append((o, tok))
        o += ln
    return out


def proc_extent_orig(orig, name):
    """(const_start, entry, end) for an original proc"""
    info = orig.info[name]
    un = info['unit']
    same = sorted((v['off'], v['end']) for v in orig.info.values() if v['unit'] == un)
    prev_end = 0
    for off, e in same:
        if off == info['off']:
            break
        prev_end = max(prev_end, e)
    return prev_end, info['off'], info['end']


def compare_proc(orig, new, name):
    """returns (status, detail).  status: 'ok', 'missing', 'size', 'diff'"""
    if name not in new.procs:
        return 'missing', None
    cs0, entry, end = proc_extent_orig(orig, name)
    un = orig.info[name]['unit']
    nun, nentry = new.procs[name]
    if nun != un:
        return 'diff', 'procedure is in segment %s, expected %s' % (nun, un)
    pre = entry - cs0
    to = tokens(orig, un, cs0, end, entry)
    tn = tokens(new, un, nentry - pre, nentry + (end - entry), nentry)
    for k, (a, b) in enumerate(zip(to, tn)):
        if a[1] != b[1]:
            return 'diff', (k, a[0], b[0])
    if len(to) != len(tn):
        return 'diff', (min(len(to), len(tn)), None, None)
    return 'ok', None


def fmt_insn(side, unit, off):
    base = side.unitbase[unit]
    ln, mn, ops, ins, emu = side.dis.decode(base + off, base)
    hx = side.img[base + off:base + off + ln].hex()
    if side.img[base + off] == 0x9A and ln == 5:
        o = struct.unpack('<H', side.img[base + off + 1:base + off + 3])[0]
        sv = struct.unpack('<H', side.img[base + off + 3:base + off + 5])[0]
        un = side.para2unit.get(sv, '?')
        nm = side.byaddr.get((un, o))
        s = 'call far %s' % (nm or '%s:%04X' % (un, o))
        rn = side.dis.rtl.get('%s:%04X' % (un, o)) if un in U.LIB else None
        if rn and side is not None:
            s += ' {%s}' % rn[:50]
        return ln, hx, s
    s = (mn + ' ' + ops).strip()
    if emu:
        s = 'F> ' + s.replace('wait', '').strip()
    return ln, hx, s


def show_proc(orig, new, name, ctx=6, maxlines=400):
    cs0, entry, end = proc_extent_orig(orig, name)
    un = orig.info[name]['unit']
    print('%s: original %s:%04X-%04X (consts from %04X)' % (name, un, entry, end, cs0))
    if name not in new.procs:
        print('  not found in build (marker {#%s} missing or no code after it)' % name)
        return
    nun, nentry = new.procs[name]
    print('%s: build    %s:%04X' % (name, nun, nentry))
    st, det = compare_proc(orig, new, name)
    print('status:', st, det if det else '')
    # side by side listing
    def listing(side, unit, entry, start, end):
        rows = []
        o = start
        base = side.unitbase[unit]
        while o < entry:
            n = min(16, entry - o)
            rows.append((o, side.img[base + o:base + o + n].hex(), 'db'))
            o += n
        while o < end:
            ln, hx, s = fmt_insn(side, unit, o)
            rows.append((o, hx, s))
            o += ln
        return rows
    pre = entry - cs0
    lo = listing(orig, un, entry, cs0, end)
    nend = nentry + (end - entry) + 64
    # extend new listing to its own next proc start if known
    later = sorted(off for (u2, off) in new.procs.values() if u2 == nun and off > nentry)
    if later:
        nend = later[0]
        # trim constants of next proc: unknown; keep
    ln_ = listing(new, nun, nentry, nentry - pre, nend)
    width = 58
    print('%-*s | %s' % (width, '---- original', '---- build'))
    for i in range(max(len(lo), len(ln_))):
        a = lo[i] if i < len(lo) else None
        b = ln_[i] if i < len(ln_) else None
        sa = '%04X %-12s %s' % (a[0], a[1][:12], a[2]) if a else ''
        sb = '%04X %-12s %s' % (b[0], b[1][:12], b[2]) if b else ''
        mark = ' ' if (a and b and a[1] == b[1]) else '*'
        print('%-*s%s| %s' % (width, sa[:width], mark, sb[:70]))
        if i > maxlines:
            print('...')
            break


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('units', nargs='*')
    ap.add_argument('--work', default=os.path.join(ROOT, 'build', 'work'))
    ap.add_argument('--proc')
    ap.add_argument('--full', action='store_true')
    ap.add_argument('--data', action='store_true')
    ap.add_argument('--layout', action='store_true', help='check that every public NAME_XXXX in DATA is at DS:XXXX')
    ap.add_argument('--json', action='store_true')
    ap.add_argument('-v', action='store_true', help='list every procedure')
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    if a.full:
        o = open(ORIG, 'rb').read()
        n = open(os.path.join(work, U.MAIN + '.EXE'), 'rb').read()
        if o == n:
            print('IDENTICAL (%d bytes)' % len(o))
            return 0
        print('DIFFERENT: orig %d bytes, build %d bytes' % (len(o), len(n)))
        diffs = [i for i in range(min(len(o), len(n))) if o[i] != n[i]]
        print('%d differing bytes in common length; first at file offset %s' % (len(diffs), hex(diffs[0]) if diffs else '-'))
        return 1
    if a.layout:
        mp = exe.load_map(os.path.join(work, U.MAIN + '.MAP'))
        dseg = [s_ >> 4 for s_, e_, n_, c_ in mp['segments'] if n_ == 'DATA'][0]
        bad = 0
        n = 0
        for sg, of, nm in mp['publics']:
            mm = re.search(r'_([0-9A-F]{4})$', nm)
            if sg == dseg and mm:
                n += 1
                want = int(mm.group(1), 16)
                for lo_, hi_, delta_ in getattr(U, 'LAYOUT_REMAP', ()):
                    if lo_ <= want < hi_:
                        want = (want + delta_) & 0xFFFF
                if want != of:
                    bad += 1
                    print('  %-24s is at DS:%04X' % (nm, of))
        print('layout: %d of %d offset-named globals misplaced' % (bad, n))
        return 1 if bad else 0
    orig = orig_side()
    new = new_side(work)
    if a.data:
        od = orig.img[orig.dseg * 16:]
        nd = new.img[new.dseg * 16:]
        print('initialized DS: orig %X bytes, build %X bytes' % (len(od), len(nd)))
        runs = []
        i = 0
        L = min(len(od), len(nd))
        while i < L:
            if od[i] != nd[i]:
                j = i
                while j < L and od[j] != nd[j]:
                    j += 1
                runs.append((i, j))
                i = j
            else:
                i += 1
        for s, e in runs[:40]:
            print('  DS %04X-%04X differs' % (s, e))
        print('%d differing runs' % len(runs))
        return 0
    if a.proc:
        show_proc(orig, new, a.proc.upper())
        return 0
    units = [u.upper() for u in a.units] or [n for _, n in U.UNITS if n not in U.LIB and n not in ('DATA', 'STACK')]
    total = okc = 0
    res = {}
    for un in units:
        names = sorted((v['off'], k) for k, v in orig.info.items() if v['unit'] == un)
        stat = []
        for off, nm in names:
            st, det = compare_proc(orig, new, nm)
            stat.append((nm, st, det))
        ok = sum(1 for s in stat if s[1] == 'ok')
        total += len(stat)
        okc += ok
        res[un] = stat
        bytes_ok = sum(orig.info[nm]['end'] - proc_extent_orig(orig, nm)[0] for nm, st, d in stat if st == 'ok')
        bytes_all = sum(orig.info[nm]['end'] - proc_extent_orig(orig, nm)[0] for nm, st, d in stat)
        osz = [e - b for n_, s_, b, e in U.unit_bounds(0) if n_ == un][0]
        nsz = [stop - start + 1 for start, stop, n_, c_ in new.map['segments'] if n_ == un]
        nsz = nsz[0] if nsz else 0
        print('%-6s %3d/%3d procs match  (%5.1f%% of code bytes)   segment: orig %04X, build %04X' % (
            un, ok, len(stat), 100.0 * bytes_ok / max(1, bytes_all), osz, (nsz + 15) & ~15))
        if a.v or len(units) == 1:
            for nm, st, det in stat:
                if st != 'ok' or a.v:
                    extra = ''
                    if st == 'diff' and isinstance(det, tuple):
                        extra = 'first diff at orig +%s' % (('%X' % (det[1] - orig.info[nm]['off'])) if det[1] is not None else 'end')
                    elif det:
                        extra = str(det)
                    print('    %-12s %-7s %s' % (nm, st, extra))
    print('TOTAL %d/%d procedures match' % (okc, total))
    if a.json:
        print(json.dumps({k: [(n, s) for n, s, d in v] for k, v in res.items()}))


if __name__ == '__main__':
    sys.exit(main() or 0)
