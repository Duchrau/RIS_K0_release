# Background

Models deserve a defense only when they claim to be true. This one does not.

------------------------------------------------------------------------

## Purpose

This repository publishes a reproducible, inspectable bundle of the RIS kernel at level K0 together with two documentation-only companions:

RFS: Reference Framing Spec (doc-only)

FPC: Fixpoint Core (doc-only at K0; factorization route described for K1)

The goal is transparency and verifiability, not persuasion. Everything is wired so you can reproduce the bundle, verify hashes, and see exactly what is enforced by CI.

------------------------------------------------------------------------

## Reset marker

Pre-reset-2025-11-27

This marks the end of the construction site. From here on, the state is reproducible and auditable.

------------------------------------------------------------------------

## What this is NOT

Not metaphysics

Not ontology

Not cognition

Not interpretation of RFS

Not semantic theory

------------------------------------------------------------------------

## Scope and boundaries

Kernel: K0 minimal surface. No RELATION objects. No RFS/FPC IDs instantiated in the kernel.

RFS: documentation-only; lives in docs/rfs/rfs.md.

FPC: documentation-only at K0; axioms and a K1 factorization route; lives in docs/metaframe/fixpoint_core_spec_v1_0.md.

No truth claims: these documents define interfaces, constraints, and reproducibility rules. They are not evidence of correctness about the world.

------------------------------------------------------------------------

## Architecture in one page

### K0
Minimal operator surface, flat schema for operators.
RELATION disabled.
Build and verification scripts produce a ZIP bundle plus sidecar hashes and a semantic anchor.

### RFS (doc-only)
Declares the divergence type used in documentation and a non-expansivity claim on an admissible subset.
Enforced by lint via exact ASCII literals in docs/rfs/rfs.md.
No kernel binding at K0.

### FPC (doc-only in K0, route for K1)
K0: idempotence is an axiom.
K1: a factorization route is described (composition with a projection-like operator) that can yield idempotence as a result once the additional structure is activated.
No kernel binding at K0.

------------------------------------------------------------------------

## Reproducibility and verification

Everything is wired to make local checks trivial and CI checks strict.

### Build orchestration
./build.ps1 pack produces:
- Release/ris_bundle.zip
- Release/ris_bundle.sha256
- Release/ris_bundle.sha512
- Release/manifest.json
- Provenance/semantic_hash.txt (SHA256 of SHA256|SHA512)

./build.ps1 verify runs the one-button verifier.

### One-button verifier
./ris-check.ps1 checks:
- Presence of ZIP, sidecars, manifest, semantic hash
- ZIP hashes equal the sidecars
- Semantic hash matches SHA256|SHA512
- Manifest paths match ZIP entries
- Repository text files obey LF and UTF-8 (and ASCII where required)

### CI gates (GitHub Actions)
Lint: ASCII/LF policy, PRE_FORMAL finite-state rules, required documentation literals.
Bundle verify: pack + verify on Ubuntu runner using PowerShell.

------------------------------------------------------------------------

## File system topology (canonical, case-sensitive)

- Docs/rfs/rfs.md
- Docs/metaframe/fixpoint_core_spec_v1_0.md
- Docs/index.md
- Tools/lint_docs_layout.py
- Build.ps1
- Ris-check.ps1

Release/ and provenance/ are created by pack.

Use exactly docs/ (lowercase). CI is case-sensitive.

------------------------------------------------------------------------

## Documentation constraints

### ASCII-only zones
All content in docs/rfs/** and docs/metaframe/** must be 7-bit ASCII.
In math blocks use TeX macros: \\circ, \\le, \\subseteq, etc.
Do not paste Unicode glyphs such as â‰¤, âˆ˜, typographic quotes, or primes.

### Line endings
LF-only for all text. Final newline required.

### PRE_FORMAL finite-state rule
Marker must be the only token on its line:
[PRE_FORMAL id="rfs#eqN"] or [PRE_FORMAL id="metaframe#eq_factN"]
Immediately followed by $$ on the next line, then the block, then closing $$.
Exactly one $$ ... $$ block per marker.

### ID formats
RFS: rfs#eq1, rfs#eq2, ...
FPC: metaframe#eq_fact1, eq_fact2, eq_fact3, eq_fact4
No alphabetic suffixes like LN unless explicitly introduced and linted.

------------------------------------------------------------------------

## RFS obligations (doc-only, enforced by lint)

Docs/rfs/rfs.md must contain these ASCII literals verbatim:

{"type":"KL","support":"S_adm"}

forall x,y in S_adm: D(PHI(x), PHI(y)) <= D(x,y)

T(S_adm) subset_of S_adm

Example PRE_FORMAL blocks are provided as TeX inside $$ with ASCII macros only.

------------------------------------------------------------------------

## FPC obligations (doc-only at K0)

K0 axioms in docs/metaframe/fixpoint_core_spec_v1_0.md:

T(W_r) subset_of W_r

T(T(w)) = T(w) on W_r

Note: Idempotence in K0 = Axiom; in K1 = Result via factorization.

K1 factorization route (doc-only description):

T := F \\circ \\Lambda

F(F(x)) = F(x) for all x in \\Lambda(W_r)

\\Lambda \\circ F = F on W_r

T^2 = T on W_r

Reading guide must state that whether T^2 = T follows depends on the chosen structure and is not enforced at K0.

------------------------------------------------------------------------

## Governance and tagging

Branch protection: main protected, required status checks pass before merge.

Releases: tag as vX.Y.Z. Release notes state K-level, doc-only scope, and reproducibility claims.

Provenance: keep semantic_hash.txt, the commit SHA, and sidecar hashes as the notarized anchor.

Reserved identifiers: if a registry file is present (e.g., spec/reserved_ids_rfs_v1_0.json), it is additive-only and doc-binding, not kernel-binding at K0.

### Suggested honesty tags for README and releases:
[DOC-ONLY] for RFS/FPC
[K0] or [K1-ENABLED] switches documented explicitly
[REPRODUCIBLE] when pack and verify pass on CI
[EXPERIMENTAL] where appropriate

------------------------------------------------------------------------

## How to verify locally

# pack the bundle
./build.ps1 pack

# run the full verifier
./ris-check.ps1

# expected outcome
ALL CHECKS PASS

If the verifier fails, it prints the first failing condition and where it occurred.

------------------------------------------------------------------------

## Known limitations

No claims about the world. These documents define interfaces, constraints, and checks.

K1 structure is descriptive until explicitly enabled; K0 never auto-derives idempotence.

Strict ASCII policy means copy-paste from PDFs will likely fail lint unless cleaned.

------------------------------------------------------------------------

## Contact and responsibility

The bundle aims to be honest, minimal, and reproducible. The responsibility is to show exactly what is asserted and what is not. Consumers are expected to verify, not to trust.

------------------------------------------------------------------------

I can explain the notation, not the universe, that remains your problem
