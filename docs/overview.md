# RIS K0 --- Technical Overview (Provenanced Model)

**Hinweis:** Folgende Referenzen sind vor der Veröffentlichung auszufüllen:

- Release tag: `____________________`
- Bundle filename: `____________________`.zip
- Expected maintainer fingerprint (ED25519, SSH-style): `____________________`
- Source-Date-Epoch (optional): `____________________`
- Semantic namespace hash (optional): `____________________`

Status: ARCHIVE_LOCKED  
Scope: Technical overview of RIS K0 release bundle structure and verification.

---

## 1. Release Structure

The canonical release consists of:
1. RIS_K0_provenanced.zip
2. RIS_K0_provenanced.zip.sha256

## 2. Verification Overview

### 2.1 ZIP Integrity (SHA256)
Hash file: RIS_K0_provenanced.zip.sha256

### 2.2 Provenance and Signature (OpenSSH)
All provenance files in `provenance/` folder.

## 3. Provenance Model

Four components:
1. Semantic namespace (optional)
2. Deterministic build origin  
3. Byte-level integrity
4. Manifest and meta-record

## 4. Policies

- ARCHIVE_LOCKED: no re-packing
- UTF-8 without BOM, LF only
- ASCII discipline in docs
