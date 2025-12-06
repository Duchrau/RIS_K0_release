# verify_all.ps1
# Deterministic verification for RIS K0 (Contract A': provenance allowlist + assets as Release-only)
# Exit codes: 0=success, 1=failure

param(
  [ValidateSet('source','bundle')]
  [string]$Mode = 'source',

  # Only for -Mode bundle
  [string]$ZipPath,
  [string]$SidecarPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string]$Msg){ throw $Msg }

function ReadAsciiLF([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ Fail "MISSING: $Path" }
  $raw = Get-Content -Raw -Encoding ASCII -LiteralPath $Path
  if($raw -notmatch "^\A[\x00-\x7F]*\n\z"){ Fail "FORMAT_FAIL (ASCII+LF required): $Path" }
  return $raw
}

function ReadUtf8NoBomLF([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ Fail "MISSING: $Path" }
  $bytes = [IO.File]::ReadAllBytes($Path)
  if($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF){
    Fail "BOM_FAIL (UTF-8 BOM not allowed): $Path"
  }
  $txt = [Text.UTF8Encoding]::new($false).GetString($bytes)
  if($txt -match "`r"){ Fail "EOL_FAIL (CR not allowed): $Path" }
  if($txt -notmatch "\n\z"){ Fail "EOL_FAIL (final LF required): $Path" }
  return $txt
}

function GetGitHead(){
  $h = (git rev-parse HEAD 2>$null).Trim()
  if($h -notmatch '^[0-9a-f]{40}$'){ Fail "GIT_FAIL: cannot read HEAD" }
  return $h
}

function Get7zPath(){
  $candidates = @(
    'C:\Program Files\7-Zip\7z.exe',
    'C:\Program Files (x86)\7-Zip\7z.exe',
    "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
  )
  foreach($p in $candidates){ if(Test-Path -LiteralPath $p){ return $p } }
  return $null
}

function Assert7zPinned([string]$WantPrefix){
  $p = Get7zPath
  if(-not $p){ Fail "TOOLCHAIN_FAIL: 7z.exe not found" }
  $line = (& $p i | Select-String '^7-Zip ' | Select-Object -First 1).ToString().Trim()
  if($line -notmatch ('^' + [regex]::Escape($WantPrefix) + '(\s|$)')){ Fail "TOOLCHAIN_PIN_FAIL: want '$WantPrefix', got '$line'" }
  return [pscustomobject]@{ Path=$p; VersionLine=$line; Sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
}

function Sha256HexOfAscii([string]$s){
  $bytes = [Text.Encoding]::ASCII.GetBytes($s)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).ToLower().Replace('-','') }
  finally { $sha.Dispose() }
}

function AssertHex64([string]$label,[string]$hex){
  if($hex -notmatch '^[a-f0-9]{64}$'){ Fail "$label invalid (need 64 hex): $hex" }
}

function AssertOrdinalSorted([string[]]$arr,[string]$label){
  $s = $arr.Clone()
  [Array]::Sort($s,[StringComparer]::Ordinal)
  for($i=0;$i -lt $arr.Count;$i++){
    if($arr[$i] -ne $s[$i]){ Fail "$label not ordinal-sorted" }
  }
}

function AssertProvenanceAllowlist(){
  $allow = @(
    'release/provenance/manifest.json',
    'release/provenance/provenance.json',
    'release/provenance/semantic_hash.txt',
    'release/provenance/byte_hash.txt',
    'release/provenance/source_date_epoch.txt'
  ) | Sort-Object

  $tracked = @(git ls-files -- release/provenance 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ }) | Sort-Object
  if(($tracked -join "`n") -ne ($allow -join "`n")){
    $extra = @($tracked | Where-Object { $allow -notcontains $_ })
    $miss  = @($allow   | Where-Object { $tracked -notcontains $_ })
    $msg = @()
    if($extra.Count -gt 0){ $msg += "PROVENANCE_TRACKED_OUTSIDE_ALLOWLIST:`n" + ($extra -join "`n") }
    if($miss.Count  -gt 0){ $msg += "PROVENANCE_ALLOWLIST_MISSING_TRACKED:`n" + ($miss -join "`n") }
    Fail ($msg -join "`n`n")
  }
}

function LoadPackSpec(){
  $p = 'spec/pack_spec_v1_0_1.json'
  $txt = ReadUtf8NoBomLF $p
  $o = $txt | ConvertFrom-Json
  if([string]$o.version -ne '1.0.1'){ Fail "PACK_SPEC_FAIL: version != 1.0.1" }
  if(-not $o.build -or -not $o.build.toolchain){ Fail "PACK_SPEC_FAIL: missing build.toolchain" }
  if([string]$o.build.toolchain.zip_writer -ne '7-Zip 24.07'){ Fail "PACK_SPEC_FAIL: zip_writer != '7-Zip 24.07'" }
  if(-not $o.build.toolchain.flags -or $o.build.toolchain.flags.Count -lt 1){ Fail "PACK_SPEC_FAIL: flags missing/empty" }
  return $o
}

function LoadManifest(){
  $txt = ReadUtf8NoBomLF 'release/provenance/manifest.json'
  $mf = $txt | ConvertFrom-Json
  if([string]$mf.version -ne '1.0'){ Fail "MANIFEST_FAIL: version != 1.0" }
  if(-not $mf.files -or $mf.files.Count -lt 1){ Fail "MANIFEST_FAIL: files empty" }
  AssertHex64 'MANIFEST_FAIL: payload_digest' ([string]$mf.payload_digest)

  $paths = @($mf.files | ForEach-Object { [string]$_.path })
  foreach($p in $paths){
    if($p -notmatch '^(bundle_root/|spec/).+[^/]$' -or $p -match '\\|(^|/)\.\.(/|$)|^\.\/'){
      Fail "MANIFEST_FAIL: path rule violated: $p"
    }
  }
  AssertOrdinalSorted $paths 'MANIFEST_FAIL: files[].path'

  # ensure no duplicates
  $dups = $paths | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
  if($dups){ Fail ("MANIFEST_FAIL: duplicate paths:`n" + ($dups -join "`n")) }

  return $mf
}

function VerifyManifestFilesAndPayload($mf){
  # verify each file exists, size and sha match
  foreach($e in $mf.files){
    $p = [string]$e.path
    $sz = [int64]$e.size
    $sh = ([string]$e.sha256).ToLower()
    AssertHex64 "MANIFEST_FAIL: sha256 ($p)" $sh
    if(-not (Test-Path -LiteralPath $p)){ Fail "MISSING_FILE: $p" }

    $fi = Get-Item -LiteralPath $p
    if([int64]$fi.Length -ne $sz){ Fail "SIZE_MISMATCH: $p (got=$($fi.Length) want=$sz)" }

    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower()
    if($h -ne $sh){ Fail "SHA_MISMATCH: $p" }
  }

  # verify payload_digest from ordinal manifest list: path \t size \t sha \n (ASCII)
  $sb = New-Object System.Text.StringBuilder
  foreach($e in $mf.files){
    [void]$sb.AppendFormat("{0}`t{1}`t{2}`n",[string]$e.path,[int64]$e.size,([string]$e.sha256).ToLower())
  }
  $pd = Sha256HexOfAscii $sb.ToString()
  if($pd -ne ([string]$mf.payload_digest).ToLower()){
    Fail "PAYLOAD_DIGEST_MISMATCH"
  }
}

function LoadProvenance(){
  $txt = ReadUtf8NoBomLF 'release/provenance/provenance.json'
  $pj = $txt | ConvertFrom-Json
  if(-not $pj.source -or -not $pj.source.git_commit){ Fail "PROVENANCE_FAIL: source.git_commit missing" }
  if(-not $pj.zip -or -not $pj.zip.sha256){ Fail "PROVENANCE_FAIL: zip.sha256 missing" }
  AssertHex64 'PROVENANCE_FAIL: zip.sha256' (([string]$pj.zip.sha256).ToLower())
  if(-not $pj.build -or -not $pj.build.toolchain){ Fail "PROVENANCE_FAIL: build.toolchain missing" }
  if([string]$pj.build.toolchain.zip_writer -ne '7-Zip 24.07'){ Fail "PROVENANCE_FAIL: build.toolchain.zip_writer != '7-Zip 24.07'" }
  if(-not $pj.build.toolchain.flags -or $pj.build.toolchain.flags.Count -lt 1){ Fail "PROVENANCE_FAIL: build.toolchain.flags missing/empty" }
  return $pj
}

function VerifyAnchorFiles($mf,$pj){
  # semantic_hash.txt must match payload_digest
  $sem = ReadAsciiLF 'release/provenance/semantic_hash.txt'
  $wantSem = "RIS:K0:$(([string]$mf.payload_digest).ToLower())`n"
  if($sem -ne $wantSem){ Fail "SEMANTIC_HASH_MISMATCH" }

  # source_date_epoch.txt digits+LF, must match provenance.sde_unix if present
  $sdeRaw = ReadAsciiLF 'release/provenance/source_date_epoch.txt'
  if($sdeRaw -notmatch '^\A[0-9]+\n\z'){ Fail "SDE_FORMAT_FAIL" }
  $sde = [int64]($sdeRaw.Trim())
  if($pj.PSObject.Properties.Name -contains 'sde_unix'){
    if([int64]$pj.sde_unix -ne $sde){ Fail "SDE_MISMATCH (provenance.sde_unix != source_date_epoch.txt)" }
  }

  # byte_hash.txt must equal provenance.zip.sha256 + LF
  $bh = ReadAsciiLF 'release/provenance/byte_hash.txt'
  $wantBh = "$(([string]$pj.zip.sha256).ToLower())`n"
  if($bh -ne $wantBh){ Fail "BYTE_HASH_MISMATCH (byte_hash.txt != provenance.zip.sha256)" }
}

function VerifyNoRepoZipLeak(){
  # Under Contract A': ZIP and sidecar are Release-assets only, not repo artifacts.
  if(Test-Path -LiteralPath 'release\K0_bundle.zip'){ Fail "POLICY_FAIL: release\K0_bundle.zip must not exist in repo working tree" }
  if(Test-Path -LiteralPath 'release\K0_bundle.zip.sha256'){ Fail "POLICY_FAIL: release\K0_bundle.zip.sha256 must not exist in repo working tree" }
}

function VerifyBundle($mf,$pj,[string]$zip,[string]$side){
  if(-not (Test-Path -LiteralPath $zip)){ Fail "ZIP_MISSING: $zip" }
  if(-not (Test-Path -LiteralPath $side)){ Fail "SIDECAR_MISSING: $side" }

  $zipSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()
  if($zipSha -ne ([string]$pj.zip.sha256).ToLower()){ Fail "ZIP_SHA_MISMATCH (zip != provenance.zip.sha256)" }

  $sideRaw = Get-Content -Raw -Encoding ASCII -LiteralPath $side
  $wantSide = ("{0}  K0_bundle.zip`n" -f $zipSha)
  if($sideRaw -ne $wantSide){ Fail "SIDECAR_FORMAT_MISMATCH" }

  # SDE time for ZIP mtimes
  $sdeRaw = ReadAsciiLF 'release/provenance/source_date_epoch.txt'
  $sde = [int64]($sdeRaw.Trim())
  $dtUtc = [DateTimeOffset]::FromUnixTimeSeconds($sde).UtcDateTime

  Add-Type -AssemblyName System.IO.Compression
  $fs = [IO.File]::OpenRead($zip)
  try{
    $za = New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Read,$false)
    try{
      $entries = @($za.Entries)
      foreach($en in $entries){ if($en.FullName.EndsWith('/')){ Fail "ZIP_DIR_ENTRY_FORBIDDEN: $($en.FullName)" } }

      # path set must match
      $pathsM = @($mf.files | ForEach-Object { [string]$_.path })
      $pathsZ = @($entries | ForEach-Object { [string]$_.FullName })

      if($pathsZ.Count -ne $pathsM.Count){ Fail "ZIP_ENTRY_COUNT_MISMATCH (zip=$($pathsZ.Count) manifest=$($pathsM.Count))" }

      $zS = $pathsZ.Clone(); [Array]::Sort($zS,[StringComparer]::Ordinal)
      $mS = $pathsM.Clone(); [Array]::Sort($mS,[StringComparer]::Ordinal)
      for($i=0; $i -lt $mS.Count; $i++){
        if($zS[$i] -ne $mS[$i]){ Fail ("ZIP_MANIFEST_PATH_SET_MISMATCH at {0}: zip='{1}' manifest='{2}'" -f $i,$zS[$i],$mS[$i]) }
      }

      $specByPath = @{}
      foreach($s in $mf.files){ $specByPath[[string]$s.path] = $s }

      $sha2 = [Security.Cryptography.SHA256]::Create()
      try{
        foreach($en in $entries){
          $p = [string]$en.FullName
          $spec = $specByPath[$p]
          if(-not $spec){ Fail "ZIP_PATH_NOT_IN_MANIFEST: $p" }

          if([int64]$en.Length -ne [int64]$spec.size){
            Fail ("ZIP_SIZE_MISMATCH: {0} (zip={1} manifest={2})" -f $p,[int64]$en.Length,[int64]$spec.size)
          }

          $lwUtc = $en.LastWriteTime.UtcDateTime
          if($lwUtc -ne $dtUtc){
            Fail ("ZIP_MTIME_MISMATCH: {0} (got={1} want={2})" -f $p,$lwUtc.ToString("o"),$dtUtc.ToString("o"))
          }

          $st = $en.Open()
          try{ $hash = $sha2.ComputeHash($st) } finally { $st.Dispose() }
          $hex = ([BitConverter]::ToString($hash)).ToLower().Replace('-','')
          if($hex -ne ([string]$spec.sha256).ToLower()){
            Fail ("ZIP_FILE_SHA_MISMATCH: {0}" -f $p)
          }
        }
      } finally { $sha2.Dispose() }
    } finally { $za.Dispose() }
  } finally { $fs.Dispose() }
}

try {
  # repo root safety: assume script lives in repo root
  $here = Split-Path -Parent $MyInvocation.MyCommand.Path
  if($here){ Set-Location $here }

  # core structure
  foreach($d in @('bundle_root/kernel','spec','release','release/provenance','docs')){
    if(-not (Test-Path -LiteralPath $d)){ Fail "MISSING_DIR: $d" }
  }

  AssertProvenanceAllowlist
  VerifyNoRepoZipLeak

  $pack = LoadPackSpec
  $mf = LoadManifest
  VerifyManifestFilesAndPayload $mf
  $pj = LoadProvenance

  # git HEAD must match provenance.source.git_commit
  $head = GetGitHead
  if(([string]$pj.source.git_commit).ToLower() -ne $head.ToLower()){
    Fail "PROVENANCE_GIT_COMMIT_MISMATCH (provenance != HEAD)"
  }

  # anchor consistency checks
  VerifyAnchorFiles $mf $pj

  # pack spec flags must match provenance flags
  $pf = @($pack.build.toolchain.flags | ForEach-Object { [string]$_ })
  $vf = @($pj.build.toolchain.flags | ForEach-Object { [string]$_ })
  if(($pf -join "`n") -ne ($vf -join "`n")){ Fail "FLAGS_MISMATCH (pack_spec != provenance)" }

  # toolchain pin gate (always)
  $tc = Assert7zPinned '7-Zip 24.07'
  if($pj.build.toolchain.PSObject.Properties.Name -contains 'zip_writer_sha256'){
    if(([string]$pj.build.toolchain.zip_writer_sha256).ToLower() -ne $tc.Sha256){ Fail "ZIP_WRITER_SHA256_MISMATCH (provenance != local 7z.exe)" }
  }

  if($Mode -eq 'source'){
    Write-Host '=== SOURCE_STATE_CONSISTENT: PASS'
    exit 0
  }

  if($Mode -eq 'bundle'){
    if(-not $ZipPath){ Fail "BUNDLE_MODE_FAIL: -ZipPath required" }
    if(-not $SidecarPath){ Fail "BUNDLE_MODE_FAIL: -SidecarPath required" }
    VerifyBundle $mf $pj $ZipPath $SidecarPath
    Write-Host '=== BUNDLE_VALIDATED: PASS'
    exit 0
  }

  Fail "INTERNAL_FAIL: unknown mode"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
