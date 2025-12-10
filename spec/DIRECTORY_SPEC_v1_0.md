RIS/IES Directory Specification v1.0
Source: INTERNAL
Status: BASELINE
Encoding: UTF-8 (LF)

Purpose
Defines the minimal required directory layout for a valid RIS/IES kernel tree.

Required Top-Level Directories
- spec/
  Contains invariant specifications, meta-rules, governance, and directory definitions.

- docs/
  Contains long-form converted documents (RELAX, ERRATA, MANIFEST, ROHKRPER).

- views/
  Contains rendered architectural perspectives. Non-normative but compliance-bound.

- tools/
  Contains deterministic helper scripts, hashing tools, and reproducible utilities.

- logs/
  Contains append-only operational logs (migration, transforms).

- reports/
  Generated machine-view results, should be reproducible and traceable.

- LICENSES/
  All license files and acknowledgements.

Files
- README.txt (human-first summary of kernel purpose)

Invariants
- No executable binaries allowed in kernel tree.
- All markdown files UTF-8 (LF).
- No trailing spaces.
- Final newline required.

[COMPLIANCE]
Encoding: utf-8
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
[/COMPLIANCE]
