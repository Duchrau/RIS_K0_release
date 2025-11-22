# CONSUMERS — ultra-short

1) Legt `RIS_K0_provenanced.zip` und `.sha256` in denselben Ordner.

2) Hash prüfen (PowerShell)
$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$h -eq $ref

3) Signatur prüfen (cmd.exe)
ssh-keygen -Y verify -f provenance\allowed_signers.txt -I maintainer -n RIS_K0 -s provenance\byte_hash.txt.sig ^< provenance\byte_hash.txt

Expected signer fingerprint (ED25519):
SHA256:En+c93lQGMAnjkd680oK0DPKYq3tpZ4ug8QXnjTiZys

4) Danach ZIP normal entpacken. Nicht repacken.
