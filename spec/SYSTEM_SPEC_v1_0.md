RIS/IES System Specification v1.0
Source: INTERNAL
Status: BASELINE
Encoding: UTF-8 (LF)

Purpose
Defines system-wide invariants for hashing, IDs, determinism, and metadata handling.

System Invariants
- All hashes: SHA-512 (lowercase hex, 128 hex chars).
- Secondary hash forms: SHA-256 allowed only for subtree or policy_subhash.
- No MD5, SHA1, or truncated SHA variants allowed.

Identifiers
- UUIDv4 required for internal objects.
- Ed25519 public keys allowed for signature verification.
- No custom ID formats allowed.

Determinism
- Hashing must be stable across builders.
- No timestamps except controlled SOURCE_DATE_EPOCH or documented provenance blocks.
- No filesystem mtime usage inside semantic or audit layers.

Ordering Rules
- Lexicographic ordering for:
  - manifest entries
  - module lists
  - Merkle leaf concatenation

JSON Format Rules
- ASCII only where possible.
- UTF-8 allowed but must avoid BOM.
- Exactly one final newline.

Allowed Numeric Forms
- Binary64 floats only.
- Hex-float profile allowed for audit channel.
- No NaN, no Inf, no negative zero.

Metadata Requirements
Each file MAY contain:
- provenance block
- compliance block
- writer_report entry
- handoff entry

Metadata MUST be ASCII-safe and machine-parseable.

[COMPLIANCE]
Encoding: utf-8
Newline: \n
Tabs: 0
Trailing_spaces: 0
Final_lf: 1
[/COMPLIANCE]
