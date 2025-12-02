Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Get-Location).Path
$bundleRoot = Join-Path $repo "bundle_root"
$release = Join-Path $repo "release"
$prov = Join-Path $release "provenance"

$zipPath  = Join-Path $release "K0_bundle.zip"
$shaPath  = Join-Path $release "K0_bundle.zip.sha256"

Remove-Item $zipPath -Force -ErrorAction Ignore
Remove-Item $shaPath -Force -ErrorAction Ignore
Remove-Item $prov -Recurse -Force -ErrorAction Ignore
New-Item -ItemType Directory -Path $prov | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem

$entries = Get-ChildItem $bundleRoot -Recurse -File | Sort-Object FullName

# ZIP erstellen
$fs = New-Object IO.FileStream($zipPath, [IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false)

foreach ($e in $entries) {
    $relative = $e.FullName.Substring($bundleRoot.Length+1).Replace("\","/")
    $entry = $zip.CreateEntry($relative, [System.IO.Compression.CompressionLevel]::NoCompression)

    $body = $entry.Open()
    [byte[]]$bytes = [IO.File]::ReadAllBytes($e.FullName)
    $body.Write($bytes, 0, $bytes.Length)
    $body.Dispose()

    # Deterministische Zeit
    $entry.LastWriteTime = (Get-Date "2025-01-01T00:00:00Z")
}

$zip.Dispose()
$fs.Dispose()

# Provenance rebuild (unchanged)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipR = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

$manifest = @{
    files = $zipR.Entries |
        Sort-Object FullName |
        ForEach-Object {
            $stream = $_.Open()
            $sha = (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash.ToLower()
            $stream.Dispose()
            @{ path = $_.FullName; sha256 = $sha }
        }
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$prov/manifest.json"
Add-Content "$prov/manifest.json" "`n"

($zipR.Entries.FullName -join "`n") + "`n" |
    Set-Content "$prov/semantic_hash_ns.txt"

(Get-Date -UFormat %s) | Set-Content -Encoding ascii "$prov/source_date_epoch.txt"
Add-Content "$prov/source_date_epoch.txt" "`n"

$bytes = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
"$bytes  K0_bundle.zip" |
    Set-Content -Encoding utf8 "$prov/byte_hash.txt"
Add-Content "$prov/byte_hash.txt" "`n"

@{
    status = "ARCHIVE_LOCKED"
    bundle = "K0_bundle.zip"
    generated = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 5 |
    Set-Content -Encoding utf8 "$prov/provenance.json"
Add-Content "$prov/provenance.json" "`n"

$zipR.Dispose()

# SHA256
$hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
Set-Content $shaPath "$hash`n" -Encoding ascii

Write-Host "BUILD COMPLETED"
