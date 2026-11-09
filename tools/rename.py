#!/usr/bin/env python3
"""Rename identifiers across the sources using a TSV table (OLD<TAB>NEW[<TAB>note]).

  rename.py TABLE            check the table (collisions, reserved words, library names)
  rename.py TABLE --apply    rewrite src/, src_cfg/ and notes/GUIDE.md in place

Pascal identifiers are case-insensitive: matching ignores case.  String
literals and {#MARKER} comments are left alone; other comments are renamed so
that cross references stay valid.  A new name must not equal (ignoring case)
any identifier already in the sources, a Pascal reserved word or an identifier
of the Borland units (taken from the TPUs in toolchain/tp6/), so that a rename
can never silently re-bind a reference.  A NEW starting with '!' skips the
library check (for Borland's own names, e.g. in the Turbo Vision help viewer).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TP = os.path.join(ROOT, 'toolchain', 'tp6')
LIBFILES = ['turbo.tpl.pristine', 'graph.tpu', 'app.tpu', 'dialogs.tpu', 'menus.tpu', 'views.tpu',
            'objects.tpu', 'drivers.tpu', 'memory.tpu', 'histlist.tpu', 'msgbox.tpu']
RESERVED = set('''AND ARRAY ASM BEGIN CASE CONST CONSTRUCTOR DESTRUCTOR DIV DO DOWNTO ELSE END
FILE FOR FUNCTION GOTO IF IMPLEMENTATION IN INLINE INTERFACE LABEL MOD NIL NOT OBJECT OF OR
PACKED PROCEDURE PROGRAM RECORD REPEAT SET SHL SHR STRING THEN TO TYPE UNIT UNTIL USES VAR
WHILE WITH XOR ABSOLUTE ASSEMBLER EXTERNAL FAR FORWARD INTERRUPT NEAR PRIVATE VIRTUAL
PUBLIC'''.split())
ID = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')


def source_files():
    out = []
    for d in ('src', 'src_cfg'):
        for f in sorted(os.listdir(os.path.join(ROOT, d))):
            if f.upper().endswith(('.PAS', '.INC', '.ASM', '.LST')):
                out.append(os.path.join(ROOT, d, f))
    out.append(os.path.join(ROOT, 'notes', 'GUIDE.md'))
    return out


def lib_idents():
    out = set()
    for f in LIBFILES:
        p = os.path.join(TP, f)
        if not os.path.exists(p):
            sys.exit('missing %s (library identifier check needs the toolchain)' % p)
        data = open(p, 'rb').read()
        # TPU symbol names are Pascal strings; take every identifier-like run (superset)
        for mm in re.finditer(rb'[A-Za-z_][A-Za-z0-9_]{2,}', data):
            out.add(mm.group().decode().upper())
    return out


def segments(text, pascal):
    """yield (kind, chunk), kind = 'code', 'comment' (both renamed) or 'keep'
    (string literals, {#markers}: copied verbatim)."""
    if not pascal:
        # markdown / asm / lst: protect only {#...} markers
        pos = 0
        for mm in re.finditer(r'\{#[^}]*\}', text):
            yield 'comment', text[pos:mm.start()]
            yield 'keep', mm.group()
            pos = mm.end()
        yield 'comment', text[pos:]
        return
    i = 0
    n = len(text)
    start = 0
    while i < n:
        c = text[i]
        if c == "'":
            j = i + 1
            while j < n:
                if text[j] == "'":
                    if j + 1 < n and text[j + 1] == "'":
                        j += 2
                        continue
                    break
                if text[j] == '\n':
                    break
                j += 1
            kind, end = 'keep', j + 1
        elif c == '{':
            j = text.find('}', i)
            end = n if j < 0 else j + 1
            kind = 'keep' if text.startswith('{#', i) else 'comment'
        elif text.startswith('(*', i):
            j = text.find('*)', i)
            end = n if j < 0 else j + 2
            kind = 'comment'
        else:
            i += 1
            continue
        yield 'code', text[start:i]
        yield kind, text[i:end]
        i = start = end
    yield 'code', text[start:]


def load_table(path):
    tab = []
    for k, l in enumerate(open(path, encoding='utf-8')):
        l = l.rstrip('\n')
        if not l.strip() or l.startswith('#'):
            continue
        p = l.split('\t')
        if len(p) < 2:
            sys.exit('%s:%d: need OLD<TAB>NEW' % (path, k + 1))
        tab.append((p[0].strip(), p[1].strip(), k + 1))
    return tab


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    apply_ = '--apply' in sys.argv
    if len(args) != 1:
        sys.exit(__doc__)
    tab = load_table(args[0])
    files = source_files()
    texts = {f: open(f, 'rb').read().decode('latin1') for f in files}
    existing = {}
    for f, t in texts.items():
        if f.endswith('.md'):
            continue
        for kind, ch in segments(t, f.upper().endswith(('.PAS', '.INC'))):
            if kind != 'code' and not f.upper().endswith(('.ASM', '.LST')):
                continue
            for mm in ID.finditer(ch):
                existing.setdefault(mm.group().upper(), mm.group())
    lib = lib_idents()
    errs = []
    olds = {}
    news = {}
    for old, new, ln in tab:
        nolib = new.startswith('!')
        new = new.lstrip('!')
        if not ID.fullmatch(new):
            errs.append('line %d: bad identifier %r' % (ln, new))
        if old.upper() in olds:
            errs.append('line %d: %s renamed twice' % (ln, old))
        if old.upper() not in existing:
            errs.append('line %d: %s does not occur in the sources' % (ln, old))
        if new.upper() in news:
            errs.append('line %d: %s also used for %s' % (ln, new, news[new.upper()]))
        olds[old.upper()] = new
        news[new.upper()] = old
        if new.upper() in RESERVED:
            errs.append('line %d: %s is a reserved word' % (ln, new))
        if not nolib and new.upper() in lib:
            errs.append('line %d: %s is a library identifier' % (ln, new))
        if len(new) > 63:
            errs.append('line %d: %s longer than 63 characters' % (ln, new))
    for nu, old in news.items():
        if nu in existing and nu not in olds and nu != old.upper():
            errs.append('%s -> %s: %s already exists in the sources' % (old, existing[nu], existing[nu]))
    if errs:
        print('\n'.join(errs))
        print('%d problem(s)' % len(errs))
        return 1
    print('table OK: %d renames' % len(tab))
    if not apply_:
        return 0
    rx = re.compile(r'\b(%s)\b' % '|'.join(re.escape(o) for o, n, _ in tab), re.I)
    changed = 0
    for f, t in texts.items():
        pascal = f.upper().endswith(('.PAS', '.INC'))
        out = []
        for kind, ch in segments(t, pascal):
            out.append(ch if kind == 'keep' else rx.sub(lambda mm: olds[mm.group().upper()], ch))
        nt = ''.join(out)
        if nt != t:
            open(f, 'wb').write(nt.encode('latin1'))
            changed += 1
    print('rewrote %d files' % changed)
    return 0


if __name__ == '__main__':
    sys.exit(main())
