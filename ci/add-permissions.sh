#!/bin/bash
set -e
M=android/app/src/main/AndroidManifest.xml
if [ ! -f "$M" ]; then
  echo "Manifest nahi mila: $M"
  exit 1
fi
for p in android.permission.INTERNET android.permission.CAMERA; do
  if ! grep -q "$p" "$M"; then
    sed -i "0,/<manifest[^>]*>/s//&\n    <uses-permission android:name=\"$p\" \/>/" "$M"
    echo "Added $p"
  fi
done
sed -i 's/android:label="[^"]*"/android:label="AutoPrint"/' "$M"
grep -n "uses-permission\|android:label" "$M"
