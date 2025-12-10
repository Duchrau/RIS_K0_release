# RIS K0 Core Release

This repository contains the normative specification, structure, and reproducible reference bundle of the K0 core.  
The content is organized into four layers:

1. Normative Specification (spec/)
2. Kernel Objects and Reference Bundle (undle_root/)
3. Verification and Provenance (elease/, erify_all.ps1)
4. Documentation and Conceptual Background (docs/)

The release bundle (K0_bundle.zip) is automatically generated from these files, fully reproducible and deterministic.

## Current Release: v1.0.0

### Integrity Hashes
- **Bundle SHA256**: 882F93CB3E2056458F27786BFC43ED66BF019805C1A0CF88289EC2A152C046A5
- **Byte-Level Hash**: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
- **Source Date Epoch**: 1764633600
- **Build Date**: 2025-12-03

### Bundle Contents
- undle_root/kernel/objects_K0.json - K0 kernel objects
- spec/SYSTEM_SPEC_v1_0.md - System specification
- spec/DIRECTORY_SPEC_v1_0.md - Directory structure
- spec/FILE_RULES_SPEC_v1_0.md - File rules
- spec/GOVERNANCE_SPEC_v1_0.md - Governance rules
- erify_all.ps1 - Verification script

### Verification
Run \./verify_all.ps1\ to validate the release integrity.

## Structure

- **bundle_root/kernel/**  
  Contains machine-readable K0 kernel objects (objects_K0.json).

- **spec/**  
  Normative system description: structure, file rules, governance, and directory layout.

- **release/**  
  Contains the generated, immutable release bundle and all provenance data.

- **docs/**  
  Conceptual and explanatory documentation, non-normative.

## Release Pipeline

A release is automatically generated when a * tag is pushed.  
The resulting bundle appears as a GitHub Release artifact.

## Provenance
Complete provenance metadata is available in elease/provenance/.


## Citation

If you reference RIS K0, please use the Zenodo Concept DOI:

**10.5281/zenodo.17872745**

This DOI always resolves to the newest version of the deterministic bundle.