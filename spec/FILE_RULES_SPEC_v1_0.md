RIS/IES File Rules Specification v1.0
Source: INTERNAL
Status: BASELINE
Encoding: UTF-8 (LF)

Purpose
Defines allowed file types, encodings, and formatting constraints inside the RIS kernel tree.

Allowed File Types
- .md (UTF-8, LF)
- .json (UTF-8, LF, ASCII-safe recommended)
- .tsv (UTF-8, LF)
- .txt (UTF-8, LF)
- .parquet (binary, audit-only)
- .sig (ASCII armored or raw signature material)
- .edn (UTF-8, LF)

Forbidden File Types
- Any binary executable (.exe, .dll, .bin)
- Any archive (.zip, .tar, .gz) inside kernel sources
- Any temporary editor or OS artifacts (~, .tmp, .swp)

Encoding Rules
- All text files MUST be UTF-8.
- Newlines MUST be LF only.
- No BOM allowed.
- No trailing spaces.
- Exactly one final newline required.

Naming Rules
- Lowercase preferred.
- Hyphens allowed.
- Underscores allowed for machine artifacts.
- No whitespace in filenames.
- No spaces at line ends.

Size Constraints
- .md files < 2MB
- .json files < 5MB (except manifest if required)
- No file may exceed 10MB inside kernel unless declared as exception.

[COMPLIANCE]
Encoding: utf-8
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
[/COMPLIANCE]
