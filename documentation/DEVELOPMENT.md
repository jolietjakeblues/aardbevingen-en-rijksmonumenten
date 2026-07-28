# Ontwikkeling: structuur, geschiedenis, beperkingen en roadmap

## Bestandsstructuur

- **`docs/index.html`** - de actuele, canonieke versie. Dit is ook het bestand dat GitHub Pages
  serveert zodra Pages is ingesteld op de map `docs/` (standaardconventie: geen aparte
  build-/deploy-stap nodig).
- **`docs/achtergrond.html`** - statische informatiepagina (geen kaart/JS-state) over waarom
  aardbevingen en rijksmonumenten samenhangen: het RCE-werkproces "versterken erfgoed", de schaal
  van de problematiek, en hoe deze kaart zich verhoudt tot de officiële, beoordeelde
  versterkingslijst. Onderling gelinkt met `index.html` (footer ↔ "Terug naar de kaart").
- `aardbevingen_en_rijksmonumenten.html` - momentopname van `index.html`, bedoeld als
  versienummerde snapshot (voorheen `..._v0.16.0.html`) zodat een specifieke release terug te
  vinden is zonder door de git-historie te zoeken. **Momenteel achterhaald**: mist het
  versienummer in de bestandsnaam en de inhoud staat nog op v0.16.0 (geen kopie van
  `achtergrond.html`, geen van de wijzigingen sinds v0.17.0) - zie "Open beslissingen" hieronder.

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
  geselecteerd - dat kan rommelig ogen bij een dichte cluster. Besloten (i.p.v. de geselecteerde
  beving apart te markeren): de NIET-geselecteerde bevingen faden/dimmen zodra er een epicentrum
  actief is - zie roadmap-item 4 hieronder.
- De applicatie blijft afhankelijk van de beschikbaarheid van KNMI, RCE, CARTO en unpkg; bij
  timeout (20s) of falen van één bron toont de pagina sinds v0.16.0 de andere bron nog wel
  (`Promise.allSettled`), met een statusmelding welk deel ontbreekt.
- Alleen getest in een Chromium-gebaseerde browser (preview-omgeving); Firefox, Safari en een
  echt mobiel toestel nog niet expliciet geverifieerd.
- Kleurenblindheid-check op het rood/oranje/groen-stoplicht is nog niet gedaan.

Zie ook [DATA.md](DATA.md) voor de dataspecifieke beperkingen (query-limieten, veldvulling).

## Roadmap naar v0.20.0 (beoogde eerste publieke release)

Checklist die eerst afgerond wordt voordat v0.20.0 als eerste officiële publieke release getagd
wordt:

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
4. **Niet-geselecteerde aardbevingen faden** zodra er een epicentrum actief is (i.p.v. de
   geselecteerde apart te markeren). Concreet: `renderEarthquakeMarkers()` kent al een volledige
   lijst zichtbare bevingen; bij een actieve selectie kunnen de overige markers een lagere
   `fillOpacity`/`opacity` krijgen (bv. 0,15) terwijl de geselecteerde beving z'n volle kleur
   behoudt - geen nieuwe marker of icoon nodig, alleen een opacity-tak in de render-functie.
5. **Korte, niet-verplichte uitleg toevoegen** - uitgewerkt voorstel:
   - Een knop **"Hoe werkt deze kaart?"** naast de titel in de zijbalk, die een
     `<details>`/uitklapblok opent (geen modal/popup - blijft naast de rest van de UI staan,
     sluit zichzelf niet geforceerd).
   - Inhoud, drie stappen: "1. Selecteer een aardbeving op de kaart of zoek op plaatsnaam. 2. Kies
     een straal. 3. Bekijk de rijksmonumenten binnen dat gebied - de kleur is een verkennende
     impactindicatie, geen schadebeoordeling."
   - Een lege-starttoestand: zolang er nog geen epicentrum gekozen is, toont het
     "GESELECTEERD EPICENTRUM"-paneel dezelfde drie stappen in plaats van de huidige neutrale
     "Klik op een aardbeving op de kaart." - hergebruikt dus dezelfde tekst, geen aparte component.
   - Een klein info-icoon (bv. "ⓘ") naast "Impactindicatie" in de legenda-hint en/of popup, met
     een `title`-attribuut of kort tooltipje dat naar dezelfde uitleg verwijst - voor wie de
     uitklaptekst gemist heeft.
   - Bewust geen verplichte popup bij het laden van de pagina.
6. **Cross-browser en mobiel testen**: Chrome, Firefox, Safari en een echt mobiel toestel.
7. **Kleurenblindheid-check** op het rood/oranje/groen-stoplicht.

## Mogelijke uitbreidingen (na v0.20.0)

- Visuele markering op de kaart voor rijksmonumenten die in het officiële RCE-versterkingsprogramma
  zitten. Er is al een aangeleverde lijst van ~140 monumentnummers uit die officiële lijst;
  `ceo:rijksmonumentnummer` is direct bevraagbaar in de RCE-linked-data (geverifieerd live), dus
  dit is technisch haalbaar zonder de namen/adressen zelf te hoeven opslaan - alleen de nummers.
  Open vraag, nog te beantwoorden voordat dit gebouwd wordt: wat levert dit de gebruiker concreet
  op? Opties: (a) puur informatief - een extra badge/rand die toont "dit monument zit al in het
  beoordeelde versterkingsprogramma", zodat de gebruiker de exploratieve straal-selectie van deze
  kaart kan vergelijken met de officiële, definitieve lijst; (b) een filter om ALLEEN de
  versterkingsprogramma-monumenten te tonen; (c) beide. Zonder een concreet antwoord hierop is dit
  feature nog te vaag om in te plannen.

**Bewust niet opgepakt (besloten deze sessie):**
- Polygon-centroid i.p.v. het eerste WKT-coördinatenpaar: die precisie is niet nodig gebleken.
- Caching van monument-queries: de live SPARQL-query is al snel genoeg, caching lost geen
  merkbaar probleem op.

## Open beslissingen

- **Besloten: de versioned-snapshot-conventie blijft.** Elke release krijgt een los HTML-bestand
  met versienummer in de bestandsnaam. Let op: het bestand staat momenteel *niet* meer volgens die
  conventie in de repo - het heet nu `aardbevingen_en_rijksmonumenten.html` (zonder
  versienummer) en de inhoud is nog v0.16.0, dus het mist alle wijzigingen sinds v0.17.0
  (automatisch zoomen, achtergrondpagina, documentatie-herstructurering, KNMI-fix,
  impactindicatie-hernoeming). Moet worden rechtgezet: hernoemen naar een versienummer en de
  inhoud bijwerken naar de actuele `docs/index.html` (+ eventueel een versienummerde kopie van
  `docs/achtergrond.html`) - nog niet uitgevoerd, wacht op bevestiging van de gewenste
  bestandsnaam/frequentie (bij elke versie, of alleen bij publieke releases als v0.20.0).
- Wanneer/of er een officiële GitHub Release getagd wordt - tot die tijd is elke versie in
  [CHANGELOG.md](../CHANGELOG.md) een ontwikkelversie, geen release.
