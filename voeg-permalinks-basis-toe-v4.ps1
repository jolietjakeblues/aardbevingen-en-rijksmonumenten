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

# Eerst ALLE ankers controleren. Pas daarna maken we een backup en wijzigen we iets.
$stateIndex = Find-UniqueLine "whatIsHereArmed" {
    param($line)
    $line.Trim() -eq 'whatIsHereArmed: false'
}

$initMapIndex = Find-UniqueLine "initMap" {
    param($line)
    $line.Trim() -eq 'function initMap() {'
}

$mapCreateIndex = Find-UniqueLine "map-aanmaak" {
    param($line)
    $line.Trim() -eq 'map = L.map("map", { center: [52.2, 5.3], zoom: 8 });'
}

$cartoStartIndex = Find-UniqueLine "CARTO-laag" {
    param($line)
    $line -like '*var cartoLayer = L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/*'
}

$pdokEndIndex = -1
$pdokStartIndex = Find-UniqueLine "PDOK-laag" {
    param($line)
    $line.Trim() -eq 'var pdokLuchtfotoLayer = L.tileLayer.wms('
}

for ($i = $pdokStartIndex; $i -lt [Math]::Min($pdokStartIndex + 20, $lines.Count); $i++) {
    if ($lines[$i].Trim() -eq ');') {
        $pdokEndIndex = $i
        break
    }
}
if ($pdokEndIndex -lt 0) {
    throw "Einde van het PDOK-blok is niet gevonden. Er is niets gewijzigd."
}

$controlEndIndex = -1
$controlStartIndex = Find-UniqueLine "layer-control" {
    param($line)
    $line.Trim() -eq 'L.control.layers('
}
for ($i = $controlStartIndex; $i -lt [Math]::Min($controlStartIndex + 30, $lines.Count); $i++) {
    if ($lines[$i].Trim() -eq ').addTo(map);') {
        $controlEndIndex = $i
        break
    }
}
if ($controlEndIndex -lt 0) {
    throw "Einde van de layer control is niet gevonden. Er is niets gewijzigd."
}

if (($lines -join "`n") -match 'function parsePermalinkHash\(') {
    throw "Permalinkfunctionaliteit lijkt al aanwezig. Er is niets gewijzigd."
}

# Zoek specifiek de }).addTo(map); die bij de CARTO-laag hoort.
$cartoEndIndex = -1
for ($i = $cartoStartIndex; $i -lt [Math]::Min($cartoStartIndex + 10, $lines.Count); $i++) {
    if ($lines[$i].Trim() -eq '}).addTo(map);') {
        $cartoEndIndex = $i
        break
    }
}
if ($cartoEndIndex -lt 0) {
    throw "Einde van de CARTO-laag is niet gevonden. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.permalinks-$timestamp-backup"
Copy-Item $path $backup -Force

# Werk van onder naar boven zodat eerder gevonden regelnummers geldig blijven.

# A. Listeners na de bestaande layer control.
$listenerLines = [string[]]@(
    '',
    '    map.on("moveend", updatePermalinkHash);',
    '',
    '    map.on("baselayerchange", function (e) {',
    '      state.permalinkBase = e.layer === pdokLuchtfotoLayer ? "air" : "map";',
    '      updatePermalinkHash();',
    '    });'
)
$lines.InsertRange($controlEndIndex + 1, $listenerLines)

# B. Juiste ondergrond activeren na het PDOK-blok.
$baseLines = [string[]]@(
    '',
    '    if (state.permalinkBase === "air") {',
    '      pdokLuchtfotoLayer.addTo(map);',
    '    } else {',
    '      cartoLayer.addTo(map);',
    '    }'
)
$lines.InsertRange($pdokEndIndex + 1, $baseLines)

# C. CARTO niet meer automatisch toevoegen.
$lines[$cartoEndIndex] = $lines[$cartoEndIndex].Replace('}).addTo(map);', '});')

# D. Vaste map-aanmaak vervangen door hashgestuurde startpositie.
$mapCreateReplacement = [string[]]@(
    '    var permalink = parsePermalinkHash();',
    '    var startCenter = (',
    '      permalink.lat !== null && permalink.lon !== null',
    '    ) ? [permalink.lat, permalink.lon] : [52.2, 5.3];',
    '    var startZoom = permalink.zoom !== null ? permalink.zoom : 8;',
    '',
    '    state.permalinkBase = permalink.base;',
    '    map = L.map("map", { center: startCenter, zoom: startZoom });'
)
$lines.RemoveAt($mapCreateIndex)
$lines.InsertRange($mapCreateIndex, $mapCreateReplacement)

# E. Permalinkfuncties vóór initMap().
# initMap is door D naar beneden verschoven; opnieuw zoeken op inhoud.
$initMapIndex = Find-UniqueLine "initMap na map-aanpassing" {
    param($line)
    $line.Trim() -eq 'function initMap() {'
}

$functionLines = [string[]]@(
    '  function parsePermalinkHash() {',
    '    var raw = window.location.hash ? window.location.hash.substring(1) : "";',
    '    var params = new URLSearchParams(raw);',
    '    var lat = parseFloat(params.get("lat"));',
    '    var lon = parseFloat(params.get("lon"));',
    '    var zoom = parseInt(params.get("z"), 10);',
    '    var base = params.get("base");',
    '',
    '    return {',
    '      lat: Number.isFinite(lat) ? lat : null,',
    '      lon: Number.isFinite(lon) ? lon : null,',
    '      zoom: Number.isFinite(zoom) ? zoom : null,',
    '      base: base === "air" ? "air" : "map"',
    '    };',
    '  }',
    '',
    '  function updatePermalinkHash() {',
    '    if (!map) return;',
    '    var center = map.getCenter();',
    '    var params = new URLSearchParams();',
    '    params.set("lat", center.lat.toFixed(5));',
    '    params.set("lon", center.lng.toFixed(5));',
    '    params.set("z", String(map.getZoom()));',
    '    params.set("base", state.permalinkBase);',
    '',
    '    var nextHash = "#" + params.toString();',
    '    if (window.location.hash !== nextHash) {',
    '      history.replaceState(null, "", nextHash);',
    '    }',
    '  }',
    ''
)
$lines.InsertRange($initMapIndex, $functionLines)

# F. State uitbreiden. Opnieuw zoeken, omdat invoegingen regelnummers hebben verschoven.
$stateIndex = Find-UniqueLine "whatIsHereArmed na invoegingen" {
    param($line)
    $line.Trim() -eq 'whatIsHereArmed: false'
}
$indent = ($lines[$stateIndex] -replace 'whatIsHereArmed: false.*$', '')
$lines[$stateIndex] = $indent + 'whatIsHereArmed: false,'
$lines.Insert($stateIndex + 1, $indent + 'permalinkBase: "map"')

Set-Content -Path $path -Value $lines -Encoding UTF8

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Permalinks stap 1:"
Write-Host "  - kaartcentrum"
Write-Host "  - zoomniveau"
Write-Host "  - ondergrond: kaart/luchtfoto"
Write-Host ""
Write-Host "Bewust nog NIET toegevoegd:"
Write-Host "  - Wat ligt hier?-locatie"
Write-Host "  - NLOG-filters"
Write-Host "  - monumentfilters"
Write-Host "  - tijdslider"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
