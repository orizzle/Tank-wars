#!/usr/bin/env python3
"""Recursive-descent disassembler for TP6 EXEs with relocation awareness.

usage: dis.py [EXE] [--unit NAME] [--out DIR]
Writes one listing per code segment (unit) into DIR (default build/dis).
"""
import sys, os, struct, argparse, json, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import exe, units as U
from capstone import Cs, CS_ARCH_X86, CS_MODE_16
from capstone import x86 as X

cs = Cs(CS_ARCH_X86, CS_MODE_16)
cs.detail = True

EMU_SEG = {0: 'es', 1: 'cs', 2: 'ss', 3: 'ds'}
SEGPFX = {0: 0x26, 1: 0x2E, 2: 0x36, 3: 0x3E}


def load_rtl_names():
    p = os.path.join(U.__file__.rsplit('/', 1)[0], 'rtl_names.json')
    if os.path.exists(p):
        return {k: v for k, v in json.load(open(p)).items()}
    return {}


class Disasm:
    def __init__(self, m, unit_table=None, dseg=None):
        self.m = m
        self.img = m.img
        self.units = unit_table or U.UNITS
        self.dseg = dseg if dseg is not None else U.DSEG
        self.ubounds = []
        for i, (s, n) in enumerate(self.units):
            if n in ('DATA', 'STACK'):
                break
            self.ubounds.append((n, s, s * 16, self.units[i + 1][0] * 16))
        self.para2unit = {s: n for s, n in self.units}
        self.rtl = load_rtl_names()

    # ---------------- decoding ----------------
    def decode(self, lin, base=0):
        """returns (length, mnemonic, op_str, insn_or_None, emu)"""
        img = self.img
        a = lin - base
        b0 = img[lin]
        if b0 == 0xCD and lin + 1 < len(img):
            n = img[lin + 1]
            if 0x34 <= n <= 0x3B:
                buf = bytes([0xD8 + n - 0x34]) + img[lin + 2:lin + 12]
                for i in cs.disasm(buf, a + 1, 1):
                    return (1 + i.size, i.mnemonic, i.op_str, i, 'emu%02x' % n)
                return (2, 'int', hex(n), None, None)
            if n == 0x3C:
                bb = img[lin + 2]
                seg = bb >> 6
                buf = bytes([SEGPFX[seg], bb | 0xC0]) + img[lin + 3:lin + 12]
                for i in cs.disasm(buf, a + 1, 1):
                    return (1 + i.size, i.mnemonic, i.op_str, i, 'emu3c')
                return (2, 'int', '0x3c', None, None)
            if n == 0x3D:
                return (2, 'fwait', '', None, 'emu3d')
        for i in cs.disasm(img[lin:lin + 16], a, 1):
            return (i.size, i.mnemonic, i.op_str, i, None)
        return (1, 'db', hex(b0), None, None)

    def unit_at(self, lin):
        for n, s, a, e in self.ubounds:
            if a <= lin < e:
                return n, s, a, e
        return None

    # ---------------- discovery ----------------
    def far_targets(self):
        """far call targets from 9A instructions w/ relocated seg words, plus
        far pointers stored in data (DS) / code."""
        m = self.m
        ent = {}  # lin -> set(kind)
        dseg_lin = self.dseg * 16
        for site in m.reloc_lin:
            seg = m.w(site)
            off = m.w(site - 2)
            if seg not in self.para2unit:
                continue
            tgt = seg * 16 + off
            if site >= 3 and self.img[site - 3] == 0x9A and site < dseg_lin:
                ent.setdefault(tgt, set()).add('farcall')
            elif site >= dseg_lin:
                ent.setdefault(tgt, set()).add('dsptr')
        return ent

    def run(self):
        img = self.img
        m = self.m
        far = self.far_targets()
        self.code = {}     # lin -> (len, mn, ops, emu)
        self.procs = {}    # lin -> kinds
        self.labels = {}   # lin -> kind (jump targets)
        self.xrefs = {}    # lin -> set(src lin)
        self.dsrefs = {}   # ds off -> set(src lin)
        self.owner = {}    # insn lin -> proc entry lin
        self.code_end = {}  # proc entry lin -> end of its code
        self.dsidx = {}    # ds off used as base of indexed access
        self.dsptr = {}    # ds off loaded as pointer (mov di,imm; push ds)
        self.dataptrs = {}  # lin -> set(src)  (pointers into code segs, maybe data)
        work = []
        for t, k in far.items():
            u = self.unit_at(t)
            if not u or u[0] in U.LIB:
                continue
            if 'farcall' in k or self.looks_like_proc(t, 'dsptr' if 'dsptr' in k else None):
                self.procs.setdefault(t, set()).update(k)
                work.append(t)
            else:
                self.dataptrs.setdefault(t, set()).update(k)
        entry = m.cs * 16 + m.hdr['ip']
        self.procs.setdefault(entry, set()).add('entry')
        work.append(entry)
        # code-embedded far pointers: mov reg,imm with relocated imm
        self.pending_ptr = []
        self.drain(work)
        # second pass: Pascal prologues sitting in unexplored gaps
        changed = True
        while changed:
            changed = False
            for n, s, ua, ue in self.ubounds:
                if n in U.LIB:
                    continue
                lin = ua
                while lin < ue - 3:
                    if lin in self.code:
                        lin += self.code[lin][0]
                        continue
                    if self.img[lin:lin + 3] in (b'\x55\x89\xe5', b'\x55\x8b\xec') and self.plausible_after(lin, ua):
                        self.procs.setdefault(lin, set()).add('gap')
                        self.drain([lin])
                        changed = True
                    lin += 1
        # TP 'interrupt' procedures: register pushes precede the bp frame
        INTPRO = b'\x50\x53\x51\x52\x56\x57\x1e\x06'
        for p in list(self.procs):
            if self.img[p - 8:p] == INTPRO and (p - 8) not in self.code:
                k = self.procs.pop(p)
                self.procs[p - 8] = k | {'interrupt'}
                for l2 in range(p - 8, p):
                    pass
                # attribute the pushes to the proc
                self.code[p - 8] = (8, 'push', 'ax,bx,cx,dx,si,di,ds,es', None)
                self.owner[p - 8] = p - 8
                self.code_end[p - 8] = self.code_end.pop(p, p)
                for l2, o in list(self.owner.items()):
                    if o == p:
                        self.owner[l2] = p - 8
        return self

    def plausible_after(self, lin, ua):
        # previous byte should be end of code (ret) or data; accept if previous code insn is a return
        p = lin - 1
        while p >= ua and p not in self.code:
            p -= 1
        return True

    def drain(self, work):
        while work:
            self.trace(work.pop(), work)
            while self.pending_ptr:
                t = self.pending_ptr.pop()
                u = self.unit_at(t)
                if not u or u[0] in U.LIB:
                    continue
                if t in self.code:
                    self.procs.setdefault(t, set()).add('codeptr')
                    continue
                if self.looks_like_proc(t, 'codeptr'):
                    self.procs.setdefault(t, set()).add('codeptr')
                    work.append(t)
                else:
                    self.dataptrs.setdefault(t, set()).add('codeptr')

    def looks_like_proc(self, t, kind=None):
        b = self.img[t:t + 3]
        if kind in ('codeptr', 'dsptr'):
            return b[:2].lower() != b'pk'
        return b[:1] == b'\x55' or b[:2] in (b'\xc8\x00',) or b[:1] == b'\xc8'

    def trace(self, start, work):
        img = self.img
        u = self.unit_at(start)
        if not u:
            return
        uname, upara, ua, ue = u
        owner = start
        stack = [start]
        while stack:
            lin = stack.pop()
            while ua <= lin < ue and lin not in self.code:
                ln, mn, ops, ins, emu = self.decode(lin, ua)
                self.code[lin] = (ln, mn, ops, emu)
                self.owner[lin] = owner
                if lin + ln > self.code_end.get(owner, 0):
                    self.code_end[owner] = lin + ln
                nxt = lin + ln
                # relocated immediates inside insn -> pointer detection
                for r in range(lin + 1, nxt - 1):
                    if r in self.m.reloc_set and mn != 'lcall':
                        segv = self.m.w(r)
                        off = self.find_prev_imm(lin, ua)
                        if off is not None and segv in self.para2unit:
                            self.pending_ptr.append(segv * 16 + off)
                if ins is not None and emu is None:
                    self.note_mem(ins, lin, ua)
                if mn in ('ret', 'retf', 'iret', 'ljmp'):
                    break
                if mn == 'jmp':
                    t = self.imm_target(ins, ua)
                    if t is not None:
                        self.labels.setdefault(t, 'jmp')
                        self.xrefs.setdefault(t, set()).add(lin)
                        lin = t
                        continue
                    break  # indirect
                if mn.startswith('j') or mn in ('loop', 'loope', 'loopne', 'jcxz'):
                    t = self.imm_target(ins, ua)
                    if t is not None:
                        self.labels.setdefault(t, 'jcc')
                        self.xrefs.setdefault(t, set()).add(lin)
                        stack.append(t)
                elif mn == 'call':
                    t = self.imm_target(ins, ua)
                    if t is not None:
                        self.procs.setdefault(t, set()).add('near' if img[lin - 1] != 0x0E else 'pushcs')
                        self.xrefs.setdefault(t, set()).add(lin)
                        work.append(t)
                lin = nxt

    def find_prev_imm(self, lin, ua):
        # scan back up to 12 bytes for "mov r16, imm16" / "mov di,imm" pattern
        for back in range(1, 13):
            p = lin - back
            if p < ua or p not in self.code:
                continue
            ln, mn, ops, emu = self.code[p]
            if mn == 'mov' and re.match(r'^(ax|bx|cx|dx|si|di), 0x[0-9a-f]+$', ops):
                if p + ln + 0 <= lin:
                    return int(ops.split(',')[1], 16)
            if mn == 'mov' and re.match(r'^word ptr \[[^\]]*\], 0x[0-9a-f]+$', ops):
                return int(ops.rsplit(',', 1)[1], 16)
        return None

    def imm_target(self, ins, ua):
        if ins is None:
            return None
        if len(ins.operands) == 1 and ins.operands[0].type == X.X86_OP_IMM:
            return ua + (ins.operands[0].imm & 0xFFFF)
        return None

    def note_mem(self, ins, lin, ua):
        for op in ins.operands:
            if op.type == X.X86_OP_MEM:
                mm = op.mem
                if mm.segment not in (0, X.X86_REG_DS):
                    continue
                if mm.base in (X.X86_REG_BP, X.X86_REG_SP):
                    continue
                if mm.base == 0 and mm.index == 0:
                    self.dsrefs.setdefault(mm.disp & 0xFFFF, set()).add(lin)
                elif mm.disp & 0xFFFF >= 0x100:
                    self.dsidx.setdefault(mm.disp & 0xFFFF, set()).add(lin)
            elif op.type == X.X86_OP_IMM and ins.mnemonic == 'mov' and (op.imm & 0xFFFF) >= 0x2:
                nb = self.img[lin + ins.size:lin + ins.size + 1]
                if nb == b'\x1e':  # push ds follows -> DS pointer
                    self.dsptr.setdefault(op.imm & 0xFFFF, set()).add(lin)

    # ---------------- output ----------------
    def fmt_ops(self, lin, ln, mn, ops, emu, ua):
        img = self.img
        ann = []
        if mn == 'lcall' and img[lin] == 0x9A:
            off = struct.unpack('<H', img[lin + 1:lin + 3])[0]
            seg = struct.unpack('<H', img[lin + 3:lin + 5])[0]
            un = self.para2unit.get(seg, '?%04x' % seg)
            name = '%s:%04X' % (un, off)
            if un == 'SYSTEM' or un in U.LIB:
                rn = self.rtl.get(name)
                if rn:
                    name += ' {%s}' % rn
            return 'call far ' + name
        s = (mn + ' ' + ops).strip()
        if emu:
            s = s.replace('wait', '').strip()
            s = 'F> ' + s
        for r in range(lin + 1, lin + ln - 1):
            if r in self.m.reloc_set:
                segv = self.m.w(r)
                ann.append('SEG %s' % self.para2unit.get(segv, '?%04x' % segv))
        if mn in ('call', 'jmp') or mn.startswith('j') or mn.startswith('loop'):
            m = re.match(r'^0x([0-9a-f]+)$', ops)
            if m:
                s = '%s L%04X' % (mn, int(m.group(1), 16))
        return s + (('    ; ' + ', '.join(ann)) if ann else '')

    def listing(self, uname):
        n, s, ua, ue = [b for b in self.ubounds if b[0] == uname][0]
        img = self.img
        out = []
        out.append('; unit %s  seg %04X  size %04X' % (n, s, ue - ua))
        lin = ua
        while lin < ue:
            if lin in self.code:
                if lin in self.procs:
                    kinds = ','.join(sorted(self.procs[lin]))
                    out.append('')
                    out.append(';==== proc %s_%04X  [%s]' % (n, lin - ua, kinds))
                elif lin in self.labels:
                    out.append('L%04X:' % (lin - ua))
                ln, mn, ops, emu = self.code[lin]
                hx = img[lin:lin + ln].hex()
                out.append('  %04X  %-14s %s' % (lin - ua, hx[:14], self.fmt_ops(lin, ln, mn, ops, emu, ua)))
                lin += ln
            else:
                # data run until next code byte
                e = lin
                while e < ue and e not in self.code:
                    e += 1
                chunk = img[lin:e]
                if lin in self.dataptrs:
                    out.append(';---- data ref [%s]' % ','.join(sorted(self.dataptrs[lin])))
                if chunk.strip(b'\x00') == b'' and e == ue:
                    out.append('  %04X  pad %d' % (lin - ua, len(chunk)))
                else:
                    for line in self.dumpdata(lin - ua, chunk):
                        out.append(line)
                lin = e
        return '\n'.join(out) + '\n'

    def dumpdata(self, off, chunk):
        res = []
        i = 0
        while i < len(chunk):
            # pascal string?
            L = chunk[i]
            if 1 <= L and i + 1 + L <= len(chunk) and all(32 <= c < 127 for c in chunk[i + 1:i + 1 + L]) and L >= 2:
                res.append('  %04X  str %r' % (off + i, chunk[i + 1:i + 1 + L].decode('latin1')))
                i += 1 + L
                continue
            seg = chunk[i:i + 16]
            res.append('  %04X  db %s  |%s|' % (off + i, seg.hex(' '), ''.join(chr(c) if 32 <= c < 127 else '.' for c in seg)))
            i += 16
        return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('exe', nargs='?', default=U.ORIG)
    ap.add_argument('--out', default=os.path.join(exe.ROOT, 'build', 'dis' if U.TARGET == 'BOMB' else 'dis_' + U.TARGET.lower()))
    ap.add_argument('--unit')
    a = ap.parse_args()
    m = exe.MZ(a.exe)
    d = Disasm(m).run()
    os.makedirs(a.out, exist_ok=True)
    for n, s, ua, ue in d.ubounds:
        if n in U.LIB:
            continue
        if a.unit and n != a.unit:
            continue
        open(os.path.join(a.out, n + '.lst'), 'w').write(d.listing(n))
    # proc table
    tab = []
    for p in sorted(d.procs):
        u = d.unit_at(p)
        if not u:
            continue
        tab.append(dict(unit=u[0], off=p - u[2], kinds=sorted(d.procs[p])))
    json.dump(tab, open(os.path.join(a.out, 'procs.json'), 'w'), indent=0)
    # coverage
    for n, s, ua, ue in d.ubounds:
        if n in U.LIB:
            continue
        cov = sum(d.code[l][0] for l in d.code if ua <= l < ue)
        np_ = sum(1 for p in d.procs if ua <= p < ue)
        print('%-8s size %5X code %5X (%3d%%) procs %d' % (n, ue - ua, cov, 100 * cov // max(1, ue - ua), np_))


if __name__ == '__main__':
    main()
