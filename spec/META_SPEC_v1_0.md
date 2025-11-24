RIS/IES Meta-Specification v1.0
Source: INTERNAL
Status: BASELINE
Encoding: UTF-8 (LF)

Purpose
Defines the minimum structural and referential requirements for a valid RIS/IES kernel tree. 
Provides invariants for directory layout, naming, and cross-file referential integrity.

Requirements
A valid kernel MUST contain the following top-level directories:
kernel/
spec/
views/
docs/
logs/
reports/
tools/
LICENSES/

The following files MUST exist:
README.txt
spec/META_SPEC_v1_0.md
spec/GOVERNANCE_SPEC_v1_0.md

No semantic content is required in META_SPEC_v1_0.md. 
This file exists solely to anchor the meta-level referential graph.

[COMPLIANCE]
Encoding: utf-8
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
[/COMPLIANCE]
