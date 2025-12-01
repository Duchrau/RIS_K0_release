# Reflexive Fixed-Point System (RFS) --- doc-only

Version: 1.0.0
Status: Informational (K0-external, documentation-only)

## Mandatory literals

{"type":"KL","support":"S_adm"}

forall x,y in S_adm: D(PHI(x), PHI(y)) <= D(x,y)

T(S_adm) subset_of S_adm

## PRE_FORMAL blocks

[PRE_FORMAL id="rfs#eq1"]
$$
\rho' = f(\rho)
$$

[PRE_FORMAL id="rfs#eq2"]
$$
f(\rho^*) = 0
$$

[PRE_FORMAL id="rfs#eq3"]
$$
f'(\rho^*) < 0
$$

## Compliance

- ASCII-only, LF-only
- PRE_FORMAL FSM followed
- No kernel IDs introduced
