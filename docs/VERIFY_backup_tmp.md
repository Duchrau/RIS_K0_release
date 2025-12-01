# VERIFY --- Full Verification Procedure (RIS K0)

Canonical, platform-neutral verification for the frozen RIS K0 release bundle.

Status: ARCHIVE_LOCKED. No network access required.

------------------------------------------------------------------------

## 1) Scope

This document validates the released artifact only. If future governance adds additional attestations, they will be appended as a new section; the core flow below remains unchanged.

------------------------------------------------------------------------

## 2) Inputs (same directory)

Required files:

- RIS_K0_provenanced.zip
- RIS_K0_provenanced.zip.sha256 ← GNU sidecar format with two spaces between hash and filename

Reject immediately if either file is missing.

------------------------------------------------------------------------

## 3) ZIP integrity (SHA256)

### PowerShell
```powershell
$zip = 'RIS_K0_provenanced.zip'
$sf = 'RIS_K0_provenanced.zip.sha256'
$h = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content $sf -Raw),'(?i)\b[0-9a-f]{64}\b')).Value.ToLower()
If ($h -ne $ref) { throw "SHA256 mismatch"; } else { "OK: SHA256" }
