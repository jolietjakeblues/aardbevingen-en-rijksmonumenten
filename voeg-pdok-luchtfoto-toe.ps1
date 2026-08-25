$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

$old = @'
    L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", {
      attribution: '&copy; <a href="https://carto.com/attributions">CARTO</a> &copy; OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(map);
'@

$new = @'
    var cartoLayer = L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", {
      attribution: '&copy; <a href="https://carto.com/attributions">CARTO</a> &copy; OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(map);

    var pdokLuchtfotoLayer = L.tileLayer.wms(
      "https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0",
      {
        layers: "Actueel_ortho25",
        format: "image/jpeg",
        transparent: false,
        version: "1.3.0",
        attribution: "PDOK / Beeldmateriaal"
      }
    );

    L.control.layers(
      {
        "Kaart": cartoLayer,
        "Luchtfoto": pdokLuchtfotoLayer
      },
      null,
      {
        position: "topright",
        collapsed: true
      }
    ).addTo(map);
'@

$count = ([regex]::Matches($content, [regex]::Escape($old))).Count

if ($count -eq 0) {
    throw "Het verwachte CARTO-blok is niet gevonden. Er is niets gewijzigd."
}

if ($count -gt 1) {
    throw "Het CARTO-blok komt meer dan één keer voor. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.pdok-luchtfoto-$timestamp-backup"

Copy-Item $path $backup -Force

$content = $content.Replace($old, $new)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd:"
Write-Host "  - CARTO blijft standaard"
Write-Host "  - PDOK luchtfoto als tweede ondergrond"
Write-Host "  - Leaflet laagkeuze rechtsboven"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
