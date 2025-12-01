# Fixpoint Core (FPC) --- doc-only

Version: 1.0.0
Status: Informational (K0 doc-only)
Policy: ASCII-only, LF-only, final newline

## 1. Purpose

FPC provides a minimal, machine-checkable scaffold for documenting fixpoint behavior alongside the K0 kernel.

## 2. K1: factorization route (doc-only)

[PRE_FORMAL id="metaframe#eq_fact1"]
Cyan
T := F \circ \Lambda
Cyan

[PRE_FORMAL id="metaframe#eq_fact2"]
Cyan
F(F(x)) = F(x) \ \text{for all}\ x \in \Lambda(W_r)
Cyan

[PRE_FORMAL id="metaframe#eq_fact3"]
Cyan
\Lambda \circ F = F \ \text{on}\ W_r
Cyan

[PRE_FORMAL id="metaframe#eq_fact4"]
Cyan
T^2 = T \ \text{on}\ W_r
Cyan

## 3. Compliance

- K0 isolation: no kernel IDs introduced
- ASCII discipline maintained
- PRE_FORMAL FSM followed
