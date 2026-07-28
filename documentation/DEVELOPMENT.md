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

1. **Validatie van de impactindicatie** - blijft het grootste inhoudelijke risico. De indicatie
   is gekalibreerd op een beperkt aantal gepubliceerde effectgebieden, vooral bedoeld voor
   ondiepe, geïnduceerde bevingen; voor diepe of tektonische bevingen blijft het een
   extrapolatie. Aanvullende validatie is nodig voordat de methode breder wordt toegepast.
2. **Hernoem "impactscore" naar "impactindicatie"** door de hele interface en documentatie -
   klinkt minder absoluut, sluit beter aan bij het indicatieve, verkennende karakter.
3. **Numerieke schijnprecisie heroverwegen** - een kaal getal als "0,42" suggereert meer precisie
   dan de methode kan waarmaken; overwegen minder decimalen te tonen of een kwalitatief label
   i.p.v. het rauwe getal.
4. **Korte, niet-verplichte uitleg toevoegen** - gebruikers moeten drie dingen begrijpen (een
   aardbeving selecteren, een zoekstraal kiezen, de impactindicatie niet als schadevoorspelling
   lezen). Geen verplichte popup (irriteert snel); wel bijvoorbeeld een knop "Hoe werkt deze
   kaart?", een kort uitklapbaar informatieblok, een lege-starttoestand met de drie stappen, en
   een info-icoon bij "impactindicatie". Voorbeeldtekst: *"Selecteer een aardbeving, kies een
   straal en bekijk de rijksmonumenten binnen dat gebied. De kleur bij een monument is een
   verkennende indicatie en geen schadebeoordeling."*
5. **Geselecteerde beving duidelijk markeren** op de kaart, zodat die herkenbaar blijft tussen de
   andere markers (vorm nog open - kruisje is één optie).
6. **Cross-browser en mobiel testen**: Chrome, Firefox, Safari en een echt mobiel toestel.
7. **Kleurenblindheid-check** op het rood/oranje/groen-stoplicht.

## Mogelijke uitbreidingen (na v0.20.0)

- Visuele markering op de kaart voor rijksmonumenten die in het officiële RCE-versterkingsprogramma
  zitten. Er is al een aangeleverde lijst van ~140 monumentnummers uit die officiële lijst;
  `ceo:rijksmonumentnummer` is direct bevraagbaar in de RCE-linked-data (geverifieerd live), dus
  dit is technisch haalbaar zonder de namen/adressen zelf te hoeven opslaan - alleen de nummers.
- Polygon-centroid berekenen in plaats van het eerste WKT-coördinatenpaar, voor nauwkeurigere
  monument-posities.
- Caching van monument-queries per (epicentrum, straal)-combinatie.

## Open beslissingen

- Of de losse "versioned snapshot"-file (`aardbevingen_en_rijksmonumenten_v0.16.0.html`) het
  waard is om te blijven onderhouden nu de site uit meerdere pagina's bestaat (`docs/index.html` +
  `docs/achtergrond.html`), of dat die conventie losgelaten kan worden nu `docs/` de canonieke
  bron is en git-tags/releases dezelfde rol zouden kunnen vervullen.
- Wanneer/of er een officiële GitHub Release getagd wordt - tot die tijd is elke versie in
  [CHANGELOG.md](../CHANGELOG.md) een ontwikkelversie, geen release.
