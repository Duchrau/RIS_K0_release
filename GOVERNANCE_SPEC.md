

## Normative Tools
The following tools are normative and part of the K0 verification surface:
- verify_all.ps1
- verify_all.sh
- tools/check_kernel.py
- tools/validate_views.py

Only these tools may influence K0 semantics or verification outcomes.

## K0 Change Definition (Final)
A change is a K0 change if it modifies:
- bundle_root/kernel/objects_K0.json
- spec/**
- release/**
- release/provenance/**
- any normative tool listed above

Any modification in these areas REQUIRES full verification via verify_all.

## Non-K0 Changes
The following paths are explicitly non-normative:
- docs/**
- provenance/** (repository working copy)
- devtools/**
- logs/**
- examples/**
- .github/**
- any file not referenced in SYSTEM_SPEC or DIRECTORY_SPEC

Non-K0 changes MUST NOT influence verification or release artifacts.

## Mixed Changes Rule
If a commit or pull request includes both K0 and non-K0 changes:
- The K0 part MUST validate cleanly.
- Non-K0 changes MUST NOT alter or interfere with any normative behavior.

## CI Requirements
- verify_all is mandatory for every K0 change.
- No merge to main is permitted unless verify_all succeeds.
- Non-normative paths are ignored by CI and MUST NOT break verification.

