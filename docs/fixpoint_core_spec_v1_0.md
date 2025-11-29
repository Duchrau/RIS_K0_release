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

## 5. PRE_FORMAL blocks: format rule (FSM)

For every PRE_FORMAL block in this file:

1.  The marker line is the only token on its line.

2.  The marker line is immediately followed by a line containing $$.

3.  Exactly one $$ ... $$ block per marker.

4.  Block content must be ASCII; use TeX macros, not Unicode.

5.  Allowed IDs here follow the regex\
    metaframe#(eq[0-9]+|eq_fact[0-9]+|L[0-9]+).

Example (format only):

[PRE_FORMAL id="metaframe#eq1"]

$$
x = x
$$

## 6. K1: factorization route (doc-only)

This section documents a standard route to idempotence when K1 is
explicitly enabled in governance. The following PRE_FORMAL entries
record the intended structure and the resulting form. The file itself
makes no kernel claim; enforcement is CI/documentation-only.

[PRE_FORMAL id="metaframe#eq_fact1"]

$$
T := F \\circ \\Lambda
$$

[PRE_FORMAL id="metaframe#eq_fact2"]

$$
F(F(x)) = F(x) \\ \\text{for all} \\ x \\in \\Lambda(W_r)
$$

[PRE_FORMAL id="metaframe#eq_fact3"]

$$
\\Lambda \\circ F = F \\ \\text{on} \\ W_r
$$

[PRE_FORMAL id="metaframe#eq_fact4"]

$$
T^2 = T \\ \\text{on} \\ W_r
$$

Clarification: eq_fact4 expresses the idempotent form of T. Whether it
**follows** from eq_fact1--eq_fact3 depends on adopting the K1 structure
above; it is **not** enforced nor derived at K0.

### Short derivation (illustrative, K1 context)

[PRE_FORMAL id="metaframe#L1"]

$$
T^2
= (F \\circ \\Lambda)(F \\circ \\Lambda)
= F \\, (\\Lambda F) \\, \\Lambda
= F \\, F \\, \\Lambda
= F \\circ \\Lambda
= T
$$

This uses eq_fact2 (idempotence of F on \\Lambda(W_r)) and eq_fact3
(saturation \\Lambda \\circ F = F on W_r).

## 7. Interaction with RFS

- RFS documents a divergence literal (KL on S_adm) and non-expansivity
  of PHI on S_adm, plus a closure statement for T over S_adm.

- FPC places no requirement on RFS and does not consume RFS IDs at K0.

- Any alignment between S_adm and W_r is documentation-only and out of
  K0 scope.

## 8. Author checklist (must pass before commit)

1.  Encoding and line endings

    - ASCII-only; LF-only; final newline present.

2.  K0 axioms present exactly as ASCII lines in Section 4

    - T(W_r) subset_of W_r

    - T(T(w)) = T(w) on W_r

    - Include the explicit note that idempotence at K0 is an axiom.

3.  PRE_FORMAL FSM satisfied for each block

    - Marker line [PRE_FORMAL id="metaframe#..."]

    - Next line is exactly $$

    - ASCII content only

    - Closing $$

    - Exactly one block per marker

    - IDs match metaframe#(eq[0-9]+|eq_fact[0-9]+|L[0-9]+)

4.  No Unicode glyphs

    - No curly quotes, primes, ≤, ∘, etc.

    - Use TeX macros inside math zones.

5.  No kernel coupling

    - No kernel IDs introduced; no RELATION objects referenced.

## 9. File location (canonical)

This file must be placed at:

docs/metaframe/fixpoint_core_spec_v1_0.md

Use lowercase docs/ (CI is case-sensitive).
