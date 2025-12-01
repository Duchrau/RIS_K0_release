# CONSUMERS --- Quick Verification & Usage (RIS K0)

**Hinweis:** Folgende Referenzen sind vor der Veröffentlichung auszufüllen:

- Bundle filename: `____________________`.zip
- Expected maintainer fingerprint (ED25519, SSH-style): `____________________`
- Release tag: `____________________`

Status: ARCHIVE_LOCKED  
Scope: minimal, machine-checkable verification for end-users. No re-packing, no mutation.

------------------------------------------------------------------------

## 1) Prerequisites

You need one of:

### Windows (PowerShell 5/7)
- Get-FileHash (built-in)
- tar/Expand-Archive or unzip

### POSIX shell
- sha256sum
- unzip  
- OpenSSH (ssh-keygen ≥ 8.2 for -Y verify)

**Wichtig:** Alle Schritte sind ASCII/LF-safe. Das ZIP oder Sidecars nicht modifizieren.

------------------------------------------------------------------------

## 2) Required files (same directory)

- RIS_K0_provenanced.zip
- RIS_K0_provenanced.zip.sha256

Format ist standard: `<64-hex>  <filename>` (zwei Leerzeichen). Geringe Whitespace-Unterschiede beeinflussen die Hash-Prüfung nicht.

Optional aber empfohlen:
- RIS_K0_provenanced.zip.sha512

------------------------------------------------------------------------

## 3) Verify ZIP integrity

### PowerShell (Windows)
```powershell
$zip = ".\RIS_K0_provenanced.zip"
$side = ".\RIS_K0_provenanced.zip.sha256"
$h = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content $side -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
If ($h -ne $ref) { throw "SHA256 mismatch" } else { "OK: SHA256 matches" }
