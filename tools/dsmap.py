"""DS reference map of the original EXE: which units touch which DS offsets."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import exe, tpdis, units as U
from collections import defaultdict

def refs(m=None):
    m = m or exe.MZ(os.path.join(exe.ROOT, 'orig', 'BOMB.EXE'))
    d = tpdis.Disasm(m).run()
    allref = defaultdict(lambda: defaultdict(set))
    for dct, k in ((d.dsrefs, 'd'), (d.dsidx, 'i'), (d.dsptr, 'p')):
        for off, srcs in dct.items():
            for s_ in srcs:
                allref[off][d.unit_at(s_)[0]].add(k)
    return d, allref

if __name__ == '__main__':
    lo = int(sys.argv[1], 16) if len(sys.argv) > 1 else 0
    hi = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0x10000
    d, allref = refs()
    order = [n for _, n in U.UNITS]
    for off in sorted(o for o in allref if lo <= o < hi):
        us = sorted(allref[off], key=order.index)
        print('%04X %s' % (off, ' '.join('%s:%s' % (u, ''.join(sorted(allref[off][u]))) for u in us)))
