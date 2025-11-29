# Reflexive Fixed-Point System (RFS) --- doc-only

Version: 1.0.0\
Status: Informational (K0-external, documentation-only)\
Policy: ASCII-only, LF-only, final newline

## 1. Purpose

RFS specifies the minimal documentation scaffold used alongside the K0
kernel. It fixes a divergence literal and a non-expansivity claim on an
admissible subset. RFS introduces no kernel objects and makes no
world-claims; it provides doc-only anchors that CI can verify.

## 2. Scope and boundaries

- **K0 isolation**: RFS defines no kernel IDs and binds none.

- **Doc-only**: All RFS content lives in docs/rfs/.

- **Operators referenced**: names are ASCII identifiers THETA, PHI,
  LAMBDA, T. Their semantics are **not** enforced by K0; they are
  placeholders for documentation.

- **RELATION**: not used at K0.

- **ASCII**: 7-bit ASCII only in this file. In math zones use TeX macros
  (e.g., \\circ, \\le, \\subseteq), not Unicode glyphs.

## 3. Mandatory literals (MUST appear verbatim)

These three lines are the doc-level anchors. CI searches for these exact
byte sequences.

{"type":"KL","support":"S_adm"}

forall x,y in S_adm: D(PHI(x), PHI(y)) <= D(x,y)

T(S_adm) subset_of S_adm

Interpretation (non-normative):

- The divergence used in RFS documentation is the **KL** type, asserted
  on the admissible subset S_adm.

- PHI is documented as **non-expansive** on S_adm w.r.t. the chosen
  divergence D.

- The transformation T is documented as **closed** over S_adm.

No kernel behavior follows from these lines at K0; they are
documentation claims tied to CI checks.

## 4. PRE_FORMAL blocks (format rule)

PRE_FORMAL markers are allowed in docs/rfs/ and must follow a strict
finite-state pattern:

- The marker line is the only token on its line.

- It is **immediately** followed by a line containing $$.

- Exactly one $$ ... $$ block per marker.

- Block content must be ASCII; use TeX macros only.

### Example PRE_FORMAL blocks (illustrative, ASCII-safe)

[PRE_FORMAL id="rfs#eq1"]

$$
\\rho' = f(\\rho)
$$

[PRE_FORMAL id="rfs#eq2"]

$$
f(\\rho^*) = 0
$$

[PRE_FORMAL id="rfs#eq3"]

$$
f'(\\rho^*) < 0
$$

The IDs are canonicalized as rfs#eqN with N being a positive integer.

## 5. Interaction with FPC

- RFS and FPC are independent documents.

- RFS sets a divergence literal and a non-expansivity claim on S_adm.

- FPC (in docs/metaframe/fixpoint_core_spec_v1_0.md) specifies a K0
  **axiom** for idempotence and a K1 **factorization route** that can
  yield idempotence as a **result** when additional structure is
  enabled.

- RFS does **not** assert or require any mapping between PHI, LAMBDA,
  and T beyond the doc-only claims in Section 3.

## 6. Compliance checklist (author-facing)

Before commit:

1.  File encoding and endings

    - 7-bit ASCII only; LF-only; final newline present.

2.  Mandatory literals present exactly once (or more), byte-exact:

    - {"type":"KL","support":"S_adm"}

    - forall x,y in S_adm: D(PHI(x), PHI(y)) <= D(x,y)

    - T(S_adm) subset_of S_adm

3.  PRE_FORMAL FSM holds for every marker:

    - Marker line [PRE_FORMAL id="rfs#eqN"]

    - Next line $$

    - ASCII content only

    - Closing $$

    - One block per marker

4.  No Unicode glyphs (no curly quotes, no ≤, no ∘, no typographic
    prime).

5.  No kernel identifiers or RELATION usage.
