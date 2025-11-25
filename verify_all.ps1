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

$ErrorActionPreference = "Stop"

$zip = $ZipPath
$sc  = $ZipPath

# 1) SHA256 gegen Sidecar prüfen
$hashRef   = ([regex]::Match((Get-Content $sc -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()

if ($hashLocal -ne $hashRef) {
}

# 2) Archiv in Temp entpacken
$tmp = New-Item -ItemType Directory -Path (Join-Path $pwd ("tmp_" + [guid]::NewGuid())) -Force


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
