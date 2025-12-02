# RIS K0 – DIRECTORY SPEC v1.0
Status: NORMATIVE
Encoding: UTF-8 (LF)

## Purpose
Defines the required top-level directory layout for a valid RIS K0 repository and release.

## Required Top-Level Directories (normative)
- bundle_root/
- spec/
- tools/

## Optional (non-normative)
- docs/
- provenance/        (working copy, never part of release)
- devtools/
- logs/
- tmp/
- anything else not referenced by K0

## Release ZIP Rules
release/K0_bundle.zip MUST contain:
- bundle_root/**
- spec/**
- tools/** (only normative tools)
- NO docs/**
- NO provenance/**          (the repo working copy)
- NO tmp/**

## End of File


## Provenance Rules
release/provenance/ MUST contain exactly:
- manifest.json
- semantic_hash_ns.txt
- source_date_epoch.txt
- byte_hash.txt
- byte_hash.txt.sig (optional)
- provenance.json

No additional files are permitted.

The repository-level provenance/ directory is NOT part of any release and MUST be ignored by normative processes.

