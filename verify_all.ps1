# verify_all.ps1
# Deterministic contract verification for RIS K0.
# Exit codes: 0 = success, 1 = failure
# Modes:
#   - Source mode (default): validates repo anchors + specs + invariants
#   - Bundle mode: add -ZipPath <path> (and optional -SidecarPath <path>) to validate ZIP asset too
#
# Contract (Variant A' allowlist):
#   Tracked in repo under release/provenance/ ONLY:
#     - manifest.json
#     - provenance.json
#     - semantic_hash.txt
#     - byte_hash.txt
#     - source_date_epoch.txt
#   ZIP and ZIP sidecar are release assets only (not tracked in repo).

[CmdletBinding()]
param(
  [string]$ZipPath,
  [string]$SidecarPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string]$Msg) { throw $Msg }

function Read-Bytes([string]$Path) {
  if(-not (Test-Path -LiteralPath $Path)) { Fail "MISSING: $Path" }
  [IO.File]::ReadAllBytes($Path)
}

function Assert-Ascii-LF([string]$Path) {
  $b = Read-Bytes $Path
  if($b.Length -lt 1) { Fail "EMPTY: $Path" }
  foreach($x in $b){
    if($x -gt 127){ Fail "NON_ASCII: $Path" }
    if($x -eq 13){ Fail "CR_FOUND (must be LF-only): $Path" }
  }
  if($b[$b.Length-1] -ne 10){ Fail "NO_TRAILING_LF: $Path" }
}

function Read-AsciiText([string]$Path) {
  Assert-Ascii-LF $Path
  [Text.Encoding]::ASCII.GetString((Read-Bytes $Path))
}

function Assert-NoUtf8Bom([string]$Path) {
  $b = Read-Bytes $Path
  if($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF){
    Fail "UTF8_BOM_FOUND: $Path"
  }
}

function Read-Utf8NoBomText([string]$Path) {
  $b = Read-Bytes $Path
  Assert-NoUtf8Bom $Path
  # allow UTF-8, but enforce LF-only for contract files separately if needed
  $utf8 = New-Object System.Text.UTF8Encoding($false,$true)
  $utf8.GetString($b)
}

function To-JsonObject([string]$Path) {
  $txt = Read-Utf8NoBomText $Path
  try { $txt | ConvertFrom-Json }
  catch { Fail "INVALID_JSON: $Path" }
}

function Hex64([string]$s) { $s -match '^[a-f0-9]{64}$' }

function Get-RepoRoot {
  $p = $MyInvocation.MyCommand.Path
  if(-not $p){ Fail "CANNOT_DETERMINE_SCRIPT_PATH" }
  Split-Path -Parent $p
}

$RepoRoot = Get-RepoRoot
Set-Location $RepoRoot

try {
  Write-Host "=== K0 VERIFY ==="

  # --- 0) Require git + ensure we are in a repo root ---
  if(-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))){
    Fail "NOT_IN_REPO_ROOT: .git not found at $RepoRoot"
  }
  if(-not (Get-Command git -ErrorAction SilentlyContinue)){
    Fail "MISSING_TOOL: git"
  }

  # --- 1) Directory structure (minimal) ---
  $requiredDirs = @(
    "bundle_root/kernel",
    "spec",
    "release",
    "release/provenance",
    "docs"
  )
  foreach($d in $requiredDirs){
    if(-not (Test-Path -LiteralPath (Join-Path $RepoRoot $d))){
      Fail "MISSING_DIR: $d"
    }
  }

  # --- 2) Provenance allowlist enforcement (TRACKED SET must match exactly) ---
  $allow = @(
    'release/provenance/manifest.json',
    'release/provenance/provenance.json',
    'release/provenance/semantic_hash.txt',
    'release/provenance/byte_hash.txt',
    'release/provenance/source_date_epoch.txt'
  )

  $tracked = @(
    git ls-files release/provenance 2>$null |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ }
  )

  $trackedS = $tracked | Sort-Object
  $allowS   = $allow   | Sort-Object

  if(($trackedS -join "`n") -ne ($allowS -join "`n")){
    $extra = @($trackedS | Where-Object { $allow -notcontains $_ })
    $miss  = @($allowS   | Where-Object { $tracked -notcontains $_ })
    if($extra.Count -gt 0){ Fail ("PROVENANCE_TRACKED_OUTSIDE_ALLOWLIST:`n" + ($extra -join "`n")) }
    if($miss.Count  -gt 0){ Fail ("PROVENANCE_ALLOWLIST_NOT_TRACKED:`n" + ($miss  -join "`n")) }
    Fail "PROVENANCE_ALLOWLIST_MISMATCH"
  }

  # --- 3) .gitignore contains the allowlist rules (guard against regression) ---
  $giPath = Join-Path $RepoRoot '.gitignore'
  if(-not (Test-Path -LiteralPath $giPath)){ Fail "MISSING: .gitignore" }
  $gi = Read-Utf8NoBomText $giPath
  foreach($needle in @(
    'release/provenance/*',
    '!release/provenance/manifest.json',
    '!release/provenance/provenance.json',
    '!release/provenance/semantic_hash.txt',
    '!release/provenance/byte_hash.txt',
    '!release/provenance/source_date_epoch.txt'
  )){
    if($gi -notmatch [regex]::Escape($needle)){
      Fail "GITIGNORE_MISSING_RULE: $needle"
    }
  }

  # --- 4) Anchors: format + internal consistency ---
  $Man  = Join-Path $RepoRoot 'release/provenance/manifest.json'
  $Prov = Join-Path $RepoRoot 'release/provenance/provenance.json'
  $Sem  = Join-Path $RepoRoot 'release/provenance/semantic_hash.txt'
  $Byte = Join-Path $RepoRoot 'release/provenance/byte_hash.txt'
  $Sde  = Join-Path $RepoRoot 'release/provenance/source_date_epoch.txt'

  foreach($p in @($Man,$Prov,$Sem,$Byte,$Sde)){
    if(-not (Test-Path -LiteralPath $p)){ Fail "MISSING_ANCHOR: $p" }
  }

  # Enforce LF-only and ASCII for the text anchors (semantic/byte/sde).
  Assert-Ascii-LF $Sem
  Assert-Ascii-LF $Byte
  Assert-Ascii-LF $Sde

  $sdeRaw = Read-AsciiText $Sde
  if($sdeRaw -notmatch '^[0-9]+\n$'){ Fail "SDE_FORMAT_FAIL (digits+LF only): release/provenance/source_date_epoch.txt" }
  $sde_unix = [int64]$sdeRaw.Trim()
  $dtUtc = [DateTimeOffset]::FromUnixTimeSeconds($sde_unix).UtcDateTime

  $byteRaw = Read-AsciiText $Byte
  if($byteRaw -notmatch '^[a-f0-9]{64}\n$'){ Fail "BYTE_HASH_FORMAT_FAIL (sha256+LF): release/provenance/byte_hash.txt" }
  $byteSha = $byteRaw.Trim()

  $mf = To-JsonObject $Man
  if([string]$mf.version -ne '1.0'){ Fail "MANIFEST_VERSION_FAIL: want '1.0'" }
  if(-not $mf.files -or $mf.files.Count -lt 1){ Fail "MANIFEST_FILES_EMPTY" }
  $payload = [string]$mf.payload_digest
  if(-not (Hex64 $payload)){ Fail "MANIFEST_PAYLOAD_DIGEST_INVALID" }

  # Validate manifest file entries: required fields, path rules, ordinal sort, uniqueness
  $paths = New-Object System.Collections.Generic.List[string]
  foreach($e in $mf.files){
    $p = [string]$e.path
    $s = [string]$e.sha256
    $z = [int64]$e.size
    if(-not $p){ Fail "MANIFEST_ENTRY_MISSING_PATH" }
    if($p -notmatch '^(bundle_root/|spec/).+[^/]$' -or $p -match '\\|(^|/)\.\.(/|$)|^\.\/'){
      Fail "MANIFEST_PATH_RULE_FAIL: $p"
    }
    if($z -lt 0){ Fail "MANIFEST_SIZE_INVALID: $p" }
    if(-not (Hex64 $s)){ Fail "MANIFEST_SHA256_INVALID: $p" }
    $paths.Add($p) | Out-Null
  }

  $ord = $paths.ToArray()
  [Array]::Sort($ord, [StringComparer]::Ordinal)
  for($i=0; $i -lt $paths.Count; $i++){
    if($paths[$i] -ne $ord[$i]){
      Fail "MANIFEST_NOT_ORDINAL_SORTED"
    }
  }

  # Uniqueness
  $seen = @{}
  foreach($p in $paths){
    if($seen.ContainsKey($p)){ Fail "MANIFEST_DUPLICATE_PATH: $p" }
    $seen[$p] = $true
  }

  # Recompute payload_digest from sorted entries: path<TAB>size<TAB>sha256<LF> over ASCII
  $sb = New-Object System.Text.StringBuilder
  foreach($e in $mf.files){
    [void]$sb.AppendFormat("{0}`t{1}`t{2}`n",[string]$e.path,[int64]$e.size,[string]$e.sha256)
  }
  $pdBytes = [Text.Encoding]::ASCII.GetBytes($sb.ToString())
  $sha2 = [Security.Cryptography.SHA256]::Create()
  try {
    $pd = ([BitConverter]::ToString($sha2.ComputeHash($pdBytes))).ToLower().Replace('-','')
  } finally { $sha2.Dispose() }
  if($pd -ne $payload){ Fail "PAYLOAD_DIGEST_MISMATCH (manifest vs recomputed)" }

  # semantic_hash.txt must match payload_digest exactly
  $semRaw = Read-AsciiText $Sem
  $wantSem = "RIS:K0:$payload`n"
  if($semRaw -ne $wantSem){ Fail "SEMANTIC_HASH_MISMATCH" }

  # provenance.json: required fields, and pinned toolchain strings
  $pj = To-JsonObject $Prov

  # Minimal required keys for contract
  if(-not $pj.source -or -not $pj.source.git_commit){ Fail "PROVENANCE_MISSING: source.git_commit" }
  if(([string]$pj.source.git_commit) -notmatch '^[0-9a-f]{40}$'){ Fail "PROVENANCE_BAD_GIT_COMMIT" }

  if(-not $pj.zip -or -not $pj.zip.sha256){ Fail "PROVENANCE_MISSING: zip.sha256" }
  $provZipSha = ([string]$pj.zip.sha256).ToLower()
  if(-not (Hex64 $provZipSha)){ Fail "PROVENANCE_BAD_ZIP_SHA256" }

  if(-not $pj.build -or -not $pj.build.toolchain -or -not $pj.build.toolchain.zip_writer){ Fail "PROVENANCE_MISSING: build.toolchain.zip_writer" }
  if(([string]$pj.build.toolchain.zip_writer) -ne '7-Zip 24.07'){ Fail "PROVENANCE_ZIP_WRITER_PIN_FAIL" }
  if(-not $pj.build.toolchain.flags){ Fail "PROVENANCE_MISSING: build.toolchain.flags" }

  # If provenance carries sde_unix / payload_digest, ensure they match anchors (recommended fields)
  if($pj.PSObject.Properties.Name -contains 'sde_unix'){
    if([int64]$pj.sde_unix -ne $sde_unix){ Fail "PROVENANCE_SDE_UNIX_MISMATCH" }
  }
  if($pj.PSObject.Properties.Name -contains 'payload_digest'){
    if(([string]$pj.payload_digest) -ne $payload){ Fail "PROVENANCE_PAYLOAD_DIGEST_MISMATCH" }
  }

  # byte_hash anchors zip.sha256 (repo anchor must match provenance)
  if($provZipSha -ne $byteSha){ Fail "ZIP_SHA_ANCHOR_MISMATCH (provenance.zip.sha256 vs byte_hash.txt)" }

  # --- 5) pack_spec pin exists and matches contract ---
  $PackSpec = Join-Path $RepoRoot 'spec/pack_spec_v1_0_1.json'
  if(-not (Test-Path -LiteralPath $PackSpec)){ Fail "MISSING: spec/pack_spec_v1_0_1.json" }
  $ps = To-JsonObject $PackSpec
  if(([string]$ps.version) -ne '1.0.1'){ Fail "PACK_SPEC_VERSION_FAIL" }
  if(-not $ps.build -or -not $ps.build.toolchain){ Fail "PACK_SPEC_MISSING: build.toolchain" }
  if(([string]$ps.build.toolchain.zip_writer) -ne '7-Zip 24.07'){ Fail "PACK_SPEC_ZIP_WRITER_PIN_FAIL" }
  if(-not $ps.build.toolchain.flags -or $ps.build.toolchain.flags.Count -lt 1){ Fail "PACK_SPEC_FLAGS_MISSING" }

  # --- 6) verification.md contains pin line (doc contract) ---
  $VerMd = Join-Path $RepoRoot 'docs/verification.md'
  if(Test-Path -LiteralPath $VerMd){
    $vtxt = Read-Utf8NoBomText $VerMd
    if($vtxt -notmatch [regex]::Escape('ZIP_WRITER_PIN: 7-Zip 24.07')){
      Fail "DOC_PIN_MISSING: docs/verification.md must mention ZIP_WRITER_PIN: 7-Zip 24.07"
    }
  } else {
    Fail "MISSING: docs/verification.md"
  }

  # --- 7) Bundle mode (optional): validate ZIP asset, sidecar, per-entry invariants ---
  if($ZipPath){
    if(-not (Test-Path -LiteralPath $ZipPath)){ Fail "ZIP_MISSING: $ZipPath" }
    $zipSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLower()
    if($zipSha -ne $byteSha){ Fail "ZIP_SHA_MISMATCH (actual vs byte_hash.txt)" }

    # sidecar default: "<zip>.sha256" OR sibling "K0_bundle.zip.sha256" if ZipPath ends with K0_bundle.zip
    if(-not $SidecarPath -or $SidecarPath.Trim() -eq ''){
      $SidecarPath = ($ZipPath + '.sha256')
      if(-not (Test-Path -LiteralPath $SidecarPath)){
        $SidecarPath = (Join-Path (Split-Path -Parent $ZipPath) 'K0_bundle.zip.sha256')
      }
    }
    if(-not (Test-Path -LiteralPath $SidecarPath)){ Fail "SIDECAR_MISSING: $SidecarPath" }

    # Sidecar format: "<sha256><2sp>K0_bundle.zip<LF>" (ASCII, LF-only)
    Assert-Ascii-LF $SidecarPath
    $sideRaw = Read-AsciiText $SidecarPath
    $wantSide = ("{0}  K0_bundle.zip`n" -f $zipSha)
    if($sideRaw -ne $wantSide){ Fail "SIDECAR_FORMAT_MISMATCH" }

    # Toolchain pin check in bundle mode: require local 7z.exe matches pin if present in provenance (strong gate)
    $sevenCandidates = @(
      'C:\Program Files\7-Zip\7z.exe',
      'C:\Program Files (x86)\7-Zip\7z.exe',
      "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    if($sevenCandidates.Count -lt 1){ Fail "TOOLCHAIN_FAIL: 7z.exe not found (bundle mode requires 7-Zip 24.07)" }
    $seven = $sevenCandidates[0]
    $verLine = (& $seven i | Select-String '^7-Zip ' | Select-Object -First 1).ToString().Trim()
    if($verLine -notmatch '^7-Zip 24\.07 '){ Fail "TOOLCHAIN_PIN_FAIL: want '7-Zip 24.07', got: $verLine" }

    if($pj.build.toolchain.PSObject.Properties.Name -contains 'zip_writer_sha256'){
      $sevenSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $seven).Hash.ToLower()
      if($sevenSha -ne ([string]$pj.build.toolchain.zip_writer_sha256).ToLower()){
        Fail "TOOLCHAIN_SHA_MISMATCH: 7z.exe sha256 != provenance.build.toolchain.zip_writer_sha256"
      }
    }

    # ZIP entry checks (set equality + per-file size/sha/mtime == SDE)
    Add-Type -AssemblyName System.IO.Compression
    $fs = [IO.File]::OpenRead($ZipPath)
    try {
      $za = New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Read,$false)
      try {
        $entries = @($za.Entries)

        foreach($en in $entries){
          if(([string]$en.FullName).EndsWith('/')){ Fail "ZIP_DIR_ENTRY_FOUND: $($en.FullName)" }
        }

        if($entries.Count -ne $mf.files.Count){
          Fail ("ZIP_ENTRY_COUNT_MISMATCH: zip={0} manifest={1}" -f $entries.Count, $mf.files.Count)
        }

        $pathsZ = @($entries | ForEach-Object { [string]$_.FullName })
        $zS = $pathsZ.Clone(); [Array]::Sort($zS,[StringComparer]::Ordinal)
        $mS = $paths.ToArray().Clone(); [Array]::Sort($mS,[StringComparer]::Ordinal)

        for($i=0; $i -lt $mS.Count; $i++){
          if($zS[$i] -ne $mS[$i]){
            Fail ("ZIP_MANIFEST_PATH_SET_MISMATCH at {0}: zip='{1}' manifest='{2}'" -f $i,$zS[$i],$mS[$i])
          }
        }

        $specByPath = @{}
        foreach($s in $mf.files){ $specByPath[[string]$s.path] = $s }

        $sha = [Security.Cryptography.SHA256]::Create()
        try {
          foreach($en in $entries){
            $p = [string]$en.FullName
            $spec = $specByPath[$p]
            if(-not $spec){ Fail "ZIP_PATH_NOT_IN_MANIFEST: $p" }

            if([int64]$en.Length -ne [int64]$spec.size){
              Fail ("ZIP_SIZE_MISMATCH: {0} (zip={1} manifest={2})" -f $p,[int64]$en.Length,[int64]$spec.size)
            }

            $lwUtc = $en.LastWriteTime.UtcDateTime
            if($lwUtc -ne $dtUtc){
              Fail ("ZIP_MTIME_MISMATCH: {0} (got={1} want={2})" -f $p,$lwUtc.ToString('o'),$dtUtc.ToString('o'))
            }

            $st = $en.Open()
            try { $h = $sha.ComputeHash($st) } finally { $st.Dispose() }

            $hex = ([BitConverter]::ToString($h)).ToLower().Replace('-','')
            if($hex -ne ([string]$spec.sha256)){
              Fail ("ZIP_FILE_SHA_MISMATCH: $p")
            }
          }
        } finally { $sha.Dispose() }
      } finally { $za.Dispose() }
    } finally { $fs.Dispose() }

    Write-Host "=== BUNDLE_VALIDATED: PASS"
    exit 0
  }

  # Source-only mode success marker
  Write-Host "=== SOURCE_STATE_CONSISTENT: PASS"
  exit 0
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
