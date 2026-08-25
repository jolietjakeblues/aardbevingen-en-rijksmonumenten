$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "docs\index.html"

if (-not (Test-Path $path)) {
    throw "Niet gevonden: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# 1. Voeg helper toe direct na nearestNlogLayer()
$anchorPattern = '(?ms)(^  function nearestNlogLayer\(layerGroup, lat, lon\) \{.*?^  \}\r?\n)(\r?\n  function nlogFeatureName\()'

$helper = @'

  function nearestLoadedMonument(lat, lon) {
    if (!state.lastMonuments || !state.lastMonuments.length) return null;

    var best = null;
    var bestKm = Infinity;

    state.lastMonuments.forEach(function (m) {
      if (m.lat === null || m.lon === null) return;
      var km = haversineKm(lat, lon, m.lat, m.lon);
      if (km < bestKm) {
        bestKm = km;
        best = { monument: m, distKm: km };
      }
    });

    return best;
  }
'@

# 2. Voeg monumentberekening toe in showWhatIsHere()
$calcPattern = '(?m)^    var facility = nearestNlogLayer\(nlogFacilityLayer, lat, lon\);$'
$calcReplacement = @'
    var facility = nearestNlogLayer(nlogFacilityLayer, lat, lon);
    var monument = nearestLoadedMonument(lat, lon);
'@

# 3. Voeg monumenttekst toe na facilityText
$textPattern = '(?ms)(^    var facilityText = facility\r?\n      \? facilityName \+ " · " \+ formatWhatIsHereDistance\(facility\)\r?\n      : "Geen mijnbouwlocatie beschikbaar\.";\r?\n)'
$textReplacement = @'
    var facilityText = facility
      ? facilityName + " · " + formatWhatIsHereDistance(facility)
      : "Geen mijnbouwlocatie beschikbaar.";

    var monumentText;
    if (monument) {
      var m = monument.monument;
      var monumentLabel = m.naam
        ? m.naam + " (nr. " + m.nr + ")"
        : "Rijksmonument nr. " + m.nr;
      monumentText =
        monumentLabel +
        " · " + monument.distKm.toFixed(1) + " km" +
        (m.type ? " · " + (m.type === "archeologisch" ? "archeologisch" : "onroerend gebouwd") : "");
    } else {
      monumentText = "Geen rijksmonumentgegevens geladen voor deze locatie.";
    }

'@

# 4. Voeg monumentblok toe aan popup/paneel
$htmlPattern = '(?ms)(^      "<b>Dichtstbijzijnde mijnbouwlocatie</b><br>" \+\r?\n      escapeHtml\(facilityText\) \+\r?\n)(      "</div>";)'
$htmlReplacement = @'
      "<b>Dichtstbijzijnde mijnbouwlocatie</b><br>" +
      escapeHtml(facilityText) + "<br><br>" +
      "<b>Dichtstbijzijnde geladen rijksmonument</b><br>" +
      escapeHtml(monumentText) +
      "</div>";
'@

$checks = @(
    @{ Name = "nearestNlogLayer-anker"; Pattern = $anchorPattern },
    @{ Name = "monument-berekening"; Pattern = $calcPattern },
    @{ Name = "facilityText-blok"; Pattern = $textPattern },
    @{ Name = "popup-blok"; Pattern = $htmlPattern }
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

if ($content -match 'function nearestLoadedMonument\(') {
    throw "nearestLoadedMonument() bestaat al. Er is niets gewijzigd."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$path.what-ligt-hier-monumenten-$timestamp-backup"
Copy-Item $path $backup -Force

$content = [regex]::Replace(
    $content,
    $anchorPattern,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $m.Groups[1].Value.TrimEnd("`r","`n") + "`r`n" + $helper + "`r`n  function nlogFeatureName("
    },
    1
)

$content = [regex]::Replace($content, $calcPattern, $calcReplacement, 1)
$content = [regex]::Replace($content, $textPattern, $textReplacement, 1)
$content = [regex]::Replace($content, $htmlPattern, $htmlReplacement, 1)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Klaar."
Write-Host "Alleen gewijzigd: docs\index.html"
Write-Host "Back-up: $backup"
Write-Host ""
Write-Host "Toegevoegd aan 'Wat ligt hier?':"
Write-Host "  - dichtstbijzijnde rijksmonument uit state.lastMonuments"
Write-Host "  - afstand opnieuw berekend vanaf de gekozen kaartlocatie"
Write-Host "  - duidelijke melding wanneer nog geen monumentgegevens geladen zijn"
Write-Host ""
Write-Host "Er wordt GEEN extra RCE/SPARQL-query uitgevoerd bij een kaartklik."
Write-Host ""
Write-Host "Controleer nu:"
Write-Host "  git diff -- docs/index.html"
