#!/bin/bash
set -e
python3 - << 'PY'
import re, sys
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
for perm in ['android.permission.INTERNET', 'android.permission.CAMERA']:
    if 'android:name="%s"' % perm not in s:
        s = re.sub(r'(<manifest[^>]*>)', r'\1\n    <uses-permission android:name="%s" />' % perm, s, count=1)
        print('Added', perm)
s = re.sub(r'android:label="[^"]*"', 'android:label="AutoPrint"', s, count=1)
open(p, 'w', encoding='utf-8').write(s)
missing = [x for x in ['android.permission.INTERNET', 'android.permission.CAMERA'] if 'android:name="%s"' % x not in s]
if missing:
    sys.exit('Permission missing in manifest: ' + ', '.join(missing))
print('Manifest OK')
PY
grep -n "uses-permission\|android:label" android/app/src/main/AndroidManifest.xml
