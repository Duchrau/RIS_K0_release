# RIS K0 - verify_all.ps1 (canonical)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (!(Test-Path "RIS_K0_provenanced.zip") -or !(Test-Path "RIS_K0_provenanced.zip.sha256")) { Write-Host "Missing release assets." -ForegroundColor Red; exit 1 }

$h   = (Get-FileHash .\RIS_K0_provenanced.zip -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content .\RIS_K0_provenanced.zip.sha256 -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
if ($h -ne $ref) { Write-Host "ZIP integrity failure." -ForegroundColor Red; exit 1 }

$tmp = Join-Path $env:TEMP ("ris_k0_verify_" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
Expand-Archive -Path .\RIS_K0_provenanced.zip -DestinationPath $tmp

$prov = Join-Path $tmp "provenance"

$need = @("manifest.json","provenance.json","byte_hash.txt","byte_hash.txt.sig","allowed_signers.txt")
foreach ($f in $need) { if (!(Test-Path (Join-Path $prov $f))) { Write-Host "Missing provenance file: $f" -ForegroundColor Red; exit 1 } }

$ok = $stdin = Join-Path $prov "byte_hash.txt"
$sig   = Join-Path $prov "byte_hash.txt.sig"
$allow = Join-Path $prov "allowed_signers.txt"
& cmd /c "type ""$stdin"" | ssh-keygen -Y verify -f ""$allow"" -I maintainer -n RIS_K0 -s ""$sig"""
if ($LASTEXITCODE -ne 0) { Write-Host "Signature verification failed." -ForegroundColor Red; exit 1 }
if ($LASTEXITCODE -ne 0) { Write-Host "Signature verification failed." -ForegroundColor Red; exit 1 }

$meta = Get-Content (Join-Path $prov "provenance.json") -Raw | ConvertFrom-Json
if ($meta.status -ne "ARCHIVE_LOCKED") { Write-Host "Invalid final state." -ForegroundColor Red; exit 1 }

Write-Host "OK"
exit 0
