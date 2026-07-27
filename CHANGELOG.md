Changelog# Changelog

Alle wijzigingen zijn ontwikkeld in één sessie (juli 2026), als opeenvolgende iteraties op een
eerdere, verloren gegane versie die aardbevingen nog als ingebakken snapshot toonde.

## v0.8 - kleurenschema herzien
- Rijksmonument-impactkleuren omgezet naar een stoplicht: rood (ruim binnen effectgebied),
  oranje (net binnen effectgebied), groen (buiten effectgebied) — voorheen groen/grijs, wat
  contra-intuïtief was (groen = "matig" i.p.v. "veilig") en op zee/water nauwelijks zichtbaar.
- Aardbevingen-categorieën omgezet naar een aparte kleurenschaal zonder overlap met de
  monument-kleuren: geel (geïnduceerd, was rood), blauw (tektonisch, ongewijzigd), zwart
  (steengroeve-explosie, was grijs), bruin (overig/onbekend, was grijs).
- Alle markers (aardbevingen én rijksmonumenten) krijgen nu een vaste donkere rand, los van de
  vulkleur, voor contrast op elke ondergrond.

## v0.7 - impactscore herijkt op echte IMG-data
- Impactscore-coëfficiënten vervangen: niet langer een educated guess, maar een lineaire
  regressie op drie gepubliceerde IMG-effectgebieden (Wirdum M3.1→17,5km, Huizinge M3.6→35+km,
  generiek IMG-voorbeeld M2.7→9,5km).
- Kleurcategorieën en popup-tekst hernoemd naar "binnen/buiten effectgebied" (voorheen vage
  "impact"-taal) om aan te sluiten bij de officiële IMG-terminologie.
- Waarschuwing toegevoegd voor diepe (>5 km) bevingen: kalibratie is aantoonbaar minder
  betrouwbaar buiten het ondiepe Groningen-regime (getest tegen Roermond 1992).
- Responsiveness getest op tablet (768px, bruikbaar) en mobiel (375px, niet bruikbaar) —
  vastgelegd als bekende beperking, bewust nog niet gefixt.

## v0.6 - impactscore (eerste versie) + zoek-op-plaats
- Impactscore toegevoegd: `magnitude − 2.5·log₁₀(Rh) − 0.001·Rh` (Rh = hypocentrale afstand),
  met kleurcodering (rood/groen/grijs) op de rijksmonument-markers.
- Zoekveld op plaatsnaam toegevoegd (autocomplete uit de toponiemen in de aardbevingsdata zelf,
  geen externe geocoding nodig).

## v0.5 - oorspronkelijke en huidige functie los getoond
- `heeftHuidigeFunctie` (~8% gevuld) toont nu niet langer alleen als fallback: oorspronkelijke
  functie (~100% gevuld) is de primaire regel, huidige functie wordt er apart naast getoond
  wanneer bekend - in plaats van een `COALESCE` die het onderscheid verborg.

## v0.4 - alleen geldige rijksmonumenten + monumentaard
- Rijksmonumenten-query filtert nu verplicht op juridische status = "rijksmonument" (niet
  "voorbeschermd" of "geen rijksmonument"), binnen graph `instanties-rce` om dubbeltellingen te
  vermijden.
- Monumentaard (archeologisch / onroerend gebouwd) toegevoegd aan de popup.

## v0.3 - uitgebreide popups
- Aardbevingen-popup uitgebreid: toponiem (via `schema:location` → Wikidata-naam), datum/tijd,
  magnitude, diepte, categorie.
- Rijksmonumenten-popup uitgebreid: naam, functie (met `COALESCE`-fallback op dat moment), link
  naar monumentenregister én de linked-data URI.

## v0.2 - aardbevingen live in plaats van snapshot
- Aardbevingen niet langer als ingebakken JSON-snapshot, maar live opgehaald via SPARQL bij het
  laden van de pagina (zelfde live-aanpak als de rijksmonumenten al hadden).
- Query's omgezet naar `GROUP BY`/`SAMPLE`-aggregaties om dubbele rijen door meertalige of
  meervoudige triples te voorkomen.

## v0.1 - herbouw van een eerdere, verloren versie
- Basisopzet met Leaflet + CARMO-kaart, sidebar met straal-slider, live rijksmonumenten-query
  met `geof:distance`, herbouwd op basis van een bewaard gebleven project-samenvatting nadat het
  originele HTML-bestand niet meer op schijf stond.
