$ErrorActionPreference = "Stop"

$root = Get-Location
$target = Join-Path $root "docs\index.html"

if (-not (Test-Path $target)) {
    throw "GitHub Pages-bestand niet gevonden: $target"
}

# Zoek de nieuwste back-up die het eerdere synchronisatiescript maakte.
$backups = Get-ChildItem -Path (Join-Path $root "docs") -Filter "index.html.*-backup" |
    Sort-Object LastWriteTime -Descending

if (-not $backups -or $backups.Count -eq 0) {
    throw "Geen docs/index.html-back-up gevonden. Verwacht iets als docs/index.html.20260824-....-backup"
}

$backup = $backups[0].FullName
Write-Host "Herstel eerst bestaande Pages-versie uit:"
Write-Host "  $backup"

Copy-Item $backup $target -Force

$content = Get-Content -Raw -Encoding UTF8 $target

function Replace-Once {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Label
    )

    $first = $Text.IndexOf($Old)
    if ($first -lt 0) {
        throw "Kon invoegpunt niet vinden: $Label. De herstelde docs/index.html wijkt af van de verwachte structuur."
    }

    $second = $Text.IndexOf($Old, $first + $Old.Length)
    if ($second -ge 0) {
        throw "Invoegpunt komt meer dan één keer voor: $Label."
    }

    return $Text.Substring(0, $first) + $New + $Text.Substring($first + $Old.Length)
}

# NLOG UI in sidebar, zonder bestaande erfgoedpanelen te vervangen.
$anchor = @'
    <div class="panel">
      <h2>Aardbevingen binnen straal</h2>
'@

$insert = @'
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

$content = Replace-Once $content $anchor $insert "NLOG sidebar"

# NLOG constants en state/layers.
$content = Replace-Once $content `
'  var map, eqLayer, monLayer, monSearchLayer, radiusCircle;' `
@'
  var map, eqLayer, monLayer, monSearchLayer, radiusCircle;
  var nlogFieldLayer, nlogFacilityLayer;

  var NLOG_WFS_ENDPOINT = "https://www.gdngeoservices.nl/geoserver/nlog/ows";
  var NLOG_FIELD_TYPENAME = "nlog:gdw_ng_field_utm";
  var NLOG_FACILITY_TYPENAME = "nlog:gdw_ng_facility_utm";
  var NLOG_SOURCE_URL = "https://www.nlog.nl/bestanden-interactieve-kaart";
'@ `
"NLOG variabelen"

$content = Replace-Once $content `
'    monumentFilter: null  // { field: "type"|"functieOorspr", value: string } of null (toon alles)' `
@'
    monumentFilter: null, // { field: "type"|"functieOorspr", value: string } of null (toon alles)
    nlogFields: [],
    nlogFacilities: [],
    nlogOperatorFilter: "all",
    nlogShowFields: true,
    nlogShowFacilities: false
'@ `
"NLOG state"

# Voeg NLOG functies vlak vóór initMap toe.
$initMapAnchor = @'
  function initMap() {
'@

$nlogFunctions = @'
  function nlogProp(properties, candidates) {
    if (!properties) return null;
    var keys = Object.keys(properties);
    for (var i = 0; i < candidates.length; i++) {
      var wanted = candidates[i].toLowerCase();
      for (var j = 0; j < keys.length; j++) {
        if (keys[j].toLowerCase() === wanted) {
          var value = properties[keys[j]];
          if (value !== null && value !== undefined && String(value).trim() !== "") return value;
        }
      }
    }
    return null;
  }

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

  function nlogPopupRows(properties, rows) {
    return rows.map(function (row) {
      var value = nlogProp(properties, row.keys);
      return value === null ? "" : escapeHtml(row.label) + ": " + escapeHtml(value) + "<br>";
    }).join("");
  }

  function bindNlogFieldPopup(feature, layer) {
    var p = feature.properties || {};
    var name = nlogProp(p, ["FIELD_NAME", "FIELDNAME", "NAME", "VELD_NAAM", "VELDNAAM"]) || "NLOG-veld";
    layer.bindPopup(
      '<div class="eq-info">' +
      "<b>" + escapeHtml(name) + "</b><br>" +
      nlogPopupRows(p, [
        { label: "Type", keys: ["RESULT", "FIELD_TYPE", "TYPE"] },
        { label: "Status", keys: ["STATUS", "FIELD_STATUS"] },
        { label: "Operator", keys: ["OPERATOR", "OPERATOR_NAME"] },
        { label: "Ontdekking", keys: ["DISCOVERY", "DISCOVERY_DATE"] },
        { label: "Start productie", keys: ["START_DATE", "PRODUCTION_START"] }
      ]) +
      '<a href="' + NLOG_SOURCE_URL + '" target="_blank" rel="noopener">Bron: NLOG</a>' +
      "</div>"
    );
  }

  function bindNlogFacilityPopup(feature, layer) {
    var p = feature.properties || {};
    var name = nlogProp(p, ["FACILITY_NAME", "FACILITY", "NAME", "LOCATION_NAME", "LOC_NAME", "INSTALLATION"]) || "Mijnbouwlocatie";
    layer.bindPopup(
      '<div class="eq-info">' +
      "<b>" + escapeHtml(name) + "</b><br>" +
      nlogPopupRows(p, [
        { label: "Type", keys: ["FACILITY_TYPE", "TYPE", "RESULT"] },
        { label: "Status", keys: ["STATUS", "FACILITY_STATUS"] },
        { label: "Operator", keys: ["OPERATOR", "OPERATOR_NAME"] }
      ]) +
      '<a href="' + NLOG_SOURCE_URL + '" target="_blank" rel="noopener">Bron: NLOG</a>' +
      "</div>"
    );
  }

  function isNamFeature(feature) {
    var operator = nlogProp((feature && feature.properties) || {}, ["OPERATOR", "OPERATOR_NAME"]);
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
    nlogFieldLayer.addData({ type: "FeatureCollection", features: fields });

    nlogFacilityLayer.clearLayers();
    nlogFacilityLayer.addData({ type: "FeatureCollection", features: facilities });

    if (state.nlogShowFields) {
      if (!map.hasLayer(nlogFieldLayer)) map.addLayer(nlogFieldLayer);
    } else if (map.hasLayer(nlogFieldLayer)) {
      map.removeLayer(nlogFieldLayer);
    }

    if (state.nlogShowFacilities) {
      if (!map.hasLayer(nlogFacilityLayer)) map.addLayer(nlogFacilityLayer);
    } else if (map.hasLayer(nlogFacilityLayer)) {
      map.removeLayer(nlogFacilityLayer);
    }

    var statusEl = $("nlogStatus");
    if (statusEl) {
      var label = state.nlogOperatorFilter === "nam" ? "NAM" : "alle operators";
      statusEl.textContent = fields.length + " velden en " + facilities.length + " mijnbouwlocaties (" + label + ").";
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
      service: "WFS",
      version: "2.0.0",
      request: "GetFeature",
      typeNames: typeName,
      outputFormat: "application/json",
      srsName: "EPSG:4326"
    });
    return NLOG_WFS_ENDPOINT + "?" + params.toString();
  }

  async function fetchNlogGeoJson(typeName) {
    var res = await fetchWithTimeout(
      buildNlogWfsUrl(typeName),
      { headers: { Accept: "application/geo+json, application/json" } },
      30000
    );
    if (!res.ok) throw new Error("NLOG WFS-verzoek mislukt (" + res.status + ")");
    var json = await res.json();
    if (!json || json.type !== "FeatureCollection" || !Array.isArray(json.features)) {
      throw new Error("Onverwacht antwoord van NLOG WFS");
    }
    return json;
  }

  async function loadNlogLayers() {
    var results = await Promise.allSettled([
      fetchNlogGeoJson(NLOG_FIELD_TYPENAME),
      fetchNlogGeoJson(NLOG_FACILITY_TYPENAME)
    ]);

    state.nlogFields = results[0].status === "fulfilled" ? (results[0].value.features || []) : [];
    state.nlogFacilities = results[1].status === "fulfilled" ? (results[1].value.features || []) : [];

    if (results[0].status !== "fulfilled") console.warn("NLOG-velden konden niet worden geladen:", results[0].reason);
    if (results[1].status !== "fulfilled") console.warn("NLOG-mijnbouwlocaties konden niet worden geladen:", results[1].reason);

    renderNlogLayers();
  }

  function initMap() {
'@

$content = Replace-Once $content $initMapAnchor $nlogFunctions "NLOG functies"

# Voeg de twee lagen toe direct na de basemap, zonder bestaande erfgoedlagen te vervangen.
$basemapAnchor = @'
    }).addTo(map);
    eqLayer = L.layerGroup().addTo(map);
'@

$basemapInsert = @'
    }).addTo(map);

    nlogFieldLayer = L.geoJSON(null, {
      style: styleNlogField,
      onEachFeature: bindNlogFieldPopup
    }).addTo(map);

    nlogFacilityLayer = L.geoJSON(null, {
      pointToLayer: function (feature, latlng) {
        return L.circleMarker(latlng, {
          radius: 4,
          color: "#111111",
          weight: 1,
          fillColor: "#7a3e9d",
          fillOpacity: 0.9
        });
      },
      onEachFeature: bindNlogFacilityPopup
    });

    eqLayer = L.layerGroup().addTo(map);
'@

$content = Replace-Once $content $basemapAnchor $basemapInsert "NLOG lagen"

# Initialisatie, zonder bestaande init-calls weg te halen.
$content = Replace-Once $content `
'  initDownloadCsv();' `
@'
  initDownloadCsv();
  initNlogControls();
  loadNlogLayers();
'@ `
"NLOG initialisatie"

# Schrijf met een extra herstelbackup.
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safety = "$target.pre-nlog-surgical-$timestamp-backup"
Copy-Item $target $safety -Force
Set-Content -Path $target -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Herstel + chirurgische NLOG-integratie gereed."
Write-Host "Hersteld uit: $backup"
Write-Host "Nieuwe safety backup: $safety"
Write-Host ""
Write-Host "Test:"
Write-Host "  python -m http.server 8000"
Write-Host "  http://localhost:8000/docs/"
Write-Host ""
Write-Host "Controle:"
Write-Host "  git diff -- docs/index.html"
