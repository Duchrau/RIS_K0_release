# Fixpoint Core (FPC) --- doc-only

Version: 1.0.0\
Status: Informational (K0 doc-only)\
Policy: ASCII-only, LF-only, final newline

## 1. Purpose

FPC defines a minimal, machine-checkable scaffold for documenting
fixpoint behavior alongside the K0 kernel. At K0, idempotence is treated
as an axiom (documentation-level only). At K1, a factorization route is
documented that can justify idempotence under additional structure. FPC
introduces no kernel objects and enforces no runtime semantics.

## 2. Scope and boundaries

- K0 isolation: no kernel IDs, no RELATION usage, no automatic mapping
  to kernel.

- Location: this file must live in docs/metaframe/.

- Operators are names only (ASCII identifiers): THETA, PHI, LAMBDA, F,
  T.

- ASCII discipline: 7-bit ASCII in prose; inside $$ use TeX macros
  (\\circ, \\le, \\subseteq) instead of Unicode glyphs.

- PRE_FORMAL blocks: allowed; must follow the FSM in Section 5.

## 3. Vocabulary (informal, doc-only)

- W: workspace (a set or carrier space)

- W_r: admissible region inside W

- THETA, PHI, LAMBDA: W -> W: documentation placeholders for
  transformations

- F: W -> W: documentation placeholder for a normalization map

- T: W -> W: the documented "update" map

No kernel meaning is attached at K0. These are documentation hooks to
make statements precise and CI-checkable.

## 4. K0: axioms (doc-only, not derived)

At K0, FPC asserts the following **as axioms** over the admissible
region W_r:

- T(W_r) subset_of W_r

- T(T(w)) = T(w) on W_r

Explicit note: idempotence at K0 is an axiom. It is **not** claimed to
follow from weaker conditions at K0.
