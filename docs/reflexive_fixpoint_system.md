# Reflexive Fixed-Point System (RFS) --- doc-only

Version: 1.0.0  
Status: Informational (K0-external, documentation-only)  
Policy: ASCII-only, LF-only, final newline

## 1. Purpose

RFS defines a minimal documentation scaffold used alongside the K0 kernel. It fixes a divergence literal and a non-expansivity claim on an admissible subset. RFS introduces no kernel objects and makes no world-claims; it provides doc-only anchors that CI can verify.

## 2. Scope and boundaries

- **K0 isolation:** RFS defines no kernel IDs and binds none.
- **Doc-only location:** all RFS content lives in `docs/rfs/`.
- **Operators referenced:** names are ASCII identifiers THETA, PHI, LAMBDA, T. Their semantics are not enforced by K0; they are placeholders for documentation.
- **RELATION:** not used at K0.
- **ASCII discipline:** 7-bit ASCII only in this file. In math zones use TeX macros (e.g., `\circ`, `\le`, `\subseteq`), not Unicode glyphs.

## 3. Mandatory literals (MUST appear verbatim)

These three lines are the doc-level anchors. CI searches for these exact byte sequences.
