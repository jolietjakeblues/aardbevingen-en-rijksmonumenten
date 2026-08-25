$ErrorActionPreference = "Stop"

$files = @(
    "docs\index.html",
    "aardbevingen_en_rijksmonumenten_v0.20.5.html"
)

function Replace-FunctionBlock {
    param(
        [string]$Text,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Replacement,
        [string]$Label,
        [string]$File
    )

    $start = $Text.IndexOf($StartMarker)
    if ($start -lt 0) {
        throw "Kon begin van '$Label' niet vinden in $File"
    }

    $end = $Text.IndexOf($EndMarker, $start)
    if ($end -lt 0) {
        throw "Kon einde van '$Label' niet vinden in $File"
    }

    return $Text.Substring(0, $start) + $Replacement + $Text.Substring($end)
}

$replacement = @'
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
    if (xml.querySelector("parsererror")) {
      throw new Error("NLOG GetCapabilities gaf ongeldige XML");
    }

    var featureTypes = Array.from(xml.getElementsByTagNameNS("*", "FeatureType"));
    var names = featureTypes.map(function (ft) {
      var nameEl = ft.getElementsByTagNameNS("*", "Name")[0];
      return nameEl ? nameEl.textContent.trim() : "";
    }).filter(Boolean);

    function findType(candidates, fallback) {
      for (var i = 0; i < candidates.length; i++) {
        var wanted = candidates[i].toLowerCase();
        var match = names.find(function (name) {
          var low = name.toLowerCase();
          return low === wanted ||
                 low.endsWith(":" + wanted) ||
                 low.indexOf(wanted) >= 0;
        });
        if (match) return match;
      }
      return fallback;
    }

    nlogResolvedTypeNames = {
      field: findType(
        ["gdw_ng_field_utm", "field_utm", "field"],
        NLOG_FIELD_TYPENAME
      ),
      facility: findType(
        ["gdw_ng_facility_utm", "facility_utm", "facility"],
        NLOG_FACILITY_TYPENAME
      )
    };

    console.info("NLOG beschikbare FeatureTypes:", names);
    console.info("NLOG gekozen laagnamen:", nlogResolvedTypeNames);

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

    if (version === "2.0.0") {
      params.set("typeNames", typeName);
    } else {
      params.set("typeName", typeName);
    }

    return NLOG_WFS_ENDPOINT + "?" + params.toString();
  }

  async function fetchNlogGeoJson(typeName) {
    var versions = ["2.0.0", "1.1.0"];
    var lastError = null;

    for (var i = 0; i < versions.length; i++) {
      var version = versions[i];

      try {
        var url = buildNlogWfsUrl(typeName, version);
        console.info("NLOG ophalen:", url);

        var res = await fetchWithTimeout(
          url,
          { headers: { Accept: "application/geo+json, application/json,*/*" } },
          45000
        );

        var body = await res.text();

        if (!res.ok) {
          throw new Error(
            "HTTP " + res.status + " via WFS " + version +
            (body ? ": " + body.slice(0, 220).replace(/\s+/g, " ") : "")
          );
        }

        var json;
        try {
          json = JSON.parse(body);
        } catch (err) {
          throw new Error(
            "antwoord is geen JSON via WFS " + version +
            ": " + body.slice(0, 220).replace(/\s+/g, " ")
          );
        }

        if (!json || json.type !== "FeatureCollection" || !Array.isArray(json.features)) {
          throw new Error("onverwacht GeoJSON-formaat via WFS " + version);
        }

        console.info(
          "NLOG laag geladen:",
          typeName,
          json.features.length,
          "features via WFS",
          version
        );

        return json;
      } catch (err) {
        lastError = err;
        console.warn(
          "NLOG poging mislukt:",
          typeName,
          "WFS " + version,
          err
        );
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
      console.warn(
        "GetCapabilities kon niet worden gelezen; bekende laagnamen worden geprobeerd:",
        err
      );

      typeNames = {
        field: NLOG_FIELD_TYPENAME,
        facility: NLOG_FACILITY_TYPENAME
      };
    }

    if (statusEl) {
      statusEl.textContent =
        "NLOG-data laden: " + typeNames.field + " / " + typeNames.facility + "…";
    }

    var results = await Promise.allSettled([
      fetchNlogGeoJson(typeNames.field),
      fetchNlogGeoJson(typeNames.facility)
    ]);

    state.nlogFields =
      results[0].status === "fulfilled"
        ? (results[0].value.features || [])
        : [];

    state.nlogFacilities =
      results[1].status === "fulfilled"
        ? (results[1].value.features || [])
        : [];

    var errors = [];

    if (results[0].status !== "fulfilled") {
      var fieldMsg =
        results[0].reason && results[0].reason.message
          ? results[0].reason.message
          : String(results[0].reason || "onbekende fout");

      console.error("NLOG-velden konden niet worden geladen:", results[0].reason);
      errors.push("velden: " + fieldMsg);
    }

    if (results[1].status !== "fulfilled") {
      var facilityMsg =
        results[1].reason && results[1].reason.message
          ? results[1].reason.message
          : String(results[1].reason || "onbekende fout");

      console.error(
        "NLOG-mijnbouwlocaties konden niet worden geladen:",
        results[1].reason
      );

      errors.push("mijnbouwlocaties: " + facilityMsg);
    }

    renderNlogLayers();

    if (statusEl && errors.length) {
      statusEl.innerHTML =
        escapeHtml(
          state.nlogFields.length +
          " velden en " +
          state.nlogFacilities.length +
          " mijnbouwlocaties geladen."
        ) +
        '<br><span class="error-msg">NLOG-fout: ' +
        escapeHtml(errors.join(" | ")) +
        "</span>";
    } else if (statusEl && state.nlogFacilities.length === 0) {
      statusEl.innerHTML =
        escapeHtml(state.nlogFields.length + " velden geladen.") +
        '<br><span class="error-msg">' +
        "De facility-laag reageert wel, maar bevat 0 objecten." +
        "</span>";
    }
  }

'@

foreach ($rel in $files) {
    $path = Join-Path (Get-Location) $rel

    if (-not (Test-Path $path)) {
        Write-Host "Overslaan, niet gevonden: $path"
        continue
    }

    $content = Get-Content -Raw -Encoding UTF8 $path

    # Zoek de NLOG-loader op functienamen, niet op exacte oude inhoud.
    $startMarker = "  function buildNlogWfsUrl("
    if ($content.IndexOf("  async function resolveNlogTypeNames()") -ge 0) {
        $startMarker = "  var nlogResolvedTypeNames"
    }

    # Alles tot aan initMap blijft NLOG-loadercode.
    $endMarker = "  function initMap() {"

    $content = Replace-FunctionBlock `
        $content `
        $startMarker `
        $endMarker `
        $replacement `
        "NLOG WFS loader" `
        $rel

    # Zorg dat facilitymarkers groot en contrastrijk zijn.
    $content = [regex]::Replace(
        $content,
        'return L\.circleMarker\(latlng,\s*\{\s*radius:\s*\d+,\s*color:\s*"#[0-9a-fA-F]{6}",\s*weight:\s*[0-9.]+,\s*fillColor:\s*"#[0-9a-fA-F]{6}",\s*fillOpacity:\s*[0-9.]+(?:,\s*pane:\s*"[^"]+")?\s*\}\);',
        @'
return L.circleMarker(latlng, {
          radius: 7,
          color: "#ffffff",
          weight: 2.5,
          fillColor: "#d81b60",
          fillOpacity: 1,
          pane: "markerPane"
        });
'@,
        1
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$path.facility-fix2-$timestamp-backup"

    Copy-Item $path $backup -Force
    Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

    Write-Host ""
    Write-Host "Gefixt:  $path"
    Write-Host "Backup:  $backup"
}

Write-Host ""
Write-Host "Robuuste NLOG facility-fix toegepast."
Write-Host ""
Write-Host "Nu testen:"
Write-Host "  python -m http.server 8000"
Write-Host "  http://localhost:8000/docs/"
Write-Host ""
Write-Host "Daarna Ctrl+F5."
Write-Host "Vink 'Mijnbouwlocaties tonen' aan."
Write-Host ""
Write-Host "Als het nog niet werkt, kopieer letterlijk de rode NLOG-fout uit de zijbalk."
