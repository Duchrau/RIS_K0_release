Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Workflow-kompatible Pfade
$zipPath = 'release\RIS_K0_v1.0.0_provenanced.zip'
$shaPath = 'release\RIS_K0_v1.0.0_provenanced.zip.sha256'

# SHA256 prüfen
if (!(Test-Path $zipPath) -or !(Test-Path $shaPath)) { 
    throw "Release-Asset oder .sha256 fehlt" 
}

$expected = (Get-Content $shaPath -Raw).Trim().Split(" `t")[0].Split(' ')[0].ToLower()
$actual = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()

"== SHA256 CHECK =="
"expected: $expected"
"actual  : $actual"
if ($expected -ne $actual) { 
    "RESULT  : MISMATCH"; throw "Hash-Mismatch." 
} else { 
    "RESULT  : OK" 
}

