# Changelog

Alle wijzigingen zijn ontwikkeld in één sessie (juli 2026), als opeenvolgende iteraties op een
eerdere, verloren gegane versie die aardbevingen nog als ingebakken snapshot toonde. Achtergrond
en technische details per onderwerp: zie `documentation/`.

## v0.20.5 - laatst geregistreerde beving

Nieuwe regel bovenaan de zijbalk (onder de subtitel): "Laatst geregistreerde beving: [datum] ·
M[magnitude] bij [plaatsnaam]" - een nieuwe `renderLatestEqInfo()`-functie zoekt de meest recente
beving uit de VOLLEDIGE dataset (1911-heden, los van de tijdslider-animatie, dezelfde regel als
bij de straal-statistieken en impactindicatie), en toont die direct na het laden. Geeft in één
oogopslag een indicatie van hoe actueel de live KNMI-data daadwerkelijk is. Live geverifieerd:
toonde bij het testen een beving van dezelfde dag (21-8-2026, M2.8 bij Zandeweer).

## v0.20.4 - logo in README

Het eigen beeldmerk (v0.20.2) ook buiten de app zelf zichtbaar gemaakt: nieuw standalone bestand
`docs/logo.svg` (zelfde ontwerp, met een witte achtergrond zodat het ook op GitHub's donkere
thema leesbaar blijft) en bovenaan `README.md` geplaatst. Bewust een apart bestand i.p.v. de
inline SVG's in `index.html`/`achtergrond.html` hergebruiken, om geen refactor-risico te nemen op
de al werkende app-pagina's. GitHub's "social preview image" (de link-voorvertoning bij delen)
kan hiermee niet automatisch worden ingesteld - dat vereist een losse rasterafbeelding via de
repository-instellingen in de GitHub-webinterface, iets wat niet via een bestandswijziging of de
GitHub CLI te automatiseren is.

## v0.20.3 - filter op monumentaard/functie

Nieuw paneel "Filter op type / functie" bij "Rijksmonumenten binnen straal": klikbare labels met
aantallen per monumentaard (bv. "Onroerend gebouwd (400)") en per oorspronkelijke functie (bv.
"Boerderij (56)", "Woonhuis (85)"), gesorteerd op aantal. Klikken filtert zowel de kaartmarkers
als de CSV-export tot alleen die categorie; nogmaals klikken (of "Wis") toont weer alles. Volledig
client-side (array-filter/group-by over `state.lastMonuments`, dat al in het geheugen staat zodra
er een epicentrum gekozen is) - geen nieuwe query of database nodig, ondanks de aanvankelijke
zorg dat dit wél nodig zou zijn. Functielijst begrensd tot de 12 grootste categorieën (met een
telling van de rest) om de zijbalk niet te laten volstromen bij een straal met veel verschillende
functies. Filter wordt automatisch gewist zodra een nieuw epicentrum wordt gekozen, en ook
automatisch opgeheven als de actieve categorie door een straal-wijziging niet meer voorkomt.
Labels zijn de officiële RCE-thesaurustermen (skos:prefLabel) en dus soms samengesteld (bv.
"Kasteel, buitenplaats") - bewust geaccepteerd, niet zelf op te splitsen zonder van de brondata
af te wijken. Live geverifieerd: klikken op "Archeologisch" toont exact 214 schop-markers (0
huisjes); "Woonhuis" toont 85 markers en een CSV-export met precies 85 rijen, allemaal
"Woonhuis"; filter reset correct bij een nieuw epicentrum.

## v0.20.2 - eigen beeldmerk i.p.v. KNMI/RCE-logo's

De KNMI- en RCE-logo's bovenaan de zijbalk (en op `docs/achtergrond.html`) vervangen door een
eigen, onafhankelijk beeldmerk: een huisje en een schop op een seismogram-achtige golflijn, in
een cirkelvormig kader, als inline SVG in de bestaande `--accent`-kleur (#2c3e50). Reden:
overheidslogo's tonen op een niet-gelieerde toepassing wekt een schijn van samenwerking of
goedkeuring - precies wat de disclaimer ontkracht - en CC0 op het beeldbestand dekt niet per se
het merkgebruik van het logo zelf. De tekstuele bronvermelding (KNMI/CEO-RCE-links in de footer)
blijft ongewijzigd staan, want dat is feitelijke attributie, geen suggestie van samenwerking.
Kleur bewust niet aangepast naar "Rijksblauw": de exacte officiële hex kon niet worden
geverifieerd (rijkshuisstijl.nl-pagina met logokleuren zit achter een inlog), en de bestaande
`--accent` draagt sowieso geen overheidsassociatie. Drie ontwerprichtingen overwogen (losse
seismogramlijn, epicentrumringen, een gespleten erfgoedschild); gekozen voor de seismogramlijn,
met een correctie nadat bleek dat het huisje in de eerste versie op de kop stond (coördinaten
verkeerd overgenomen bij het herschalen van de bestaande 16px-huisvorm).

## v0.20.1 - CSV-export

Nieuwe knop "Download CSV" bij "Rijksmonumenten binnen straal": exporteert de huidige
straal-resultaten (de aardbeving + alle getoonde rijksmonumenten, beide typen) als platte,
pipe-gescheiden (`|`) CSV - op verzoek geen komma, om escaping van komma's in tekstvelden
(naam, functie) te vermijden. De aardbevinggegevens (plaats, datum, magnitude, diepte, straal)
worden op elke monumentrij herhaald (gangbaar patroon voor een-op-veel-exports). Kolommen per
monument: nummer, naam, type, oorspronkelijke/huidige functie, afstand tot epicentrum,
impactindicatie, effectgebied, of het monument in het officiële versterkingsprogramma zit, link
naar het monumentenregister en de linked-data URI. Client-side gegenereerd (`Blob` + tijdelijke
downloadlink), geen server nodig. UTF-8 BOM toegevoegd zodat accenten correct tonen in Excel.
Live geverifieerd: 614 monumentrijen + 1 header voor Loppersum/25km, kolommen kloppen (incl.
"ja" voor nr. 26265 bij Versterkingsprogramma), bestandsnaam `rijksmonumenten_loppersum_25km.csv`.

## v0.20.0 - eerste officiële release

De volledige roadmap-checklist naar deze release is afgerond (zie v0.19.0 t/m v0.19.5 hieronder):
impactindicatie-hernoeming en schijnprecisie, ingebouwde uitleg, het faden van niet-geselecteerde
aardbevingen, cross-browser/mobiel testen (inclusief een gevonden en gefixte legenda-bug), en de
kleurenblindheid-check (inclusief een gefixt rood/groen-contrastprobleem).

**Bewust nog niet gedaan, uitgesteld tot de 2e release**: aanvullende validatie van de
impactindicatie (zie `documentation/DEVELOPMENT.md`, "Roadmap"), een onderzoekstaak die meer
tijd en inlezen vergt dan de rest van deze checklist.

**Aanvullend gefixt vóór het taggen** (gevonden bij hands-on gebruik van de rijksmonumentnummer-
zoekfunctie): de `monSearchLayer`-marker werd maar één keer getekend en daarna nooit meer
bijgewerkt of verwijderd, waardoor een opgezocht monument permanent grijs (verouderd) bleef staan
en soms dubbel verscheen naast de straal-marker van hetzelfde monument (net niet overlappend, want
andere brongeometrie: WKT-punt vs. polygooncentrum). Root cause bleek dubbel: (1) er was geen
enkel moment waarop de laag werd opgeruimd, en (2) `buildMonumentMarker()` kon de kleur sowieso
nooit bijwerken omdat het opgezochte monument-object altijd `distKm: null` had (geen
afstandsfilter in de nummer-query) - `impactScore()` gaf daardoor altijd `null` terug, ongeacht
welk epicentrum actief was. Opgelost met een nieuwe `renderMonSearchMarker()`, die: (a) de
afstand tot het actuele epicentrum alsnog berekent (`haversineKm`) zodat de kleur meebeweegt met
latere epicentrum-selecties, en (b) de marker overslaat zodra hetzelfde rijksmonumentnummer al in
de straal-resultaten zit (voorkomt de dubbele marker). Verder een "Wis"-knop toegevoegd om het
zoekresultaat (marker, statustekst, invoerveld) handmatig te legen, en een zichtbare
laad-spinner (i.p.v. alleen cursieve tekst) voor alle asynchrone acties (aardbevingen laden,
rijksmonumenten binnen straal, nummer-opzoeking) - met `prefers-reduced-motion`-uitzondering.
Alle drie live geverifieerd: de marker bleef zichtbaar en veranderde kleur na een nieuwe,
verre epicentrum-selectie (geen "vast grijs" meer), verdween correct zodra hetzelfde monument al
in de straal-resultaten zat (448 → 447, gelijk aan het aantal in de statustekst), en de "Wis"-knop
verwijderde de marker exact (448 → 447 na klikken, terwijl de straal-resultaten ongewijzigd
bleven).

**Nog een bug gevonden en gefixt** (eveneens bij hands-on gebruik): de aardbevingen-popup
verscheen niet meer na een klik. Root cause: `selectEpicenter()` riep sinds de fade-feature
(v0.19.2) bij elke klik `renderEarthquakeMarkers()` aan, wat `eqLayer.clearLayers()` deed en dus
ELKE marker (inclusief de zojuist door Leaflet's eigen click-to-open-popup geopende) meteen
vernietigde en verving door een nieuwe, ongeopende instantie. Opgelost door de fade-toepassing te
ontkoppelen van het opnieuw opbouwen van de laag: een nieuwe `updateEarthquakeFade()` past
`setStyle()`/`bringToFront()` toe op de BESTAANDE marker-instanties (elke marker onthoudt zijn
eigen event via `marker.__ev`) i.p.v. ze te vernietigen en opnieuw te tekenen.
`renderEarthquakeMarkers()` (volledige heropbouw) blijft gebruikt bij initieel laden en
tijdslider-wijzigingen, waar de zichtbare verzameling bevingen echt verandert. Live geverifieerd:
twee opeenvolgende klikken op verschillende bevingen tonen allebei correct hun eigen popup, en de
faded/niet-faded verdeling (3.749 / 1) blijft kloppen.

Tot slot een korte disclaimer toegevoegd aan de footer van zowel `docs/index.html` als
`docs/achtergrond.html`: "Onafhankelijk initiatief. Niet ontwikkeld in opdracht van KNMI of RCE.
Aan deze kaart en de bijbehorende teksten kunnen geen rechten of plichten worden ontleend." -
zodat ook bezoekers van de live pagina's (niet alleen lezers van de README) deze zien.

## v0.19.5 - mobiele legenda-bug + kleurenblindheid-fix

Twee van de laatste drie punten op de roadmap naar v0.20.0 afgerond. **Mobiele bug** (gevonden
tijdens cross-browser/mobiel testen door gebruikers: "de legenda sluit niet meer"): de
uitgeklapte legenda kon hoger worden dan de kaartpane zelf, waardoor Leaflet's bottom-anchored
control omhoog groeide voorbij de bovenkant van `#map` (`overflow:hidden`) en de "Legenda"-knop
buiten het klikbare kaartgebied belandde - een tik daar raakte in plaats daarvan een
zijbalk-paneel eronder. Root cause bevestigd via `elementFromPoint()`. Fix: begrensde hoogte met
scroll (`max-height: 35dvh; overflow-y: auto`) in de mobiele media query, alleen op mobiel.
**Kleurenblindheid-check**: gesimuleerd met de Machado et al. (2009)-matrices (zelfde als Chrome's
"Emulate vision deficiencies"). Rood en het oorspronkelijke groen bleken bij deuteranopie (de
meest voorkomende vorm) vrijwel identiek. Groen vervangen door Okabe & Ito's kleurenblind-veilige
"bluish green" (#009E73) - blijft voor gewoon zicht duidelijk groen, lost het probleem op.
Cross-browser testen (Chrome/Firefox/Safari) door verschillende gebruikers: geen problemen gevonden. Daarmee
is de volledige roadmap-checklist naar v0.20.0 afgerond, op de bewust uitgestelde validatie van de
impactindicatie na (die schuift door naar het onderzoekstraject voor de 2e officiële release).

## v0.19.4 - handmatige testchecklist

Nieuw: `documentation/TESTS.md`, een handmatige testchecklist (13 secties, van KNMI-laadgedrag
tot responsiviteit) met concrete, al geverifieerde voorbeeldwaarden (plaatsnamen, monumentnummers)
om na een wijziging snel te kunnen controleren of alles nog werkt. Geen testframework - dit
project heeft geen build-stap en leunt op live externe data, dus geautomatiseerde tests zouden
vooral de live bronnen zelf testen, niet de eigen code. README verwijst er nu naar vanuit
"Lokaal draaien".

## v0.19.3 - zoeken op rijksmonumentnummer

Nieuw paneel "Zoek op rijksmonumentnummer": toont de locatie van het opgezochte monument (marker
in een eigen kaartlaag, blijft staan ongeacht latere straal-wijzigingen) en de dichtstbijzijnde
aardbeving uit de volledige dataset, met een knop om die beving als epicentrum te selecteren -
een omgekeerde ingang naast de bestaande "kies een beving, zie de monumenten eromheen"-flow.
Marker/popup hergebruiken dezelfde huisje/schop/kleur/ring-logica als de straal-resultaten (nu
achter een gedeelde `buildMonumentMarker()`-functie). Invoer wordt strikt gevalideerd (alleen
cijfers) vóór die in de SPARQL-query komt. Tijdens het testen een bug gevonden en gefixt: de
query bond `?nr` niet aan de gefilterde waarde, waardoor elk resultaat crashte op een ontbrekend
veld - opgelost met een expliciete `BIND`.

## v0.19.2 - niet-geselecteerde aardbevingen faden

Bij een actieve selectie faden alle overige aardbevingen (fillOpacity 0,15/opacity 0,25) terwijl
de geselecteerde beving vol zichtbaar blijft en bovenop de cluster getekend wordt - lost het
"te veel clusters"-probleem op in dichtbevolkte gebieden zoals Groningen en Limburg, zonder de
eerder afgewezen aparte marker/kruisje op de selectie zelf. Selectie wordt nu getrackt via een
object-referentie (`state.selected.sourceEvent`), niet via coördinaten, zodat bevingen met
identieke lat/lon niet per ongeluk worden verward.

## v0.19.1 - ingebouwde uitleg + versterkingsprogramma-badge

Naar aanleiding van de roadmap-review twee punten daadwerkelijk gebouwd (i.p.v. alleen gepland):
een knop "Hoe werkt deze kaart?" naast de titel opent een uitklapblok met de drie gebruiksstappen;
diezelfde tekst dient nu ook als lege-starttoestand van het "Geselecteerd epicentrum"-paneel; en
een info-icoon (ⓘ) staat bij "Impactindicatie" in zowel de legenda als de popup. Daarnaast een
paarse stippelring toegevoegd rond rijksmonumenten die voorkomen op de aangeleverde lijst van 140
nummers uit het officiële RCE-versterkingsprogramma (optie "puur informatief", geen filter) - een
extra popup-regel maakt dit ook expliciet. Versionering: snapshot-bestanden bijgewerkt naar
`_v0.19.1`.

## v0.19.0 - documentatie opgeschoond, KNMI-betrouwbaarheidsfix, achtergrondpagina aangevuld

README fors ingekort en gesplitst naar `documentation/DATA.md`, `IMPACTSCORE.md` en
`DEVELOPMENT.md`; verspreide versie-claims samengevoegd tot één regel; changelog-heading en de
"alles is live"-formulering gecorrigeerd; impactscore-terminologie in de UI aangescherpt naar
indicatief/verkennend; dit changelog zelf teruggebracht tot één hoofdpunt per versie (was
uitgebreide technische verantwoording, die nu in `documentation/` staat). Daarnaast een echte bug
gefixt: het KNMI induced-events-endpoint bleek een trage koude-cache-start (~15,5s) te hebben die
op sommige apparaten het toenmalige 20s-timeout overschreed, waardoor die categorie soms pas na
een handmatige refresh verscheen - opgelost met een ruimere timeout en een automatische
herkansing. Verder `docs/achtergrond.html` aangevuld met informatie uit 11 aanvullende
RCE-bronnen: historische kerkversterkingen, boerderijenvisies en -subsidies, karakteristieke
(niet-monumentale) panden, het industrieel erfgoed van de gaswinning zelf, het archeologische
onderzoeksprotocol bij funderingsherstel (nieuwe sectie, expliciet gekoppeld aan het schop-icoon
op de kaart), bredere bodembewegingsmechanismen naast trilling, en de daadwerkelijke
RCE-monitoringspraktijk (nieuwe sectie, als contrast met de indicatieve impactscore). Naar
aanleiding van een review "impactscore" hernoemd naar "impactindicatie" door de hele interface en
documentatie, en de popup toont nu 1 decimaal i.p.v. 2 om geen schijnprecisie te suggereren.
Tot slot de versienummerde snapshot-bestanden rechtgezet: het achterhaalde, ongenummerde
`aardbevingen_en_rijksmonumenten.html` (inhoud nog op v0.16.0) vervangen door een bijgewerkt,
zelfstandig gelinkt paar - `aardbevingen_en_rijksmonumenten_v0.19.0.html` en
`..._achtergrond_v0.19.0.html`.

## v0.18.0 - achtergrondpagina

Nieuwe statische pagina `docs/achtergrond.html` met uitleg over waarom aardbevingen en
rijksmonumenten samenhangen, het RCE-werkproces, en een sectie over niet-Groningse gevallen
(Roermond, Limburgse mijnbouwschade) - eigen samenvatting met bronvermelding.

## v0.17.0 - automatisch in-/uitzoomen op de straal

De kaart zoomt zichzelf nu in/uit op de gekozen straal-cirkel, zowel bij epicentrum-selectie als
bij het verslepen van de straal-slider.

## v0.16.0 - dubbele tijdslider + bronlogo's

Twee-handvat tijdslider voor een specifiek jarenvenster; RCE/KNMI-logo's als bronvermelding; plus
een reeks toegankelijkheids- en robuustheidsverbeteringen (mobiele weergave, timeouts,
gedeeltelijke resultaten bij een falende bron, statusmeldingen, toetsenbordbediening).

## v0.15.0 - eerste publieke release

Documentatie en teksten klaargemaakt voor openbaar gebruik; verouderde verwijzingen naar de oude
RCE-aardbevingsdataset verwijderd.

## v0.14 - functienamen ontdaan van codeachtervoegsel

CEO-functienamen tonen voortaan zonder het interne "(code)"-achtervoegsel.

## v0.13 - aardbevingen rechtstreeks bij het KNMI

Aardbevingen komen niet langer via RCE, maar rechtstreeks van het KNMI (dekking 1911-heden i.p.v.
het beperktere bereik van RCE's eigen import).

## v0.12 - tijd-animatie + legenda naar kaart-overlay

Tijd-animatie met jaar-slider en afspeelknop toegevoegd; legenda verplaatst van de zijbalk naar
een inklapbare kaart-overlay.

## v0.11 - iconen naar type: huisje vs. schop

Rijksmonument-markers krijgen een vorm naar monumentaard (huisje/schop), onafhankelijk van de
impactscore-kleur.

## v0.10 - monument-markers onzichtbaar bij uitgezoomde weergave

Bugfix: monumenten werden getekend met een vaste-graden-grootte rechthoek die bij uitzoomen
onzichtbaar werd; vervangen door een icoon met vaste pixelgrootte.

## v0.9 - archeologische monumenten (scheepswrakken) waren onvindbaar

Bugfix: een gedeelde resultaatlimiet verdrong de archeologische categorie structureel; opgelost
met aparte queries per monumentaard.

## v0.8 - kleurenschema herzien

Rijksmonument-impactkleuren omgezet naar rood/oranje/groen; aardbevingen naar een aparte,
niet-overlappende kleurenschaal.

## v0.7 - impactscore herijkt op echte IMG-data

Impactscore-coëfficiënten vervangen door een regressie op drie echte, gepubliceerde
IMG-effectgebieden; waarschuwing toegevoegd voor diepe bevingen.

## v0.6 - impactscore (eerste versie) + zoek-op-plaats

Eerste, nog niet gekalibreerde impactscore toegevoegd, plus een zoekveld op plaatsnaam.

## v0.5 - oorspronkelijke en huidige functie los getoond

Oorspronkelijke en huidige functie apart getoond in plaats van samengevoegd.

## v0.4 - alleen geldige rijksmonumenten + monumentaard

Query filtert voortaan op juridische status "rijksmonument"; monumentaard toegevoegd aan de
popup.

## v0.3 - uitgebreide popups

Aardbevingen- en rijksmonumenten-popups uitgebreid met meer velden.

## v0.2 - aardbevingen live in plaats van snapshot

Aardbevingen niet langer als ingebakken snapshot, maar live via SPARQL opgehaald.

## v0.1 - herbouw van een eerdere, verloren versie

Basisopzet herbouwd: Leaflet + CARTO-kaart, straal-slider, live rijksmonumenten-query.
