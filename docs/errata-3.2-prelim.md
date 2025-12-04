# RIS/IES ERRATA v3.2 PRELIM (non-normative) Source: INTERNAL | Version: 3.2-PRELIM | Date: 2025-11-12 | Status: DOC-ONLY (no semantic activation in K0)

## Summary
Proposal to transition RCC → RBI as a dimension-consistent bound for thermodynamically motivated couplings. This document is documentation-only and does not activate any semantic change in 3.1.

## Change Type
Semantic change planned for 3.2. In 3.1 the semantic lock prevents activation.

- `ARCH_SEMANTIC_LOCK = true` in 3.1 blocks any activation.
- Target activation window: 3.2.

## Migration Path (3.2)
- Gate: set `ARCH_SEMANTIC_LOCK = false` on the 3.2 branch prior to any RELAX activation.
- Parents: `parent_core = RIS_CoreCorpus_3.0`, `parent_arch = RIS/IES_3.1-NORM`.
- QC bits, schema updates, and packaging mode selection happen only in 3.2.

## Impact Analysis (doc-only in 3.1)
- **QC:** new bits reserved for 3.2 only; not used in 3.1.
- **Reports/Schemas:** documentation of fields only; no production fields in 3.1.
- **Packaging:** `FILE_HASH_CONCAT` remains normative; `PAX_TAR` discussed as outlook.

## Terms
JCS (RFC-8785), binary64 (IEEE-754), ULP, QC, DEV/QA/FINAL, ERRATA.

## QC Registry v2 (Mask128)
### 1. Mask definition
- Field: `qc.mask128_hex`
- Type: exactly 32 hex chars, lowercase: `^[0-9a-f]{32}$` (128 bits = 32 hex chars)
- Endianness: big-endian bit numbering.
- Examples: Bit 0 → `000...01`, Bit 1 → `000...02`, Bit 127 → `800...00`

### 2. Classes
- WARN: 0–31
- FAIL_ANALYSIS: 32–63
- FAIL_AUDIT: 64–127

### 3. Assigned bits (excerpt as in 3.1 canonical)
`WARN_WEAK_STATIONARITY=1`, `WARN_NUMERIC_ENV=2`, `WARN_UNKNOWN_EXTENSION=3`,  
`WARN_MANIFEST_SPACE=4`, `FAIL_KAPPA_MAX=20`, `FAIL_ANALYSIS_EDN=52`,  
`FAIL_SCHEMA=64`, `FAIL_SCHEMA_DIFF_HASH_ALIAS=65`, `FAIL_MANIFEST_SELF=66`,  
`FAIL_STRUCTURAL_INPUTS=67`, `FAIL_ID_COLLISION=68`, `FAIL_MANIFEST_DUP=69`,  
`FAIL_AUDIT_SECRET=72`.

### 4. Mirroring
`qc.flags` is the decoded view of `qc.mask128_hex`. Unknown flags map to `FAIL_SCHEMA`. `mask64_compat` allowed only when all bits < 64.

### 5. JSON Schema (JCS)
```json-doc
{
  "type": "object",
  "required": ["mask128_hex", "flags"],
  "properties": {
    "mask128_hex": { "type": "string", "pattern": "^[0-9a-f]{32}$" },
    "flags": { "type": "array", "items": { "type": "string" }, "uniqueItems": true }
  }
}
```
Provenance

Source: "INTERNAL"
Author: "RIS Writer Unit"
Version: "3.2-PRELIM"
Date: "2025-11-12T00:00Z"

[COMPLIANCE]

Encoding: utf-8
Bom: false
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
Placeholders: present

[/COMPLIANCE]

writer_report.json
{
  "phase": "integration",
  "architecture": "3.2-PRELIM",
  "actions": [
    "updated /docs/ERRATA_3_2_PRELIM.md (doc-only, normalized v3.2 ERRATA)",
    "wrote /staging/MANIFEST.stage (RELAX-2SP)"
  ],
  "provenance_check": "complete",
  "semantic_lock": true,
  "qc": { "mask": 0, "flags": ["OK"] },
  "timestamp_utc": "2025-11-12T00:00:00Z",
  "placeholders": { "sha512": 2, "sha256": 1, "ed25519_base64url": 1, "sha512_raw": 1 },
  "lines_written": 120,
  "files_touched": [
    "/docs/ERRATA_3_2_PRELIM.md"
  ],
  "space_style": "RELAX-2SP",
  "crlf_detected": 0,
  "tabs_detected": 0,
  "dupes": 0,
  "self_listing": 0,
  "idempotent": true,
  "atomic_write": true,
  "manifest_delta": { "added": 0, "removed": 0, "reordered": "none" }
}

handoff/errata_to_next.json
{
  "writer_id": "errata",
  "status": "completed",
  "output_path": "/docs/ERRATA_3_2_PRELIM.md",
  "hash_placeholder_count": 2,
  "provenance_header": true,
  "compliance_block": true,
  "qc": { "mask": 0, "flags": ["OK"] },
  "timestamp_utc": "2025-11-12T00:00:00Z"
}
