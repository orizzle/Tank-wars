#!/usr/bin/env python3
"""Recreate toolchain/tp6/turbo.tpl from turbo.tpl.pristine so that its
System and Crt units match the (earlier) TP 6.0 runtime library that the
original BOMB.EXE was linked with.

usage: patch_tpl.py REF_EXE
  REF_EXE = a release build (build.py --final) of the decompiled sources made
            with the PRISTINE library (or with a previous patch; only units that
            are being patched must still be pristine in it).  It is used to find
            where each TPU code block was linked, so the same blocks can be
            located in orig/BOMB.EXE.

What gets patched (the TPU tables are rewritten accordingly):
  * System typed constant OvrEmsHandle  $FFFF -> $0000
  * every System / Crt code block whose bytes differ from the original:
    the block's bytes are replaced by the original's, keeping the TPU's own
    bytes at relocation fields.  If the size changes (Crt.Delay -2,
    System stack check -2), relocation positions after the changed region,
    references to offsets after it (intra-unit code refs, entry points) and
    the code-size fields are adjusted.
The resulting units differ from the pristine ones ONLY in those blocks; this
is checked by re-linking.
"""
import struct, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import exe, units as U

TPD = os.path.join(ROOT, 'toolchain', 'tp6')
TPUS = {'SYSTEM': 0x0000, 'CRT': 0x87C0}   # offsets of the TPUs inside TURBO.TPL
OVREMS = 0x67F2


def a16(x):
    return (x + 15) & ~15


class TPU:
    def __init__(self, data, off):
        self.d = data
        self.off = off
        t = off
        assert data[t:t + 4] == b'TPU9'
        self.hdr = list(struct.unpack('<32H', data[t + 8:t + 72]))
        h = self.hdr
        self.ent_tab, self.blk_tab = h[2], h[3]
        self.code_size, self.const_size, self.reloc_size = h[11], h[12], h[13]
        self.code_off = a16(h[10])
        self.const_off = a16(self.code_off + self.code_size)
        self.reloc_off = a16(self.const_off + self.const_size)
        self.end = a16(self.reloc_off + self.reloc_size)
        nb = (h[4] - self.blk_tab) // 8
        self.blocks = [list(struct.unpack('<4H', data[t + self.blk_tab + 8 * i:t + self.blk_tab + 8 * i + 8]))
                       for i in range(nb)]
        ne = (self.blk_tab - self.ent_tab) // 8
        self.entries = [list(struct.unpack('<4H', data[t + self.ent_tab + 8 * i:t + self.ent_tab + 8 * i + 8]))
                        for i in range(ne)]
        rel = [list(struct.unpack('<BBHHH', data[t + self.reloc_off + 8 * i:t + self.reloc_off + 8 * i + 8]))
               for i in range(self.reloc_size // 8)]
        # split relocations per code block (code block relocs come first, in block order)
        self.brel = []
        k = 0
        for b in self.blocks:
            n = b[2] // 8
            self.brel.append(rel[k:k + n])
            k += n
        self.other_rel = rel[k:]          # typed-const relocs etc.
        self.bstart = []
        p = 0
        for b in self.blocks:
            self.bstart.append(p)
            p += b[1]
        self.code = bytearray(data[t + self.code_off:t + self.code_off + self.code_size])

    def block(self, i):
        s = self.bstart[i]
        return bytes(self.code[s:s + self.blocks[i][1]])

    @staticmethod
    def fsize(e):
        return 4 if (e[1] & 0xF0) == 0x30 else 2

    def masked_block(self, i):
        b = bytearray(self.block(i))
        for e in self.brel[i]:
            for k in range(self.fsize(e)):
                if e[4] + k < len(b):
                    b[e[4] + k] = 0
        return bytes(b)


def masked(img, lin, n, relocset):
    b = bytearray(img[lin:lin + n])
    for k in range(n - 1):
        if lin + k in relocset:
            b[k] = b[k + 1] = 0
    return b


def locate_blocks(tpu, m, seg_lin, seg_len):
    """map TPU code blocks -> offsets in a linked segment (sequential, smart-linked subset)."""
    pos = 0
    where = {}
    for i in range(len(tpu.blocks)):
        n = tpu.blocks[i][1]
        if pos + n > seg_len:
            continue
        mb = tpu.masked_block(i)
        lb = masked(m.img, seg_lin + pos, n, m.reloc_set)
        # relocation fields were zeroed in mb; zero the same positions in lb
        for e in tpu.brel[i]:
            for k in range(tpu.fsize(e)):
                if e[4] + k < n:
                    lb[e[4] + k] = 0
        if bytes(lb) == mb:
            where[i] = pos
            pos += n
    return where, pos


def diff_region(old, new, mask=()):
    """common prefix/suffix; positions in mask (relocation fields of `old`) always match"""
    p = 0
    while p < min(len(old), len(new)) and (old[p] == new[p] or p in mask):
        p += 1
    s = 0
    while s < min(len(old), len(new)) - p and (old[-1 - s] == new[-1 - s] or (len(old) - 1 - s) in mask):
        s += 1
    return p, len(old) - s, len(new) - s


def patch_unit(tpl, name, ref, orig, ref_seg, orig_seg, ref_len, log):
    tpu = TPU(tpl, TPUS[name])
    where, used = locate_blocks(tpu, ref, ref_seg, ref_len)
    if abs(used - ref_len) > 15:
        raise SystemExit('%s: could not map all linked blocks (%X of %X)' % (name, used, ref_len))
    # walk linked blocks in order, tracking accumulated size delta
    delta_total = 0
    changes = {}
    order = sorted(where.items(), key=lambda kv: kv[1])
    for idx, (i, rpos) in enumerate(order):
        n = tpu.blocks[i][1]
        opos = rpos + delta_total
        nxt_rpos = order[idx + 1][1] if idx + 1 < len(order) else None
        rb = bytes(ref.img[ref_seg + rpos:ref_seg + rpos + n])
        # candidate original sizes: same, -2, +2, -4, +4
        best = None
        for dn in (0, -2, 2, -4, 4, -6, 6):
            on = n + dn
            ob = bytes(orig.img[orig_seg + opos:orig_seg + opos + on])
            # the next block must follow immediately in the original too
            if nxt_rpos is not None:
                nb_ = order[idx + 1][0]
                nn = tpu.blocks[nb_][1]
                r2 = ref.img[ref_seg + nxt_rpos:ref_seg + nxt_rpos + min(nn, 24)]
                o2 = orig.img[orig_seg + opos + on:orig_seg + opos + on + min(nn, 24)]
                score = sum(1 for x, y in zip(r2, o2) if x == y)
            else:
                mask = set()
                for e in tpu.brel[i]:
                    for k in range(TPU.fsize(e)):
                        mask.add(e[4] + k)
                a_, b_, c_ = diff_region(rb, ob, mask)
                score = -(b_ - a_)          # last block: smallest differing region wins
            if best is None or score > best[0]:
                best = (score, dn, ob)
        score, dn, ob = best
        if ob == rb:
            continue
        changes[i] = (rb, ob, dn)
        delta_total += dn
    for i, (rb, ob, dn) in changes.items():
        oldb = tpu.block(i)
        mask = set()
        for e in tpu.brel[i]:
            for k in range(TPU.fsize(e)):
                mask.add(e[4] + k)
        p0, r_old_end, r_new_end = diff_region(rb, ob, mask)
        if dn:
            # precise region: window [k, k+w) (old) / [k, k+w+dn) (new) minimising mismatches outside
            n_, D_ = len(rb), -dn
            pre = [0]
            for x in range(n_):
                pre.append(pre[-1] + (0 if (x in mask or x >= len(ob) or rb[x] == ob[x]) else 1))
            suf = [0] * (n_ + 1)
            for x in range(n_ - 1, -1, -1):
                y = x - D_
                suf[x] = suf[x + 1] + (0 if (x in mask or y < 0 or rb[x] == ob[y]) else 1)
            best_ = None
            for k in range(n_):
                for w in range(max(D_, 1), min(0x60, n_ - k) + 1):
                    c = pre[k] + suf[k + w] + w * 0.001
                    if best_ is None or c < best_[0]:
                        best_ = (c, k, w)
            c, k, w = best_
            p0, r_old_end, r_new_end = k, k + w, k + w - D_
            log.append('   precise region %X-%X, %d displacement bytes differ outside it' % (k, k + w, int(c)))
        log.append('%s block %d: region %X-%X -> %X bytes (size %+d)' % (name, i, p0, r_old_end, r_new_end - p0, dn))
        # new block bytes = original's, with relocation fields restored from the TPU
        nbk = bytearray(ob)
        D = -dn                        # bytes removed
        newrel = []
        for e in tpu.brel[i]:
            e = list(e)
            op = e[4]
            if e[4] >= r_old_end:
                e[4] -= D
            elif e[4] + TPU.fsize(e) > p0:
                # relocation inside the changed region: find the same instruction in the original
                fs = TPU.fsize(e)
                cands = [q for q in range(max(0, p0 - 2), min(len(ob) - fs, r_new_end + 2) + 1)
                         if ob[q:q + fs] == rb[op:op + fs] and ob[q - 1] == rb[op - 1]]
                if not cands:   # e.g. same operand, different register (modrm differs)
                    cands = [q for q in range(max(0, p0 - 2), min(len(ob) - fs, r_new_end + 2) + 1)
                             if ob[q:q + fs] == rb[op:op + fs]]
                if not cands:
                    raise SystemExit('%s block %d: relocation at %X not found in new region' % (name, i, op))
                q = min(cands, key=lambda x: abs(x - op))
                if q != op:
                    log.append('   relocation moved %X -> %X' % (op, q))
                e[4] = q
            for k in range(TPU.fsize(e)):
                nbk[e[4] + k] = oldb[op + k]
            newrel.append(e)
        tpu.brel[i] = newrel
        s = tpu.bstart[i]
        tpu.code[s:s + len(oldb)] = nbk
        if D:
            # shift following blocks' starts
            for j in range(i + 1, len(tpu.blocks)):
                tpu.bstart[j] -= D
            tpu.blocks[i][1] -= D
            # references to offsets after the region in this block
            for bl in tpu.brel + [tpu.other_rel]:
                for e in bl:
                    if e[0] == 0 and (e[1] & 0xF0) in (0x50, 0x10) and e[2] == i * 8 and e[3] >= r_old_end:
                        e[3] -= D
            for e in tpu.entries:
                if e[2] == i * 8 and e[3] >= r_old_end:
                    e[3] -= D
            tpu.code_size -= D
    # serialise
    t = tpu.off
    hdr = tpu.hdr
    hdr[11] = tpu.code_size
    assert a16(tpu.code_off + tpu.code_size) == tpu.const_off, 'code shrink crosses alignment'
    struct.pack_into('<32H', tpl, t + 8, *hdr)
    for k, b in enumerate(tpu.blocks):
        struct.pack_into('<4H', tpl, t + tpu.blk_tab + 8 * k, *b)
    for k, e in enumerate(tpu.entries):
        struct.pack_into('<4H', tpl, t + tpu.ent_tab + 8 * k, *e)
    code = bytes(tpu.code[:tpu.code_size])
    tpl[t + tpu.code_off:t + tpu.const_off] = code + b'\x00' * (tpu.const_off - tpu.code_off - len(code))
    allrel = [e for bl in tpu.brel for e in bl] + tpu.other_rel
    for k, e in enumerate(allrel):
        struct.pack_into('<BBHHH', tpl, t + tpu.reloc_off + 8 * k, *e)
    return len(changes)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    ref = exe.MZ(sys.argv[1])
    mp = exe.load_map(os.path.splitext(sys.argv[1])[0] + '.MAP')
    rseg = {n: (s, e + 1 - s) for s, e, n, c in mp['segments']}
    orig = exe.MZ(os.path.join(ROOT, 'orig', 'BOMB.EXE'))
    oseg = {n: a for n, s, a, e in U.unit_bounds(0)}
    tpl = bytearray(open(os.path.join(TPD, 'turbo.tpl.pristine'), 'rb').read())
    assert tpl[OVREMS:OVREMS + 2] == b'\xff\xff'
    tpl[OVREMS:OVREMS + 2] = b'\x00\x00'
    log = []
    for name in ('SYSTEM', 'CRT'):
        s, ln = rseg[name]
        patch_unit(tpl, name, ref, orig, s, oseg[name], ln, log)
    open(os.path.join(TPD, 'turbo.tpl'), 'wb').write(tpl)
    print('\n'.join(log))
    print('turbo.tpl written (OvrEmsHandle + %d code blocks patched)' % len(log))


if __name__ == '__main__':
    main()
