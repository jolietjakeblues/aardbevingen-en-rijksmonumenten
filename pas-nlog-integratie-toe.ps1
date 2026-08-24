$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "aardbevingen_en_rijksmonumenten_v0.20.5.html"

if (-not (Test-Path $path)) {
    throw "Bestand niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

function Replace-Once {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Label
    )

    $first = $Text.IndexOf($Old)
    if ($first -lt 0) {
        throw "Kon invoegpunt niet vinden: $Label. Controleer of de eerste NLOG-integratie al is toegepast."
    }

    $second = $Text.IndexOf($Old, $first + $Old.Length)
    if ($second -ge 0) {
        throw "Invoegpunt komt meer dan één keer voor: $Label."
    }

    return $Text.Substring(0, $first) + $New + $Text.Substring($first + $Old.Length)
}

# 1. Voeg NLOG filter-UI toe in de sidebar.
$old = @'
    <div class="panel">
      <h2>Aardbevingen binnen straal</h2>
'@

$new = @'
    <div class="panel" id="nlogPanel">
      <h2>NLOG mijnbouw</h2>

      <label for="nlogOperatorFilter" class="hint" style="display:block;margin-bottom:4px;">Operator</label>
      <select id="nlogOperatorFilter" style="width:100%;box-sizing:border-box;padding:6px 8px;font-size:13px;border:1px solid var(--border);border-radius:4px;background:#fff;">
        <option value="all">Alle operators</option>
        <option value="nam">Alleen NAM</option>
      </select>

      <div style="margin-top:8px;">
        <label style="display:block;font-size:12px;margin-bottom:4px;">
          <input type="checkbox" id="nlogFieldsToggle" checked>
          Velden tonen
        </label>
        <label style="display:block;font-size:12px;">
          <input type="checkbox" id="nlogFacilitiesToggle">
          Mijnbouwlocaties tonen
        </label>
      </div>

      <div id="nlogStatus" class="hint" style="margin-top:6px;">NLOG-data laden…</div>
    </div>

    <div class="panel">
      <h2>Aardbevingen binnen straal</h2>
'@

$content = Replace-Once $content $old $new "NLOG filter-UI"

# 2. Breid state uit voor NLOG.
$old = @'
    lastMonuments: [],    // huidige straal-resultaten (gebouwd + archeologisch), ongefilterd
    monumentFilter: null  // { field: "type"|"functieOorspr", value: string } of null (toon alles)
'@

$new = @'
    lastMonuments: [],    // huidige straal-resultaten (gebouwd + archeologisch), ongefilterd
    monumentFilter: null, // { field: "type"|"functieOorspr", value: string } of null (toon alles)
    nlogFields: [],
    nlogFacilities: [],
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false
'@

$content = Replace-Once $content $old $new "NLOG state"

# 3. Maak facilities standaard UIT: verwijder addTo(map) bij facilitylaag.
$old = @'
      },
      onEachFeature: bindNlogFacilityPopup
    }).addTo(map);

    eqLayer = L.layerGroup().addTo(map);
'@

$new = @'
      },
      onEachFeature: bindNlogFacilityPopup
    });

    eqLayer = L.layerGroup().addTo(map);
'@

$content = Replace-Once $content $old $new "facilities standaard uit"

# 4. Maak de veldstijl dynamisch.
$old = @'
    nlogFieldLayer = L.geoJSON(null, {
      style: {
        color: "#6f5b3e",
        weight: 1.2,
        opacity: 0.8,
        fillColor: "#c9b27c",
        fillOpacity: 0.18
      },
      onEachFeature: bindNlogFieldPopup
    }).addTo(map);
'@

$new = @'
    nlogFieldLayer = L.geoJSON(null, {
      style: styleNlogField,
      onEachFeature: bindNlogFieldPopup
    }).addTo(map);
'@

$content = Replace-Once $content $old $new "dynamische NLOG veldstijl"

# 5. Voeg styling/filter/renderfuncties toe.
$old = @'
  function buildNlogWfsUrl(typeName) {
    var params = new URLSearchParams({
'@

$new = @'
  function nlogFieldKind(properties) {
    var raw = [
      nlogProp(properties, ["RESULT"]),
      nlogProp(properties, ["FIELD_TYPE"]),
      nlogProp(properties, ["TYPE"])
    ].filter(Boolean).join(" ").toLowerCase();

    if (raw.indexOf("gas") >= 0) return "gas";
    if (raw.indexOf("olie") >= 0 || raw.indexOf("oil") >= 0) return "oil";
    if (raw.indexOf("geother") >= 0 || raw.indexOf("aardwarm") >= 0) return "geothermal";
    if (raw.indexOf("opslag") >= 0 || raw.indexOf("storage") >= 0) return "storage";
    return "other";
  }

  function styleNlogField(feature) {
    var kind = nlogFieldKind((feature && feature.properties) || {});
    var styles = {
      gas:        { color: "#6f5b3e", fillColor: "#c9b27c" },
      oil:        { color: "#4d4d4d", fillColor: "#8a8a8a" },
      geothermal: { color: "#2f6f73", fillColor: "#7fb3b5" },
      storage:    { color: "#6b5a7a", fillColor: "#a995b8" },
      other:      { color: "#777777", fillColor: "#b8b8b8" }
    };
    var s = styles[kind] || styles.other;
    return {
      color: s.color,
      weight: 1.2,
      opacity: 0.85,
      fillColor: s.fillColor,
      fillOpacity: 0.18
    };
  }

  function isNamFeature(feature) {
    var p = (feature && feature.properties) || {};
    var operator = nlogProp(p, ["OPERATOR", "OPERATOR_NAME"]);
    if (!operator) return false;
    var s = String(operator).toLowerCase();
    return s.indexOf("nederlandse aardolie maatschappij") >= 0 ||
           s === "nam" ||
           s.indexOf("nam b.v.") >= 0 ||
           s.indexOf("nam bv") >= 0;
  }

  function filterNlogFeatures(features) {
    if (state.nlogOperatorFilter !== "nam") return features;
    return features.filter(isNamFeature);
  }

  function renderNlogLayers() {
    var fields = filterNlogFeatures(state.nlogFields);
    var facilities = filterNlogFeatures(state.nlogFacilities);

    nlogFieldLayer.clearLayers();
    nlogFieldLayer.addData({
      type: "FeatureCollection",
      features: fields
    });

    nlogFacilityLayer.clearLayers();
    nlogFacilityLayer.addData({
      type: "FeatureCollection",
      features: facilities
    });

    if (state.nlogShowFields) {
      if (!map.hasLayer(nlogFieldLayer)) map.addLayer(nlogFieldLayer);
    } else {
      if (map.hasLayer(nlogFieldLayer)) map.removeLayer(nlogFieldLayer);
    }

    if (state.nlogShowFacilities) {
      if (!map.hasLayer(nlogFacilityLayer)) map.addLayer(nlogFacilityLayer);
    } else {
      if (map.hasLayer(nlogFacilityLayer)) map.removeLayer(nlogFacilityLayer);
    }

    var statusEl = $("nlogStatus");
    if (statusEl) {
      var filterLabel = state.nlogOperatorFilter === "nam" ? "NAM" : "alle operators";
      statusEl.textContent =
        fields.length + " velden en " + facilities.length +
        " mijnbouwlocaties (" + filterLabel + ").";
    }
  }

  function initNlogControls() {
    var select = $("nlogOperatorFilter");
    var fieldsToggle = $("nlogFieldsToggle");
    var facilitiesToggle = $("nlogFacilitiesToggle");

    if (select) {
      select.value = state.nlogOperatorFilter;
      select.addEventListener("change", function () {
        state.nlogOperatorFilter = select.value;
        renderNlogLayers();
      });
    }

    if (fieldsToggle) {
      fieldsToggle.checked = state.nlogShowFields;
      fieldsToggle.addEventListener("change", function () {
        state.nlogShowFields = fieldsToggle.checked;
        renderNlogLayers();
      });
    }

    if (facilitiesToggle) {
      facilitiesToggle.checked = state.nlogShowFacilities;
      facilitiesToggle.addEventListener("change", function () {
        state.nlogShowFacilities = facilitiesToggle.checked;
        renderNlogLayers();
      });
    }
  }

  function buildNlogWfsUrl(typeName) {
    var params = new URLSearchParams({
'@

$content = Replace-Once $content $old $new "NLOG filter en styling functies"

# 6. Vervang loadNlogLayers zodat ruwe features in state komen.
$old = @'
    if (results[0].status === "fulfilled") {
      nlogFieldLayer.clearLayers();
      nlogFieldLayer.addData(results[0].value);
    } else {
      console.warn("NLOG-velden konden niet worden geladen:", results[0].reason);
    }

    if (results[1].status === "fulfilled") {
      nlogFacilityLayer.clearLayers();
      nlogFacilityLayer.addData(results[1].value);
    } else {
      console.warn("NLOG-mijnbouwlocaties konden niet worden geladen:", results[1].reason);
    }
  }
'@

$new = @'
    if (results[0].status === "fulfilled") {
      state.nlogFields = results[0].value.features || [];
    } else {
      state.nlogFields = [];
      console.warn("NLOG-velden konden niet worden geladen:", results[0].reason);
    }

    if (results[1].status === "fulfilled") {
      state.nlogFacilities = results[1].value.features || [];
    } else {
      state.nlogFacilities = [];
      console.warn("NLOG-mijnbouwlocaties konden niet worden geladen:", results[1].reason);
    }

    renderNlogLayers();

    if (!state.nlogFields.length && !state.nlogFacilities.length) {
      var statusEl = $("nlogStatus");
      if (statusEl) statusEl.textContent = "NLOG-data kon niet worden geladen.";
    }
  }
'@

$content = Replace-Once $content $old $new "NLOG loader"

# 7. Legenda uitbreiden met veldtypen.
$old = @'
      '<div class="legend-item"><span class="legend-square" style="background:#c9b27c;border:1px solid #6f5b3e"></span>NLOG veld</div>' +
      '<div class="legend-item"><span class="legend-dot" style="background:#7a3e9d;border:1px solid #111"></span>NLOG mijnbouwlocatie</div>' +
'@

$new = @'
      '<div class="legend-item"><span class="legend-square" style="background:#c9b27c;border:1px solid #6f5b3e"></span>NLOG gasveld</div>' +
      '<div class="legend-item"><span class="legend-square" style="background:#8a8a8a;border:1px solid #4d4d4d"></span>NLOG olieveld</div>' +
      '<div class="legend-item"><span class="legend-square" style="background:#7fb3b5;border:1px solid #2f6f73"></span>NLOG geothermie</div>' +
      '<div class="legend-item"><span class="legend-square" style="background:#a995b8;border:1px solid #6b5a7a"></span>NLOG opslag</div>' +
      '<div class="legend-item"><span class="legend-dot" style="background:#7a3e9d;border:1px solid #111"></span>NLOG mijnbouwlocatie</div>' +
'@

$content = Replace-Once $content $old $new "uitgebreide NLOG legenda"

# 8. Initialiseer controls.
$old = @'
  initHelpToggle();
  initDownloadCsv();
  loadNlogLayers();
'@

$new = @'
  initHelpToggle();
  initDownloadCsv();
  initNlogControls();
  loadNlogLayers();
'@

$content = Replace-Once $content $old $new "NLOG controls initialisatie"

# Maak backup en schrijf bestand.
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.nlog-full-$timestamp-backup"
Copy-Item $path $backup -Force
Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "NLOG fase 2 (volledige dekking) toegepast."
Write-Host "Gewijzigd: $path"
Write-Host "Back-up:    $backup"
Write-Host ""
Write-Host "Nieuw:"
Write-Host "  - volledige NLOG-dekking Nederland + Noordzee behouden"
Write-Host "  - filter Alle operators / Alleen NAM"
Write-Host "  - velden aan/uit"
Write-Host "  - mijnbouwlocaties aan/uit"
Write-Host "  - veldtypen krijgen eigen stijl"
Write-Host ""
Write-Host "Controleer met:"
Write-Host "  git diff -- aardbevingen_en_rijksmonumenten_v0.20.5.html"
