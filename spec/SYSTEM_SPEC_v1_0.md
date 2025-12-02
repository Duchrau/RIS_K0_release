# RIS K0 – SYSTEM SPEC v1.0
Status: NORMATIVE
Encoding: UTF-8 (LF)

## Purpose
Defines the minimal system-wide invariants required for deterministic verification of a RIS K0 release.

## Hashing
- Primary hash: SHA-256 (lowercase hex).
- Used for:
  - K0_bundle.zip
  - provenance/semantic_hash_ns.txt
  - provenance/byte_hash.txt

No alternative hash formats allowed.

## Determinism
- All normative content MUST be ASCII or UTF-8 (LF), without BOM.
- No timestamps except source_date_epoch.txt inside release/provenance/.
- No file mtimes, system times or builder-dependent markers may appear in normative artifacts.

## Normative Scope
Normative files and directories:
- bundle_root/**
- spec/**
- tools/** (only normative tools listed in GOVERNANCE_SPEC)
- release/provenance/manifest.json
- release/provenance/semantic_hash_ns.txt
- release/provenance/source_date_epoch.txt
- release/provenance/byte_hash.txt
- release/provenance/provenance.json

Non-normative:
- docs/**
- provenance/**          (repo working copy)
- devtools/**, logs/**, tmp/**, etc.

## JSON Requirements
- UTF-8 (LF)
- No BOM
- ASCII-safe keys
- Exactly one final LF

## End of File


## Normative Provenance
Only the directory release/provenance/ is normative.

Normative Provenance files:
- manifest.json
- semantic_hash_ns.txt
- source_date_epoch.txt
- byte_hash.txt
- byte_hash.txt.sig (optional)
- provenance.json

No other files may appear in release/provenance/.

Repository-level provenance/ is non-normative and MUST be ignored by verification tools.

