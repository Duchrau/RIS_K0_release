# RIS K0 --- Technical Deep Dive

Status: ARCHIVE_LOCKED  
Scope: Technical details of the RIS K0 release, bundle structure, and verification mechanisms.

---

## 1. Bundle Composition

The RIS K0 Bundle follows a strict layered model:

### 1.1 Core Layer
- `bundle_root/` – Core model content
  - `kernel/objects_K0.json` – Kernel object definitions
  - `views/` – Derived representations
  - `reports/` – Statistical analyses
  - `logs/` – Migration and operations logs

### 1.2 Documentation Layer
- `docs/` – Public documentation
  - All files are UTF-8 (no BOM), LF-only
  - ASCII-only where possible, TeX macros for mathematics
  - RFS/FPC as doc-only, no kernel IDs

### 1.3 Provenance Layer
- `provenance/` – Integrity and authentication data
  - Complete verification chain from byte-level to signature
  - Deterministic build metadata
  - Machine-readable manifests

---

## 2. Verification Architecture

### 2.1 Multi-Layer Verification
1. **Byte Integrity** – SHA256/SHA512 over ZIP
2. **Structural Integrity** – Manifest matching
3. **Semantic Integrity** – Namespace hash (optional)
4. **Authenticity** – ED25519 signature over byte-hash
5. **State Verification** – ARCHIVE_LOCKED status

### 2.2 Tooling Requirements
- **Windows:** PowerShell 5+, OpenSSH Client, Get-FileHash
- **POSIX:** sha256sum, unzip, OpenSSH ≥ 8.2
- **Cross-platform:** Git (for OpenSSH on Windows)

---

## 3. Deterministic Build Principles

### 3.1 Fixed Parameters
- SOURCE_DATE_EPOCH – UNIX timestamp for reproducible builds
- Locale: C (fixed for string operations)
- Encoding: UTF-8 without BOM, LF line endings
- Path normalization: forward slashes (/) in all manifests

### 3.2 Text Discipline
- All text files: final newline required
- ASCII-only in core paths (provenance/, manifest.json)
- TeX macros instead of Unicode in mathematics
- PRE_FORMAL blocks with strict FSM

---

## 4. Security Considerations

### 4.1 Signature Scheme
- Algorithm: ED25519 (via OpenSSH ssh-keygen)
- Signature over byte-hash, not over ZIP directly
- Allowed-signers file with specific namespace (-n RIS_K0)
- Fingerprint verification optional but recommended

### 4.2 Tamper Resistance
- ARCHIVE_LOCKED status prevents re-packaging
- Sidecar hashes must stay next to ZIP
- Manifest matching detects structure changes
- Signature verification requires correct namespace

---

## 5. Extension Points

### 5.1 Optional Components
- Semantic namespace hash – for conceptual identification
- Source date epoch – for build reproducibility
- Additional attestations – future governance extensions

### 5.2 Versioning
- K0 – current version, archive-locked
- K1 – documented factorization route (doc-only)
- Future versions – governed by governance process

---

## 6. Best Practices for Consumers

### 6.1 Verification Workflow
1. Always run complete verification path
2. Verify maintainer key fingerprint
3. Don't skip manifest matching
4. Check for ARCHIVE_LOCKED status

### 6.2 Distribution Guidelines
- Always distribute ZIP and sidecars together
- Don't modify the bundle
- If uncertain: run complete verification again
- Contact maintainer on verification failures

---

## 7. Compliance and Auditing

### 7.1 Audit Trail
- All verification steps are deterministic
- Each step has binary pass/fail criteria
- Complete provenance chain is machine-verifiable
- Status transitions are documented

### 7.2 Reproducibility
- Bundle can be reproduced from verified sources
- All build parameters are documented
- Verification is platform-independent
- Results are deterministic and comparable

---

This technical overview describes the architecture and principles behind the RIS K0 release bundle.
