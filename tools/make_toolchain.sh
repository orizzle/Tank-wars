#!/bin/bash
# Derive the patched TP 6.0 library files (1990-era runtime) from the pristine
# Borland files in toolchain/tp6 (*.pristine), using reference links of the
# decompiled sources against orig/BOMB.EXE and orig/BOMBCFG.EXE.
#   turbo.tpl   System + Crt   (reference: BOMB.EXE)
#   drivers.tpu CtrlToArrow    (fixed patch)
#   views.tpu, dialogs.tpu     (reference: BOMBCFG.EXE)
set -e
cd "$(dirname "$0")/.."
T=toolchain/tp6
for f in drivers views dialogs; do
  [ -f $T/$f.tpu.pristine ] || cp $T/$f.tpu $T/$f.tpu.pristine
  cp $T/$f.tpu.pristine $T/$f.tpu
done
python3 - <<'PY'
d = bytearray(open('toolchain/tp6/turbo.tpl.pristine', 'rb').read())
d[0x67F2:0x67F4] = b'\0\0'          # OvrEmsHandle
open('toolchain/tp6/turbo.tpl', 'wb').write(d)
PY
python3 tools/build.py --work build/w_ref --final --no-lkg --quiet
python3 tools/patch_tpl.py build/w_ref/BOMB.EXE | grep -E 'size [-+][1-9]|written'
TW_TARGET=BOMBCFG python3 tools/build.py --work build/wc_ref --final --no-lkg --quiet
python3 tools/patch_tpl.py --tv build/wc_ref/BOMBCFG.EXE | grep -E 'tpu:|re-targeted|dropped'
