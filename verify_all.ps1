$ErrorActionPreference = "Stop"

$zip   = Join-Path $pwd "RIS_K0_provenanced.zip"
$sc    = Join-Path $pwd "RIS_K0_provenanced.zip.sha256"

$hashLocal = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$hashRef   = ([regex]::Match((Get-Content $sc -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()

if ($hashLocal -ne $hashRef) { throw "SHA256 mismatch" }

$tmp = New-Item -ItemType Directory -Path (Join-Path $pwd ("tmp_" + [guid]::NewGuid())) -Force

Expand-Archive -Path $zip -DestinationPath $tmp.FullName

$bh   = Get-Content (Join-Path $tmp.FullName "provenance\byte_hash.txt") -Raw
$sig  = Join-Path $tmp.FullName "provenance\byte_hash.txt.sig"
$asg  = Join-Path $tmp.FullName "provenance\allowed_signers.txt"

$proc = Start-Process ssh-keygen -ArgumentList @(
    "-Y", "verify",
    "-f", $asg,
    "-I", "maintainer",
    "-n", "RIS_K0",
    "-s", $sig
) -NoNewWindow -PassThru -Wait -RedirectStandardInput "byte_hash.txt"

if ($proc.ExitCode -ne 0) { throw "Signature invalid" }

$prov = Get-Content (Join-Path $tmp.FullName "provenance\provenance.json") -Raw | ConvertFrom-Json
if ($prov.status -ne "ARCHIVE_LOCKED") { throw "Invalid release state" }

"OK"
Remove-Item $tmp -Recurse -Force
