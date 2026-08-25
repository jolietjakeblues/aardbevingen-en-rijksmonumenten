$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "documentation\DATA.md"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

$oldTable = @'
| Aardbevingen (alle ~3.750, 1911-heden) | eenmalig bij laden van de pagina | **KNMI**, rechtstreeks (`rdsa.knmi.nl`, CSV) |
| Rijksmonumenten binnen straal | bij elke selectie/straal-wijziging (gedebounced, 350ms) | RCE CHO linked data, live SPARQL |
| Kaarttegels | doorlopend tijdens pannen/zoomen | CARTO (extern, CDN) |
| Leaflet-library | eenmalig bij laden | unpkg CDN |
'@

$newTable = @'
| Aardbevingen (alle ~3.750, 1911-heden) | eenmalig bij laden van de pagina | **KNMI**, rechtstreeks (`rdsa.knmi.nl`, CSV) |
| Rijksmonumenten binnen straal | bij elke selectie/straal-wijziging (gedebounced, 350ms) | RCE CHO linked data, live SPARQL |
| NLOG mijnbouwvelden en mijnbouwlocaties | eenmalig bij laden van de pagina | NLOG / Geologische Dienst Nederland, live WFS |
| CARTO-kaarttegels | doorlopend tijdens pannen/zoomen | CARTO (extern, CDN) |
| PDOK-luchtfoto | alleen wanneer deze ondergrond actief is, tijdens pannen/zoomen | PDOK / Beeldmateriaal, live WMS |
| Leaflet-library | eenmalig bij laden | unpkg CDN |
'@

$oldSources = @'
- **Aardbevingen:** KNMI, rechtstreeks opgehaald als CSV via `rdsa.knmi.nl`. De categorieën
  `induced` en `tectonic` worden afzonderlijk bevraagd.
- **Rijksmonumenten:** RCE Cultureel Erfgoed Open Data, via het CHO SPARQL-endpoint.
- **Ontologie:** CEO, de Cultureel Erfgoed Ontologie van de Rijksdienst voor het Cultureel
  Erfgoed.

De gebruikte endpoints ondersteunen CORS. Daardoor kan de browser de gegevens rechtstreeks
ophalen en is geen eigen backend of proxy nodig.
'@

$newSources = @'
- **Aardbevingen:** KNMI, rechtstreeks opgehaald als CSV via `rdsa.knmi.nl`. De categorieën
  `induced` en `tectonic` worden afzonderlijk bevraagd.
- **Rijksmonumenten:** RCE Cultureel Erfgoed Open Data, via het CHO SPARQL-endpoint.
- **Mijnbouwvelden en mijnbouwlocaties:** NLOG / Geologische Dienst Nederland via de publieke
  WFS-service (`https://www.gdngeoservices.nl/geoserver/nlog/ows`). De applicatie gebruikt
  onder meer `gdw_ng_field_utm` en `gdw_ng_facility_utm`.
- **Luchtfoto:** PDOK / Beeldmateriaal via de RGB-luchtfoto WMS
  (`https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0`), laag `Actueel_ortho25`.
- **Ontologie:** CEO, de Cultureel Erfgoed Ontologie van de Rijksdienst voor het Cultureel
  Erfgoed.

De gebruikte data-endpoints ondersteunen browsergebruik zonder eigen backend. De applicatie
bevraagt KNMI, RCE en NLOG rechtstreeks; kaart- en luchtfototegels worden door Leaflet bij de
betreffende externe kaartdienst opgehaald.
'@

$insertBefore = @'
## Rijksmonumenten: filtering en dataqualiteit
'@

$nlogSection = @'
## NLOG: mijnbouwlagen

De NLOG-integratie laadt twee typen objecten rechtstreeks uit de publieke WFS-service:

- **Mijnbouwvelden:** `gdw_ng_field_utm`. Deze laag staat standaard aan en wordt op type
  gestileerd (onder andere gas, olie, geothermie en opslag).
- **Mijnbouwlocaties:** `gdw_ng_facility_utm`. Deze puntlaag staat standaard uit en kan in de
  zijbalk worden ingeschakeld.

De gebruiker kan client-side filteren op alle operators of alleen NAM. De data wordt niet in de
repository opgeslagen. Bij het laden vraagt de applicatie eerst de beschikbare WFS-laagnamen op
via `GetCapabilities`; daarna wordt GeoJSON opgehaald via WFS 2.0.0, met WFS 1.1.0 als fallback.

## PDOK-luchtfoto

Naast de standaard lichte CARTO-ondergrond kan de gebruiker overschakelen naar de actuele
RGB-luchtfoto van PDOK / Beeldmateriaal. De luchtfoto wordt als WMS-laag geladen en is alleen
actief wanneer de gebruiker deze ondergrond kiest. CARTO blijft de standaardondergrond.

'@

$checks = @(
    @{ Name = "live-tabel"; Old = $oldTable },
    @{ Name = "databronnen"; Old = $oldSources },
    @{ Name = "sectie-invoegpunt"; Old = $insertBefore }
)

foreach ($check in $checks) {
    $count = ([regex]::Matches($content, [regex]::Escape($check.Old))).Count
    if ($count -eq 0) {
        throw "Het verwachte blok '$($check.Name)' is niet gevonden. Er is niets gewijzigd."
    }
    if ($count -gt 1) {
        throw "Het blok '$($check.Name)' komt meer dan één keer voor. Er is niets gewijzigd."
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.nlog-pdok-$timestamp-backup"
Copy-Item $path $backup -Force

$content = $content.Replace($oldTable, $newTable)
$content = $content.Replace($oldSources, $newSources)
$content = $content.Replace($insertBefore, $nlogSection + $insertBefore)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: documentation\DATA.md"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd:"
Write-Host "  - NLOG in live-datatabel en databronnen"
Write-Host "  - NLOG WFS-laagnamen en laadgedrag"
Write-Host "  - PDOK luchtfoto in live-datatabel en databronnen"
Write-Host "  - korte secties over NLOG en PDOK"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- documentation/DATA.md"
