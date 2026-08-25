$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "README.md"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

$oldFeatures = @'
- Laatst geregistreerde beving: een regel bovenaan de zijbalk toont direct de meest recente
  beving uit de volledige dataset, als indicatie van hoe actueel de live KNMI-data is.
- Toegankelijkheid: verborgen labels, `aria-live`-statusmeldingen, toetsenbordbedienbare legenda.
'@

$newFeatures = @'
- Laatst geregistreerde beving: een regel bovenaan de zijbalk toont direct de meest recente
  beving uit de volledige dataset, als indicatie van hoe actueel de live KNMI-data is.
- NLOG mijnbouwlagen: toont olie-, gas-, geothermie- en opslagvelden plus mijnbouwlocaties,
  met operatorfilter voor alle operators of alleen NAM. Velden staan standaard aan;
  mijnbouwlocaties zijn optioneel.
- Alternatieve ondergrond: schakel tussen de lichte CARTO-kaart en de actuele RGB-luchtfoto
  van PDOK / Beeldmateriaal.
- Toegankelijkheid: verborgen labels, `aria-live`-statusmeldingen, toetsenbordbedienbare legenda.
'@

$oldSources = @'
- **Aardbevingen:** KNMI, rechtstreeks via `rdsa.knmi.nl` (CSV).
- **Rijksmonumenten:** RCE Cultureel Erfgoed Linked Open Data, via het CHO SPARQL-endpoint (CEO-ontologie).
'@

$newSources = @'
- **Aardbevingen:** KNMI, rechtstreeks via `rdsa.knmi.nl` (CSV).
- **Rijksmonumenten:** RCE Cultureel Erfgoed Linked Open Data, via het CHO SPARQL-endpoint (CEO-ontologie).
- **Mijnbouwvelden en mijnbouwlocaties:** NLOG / Geologische Dienst Nederland, via de publieke WFS-service.
- **Luchtfoto:** PDOK / Beeldmateriaal, via de actuele RGB-luchtfoto WMS.
'@

$oldThanks = @'
- Het KNMI voor de openbare aardbevingsgegevens.
- De Rijksdienst voor het Cultureel Erfgoed voor de linked data over rijksmonumenten en de
  Cultureel Erfgoed Ontologie.
- Het Instituut Mijnbouwschade Groningen voor de gepubliceerde gegevens over effectgebieden.
- Leaflet en CARTO voor de kaartweergave.
'@

$newThanks = @'
- Het KNMI voor de openbare aardbevingsgegevens.
- De Rijksdienst voor het Cultureel Erfgoed voor de linked data over rijksmonumenten en de
  Cultureel Erfgoed Ontologie.
- NLOG / Geologische Dienst Nederland voor de openbare mijnbouwgegevens.
- PDOK / Beeldmateriaal voor de actuele RGB-luchtfoto.
- Het Instituut Mijnbouwschade Groningen voor de gepubliceerde gegevens over effectgebieden.
- Leaflet en CARTO voor de kaartweergave.
'@

$checks = @(
    @{ Name = "featurelijst"; Old = $oldFeatures; New = $newFeatures },
    @{ Name = "databronnen"; Old = $oldSources; New = $newSources },
    @{ Name = "dankwoord"; Old = $oldThanks; New = $newThanks }
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
$backup = "$path.documentatie-$timestamp-backup"
Copy-Item $path $backup -Force

foreach ($check in $checks) {
    $content = $content.Replace($check.Old, $check.New)
}

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: README.md"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd aan README:"
Write-Host "  - NLOG mijnbouwvelden en mijnbouwlocaties"
Write-Host "  - NAM/operatorfilter"
Write-Host "  - PDOK luchtfoto als alternatieve ondergrond"
Write-Host "  - NLOG en PDOK bij databronnen en dankwoord"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- README.md"
