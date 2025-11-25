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

param(
    [string]$Owner = "Duchrau",
    [string]$Repo  = "RIS_K0_release",
    [string]$Tag   = "k0-archive-locked-2025-11-25"
)

Write-Host "== VERIFY REMOTE BUNDLE =="

$dlDir = Join-Path $env:TEMP ("k0_dl_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $dlDir | Out-Null

$zipUrl = "https://github.com/$Owner/$Repo/releases/download/$Tag/release\\$ZipPath"

$zipDl = $ZipPath
$scDl  = $ZipPath

Invoke-WebRequest -Uri $zipUrl -OutFile $zipDl
Invoke-WebRequest -Uri $scUrl  -OutFile $scDl

$ref = ([regex]::Match((Get-Content $scDl -Raw),'(?i)[0-9a-f]{64}')).Value.ToLower()
$shaOk = ($h -eq $ref)
Write-Host ("REMOTE_SHA_OK=" + $shaOk)

$tmp = Join-Path $env:TEMP ("k0_vf_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null

Push-Location $tmp
cmd /c "type provenance\byte_hash.txt | ssh-keygen -Y verify -f provenance\allowed_signers.txt -I maintainer -n RIS_K0 -s provenance\byte_hash.txt.sig"
$status = (Get-Content ".\provenance\provenance.json" -Raw | ConvertFrom-Json).status
Write-Host ("PROVENANCE_STATUS=" + $status)
Pop-Location

Remove-Item -Recurse -Force $tmp, $dlDir

if(-not $shaOk -or $status -ne "ARCHIVE_LOCKED"){
    throw "VERIFY_FAILED: SHA_OK=$shaOk, STATUS=$status"
}











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
