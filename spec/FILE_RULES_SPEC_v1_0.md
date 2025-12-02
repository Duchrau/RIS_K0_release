# RIS K0 – FILE RULES SPEC v1.0
Status: NORMATIVE
Encoding: UTF-8 (LF)

## Allowed Normative File Types
- .md (UTF-8, LF)
- .json (UTF-8, LF)
- .txt (UTF-8, LF)
- .py  (nur normative tools)
- .ps1 (nur normative tools)

## Forbidden in normative areas
- binary executables (.exe, .dll, .so)
- archives inside bundle_root/spec/tools (zip, tar, gz…)
- editor trash: ~, .tmp, .swp

## Encoding Rules
- UTF-8 (LF) only
- No BOM
- No trailing spaces
- Exactly one final LF

## Filename Rules
- lower-case recommended
- no whitespace
- hyphens and underscores allowed

## Size Limits
- json: < 5MB
- md:   < 2MB
- Kernel objects_K0.json: MUST remain ASCII/UTF-8 and deterministic

## End of File

