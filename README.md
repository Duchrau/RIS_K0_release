# RIS K0 — canonical release (provenanced + signed)

Download: https://github.com/Duchrau/RIS_K0_release/releases/latest

Artifacts:
- RIS_K0_provenanced.zip
- RIS_K0_provenanced.zip.sha256

Verify (PowerShell):
$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$h -eq $ref

Verify signature (cmd.exe):
ssh-keygen -Y verify -f provenance\allowed_signers.txt -I maintainer -n RIS_K0 -s provenance\byte_hash.txt.sig < provenance\byte_hash.txt

Allowed signer fingerprint (ED25519): SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys

Status: ARCHIVE_LOCKED
