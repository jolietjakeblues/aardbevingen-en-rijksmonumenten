$ErrorActionPreference = "Stop"

$root = Get-Location
$source = Join-Path $root "aardbevingen_en_rijksmonumenten_v0.20.5.html"
$target = Join-Path $root "docs\index.html"

if (-not (Test-Path $source)) {
    throw "Bronbestand niet gevonden: $source"
}
if (-not (Test-Path $target)) {
    throw "GitHub Pages-bestand niet gevonden: $target"
}

$sourceContent = Get-Content -Raw -Encoding UTF8 $source

# Alleen synchroniseren als de lokale kaart daadwerkelijk de NLOG-integratie bevat.
$requiredMarkers = @(
    'NLOG_WFS_ENDPOINT',
    'nlogFieldLayer',
    'NLOG mijnbouw'
)

foreach ($marker in $requiredMarkers) {
    if ($sourceContent.IndexOf($marker) -lt 0) {
        throw "Bronbestand bevat de verwachte NLOG-integratie niet: ontbrekend kenmerk '$marker'."
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$target.$timestamp-backup"

Copy-Item $target $backup -Force
Copy-Item $source $target -Force

Write-Host ""
Write-Host "GitHub Pages-versie gesynchroniseerd."
Write-Host "Bron:     $source"
Write-Host "Doel:     $target"
Write-Host "Back-up:  $backup"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
Write-Host ""
Write-Host "Lokaal testen:"
Write-Host "  python -m http.server 8000"
Write-Host "  http://localhost:8000/docs/"
Write-Host ""
Write-Host "Als alles goed is:"
Write-Host "  git add aardbevingen_en_rijksmonumenten_v0.20.5.html docs/index.html"
Write-Host '  git commit -m "Voeg NLOG mijnbouwlagen en filters toe"'
Write-Host "  git push -u origin feature/nlog-mijnbouwlagen"
