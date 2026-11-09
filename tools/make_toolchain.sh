#!/bin/bash
# Recreate toolchain/tp6/turbo.tpl (1990-style System/Crt) from turbo.tpl.pristine.
# Needs the decompiled sources (a reference link tells the patcher where each
# library code block lands).
set -e
cd "$(dirname "$0")/.."
python3 - <<'PY'
d = bytearray(open('toolchain/tp6/turbo.tpl.pristine', 'rb').read())
d[0x67F2:0x67F4] = b'\0\0'          # OvrEmsHandle (no code shift, needed for a clean data image)
open('toolchain/tp6/turbo.tpl', 'wb').write(d)
PY
python3 tools/build.py --work build/w_ref --final --no-lkg --quiet
python3 tools/patch_tpl.py build/w_ref/BOMB.EXE | grep -v 'size +0)$'
