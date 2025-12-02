Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# === CONFIG (platform-neutral) =============================================
$zipPath = Join-Path "release" "K0_bundle.zip"
$shaPath = Join-Path "release" "K0_bundle.zip.sha256"
$prov    = Join-Path "release" "provenance"

$requiredDirs = @(
    "bundle_root",
    "spec",
    "tools",
    $prov
)

$requiredProv = @(
    "manifest.json",
    "semantic_hash_ns.txt",
    "source_date_epoch.txt",
    "byte_hash.txt",
    "provenance.json"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# === 1. SHA256 VALIDATION ===================================================
if (!(Test-Path $zipPath) -or !(Test-Path $shaPath)) {
    Write-Host "ERROR: Missing release asset or SHA256 file" -ForegroundColor Red
    exit 1
}

$expected = (Get-Content $shaPath -Raw).Trim().Split(' ')[0].ToLower()
$actual   = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()

if ($expected -ne $actual) {
    Write-Host "ERROR: SHA256 mismatch" -ForegroundColor Red
    exit 2
}

# === 2. REQUIRED DIRECTORIES ================================================
foreach ($dir in $requiredDirs) {
    if (!(Test-Path $dir)) {
        Write-Host "ERROR: Missing directory: $dir" -ForegroundColor Red
        exit 3
    }
}

# === 3. PROVENANCE STRUCTURE ================================================
foreach ($file in $requiredProv) {
    $path = Join-Path $prov $file
    if (!(Test-Path $path)) {
        Write-Host "ERROR: Missing provenance file: $file" -ForegroundColor Red
        exit 4
    }
}

$actualFiles = Get-ChildItem $prov -File | Select-Object -ExpandProperty Name
$extra       = @($actualFiles | Where-Object { $_ -notin $requiredProv })

if ($extra.Count -gt 0) {
    Write-Host "ERROR: Unexpected files in provenance: $($extra -join ', ')" -ForegroundColor Red
    exit 5
}

# === 4. ZIP / MANIFEST CONSISTENCY ==========================================
$zip      = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$entries  = $zip.Entries | Sort-Object FullName

$manifestPath = Join-Path $prov "manifest.json"
$manifest     = Get-Content $manifestPath -Raw | ConvertFrom-Json

$mf = $manifest.files.path
$zf = $entries.FullName

if ($mf.Count -ne $zf.Count) {
    $zip.Dispose()
    Write-Host "ERROR: Manifest file count mismatch" -ForegroundColor Red
    exit 7
}

for ($i = 0; $i -lt $mf.Count; $i++) {
    if ($mf[$i] -ne $zf[$i]) {
        $zip.Dispose()
        Write-Host "ERROR: Manifest entry mismatch at index $i" -ForegroundColor Red
        exit 8
    }
}

$zip.Dispose()

# === 5. JSON VALIDATION ON NORMATIVE FILES ==================================
$normFiles = @()
$normFiles += Get-ChildItem "bundle_root" -Recurse -File
$normFiles += Get-ChildItem "spec"        -Recurse -File
$normFiles += Get-ChildItem "tools"       -Recurse -File
$normFiles += Get-ChildItem $prov         -File

$jsonFiles = $normFiles | Where-Object { $_.Extension -eq ".json" }

foreach ($jf in $jsonFiles) {
    try {
        $null = (Get-Content $jf.FullName -Raw | ConvertFrom-Json)
    } catch {
        Write-Host "ERROR: Invalid JSON in $($jf.FullName)" -ForegroundColor Red
        exit 6
    }
}

# === SUCCESS ================================================================
Write-Host "VERIFY_ALL PASSED" -ForegroundColor Green
exit 0
