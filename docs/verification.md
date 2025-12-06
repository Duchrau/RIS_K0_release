# Verification

This document describes the verification process for K0 releases.

## Current Release Hashes (v1.0.0)

### Primary Integrity Checks
- **Bundle**: 882F93CB3E2056458F27786BFC43ED66BF019805C1A0CF88289EC2A152C046A5
- **Byte-Level**: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
- **Source**: 1764633600

### Verification Script
The primary verification script is \erify_all.ps1\. It performs:

1. Directory structure validation
2. File existence checks
3. JSON validation
4. Hash verification
5. Provenance validation

### Manual Verification
\\\powershell
# Check bundle hash
Get-FileHash release/K0_bundle.zip -Algorithm SHA256

# Compare with recorded hash
Get-Content release/K0_bundle.zip.sha256

# Run full verification
./verify_all.ps1
\\\

### CI Verification
The GitHub workflow \erify-k0.yml\ runs automatic verification on all pushes and pull requests.


## Toolchain Pin

ZIP_WRITER_PIN: 7-Zip 24.07
Flags: a -tzip -mx=9 -mm=Copy -mtm=on -mtc=off -mta=off -mcu=on -i@files_v1_0_1.lst
