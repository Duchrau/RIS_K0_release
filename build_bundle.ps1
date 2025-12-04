# build_bundle.ps1
# Deterministic K0 bundle creation

param(
    [string]$OutputPath = "release/K0_bundle.zip",
    [switch]$Force
)

Write-Host "=== K0 Deterministic Bundle Builder ===" -ForegroundColor Cyan

# Check existing bundle
if ((Test-Path $OutputPath) -and (-not $Force)) {
    Write-Host "Error: Bundle already exists at $OutputPath" -ForegroundColor Red
    Write-Host "Use -Force to overwrite" -ForegroundColor Yellow
    exit 1
}

# Create temporary directory with deterministic structure
$tempDir = "$env:TEMP\k0_bundle_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Define files to include (deterministic order)
    $filesToInclude = @(
        "bundle_root/kernel/objects_K0.json",
        "spec/SYSTEM_SPEC_v1_0.md",
        "spec/DIRECTORY_SPEC_v1_0.md",
        "spec/FILE_RULES_SPEC_v1_0.md",
        "spec/GOVERNANCE_SPEC_v1_0.md",
        "verify_all.ps1"
    )

    # Copy files in deterministic order
    foreach ($file in $filesToInclude) {
        if (Test-Path $file) {
            $destPath = Join-Path $tempDir $file
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $file -Destination $destPath -Force
            Write-Host "  Added: $file" -ForegroundColor Green
        } else {
            Write-Host "  Error: Missing required file: $file" -ForegroundColor Red
            exit 1
        }
    }

    # Create ZIP with deterministic compression
    Write-Host "`nCreating ZIP archive..." -ForegroundColor Yellow
    Compress-Archive -Path "$tempDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal -Force
    
    $zipSize = (Get-Item $OutputPath).Length
    Write-Host "  Created: $OutputPath ($($zipSize) bytes)" -ForegroundColor Green

    # Generate SHA256
    $hash = Get-FileHash $OutputPath -Algorithm SHA256
    $hash.Hash | Set-Content "$OutputPath.sha256" -Encoding UTF8
    Write-Host "  SHA256: $($hash.Hash)" -ForegroundColor Cyan

} finally {
    # Cleanup
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Bundle creation complete" -ForegroundColor Green
