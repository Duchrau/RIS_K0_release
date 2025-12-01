````markdown
# CONSUMERS — Quick Verification & Usage (RIS K0)

> Pending references to fill before publishing:
>
> * Bundle filename: `__________________________.zip`
> * Expected maintainer fingerprint (ED25519, SSH-style): `__________________________`
> * Release tag: `__________________________`

Status: **ARCHIVE_LOCKED**  
Scope: minimal, machine-checkable verification for end-users. No re-packing, no mutation.

---

## 0) Prerequisites

You need one of:

- **Windows (PowerShell 5/7)** with built-in `Get-FileHash` and `Expand-Archive` or `tar`/`unzip`
- **POSIX** shell with `sha256sum`, `unzip`, and OpenSSH (`ssh-keygen` ≥ 8.2 for `-Y verify`)

All steps are ASCII/LF-safe. Do not modify the ZIP or sidecars.

---

## 1) Files required (same directory)

- `RIS_K0_provenanced.zip`
- `RIS_K0_provenanced.zip.sha256`  
  Format: `<64-hex>␠␠<filename>` (two spaces). The check only uses the 64-hex digest.

---

## 2) Verify ZIP integrity

### PowerShell (Windows)
```powershell
$zip  = ".\RIS_K0_provenanced.zip"
$side = ".\RIS_K0_provenanced.zip.sha256"
$h    = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$ref  = ([regex]::Match((Get-Content $side -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
if ($h -ne $ref) { throw "SHA256 mismatch" } else { "OK: SHA256 matches" }
````

### POSIX

```sh
sha256sum -c RIS_K0_provenanced.zip.sha256
# Expected output ends with: OK
```

If the hash does not match, **reject** the bundle.

---

## 3) Extract the bundle

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

## 4) Verify signature (OpenSSH)

The bundle includes:

* `provenance/byte_hash.txt`         # canonical byte digest of the ZIP
* `provenance/byte_hash.txt.sig`     # signature over the above
* `provenance/allowed_signers.txt`   # SSH allowed signers line(s)

### POSIX and Windows (OpenSSH)

```sh
ssh-keygen -Y verify \
  -f provenance/allowed_signers.txt \
  -I maintainer \
  -n RIS_K0 \
  -s provenance/byte_hash.txt.sig < provenance/byte_hash.txt
```

Expected: verification success with the maintainer identity.

Optionally confirm the maintainer key fingerprint:

```sh
awk '{print $2}' provenance/allowed_signers.txt | ssh-keygen -lf - | sed 's/ (ED25519).*//'
# Compare to the expected fingerprint published with the release.
```

If signature verification fails, **reject** the bundle.

---

## 5) Manifest match (recommended)

Ensure the ZIP contents equal the declared manifest.

Minimal visual check:

* Open `provenance/manifest.json` and note the `files[].path` list (paths use `/` separators).
* List entries from the extracted tree and confirm the set matches (directory entries may be omitted in the manifest).

If you have `unzip`:

```sh
unzip -Z1 RIS_K0_provenanced.zip | sed 's|\\|/|g' | sort > /tmp/zip.lst
# Compare with the manifest paths (sorted); they must match 1:1.
```

A mismatch indicates a packaging error. Prefer **reject**.

---

## 6) Final state check

Open `provenance/provenance.json` and confirm:

* `"status": "ARCHIVE_LOCKED"`
* `"zip_sha256"` equals the value verified in step 2
* `"signing"` section references `byte_hash.txt` and `byte_hash.txt.sig`
* Any optional semantic hash or policy fields match the release notes

Anything else → **reject**.

---

## 7) Usage and constraints

* Do **not** re-pack or re-sign the ZIP.
* Keep the sidecars (`.sha256`, and `provenance/*`) next to the ZIP if you redistribute it.
* Documentation under `docs/` is ASCII/LF and machine-linted.
* RFS and FPC are **informational**; they do not introduce kernel IDs.

---

## Troubleshooting

* **SHA256 mismatch:** file corrupted or different ZIP; re-download.
* **Signature verify fails:** wrong `allowed_signers.txt` or tampered `byte_hash.txt`; do not trust the artifact.
* **Manifest mismatch:** packaging error; contact the maintainer.
* **OpenSSH missing `-Y`:** update OpenSSH (8.2+). On Windows, enable the OpenSSH client feature.

---

Verification complete.

```


