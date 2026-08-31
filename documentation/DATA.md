# Databronnen en live-gedrag

## Wat is live en wat niet

De aardbevings- en monumentgegevens worden tijdens het gebruik rechtstreeks bij de bron
opgehaald. De applicatie bevat geen ingebouwde momentopname van deze datasets. Bij het openen van
de pagina en bij elke interactie wordt er in de browser (`fetch()`) rechtstreeks bevraagd:

| Onderdeel | Wanneer opgehaald | Bron |
|---|---|---|
| Aardbevingen (alle ~3.750, 1911-heden) | eenmalig bij laden van de pagina | **KNMI**, rechtstreeks (`rdsa.knmi.nl`, CSV) |
| Rijksmonumenten binnen straal | bij elke selectie/straal-wijziging (gedebounced, 350ms) | RCE CHO linked data, live SPARQL |
| NLOG mijnbouwvelden en mijnbouwlocaties | eenmalig bij laden van de pagina | NLOG / Geologische Dienst Nederland, live WFS |
| PDOK BRT-kaarttegels | doorlopend tijdens pannen/zoomen | PDOK / Kadaster, live WMTS |
| OpenStreetMap-kaarttegels | alleen wanneer deze ondergrond actief is | OpenStreetMap |
| PDOK-luchtfoto | alleen wanneer deze ondergrond actief is, tijdens pannen/zoomen | PDOK / Beeldmateriaal, live WMS |
| Leaflet-library | eenmalig bij laden | unpkg CDN |

Er is dus geen "ververs de data"-knop nodig en geen risico op een verouderde snapshot van de
brondata zelf, maar de applicatiecode (HTML/CSS/JS), de Leaflet-library en de achtergrondpagina
zijn wel gewoon statische bestanden, geen live diensten. De pagina werkt bovendien niet zonder
internetverbinding, en de snelheid hangt af van de bron-endpoints.

### Bekende KNMI-eigenaardigheid: koude-cache-vertraging

Op meerdere apparaten leken de geïnduceerde aardbevingen soms pas na een handmatige refresh te
verschijnen, terwijl de tektonische wel meteen toonden. Gemeten met herhaalde `curl`-verzoeken
bleek de oorzaak bij het KNMI zelf te liggen: het `eventtype=induced`-endpoint kost bij een koude
cache ~15,5s om te antwoorden, tegen ~0,8s zodra de server het net gecached heeft; het
`eventtype=tectonic`-endpoint toont hetzelfde patroon maar minder uitgesproken (~7,2s koud, ~0,9s
warm). Op een trager netwerk kon die koude start het toenmalige timeout van 20s overschrijden.
Opgelost door de timeout te verruimen naar 35s en één automatische herkansing toe te voegen na een
korte pauze (`KNMI_TIMEOUT_MS`, `KNMI_RETRY_DELAY_MS` in `docs/index.html`), zodat een handmatige
refresh niet meer nodig zou moeten zijn.

## Waarom rechtstreeks het KNMI en niet (meer) RCE voor de aardbevingen

RCE's eigen aardbevingen-graph bleek zelf een periodieke import van precies dezelfde twee
KNMI-endpoints te zijn (te zien aan `prov:wasDerivedFrom` op elk event, wijzend naar
`rdsa.knmi.nl`). Rechtstreeks bij de bron ophalen is dus zowel actueler (geen wachten op RCE's
eigen ververscyclus) als completer: KNMI's archief gaat terug tot 1911, verder terug dan wat er
via RCE beschikbaar bleek. Kanttekening: het KNMI kent alleen de categorieën "induced" en
"tectonic", de categorie "steengroeve explosie" die in de RCE-versie voorkwam, bestaat niet in
deze bron en is dus vervallen. Rijksmonumenten blijven wel via RCE lopen; dat is een andere
databron met een ander doel (cultureel erfgoed, niet seismologie).

Andere KNMI-bronnen zijn overwogen en afgevallen: `dataplatform.knmi.nl/aardbevingen_nederland`
beperkt zich tot de laatste 100 events (en levert NetCDF, lastig te parsen in de browser zonder
extra library); `aardbevingen_cijfers` bleek aggregaat-tellingen te zijn, geen coördinaten per
event.

## Databronnen

- **Aardbevingen:** KNMI, rechtstreeks opgehaald als CSV via `rdsa.knmi.nl`. De categorieën
  `induced` en `tectonic` worden afzonderlijk bevraagd.
- **Rijksmonumenten:** RCE Cultureel Erfgoed Open Data, via het CHO SPARQL-endpoint.
- **Mijnbouwvelden en mijnbouwlocaties:** NLOG / Geologische Dienst Nederland via de publieke
  WFS-service (`https://www.gdngeoservices.nl/geoserver/nlog/ows`). De applicatie gebruikt
  onder meer `gdw_ng_field_utm` en `gdw_ng_facility_utm`.
- **Luchtfoto:** PDOK / Beeldmateriaal via de RGB-luchtfoto WMS
  (`https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0`), laag `Actueel_ortho25`.
- **Ontologie:** CEO, de Cultureel Erfgoed Ontologie van de Rijksdienst voor het Cultureel
  Erfgoed.

De gebruikte data-endpoints ondersteunen browsergebruik zonder eigen backend. De applicatie
bevraagt KNMI, RCE en NLOG rechtstreeks; kaart- en luchtfototegels worden door Leaflet bij de
betreffende externe kaartdienst opgehaald.

## NLOG: mijnbouwlagen

De NLOG-integratie laadt twee typen objecten rechtstreeks uit de publieke WFS-service:

- **Mijnbouwvelden:** `gdw_ng_field_utm`. Deze laag staat standaard aan en wordt op type
  gestileerd (onder andere gas, olie, geothermie en opslag).
- **Mijnbouwlocaties:** `gdw_ng_facility_utm`. Deze puntlaag staat standaard uit en kan in de
  zijbalk worden ingeschakeld.

De gebruiker kan client-side filteren op alle operators of alleen NAM. De data wordt niet in de
repository opgeslagen. Bij het laden vraagt de applicatie eerst de beschikbare WFS-laagnamen op
via `GetCapabilities`; daarna wordt GeoJSON opgehaald via WFS 2.0.0, met WFS 1.1.0 als fallback.

## Achtergrondkaarten

De standaardondergrond is PDOK BRT Achtergrondkaart in het thema pastel, geladen via WMTS in
EPSG:3857. De gebruiker kan overschakelen naar OpenStreetMap voor dekking buiten Nederland of
naar de actuele RGB-luchtfoto van PDOK / Beeldmateriaal. De luchtfoto wordt als WMS-laag geladen.
Elke externe aanvraag wordt pas actief wanneer de gebruiker die basislaag kiest. Geen van deze
basislagen vereist een API-key.
## Rijksmonumenten: filtering en dataqualiteit

- **Alleen geldige rijksmonumenten**: gefilterd op juridische status = "rijksmonument" (dus niet
  "voorbeschermd" of "geen rijksmonument").
- Rijksmonumenten worden in twee aparte queries opgehaald: "onroerend gebouwd" (gelimiteerd tot
  400, dichtstbijzijnde eerst, bij een grote straal in een dichte regio zoals Amsterdam kan het
  werkelijke aantal hoger liggen) en "archeologisch" (limiet 3.000, landelijk maar ~1.500 dus in
  de praktijk ongelimiteerd). Deze splitsing is bewust: bij één gedeelde LIMIT 400 verdrongen
  gebouwde monumenten de archeologische categorie systematisch, een scheepswrak op 25 km van een
  epicentrum verscheen nooit omdat er 792 gebouwde monumenten dichterbij lagen. Bevestigd
  gerepareerd voor "Scheepswrak aanloop Molengat" (rijksmonumentnr. 532450, bij Den Helder).
- Naam is bij slechts ~13% van de rijksmonumenten bekend, oorspronkelijke functie bij vrijwel
  100%, huidige functie apart bij ~8%, dit is een eigenschap van de brondata, geen bug (zie ook
  de code-comments in `docs/index.html`).
