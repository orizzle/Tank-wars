# Tank Wars (BOMB.EXE) matching decompilation — working guide

Goal: Pascal sources that Turbo Pascal 6.0 compiles into a **byte-identical**
`orig/BOMB.EXE`. The original was built with TP 6.0 (TPC/TURBO.TPL is in
`toolchain/tp6/`, run headless in DOSBox by the tools).

## Layout
```
orig/BOMB.EXE          original (never modify)
src/                   THE SOURCES (BOMB.PAS + one unit per code segment)
  BOMB.PAS             main program (done)
  Uxxxx.PAS            unit whose code segment was at paragraph xxxx in the original
  U0728_A.INC/_B.INC   implementation halves of big units (included by U0728.PAS)
  *.BGI *.CHR *.BIN    binary blobs linked as OBJ (BINOBJ.LST: file -> public name)
build/dis/Uxxxx.lst    disassembly of the ORIGINAL unit (regenerate: tools/tpdis.py)
tools/                 build.py, cmp.py, tpdis.py, mergevar.py, tpc, dosrun
```

## Unit map (memory order; init order is the reverse)
BOMB(main) U0040 U0098 U0728 U0E9B U1615 U1B27 U1DD4 U1F69 U20C6 U22B7 U2390
U23C3 U26A9 U26D4 U27B1 U27D1 U27D4 U2823 U2918 U2968 | Printer Dos Crt Graph System.
A unit may only `uses` units to its right (they are generated that way: each
unit uses Graph, Crt, Dos, Printer and every user unit to its right).

* **U27D1 = GLOBALS**: owns almost all global data: typed constants
  DS:0056-383F and variables DS:3ACC-E79F. Its only code is the init part.
* U23C3 owns typed constants DS:0002-0055 (= 7 VMTs of TP6 object types; U23C3 is OOP).
* U27D4 vars E7A0-E7BF, U2823 E7C0-E7E1, U2918 E7E2-E81F, U2968 E820-E821.
* DS:3840-3A89 are Graph/Crt/... typed consts, 3A8A-3ACB System's; E822+ library vars.
* `.OBJ` data: U0098 ends with the VGA256 BGI driver + EURO/LITT/TINY fonts,
  U26D4 ends with a sine table blob (SinTable).

## Build & compare (each agent uses its OWN work dir)
```
python3 tools/build.py --work build/w_NAME --mine U0728        # ~2 s
python3 tools/cmp.py   --work build/w_NAME U0728               # per-proc status
python3 tools/cmp.py   --work build/w_NAME --proc U0728_05D8   # side-by-side diff
python3 tools/cmp.py   --work build/w_NAME --layout            # globals at right DS offsets?
python3 tools/cmp.py   --work build/w_NAME --data              # typed-const image identical?
```
* `--mine`: units you own. If someone else's unit fails to compile at that
  moment, build.py silently uses its last-known-good copy instead.
* Dev builds define `KEEPALL`, which takes the address of every marked
  procedure so the smart linker keeps it even though its callers are stubs.
* cmp normalises far-call targets by procedure (marker) name, segment words by
  unit name, CS-relative constant offsets relative to the proc entry, and library
  calls by routine fingerprint. **DS offsets are compared raw** (layout is exact).
* In `--proc` output a `*` marks lines whose raw hex differs; the real verdict
  is the `status:` line (normalised). `first diff at orig +X` = offset from entry.
* The `{...}` text after library calls in listings is a guess from a probe
  build (e.g. `{s:=s+s2#1}` = 2nd helper called by a string concat). Treat as hints.

## Conventions (important — other people's code depends on them)
1. **Markers**: each procedure/function/method is preceded by a line `{#Uxxxx_OOOO}`
   (unit + entry offset in the original). Unit init parts: marker before the
   final `begin`. Never remove or change markers; cmp and KEEPALL rely on them.
2. **Keep the procedure names** `Uxxxx_OOOO` for now (other units call them).
   Put a descriptive comment above the procedure instead. Names of params,
   locals, types, private constants are yours to choose.
3. **Everything goes in the interface** (all procs, all types). Needed for
   KEEPALL; generates the same code since everything is `{$F+}`.
4. **Globals keep the `_XXXX` suffix** = their DS offset (e.g. `KeyDown_440A`).
   `cmp.py --layout` verifies every such name is at that offset.
5. Placeholder globals are `g_XXXX: Byte/Word/LongInt/array[0..n] of Byte`,
   split at every offset the original code references directly. Real arrays
   are usually indexed through a displacement that is NOT their start (TP folds
   the low bound into the displacement), so merge placeholders as you learn the
   real type: `tools/mergevar.py U27D1 START END 'Name_START: Type;'`.
   Typed constants (`c_XXXX`) carry their bytes; keep `--data` identical.
6. Placeholder signatures are `(a1, a2, ...: Word)` from `retf N`. The owner of
   a unit fixes the real signatures of its procedures (types matter for how
   callers push arguments: byte params push AX after `mov al,..`, var/pointer
   params push seg+ofs, value strings/records push a pointer, Real = 3 words,
   functions return AL / AX / DX:AX / DX:BX:AX(Real) / ST(0) (Single/Double/Extended)).
   If you call a proc in someone else's unit and its declaration is still a
   placeholder, you may fix it (interface line + implementation header, keep
   them identical) — read the callee's listing to be sure.
7. Only edit files of your own units, except: (a) declaration fixes per rule 6,
   (b) GLOBALS (U27D1) declarations via mergevar.py or small Edit calls on single
   declarations. Re-read before editing; others edit concurrently.
8. Don't use `{$I}`/`{$L}` for new files without telling the coordinator.

## Compiler settings found so far
Every unit: `{$A-,B-,D+,F+,G-,I-,L+,O-,R-,S-,V+,X+}` (+ `$N+,E+` where the unit
uses floating point through the emulator: INT 34h-3Dh, shown as `F> ...`;
U2918 uses software 6-byte Real: `$N-`). These were inferred; if a unit
needs different switches (e.g. `$B+`, `$V-`, `$N+`), change them.
With `$N+`, `Real` arithmetic goes through the FPU (SYSTEM:42D3 = load Real
into ST, 42FD = store ST to Real); `Single/Double/Extended/Comp` are native.

## TP6 code generation notes
* Prologue `55 89 E5` (+ `83 EC n`/`81 EC n` locals). Epilogue `89 EC 5D` (only if
  locals) then `CB`/`CA n`. Frameless procs = `assembler` procs without
  params/locals. BASM encodes `mov bp,sp` as `8B EC`, the compiler as `89 E5`,
  so `8B EC` / `8B xx` reg-reg forms usually mean hand-written asm.
* `assembler` procs: no frame if no params/locals; compiler appends `CB`/`CA n`.
  A Pascal proc can also contain `asm ... end;` blocks.
* Value parameters larger than 4 bytes (records/arrays) are copied into the
  frame in the prologue (helper SYSTEM:34E4 = move); value strings via 35CA (copy
  with max length). Functions keep their result in a local and load it at the end.
* `for i := a to b`: `mov [i],a; jmp L2; L1: inc [i]; L2: body; cmp [i],b; jne L1`
  (with a pre-check when bounds aren't constants). `while`: test at the top.
  `repeat`: test at the bottom. `case`: compare/jump chains.
* Calls inside a unit to far procs: `push cs; call near` (`0E E8`).
* Strings: temp strings live in the frame (`lea di,[bp-N]; push ss; push di`).
  String literals live in the CODE segment before the procedure that uses them
  (`mov di,ofs; push cs; push di`). Float constants too (`F> fld dword cs:[..]`).
* Boolean expressions with `$B-` short-circuit; `if b then` on a Byte/Boolean
  is `cmp byte ptr [x],0; je`.
* When unsure how TP compiles something, write a tiny test program in a scratch
  dir and compile it: `tools/tpc DIR /B /GD TEST.PAS`, then disassemble
  (python3 tools/tpdis.py DIR/TEST.EXE won't know its units — use ndisasm on the
  image or `cmp.py`-style helpers). This is often the fastest way to settle a pattern.

## Definition of done for a unit
`cmp.py UNIT` shows all procs `ok` and `segment: orig X, build X` equal,
`--layout` and `--data` clean. Then improve readability (comments, names of
locals/types) without breaking the match (re-run cmp after every change).
