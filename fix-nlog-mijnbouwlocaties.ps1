$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

$old = @'
          radius: 7,
          color: "#ffffff",
          weight: 2.5,
          fillColor: "#d81b60",
          fillOpacity: 1,
          pane: "markerPane"
'@

$new = @'
          radius: 5,
          color: "#ffffff",
          weight: 1.5,
          fillColor: "#d81b60",
          fillOpacity: 0.9,
          pane: "markerPane"
'@

$count = ([regex]::Matches($content, [regex]::Escape($old))).Count

if ($count -eq 0) {
    throw "De verwachte NLOG-markerstijl is niet gevonden. Er is niets gewijzigd."
}

if ($count -gt 1) {
    throw "De markerstijl komt meer dan één keer voor. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.marker-size-$timestamp-backup"

Copy-Item $path $backup -Force

$content = $content.Replace($old, $new)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Nieuwe mijnbouwmarker:"
Write-Host "  radius: 5"
Write-Host "  weight: 1.5"
Write-Host "  fillOpacity: 0.9"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
Write-Host ""
Write-Host "Test daarna via localhost en commit pas als het er goed uitziet."
