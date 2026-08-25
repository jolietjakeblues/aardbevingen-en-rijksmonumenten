$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$lines = [System.Collections.Generic.List[string]](Get-Content -Path $path -Encoding UTF8)

function Find-UniqueLine {
    param(
        [string]$Label,
        [scriptblock]$Predicate
    )

    $matches = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (& $Predicate $lines[$i]) {
            $matches += $i
        }
    }

    if ($matches.Count -eq 0) {
        throw "Anker '$Label' is niet gevonden. Er is niets gewijzigd."
    }
    if ($matches.Count -gt 1) {
        throw "Anker '$Label' komt meer dan één keer voor. Er is niets gewijzigd."
    }

    return $matches[0]
}

# Eerst alle ankers controleren.
$stateIndex = Find-UniqueLine "permalinkBase state" {
    param($line)
    $line.Trim() -eq 'permalinkBase: "map"'
}

$baseParseIndex = Find-UniqueLine "base parse" {
    param($line)
    $line.Trim() -eq 'var base = params.get("base");'
}

$returnBaseIndex = Find-UniqueLine "base return" {
    param($line)
    $line.Trim() -eq 'base: base === "air" ? "air" : "map"'
}

$hashBaseIndex = Find-UniqueLine "base hash" {
    param($line)
    $line.Trim() -eq 'params.set("base", state.permalinkBase);'
}

$clickShowIndex = Find-UniqueLine "Wat ligt hier show" {
    param($line)
    $line.Trim() -eq 'showWhatIsHere(e.latlng.lat, e.latlng.lng);'
}

$initWhatIndex = Find-UniqueLine "initWhatIsHere" {
    param($line)
    $line.Trim() -eq 'initWhatIsHere();'
}

$statePermalinkSetIndex = Find-UniqueLine "state permalinkBase restore" {
    param($line)
    $line.Trim() -eq 'state.permalinkBase = permalink.base;'
}

if (($lines -join "`n") -match 'permalinkWhatIsHere|hereLat|hereLon') {
    throw "Wat ligt hier?-permalink lijkt al aanwezig. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.permalink-wat-ligt-hier-$timestamp-backup"
Copy-Item $path $backup -Force

# Werk van onder naar boven.

# 1. Tijdens initialisatie herstelde locatie tonen.
$restoreInitLines = [string[]]@(
    '  if (state.permalinkWhatIsHere) {',
    '    showWhatIsHere(',
    '      state.permalinkWhatIsHere.lat,',
    '      state.permalinkWhatIsHere.lon',
    '    );',
    '  }',
    '  updatePermalinkHash();'
)
$lines.InsertRange($initWhatIndex + 1, $restoreInitLines)

# 2. Kliklocatie bewaren vóór showWhatIsHere().
$clickShowIndex = Find-UniqueLine "Wat ligt hier show na init-invoeging" {
    param($line)
    $line.Trim() -eq 'showWhatIsHere(e.latlng.lat, e.latlng.lng);'
}
$clickLines = [string[]]@(
    '      state.permalinkWhatIsHere = {',
    '        lat: e.latlng.lat,',
    '        lon: e.latlng.lng',
    '      };'
)
$lines.InsertRange($clickShowIndex, $clickLines)

# Voeg updatePermalinkHash direct na show toe.
$clickShowIndex = Find-UniqueLine "Wat ligt hier show voor hash-update" {
    param($line)
    $line.Trim() -eq 'showWhatIsHere(e.latlng.lat, e.latlng.lng);'
}
$lines.Insert($clickShowIndex + 1, '      updatePermalinkHash();')

# 3. Parsed hereLat/hereLon in state zetten.
$statePermalinkSetIndex = Find-UniqueLine "state permalinkBase restore na invoegingen" {
    param($line)
    $line.Trim() -eq 'state.permalinkBase = permalink.base;'
}
$restoreStateLines = [string[]]@(
    '    if (permalink.hereLat !== null && permalink.hereLon !== null) {',
    '      state.permalinkWhatIsHere = {',
    '        lat: permalink.hereLat,',
    '        lon: permalink.hereLon',
    '      };',
    '    }'
)
$lines.InsertRange($statePermalinkSetIndex + 1, $restoreStateLines)

# 4. Hashschrijver uitbreiden.
$hashBaseIndex = Find-UniqueLine "base hash na invoegingen" {
    param($line)
    $line.Trim() -eq 'params.set("base", state.permalinkBase);'
}
$hashHereLines = [string[]]@(
    '',
    '    if (state.permalinkWhatIsHere) {',
    '      params.set("hereLat", state.permalinkWhatIsHere.lat.toFixed(5));',
    '      params.set("hereLon", state.permalinkWhatIsHere.lon.toFixed(5));',
    '    }'
)
$lines.InsertRange($hashBaseIndex + 1, $hashHereLines)

# 5. parsePermalinkHash uitbreiden.
$returnBaseIndex = Find-UniqueLine "base return na invoegingen" {
    param($line)
    $line.Trim() -eq 'base: base === "air" ? "air" : "map"'
}
$lines[$returnBaseIndex] = '      base: base === "air" ? "air" : "map",'
$lines.InsertRange($returnBaseIndex + 1, [string[]]@(
    '      hereLat: Number.isFinite(hereLat) ? hereLat : null,',
    '      hereLon: Number.isFinite(hereLon) ? hereLon : null'
))

$baseParseIndex = Find-UniqueLine "base parse na invoegingen" {
    param($line)
    $line.Trim() -eq 'var base = params.get("base");'
}
$lines.InsertRange($baseParseIndex + 1, [string[]]@(
    '    var hereLat = parseFloat(params.get("hereLat"));',
    '    var hereLon = parseFloat(params.get("hereLon"));'
))

# 6. State uitbreiden.
$stateIndex = Find-UniqueLine "permalinkBase state na invoegingen" {
    param($line)
    $line.Trim() -eq 'permalinkBase: "map"'
}
$indent = ($lines[$stateIndex] -replace 'permalinkBase: "map".*$', '')
$lines[$stateIndex] = $indent + 'permalinkBase: "map",'
$lines.Insert($stateIndex + 1, $indent + 'permalinkWhatIsHere: null')

Set-Content -Path $path -Value $lines -Encoding UTF8

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd aan permalink:"
Write-Host "  - hereLat"
Write-Host "  - hereLon"
Write-Host "  - gekozen 'Wat ligt hier?'-locatie wordt bij openen hersteld"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
