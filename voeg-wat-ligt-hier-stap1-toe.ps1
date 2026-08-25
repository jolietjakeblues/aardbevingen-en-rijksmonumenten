$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# --- 1. Sidebar-panel toevoegen na 'Geselecteerd epicentrum' ---
$panelAnchor = @'
    <div class="panel" id="nlogPanel">
      <h2>NLOG mijnbouw</h2>
'@

$panelNew = @'
    <div class="panel" id="whatIsHerePanel">
      <h2>Wat ligt hier?</h2>
      <button type="button" id="whatIsHereBtn" class="download-btn" style="margin-top:0;">Kies locatie op kaart</button>
      <div id="whatIsHereStatus" class="hint" style="margin-top:6px;">Klik op de knop en daarna op een plek op de kaart.</div>
    </div>

    <div class="panel" id="nlogPanel">
      <h2>NLOG mijnbouw</h2>
'@

# --- 2. State-vlag toevoegen ---
$stateAnchor = @'
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false
'@

$stateNew = @'
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false,
    whatIsHereArmed: false
'@

# --- 3. Functies toevoegen direct na nearestEarthquake() ---
$functionAnchor = @'
  function nearestEarthquake(lat, lon) {
    var best = null, bestKm = Infinity;
    state.events.forEach(function (ev) {
      var km = haversineKm(lat, lon, ev.lat, ev.lon);
      if (km < bestKm) { bestKm = km; best = ev; }
    });
    return best ? { event: best, distKm: bestKm } : null;
  }

'@

$functionNew = @'
  function nearestEarthquake(lat, lon) {
    var best = null, bestKm = Infinity;
    state.events.forEach(function (ev) {
      var km = haversineKm(lat, lon, ev.lat, ev.lon);
      if (km < bestKm) { bestKm = km; best = ev; }
    });
    return best ? { event: best, distKm: bestKm } : null;
  }

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

# --- 4. Initialisatie toevoegen ---
$initAnchor = @'
  initDownloadCsv();
  initNlogControls();
  loadNlogLayers();
  loadEarthquakes();
'@

$initNew = @'
  initDownloadCsv();
  initNlogControls();
  initWhatIsHere();
  loadNlogLayers();
  loadEarthquakes();
'@

$replacements = @(
    @{ Name = "sidebar-panel"; Old = $panelAnchor; New = $panelNew },
    @{ Name = "state-vlag"; Old = $stateAnchor; New = $stateNew },
    @{ Name = "functies"; Old = $functionAnchor; New = $functionNew },
    @{ Name = "initialisatie"; Old = $initAnchor; New = $initNew }
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

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.what-ligt-hier-$timestamp-backup"
Copy-Item $path $backup -Force

foreach ($r in $replacements) {
    $content = $content.Replace($r.Old, $r.New)
}

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
