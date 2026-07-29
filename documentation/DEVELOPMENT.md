# Ontwikkeling: structuur, geschiedenis, beperkingen en roadmap

## Bestandsstructuur

- **`docs/index.html`** - de actuele, canonieke versie. Dit is ook het bestand dat GitHub Pages
  serveert zodra Pages is ingesteld op de map `docs/` (standaardconventie: geen aparte
  build-/deploy-stap nodig).
- **`docs/achtergrond.html`** - statische informatiepagina (geen kaart/JS-state) over waarom
  aardbevingen en rijksmonumenten samenhangen: het RCE-werkproces "versterken erfgoed", de schaal
  van de problematiek, en hoe deze kaart zich verhoudt tot de officiële, beoordeelde
  versterkingslijst. Onderling gelinkt met `index.html` (footer ↔ "Terug naar de kaart").
- **`docs/logo.svg`** - standalone versie van het eigen beeldmerk (zie v0.20.2), met een witte
  achtergrond zodat het ook leesbaar blijft op GitHub's donkere thema. Losstaand van de inline
  SVG's in `index.html`/`achtergrond.html` (bewust niet gedeeld, om geen refactor-risico te nemen
  op de al werkende, geteste app-pagina's) - gebruikt in `README.md` als logo bovenaan.
- `aardbevingen_en_rijksmonumenten_v0.20.4.html` + `aardbevingen_en_rijksmonumenten_achtergrond_v0.20.4.html`
  - versienummerde momentopname van het pagina-paar (`docs/index.html` + `docs/achtergrond.html`),
  onderling gelinkt (niet naar de `docs/`-versies), voor wie een specifieke release wil
  terugvinden zonder door de git-historie te zoeken. Rechtgezet in v0.19.0 (het vorige,
  ongenummerde bestand met inhoud op v0.16.0 verving) en sindsdien meegewerkt per versie.

Het oudere `aardbevingen_kaart.html` (van vóór v0.16.0) is verwijderd nadat is geverifieerd dat
`docs/index.html` er een volledige superset van is - geen functionaliteit kwijt, wel twee
verklarende code-comments teruggezet die tijdens een refactor per ongeluk waren weggevallen.

## Bekende beperkingen

Getest (juli 2026) met de responsive-resize-tool van de browser:

- **Mobiel (375px breed): opgelost sinds v0.16.0.** Een `@media (max-width: 700px)`-breakpoint
  stapelt de zijbalk (max 45% hoogte) boven de kaart (55%) i.p.v. ernaast. Geverifieerd: geen
  horizontale overflow meer (`document.body.scrollWidth === window.innerWidth`).
- **Tablet (768px breed): bruikbaar**, zijbalk en kaart zijn beide zichtbaar, geen overflow.
- **Alle aardbevingen blijven zichtbaar** op de kaart, ook nadat je een epicentrum hebt
  geselecteerd - dat kan rommelig ogen bij een dichte cluster. Opgelost sinds v0.19.2: de
  NIET-geselecteerde bevingen faden zodra er een epicentrum actief is.
- De applicatie blijft afhankelijk van de beschikbaarheid van KNMI, RCE, CARTO en unpkg; bij
  timeout (20s) of falen van één bron toont de pagina sinds v0.16.0 de andere bron nog wel
  (`Promise.allSettled`), met een statusmelding welk deel ontbreekt.
- **Cross-browser: gedaan.** Chrome, Firefox en Safari getest door meerdere gebruikers - alles werkt.
  **Mobiel: bug gevonden en gefixt (v0.19.5).** De uitgeklapte legenda kon hoger worden dan de
  kaartpane zelf; Leaflet's bottom-anchored control groeide dan omhoog voorbij de bovenkant van
  `#map` (dat `overflow:hidden` heeft), waardoor zelfs de "Legenda"-knop buiten het klikbare
  kaartgebied kwam en niet meer te sluiten was - een tik op die plek raakte in plaats daarvan een
  zijbalk-paneel eronder. Root cause bevestigd via `elementFromPoint()`/`getBoundingClientRect()`
  op een 375px-viewport. Fix: `.legend-control-body { max-height: 35dvh; overflow-y: auto; }` in
  de mobiele media query, zodat de legenda nooit meer boven de kaartpane kan uitgroeien. Alleen
  op desktop (>700px) blijft de legenda onbegrensd (`max-height: none`), geen regressie daar.
- **Kleurenblindheid-check: gedaan (v0.19.5).** Gesimuleerd met de Machado et al. (2009)-matrices
  (dezelfde die Chrome's eigen "Emulate vision deficiencies" gebruikt) op de drie stoplicht-
  kleuren. Uitkomst: bij deuteranopie (de meest voorkomende vorm, ~5% van mannen) lagen rood
  (#c0392b) en het oorspronkelijke groen (#2e7d32) nagenoeg op elkaar (RGB-afstand 13 van de
  ~440 mogelijke) - vrijwel niet te onderscheiden. Bij protanopie was het verschil ook mager (61).
  Opgelost door groen te vervangen door Okabe & Ito's "bluish green" (#009E73, uit hun bekende
  kleurenblind-veilige palet): voor gewoon zicht nog steeds duidelijk "groen", maar de afstand tot
  rood loopt op naar 78 (deuteranopie) en 115 (protanopie). Rood en oranje bleven in alle gevallen
  goed te onderscheiden, dus alleen groen is aangepast.

Zie ook [DATA.md](DATA.md) voor de dataspecifieke beperkingen (query-limieten, veldvulling).

## Roadmap naar v0.20.0 (eerste officiële release) - AFGEROND

Checklist die is afgerond voordat v0.20.0 als eerste officiële publieke release is getagd:

1. ~~**Hernoem "impactscore" naar "impactindicatie"**~~ - **gedaan** (v0.19.0): term aangepast
   door de hele interface (legenda, popup) en documentatie (README, IMPACTSCORE.md,
   achtergrond.html). Interne codenamen (`impactScore()`, `impactColor()`) bewust ongewijzigd
   gelaten - dat is implementatiedetail, geen gebruikersgerichte tekst.
2. ~~**Numerieke schijnprecisie heroverwegen**~~ - **gedaan** (v0.19.0): popup toont nu 1 decimaal
   (`score.toFixed(1)`, was 2). Volstaat: de kalibratie zelf is al maar tot ±0,01 magnitude gefit
   op de drie IMG-punten, en de coëfficiënten zijn niet nauwkeuriger dan dat - een tweede
   decimaal in de weergave zou dus sowieso ongefundeerde schijnnauwkeurigheid zijn geweest. Bij de
   kleurgrenzen (score ≥ 1, score ≥ 0) verandert 1 decimaal niets aan de indeling.
3. **Validatie van de impactindicatie** - blijft het grootste inhoudelijke risico en staat nog
   open. Wat verdere validatie concreet zou opleveren: (a) betere onderbouwing waaróm de kaart
   alleen ondiepe, geïnduceerde bevingen dekt in plaats van dat als losse waarschuwing te melden;
   (b) mogelijk een tweede, apart gekalibreerde curve voor diepere/tektonische bevingen in plaats
   van "geen betrouwbare uitspraak"; (c) een onderbouwde reactie als iemand de methode bekritiseert
   - nu steunt de kalibratie op maar 3 publieke datapunten, wat een makkelijk aanvalspunt is.
   Concreet zou dit betekenen: meer IMG/KNMI-publicaties met bekende effectgebieden opsporen om
   op te fitten, en/of de eigen indicatie naast RCE's daadwerkelijke monitoringdata leggen (zie
   `docs/achtergrond.html`, sectie "Hoe RCE het écht meet") om te zien hoe ver de vuistregel
   afwijkt van metingen. Dit is een onderzoekstaak, geen ontwikkeltaak - nog geen tijdsinschatting.
4. ~~**Niet-geselecteerde aardbevingen faden**~~ - **gedaan** (v0.19.1): `selectEpicenter()` slaat
   nu ook de bronreferentie van het geklikte/gezochte event op (`state.selected.sourceEvent`,
   object-identiteit i.p.v. lat/lon-vergelijking - robuust tegen bevingen met identieke
   coördinaten). `renderEarthquakeMarkers()` (opgesplitst met een nieuwe helper
   `addEarthquakeMarker(ev, fillOpacity, strokeOpacity)`) tekent bij een actieve selectie alle
   overige bevingen op `fillOpacity 0,15`/`opacity 0,25`, de geselecteerde als laatste (dus
   bovenop) op volle 0,85/1. Live geverifieerd: van 3.750 markers gingen er 3.749 naar 0,15 en 1
   (de geklikte) bleef op 0,85.
5. ~~**Korte, niet-verplichte uitleg toevoegen**~~ - **gedaan** (v0.19.0): een knop
   "Hoe werkt deze kaart?" naast de titel opent een uitklapblok (`#helpBody`, geen modal) met de
   drie stappen; het "Geselecteerd epicentrum"-paneel toont dezelfde drie stappen als
   lege-starttoestand (`EMPTY_STATE_STEPS_HTML`, hergebruikt in zowel de statische HTML als
   `renderSelectedInfo()`); en een info-icoon (ⓘ, met `title`-tooltip) staat nu naast
   "Impactindicatie" in zowel de legenda-hint als de monument-popup. Bewust geen verplichte popup
   bij het laden. Live geverifieerd, geen console-errors.
6. ~~**Cross-browser en mobiel testen**~~ - **gedaan** (v0.19.5): Chrome/Firefox/Safari getest
   (werkt), plus een echte mobiel-bug gevonden en gefixt (zie "Bekende beperkingen" hierboven).
7. ~~**Kleurenblindheid-check**~~ - **gedaan** (v0.19.5): een echt probleem gevonden (rood/groen
   vrijwel identiek bij deuteranopie) en gefixt door groen te vervangen door een
   kleurenblind-veilige variant (zie "Bekende beperkingen" hierboven).

Alle zeven checklist-punten zijn afgerond, **op punt 3 (validatie van de impactindicatie) na** -
die is bewust uitgesteld naar het onderzoekstraject voor de 2e officiële release (zie hieronder).

## Roadmap naar de 2e officiële release

- **Validatie van de impactindicatie** (roadmap-item 3 hierboven, uitgesteld) - Nog geen tijdsinschatting.

## Gemeld door een gebruiker: rijksmonumentnummer-zoeken - opgelost (vóór v0.20.0-release)

Gevonden bij hands-on gebruik na v0.19.3, gefixt vóór het taggen van v0.20.0:

- ~~**Bug: dubbele/verouderde marker.**~~ - **gefixt.** Root cause was dubbel: (1) `monSearchLayer`
  werd nooit opnieuw getekend of geleegd na het moment van zoeken, en (2) het opgezochte
  monument-object had altijd `distKm: null` (geen afstandsfilter in de nummer-query), waardoor
  `impactScore()` sowieso altijd `null` teruggaf - de marker kon dus NOOIT van kleur veranderen,
  ongeacht welk epicentrum actief was. Opgelost met een nieuwe `renderMonSearchMarker()`,
  aangeroepen vanuit `renderMonuments()` (dus bij elke straal-/epicentrum-wijziging): berekent
  `distKm` opnieuw tov het actuele epicentrum (`haversineKm`) en slaat de marker over zodra
  hetzelfde rijksmonumentnummer al in de straal-resultaten zit. Live geverifieerd: marker bleef
  zichtbaar en van kleur veranderd na een verre epicentrum-selectie (448 iconen, geen grijs meer);
  correct overgeslagen zodra het monument alsnog in de straal viel (614 = 614, geen dubbele).
- ~~**Verzoek: reset/wis-knop**~~ - **gedaan.** Nieuwe knop `#monNrResetBtn` naast Zoek, leegt
  `monSearchLayer`, `monNrStatus` en het invoerveld. Live geverifieerd: 448 → 447 iconen na klikken.
- ~~**Verzoek: zichtbare laad-indicator**~~ - **gedaan.** Nieuwe `loadingHtml()`-helper (draaiende
  CSS-spinner + tekst, met `prefers-reduced-motion`-uitzondering) vervangt de eerdere kale
  `.loading`-tekst overal: aardbevingen laden, rijksmonumenten binnen straal, nummer-opzoeking.

## Mogelijke uitbreidingen (later)

- ~~Filter op monumentaard/oorspronkelijke functie~~ - **gedaan** (v0.20.3): klikbare labels met
  aantallen filteren zowel de kaart als de CSV-export, volledig client-side (geen database nodig,
  zoals aanvankelijk gevreesd) over `state.lastMonuments`. Functielijst begrensd tot de 12
  grootste categorieën. Reset automatisch bij een nieuw epicentrum of als de actieve categorie
  door een straal-wijziging niet meer voorkomt. Zie CHANGELOG voor de volledige details.

- ~~Eigen beeldmerk i.p.v. KNMI/RCE-logo's~~ - **gedaan** (v0.20.2): inline SVG (huisje + schop op
  een seismogram-golflijn, `--accent`-kleur) vervangt de logo's bovenaan de zijbalk en op
  `docs/achtergrond.html`. Reden: een overheidslogo op een niet-gelieerde toepassing wekt een
  schijn van samenwerking, wat de disclaimer juist ontkracht. Tekstuele bronvermelding
  (KNMI/CEO-RCE-links in de footer) blijft staan - dat is feitelijke attributie, geen logo-gebruik.

- ~~Download CSV van de straal-resultaten~~ - **gedaan** (v0.20.1): knop bij "Rijksmonumenten
  binnen straal" exporteert een platte, pipe-gescheiden CSV (aardbeving + alle getoonde
  rijksmonumenten, beide typen), client-side gegenereerd via `Blob`. Zie CHANGELOG voor de
  volledige kolomlijst.

- ~~Visuele markering voor rijksmonumenten in het officiële RCE-versterkingsprogramma~~ -
  **gedaan** (v0.19.0), optie (a) puur informatief gekozen (niet een filter): monumenten waarvan
  het rijksmonumentnummer voorkomt in `VERSTERKINGSPROGRAMMA_NRS` (de aangeleverde lijst van 140
  nummers) krijgen een paarse stippelring rond het icoon (los van de rood/oranje/groen-
  impactindicatie) plus een regel in de popup ("In het officiële RCE-versterkingsprogramma").
  Puur ter vergelijking van de exploratieve straal-selectie met de officiële, beoordeelde lijst -
  geen filter. Live geverifieerd op rijksmonument nr. 26265 (Petrus en Pauluskerk, Loppersum).
  Kanttekening: dit is een snapshot van de door RCE geleverde/samengestelde lijst, geen live
  koppeling - kan achterlopen als de officiële lijst wijzigt.

- ~~Rijksmonumentnummer-opzoeking (locatie + dichtstbijzijnde aardbeving)~~ - **gedaan** (v0.19.3):
  nieuw paneel "Zoek op rijksmonumentnummer". Invoer strikt gevalideerd tegen `/^\d+$/` vóór
  interpolatie in de SPARQL-query (enige plek in de app met vrije tekstinvoer richting een query -
  injectierisico anders). Nieuwe query `buildMonumentByNumberQuery(nr)` (geen afstandsfilter,
  haalt zelf de aard-URI op om huisje/schop te bepalen) en `mapMonumentByNumberBindings()`.
  Marker- en popup-opbouw hergebruikt via een nieuwe gedeelde `buildMonumentMarker(m)`-functie
  (ook gebruikt door `renderMonuments()`) - geen tweede visuele taal. Eigen `monSearchLayer`
  (niet `monLayer`), zodat een latere straal-wijziging de gevonden marker niet wegveegt.
  Dichtstbijzijnde aardbeving via een nieuwe `nearestEarthquake()`-scan over de volledige
  `state.events` (1911-heden), los van de tijdslider. Resultaat toont een brug-knop "Selecteer
  deze aardbeving als epicentrum" die de bestaande `selectEpicenter()` aanroept. **Bug gevonden en
  gefixt tijdens het testen**: de eerste queryversie matchte `ceo:rijksmonumentnummer` op een
  letterlijke waarde zonder die aan `?nr` te binden, waardoor `?nr` in elke oplossing ontbrak
  (`b.nr` was `undefined` in JS) - opgelost met een expliciete `BIND("nr" AS ?nr)`. Live
  geverifieerd op nr. 26265 (Loppersum, Petrus en Pauluskerk, ook in het versterkingsprogramma):
  vindt "27-10-2007 · M2.0 · 0.1 km" als dichtstbijzijnde beving; brug-knop selecteert 'm correct
  als epicentrum (1.689 aardbevingen / 613 rijksmonumenten binnen 25 km). Ongeldige/niet-gevonden
  nummers geven een duidelijke foutmelding i.p.v. een crash.

**Bewust niet opgepakt:**
- Polygon-centroid i.p.v. het eerste WKT-coördinatenpaar: die precisie is niet nodig gebleken.
- Caching van monument-queries: de live SPARQL-query is al snel genoeg, caching lost geen
  merkbaar probleem op.

## Open beslissingen

- **Besloten: de versioned-snapshot-conventie blijft** (zie Bestandsstructuur hierboven): een
  bijgewerkt, versienummerd paar per versie, onderling zelfstandig gelinkt.
