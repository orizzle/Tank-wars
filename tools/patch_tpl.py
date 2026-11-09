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


def _insns(buf, lo, hi):
    from capstone import Cs, CS_ARCH_X86, CS_MODE_16
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    out = []
    pos = lo
    while pos < hi:
        got = list(md.disasm(bytes(buf[pos:pos + 16]), pos, 1))
        if not got:
            out.append((pos, 1, 'db'))
            pos += 1
            continue
        ins = got[0]
        out.append((pos, ins.size, ins.mnemonic + ' ' + ins.op_str))
        pos += ins.size
    return out


def align_relocs(rb, ob, p0, r_old_end, r_new_end, rels, log):
    """map relocation positions inside the changed region [p0, r_old_end) of the
    old block to positions in the new block by aligning instruction sequences"""
    import difflib, re as _re
    # start decoding a little before the region at an instruction boundary: decode from 0
    oi = _insns(rb, 0, len(rb))
    ni = _insns(ob, 0, len(ob))
    norm = lambda t: _re.sub(r'0x[0-9a-f]+', '#', t)
    sm = difflib.SequenceMatcher(None, [norm(x[2]) for x in oi], [norm(x[2]) for x in ni], autojunk=False)
    rmap = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'replace' and i2 - i1 != j2 - j1:
            usedj = set()
            for (pa, la, ta) in oi[i1:i2]:
                for e in rels:
                    if pa <= e[4] < pa + la:
                        fs = TPU.fsize(e)
                        rel_ = e[4] - pa
                        for jj in range(j1, j2):
                            pb, lb, tb = ni[jj]
                            if jj in usedj or lb != la:
                                continue
                            if ob[pb + rel_:pb + rel_ + fs] == rb[e[4]:e[4] + fs]:
                                rmap[e[4]] = pb + rel_
                                usedj.add(jj)
                                break
            continue
        if tag == 'equal' or (tag == 'replace' and i2 - i1 == j2 - j1):
            for k in range(i2 - i1):
                (pa, la, ta), (pb, lb, tb) = oi[i1 + k], ni[j1 + k]
                if la != lb and tag == 'replace':
                    continue
                for e in rels:
                    if pa <= e[4] < pa + la:
                        rmap[e[4]] = pb + (e[4] - pa)
    return rmap


def _para_name_ref(para):
    for sb, se, nm in REF_SEGS:
        if sb == para * 16:
            return nm
    return None


def _para_name_orig(para):
    for p_, nm in U.UNITS:
        if p_ == para:
            return nm
    return None


def match_far(rels, rb, ob, ref, orig, rbase, obase, p0, r_old_end, r_new_end, log):
    """far relocations inside the changed region: match by target (unit, offset)"""
    R = []
    for e in rels:
        if TPU.fsize(e) == 4 and p0 - 4 < e[4] < r_old_end:
            lin = rbase + e[4] + 2
            if lin in ref.reloc_set:
                un_ = _para_name_ref(ref.w(lin))
            R.append((e[4], un_, ('E', e[2] // 8) if un_ in ENTRY_MAPS else ref.w(lin - 2), rb[e[4] - 1]))
    S = []
    for qq in range(max(1, p0 - 4), r_new_end):
        lin = obase + qq + 2
        if lin in orig.reloc_set:
            un_ = _para_name_orig(orig.w(lin))
            off_ = orig.w(lin - 2)
            if un_ in ENTRY_MAPS:
                off_ = ('E', ENTRY_MAPS[un_].get(off_, -1))
            S.append((qq, un_, off_, ob[qq - 1]))
    out = {}
    usedS = set()
    for r in R:                      # exact (unit, offset, opcode)
        for s_ in S:
            if s_[0] not in usedS and s_[1:] == r[1:]:
                out[r[0]] = s_[0]
                usedS.add(s_[0])
                break
    for r in R:                      # same unit + opcode, in order
        if r[0] in out:
            continue
        for s_ in S:
            if s_[0] not in usedS and s_[1] == r[1] and s_[3] == r[3]:
                out[r[0]] = s_[0]
                usedS.add(s_[0])
                break
    left_s = [s_ for s_ in S if s_[0] not in usedS]
    left_r = [r for r in R if r[0] not in out]
    # same opcode, different target: the old library called another routine
    for r in list(left_r):
        for s_ in left_s:
            if s_[3] == r[3]:
                out[r[0]] = s_[0]
                RETARGET.append((r[0], s_[0], s_[1], s_[2]))
                log.append('   far call at %X re-targeted: %s:%s -> %s:%s (original routine)' % (r[0], r[1], r[2], s_[1], s_[2]))
                left_s.remove(s_)
                left_r.remove(r)
                break
    for r in left_r:                 # call removed in the original version
        out[r[0]] = None
        log.append('   far relocation at %X (%s:%s) not in the original: dropped' % (r[0], r[1], r[2]))
    if left_s:
        raise SystemExit('far relocations in the original without counterpart: %s' % left_s)
    return out


def check_far(e, op, q, rb, ob, ref, orig, ref_seg, orig_seg, p0, r_new_end, used, log):
    """a far pointer/call relocation must land on a relocated segment word in the
    original that points into the same unit; otherwise look for the right one"""
    rlin = ref_seg + op + 2
    rname = _para_name_ref(ref.w(rlin)) if rlin in ref.reloc_set else None
    def ok(qq):
        ol = orig_seg + qq + 2
        return ol in orig.reloc_set and _para_name_orig(orig.w(ol)) == rname and qq not in used
    if rname is None or ok(q):
        return q
    cands = [qq for qq in range(max(1, p0 - 2), r_new_end + 2) if ok(qq) and ob[qq - 1] == rb[op - 1]]
    if not cands:
        log.append('   far relocation at %X (to %s): no matching site in the original' % (op, rname))
        return q
    nq = min(cands, key=lambda x: abs(x - q))
    log.append('   far relocation at %X (to %s): re-targeted %X -> %X' % (op, rname, q, nq))
    return nq


def patch_unit(tpl, name, ref, orig, ref_seg, orig_seg, ref_len, log, off=None, relayout=False):
    tpu = TPU(tpl, TPUS[name] if off is None else off)
    where, used = locate_blocks(tpu, ref, ref_seg, ref_len)
    if abs(used - ref_len) > 15:
        raise SystemExit('%s: could not map all linked blocks (%X of %X)' % (name, used, ref_len))
    # ---- align the linked blocks with the original segment
    order = sorted(where.items(), key=lambda kv: kv[1])
    seg_end = ref_len
    # original segment length (code part): next unit start - padding
    ocands = []
    for i, rpos in order:
        n = tpu.blocks[i][1]
        L_ = min(n, 24)
        pat = bytes(tpu.masked_block(i)[:L_])
        mask = set(k for e in tpu.brel[i] for k in range(e[4], e[4] + TPU.fsize(e)) if k < L_)
        cands = []
        lo, hi = max(0, rpos - 0x800), rpos + 0x800
        for q in range(lo, hi):
            ob2 = orig.img[orig_seg + q:orig_seg + q + L_]
            if len(ob2) < L_:
                break
            mism = 0
            for k in range(L_):
                if k in mask or (orig_seg + q + k) in orig.reloc_set or (orig_seg + q + k - 1) in orig.reloc_set:
                    continue
                if ob2[k] != pat[k]:
                    mism += 1
                    if mism > 3:
                        break
            if mism <= 3:
                cands.append((q, mism))
        ocands.append((i, rpos, n, cands))
    # anchors: far pointers/calls into this unit at identical sites (same segment
    # name + offset) in the reference build and the original
    rpara, opara = ref_seg >> 4, orig_seg >> 4
    anchors = {}
    rsegs = sorted(REF_SEGS) if REF_SEGS else []
    for site in ref.reloc_lin:
        if ref.w(site) != rpara:
            continue
        loc = None
        for (sb, se, nm) in rsegs:
            if sb <= site < se:
                loc = (nm, site - sb)
                break
        if not loc or loc[0] not in ORIG_SEGS:
            continue
        osite = ORIG_SEGS[loc[0]] + loc[1]
        if osite in orig.reloc_set and orig.w(osite) == opara:
            anchors.setdefault(ref.w(site - 2), set()).add(orig.w(osite - 2))
    for k, (i, rpos, n, cands) in enumerate(ocands):
        if rpos in anchors and len(anchors[rpos]) == 1:
            q = next(iter(anchors[rpos]))
            cands[:] = [c for c in cands if c[0] != q] + [(q, -3)]     # strong preference
    # DP: choose increasing positions; maximise matched blocks, then minimise mismatches/drift
    best = {}            # index in order -> (score, prevstate)
    states = []          # (k, q, score, prev)
    import math
    for k, (i, rpos, n, cands) in enumerate(ocands):
        for q, mism in cands:
            sc = (1.0 - mism * 0.2)
            bestprev = (0.0, None)
            for st_idx in range(len(states)):
                k2, q2, s2, _ = states[st_idx]
                if k2 >= k or q2 >= q:
                    continue
                n2 = ocands[k2][2]
                tot = s2 + (0.5 if q == q2 + n2 else 0.0) - abs(q - (q2 + n2)) * 1e-5
                if bestprev[1] is None or tot > bestprev[0]:
                    bestprev = (tot, st_idx)
            states.append((k, q, bestprev[0] + sc - (abs(q - rpos) * 1e-7 if bestprev[1] is None else 0), bestprev[1]))
    if not states:
        raise SystemExit('%s: no blocks aligned' % name)
    top = max(range(len(states)), key=lambda x: states[x][2])
    chosen = {}
    while top is not None:
        k, q, s_, prev = states[top]
        chosen[k] = q
        top = prev
    changes = {}
    for k, (i, rpos, n, cands) in enumerate(ocands):
        if k not in chosen:
            log.append('%s block %d (%X bytes) is not in the original: left unchanged '
                       '(no longer linked once its callers use the original code)' % (name, i, n))
            continue
        q = chosen[k]
        nxt = [chosen[k2] for k2 in range(k + 1, len(ocands)) if k2 in chosen]
        if nxt:
            on = nxt[0] - q
        else:
            # last block: choose the size that best matches its tail
            best_ = None
            rb = bytes(ref.img[ref_seg + rpos:ref_seg + rpos + n])
            mask = set(kk for e in tpu.brel[i] for kk in range(e[4], e[4] + TPU.fsize(e)))
            for dn in range(-0x80, 0x81):
                on_ = n + dn
                if on_ <= 0:
                    continue
                ob = bytes(orig.img[orig_seg + q:orig_seg + q + on_])
                a_, b_, c_ = diff_region(rb, ob, mask)
                score = -(b_ - a_) - abs(dn) * 0.001
                if best_ is None or score > best_[0]:
                    best_ = (score, on_)
            on = best_[1]
        rb = bytes(ref.img[ref_seg + rpos:ref_seg + rpos + n])
        ob = bytes(orig.img[orig_seg + q:orig_seg + q + on])
        if ob == rb:
            continue
        changes[i] = (rb, ob, on - n, rpos, q)
    for i, (rb, ob, dn, b_rpos, b_q) in changes.items():
        oldb = tpu.block(i)
        mask = set()
        for e in tpu.brel[i]:
            for k in range(TPU.fsize(e)):
                mask.add(e[4] + k)
        p0, r_old_end, r_new_end = diff_region(rb, ob, mask)
        if dn:
            # precise region: window [k, k+w) (old) / [k, k+w+dn) (new) minimising mismatches outside
            n_, D_ = len(rb), -dn
            WMAX = n_
            soft = set()       # branch displacements: expected to differ when code moves
            for (pa, la, ta) in _insns(rb, 0, len(rb)):
                mn_ = ta.split()[0] if ta else ''
                if (mn_.startswith('j') or mn_ in ('call', 'loop', 'loope', 'loopne', 'jcxz')) and la in (2, 3):
                    for kk in range(pa + 1, pa + la):
                        soft.add(kk)
            pre = [0]
            for x in range(n_):
                pre.append(pre[-1] + (0 if (x in mask or x in soft or x >= len(ob) or rb[x] == ob[x]) else 1))
            suf = [0] * (n_ + 1)
            for x in range(n_ - 1, -1, -1):
                y = x - D_
                suf[x] = suf[x + 1] + (0 if (x in mask or x in soft or y < 0 or rb[x] == ob[y]) else 1)
            best_ = None
            for k in range(n_):
                for w in range(max(D_, 1), min(WMAX, n_ - k) + 1):
                    c = pre[k] + suf[k + w] + w * 0.001
                    if best_ is None or c < best_[0]:
                        best_ = (c, k, w)
            c, k, w = best_
            p0, r_old_end, r_new_end = k, k + w, k + w - D_
            log.append('   precise region %X-%X, %d displacement bytes differ outside it' % (k, k + w, int(c)))
        log.append('%s block %d: region %X-%X -> %X bytes (size %+d)' % (name, i, p0, r_old_end, r_new_end - p0, dn))
        rmap = align_relocs(rb, ob, p0, r_old_end, r_new_end, tpu.brel[i], log)
        used_q = set()
        farmap = {}
        del RETARGET[:]
        if REF_SEGS:
            farmap = match_far(tpu.brel[i], rb, ob, ref, orig, ref_seg + b_rpos, orig_seg + b_q,
                               p0, r_old_end, r_new_end, log)
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
                # relocation inside the changed region: use the instruction alignment
                q = rmap.get(op)
                if TPU.fsize(e) == 4 and op in farmap:
                    q = farmap[op]
                    for (rop, rq, tun, toff) in RETARGET:
                        if rop == op and rq == q:
                            PENDING.append((name, i, q, tun, toff))
                if q is not None:
                    used_q.add(q)
                if q is None:
                    log.append('   relocation at %X (%s): instruction deleted in the original, dropped' % (op, e))
                    continue
                if q != op:
                    log.append('   relocation moved %X -> %X' % (op, q))
                e[4] = q
            for k in range(TPU.fsize(e)):
                nbk[e[4] + k] = oldb[op + k]
            newrel.append(e)
        if REF_SEGS:
            # validation: far relocations must sit on relocated words of the original
            obase = orig_seg + b_q
            keep = []
            for e in newrel:
                if TPU.fsize(e) == 4 and (obase + e[4] + 2) not in orig.reloc_set:
                    log.append('   far relocation %s does not match a relocated word in the original: dropped' % (e,))
                    for k in range(4):
                        nbk[e[4] + k] = ob[e[4] + k]
                    continue
                keep.append(e)
            newrel = keep
            covered = set(e[4] + 2 for e in newrel if TPU.fsize(e) == 4) | set(e[4] for e in newrel if TPU.fsize(e) == 2)
            for k in range(len(ob) - 1):
                if (obase + k) in orig.reloc_set and k not in covered:
                    log.append('   WARNING: relocated word at %X in the original has no relocation' % k)
        newrel.sort(key=lambda e: e[4])      # TPC emits relocations in position order
        tpu.brel[i] = newrel
        tpu.blocks[i][2] = 8 * len(newrel)
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
    if relayout:
        return serialise_relayout(tpu, tpl), len(changes)
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


def serialise_relayout(tpu, d):
    """rebuild a standalone TPU file: header+tables, code, typed consts,
    code relocations, typed-const relocations (header word 14)"""
    assert tpu.off == 0
    h = tpu.hdr
    old_crel_off = a16(tpu.reloc_off + tpu.reloc_size)
    crel = bytes(d[old_crel_off:old_crel_off + h[14]])
    consts = bytes(d[tpu.const_off:tpu.const_off + tpu.const_size])
    allrel = [e for bl in tpu.brel for e in bl] + tpu.other_rel
    h[11] = tpu.code_size
    h[13] = 8 * len(allrel)
    out = bytearray(d[:tpu.code_off])
    struct.pack_into('<32H', out, 8, *h)
    for k, b in enumerate(tpu.blocks):
        struct.pack_into('<4H', out, tpu.blk_tab + 8 * k, *b)
    for k, e in enumerate(tpu.entries):
        struct.pack_into('<4H', out, tpu.ent_tab + 8 * k, *e)
    def pad():
        out.extend(b'\0' * (a16(len(out)) - len(out)))
    out += tpu.code[:tpu.code_size]; pad()
    out += consts; pad()
    for e in allrel:
        out += struct.pack('<BBHHH', *e)
    pad()
    out += crel; pad()
    return bytes(out)


RETARGET = []      # (old pos, new pos, target unit, orig target offset) for the current block
PENDING = []       # (unit, block, pos, target unit, orig target offset): relocations to re-target
REF_SEGS = []      # [(start, end, name)] of the reference build (set by patch_tv)
ORIG_SEGS = {}     # name -> linear start in the original (user units + DATA only)
TV_FILES = ('VIEWS', 'DIALOGS')     # Views first: Dialogs' calls into Views are matched by entry
ENTRY_MAPS = {}    # unit -> {orig offset: entry index} for already patched units      # standalone Turbo Vision TPUs patched against BOMBCFG.EXE


def patch_tv(ref_exe):
    """patch toolchain/tp6/<unit>.tpu (from .pristine) against orig/BOMBCFG.EXE;
    ref_exe = a BOMBCFG --final build linked with the pristine TV units"""
    os.environ['TW_TARGET'] = 'BOMBCFG'
    import importlib
    importlib.reload(U)
    ref = exe.MZ(ref_exe)
    mp = exe.load_map(os.path.splitext(ref_exe)[0] + '.MAP')
    rseg = {n: (s, e + 1 - s) for s, e, n, c in mp['segments']}
    orig = exe.MZ(os.path.join(ROOT, 'orig', 'BOMBCFG.EXE'))
    oseg = {n: a for n, s, a, e in U.unit_bounds(0)}
    global REF_SEGS, ORIG_SEGS
    REF_SEGS = [(s, e + 1, n) for s, e, n, c in mp['segments']]
    ORIG_SEGS = {n: a for n, a in oseg.items() if n not in U.LIB}
    ORIG_SEGS['DATA'] = U.DSEG * 16
    log = []
    for name in TV_FILES:
        fn = os.path.join(TPD, name.lower() + '.tpu')
        data = bytearray(open(fn + '.pristine', 'rb').read())
        s, ln = rseg[name]
        out, n = patch_unit(data, name, ref, orig, s, oseg[name], ln, log, off=0, relayout=True)
        open(fn, 'wb').write(out)
        log.append('%s.tpu: %d blocks rewritten, %d -> %d bytes' % (name.lower(), n, len(data), len(out)))
        tt = TPU(out, 0)
        seglen = [e - a for n_, s_, a, e in U.unit_bounds(0) if n_ == name][0]
        where, used = locate_blocks(tt, orig, oseg[name], seglen)
        ENTRY_MAPS[name] = {where[e[2] // 8] + e[3]: k for k, e in enumerate(tt.entries)
                            if e[2] % 8 == 0 and (e[2] // 8) in where}
    for (uname, bi, pos, tun, toff) in PENDING:
        log.append(resolve_retarget(uname, bi, pos, tun, toff, orig, oseg))
    return log


def unit_list(tpu, d):
    """TPU unit list (header words 7..8): {name: offset} = the unit index used in relocations"""
    a, b = tpu.hdr[7], tpu.hdr[8]
    out = {}
    p = a
    while p < b:
        ln = d[p + 2]
        out[bytes(d[p + 3:p + 3 + ln]).decode()] = p - a
        p += 3 + ln
    return out


def resolve_retarget(uname, bi, pos, tun, toff, orig, oseg):
    fn = os.path.join(TPD, uname.lower() + '.tpu')
    d = bytearray(open(fn, 'rb').read())
    t = TPU(d, 0)
    ul = unit_list(t, d)
    if tun not in ul:
        raise SystemExit('%s does not use %s' % (uname, tun))
    # entry of the target unit linked at orig offset toff
    tfn = os.path.join(TPD, tun.lower() + '.tpu')
    td = open(tfn, 'rb').read()
    tt = TPU(td, 0)
    seg = oseg[tun]
    seglen = [e - a for n, s, a, e in U.unit_bounds(0) if n == tun][0]
    where, used = locate_blocks(tt, orig, seg, seglen)
    ent = toff[1] if isinstance(toff, tuple) else None
    for k, e in enumerate(tt.entries if ent is None else []):
        if e[2] % 8 == 0 and (e[2] // 8) in where and where[e[2] // 8] + e[3] == toff:
            ent = k
            break
    if ent is None:
        raise SystemExit('no entry of %s at %s' % (tun, toff))
    for bl in t.brel:
        pass
    e = [x for x in t.brel[bi] if x[4] == pos][0]
    old = list(e)
    e[0], e[2], e[3] = ul[tun], ent * 8, 0
    out = serialise_relayout(t, d)
    open(fn, 'wb').write(out)
    return '%s block %d: relocation %s -> %s (%s entry %d)' % (uname, bi, old, e, tun, ent)


def main():
    if len(sys.argv) == 3 and sys.argv[1] == '--tv':
        print('\n'.join(patch_tv(sys.argv[2])))
        return
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
    print(patch_drivers())


def patch_drivers():
    """Turbo Vision DRIVERS.TPU: the original (1990) CtrlToArrow knows 10 control
    keys; the 1991 unit added ^H -> kbBack (11 entries).  Restore the 10-entry
    tables (typed constants CtrlCodes/ArrowCodes) and the loop bound."""
    src = os.path.join(TPD, 'drivers.tpu.pristine')
    if not os.path.exists(src):
        return 'drivers.tpu.pristine missing - skipped'
    d = bytearray(open(src, 'rb').read())
    t = TPU(d, 0)
    h = t.hdr
    cblk_tab = h[4]
    cblocks = [list(struct.unpack('<4H', d[cblk_tab + 8 * i:cblk_tab + 8 * i + 8])) for i in range((h[5] - cblk_tab) // 8)]
    assert cblocks[5][1] == 34
    cstart = sum(b[1] for b in cblocks[:5])
    consts = bytearray(d[t.const_off:t.const_off + t.const_size])
    old = consts[cstart:cstart + 34]
    assert old[:11] == bytes([0x13, 4, 5, 0x18, 1, 6, 7, 0x16, 0x12, 3, 8])
    new = old[:10] + old[12:12 + 20]          # drop ^H, the pad byte and kbBack
    consts[cstart:cstart + 34] = new
    cblocks[5][1] = 30
    # CtrlToArrow (code block 25): loop bound and ArrowCodes reference
    b = 25
    s0 = t.bstart[b]
    blk = t.code[s0:s0 + t.blocks[b][1]]
    k = bytes(blk).find(bytes.fromhex('837EFC0A'))
    assert k > 0
    t.code[s0 + k + 3] = 9
    n = 0
    for e in t.brel[b]:
        if e[0] == 0 and e[2] == 5 * 8 and e[3] == 12:
            e[3] = 10
            n += 1
    assert n == 1
    # re-lay out the file: header, tables, code, consts, code relocs, const relocs
    const_size = t.const_size - 4
    const_rel_size = h[14]
    const_rel = d[a16(t.reloc_off + t.reloc_size):a16(t.reloc_off + t.reloc_size) + const_rel_size]
    h[12] = const_size
    struct.pack_into('<32H', d, 8, *h)
    for i, cb in enumerate(cblocks):
        struct.pack_into('<4H', d, cblk_tab + 8 * i, *cb)
    out = bytearray(d[:t.code_off])
    out += t.code
    out += b'\0' * (a16(len(out)) - len(out))
    out += consts[:const_size]
    out += b'\0' * (a16(len(out)) - len(out))
    for e in [e for bl in t.brel for e in bl] + t.other_rel:
        out += struct.pack('<BBHHH', *e)
    out += b'\0' * (a16(len(out)) - len(out))
    out += const_rel
    out += b'\0' * (a16(len(out)) - len(out))
    open(os.path.join(TPD, 'drivers.tpu'), 'wb').write(out)
    return 'drivers.tpu written (CtrlToArrow: 10 control keys)'


if __name__ == '__main__':
    main()
