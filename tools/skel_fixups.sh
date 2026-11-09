#!/bin/bash
# manual fixups applied on top of the generated skeleton (reproducible)
set -e
cd "$(dirname "$0")/.."
T=tools
python3 $T/mergevar.py U27D1 440A 460A 'g_440A: array[0..511] of Byte;'
python3 $T/mergevar.py U27D1 46CA 46E9 'g_46CA: string[30];'
python3 $T/mergevar.py U27D1 46F8 46FC 'g_46F8: Pointer;'
sed -i 's/^  g_461E: Word;/  g_461E: Integer;/' src/U27D1.PAS
python3 - <<'PY'
import re
def setsig(unit, name, sig):
    p='src/%s.PAS'%unit; s=open(p).read()
    s2=re.sub(r'(procedure|function) %s(\([^)]*\))?(: \w+)?;'%name, sig, s)
    assert s2!=s, name
    open(p,'w').write(s2)
setsig('U0098','U0098_0226','procedure U0098_0226(S: string);')
setsig('U27B1','U27B1_007D','procedure U27B1_007D(Flag: Boolean; Handler: Pointer);')
setsig('U2968','U2968_002E','procedure U2968_002E(B: Byte);')
setsig('U2968','U2968_003B','function U2968_003B: Byte;')
setsig('U27D4','U27D4_0244','procedure U27D4_0244(B: Byte);')
PY
