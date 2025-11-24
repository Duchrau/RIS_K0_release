# CONSUMERS — Quick Verification & Usage (RIS K0)

This is the minimal verification path for end-users.

Status: **ARCHIVE_LOCKED**

---

## 1) Files required (same directory)

- `RIS_K0_provenanced.zip`
- `RIS_K0_provenanced.zip.sha256`
  Format: **two spaces** between hash and filename.

---

## 2) Verify ZIP integrity

### PowerShell
$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$h -eq $ref

### POSIX
sha256sum -c RIS_K0_provenanced.zip.sha256

If mismatch → reject.

---

## 3) Extract the bundle
unzip RIS_K0_provenanced.zip

Result:
- bundle_root/
- provenance/

---

## 4) Verify signature
ssh-keygen -Y verify `
  -f provenance/allowed_signers.txt `
  -I maintainer `
  -n RIS_K0 `
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt

Expected ED25519 fingerprint:
SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys

If invalid → reject.

---

## 5) Check final state
Open provenance/provenance.json  
Required:

status = "ARCHIVE_LOCKED"

Anything else → reject.

---

Verification complete.
