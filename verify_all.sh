#!/usr/bin/env sh
set -eu

zip="RIS_K0_provenanced.zip"
sidecar="RIS_K0_provenanced.zip.sha256"

if [ ! -f "$zip" ] || [ ! -f "$sidecar" ]; then
  echo "Missing release assets." >&2
  exit 1
fi

if ! sha256sum -c "$sidecar"; then
  echo "ZIP integrity failure." >&2
  exit 1
fi

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t ris_k0_verify)"
if unzip -q "$zip" -d "$tmp"; then
  :
else
  ec=$?
  [ "$ec" -eq 1 ] || exit "$ec"
fi

prov="$tmp/provenance"
need="manifest.json provenance.json byte_hash.txt byte_hash.txt.sig allowed_signers.txt"

for f in $need; do
  if [ ! -f "$prov/$f" ]; then
    echo "Missing provenance file: $f" >&2
    exit 1
  fi
done

if ! ssh-keygen -Y verify \
  -f "$prov/allowed_signers.txt" \
  -I maintainer \
  -n RIS_K0 \
  -s "$prov/byte_hash.txt.sig" < "$prov/byte_hash.txt"; then
  echo "Signature verification failed." >&2
  exit 1
fi

status="$(jq -r '.status' "$prov/provenance.json" 2>/dev/null || printf 'UNKNOWN')"
if [ "$status" != "ARCHIVE_LOCKED" ]; then
  echo "Invalid final state: $status" >&2
  exit 1
fi

echo "OK"
exit 0

