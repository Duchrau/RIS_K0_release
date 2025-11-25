[![verify](https://github.com/Duchrau/RIS_K0_release/actions/workflows/verify.yml/badge.svg)](https://github.com/Duchrau/RIS_K0_release/actions/workflows/verify.yml)

#RIS K0 — Provenanced Model (ARCHIVE_LOCKED)

This repository provides the frozen, provenance-verified RIS K0 release bundle.
All integrity, signature and provenance data is immutable.

Status: **ARCHIVE_LOCKED**

---

## Quick Verify

### 1) Required files (same directory)
- `RIS_K0_provenanced.zip`
- `RIS_K0_provenanced.zip.sha256`  
  (GNU format: **two spaces** between hash and filename)

### 2) SHA256 check

**PowerShell**
```powershell
$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$h -eq $ref
POSIX

sh
Code kopieren
sha256sum -c RIS_K0_provenanced.zip.sha256
3) Extract
sh
Code kopieren
unzip RIS_K0_provenanced.zip
Results:

bundle_root/

provenance/

4) Signature verification
sh
Code kopieren
ssh-keygen -Y verify \
  -f provenance/allowed_signers.txt \
  -I maintainer \
  -n RIS_K0 \
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt
Expected ED25519 fingerprint:

ruby
Code kopieren
SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys
5) Final state
Open:

bash
Code kopieren
provenance/provenance.json
Required:

ini
Code kopieren
status = "ARCHIVE_LOCKED"
Documentation
Quick verification: [CONSUMERS.md](CONSUMERS.md)

Full verification: [VERIFY.md](VERIFY.md)

Technical overview (Markdown): [Overview.md](Overview.md)

Technical overview (PDF): [Overview.pdf](Overview.pdf)

Release Facts
makefile
Code kopieren
ZIP:                  RIS_K0_provenanced.zip
ZIP_SHA256:           (see RIS_K0_provenanced.zip.sha256)
BYTE_HASH_SHA512:     contents of provenance/byte_hash.txt
SEMANTIC_NS_SHA256:   contents of provenance/semantic_hash_ns.txt
SIGNER_FPR:           SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys
STATUS:               ARCHIVE_LOCKED
Bundle Layout
pgsql
Code kopieren
bundle_root/
  README.txt
  views/
  spec/
  kernel/
    objects_K0.json
  reports/
    kernel_stats.tsv
  logs/
    migration_log.tsv
  docs/ (optional)

provenance/
  manifest.json
  provenance.json
  semantic_hash_ns.txt
  source_date_epoch.txt
  byte_hash.txt
  byte_hash.txt.sig
  allowed_signers.txt
This repository contains the canonical, frozen RIS K0 bundle with full reproducible provenance and signature verification.
---

## Related Non-Normative Releases

### [RIS_RFS_release](https://github.com/Duchrau/RIS_RFS_release)
*Reflexive Fixed-Point System (non-normative background release)*  
Defines minimal operator conditions under which reflexive transformations become locally idempotent.  
Independent from the RIS Kâ‚€ kernel; provides theoretical scaffolding for recursive invariance.



