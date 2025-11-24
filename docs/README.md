# RIS K0 – Provenanced Model (ARCHIVE_LOCKED)

A canonical, verifiable release of the RIS K0 system model.  
All artifacts are cryptographically sealed and verified through reproducible build provenance.

## Repository Structure

/
├── release/ # Canonical release archives
│ ├── RIS_K0_provenanced.zip
│ └── RIS_K0_provenanced.zip.sha256
│
├── docs/ # Public documentation and verification guides
│ ├── Overview.md / .pdf
│ ├── VERIFY.md
│ ├── CONSUMERS.md
│ └── README.md # This document
│
├── spec/ # Normative specifications (v1.0)
│ ├── DIRECTORY_SPEC_v1_0.md
│ ├── FILE_RULES_SPEC_v1_0.md
│ ├── GOVERNANCE_SPEC_v1_0.md
│ ├── META_SPEC_v1_0.md
│ └── SYSTEM_SPEC_v1_0.md
│
├── tools/ # Verification scripts (cross-platform)
│ ├── verify_all.ps1
│ └── verify_all.sh
│
├── .github/workflows/verify.yml # CI verification pipeline
├── LICENSE # MIT (code)
└── LICENSE-docs # CC-BY-4.0 (documentation)

## Verification Summary

Use the scripts under `/tools` or see  
[`docs/VERIFY.md`](docs/VERIFY.md) for manual verification steps.

**Release status:** `ARCHIVE_LOCKED`  
**Integrity:** Verified (hash + signature OK)  
**Maintainer key fingerprint:** `SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys`
