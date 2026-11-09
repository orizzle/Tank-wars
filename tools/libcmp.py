"""For each library routine of the original (chunk starting at a far target),
check whether its normalised instruction sequence occurs in the build's segment."""
import sys, os, struct
sys.path.insert(0, '/vmstore/claude/bomb/decomp/tools')
os.environ['TW_TARGET'] = 'BOMBCFG'
import exe, units as U
from capstone import *
md = Cs(CS_ARCH_X86, CS_MODE_16)
work = sys.argv[1]
only = sys.argv[2:] 
o = exe.MZ(U.ORIG)
n = exe.MZ(os.path.join(work, 'BOMBCFG.EXE'))
mp = exe.load_map(os.path.join(work, 'BOMBCFG.MAP'))
nseg = {nm: (s, e + 1) for s, e, nm, c in mp['segments'] if c == 'CODE'}
oseg = {nm: (s * 16, U.UNITS[i + 1][0] * 16) for i, (s, nm) in enumerate(U.UNITS) if nm in U.LIB}
def toks(m, a, b):
    out = []
    pos = a
    while pos < b:
        got = False
        for ins in md.disasm(m.img[pos:min(b, pos + 16)], 0, 1):
            raw = bytearray(ins.bytes)
            for k in range(len(raw) - 1):
                if pos + k in m.reloc_set:
                    raw[k] = raw[k + 1] = 0xEE
                    if raw[0] == 0x9A: raw[1] = raw[2] = 0xEE   # far call offset
                    if k >= 3 and raw[k-3] in (0xB8,0xB9,0xBA,0xBB,0xBE,0xBF): pass
            if raw[0] in (0xE8, 0xE9) and len(raw) == 3:
                raw[1] = raw[2] = 0xEE
            # mov reg,imm preceding a relocated seg (code pointer offsets)
            if 0xB8 <= raw[0] <= 0xBF and len(raw) == 3 and (pos + 4) in m.reloc_set:
                raw[1] = raw[2] = 0xEE
            out.append((pos, bytes(raw)))
            pos += ins.size
            got = True
        if not got:
            out.append((pos, bytes([m.img[pos]])))
            pos += 1
    return out
tg = set()
for site in o.reloc_lin:
    if site >= 2:
        tg.add(o.w(site) * 16 + o.w(site - 2))
for un in [x for x in U.LIB]:
    if only and un not in only: continue
    a, b = oseg[un]
    if un not in nseg: print(un, 'missing'); continue
    na, nb = nseg[un]
    T2 = toks(n, na, nb)
    s2 = b''.join(t for p, t in T2)
    starts = sorted(x for x in tg if a <= x < b)
    bad = []
    for i, p in enumerate(starts):
        q = starts[i + 1] if i + 1 < len(starts) else b
        T1 = toks(o, p, q)
        while T1 and T1[-1][1] == b'\x00': T1.pop()
        s1 = b''.join(t for p_, t in T1)
        if not s1 or s2.find(s1) >= 0: continue
        # longest matching prefix in instructions
        k = 0
        lo, hi = 0, len(T1)
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if s2.find(b''.join(t for p_, t in T1[:mid])) >= 0: lo = mid
            else: hi = mid - 1
        bad.append('%04X(+%X of %X)' % (p - a, T1[lo][0] - p if lo < len(T1) else q - p, q - p))
    print('%-8s %3d chunks, not found: %s' % (un, len(starts), ' '.join(bad)))
