# VERIFY — Full Verification Procedure (RIS K0)

Canonical, deterministic verification steps for the RIS K0 release.
All commands are platform-neutral and ASCII/LF-safe.

Status: **ARCHIVE_LOCKED**

---

## 1) Inputs

You must have these files in the same directory:

* `RIS_K0_provenanced.zip`
* `RIS_K0_provenanced.zip.sha256`
  Sidecar format: `<64-hex>␠␠RIS_K0_provenanced.zip` (two spaces between hash and filename).

Do not modify the ZIP or sidecars.

---

## 2) Verify ZIP integrity (SHA256)

### PowerShell (Windows)

```powershell
$zip  = ".\RIS_K0_provenanced.zip"
$side = ".\RIS_K0_provenanced.zip.sha256"
$h    = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$ref  = ([regex]::Match((Get-Content $side -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
if ($h -ne $ref) { throw "SHA256 mismatch" } else { "OK: SHA256 matches" }
```

### POSIX

```sh
sha256sum -c RIS_K0_provenanced.zip.sha256
# Expected output ends with: OK
```

If the hash check fails, **reject** the bundle.

---

## 3) Extract bundle

### PowerShell

```powershell
# Either:
Expand-Archive -Path .\RIS_K0_provenanced.zip -DestinationPath .\extracted
# Or (Windows tar):
tar -xf RIS_K0_provenanced.zip -C .
```

### POSIX

```sh
unzip RIS_K0_provenanced.zip
```

Result (authoritative list is in `provenance/manifest.json`):

```
./bundle_root/...
./provenance/
./provenance/manifest.json
```

---

## 4) Provenance checks (signature)

The bundle includes:

* `provenance/byte_hash.txt`       # canonical byte digest of the ZIP
* `provenance/byte_hash.txt.sig`   # detached signature over the digest
* `provenance/allowed_signers.txt` # SSH allowed-signers entry

Verify the signature (OpenSSH 8.2+):

```sh
ssh-keygen -Y verify \
  -f provenance/allowed_signers.txt \
  -I maintainer \
  -n RIS_K0 \
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt
```

Expected: verification succeeds for identity `maintainer`.
If signature verification fails, **reject** the bundle.

Optionally confirm the maintainer’s ED25519 fingerprint:

```sh
awk '{print $2}' provenance/allowed_signers.txt | ssh-keygen -lf - | sed 's/ (ED25519).*//'
```

---

## 5) Manifest match (recommended)

Ensure the ZIP contents equal the declared manifest paths.

* Open `provenance/manifest.json` and inspect `files[].path` (paths use `/`).
* Compare with the entries in the extracted tree (directory entries may be omitted in the manifest).

If you have `unzip`:

```sh
unzip -Z1 RIS_K0_provenanced.zip | sed 's|\\|/|g' | sort > /tmp/zip.lst
# Compare /tmp/zip.lst with the sorted manifest paths; they must match 1:1.
```

Any mismatch indicates a packaging error. Prefer **reject**.

---

## 6) Final state check

Open `provenance/provenance.json` and confirm:

* `"status": "ARCHIVE_LOCKED"`
* `"zip_sha256"` matches the value verified in step 2
* `"signing"` references `byte_hash.txt` and `byte_hash.txt.sig` (same files you used)
* Any optional semantic or policy fields match the published release notes

If any check fails, **reject**.

---

Verification complete.
