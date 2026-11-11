#!/bin/sh
# Lab 5: convert staff-broken.csv from RK1048 (KZ-1048) to UTF-8
# Run from labs/lab05-encoding/:  sh scripts/fix.sh
in=evidence/staff-broken.csv
out=evidence/staff-fixed.csv
iconv -f RK1048 -t UTF-8 "$in" > "$out"                  # 1. encoding: KZ-1048 -> UTF-8
sed -i 's/\r$//' "$out"                                  # 2. line endings: CRLF -> LF
printf '\357\273\277' | cat - "$out" > "$out.tmp" && mv "$out.tmp" "$out"   # 3. add UTF-8 BOM (for Excel double-click)
