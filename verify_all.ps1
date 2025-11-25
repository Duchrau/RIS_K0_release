$ErrorActionPreference = "Stop"

$zip = Join-Path $pwd "release\\release\RIS_K0_provenanced.zip"
$sc  = Join-Path $pwd "release\\release\RIS_K0_provenanced.zip.sha256"

# 1) SHA256 gegen Sidecar prüfen
$hashLocal = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$hashRef   = ([regex]::Match((Get-Content $sc -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()

if ($hashLocal -ne $hashRef) {
    throw "SHA256 mismatch"
}

# 2) Archiv in Temp entpacken
$tmp = New-Item -ItemType Directory -Path (Join-Path $pwd ("tmp_" + [guid]::NewGuid())) -Force

Expand-Archive -Path $zip -DestinationPath $tmp.FullName

$bhPath = Join-Path $tmp.FullName "provenance\byte_hash.txt"
$sig    = Join-Path $tmp.FullName "provenance\byte_hash.txt.sig"
$asg    = Join-Path $tmp.FullName "provenance\allowed_signers.txt"

# 3) Signatur prüfen (stdin-Pipe)
Get-Content $bhPath -Raw | ssh-keygen -Y verify -f $asg -I maintainer -n RIS_K0 -s $sig
if ($LASTEXITCODE -ne 0) {
    throw "Signature invalid (ssh-keygen exit $LASTEXITCODE)"
}

# 4) Provenance-Status prüfen
$prov = Get-Content (Join-Path $tmp.FullName "provenance\provenance.json") -Raw | ConvertFrom-Json
if ($prov.status -ne "ARCHIVE_LOCKED") {
    throw "Invalid release state: $($prov.status)"
}

"OK"

Remove-Item $tmp -Recurse -Force


