# Aardbevingen NL — epicentrum & rijksmonumenten

Interactieve kaart van Nederlandse aardbevingen met een straal-selectie die laat zien welke
rijksmonumenten binnen die straal liggen, inclusief een indicatieve "impactscore" per monument.

Standalone HTML-bestand (`aardbevingen_kaart.html`), geen build-stap, geen server-side code,
geen API-key nodig. Bedoelde repository: `github.com/jolietjakeblues/aardbevingen-en-rijksmonumenten`
(nog niet gepubliceerd — dit is de lokale voorbereiding).

## Wat is live en wat niet

**Alles is live.** Er zit geen ingebakken/embedded dataset in de HTML — bij het openen van de
pagina en bij elke interactie wordt er in de browser (`fetch()`) rechtstreeks bij de bron
bevraagd:

| Onderdeel | Wanneer opgehaald | Bron |
|---|---|---|
| Aardbevingen (alle ~3.700) | eenmalig bij laden van de pagina | RCE linked data, live SPARQL |
| Rijksmonumenten binnen straal | bij elke selectie/straal-wijziging (gedebounced, 350ms) | RCE CHO linked data, live SPARQL |
| Kaarttegels | doorlopend tijdens pannen/zoomen | CARTO (extern, CDN) |
| Leaflet-library | eenmalig bij laden | unpkg CDN |

Er is dus geen "ververs de data"-knop nodig en geen risico op een verouderde snapshot — maar
het betekent ook dat de pagina niet werkt zonder internetverbinding, en dat de snelheid afhangt
van de RCE-endpoints.

## Features

- **Epicentrum selecteren**: klik op een aardbeving op de kaart, of typ een plaatsnaam (zoekveld
  met autocomplete, gevuld uit de toponiemen die al in de aardbevingsdata zitten — geen aparte
  geocoding-service nodig). Springt naar de meest recente beving bij die plaatsnaam.
- **Straal-slider** (1–200 km): tekent een cirkel en herberekent statistieken en monumenten live.
- **Aardbevingen-popup**: toponiem, datum/tijd, magnitude (ML), diepte, categorie (geïnduceerd /
  tektonisch / steengroeve-explosie).
- **Rijksmonumenten-popup**: naam (indien aanwezig), oorspronkelijke functie (vrijwel altijd
  aanwezig) én huidige functie apart getoond wanneer bekend, monumentaard (archeologisch /
  onroerend gebouwd), link naar het monumentenregister én de linked-data URI zelf.
- **Alleen geldige rijksmonumenten**: gefilterd op juridische status = "rijksmonument" (dus niet
  "voorbeschermd" of "geen rijksmonument").
- **Impactscore**: per rijksmonument een indicatie of het epicentrum-monument-paar binnen een
  realistisch "effectgebied" valt — zie hieronder.

## Databronnen

- Aardbevingen: `https://api.linkeddata.cultureelerfgoed.nl/datasets/rce/aardbevingen/sparql`
  (graph `https://linkeddata.cultureelerfgoed.nl/graph/aardbevingen`)
- Rijksmonumenten: `https://api.linkeddata.cultureelerfgoed.nl/datasets/rce/cho/services/cho/sparql`
  (juridische status en monumentaard specifiek uit graph
  `https://linkeddata.cultureelerfgoed.nl/graph/instanties-rce`, om dubbeltellingen te vermijden)
- Ontologie: [CEO](https://linkeddata.cultureelerfgoed.nl/def/ceo) (Rijksdienst voor het
  Cultureel Erfgoed)

Beide endpoints hebben open CORS (`Access-Control-Allow-Origin: *`), vandaar dat rechtstreeks
bevragen vanuit de browser werkt zonder eigen backend of proxy.

## Impactscore — uitgelegd

De impactscore is een **vereenvoudigde, illustratieve indicator** — geen gevalideerd schade- of
risicomodel. Doel: laten zien of een epicentrum-monument-combinatie plausibel binnen een
realistisch trillingsgebied valt, niet om schade te voorspellen.

### Formule

```
Rh (hypocentrale afstand, km) = √(epicentrale_afstand² + diepte²)
score = magnitude − 1.646 · log₁₀(Rh) − 1.052
```

`score ≥ 0` betekent: binnen het indicatieve effectgebied. Kleurcodering in de kaart:

- **rood** (`score ≥ 1`): ruim binnen effectgebied
- **groen** (`0 ≤ score < 1`): net binnen effectgebied
- **grijs, gedimd** (`score < 0`): buiten effectgebied

### Kalibratie (met bronnen)

De coëfficiënten (1.646 en 1.052) komen niet uit de losse pols — het zijn de resultaten van een
lineaire regressie op `log₁₀(Rh)` tegen magnitude, gefit op **drie echte, gepubliceerde
effectgebieden** van het Instituut Mijnbouwschade Groningen (IMG), allemaal op basis van dezelfde
methode (trillingssnelheidsdrempel 2 mm/s bij 1% overschrijdingskans, Bommer et al.-methode):

| Beving | Magnitude | Effectgebied | Bron |
|---|---|---|---|
| generiek IMG-voorbeeld | M2.7 | 9,5 km | [schadedoormijnbouw.nl — Effectgebied na een nieuwe beving](https://www.schadedoormijnbouw.nl/nieuws/2022/11/effectgebied-na-een-nieuwe-beving) |
| Wirdum, 8 okt 2012 | M3.1 | 17,5 km | [schadedoormijnbouw.nl](https://www.schadedoormijnbouw.nl/nieuws/2022/11/effectgebied-na-een-nieuwe-beving) |
| Huizinge, 16 aug 2012 | M3.6 | >35 km | [KNMI — Magnitude beving Huizinge wordt 3,6](https://www.knmi.nl/over-het-knmi/nieuws/magnitude-beving-huizinge-wordt-3-6) / schadedoormijnbouw.nl |

Diepte is voor deze drie punten aangenomen op ~3 km (de gebruikelijke diepte van het
Groningenveld). De gefitte lijn benadert alle drie punten binnen ±0,01 magnitude.

### Belangrijke beperking

Deze kalibratie is **alleen valide voor ondiepe (≤5 km), geïnduceerde bevingen** zoals in
Groningen. Getest tegen de zwaarste natuurlijke Nederlandse beving (Roermond, 1992, M5,8, 18 km
diep — reëel schadegebied ~15–20 km rond Roermond/Maaseik/Heinsberg volgens
[Wikipedia](https://en.wikipedia.org/wiki/1992_Roermond_earthquake)) blijkt de score op grote
afstand veel te hoog te blijven: andere bodem, andere diepte, andere attenuatie-eigenschappen dan
het Groningenveld. Vandaar een expliciete waarschuwing in de popup ("kalibratie minder
betrouwbaar") zodra de diepte van de geselecteerde beving groter is dan 5 km.

**Dit is en blijft een vuistregel voor verkenning, geen schadebeoordeling.**

## Bekende beperkingen / roadmap

Getest (juli 2026) met de responsive-resize-tool van de browser:

- **Mobiel (375px breed): werkt niet goed.** De zijbalk heeft een vaste breedte (340px) en
  schuift niet mee — op een telefoonformaat ontstaat horizontale overflow en is de kaart
  nauwelijks zichtbaar. Nog te bouwen: een responsive layout (bv. zijbalk onder de kaart, of
  inklapbaar, bij smalle viewports).
- **Tablet (768px breed): bruikbaar**, zijbalk en kaart zijn beide zichtbaar, geen overflow.
- **Alle aardbevingen blijven zichtbaar** op de kaart, ook nadat je een epicentrum hebt
  geselecteerd — dat kan rommelig ogen bij een dichte cluster. Gepland: niet-geselecteerde
  bevingen dimmen of filteren zodra er een epicentrum actief is.
- Rijksmonumenten-resultaat is gelimiteerd tot 400 (dichtstbijzijnde eerst) — bij een grote
  straal in een dichte regio (bv. Amsterdam) kan het werkelijke aantal hoger liggen.
- Naam is bij slechts ~13% van de rijksmonumenten bekend, huidige functie bij ~8% — dit is een
  eigenschap van de brondata, geen bug (zie ook de code-comments in `aardbevingen_kaart.html`).

## Mogelijke toekomstige toevoegingen

- **Tijd-animatie**: play-knop/slider die bevingen chronologisch laat verschijnen, om de
  toename (en recente afname) van geïnduceerde Groningse seismiciteit te laten zien.
- Polygon-centroid berekenen in plaats van het eerste WKT-coördinatenpaar, voor nauwkeurigere
  monument-posities.
- Caching van monument-queries per (epicentrum, straal)-combinatie.

## Lokaal draaien

Geen build-stap nodig. Twee opties:

1. Dubbelklik `aardbevingen_kaart.html` (werkt in de meeste browsers, `fetch()` naar externe
   https-bronnen is niet CORS-geblokkeerd vanaf een `file://`-pagina).
2. Of serveer de map lokaal voor de beste compatibiliteit:
   ```bash
   python -m http.server 8000
   ```
   en open `http://localhost:8000/aardbevingen_kaart.html`.

## Licentie

[MIT](LICENSE) — vrij te gebruiken, aan te passen en te verspreiden, mits de copyright-notice
behouden blijft. Let op: dit dekt alleen de code in deze repository. De gebruikte databronnen
(RCE linked data) zijn overheidsdata met hun eigen voorwaarden; check die van RCE en
IMG/schadedoormijnbouw.nl voordat je afgeleide claims publiceert.

## Dank aan

- Rijksdienst voor het Cultureel Erfgoed (RCE) — linked data voor aardbevingen en rijksmonumenten
- Instituut Mijnbouwschade Groningen (IMG) / schadedoormijnbouw.nl — effectgebied-cijfers voor de
  impactscore-kalibratie
- [Leaflet](https://leafletjs.com/) en [CARTO](https://carto.com/) — kaartweergave
