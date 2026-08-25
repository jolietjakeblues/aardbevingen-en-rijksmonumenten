$ErrorActionPreference = "Stop"

$files = @(
    "docs\index.html",
    "aardbevingen_en_rijksmonumenten_v0.20.5.html"
)

function Replace-Once {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Label,
        [string]$File
    )

    $first = $Text.IndexOf($Old)
    if ($first -lt 0) {
        throw "Kon '$Label' niet vinden in $File"
    }
    $second = $Text.IndexOf($Old, $first + $Old.Length)
    if ($second -ge 0) {
        throw "'$Label' komt meer dan één keer voor in $File"
    }
    return $Text.Substring(0, $first) + $New + $Text.Substring($first + $Old.Length)
}

foreach ($rel in $files) {
    $path = Join-Path (Get-Location) $rel
    if (-not (Test-Path $path)) {
        Write-Host "Overslaan, niet gevonden: $path"
        continue
    }

    $content = Get-Content -Raw -Encoding UTF8 $path

    # Vervang de huidige fetch/load-sectie door capability-discovery + fallback.
    $old = @'
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
'@

    $new = @'
  var nlogResolvedTypeNames = null;

  async function resolveNlogTypeNames() {
    if (nlogResolvedTypeNames) return nlogResolvedTypeNames;

    var params = new URLSearchParams({
      service: "WFS",
      version: "2.0.0",
      request: "GetCapabilities"
    });

    var res = await fetchWithTimeout(
      NLOG_WFS_ENDPOINT + "?" + params.toString(),
      { headers: { Accept: "application/xml,text/xml,*/*" } },
      30000
    );

    if (!res.ok) throw new Error("NLOG GetCapabilities mislukt (" + res.status + ")");

    var xmlText = await res.text();
    var xml = new DOMParser().parseFromString(xmlText, "application/xml");
    if (xml.querySelector("parsererror")) throw new Error("NLOG GetCapabilities gaf ongeldige XML");

    var names = Array.from(xml.getElementsByTagNameNS("*", "FeatureType")).map(function (ft) {
      var nameEl = ft.getElementsByTagNameNS("*", "Name")[0];
      return nameEl ? nameEl.textContent.trim() : "";
    }).filter(Boolean);

    function findType(suffix, fallback) {
      var wanted = suffix.toLowerCase();
      var match = names.find(function (name) {
        var low = name.toLowerCase();
        return low === wanted || low.endsWith(":" + wanted);
      });
      return match || fallback;
    }

    nlogResolvedTypeNames = {
      field: findType("gdw_ng_field_utm", NLOG_FIELD_TYPENAME),
      facility: findType("gdw_ng_facility_utm", NLOG_FACILITY_TYPENAME)
    };

    console.info("NLOG WFS-laagnamen:", nlogResolvedTypeNames);
    return nlogResolvedTypeNames;
  }

  function buildNlogWfsUrl(typeName, version) {
    version = version || "2.0.0";
    var params = new URLSearchParams({
      service: "WFS",
      version: version,
      request: "GetFeature",
      outputFormat: "application/json",
      srsName: "EPSG:4326"
    });

    // WFS 2.0 gebruikt typeNames; WFS 1.1 gebruikt typeName.
    if (version === "2.0.0") params.set("typeNames", typeName);
    else params.set("typeName", typeName);

    return NLOG_WFS_ENDPOINT + "?" + params.toString();
  }

  async function fetchNlogGeoJson(typeName) {
    var attempts = ["2.0.0", "1.1.0"];
    var lastError = null;

    for (var i = 0; i < attempts.length; i++) {
      var version = attempts[i];
      try {
        var res = await fetchWithTimeout(
          buildNlogWfsUrl(typeName, version),
          { headers: { Accept: "application/geo+json, application/json,*/*" } },
          45000
        );

        var body = await res.text();

        if (!res.ok) {
          throw new Error("HTTP " + res.status + " via WFS " + version + ": " + body.slice(0, 180));
        }

        var json;
        try {
          json = JSON.parse(body);
        } catch (e) {
          throw new Error("geen GeoJSON via WFS " + version + ": " + body.slice(0, 180));
        }

        if (!json || json.type !== "FeatureCollection" || !Array.isArray(json.features)) {
          throw new Error("onverwacht GeoJSON-formaat via WFS " + version);
        }

        console.info("NLOG " + typeName + ": " + json.features.length + " features via WFS " + version);
        return json;
      } catch (err) {
        lastError = err;
        console.warn("NLOG poging mislukt voor " + typeName + " via WFS " + version + ":", err);
      }
    }

    throw lastError || new Error("NLOG-laag kon niet worden geladen");
  }

  async function loadNlogLayers() {
    var statusEl = $("nlogStatus");
    if (statusEl) statusEl.textContent = "NLOG-laagnamen bepalen…";

    var typeNames;
    try {
      typeNames = await resolveNlogTypeNames();
    } catch (err) {
      // GetCapabilities mag de data niet blokkeren. Val terug op bekende laagnamen.
      console.warn("NLOG GetCapabilities niet beschikbaar; bekende laagnamen worden gebruikt:", err);
      typeNames = {
        field: NLOG_FIELD_TYPENAME,
        facility: NLOG_FACILITY_TYPENAME
      };
    }

    if (statusEl) statusEl.textContent = "NLOG-data laden…";

    var results = await Promise.allSettled([
      fetchNlogGeoJson(typeNames.field),
      fetchNlogGeoJson(typeNames.facility)
    ]);

    state.nlogFields = results[0].status === "fulfilled"
      ? (results[0].value.features || [])
      : [];

    state.nlogFacilities = results[1].status === "fulfilled"
      ? (results[1].value.features || [])
      : [];

    var errors = [];

    if (results[0].status !== "fulfilled") {
      console.error("NLOG-velden konden niet worden geladen:", results[0].reason);
      errors.push("velden: " + (results[0].reason && results[0].reason.message ? results[0].reason.message : "onbekende fout"));
    }

    if (results[1].status !== "fulfilled") {
      console.error("NLOG-mijnbouwlocaties konden niet worden geladen:", results[1].reason);
      errors.push("mijnbouwlocaties: " + (results[1].reason && results[1].reason.message ? results[1].reason.message : "onbekende fout"));
    }

    renderNlogLayers();

    if (statusEl && errors.length) {
      var loadedText = state.nlogFields.length + " velden, " + state.nlogFacilities.length + " mijnbouwlocaties.";
      statusEl.innerHTML =
        escapeHtml(loadedText) +
        '<br><span class="error-msg">NLOG-fout: ' + escapeHtml(errors.join(" | ")) + "</span>";
    } else if (statusEl && state.nlogFacilities.length === 0) {
      statusEl.innerHTML =
        escapeHtml(state.nlogFields.length + " velden geladen.") +
        '<br><span class="error-msg">Let op: de facility-laag gaf 0 objecten terug.</span>';
    }
  }
'@

    $content = Replace-Once $content $old $new "NLOG WFS loader" $rel

    # Maak facilities nog duidelijker en boven andere vectoren.
    $oldMarker = @'
        return L.circleMarker(latlng, {
          radius: 6,
          color: "#ffffff",
          weight: 2,
          fillColor: "#d81b60",
          fillOpacity: 1
        });
'@

    $newMarker = @'
        return L.circleMarker(latlng, {
          radius: 7,
          color: "#ffffff",
          weight: 2.5,
          fillColor: "#d81b60",
          fillOpacity: 1,
          pane: "markerPane"
        });
'@

    if ($content.Contains($oldMarker)) {
        $content = $content.Replace($oldMarker, $newMarker)
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$path.facility-fix-$timestamp-backup"
    Copy-Item $path $backup -Force
    Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

    Write-Host "Gefixt:   $path"
    Write-Host "Back-up:  $backup"
}

Write-Host ""
Write-Host "Facility-fix toegepast."
Write-Host ""
Write-Host "De kaart doet nu:"
Write-Host "  1. WFS GetCapabilities uitlezen"
Write-Host "  2. actuele facility-laagnaam automatisch vinden"
Write-Host "  3. WFS 2.0 proberen"
Write-Host "  4. bij fout WFS 1.1 proberen"
Write-Host "  5. concrete fout in de zijbalk tonen"
Write-Host ""
Write-Host "Test:"
Write-Host "  python -m http.server 8000"
Write-Host "  http://localhost:8000/docs/"
Write-Host ""
Write-Host "Ververs met Ctrl+F5 en vink 'Mijnbouwlocaties tonen' aan."
