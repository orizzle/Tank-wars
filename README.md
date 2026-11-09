# Tank Wars 3.0 — matching decompilation

Pascal source for **Tank Wars 3.0** (Kenneth Morse, 1992; files named `BOMB`).
Built with Turbo Pascal 6.0, it reproduces both original executables
**byte for byte**:

| file | size | MD5 |
|---|---|---|
| `BOMB.EXE` (the game) | 241 312 | `cb93e5218e4d06e4c162f829c18ae329` |
| `BOMBCFG.EXE` (Turbo Vision setup program) | 94 544 | `b9234efac0a58329accaa9914fec72a4` |

The author released the game as freeware and explicitly allows decompiling it.

## Building
Requirements: Linux with `dosbox`, `python3` + `capstone`, `nasm`; the Turbo
Pascal 6.0 distribution files in `toolchain/tp6/` (TPC.EXE, TURBO.TPL as
`turbo.tpl.pristine`, GRAPH.TPU, BINOBJ.EXE and the Turbo Vision TPUs from
TVISION.ZIP — not included); the original `BOMB.EXE` and `BOMBCFG.EXE` in
`orig/` (needed once, to derive the library patches, and for comparing).

```
tools/make_toolchain.sh                                   # once: derive the patched library (see below)
python3 tools/build.py --work build/w_final --final --no-lkg
python3 tools/cmp.py   --work build/w_final --full        # -> IDENTICAL (241312 bytes)
TW_TARGET=BOMBCFG python3 tools/build.py --work build/wc_final --final --no-lkg
TW_TARGET=BOMBCFG python3 tools/cmp.py   --work build/wc_final --full   # -> IDENTICAL (94544 bytes)
```
The EXEs are `build/w_final/BOMB.EXE` and `build/wc_final/BOMBCFG.EXE`; the
game data files (`BOMB1.RAW`, `BOMB2.RAW`, ...) are not part of this project.

## Runtime library note
The originals were linked with an earlier TP 6.0 runtime library than the one
on the available TP 6.0 / 6.01 disks (which say "Copyright 1983,91"). Known
differences, all in Borland's code:
* System: copyright year, heap-error path, stack-overflow check (2 bytes
  shorter), one more byte; OvrEmsHandle initial value
* Crt: `Delay` (2 bytes shorter)
* Turbo Vision Drivers: `CtrlToArrow` knows 10 control keys, not 11 (no ^H)
* Turbo Vision Dialogs: `TCluster.DrawBox` (older version, calls a Views routine
  instead of a Drivers one); Views: several routines (one helper and two
  System calls did not exist yet)

`tools/make_toolchain.sh` (using `tools/patch_tpl.py`) derives patched copies
of `turbo.tpl`, `drivers.tpu`, `dialogs.tpu` and `views.tpu` from the pristine
files: the differing code blocks are replaced by the bytes found in the
original EXEs, and the TPU tables (sizes, relocations, entry points) are
rewritten. Every other library byte, and all of the programs' own code and
data, comes from the compiler.

## BOMBCFG.EXE (`src_cfg/`)
`BOMBCFG.PAS` (Turbo Vision application: option dialogs, BOMB.CFG load/save),
`C0453.PAS` (numeric input line), `C04B6.PAS` (Borland's Turbo Vision help-file
viewer, HELPFILE.PAS from the TV demos). Units `U2918` and `U2968` are shared
with the game (`src/`). Select this target with `TW_TARGET=BOMBCFG`.

## Source layout (`src/`)
| file | contents |
|---|---|
| `BOMB.PAS` | main program |
| `U0040.PAS` … `U2968.PAS` | one unit per original code segment (named after its paragraph address) |
| `U27D1.PAS` | GLOBALS: nearly all global variables and typed constants |
| `U0728_A/B.INC`, `U0E9B_A/B.INC` | implementation halves of the two biggest units |
| `CPUID.ASM` | hand-written CPU detection (NASM → BINOBJ → linked external) |
| `*.BGI`, `*.CHR`, `SINTAB.BIN` | linked data: VGA256 BGI driver, EURO/LITT/TINY fonts, sine table |

Rough map of the game: U0728 setup/config/menus, U0E9B shop, rounds, save/load,
U1615 weapon flight/MIRV/laser/round loop, U1B27/U1DD4 explosions and effects,
U1F69/U20C6/U22B7 player turn UI, U23C3 computer players (TP objects),
U0098 screens/dialogs, U2390 hot keys/boss key, U27B1 keyboard handler,
U27D4 palette cycler (retrace interrupt), U2823 graphics primitives (BASM),
U2918 misc/strings/CPU detection, U2968 mouse.

## Conventions
* `{#Uxxxx_OOOO}` markers precede every procedure; the name gives the unit and
  its entry offset in the original, and `tools/cmp.py` uses it to compare procedure by procedure.
* Identifiers are readable names; `notes/names.tsv` maps each one to its
  placeholder name (`U1B27_0047` = unit U1B27, entry offset 0047 in the
  original; `Players_3F0E` = DS:3F0E) with a one-line note.  Global
  declarations carry their DS offset as a comment (`{ DS:3F0E }`).
  `tools/rename.py TABLE [--apply]` renames safely: it refuses any new name that
  already exists in the sources, in the Borland units or as a reserved word, so
  a rename cannot re-bind a reference.  Names are a best reading of the code;
  `UnknownXXXX`/`UnusedXXXX` mark what is unclear or unreferenced.
* Dev builds (`build.py` without `--final`) add a `KEEPALL` reference to every
  procedure so the smart linker keeps it while callers are unfinished.
* See `notes/GUIDE.md` for TP6 code-generation details found along the way.
