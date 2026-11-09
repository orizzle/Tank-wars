#!/usr/bin/env python3
"""Replace the placeholder declarations covering DS range [START,END) in a
unit's var (or const) block by one new declaration.

usage: mergevar.py UNIT START END 'Name_XXXX: Type;'
   e.g. mergevar.py U27D1 440A 460A 'KeyDown_440A: array[0..511] of Boolean;'

Only works on the generated per-offset declarations (lines that start with an
identifier ending in _XXXX).  The first removed declaration must begin exactly
at START and the next remaining one at END.  For typed constants (c_XXXX) the
removed lines include their initializer; you have to supply the new
initializer yourself (the tool prints the old bytes for reference).
After editing: build, then `cmp.py --layout` checks every _XXXX name is at XXXX.
"""
import sys, os, re, fcntl

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(2)
    unit, lo, hi, decl = sys.argv[1].upper(), int(sys.argv[2], 16), int(sys.argv[3], 16), sys.argv[4]
    path = os.path.join(ROOT, 'src', unit + '.PAS')
    lk = open(os.path.join(ROOT, 'build', unit + '.lock'), 'w')
    fcntl.flock(lk, fcntl.LOCK_EX)
    L = open(path).read().split('\n')
    # find declaration starts: "  name_XXXX: ..." possibly multi-line until ';' at paren depth 0
    starts = []
    for i, l in enumerate(L):
        mm = re.match(r'^\s+([A-Za-z]\w*_([0-9A-F]{4}))\s*:', l)
        if mm:
            starts.append((i, int(mm.group(2), 16), mm.group(1)))
    idx = [k for k, (i, off, nm) in enumerate(starts) if lo <= off < hi]
    if not idx:
        sys.exit('no declarations in range')
    first = starts[idx[0]]
    if first[1] != lo:
        sys.exit('first declaration in range is at %04X, not %04X' % (first[1], lo))
    after = starts[idx[-1] + 1] if idx[-1] + 1 < len(starts) else None
    if after is None or after[1] != hi:
        sys.exit('declaration following the range is at %s, not %04X' % ('%04X' % after[1] if after else '-', hi))
    # removal: from first line to the line before 'after', but stop at blank/section lines
    i0 = first[0]
    i1 = after[0]
    # do not swallow comments/section keywords between: only remove lines that belong to decls
    removed = L[i0:i1]
    keep_tail = []
    while removed and (removed[-1].strip().startswith('{') or removed[-1].strip() == ''):
        keep_tail.insert(0, removed.pop())
    print('removed %d lines:' % len(removed))
    for r in removed[:8]:
        print('   ' + r)
    if len(removed) > 8:
        print('   ...')
    L[i0:i1] = ['  ' + decl.strip()] + keep_tail
    open(path, 'w').write('\n'.join(L))
    print('inserted: ' + decl.strip())


if __name__ == '__main__':
    main()
