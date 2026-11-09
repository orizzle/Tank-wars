#!/usr/bin/env python3
"""Build the Pascal sources with Turbo Pascal 6.0 (TPC.EXE under headless DOSBox).

usage: build.py [--work DIR] [--mine U0728,U0E9B] [--quiet]

* copies src/ into the work dir (default build/work) and runs
  TPC /B /GD BOMB.PAS there; result: WORK/BOMB.EXE, WORK/BOMB.MAP
* if compilation fails in a file that is NOT listed in --mine, that file is
  replaced by its last-known-good copy (build/lkg/) and the build is retried.
  (Lets several people/agents work on different units at the same time.)
* after a successful build, the files that were used are stored in build/lkg/.
Exit status 0 on success; compiler output is printed.
"""
import sys, os, shutil, subprocess, argparse, re, fcntl, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, 'src')
LKG = os.path.join(ROOT, 'build', 'lkg')
TP = os.path.join(ROOT, 'toolchain', 'tp6')

CONF = """[sdl]
output=surface
[dosbox]
memsize=16
[cpu]
cycles=max
[mixer]
nosound=true
[speaker]
pcspeaker=false
[autoexec]
mount c "{work}"
mount t "{tp}"
c:
t:\\tpc.exe /Tt:\\ /Ut:\\ {args} > TPC.OUT
exit
"""


def run_tpc(work, args):
    conf = os.path.join(work, '_dosbox.conf')
    open(conf, 'w').write(CONF.format(work=work, tp=TP, args=args))
    for f in ('TPC.OUT', 'BOMB.EXE'):
        try:
            os.remove(os.path.join(work, f))
        except FileNotFoundError:
            pass
    env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
    subprocess.run(['timeout', '300', 'dosbox', '-conf', conf, '-exit'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env)
    try:
        return open(os.path.join(work, 'TPC.OUT'), 'rb').read().decode('latin1').replace('\r', '')
    except FileNotFoundError:
        return 'TPC.OUT missing (dosbox failed?)'


def copy_tree(src, dst):
    for root, dirs, files in os.walk(src):
        rel = os.path.relpath(root, src)
        for f in files:
            if f.startswith('.'):
                continue
            d = os.path.join(dst, rel, f) if rel != '.' else os.path.join(dst, f)
            os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copy2(os.path.join(root, f), d)


def src_files():
    out = []
    for f in sorted(os.listdir(SRC)):
        p = os.path.join(SRC, f)
        if os.path.isfile(p) and not f.startswith('.'):
            out.append(f)
    return out


def owner_unit(fname):
    """U0728.PAS / U0728_A.INC / U0728.OBJ ... -> U0728"""
    b = os.path.basename(fname).upper()
    m = re.match(r'^([A-Z0-9]+?)(?:_[A-Z0-9_]*)?\.(PAS|INC|OBJ|ASM)$', b)
    return m.group(1) if m else b


def gen_keepall(work):
    """KEEPALL.INC: takes the address of every procedure that has a {#MARKER}
    so that the smart linker keeps it even while its callers are unfinished."""
    refs = []
    for f in sorted(os.listdir(work)):
        if not f.upper().endswith(('.PAS', '.INC')) or f.upper().startswith('BOMB'):
            continue
        txt = open(os.path.join(work, f), 'rb').read().decode('latin1').split('\n')
        for i, l in enumerate(txt):
            if re.search(r'\{#[A-Z0-9]+_[0-9A-F]{4}\}', l):
                for j in range(i, min(i + 4, len(txt))):
                    mm = re.match(r'\s*(?:procedure|function|constructor|destructor)\s+([A-Za-z_][\w.]*)', txt[j], re.I)
                    if mm:
                        refs.append(mm.group(1))
                        break
    # one typed constant and one variable per unit (data blocks are smart-linked per unit)
    for f in sorted(os.listdir(work)):
        if not f.upper().endswith('.PAS') or f.upper().startswith('BOMB'):
            continue
        txt = open(os.path.join(work, f), 'rb').read().decode('latin1').split('\n')
        sect = None
        got = set()
        for l in txt:
            ls = l.strip().lower()
            if ls == 'implementation':
                break
            if re.match(r'^(const|var|type|procedure|function|uses)\b', ls):
                sect = ls.split()[0]
                if sect in ('const', 'var') and len(ls.split()) == 1:
                    continue
            mm = re.match(r'^\s*(?:const\s+|var\s+)?([A-Za-z_]\w*)\s*:\s*[^=]*(=)?', l)
            if mm and sect in ('const', 'var') and sect not in got:
                if sect == 'const' and not mm.group(2):
                    continue
                refs.append(mm.group(1))
                got.add(sect)
    body = ['procedure KeepAll;', 'var KeepP: Pointer;', 'begin']
    body += ['  KeepP := @%s;' % r for r in refs]
    body += ['end;', '']
    open(os.path.join(work, 'KEEPALL.INC'), 'w').write('\n'.join(body))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', default=os.path.join(ROOT, 'build', 'work'))
    ap.add_argument('--mine', default='')
    ap.add_argument('--quiet', action='store_true')
    ap.add_argument('--no-lkg', action='store_true', help='do not fall back / update last-known-good')
    ap.add_argument('--final', action='store_true',
                    help='release build: no KEEPALL (dev builds reference every marked procedure so it gets linked)')
    a = ap.parse_args()
    mine = set(x.strip().upper() for x in a.mine.split(',') if x.strip())
    work = os.path.abspath(a.work)
    if os.path.exists(work):
        for f in os.listdir(work):
            p = os.path.join(work, f)
            if os.path.isfile(p):
                os.remove(p)
    os.makedirs(work, exist_ok=True)
    copy_tree(SRC, work)
    # binary blobs -> OBJ via Borland BINOBJ (list in src/BINOBJ.LST: file public)
    lst = os.path.join(work, 'BINOBJ.LST')
    if os.path.exists(lst):
        cmds = []
        for l in open(lst):
            p = l.split()
            if len(p) == 2:
                obj = os.path.splitext(p[0])[0] + '.OBJ'
                if not os.path.exists(os.path.join(work, obj)):
                    cmds.append('t:\\binobj.exe %s %s %s' % (p[0], obj, p[1]))
        if cmds:
            conf = os.path.join(work, '_dosbox.conf')
            body = CONF.format(work=work, tp=TP, args='/?').split('[autoexec]')[0]
            body += '[autoexec]\nmount c "%s"\nmount t "%s"\nc:\n%s\nexit\n' % (work, TP, '\n'.join(c + ' > NUL' for c in cmds))
            open(conf, 'w').write(body)
            env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
            subprocess.run(['timeout', '120', 'dosbox', '-conf', conf, '-exit'],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env)
    if not a.final:
        gen_keepall(work)
    replaced = set()
    for attempt in range(12):
        out = run_tpc(work, '/B /GD /Q %sBOMB.PAS' % ('' if a.final else '/DKEEPALL '))
        ok = os.path.exists(os.path.join(work, 'BOMB.EXE')) and 'Error' not in out
        if ok:
            break
        m = re.search(r'([A-Z0-9_]+\.(?:PAS|INC))\((\d+)\): (Error.*)', out.upper())
        if not m or a.no_lkg:
            break
        bad = m.group(1)
        unit = owner_unit(bad)
        if unit in mine or not mine:
            break
        # fall back to LKG versions of every file of that unit
        lk = [f for f in (os.listdir(LKG) if os.path.isdir(LKG) else []) if owner_unit(f) == unit]
        if not lk or unit in replaced:
            break
        for f in os.listdir(work):
            if owner_unit(f) == unit and f.upper().endswith(('.PAS', '.INC')):
                os.remove(os.path.join(work, f))
        for f in lk:
            shutil.copy2(os.path.join(LKG, f), os.path.join(work, f))
        replaced.add(unit)
        if not a.quiet:
            print('[build] %s fails to compile (%s); using last-known-good copy' % (unit, m.group(3).strip()))
    if not a.quiet or not ok:
        print(out.strip())
    if replaced:
        print('[build] units taken from last-known-good:', ', '.join(sorted(replaced)))
    if ok and not a.no_lkg:
        os.makedirs(LKG, exist_ok=True)
        lockf = open(os.path.join(LKG, '.lock'), 'w')
        fcntl.flock(lockf, fcntl.LOCK_EX)
        for f in os.listdir(work):
            if f.upper().endswith(('.PAS', '.INC', '.OBJ')) and owner_unit(f) not in replaced:
                shutil.copy2(os.path.join(work, f), os.path.join(LKG, f))
        fcntl.flock(lockf, fcntl.LOCK_UN)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
