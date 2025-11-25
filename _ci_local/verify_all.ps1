  param([Parameter(Mandatory)][string]$Path,[string]$Algorithm='SHA256')
}
Remove-Item function:\Get-Content -ErrorAction SilentlyContinue
function Get-Content {
  [CmdletBinding(DefaultParameterSetName='Path')]
  param(
    [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0)]
    [string]$Path,
    [Parameter(ParameterSetName='Path')][switch]$Raw,
    [Parameter(ParameterSetName='Path')][int]$TotalCount
  )
    Write-Host ("DBG Read-Sidecar: {0} (Raw={1} Top={2})" -f $Path,$Raw,$TotalCount)
  }
  Microsoft.PowerShell.Management\Get-Content @PSBoundParameters
}
# === /DBG SHIMS ===

function Resolve-RepoRoot {
  param([string]$Start)
  if ([string]::IsNullOrWhiteSpace($Start)) {
    $Start = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
  }
  $d = [IO.DirectoryInfo]$Start
  while ($d -and -not (Test-Path (Join-Path $d.FullName '.git')) -and -not (Test-Path (Join-Path $d.FullName 'release') -PathType Container)) {
    $d = $d.Parent
  }
  if (-not $d) { throw "Repo-Root nicht gefunden." }
  if ((Split-Path -Leaf $d.FullName) -ieq 'release' -and $d.Parent) { $d = $d.Parent }
  return $d.FullName
}

$RepoRoot = Resolve-RepoRoot
# REMOVED self-join of $ZipPath
if (-not (Test-Path $ZipPath -PathType Leaf)) { throw "Missing $ZipPath" }

# RIS K0 - verify_all.ps1 (canonical)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


if ($h -ne $ref) { Write-Host "ZIP integrity failure." -ForegroundColor Red; exit 1 }

$tmp = Join-Path $env:TEMP ("ris_k0_verify_" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null

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











# --- CANONICAL SHA CHECK ---
$ShaPath = "$ZipPath.sha256"
if (-not (Test-Path $ShaPath -PathType Leaf)) { throw "Missing $ShaPath" }
$act = (Get-FileHash -Algorithm SHA256 -Path $ZipPath).Hash.ToLower()
$ref = ([regex]::Match((Get-Content -LiteralPath $ShaPath -Raw),'(?i)\b[0-9a-f]{64}\b')).Value.ToLower()
if ([string]::IsNullOrWhiteSpace($ref)) { throw "Invalid sidecar: no digest in $ShaPath" }
if ($act -ne $ref) {
  Write-Host "DBG ZipPath = $ZipPath"
  Write-Host "DBG ShaPath = $ShaPath"
  Write-Host "DBG act    = $act"
  Write-Host "DBG ref    = $ref"
  throw "SHA256 mismatch"
}
"SHA256 OK: $act"
# --- /CANONICAL SHA CHECK ---
