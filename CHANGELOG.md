# Changelog

Alle wijzigingen zijn ontwikkeld in één sessie (juli 2026), als opeenvolgende iteraties op een
eerdere, verloren gegane versie die aardbevingen nog als ingebakken snapshot toonde. Achtergrond
en technische details per onderwerp: zie `documentation/`.

## v0.19.0 - documentatie opgeschoond, KNMI-betrouwbaarheidsfix, achtergrondpagina aangevuld

README fors ingekort en gesplitst naar `documentation/DATA.md`, `IMPACTSCORE.md` en
`DEVELOPMENT.md`; verspreide versie-claims samengevoegd tot één regel; changelog-heading en de
"alles is live"-formulering gecorrigeerd; impactscore-terminologie in de UI aangescherpt naar
indicatief/verkennend; dit changelog zelf teruggebracht tot één hoofdpunt per versie (was
uitgebreide technische verantwoording, die nu in `documentation/` staat). Daarnaast een echte bug
gefixt: het KNMI induced-events-endpoint bleek een trage koude-cache-start (~15,5s) te hebben die
op sommige apparaten het toenmalige 20s-timeout overschreed, waardoor die categorie soms pas na
een handmatige refresh verscheen - opgelost met een ruimere timeout en een automatische
herkansing. Tot slot `docs/achtergrond.html` aangevuld met informatie uit 11 aanvullende
RCE-bronnen: historische kerkversterkingen, boerderijenvisies en -subsidies, karakteristieke
(niet-monumentale) panden, het industrieel erfgoed van de gaswinning zelf, het archeologische
onderzoeksprotocol bij funderingsherstel (nieuwe sectie, expliciet gekoppeld aan het schop-icoon
op de kaart), bredere bodembewegingsmechanismen naast trilling, en de daadwerkelijke
RCE-monitoringspraktijk (nieuwe sectie, als contrast met de indicatieve impactscore).

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
