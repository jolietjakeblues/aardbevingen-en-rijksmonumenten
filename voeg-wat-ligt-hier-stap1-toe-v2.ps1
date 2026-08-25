$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# 1. Paneel invoegen direct vóór het bestaande NLOG-paneel
$panelPattern = '(?m)^    <div class="panel" id="nlogPanel">\r?\n      <h2>NLOG mijnbouw</h2>'
$panelReplacement = @'
    <div class="panel" id="whatIsHerePanel">
      <h2>Wat ligt hier?</h2>
      <button type="button" id="whatIsHereBtn" class="download-btn" style="margin-top:0;">Kies locatie op kaart</button>
      <div id="whatIsHereStatus" class="hint" style="margin-top:6px;">Klik op de knop en daarna op een plek op de kaart.</div>
    </div>

    <div class="panel" id="nlogPanel">
      <h2>NLOG mijnbouw</h2>
'@

# 2. State-vlag toevoegen
$statePattern = '(?m)^    nlogOperatorFilter: "all",\r?\n    nlogShowFields: true,\r?\n    nlogShowFacilities: false'
$stateReplacement = @'
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false,
    whatIsHereArmed: false
'@

# 3. Functies invoegen na nearestEarthquake()
$nearestPattern = '(?ms)^  function nearestEarthquake\(lat, lon\) \{\r?\n    var best = null, bestKm = Infinity;\r?\n    state\.events\.forEach\(function \(ev\) \{\r?\n      var km = haversineKm\(lat, lon, ev\.lat, ev\.lon\);\r?\n      if \(km < bestKm\) \{ bestKm = km; best = ev; \}\r?\n    \}\);\r?\n    return best \? \{ event: best, distKm: bestKm \} : null;\r?\n  \}\r?\n'

$nearestMatch = [regex]::Match($content, $nearestPattern)
if (-not $nearestMatch.Success) {
    throw "Functie nearestEarthquake() is niet in de verwachte vorm gevonden. Er is niets gewijzigd."
}

$whatIsHereFunctions = @'

  function nlogLayerRepresentativePoint(layer, clickLat, clickLon) {
    if (layer && typeof layer.getLatLng === "function") {
      var point = layer.getLatLng();
      return { lat: point.lat, lon: point.lng, inside: false };
    }

    if (layer && typeof layer.getBounds === "function") {
      var bounds = layer.getBounds();
      if (bounds && bounds.isValid && bounds.isValid()) {
        var clickPoint = L.latLng(clickLat, clickLon);
        var inside = bounds.contains(clickPoint);
        var center = bounds.getCenter();
        return {
          lat: inside ? clickLat : center.lat,
          lon: inside ? clickLon : center.lng,
          inside: inside
        };
      }
    }

    return null;
  }

  function nearestNlogLayer(layerGroup, lat, lon) {
    if (!layerGroup) return null;

    var best = null;
    var bestKm = Infinity;

    layerGroup.eachLayer(function (layer) {
      var point = nlogLayerRepresentativePoint(layer, lat, lon);
      if (!point) return;

      var km = point.inside ? 0 : haversineKm(lat, lon, point.lat, point.lon);
      if (km < bestKm) {
        bestKm = km;
        best = {
          layer: layer,
          feature: layer.feature || null,
          distKm: km,
          inside: point.inside
        };
      }
    });

    return best;
  }

  function nlogFeatureName(feature, candidates, fallback) {
    var p = feature && feature.properties ? feature.properties : {};
    return nlogProp(p, candidates) || fallback;
  }

  function formatWhatIsHereDistance(result) {
    if (!result) return "niet beschikbaar";
    if (result.inside) return "op deze locatie";
    return "ca. " + result.distKm.toFixed(1) + " km";
  }

  function showWhatIsHere(lat, lon) {
    var eq = nearestEarthquake(lat, lon);
    var field = nearestNlogLayer(nlogFieldLayer, lat, lon);
    var facility = nearestNlogLayer(nlogFacilityLayer, lat, lon);

    var fieldName = field
      ? nlogFeatureName(
          field.feature,
          ["FIELD_NAME", "FIELDNAME", "NAME", "VELD_NAAM", "VELDNAAM"],
          "NLOG-veld"
        )
      : null;

    var facilityName = facility
      ? nlogFeatureName(
          facility.feature,
          ["FACILITY_NAME", "FACILITY", "NAME", "LOCATION_NAME", "LOC_NAME", "INSTALLATION"],
          "Mijnbouwlocatie"
        )
      : null;

    var eqText = "Nog geen aardbevingsdata geladen.";
    if (eq) {
      var ev = eq.event;
      var dateStr = ev.date ? new Date(ev.date).toLocaleDateString("nl-NL") : "onbekende datum";
      eqText =
        (ev.place || "Onbekend toponiem") +
        " · " + dateStr +
        (ev.mag !== null ? " · M" + ev.mag.toFixed(1) : "") +
        " · " + eq.distKm.toFixed(1) + " km";
    }

    var fieldText = field
      ? fieldName + " · " + formatWhatIsHereDistance(field)
      : "Geen NLOG-veld beschikbaar.";

    var facilityText = facility
      ? facilityName + " · " + formatWhatIsHereDistance(facility)
      : "Geen mijnbouwlocatie beschikbaar.";

    var html =
      '<div class="eq-info">' +
      '<b>Locatie</b><br>' +
      lat.toFixed(5) + ", " + lon.toFixed(5) + "<br><br>" +
      "<b>Dichtstbijzijnde aardbeving</b><br>" +
      escapeHtml(eqText) + "<br><br>" +
      "<b>Dichtstbijzijnde NLOG-veld</b><br>" +
      escapeHtml(fieldText) + "<br><br>" +
      "<b>Dichtstbijzijnde mijnbouwlocatie</b><br>" +
      escapeHtml(facilityText) +
      "</div>";

    var statusEl = $("whatIsHereStatus");
    if (statusEl) statusEl.innerHTML = html;

    L.popup()
      .setLatLng([lat, lon])
      .setContent(html)
      .openOn(map);
  }

  function initWhatIsHere() {
    var btn = $("whatIsHereBtn");
    var statusEl = $("whatIsHereStatus");
    if (!btn || !statusEl) return;

    btn.addEventListener("click", function () {
      state.whatIsHereArmed = true;
      btn.textContent = "Klik nu op de kaart";
      statusEl.textContent = "Kies één locatie op de kaart.";
      map.getContainer().style.cursor = "crosshair";
    });

    map.on("click", function (e) {
      if (!state.whatIsHereArmed) return;

      state.whatIsHereArmed = false;
      btn.textContent = "Kies locatie op kaart";
      map.getContainer().style.cursor = "";

      showWhatIsHere(e.latlng.lat, e.latlng.lng);
    });
  }
'@

$functionReplacement = $nearestMatch.Value.TrimEnd("`r","`n") + "`r`n" + $whatIsHereFunctions + "`r`n"

# 4. Initialisatie toevoegen
$initPattern = '(?m)^  initDownloadCsv\(\);\r?\n  initNlogControls\(\);\r?\n  loadNlogLayers\(\);\r?\n  loadEarthquakes\(\);'
$initReplacement = @'
  initDownloadCsv();
  initNlogControls();
  initWhatIsHere();
  loadNlogLayers();
  loadEarthquakes();
'@

$checks = @(
    @{ Name = "sidebar-panel"; Pattern = $panelPattern },
    @{ Name = "state-vlag"; Pattern = $statePattern },
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

if ([regex]::Matches($content, $nearestPattern).Count -ne 1) {
    throw "nearestEarthquake() komt niet exact één keer in de verwachte vorm voor. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.what-ligt-hier-$timestamp-backup"
Copy-Item $path $backup -Force

$content = [regex]::Replace($content, $panelPattern, $panelReplacement, 1)
$content = [regex]::Replace($content, $statePattern, $stateReplacement, 1)
$content = [regex]::Replace($content, $nearestPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $functionReplacement }, 1)
$content = [regex]::Replace($content, $initPattern, $initReplacement, 1)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd:"
Write-Host "  - paneel 'Wat ligt hier?'"
Write-Host "  - bewuste eenmalige klikmodus"
Write-Host "  - coördinaten"
Write-Host "  - dichtstbijzijnde aardbeving"
Write-Host "  - dichtstbijzijnde NLOG-veld"
Write-Host "  - dichtstbijzijnde mijnbouwlocatie"
Write-Host ""
Write-Host "Nog NIET toegevoegd:"
Write-Host "  - rijksmonumenten"
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
