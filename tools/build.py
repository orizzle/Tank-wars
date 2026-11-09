#!/usr/bin/env python3
"""Build the Pascal sources with Turbo Pascal 6.0 (TPC.EXE under headless DOSBox).

usage: build.py [--work DIR] [--mine U0728,U0E9B] [--quiet]

* copies src/ into the work dir (default build/work) and runs
  TPC /B /GD BOMB.PAS there; result: WORK/BOMB.EXE, WORK/BOMB.MAP
* if compilation fails in a file that is NOT listed in --mine, the build is
  retried with ALL other units taken from build/lkg_full/ (a consistent
  snapshot of the last successful build by anyone) plus your own files.
* after a successful build, its sources are stored as the new snapshot.
Exit status 0 on success; compiler output is printed.
"""
import sys, os, shutil, subprocess, argparse, re, fcntl, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import units as U

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
    for f in ('TPC.OUT', U.MAIN + '.EXE'):
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


USER_UNITS = set(n for _, n in U.UNITS if n not in U.LIB and n not in ('DATA', 'STACK'))


def gen_keepall(work):
    """KEEPALL.INC: takes the address of every procedure that has a {#MARKER}
    so that the smart linker keeps it even while its callers are unfinished."""
    refs = []
    for f in sorted(os.listdir(work)):
        if not f.upper().endswith(('.PAS', '.INC')) or owner_unit(f) not in USER_UNITS or f.upper() == 'KEEPALL.INC':
            continue
        txt = open(os.path.join(work, f), 'rb').read().decode('latin1').split('\n')
        HDR = re.compile(r'^\s*(?:procedure|function|constructor|destructor)\s+([A-Za-z_][\w.]*)', re.I)
        for i, l in enumerate(txt):
            if not re.search(r'\{#[A-Z0-9]+_[0-9A-F]{4}\}', l):
                continue
            if HDR.match(re.sub(r'\{#[^}]*\}', '', l)):
                continue        # marker on the header line = nested procedure (cannot take its address)
            name = None
            for j in range(i + 1, min(i + 4, len(txt))):
                mm = HDR.match(txt[j])
                if mm:
                    name = mm.group(1)
                    break
                if re.match(r'^\s*begin\b', txt[j], re.I):
                    break
            if name is None:
                # marker placed before the 'begin' of a procedure with nested procedures:
                # use the closest preceding top-level header (column 0, no marker on it)
                for j in range(i - 1, -1, -1):
                    if re.match(r'^(procedure|function|constructor|destructor)\s', txt[j], re.I) and '{#' not in txt[j]:
                        name = HDR.match(txt[j]).group(1)
                        break
                    if re.match(r'^\s*(implementation|interface)\s*$', txt[j], re.I):
                        break
            if name and '.' not in name or (name and re.match(r'^T\w*\.\w+$', name)):
                refs.append(name)
    # one typed constant and one variable per unit (data blocks are smart-linked per unit)
    for f in sorted(os.listdir(work)):
        if not f.upper().endswith('.PAS') or owner_unit(f) == U.MAIN or owner_unit(f) not in USER_UNITS:
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
    for sd in U.SRCDIRS:
        if os.path.isdir(os.path.join(ROOT, sd)):
            copy_tree(os.path.join(ROOT, sd), work)
    # hand-written external code: NAME.ASM -> NAME.BIN (NASM, flat binary, no fixups)
    for f in os.listdir(work):
        if f.upper().endswith('.ASM'):
            b = os.path.splitext(f)[0] + '.BIN'
            r = subprocess.run(['nasm', '-f', 'bin', '-o', os.path.join(work, b), os.path.join(work, f)],
                               capture_output=True, text=True)
            if r.returncode:
                print(r.stderr)
                sys.exit(1)
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
    flags = '/B /GD /Q %s%s.PAS' % ('' if a.final else '/DKEEPALL ', U.MAIN)
    SNAP = os.path.join(ROOT, 'build', 'lkg_full' + ('' if U.TARGET == 'BOMB' else '_' + U.TARGET))
    used_snapshot = False
    out = run_tpc(work, flags)
    ok = os.path.exists(os.path.join(work, U.MAIN + '.EXE')) and 'Error' not in out
    if not ok and not a.no_lkg and mine and os.path.isdir(SNAP):
        m = re.search(r'([A-Z0-9_]+\.(?:PAS|INC))\((\d+)\): (ERROR.*)', out.upper())
        if m and owner_unit(m.group(1)) not in mine:
            if not a.quiet:
                print('[build] %s fails to compile (%s); retrying with the last-known-good snapshot '
                      'for all units except yours' % (owner_unit(m.group(1)), m.group(3).strip()))
            # rebuild work: snapshot + my files from src
            for f in os.listdir(work):
                p_ = os.path.join(work, f)
                if os.path.isfile(p_) and f.upper().endswith(('.PAS', '.INC')):
                    os.remove(p_)
            for f in os.listdir(SNAP):
                if owner_unit(f) not in mine:
                    shutil.copy2(os.path.join(SNAP, f), os.path.join(work, f))
            for sd in U.SRCDIRS:
                sdp = os.path.join(ROOT, sd)
                if not os.path.isdir(sdp):
                    continue
                for f in os.listdir(sdp):
                    if owner_unit(f) in mine or not f.upper().endswith(('.PAS', '.INC')):
                        if os.path.isfile(os.path.join(sdp, f)):
                            shutil.copy2(os.path.join(sdp, f), os.path.join(work, f))
            if not a.final:
                gen_keepall(work)
            out = run_tpc(work, flags)
            ok = os.path.exists(os.path.join(work, U.MAIN + '.EXE')) and 'Error' not in out
            used_snapshot = True
    if not a.quiet or not ok:
        print(out.strip())
    if used_snapshot:
        print('[build] NOTE: other units were taken from build/lkg_full (snapshot of the last successful build)')
    if ok and not a.no_lkg:
        # save a consistent snapshot of every source file of this successful build
        tmp = SNAP + '.tmp%d' % os.getpid()
        os.makedirs(tmp, exist_ok=True)
        for f in os.listdir(work):
            if f.upper().endswith(('.PAS', '.INC')) and f.upper() != 'KEEPALL.INC':
                shutil.copy2(os.path.join(work, f), os.path.join(tmp, f))
        lockf = open(os.path.join(ROOT, 'build', '.lkg.lock'), 'w')
        fcntl.flock(lockf, fcntl.LOCK_EX)
        old = SNAP + '.old%d' % os.getpid()
        if os.path.isdir(SNAP):
            os.rename(SNAP, old)
        os.rename(tmp, SNAP)
        if os.path.isdir(old):
            shutil.rmtree(old, ignore_errors=True)
        fcntl.flock(lockf, fcntl.LOCK_UN)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
