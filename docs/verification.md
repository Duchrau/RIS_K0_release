# VERIFICATION — Canonical Procedure (RIS K0)

Deterministic, platform-neutral steps to verify the **RIS K0** release bundle and its provenance.

Status: **ARCHIVE_LOCKED**

---

## 0) Scope

This document covers integrity, signature, manifest, and state checks for the canonical asset:

* `RIS_K0_provenanced.zip`
* `RIS_K0_provenanced.zip.sha256`  *(GNU sidecar, two spaces between hash and filename)*

Do not modify the ZIP or sidecars.

---

## 1) Prerequisites

Use one of the following environments:

* **Windows**: PowerShell 5/7, built-in `Get-FileHash`, `Expand-Archive` or `tar`, OpenSSH (for `ssh-keygen -Y verify`).
* **POSIX**: `sha256sum`, `unzip`, OpenSSH ≥ 8.2 (for `-Y verify`).

All files are ASCII/LF; verification is offline.

---

## 2) ZIP integrity (SHA256)

### PowerShell (Windows)

```powershell
$zip  = ".\RIS_K0_provenanced.zip"
$side = ".\RIS_K0_provenanced.zip.sha256"
$h    = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$ref  = ([regex]::Match((Get-Content $side -Raw),'(?i)\b[0-9a-f]{64}\b')).Value.ToLower()
if ($h -ne $ref) { throw "SHA256 mismatch" } else { "OK: SHA256 matches" }
```

### POSIX

```sh
sha256sum -c RIS_K0_provenanced.zip.sha256
# Expected: line ends with "OK"
```

**Fail → reject** the bundle.

---

## 3) Extract bundle

### PowerShell

```powershell
# Option A (PowerShell):
Expand-Archive -Path .\RIS_K0_provenanced.zip -DestinationPath .\extracted
# Option B (Windows tar):
tar -xf RIS_K0_provenanced.zip -C .
```

### POSIX

```sh
unzip RIS_K0_provenanced.zip
```

Result (authoritative list is `provenance/manifest.json`):

```
./bundle_root/...
./provenance/
./provenance/manifest.json
```

---

## 4) Signature verification (OpenSSH)

The bundle includes:

* `provenance/byte_hash.txt`       # canonical byte digest
* `provenance/byte_hash.txt.sig`   # detached signature over the digest
* `provenance/allowed_signers.txt` # SSH allowed-signers entry

Verify:

```sh
ssh-keygen -Y verify \
  -f provenance/allowed_signers.txt \
  -I maintainer \
  -n RIS_K0 \
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt
```

Expected: verification succeeds for identity `maintainer`.
**Fail → reject** the bundle.

Optional: print the signer fingerprint for comparison with the release notes:

```sh
awk '{print $2}' provenance/allowed_signers.txt | ssh-keygen -lf - | sed 's/ (ED25519).*//'
```

---

## 5) Manifest congruence (recommended)

Ensure ZIP entries equal the manifest’s path set (paths use `/`).

* Open `provenance/manifest.json`, read `files[].path`.
* Compare to the ZIP entries (directory placeholders may be omitted in the manifest).

If `unzip` is available:

```sh
unzip -Z1 RIS_K0_provenanced.zip | sed 's|\\|/|g' | sort > /tmp/zip.lst
# Compare /tmp/zip.lst with a sorted list of manifest paths. Must match 1:1.
```

Mismatch → packaging error → prefer **reject**.

---

## 6) Final state

Open `provenance/provenance.json` and confirm:

* `"status": "ARCHIVE_LOCKED"`
* `"zip_sha256"` equals the value from step 2
* `"signing"` references `byte_hash.txt` and `byte_hash.txt.sig`

Any deviation → **reject**.

---

## 7) Redistribution rules

* Do **not** re-pack or re-sign the ZIP.
* Distribute the ZIP **with** its sidecars (`.sha256`, optional `.sha512`, and `provenance/*`).
* Documentation inside `bundle_root/docs/` is ASCII/LF and machine-linted.
* RFS/FPC files are **informational**; they do not introduce kernel IDs.

---

## Troubleshooting

* **SHA256 mismatch**: corrupted or wrong file → re-download.
* **Signature verify fails**: wrong `allowed_signers.txt` or tampering → do not trust.
* **Manifest mismatch**: packaging error → contact maintainer.
* **`ssh-keygen: unknown option -Y`**: upgrade OpenSSH (8.2+). On Windows, enable the OpenSSH Client feature.

---

Verification complete.
