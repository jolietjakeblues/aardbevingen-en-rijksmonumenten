$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# 1. State uitbreiden.
$stateOld = @'
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false,
    whatIsHereArmed: false
'@

$stateNew = @'
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false,
    whatIsHereArmed: false,
    permalinkBase: "map",
    permalinkWhatIsHere: null
'@

# 2. Permalinkfuncties invoegen direct vóór initMap().
$initMapAnchor = '  function initMap() {'

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

# 3. Begin van initMap aanpassen.
$mapStartOld = @'
  function initMap() {
    map = L.map("map", { center: [52.2, 5.3], zoom: 8 });
    var cartoLayer = L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", {
      attribution: '&copy; <a href="https://carto.com/attributions">CARTO</a> &copy; OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(map);
'@

$mapStartNew = @'
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

# 4. PDOK-laag gevolgd door de juiste startondergrond.
$pdokOld = @'
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
'@

$pdokNew = @'
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

# 5. Layer control uitbreiden met permalink-listeners.
$controlOld = @'
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

$controlNew = @'
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

# 6. Wat ligt hier?-klik ook in permalink bewaren.
$clickOld = @'
      showWhatIsHere(e.latlng.lat, e.latlng.lng);
'@

$clickNew = @'
      state.permalinkWhatIsHere = {
        lat: e.latlng.lat,
        lon: e.latlng.lng
      };
      showWhatIsHere(e.latlng.lat, e.latlng.lng);
      updatePermalinkHash();
'@

# 7. Herstellen na initWhatIsHere().
$initOld = @'
  initNlogControls();
  initWhatIsHere();
  loadNlogLayers();
  loadEarthquakes();
'@

$initNew = @'
  initNlogControls();
  initWhatIsHere();
  restorePermalinkWhatIsHere();
  updatePermalinkHash();
  loadNlogLayers();
  loadEarthquakes();
'@

$replacements = @(
    @{ Name = "state"; Old = $stateOld; New = $stateNew },
    @{ Name = "map-start"; Old = $mapStartOld; New = $mapStartNew },
    @{ Name = "PDOK-blok"; Old = $pdokOld; New = $pdokNew },
    @{ Name = "layer-control"; Old = $controlOld; New = $controlNew },
    @{ Name = "Wat ligt hier klik"; Old = $clickOld; New = $clickNew },
    @{ Name = "initialisatie"; Old = $initOld; New = $initNew }
)

foreach ($r in $replacements) {
    $count = ([regex]::Matches($content, [regex]::Escape($r.Old))).Count
    if ($count -eq 0) {
        throw "Het verwachte blok '$($r.Name)' is niet gevonden. Er is niets gewijzigd."
    }
    if ($count -gt 1) {
        throw "Het blok '$($r.Name)' komt meer dan één keer voor. Er is niets gewijzigd."
    }
}

$initMapCount = ([regex]::Matches($content, [regex]::Escape($initMapAnchor))).Count
if ($initMapCount -ne 1) {
    throw "initMap() komt niet exact één keer voor. Er is niets gewijzigd."
}

if ($content -match 'function parsePermalinkHash\(') {
    throw "Permalinkfunctionaliteit lijkt al aanwezig. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.permalinks-$timestamp-backup"
Copy-Item $path $backup -Force

foreach ($r in $replacements) {
    $content = $content.Replace($r.Old, $r.New)
}

$content = $content.Replace(
    $initMapAnchor,
    $permalinkFunctions + $initMapAnchor
)

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
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
