$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# 1. State uitbreiden met permalinkgegevens.
$statePattern = '(?m)^    whatIsHereArmed: false$'
$stateReplacement = @'
    whatIsHereArmed: false,
    permalinkBase: "map",
    permalinkWhatIsHere: null
'@

# 2. Permalinkfuncties toevoegen vóór initMap().
$initMapPattern = '(?m)^  function initMap\(\) \{'

$permalinkFunctions = @'
  function parsePermalinkHash() {
    var raw = window.location.hash ? window.location.hash.substring(1) : "";
    var params = new URLSearchParams(raw);

    var lat = parseFloat(params.get("lat"));
    var lon = parseFloat(params.get("lon"));
    var zoom = parseInt(params.get("z"), 10);
    var base = params.get("base");
    var hereLat = parseFloat(params.get("hereLat"));
    var hereLon = parseFloat(params.get("hereLon"));

    return {
      lat: Number.isFinite(lat) ? lat : null,
      lon: Number.isFinite(lon) ? lon : null,
      zoom: Number.isFinite(zoom) ? zoom : null,
      base: base === "air" ? "air" : "map",
      hereLat: Number.isFinite(hereLat) ? hereLat : null,
      hereLon: Number.isFinite(hereLon) ? hereLon : null
    };
  }

  function updatePermalinkHash() {
    if (!map) return;

    var center = map.getCenter();
    var params = new URLSearchParams();

    params.set("lat", center.lat.toFixed(5));
    params.set("lon", center.lng.toFixed(5));
    params.set("z", String(map.getZoom()));
    params.set("base", state.permalinkBase);

    if (state.permalinkWhatIsHere) {
      params.set("hereLat", state.permalinkWhatIsHere.lat.toFixed(5));
      params.set("hereLon", state.permalinkWhatIsHere.lon.toFixed(5));
    }

    var nextHash = "#" + params.toString();
    if (window.location.hash !== nextHash) {
      history.replaceState(null, "", nextHash);
    }
  }

  function restorePermalinkWhatIsHere() {
    if (!state.permalinkWhatIsHere) return;
    showWhatIsHere(
      state.permalinkWhatIsHere.lat,
      state.permalinkWhatIsHere.lon
    );
  }

'@

# 3. initMap() aanpassen zodat startpositie en base layer uit hash komen.
$mapStartPattern = '(?ms)^  function initMap\(\) \{\r?\n    map = L\.map\("map", \{ center: \[52\.2, 5\.3\], zoom: 8 \}\);\r?\n    var cartoLayer = L\.tileLayer\("https://\{s\}\.basemaps\.cartocdn\.com/light_all/\{z\}/\{x\}/\{y\}\{r\}\.png", \{\r?\n      attribution: ''&copy; <a href="https://carto\.com/attributions">CARTO</a> &copy; OpenStreetMap contributors'',\r?\n      maxZoom: 19\r?\n    \}\)\.addTo\(map\);'

$mapStartReplacement = @'
  function initMap() {
    var permalink = parsePermalinkHash();
    var startCenter = (
      permalink.lat !== null && permalink.lon !== null
    ) ? [permalink.lat, permalink.lon] : [52.2, 5.3];
    var startZoom = permalink.zoom !== null ? permalink.zoom : 8;

    state.permalinkBase = permalink.base;
    if (permalink.hereLat !== null && permalink.hereLon !== null) {
      state.permalinkWhatIsHere = {
        lat: permalink.hereLat,
        lon: permalink.hereLon
      };
    }

    map = L.map("map", { center: startCenter, zoom: startZoom });
    var cartoLayer = L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", {
      attribution: '&copy; <a href="https://carto.com/attributions">CARTO</a> &copy; OpenStreetMap contributors',
      maxZoom: 19
    });
'@

# 4. PDOK-blok gevolgd door conditioneel toevoegen van de juiste base layer.
$pdokPattern = '(?ms)(^    var pdokLuchtfotoLayer = L\.tileLayer\.wms\(\r?\n      "https://service\.pdok\.nl/hwh/luchtfotorgb/wms/v1_0",\r?\n      \{\r?\n        layers: "Actueel_ortho25",\r?\n        format: "image/jpeg",\r?\n        transparent: false,\r?\n        version: "1\.3\.0",\r?\n        attribution: "PDOK / Beeldmateriaal"\r?\n      \}\r?\n    \);\r?\n)'

$pdokReplacement = @'
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

    if (state.permalinkBase === "air") {
      pdokLuchtfotoLayer.addTo(map);
    } else {
      cartoLayer.addTo(map);
    }

'@

# 5. Listeners toevoegen direct na layer control.
$controlPattern = '(?ms)(^    L\.control\.layers\(\r?\n      \{\r?\n        "Kaart": cartoLayer,\r?\n        "Luchtfoto": pdokLuchtfotoLayer\r?\n      \},\r?\n      null,\r?\n      \{\r?\n        position: "topright",\r?\n        collapsed: true\r?\n      \}\r?\n    \)\.addTo\(map\);\r?\n)'

$controlReplacement = @'
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

    map.on("moveend", updatePermalinkHash);

    map.on("baselayerchange", function (e) {
      state.permalinkBase = e.layer === pdokLuchtfotoLayer ? "air" : "map";
      updatePermalinkHash();
    });

'@

# 6. Wat ligt hier?-klik opslaan in permalink.
$whatClickPattern = '(?m)^      showWhatIsHere\(e\.latlng\.lat, e\.latlng\.lng\);$'
$whatClickReplacement = @'
      state.permalinkWhatIsHere = {
        lat: e.latlng.lat,
        lon: e.latlng.lng
      };
      showWhatIsHere(e.latlng.lat, e.latlng.lng);
      updatePermalinkHash();
'@

# 7. Na initWhatIsHere() een herstelde locatie tonen en hash normaliseren.
$initPattern = '(?m)^  initWhatIsHere\(\);\r?\n  loadNlogLayers\(\);'
$initReplacement = @'
  initWhatIsHere();
  restorePermalinkWhatIsHere();
  updatePermalinkHash();
  loadNlogLayers();
'@

$checks = @(
    @{ Name = "state"; Pattern = $statePattern },
    @{ Name = "initMap-anker"; Pattern = $initMapPattern },
    @{ Name = "map-start"; Pattern = $mapStartPattern },
    @{ Name = "PDOK-blok"; Pattern = $pdokPattern },
    @{ Name = "layer-control"; Pattern = $controlPattern },
    @{ Name = "Wat ligt hier klik"; Pattern = $whatClickPattern },
    @{ Name = "initialisatie"; Pattern = $initPattern }
)

foreach ($check in $checks) {
    $matches = [regex]::Matches($content, $check.Pattern)
    if ($matches.Count -eq 0) {
        throw "Het verwachte blok '$($check.Name)' is niet gevonden. Er is niets gewijzigd."
    }
    if ($matches.Count -gt 1) {
        throw "Het blok '$($check.Name)' komt meer dan één keer voor. Er is niets gewijzigd."
    }
}

if ($content -match 'function parsePermalinkHash\(') {
    throw "Permalinkfunctionaliteit lijkt al aanwezig. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.permalinks-$timestamp-backup"
Copy-Item $path $backup -Force

$content = [regex]::Replace($content, $statePattern, $stateReplacement, 1)
$content = [regex]::Replace(
    $content,
    $initMapPattern,
    $permalinkFunctions + '  function initMap() {',
    1
)
$content = [regex]::Replace($content, $mapStartPattern, $mapStartReplacement, 1)
$content = [regex]::Replace($content, $pdokPattern, $pdokReplacement, 1)
$content = [regex]::Replace($content, $controlPattern, $controlReplacement, 1)
$content = [regex]::Replace($content, $whatClickPattern, $whatClickReplacement, 1)
$content = [regex]::Replace($content, $initPattern, $initReplacement, 1)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Permalinks stap 1:"
Write-Host "  - kaartcentrum"
Write-Host "  - zoomniveau"
Write-Host "  - ondergrond: kaart/luchtfoto"
Write-Host "  - gekozen 'Wat ligt hier?'-locatie"
Write-Host ""
Write-Host "Nog NIET toegevoegd:"
Write-Host "  - NLOG-filters"
Write-Host "  - monumentfilters"
Write-Host "  - tijdslider"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
