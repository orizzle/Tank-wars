"""MZ EXE loader for Turbo Pascal 6 executables (Tank Wars decomp tooling)."""
import struct, os, bisect

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


class MZ:
    def __init__(self, path):
        self.path = path
        d = self.raw = open(path, 'rb').read()
        (sig, lastp, pages, nrel, hdrp, minalloc, maxalloc, ss, sp, csum,
         ip, cs, relo, ovl) = struct.unpack('<14H', d[:28])
        self.hdr = dict(lastp=lastp, pages=pages, nrel=nrel, hdrp=hdrp,
                        minalloc=minalloc, maxalloc=maxalloc, ss=ss, sp=sp,
                        csum=csum, ip=ip, cs=cs, relo=relo, ovl=ovl)
        size = (pages - 1) * 512 + lastp if lastp else pages * 512
        self.img = d[hdrp * 16:size]
        self.relocs = [struct.unpack('<HH', d[relo + 4 * i:relo + 4 * i + 4])
                       for i in range(nrel)]
        # linear addresses of words that get relocated
        self.reloc_lin = sorted(s * 16 + o for o, s in self.relocs)
        self.reloc_set = set(self.reloc_lin)
        self.ss = ss
        self.cs = cs
        # segments: all relocated segment values + the reloc site segments
        segvals = set()
        for lin in self.reloc_lin:
            segvals.add(self.w(lin))
        self.segvals = sorted(segvals)

    def w(self, lin):
        return struct.unpack('<H', self.img[lin:lin + 2])[0]

    def b(self, lin, n):
        return self.img[lin:lin + n]


def load_map(path):
    """Parse a TPC /GD map: returns dict(segments=[(start,stop,name,class)],
    publics=[(seg,off,name)], lines={unit:[(line,seg,off)]})"""
    segs, pubs, lines = [], [], {}
    mode = None
    cur = None
    for ln in open(path, 'r', errors='replace'):
        ln = ln.rstrip('\r\n')
        s = ln.strip()
        if s.startswith('Start  Stop'):
            mode = 'segs'; continue
        if s.startswith('Address') and 'Publics by Value' in s:
            mode = 'pubs'; continue
        if s.startswith('Line numbers for'):
            mode = 'lines'
            # Line numbers for UA(UA.PAS) segment UA
            cur = s.split()[3].split('(')[0]
            lines.setdefault(cur, [])
            continue
        if s.startswith('Program entry point'):
            mode = None; continue
        if not s:
            continue
        if mode == 'segs':
            p = s.split()
            segs.append((int(p[0][:-1], 16), int(p[1][:-1], 16), p[3], p[4]))
        elif mode == 'pubs':
            a, name = s.split(None, 1)
            sg, of = a.split(':')
            pubs.append((int(sg, 16), int(of, 16), name.strip()))
        elif mode == 'lines':
            p = s.split()
            for i in range(0, len(p) - 1, 2):
                sg, of = p[i + 1].split(':')
                lines[cur].append((int(p[i]), int(sg, 16), int(of, 16)))
    return dict(segments=segs, publics=pubs, lines=lines)
