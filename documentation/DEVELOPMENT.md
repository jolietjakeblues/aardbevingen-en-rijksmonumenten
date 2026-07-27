# Ontwikkeling: structuur, geschiedenis, beperkingen en roadmap

## Bestandsstructuur

- **`docs/index.html`** - de actuele, canonieke versie. Dit is ook het bestand dat GitHub Pages
  serveert zodra Pages is ingesteld op de map `docs/` (standaardconventie: geen aparte
  build-/deploy-stap nodig).
- **`docs/achtergrond.html`** - statische informatiepagina (geen kaart/JS-state) over waarom
  aardbevingen en rijksmonumenten samenhangen: het RCE-werkproces "versterken erfgoed", de schaal
  van de problematiek, en hoe deze kaart zich verhoudt tot de officiële, beoordeelde
  versterkingslijst. Onderling gelinkt met `index.html` (footer ↔ "Terug naar de kaart").
- `aardbevingen_en_rijksmonumenten_v0.16.0.html` - momentopname van `index.html` onder een
  versienummer, voor wie een specifieke release wil terugvinden zonder door de git-historie te
  hoeven zoeken. Bevat nog geen kopie van `achtergrond.html` (toegevoegd in een latere versie) -
  zie "Open beslissingen" hieronder voor of dit conventie de moeite waard blijft nu de site
  meerdere pagina's heeft.

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
  geselecteerd - dat kan rommelig ogen bij een dichte cluster. Gepland: niet-geselecteerde
  bevingen dimmen of filteren zodra er een epicentrum actief is.
- Afspeelsnelheid van de tijd-animatie staat vast op 400 ms per jaar, nog niet instelbaar.
- De applicatie blijft afhankelijk van de beschikbaarheid van KNMI, RCE, CARTO en unpkg; bij
  timeout (20s) of falen van één bron toont de pagina sinds v0.16.0 de andere bron nog wel
  (`Promise.allSettled`), met een statusmelding welk deel ontbreekt.
- Kleurenblindheid-check op het rood/oranje/groen-stoplicht is nog niet gedaan.
- Alleen getest in een Chromium-gebaseerde browser (preview-omgeving); Firefox/Safari niet
  expliciet geverifieerd.

Zie ook [DATA.md](DATA.md) voor de dataspecifieke beperkingen (query-limieten, veldvulling).

## Mogelijke uitbreidingen

- Polygon-centroid berekenen in plaats van het eerste WKT-coördinatenpaar, voor nauwkeurigere
  monument-posities.
- Caching van monument-queries per (epicentrum, straal)-combinatie.
- Visuele markering (bv. een kruisje) op de geselecteerde aardbeving-marker zelf, zodat die op de
  kaart te onderscheiden is van de overige aardbevingen nadat je erop geklikt hebt.
- Visuele markering op de kaart voor rijksmonumenten die in het officiële RCE-versterkingsprogramma
  zitten. Er is al een aangeleverde lijst van ~140 monumentnummers uit die officiële lijst;
  `ceo:rijksmonumentnummer` is direct bevraagbaar in de RCE-linked-data (geverifieerd live), dus
  dit is technisch haalbaar zonder de namen/adressen zelf te hoeven opslaan - alleen de nummers.
  Voor een ander keertje.
- Archeologische monumenten (schop-icoon) een eigen kleur geven bij "buiten indicatie" - bruin in
  plaats van het huidige groen - zodat de kleur niet alleen de impactscore maar ook het type
  meesignaleert. Uitwerken hoe dit zich verhoudt tot het bestaande rood/oranje/groen-stoplicht bij
  "in indicatie", waar de score juist de enige betekenisvolle kleurdimensie is.

## Open beslissingen

- Of de losse "versioned snapshot"-file (`aardbevingen_en_rijksmonumenten_v0.16.0.html`) het
  waard is om te blijven onderhouden nu de site uit meerdere pagina's bestaat (`docs/index.html` +
  `docs/achtergrond.html`), of dat die conventie losgelaten kan worden nu `docs/` de canonieke
  bron is en git-tags/releases dezelfde rol zouden kunnen vervullen.
- Wanneer/of er een officiële GitHub Release getagd wordt - tot die tijd is elke versie in
  [CHANGELOG.md](../CHANGELOG.md) een ontwikkelversie, geen release.
