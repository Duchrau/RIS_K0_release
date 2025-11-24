RIS/IES Governance Specification v1.0
Source: INTERNAL
Status: BASELINE
Encoding: UTF-8 (LF)

Purpose
Defines governance responsibilities, ownership boundaries, and reference anchors 
required for maintaining consistency across the RIS/IES kernel tree.

Governance Model
- spec/ defines structural and meta-level invariants.
- views/ defines rendered perspectives (non-semantic).
- docs/ holds human-first long-form documents.
- tools/ contains only deterministic or documented utilities.
- reports/ contains machine-generated artifacts.
- logs/ contains append-only operational logs.

Ownership
- spec/ is authoritative over:
  - directory layout
  - naming conventions
  - compliance invariants
- docs/ is non-authoritative, purely descriptive
- views/ is descriptive but required to follow compliance blocks

Versioning
- Major versions change when semantic invariants change.
- Minor versions change when directory or compliance requirements change.

[COMPLIANCE]
Encoding: utf-8
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
[/COMPLIANCE]
