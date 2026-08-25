$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"
if (-not (Test-Path $path)) { throw "Niet gevonden: $path" }

$lines = [System.Collections.Generic.List[string]](Get-Content -Path $path -Encoding UTF8)

function Find-UniqueLine {
    param([string]$Label, [scriptblock]$Predicate)
    $hits = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (& $Predicate $lines[$i]) { $hits += $i }
    }
    if ($hits.Count -eq 0) { throw "Anker '$Label' niet gevonden. Er is niets gewijzigd." }
    if ($hits.Count -gt 1) { throw "Anker '$Label' komt meer dan één keer voor. Er is niets gewijzigd." }
    return $hits[0]
}

# Veiligheidschecks: bestaande permalinkbasis + BRO moeten aanwezig zijn.
$stateHere = Find-UniqueLine "permalinkWhatIsHere" {
    param($l) $l.Trim() -eq 'permalinkWhatIsHere: null'
}
$parseBase = Find-UniqueLine "parse base" {
    param($l) $l.Trim() -eq 'var base = params.get("base");'
}
$returnHereLon = Find-UniqueLine "return hereLon" {
    param($l) $l.Trim() -eq 'hereLon: Number.isFinite(hereLon) ? hereLon : null'
}
$hashBase = Find-UniqueLine "hash base" {
    param($l) $l.Trim() -eq 'params.set("base", state.permalinkBase);'
}
$restoreBase = Find-UniqueLine "restore base" {
    param($l) $l.Trim() -eq 'state.permalinkBase = permalink.base;'
}
$broSoilEnd = Find-UniqueLine "BRO bodemkaart laag" {
    param($l) $l.Trim() -eq 'var broBodemkaartLayer = L.tileLayer.wms('
}
$baseLayerIf = Find-UniqueLine "basislaag keuze" {
    param($l) $l.Trim() -eq 'if (state.permalinkBase === "air") {'
}
$baseLayerListener = Find-UniqueLine "baselayerchange" {
    param($l) $l.Trim() -eq 'map.on("baselayerchange", function (e) {'
}
$nlogOperatorAssign = Find-UniqueLine "NLOG operator change" {
    param($l) $l.Trim() -eq 'state.nlogOperatorFilter = select.value;'
}
$nlogFieldsAssign = Find-UniqueLine "NLOG fields change" {
    param($l) $l.Trim() -eq 'state.nlogShowFields = fieldsToggle.checked;'
}
$nlogFacilitiesAssign = Find-UniqueLine "NLOG facilities change" {
    param($l) $l.Trim() -eq 'state.nlogShowFacilities = facilitiesToggle.checked;'
}

$joined = $lines -join "`n"
if ($joined -match 'permalinkBroGt|broGt|broSoil|nlogOperatorFilter: params\.get') {
    throw "Uitgebreide permalink-instellingen lijken al aanwezig. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.permalinks-uitgebreid-$timestamp-backup"
Copy-Item $path $backup -Force

# Werk steeds via opnieuw zoeken zodat regelnummers niet verschuiven.

# 1. NLOG change handlers laten hash bijwerken.
foreach ($needle in @(
    'state.nlogOperatorFilter = select.value;',
    'state.nlogShowFields = fieldsToggle.checked;',
    'state.nlogShowFacilities = facilitiesToggle.checked;'
)) {
    $idx = Find-UniqueLine "NLOG wijziging $needle" { param($l) $l.Trim() -eq $needle }
    # Na de eerstvolgende renderNlogLayers(); binnen enkele regels.
    $renderIdx = -1
    for ($j = $idx; $j -lt [Math]::Min($idx + 6, $lines.Count); $j++) {
        if ($lines[$j].Trim() -eq 'renderNlogLayers();') { $renderIdx = $j; break }
    }
    if ($renderIdx -lt 0) { throw "renderNlogLayers() na '$needle' niet gevonden. Er is niets gewijzigd." }
    $lines.Insert($renderIdx + 1, '        updatePermalinkHash();')
}

# 2. BRO overlay listeners na baselayerchange-blok invoegen.
$listenerStart = Find-UniqueLine "baselayerchange opnieuw" {
    param($l) $l.Trim() -eq 'map.on("baselayerchange", function (e) {'
}
$listenerEnd = -1
for ($j = $listenerStart; $j -lt [Math]::Min($listenerStart + 10, $lines.Count); $j++) {
    if ($lines[$j].Trim() -eq '});') { $listenerEnd = $j; break }
}
if ($listenerEnd -lt 0) { throw "Einde baselayerchange-listener niet gevonden." }

$broListenerLines = [string[]]@(
    '',
    '    map.on("overlayadd", function (e) {',
    '      if (e.layer === broGrondwaterLayer) state.permalinkBroGt = true;',
    '      if (e.layer === broBodemkaartLayer) state.permalinkBroSoil = true;',
    '      updatePermalinkHash();',
    '    });',
    '',
    '    map.on("overlayremove", function (e) {',
    '      if (e.layer === broGrondwaterLayer) state.permalinkBroGt = false;',
    '      if (e.layer === broBodemkaartLayer) state.permalinkBroSoil = false;',
    '      updatePermalinkHash();',
    '    });'
)
$lines.InsertRange($listenerEnd + 1, $broListenerLines)

# 3. BRO-lagen herstellen uit permalink vóór basislaagkeuze.
$baseIf = Find-UniqueLine "basislaag keuze opnieuw" {
    param($l) $l.Trim() -eq 'if (state.permalinkBase === "air") {'
}
$restoreBroLines = [string[]]@(
    '    if (state.permalinkBroGt) broGrondwaterLayer.addTo(map);',
    '    if (state.permalinkBroSoil) broBodemkaartLayer.addTo(map);',
    ''
)
$lines.InsertRange($baseIf, $restoreBroLines)

# 4. Parsed NLOG/BRO state herstellen na permalinkBase.
$restoreBase = Find-UniqueLine "restore base opnieuw" {
    param($l) $l.Trim() -eq 'state.permalinkBase = permalink.base;'
}
$restoreLines = [string[]]@(
    '    state.nlogOperatorFilter = permalink.nlogOperatorFilter;',
    '    state.nlogShowFields = permalink.nlogShowFields;',
    '    state.nlogShowFacilities = permalink.nlogShowFacilities;',
    '    state.permalinkBroGt = permalink.broGt;',
    '    state.permalinkBroSoil = permalink.broSoil;'
)
$lines.InsertRange($restoreBase + 1, $restoreLines)

# 5. updatePermalinkHash uitbreiden na base.
$hashBase = Find-UniqueLine "hash base opnieuw" {
    param($l) $l.Trim() -eq 'params.set("base", state.permalinkBase);'
}
$hashExtra = [string[]]@(
    '',
    '    if (state.nlogOperatorFilter === "nam") params.set("nlog", "nam");',
    '    if (!state.nlogShowFields) params.set("fields", "0");',
    '    if (state.nlogShowFacilities) params.set("facilities", "1");',
    '    if (state.permalinkBroGt) params.set("broGt", "1");',
    '    if (state.permalinkBroSoil) params.set("broSoil", "1");'
)
$lines.InsertRange($hashBase + 1, $hashExtra)

# 6. parsePermalinkHash variabelen toevoegen.
$parseBase = Find-UniqueLine "parse base opnieuw" {
    param($l) $l.Trim() -eq 'var base = params.get("base");'
}
$parseExtra = [string[]]@(
    '    var nlog = params.get("nlog");',
    '    var fields = params.get("fields");',
    '    var facilities = params.get("facilities");',
    '    var broGt = params.get("broGt");',
    '    var broSoil = params.get("broSoil");'
)
$lines.InsertRange($parseBase + 1, $parseExtra)

# 7. Return-object uitbreiden: hereLon krijgt komma, daarna instellingen.
$returnHereLon = Find-UniqueLine "return hereLon opnieuw" {
    param($l) $l.Trim() -eq 'hereLon: Number.isFinite(hereLon) ? hereLon : null'
}
$lines[$returnHereLon] = '      hereLon: Number.isFinite(hereLon) ? hereLon : null,'
$returnExtra = [string[]]@(
    '      nlogOperatorFilter: nlog === "nam" ? "nam" : "all",',
    '      nlogShowFields: fields !== "0",',
    '      nlogShowFacilities: facilities === "1",',
    '      broGt: broGt === "1",',
    '      broSoil: broSoil === "1"'
)
$lines.InsertRange($returnHereLon + 1, $returnExtra)

# 8. State uitbreiden.
$stateHere = Find-UniqueLine "state permalinkWhatIsHere opnieuw" {
    param($l) $l.Trim() -eq 'permalinkWhatIsHere: null'
}
$indent = ($lines[$stateHere] -replace 'permalinkWhatIsHere: null.*$', '')
$lines[$stateHere] = $indent + 'permalinkWhatIsHere: null,'
$lines.InsertRange($stateHere + 1, [string[]]@(
    $indent + 'permalinkBroGt: false,',
    $indent + 'permalinkBroSoil: false'
))

Set-Content -Path $path -Value $lines -Encoding UTF8

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Permalinks uitgebreid met:"
Write-Host "  - NLOG operator (alle/NAM)"
Write-Host "  - NLOG velden aan/uit"
Write-Host "  - NLOG mijnbouwlocaties aan/uit"
Write-Host "  - BRO Grondwaterspiegeldiepte aan/uit"
Write-Host "  - BRO Bodemkaart aan/uit"
Write-Host ""
Write-Host "Bestaand blijft:"
Write-Host "  - kaartcentrum, zoom, ondergrond"
Write-Host "  - Wat ligt hier?-locatie"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
