param(
    [string]$Owner = "Duchrau",
    [string]$Repo  = "RIS_K0_release",
    [string]$Tag   = "k0-archive-locked-2025-11-25"
)

Write-Host "== VERIFY REMOTE BUNDLE =="

$dlDir = Join-Path $env:TEMP ("k0_dl_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $dlDir | Out-Null

$zipUrl = "https://github.com/$Owner/$Repo/releases/download/$Tag/release\\release\RIS_K0_provenanced.zip"
$scUrl  = "https://github.com/$Owner/$Repo/releases/download/$Tag/release\\release\RIS_K0_provenanced.zip.sha256"

$zipDl = Join-Path $dlDir 'release\\release\RIS_K0_provenanced.zip'
$scDl  = Join-Path $dlDir 'release\\release\RIS_K0_provenanced.zip.sha256'

Invoke-WebRequest -Uri $zipUrl -OutFile $zipDl
Invoke-WebRequest -Uri $scUrl  -OutFile $scDl

$h   = (Get-FileHash $zipDl -Algorithm SHA256).Hash.ToLower()
$ref = ([regex]::Match((Get-Content $scDl -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$shaOk = ($h -eq $ref)
Write-Host ("REMOTE_SHA_OK=" + $shaOk)

$tmp = Join-Path $env:TEMP ("k0_vf_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
Expand-Archive -Path $zipDl -DestinationPath $tmp -Force

Push-Location $tmp
cmd /c "type provenance\byte_hash.txt | ssh-keygen -Y verify -f provenance\allowed_signers.txt -I maintainer -n RIS_K0 -s provenance\byte_hash.txt.sig"
$status = (Get-Content ".\provenance\provenance.json" -Raw | ConvertFrom-Json).status
Write-Host ("PROVENANCE_STATUS=" + $status)
Pop-Location

Remove-Item -Recurse -Force $tmp, $dlDir

if(-not $shaOk -or $status -ne "ARCHIVE_LOCKED"){
    throw "VERIFY_FAILED: SHA_OK=$shaOk, STATUS=$status"
}


