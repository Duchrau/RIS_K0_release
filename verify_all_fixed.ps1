Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Pfade
$proj       = (Get-Location).Path
$releaseDir = Join-Path $proj 'release'
$zipPath    = Join-Path $releaseDir 'RIS_K0_provenanced.zip'
$shaPath    = Join-Path $releaseDir 'RIS_K0_provenanced.zip.sha256'
$docsDir    = Join-Path $proj 'docs'
$logsDir    = Join-Path $proj 'logs'

# I/O-Ordner absichern
New-Item -ItemType Directory -Force -Path $docsDir, $logsDir | Out-Null

# SHA256 prüfen
if (!(Test-Path $zipPath) -or !(Test-Path $shaPath)) { 
    throw "Release-Asset oder .sha256 fehlt: $zipPath / $shaPath" 
}

$expected = (Get-Content $shaPath -Raw).Trim().Split(" `t")[0].Split(' ')[0].ToLower()
$actual   = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()

"== SHA256 CHECK =="
"expected: $expected"
"actual  : $actual"
if ($expected -ne $actual) { 
    "RESULT  : MISMATCH"; throw "Hash-Mismatch." 
} else { 
    "RESULT  : OK" 
}
