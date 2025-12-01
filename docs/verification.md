**Nein, nicht 1:1!** Die Inhalte aus dem Word-Dokument müssen **angepasst** werden:

## ✅ Was du übernehmen kannst (fast 1:1):
- Struktur und Text der Dokumente
- Code-Blöcke und Anleitungen  
- PRE_FORMAL Blöcke (RFS/FPC)
- Policies und Konventionen

## ⚠️ Was du **anpassen** musst:
1. **Platzhalter für Hashes/IDs** → leer lassen oder `_________` belassen
2. **Veraltete Referenzen** → auf aktuellen Stand prüfen
3. **Pfade** → müssen zur aktuellen Struktur passen
4. **Workflow-Namen** → müssen existieren (rewind-temp.yml)

## 📋 Konkrete Aktion für jedes Dokument:

### 1. **README.md** (oberste Ebene)
- Übernehme den "Readme"-Abschnitt aus Word
- Behalte Platzhalter für Fingerprint/Tag/Filename
- **Achtung:** Pfade in Struktur-Darstellung prüfen

### 2. **docs/background.md**
- Ist schon vorhanden und aktuell ✓
- Nur prüfen ob Platzhalter drin sind

### 3. **docs/consumer_guide.md**
- Übernehme "CONSUMERS --- Quick Verification"-Abschnitt
- PowerShell-Code prüfen (escaping!)

### 4. **docs/overview.md**
- Übernehme "Overview.md"-Abschnitt aus Word
- PDF-Erstellungs-Skript **unten dranhängen** (als separater Abschnitt)

### 5. **docs/technical_overview.md**
- Übernehme "Technical Deep Dive" Inhalt
- Keine veralteten Referenzen

### 6. **docs/verification.md**
- Übernehme "VERIFY --- Full Verification Procedure"
- Fingerprint SHA256 anpassen/leerlassen

### 7. **docs/reflexive_fixpoint_system.md**
- Übernehme RFS-Abschnitt aus Word
- PRE_FORMAL Blöcke sind schon in rfs.md ✓

### 8. **docs/fixpoint_core_spec_v1_0.md**
- Ist schon aktualisiert mit PRE_FORMAL Blöcken ✓

---

## 🎯 Empfehlung:
1. **Beginne mit README.md** (wichtigste Datei)
2. **Dann consumer_guide.md** (für Nutzer)
3. **Zuletzt overview.md** (inkl. PDF-Skript)

## 📦 PDF-Erstellung via PowerShell:
Für `overview.md` füge diesen Abschnitt **ganz unten** ein:

```markdown
## PDF Reproduction (deterministic, Win11 + Pandoc + TinyTeX)

```powershell
# 0) Set paths
$Root = $PWD
$In = Join-Path $Root 'docs\overview.md'
$Out = Join-Path $Root 'docs\overview.pdf'

# 1) Ensure LF + ASCII (no BOM, stable input)
$md = [IO.File]::ReadAllText($In) -replace "`r`n","`n"
[IO.File]::WriteAllBytes($In, [Text.Encoding]::ASCII.GetBytes($md))

# 2) Fix repro environment
$env:LC_ALL = 'C'  # fixed locale
$env:LANG = 'C'
$env:SOURCE_DATE_EPOCH = '1704067200'  # example: 2024-01-01 00:00:00 UTC

# 3) Build PDF (no date stamps/variable content; pdflatex is more stable than xelatex)
pandoc $In `
  --from gfm `
  --to pdf `
  --pdf-engine=pdflatex `
  -V papersize:a4 `
  -V geometry:margin=2.5cm `
  -V colorlinks=false -V linkcolor=black -V urlcolor=black `
  --metadata=date: '' `
  --output $Out

# 4) Output hash (for sidecar if desired)
$sha = (Get-FileHash $Out -Algorithm SHA256).Hash.ToLower()
"$sha $(Split-Path -Leaf $Out)"
```

**Möchtest du mit README.md beginnen?** Ich kann dir den genauen, angepassten Inhalt dafür geben.
