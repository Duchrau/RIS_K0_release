Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# === PATHS ============================================================
$zipPath = Join-Path "release" "K0_bundle.zip"
$shaPath = Join-Path "release" "K0_bundle.zip.sha256"
$prov    = Join-Path "release" "provenance"

$normativeDirs = @(
    "bundle_root",
    "spec",
    "tools",
    $prov
)

# === 1. SHA256 VALIDATION =============================================
if (!(Test-Path $zipPath) -or !(Test-Path $shaPath)) {
    Write-Host "ERROR: Missing release asset or SHA256 file" -ForegroundColor Red
    exit 1
}

$expected = (Get-Content $shaPath -Raw).Trim().Split()[0].ToLower()
$actual   = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()

if ($expected -ne $actual) {
    Write-Host "SHA256 MISMATCH" -ForegroundColor Red
    exit 2
}

# === 2. REQUIRED DIRECTORIES ==========================================
foreach ($dir in $normativeDirs) {
    if (!(Test-Path $dir)) {
        Write-Host "ERROR: Missing directory: $dir" -ForegroundColor Red
        exit 3
    }
}

# === 3. PROVENANCE STRUCTURE ==========================================
$requiredFiles = @(
    "manifest.json",
    "semantic_hash_ns.txt",
    "source_date_epoch.txt",
    "byte_hash.txt",
    "provenance.json"
)

foreach ($file in $requiredFiles) {
    if (!(Test-Path (Join-Path $prov $file))) {
        Write-Host "ERROR: Missing provenance file: $file" -ForegroundColor Red
        exit 4
    }
}

$actualFiles = @( Get-ChildItem $prov -File | Select-Object -ExpandProperty Name )
$extra = @($actualFiles | Where-Object { $_ -notin $requiredFiles })

if ($extra.Count -gt 0) {
    Write-Host "ERROR: Unexpected files in provenance: $extra" -ForegroundColor Red
    exit 5
}

# === 4. NORMATIVE FILE SCAN ===========================================
$normativeFiles = @()
$normativeFiles += Get-ChildItem "bundle_root" -Recurse -File
$normativeFiles += Get-ChildItem "spec"        -Recurse -File
$normativeFiles += Get-ChildItem "tools"       -Recurse -File
$normativeFiles += Get-ChildItem $prov         -File

$fileCount = $normativeFiles.Count

# === 5. JSON VALIDATION ===============================================
$jsonFiles = $normativeFiles | Where-Object { $_.Extension -eq '.json' }

foreach ($jsonFile in $jsonFiles) {
    try {
        $content = Get-Content $jsonFile.FullName -Raw
        $null = $content | ConvertFrom-Json
    }
    catch {
        Write-Host "ERROR: Invalid JSON: $($jsonFile.Name)" -ForegroundColor Red
        exit 6
    }
}

# === SUCCESS ==========================================================
Write-Host "VERIFY_ALL PASSED" -ForegroundColor Green
Write-Host "Files scanned: $fileCount" -ForegroundColor Gray
exit 0
