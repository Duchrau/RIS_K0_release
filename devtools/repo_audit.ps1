# --- Kontext: sicherstellen, dass wir im Repo-Root sind ----------------------
Get-Location
git status -sb
git remote -v
git branch -vv
git config --get remote.origin.url

# --- Basis: Tooling / Umgebung ----------------------------------------------
$PSVersionTable
git --version
gh --version

# --- GitHub: Basis-Metadaten zum aktuellen Repo ------------------------------
$repoInfo = gh repo view --json nameWithOwner,defaultBranchRef,isPrivate,visibility,description,homepageUrl,sshUrl,licenseInfo,archived,disabled,securityPolicyUrl |
    ConvertFrom-Json
$repoInfo
$repoInfo.nameWithOwner
$repoInfo.defaultBranchRef

# --- GitHub: Branch-Liste & Default-Branch prüfen ---------------------------
git branch -a
git rev-parse HEAD
git rev-parse $repoInfo.defaultBranchRef.name

# --- GitHub: Branch-Protection für Default-Branch ----------------------------
$ownerRepo = $repoInfo.nameWithOwner
$defaultBranch = $repoInfo.defaultBranchRef.name
gh api "repos/$ownerRepo/branches/$defaultBranch/protection"

# Optional: develop-Branch, falls vorhanden
if (git branch -a | Select-String -SimpleMatch "remotes/origin/develop") {
    gh api "repos/$ownerRepo/branches/develop/protection"
}

# --- GitHub: Actions-Workflows & deren Status --------------------------------
$workflows = gh api "repos/$ownerRepo/actions/workflows" | ConvertFrom-Json
$workflows.total_count
$workflows.workflows | Select-Object id,name,path,created_at,updated_at,state

# Detail: letzte Runs je Workflow (limitiert) ---------------------------------
foreach ($wf in $workflows.workflows) {
    gh api "repos/$ownerRepo/actions/workflows/$($wf.id)/runs?per_page=5" |
        ConvertFrom-Json |
        Select-Object -ExpandProperty workflow_runs |
        Select-Object name,head_branch,event,status,conclusion,created_at,updated_at -First 5
}

# --- GitHub: Environments, Pages, Webhooks -----------------------------------
# Environments
gh api "repos/$ownerRepo/environments" | ConvertFrom-Json

# Pages
gh api "repos/$ownerRepo/pages" 2>$null

# Webhooks (nur Lesen)
gh api "repos/$ownerRepo/hooks?per_page=50" | ConvertFrom-Json |
    Select-Object id,active,events,config

# --- GitHub: Labels, Milestones, Projects (Next) -----------------------------
gh api "repos/$ownerRepo/labels?per_page=100" | ConvertFrom-Json |
    Select-Object name,color,description

gh api "repos/$ownerRepo/milestones?state=all&per_page=100" | ConvertFrom-Json |
    Select-Object number,title,state,description,due_on

gh api "repos/$ownerRepo/projects?per_page=50" 2>$null | ConvertFrom-Json

gh api "repos/$ownerRepo/projects?state=all&per_page=50" 2>$null | ConvertFrom-Json

# Projects (Next)
gh api "repos/$ownerRepo/projects?per_page=50&state=all" 2>$null | ConvertFrom-Json

# --- GitHub: Releases & Assets -----------------------------------------------
gh release list --limit 10

# Detailansicht der letzten/aktuellen Release (falls v1.0.0 existiert) -------
if (gh release view "v1.0.0" 2>$null) {
    gh release view "v1.0.0" --json tagName,name,body,createdAt,publishedAt,isDraft,isPrerelease,assets |
        ConvertFrom-Json
} else {
    $latestRel = gh release list --limit 1 --json tagName | ConvertFrom-Json
    if ($latestRel) {
        gh release view $latestRel[0].tagName --json tagName,name,body,createdAt,publishedAt,isDraft,isPrerelease,assets |
            ConvertFrom-Json
    }
}

# --- Repo-Tree: Topologie & Zielpfade ----------------------------------------
# Top-Level
Get-ChildItem -Force

# Kernverzeichnisse, falls vorhanden
@('kernel','spec','views','tools','logs','reports','release','docs','.github') |
    ForEach-Object {
        if (Test-Path $_) {
            Write-Host "`n=== DIR: $_ ==="
            Get-ChildItem $_ -Recurse | Select-Object FullName,Length,LastWriteTime
        } else {
            Write-Host "`n=== DIR fehlt: $_ ==="
        }
    }

# --- .github/Workflows & Governance-Dateien ----------------------------------
if (Test-Path ".github\workflows") {
    Get-ChildItem ".github\workflows" -File
    Get-Content ".github\workflows\validate-docs.yml" -Raw 2>$null
    Get-Content ".github\workflows\validate-bundle.yml" -Raw 2>$null
    Get-Content ".github\workflows\build-pdf.yml" -Raw 2>$null
}

# CODEOWNERS, SECURITY, CONTRIBUTING, CITATION, SPECS --------------------------
@('.github\CODEOWNERS','CODEOWNERS','SECURITY.md','CONTRIBUTING.md','CITATION.cff',
  'DIRECTORY_SPEC.md','DIRECTORY_SPEC.txt','GOVERNANCE_SPEC.md','SYSTEM_SPEC.md','META_SPEC.md') |
    ForEach-Object {
        if (Test-Path $_) {
            Write-Host "`n=== FILE: $_ ==="
            Get-Content $_ -Raw
        }
    }

# --- Docs: Ist-Zustand (für spätere K0-Härtung / Alias-Bereinigung) ----------
if (Test-Path "docs") {
    Write-Host "`n=== docs/ Struktur ==="
    Get-ChildItem "docs" -Recurse | Select-Object FullName,Length

    @(
        "docs\index.md",
        "docs\background.md",
        "docs\overview.md",
        "docs\overview.pdf",
        "docs\technical_overview.md",
        "docs\verification.md",
        "docs\consumer_guide.md",
        "docs\reflexive_fixpoint_system.md",
        "docs\rfs.md",
        "docs\metaframe\fixpoint_core_spec_v1_0.md",
        "docs\readme.md"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Write-Host "`n=== CONTENT: $_ ==="
            Get-Content $_ -Raw
        }
    }
}

# --- Release-Verzeichnis & ZIP-Inhalt prüfen (nur lesend) --------------------
if (Test-Path "release") {
    Write-Host "`n=== release/ Struktur ==="
    Get-ChildItem "release" -Recurse | Select-Object FullName,Length

    $zipPath = Get-ChildItem "release" -Filter "*.zip" | Select-Object -First 1 -ExpandProperty FullName
    if ($zipPath) {
        Write-Host "`n=== ZIP-Inhalt (read-only) ==="
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        $zip.Entries | ForEach-Object {
            [PSCustomObject]@{
                FullName   = $_.FullName
                Length     = $_.Length
                Compressed = $_.CompressedLength
            }
        }
        $zip.Dispose()
    }

    # Manifest/Provenance-Dateien, falls direkt im Repo vorhanden
    @("release\manifest.json","release\provenance.json") |
        ForEach-Object {
            if (Test-Path $_) {
                Write-Host "`n=== CONTENT: $_ ==="
                Get-Content $_ -Raw
            }
        }
}

# --- Tools/Checker: Inventar & Inhalte (read-only) ---------------------------
if (Test-Path "tools") {
    Write-Host "`n=== tools/ Struktur ==="
    Get-ChildItem "tools" -Recurse | Select-Object FullName,Length

    Get-ChildItem "tools" -Recurse -File |
        Where-Object { $_.Extension -in ".ps1",".py",".psm1" } |
        ForEach-Object {
            Write-Host "`n=== TOOL CONTENT: $($_.FullName) ==="
            Get-Content $_.FullName -Raw
        }
}

# --- Line-Ending / Encoding-Policy: .gitattributes / .editorconfig -----------
@(".gitattributes",".editorconfig") |
    ForEach-Object {
        if (Test-Path $_) {
            Write-Host "`n=== CONTENT: $_ ==="
            Get-Content $_ -Raw
        }
    }

# --- Normative vs. non-normative Pfade prüfen (ASCII/LF-Zonen) ---------------
$normativeRoots = @("kernel","spec","views","tools","logs","reports","release")
foreach ($root in $normativeRoots) {
    if (Test-Path $root) {
        Write-Host "`n=== Normative Zone: $root ==="
        Get-ChildItem $root -Recurse -File | Select-Object FullName,Length
    }
}

# --- Git-Config: CI/Workflow/Einstellungen lokal -----------------------------
git config --list
