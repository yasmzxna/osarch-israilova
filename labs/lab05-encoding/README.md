# Lab 5 — Encoding forensics

Name: Исраилова Ясмина · Date: 2026-11-11 · Tools: terminal (`file`, `iconv`, `sed`, `xxd`-style hex dump), Microsoft Excel, LibreOffice Calc, Windows PowerShell (`cat`)

## What I received
- Excel: Cyrillic and Kazakh names shown as garbage (mojibake) instead of readable text.
- LibreOffice: also garbage, but different from Excel, because the import dialog guessed a different character set.
- Terminal (`cat`): replacement characters (�) in place of every non-ASCII letter, because the bytes are not valid UTF-8.

## Diagnosis (made before the fix)
- `file` said: `Non-ISO extended-ASCII text, with CRLF line terminators` (evidence/file-before.txt). `file` only guesses, it cannot name the code page.
- First 16 bytes: `49 44 3b d4 e0 ec e8 eb e8 ff 3b c8 ec ff 3b ce` (evidence/hexdump-before.txt)
- **Encoding: KZ-1048 (RK1048, Kazakh variant of Windows-1251)** — because every Cyrillic letter is a single byte in the range C0–FF (e.g. "Ф" = `D4`, "а" = `E0`), so it is not UTF-8 (the file is not valid UTF-8: first byte `D4` at position 3 is followed by `E0`, not a continuation byte). Decoding as Windows-1251 reads the Russian names but breaks the Kazakh letters (`A3` -> "Ј", `8D` -> "Ќ", `BC` -> "ј"); decoding as KZ-1048 gives "Ә", "Қ", "ә" and all 15 rows read correctly (Әбдірахманова, Қасымов, Нұрлан, Өмірзақова, Үміт...). KOI8-R gives nonsense.
- **Line ending: CRLF (Windows)** — because every line ends with `0D 0A`: 16 CRLF, 16 LF in total, no lone CR.
- **BOM: no** — the file starts with `49 44` ("ID"), not `EF BB BF` or `FF FE`.
- Separator: `;` (5 per line, no commas). This matches Excel in a Russian/Kazakh locale, so I kept it.

## Decisions for the fixed file
- Encoding: UTF-8.
- BOM: **added** (`EF BB BF`). Without it Excel on Windows does not recognise UTF-8 on double-click and shows garbage again. The brief requires it to open correctly everywhere, including Excel.
- Line ending: **LF**. CRLF would break a Linux script (`$'\r': command not found`); Excel, LibreOffice and `cat` all handle LF fine.

## Fix
```sh
#!/bin/sh
in=evidence/staff-broken.csv
out=evidence/staff-fixed.csv
iconv -f RK1048 -t UTF-8 "$in" > "$out"                                    # encoding
sed -i 's/\r$//' "$out"                                                    # CRLF -> LF
printf '\357\273\277' | cat - "$out" > "$out.tmp" && mv "$out.tmp" "$out"  # add BOM
```
Run from `labs/lab05-encoding/`: `sh scripts/fix.sh`

## Verification
- `file evidence/staff-fixed.csv`: `Unicode text, UTF-8 (with BOM) text`, no CRLF mention (evidence/file-after.txt). Cyrillic is now `D0 xx` / `D1 xx` pairs.
- Opens correctly in three applications, all names (including Kazakh letters Ә, Қ, Ұ, Ө, Ү, Ғ) read correctly: evidence/opens-correctly.png (one image combining the three real screenshots: Excel, LibreOffice Calc, terminal)
  - **Excel** — opened by double-click, no import dialog, each field in its own column. The UTF-8 BOM is what lets Excel recognise the encoding. I did not save the file from Excel (the "possible data loss" bar was ignored).
  - **LibreOffice Calc** — import dialog detected UTF-8 and the `;` separator, preview already shows the correct names.
  - **Terminal (`cat` in PowerShell)** — the first line prints as `ID;Фамилия;...`, so the BOM does not show up and does not break the header.

## What did not work the first time
- My first guess was Windows-1251 (the usual Cyrillic code page). Russian names were fine but Kazakh letters came out wrong (Ј, Ќ, ґ instead of Ә, Қ, Ө). Looking at the bytes of a Kazakh letter (`A3`, `8D`) led to KZ-1048.
- `xxd` was not installed in my first environment, so I produced the hex dump in the same `xxd` format with a short Python script and checked the bytes (first 16 bytes, BOM, CRLF count) there.
