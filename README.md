# Tank Wars 3.0 — matching decompilation

Pascal source for **Tank Wars 3.0** (Kenneth Morse, 1992; files named `BOMB`).
Built with Turbo Pascal 6.0, it reproduces the original `BOMB.EXE`
**byte for byte** (241 312 bytes, MD5 `cb93e5218e4d06e4c162f829c18ae329`).
The author released the game as freeware and explicitly allows decompiling it.

## Building
Requirements: Linux with `dosbox`, `python3` + `capstone`, `nasm`; the Turbo
Pascal 6.0 distribution files in `toolchain/tp6/` (TPC.EXE, TURBO.TPL as
`turbo.tpl.pristine`, GRAPH.TPU, BINOBJ.EXE — not included).

```
tools/make_toolchain.sh                                   # once: derive turbo.tpl (see below)
python3 tools/build.py --work build/w_final --final --no-lkg
python3 tools/cmp.py   --work build/w_final --full        # -> IDENTICAL (241312 bytes)
```
The EXE is `build/w_final/BOMB.EXE`; the original game data files
(`BOMB1.RAW`, `BOMB2.RAW`, ...) are not part of this project.

## Runtime library note
The original was linked with an earlier TP 6.0 runtime than the one on the
available TP 6.0 / 6.01 disks (which say "Copyright 1983,91"). Five
library code blocks differ: System's copyright year, its heap-error path, its
stack-overflow check (2 bytes shorter), one more byte in System, and Crt's
`Delay` (2 bytes shorter). The OvrEmsHandle initial value differs too.
`tools/make_toolchain.sh` / `tools/patch_tpl.py` rewrite those blocks inside
`turbo.tpl` (taking their bytes from the original EXE). Every other
library byte, and all of the game's own code and data, comes from the
compiler.

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
* Procedure names are still `Uxxxx_OOOO` (comments say what they do); globals
  carry their DS offset as a suffix (`Players_3F0E`).
* Dev builds (`build.py` without `--final`) add a `KEEPALL` reference to every
  procedure so the smart linker keeps it while callers are unfinished.
* See `notes/GUIDE.md` for TP6 code-generation details found along the way.
