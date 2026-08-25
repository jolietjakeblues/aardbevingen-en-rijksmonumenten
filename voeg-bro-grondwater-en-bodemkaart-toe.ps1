$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# Dit script ondersteunt de bestaande layer control met "null" als overlay-object.
# Het wijzigt uitsluitend docs/index.html.

$pdokPattern = '(?ms)(^    var pdokLuchtfotoLayer = L\.tileLayer\.wms\(\r?\n      "https://service\.pdok\.nl/hwh/luchtfotorgb/wms/v1_0",\r?\n      \{\r?\n        layers: "Actueel_ortho25",\r?\n        format: "image/jpeg",\r?\n        transparent: false,\r?\n        version: "1\.3\.0",\r?\n        attribution: "PDOK / Beeldmateriaal"\r?\n      \}\r?\n    \);\r?\n)'

$controlPattern = '(?ms)^    L\.control\.layers\(\r?\n      \{\r?\n        "Kaart": cartoLayer,\r?\n        "Luchtfoto": pdokLuchtfotoLayer\r?\n      \},\r?\n      null,\r?\n      \{\r?\n        position: "topright",\r?\n        collapsed: true\r?\n      \}\r?\n    \)\.addTo\(map\);'

$pdokMatches = [regex]::Matches($content, $pdokPattern)
$controlMatches = [regex]::Matches($content, $controlPattern)

if ($pdokMatches.Count -ne 1) {
    throw "Het PDOK-luchtfotoblok is niet exact één keer gevonden. Er is niets gewijzigd."
}

if ($controlMatches.Count -ne 1) {
    throw "De bestaande Leaflet layer control met null-overlay is niet exact één keer gevonden. Er is niets gewijzigd."
}

if ($content -match 'broGrondwaterLayer|broBodemkaartLayer|bro-grondwaterspiegeldieptemetingen-GT|layers: "soilarea"') {
    throw "BRO-themalagen lijken al aanwezig. Er is niets gewijzigd."
}

$broLayers = @'

    var broGrondwaterLayer = L.tileLayer.wms(
      "https://service.pdok.nl/tno/bro-model-grondwaterspiegeldiepte/wms/v2_0",
      {
        layers: "bro-grondwaterspiegeldieptemetingen-GT",
        format: "image/png",
        transparent: true,
        version: "1.3.0",
        opacity: 0.65,
        attribution: "BRO / TNO via PDOK"
      }
    );

    var broBodemkaartLayer = L.tileLayer.wms(
      "https://service.pdok.nl/tno/bro-bodemkaart/wms/v1_0",
      {
        layers: "soilarea",
        format: "image/png",
        transparent: true,
        version: "1.3.0",
        opacity: 0.60,
        attribution: "BRO / TNO via PDOK"
      }
    );
'@

$controlReplacement = @'
    L.control.layers(
      {
        "Kaart": cartoLayer,
        "Luchtfoto": pdokLuchtfotoLayer
      },
      {
        "BRO Grondwaterspiegeldiepte (Gt)": broGrondwaterLayer,
        "BRO Bodemkaart": broBodemkaartLayer
      },
      {
        position: "topright",
        collapsed: true
      }
    ).addTo(map);
'@

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.bro-themalagen-$timestamp-backup"
Copy-Item $path $backup -Force

$content = [regex]::Replace(
    $content,
    $pdokPattern,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $m.Groups[1].Value.TrimEnd("`r","`n") + $broLayers + "`r`n"
    },
    1
)

$content = [regex]::Replace(
    $content,
    $controlPattern,
    $controlReplacement,
    1
)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd, standaard UIT:"
Write-Host "  - BRO Grondwaterspiegeldiepte (Gt)"
Write-Host "    laag: bro-grondwaterspiegeldieptemetingen-GT"
Write-Host "  - BRO Bodemkaart"
Write-Host "    laag: soilarea"
Write-Host ""
Write-Host "Beide via actuele PDOK/TNO WMS-diensten."
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
