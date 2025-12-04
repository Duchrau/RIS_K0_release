# verify_all.ps1
# Complete deterministic verification of the K0 system.
# Exit codes: 0 = success, 1 = failure

Write-Host "=== K0 Verification ===" -ForegroundColor Cyan

$errors = @()
$warnings = @()

# --- 1. Top-Level Directory Structure ---
Write-Host "Checking directory structure..." -ForegroundColor Yellow

$requiredDirs = @(
    "bundle_root/kernel",
    "spec",
    "release",
    "release/provenance",
    "docs"
)

foreach ($dir in $requiredDirs) {
    if (!(Test-Path $dir)) {
        $errors += "Missing required directory: $dir"
    } else {
        Write-Host "  ✓ $dir" -ForegroundColor Green
    }
}

# --- 2. Normative Files ---
Write-Host "`nChecking normative files..." -ForegroundColor Yellow

# Kernel JSON
if (!(Test-Path "bundle_root/kernel/objects_K0.json")) {
    $errors += "Missing objects_K0.json"
} else {
    try {
        Get-Content "bundle_root/kernel/objects_K0.json" -Raw | Test-Json
        Write-Host "  ✓ objects_K0.json (valid JSON)" -ForegroundColor Green
    } catch {
        $errors += "objects_K0.json contains invalid JSON: $_"
    }
}

# Specification files
$specFiles = @(
    "SYSTEM_SPEC_v1_0.md",
    "DIRECTORY_SPEC_v1_0.md", 
    "FILE_RULES_SPEC_v1_0.md",
    "GOVERNANCE_SPEC_v1_0.md"
)

foreach ($file in $specFiles) {
    $path = "spec/$file"
    if (!(Test-Path $path)) {
        $errors += "Missing specification: $file"
    } else {
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
}

# --- 3. Release Bundle ---
Write-Host "`nChecking release artifacts..." -ForegroundColor Yellow

if (Test-Path "release/K0_bundle.zip") {
    $zipSize = (Get-Item "release/K0_bundle.zip").Length
    if ($zipSize -eq 0) {
        $warnings += "K0_bundle.zip is empty (0 bytes)"
    } else {
        Write-Host "  ✓ K0_bundle.zip ($($zipSize) bytes)" -ForegroundColor Green
    }
} else {
    $errors += "Missing K0_bundle.zip"
}

if (Test-Path "release/K0_bundle.zip.sha256") {
    $hashFile = Get-Content "release/K0_bundle.zip.sha256" -Raw
    if ($hashFile.Trim().Length -eq 64) {
        Write-Host "  ✓ SHA256 file present" -ForegroundColor Green
    } else {
        $warnings += "SHA256 file may be malformed"
    }
} else {
    $errors += "Missing K0_bundle.zip.sha256"
}

# --- 4. Provenance Files ---
Write-Host "`nChecking provenance files..." -ForegroundColor Yellow

$provenanceFiles = @(
    "manifest.json",
    "semantic_hash_ns.txt", 
    "source_date_epoch.txt",
    "byte_hash.txt",
    "provenance.json"
)

foreach ($file in $provenanceFiles) {
    $path = "release/provenance/$file"
    if (!(Test-Path $path)) {
        $warnings += "Missing provenance file: $file"
    } else {
        $size = (Get-Item $path).Length
        Write-Host "  ✓ $file ($($size) bytes)" -ForegroundColor Green
    }
}

# --- 5. File Encoding and Format Checks ---
Write-Host "`nRunning format checks..." -ForegroundColor Yellow

# Check for BOM in JSON files
Get-ChildItem -Recurse -Filter *.json | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -and ($content[0] -eq 0xFEFF -or $content[0] -eq 0xFFFE)) {
        $errors += "JSON file contains BOM: $($_.FullName)"
    }
}

# Check spec files for basic Markdown structure
Get-ChildItem "spec/*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch "^# ") {
        $warnings += "Spec file missing H1 header: $($_.Name)"
    }
}

# --- 6. Summary ---
Write-Host "`n=== Verification Summary ===" -ForegroundColor Cyan

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  ⚠ $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  ✗ $error" -ForegroundColor Red
    }
    Write-Host "`n❌ Verification FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ Verification PASSED" -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        Write-Host "   (with $($warnings.Count) warning(s))" -ForegroundColor Yellow
    }
    exit 0
}

