# VERIFY — Full Verification Procedure (RIS K0)

This document defines the canonical verification steps for the RIS K0 release.
All commands are deterministic and platform-neutral.

Status: **ARCHIVE_LOCKED**

---

## 1. Inputs

You must have the two release assets in the same directory:

RIS_K0_provenanced.zip
RIS_K0_provenanced.zip.sha256

Sidecar format: **two spaces** between hash and filename.

---

## 2. ZIP integrity (SHA256)

### PowerShell
$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$h -eq $ref

### POSIX
sha256sum -c RIS_K0_provenanced.zip.sha256

If false or non-zero exit code → reject.

---

## 3. Extract bundle

unzip RIS_K0_provenanced.zip

Resulting tree:

bundle_root/
provenance/

---

## 4. Provenance checks

1. Read provenance/manifest.json
2. Read provenance/byte_hash.txt
3. Verify signature:

ssh-keygen -Y verify \
  -f provenance/allowed_signers.txt \
  -I maintainer \
  -n RIS_K0 \
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt

Expected signer fingerprint (ED25519):
SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys

If signature invalid → reject.

---

## 5. Final state check

Open:
provenance/provenance.json

Required:
status = "ARCHIVE_LOCKED"

If any other value → reject.

---

Verification complete.
