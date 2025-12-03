Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# infer repo root from script location
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Join-RepoPath {
  param([Parameter(Mandatory=$true)][string]$Rel)
  Join-Path -Path $repoRoot -ChildPath $Rel
}

$HadError = $false
function Fail {
  param([Parameter(Mandatory=$true)][string]$Message)
  $script:HadError = $true
  Write-Error $Message
}

# --- required paths ---

$bundleRoot   = Join-RepoPath "bundle_root"
$specDir      = Join-RepoPath "spec"
$releaseDir   = Join-RepoPath "release"
$provDir      = Join-RepoPath "release/provenance"
$zipPath      = Join-RepoPath "release/K0_bundle.zip"
$shaPath      = Join-RepoPath "release/K0_bundle.zip.sha256"
$manifestPath = Join-RepoPath "release/provenance/manifest.json"
$provJsonPath = Join-RepoPath "release/provenance/provenance.json"

if (-not (Test-Path -LiteralPath $bundleRoot)) { Fail "Missing bundle_root directory: $bundleRoot" }
if (-not (Test-Path -LiteralPath $specDir))    { Fail "Missing spec directory: $specDir" }
if (-not (Test-Path -LiteralPath $releaseDir)) { Fail "Missing release directory: $releaseDir" }
if (-not (Test-Path -LiteralPath $provDir))    { Fail "Missing provenance directory: $provDir" }

if (-not (Test-Path -LiteralPath $zipPath)) { Fail "Missing release/K0_bundle.zip" }
if (-not (Test-Path -LiteralPath $shaPath)) { Fail "Missing release/K0_bundle.zip.sha256" }

if (-not (Test-Path -LiteralPath $manifestPath)) { Fail "Missing release/provenance/manifest.json" }
if (-not (Test-Path -LiteralPath $provJsonPath)) { Fail "Missing release/provenance/provenance.json" }

# --- SHA256 check for ZIP ---

if ((Test-Path -LiteralPath $zipPath) -and (Test-Path -LiteralPath $shaPath)) {
  try {
    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
  } catch {
    Fail ("Failed to compute SHA256 for K0_bundle.zip: " + $_.Exception.Message)
    $zipHash = $null
  }

  try {
    $sidecarRaw = Get-Content -LiteralPath $shaPath -Raw -Encoding UTF8
    $m = [regex]::Match($sidecarRaw, "([A-Fa-f0-9]{64})")
    if (-not $m.Success) {
      Fail "Could not find 64-hex SHA256 in K0_bundle.zip.sha256"
    } else {
      $sideHash = $m.Groups[1].Value.ToUpperInvariant()
      if ($zipHash -and $sideHash -and $zipHash -ne $sideHash) {
        Fail ("ZIP SHA256 mismatch: zip=" + $zipHash + " sidecar=" + $sideHash)
      }
    }
  } catch {
    Fail ("Failed to parse K0_bundle.zip.sha256: " + $_.Exception.Message)
  }
}

# --- JSON validation in normative paths ---

$normJson = @()

if (Test-Path -LiteralPath $bundleRoot) {
  $normJson += Get-ChildItem -LiteralPath $bundleRoot -Recurse -File -Filter "*.json"
}

if (Test-Path -LiteralPath $provDir) {
  $normJson += Get-ChildItem -LiteralPath $provDir -Recurse -File -Filter "*.json"
}

$seen = New-Object System.Collections.Generic.HashSet[string]

foreach ($f in $normJson) {
  $full = $f.FullName
  if (-not $seen.Add($full)) { continue }

  try {
    $raw = Get-Content -LiteralPath $full -Raw -Encoding UTF8
  } catch {
    Fail ("Failed to read JSON file: " + $full + " | " + $_.Exception.Message)
    continue
  }

  try {
    $null = $raw | ConvertFrom-Json -ErrorAction Stop
  } catch {
    Fail ("JSON invalid in " + $full + " | " + $_.Exception.Message)
  }
}

# --- ZIP vs manifest consistency (temporarily disabled complexity) ---

# Future: compare entries in $zipPath with manifest.json content.
# For v1.0 minimal verifier we only enforce SHA256 and JSON validity.

if ($HadError) {
  Write-Host "K0 verification FAILED"
  exit 1
} else {
  Write-Host "K0 verification OK"
  exit 0
}
