#!/usr/bin/env python3
"""Rewrite all `uses` clauses so that TP6 links the units in the original order.

TP6 (/B) orders units by a depth-first walk over interface AND implementation
uses (a unit is placed when its walk finishes).  The original order is
reproduced by:
  * low units (U23C3 .. U2968): interface uses only lower units (ascending order)
  * high units (U0040 .. U2390): interface uses Graph..U23C3 only; implementation
    uses its right-hand neighbour FIRST (U0040->U0098->U0728->...->U2390), then
    any other high units it needs.
  * BOMB uses Graph..U23C3, then U0040, U0098, ... U2390.
"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'src')
LIBS = ['Graph', 'Crt', 'Dos', 'Printer']
LOW = ['U2968', 'U2918', 'U2823', 'U27D4', 'U27D1', 'U27B1', 'U26D4', 'U26A9', 'U23C3']
HIGH = ['U0040', 'U0098', 'U0728', 'U0E9B', 'U1615', 'U1B27', 'U1DD4', 'U1F69', 'U20C6', 'U22B7', 'U2390']
USES_RE = re.compile(r'\buses\b(.*?);', re.S | re.I)


def fmt(lst, indent='  '):
    rows = [', '.join(lst[i:i + 6]) for i in range(0, len(lst), 6)]
    return 'uses\n' + indent + (',\n' + indent).join(rows) + ';'


def names(clause):
    c = re.sub(r'\{[^}]*\}', '', clause)
    return [x.strip() for x in c.split(',') if x.strip()]


def fix_unit(un):
    p = os.path.join(SRC, un + '.PAS')
    s = open(p).read()
    ii = re.search(r'^\s*interface\s*$', s, re.M | re.I)
    im = re.search(r'^\s*implementation\s*$', s, re.M | re.I)
    head, iface, impl = s[:ii.end()], s[ii.end():im.end()], s[im.end():]
    mi = USES_RE.search(iface)
    used = set()
    if mi and re.sub(r'\{[^}]*\}', '', iface[:mi.start()]).strip() == '':
        used |= set(x.upper() for x in names(mi.group(1)))
    mm = USES_RE.search(impl)
    has_impl_uses = mm and re.sub(r'\{[^}]*\}', '', impl[:mm.start()]).strip() == ''
    if has_impl_uses:
        used |= set(x.upper() for x in names(mm.group(1)))
    if un in LOW:
        lower = LOW[:LOW.index(un)]   # units initialised earlier, in init order
        new_if = LIBS + lower
        new_im = []
    else:
        new_if = LIBS + LOW
        k = HIGH.index(un)
        nb = HIGH[k + 1] if k + 1 < len(HIGH) else None
        others = [h for h in HIGH if h != un and h != nb and h.upper() in used]
        new_im = ([nb] if nb else []) + others
    # rewrite interface uses
    if mi and re.sub(r'\{[^}]*\}', '', iface[:mi.start()]).strip() == '':
        iface = iface[:mi.start()] + '\n' + fmt(new_if) + iface[mi.end():]
    else:
        iface = '\n\n' + fmt(new_if) + '\n' + iface
    if has_impl_uses:
        impl = impl[:mm.start()] + ('\n' + fmt(new_im) if new_im else '') + impl[mm.end():]
    elif new_im:
        impl = '\n\n' + fmt(new_im) + '\n' + impl
    s2 = head + iface + impl
    if s2 != s:
        open(p, 'w').write(s2)
        print('updated', un, 'impl uses:', ', '.join(new_im))


def fix_main():
    p = os.path.join(SRC, 'BOMB.PAS')
    s = open(p).read()
    m = USES_RE.search(s)
    s2 = s[:m.start()] + fmt(LIBS + LOW + HIGH) + s[m.end():]
    if s2 != s:
        open(p, 'w').write(s2)
        print('updated BOMB')


for u in LOW + HIGH:
    fix_unit(u)
fix_main()
