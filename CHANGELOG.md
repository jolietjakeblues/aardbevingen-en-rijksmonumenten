Changelog# Changelog

Alle wijzigingen zijn ontwikkeld in één sessie (juli 2026), als opeenvolgende iteraties op een
eerdere, verloren gegane versie die aardbevingen nog als ingebakken snapshot toonde.

## v0.16.0 - dubbele tijdslider + bronlogo's

### Toegevoegd

- Twee-handvat tijdslider: een specifiek jarenvenster kiezen (bv. 1986–2011) i.p.v. alleen een
  cumulatief "tot en met"-jaar. Gebouwd met twee overlappende, transparante `<input type=range>`-
  elementen (alleen de thumb is klikbaar) plus een losse fill-balk voor het visuele effect, met
  klem-logica zodat de handvatten elkaar niet kunnen passeren.
- Logo's van RCE (SVG) en KNMI (PNG) bovenaan de zijbalk als bronvermelding, doorklikbaar naar de
  officiële sites. Beide gehost op Wikimedia Commons onder CC0, rechtstreeks door de betreffende
  overheidsdiensten gepubliceerd — geverifieerd via de licentiepagina's voordat ze zijn ingebed.

### Gewijzigd

- Afspeelknop aangepast aan het nieuwe model: houdt het gekozen startjaar (linkerhandvat) vast en
  schuift alleen het eindjaar (rechterhandvat) op tot het laatste beschikbare jaar.
- `resetTimeFilter()` en de plaatszoeker zetten nu beide handvatten terug (i.p.v. één jaarwaarde).
- `initPlaceSearch()` verbeterd door de gebruiker: zoekresultaat wordt nu via een expliciete
  `newestEvent()`-sortering op datum bepaald in plaats van te vertrouwen op de volgorde waarin de
  KNMI-CSV's binnenkomen (die garantie verviel toen induced- en tectonic-events werden
  samengevoegd na de overstap naar rechtstreekse KNMI-data in v0.13).
- `parseKnmiCsv()` gebruikt nu `Number.isFinite` voor depth/mag i.p.v. losse `isNaN`-checks.

Getest: venster 1986–2011 geeft 1.833 van de 3.750 bevingen met een correct gepositioneerde
fill-balk (65,2% / 21,7%, exact overeenkomend met de jaarverhouding); handvatten kunnen elkaar
niet passeren; reset en plaatszoeker zetten het venster correct terug naar "alles".

### Toegevoegd (aanvulling)

Onderstaande punten zijn later in dezelfde v0.16.0-cyclus toegevoegd, in
`aardbevingen_en_rijksmonumenten_v0.16.0.html` (nu ook `docs/index.html`, de canonieke versie):

- **Mobiele weergave**: `@media (max-width: 700px)`-breakpoint stapelt de zijbalk (max 45%
  hoogte) boven de kaart (55%) i.p.v. ernaast. Geverifieerd op 375px breed: geen horizontale
  overflow meer (voorheen een bekende beperking).
- **Timeouts voor KNMI- en RCE-verzoeken**: `fetchWithTimeout()` met `AbortController`,
  20 seconden, gebruikt door zowel `sparqlSelect` als `fetchKnmiCsv`.
- **Gedeeltelijke resultaten bij een falende databron**: `loadEarthquakes()` en
  `fetchMonuments()` gebruiken nu `Promise.allSettled` i.p.v. `Promise.all` — als bijvoorbeeld
  alleen de tektonische KNMI-categorie faalt, blijft de geïnduceerde categorie gewoon zichtbaar
  (en andersom), met een statusmelding welk deel ontbreekt. Alleen als écht alles mislukt, toont
  de pagina een foutmelding.
- **Statusmeldingen voor laadfouten en ontbrekende zoekresultaten**: nieuw `#placeStatus`-element
  toont "Geen aardbeving gevonden bij deze plaatsnaam." bij een lege zoekopdracht; foutmeldingen
  krijgen `role="alert"`.
- **Toegankelijkheidslabels en live-statusmeldingen**: verborgen (`visually-hidden`) `<label>`s
  bij zoekveld, straal-slider en beide tijd-sliderhandvatten; `aria-live="polite"` op
  `#eqStats`/`#monStatus`/`#placeStatus`; `aria-valuetext` op de straal-slider.
- **Toetsenbordbediening voor de legenda**: de legenda-header is omgezet van een klikbare `<div>`
  naar een echte `<button type="button">` met `aria-expanded`, dus native focusbaar en met
  Enter/spatie te bedienen — geen custom keydown-handler nodig.
- Melding bij de 400-limiet van gebouwde monumenten verduidelijkt: "minstens 400 ... alleen de
  400 dichtstbijzijnde getoond" i.p.v. de kortere "limiet bereikt"-tekst.

Geverifieerd: alle zes punten empirisch gecontroleerd (aanwezigheid van `@media`,
`AbortController`, `Promise.allSettled`, `aria-live`, `visually-hidden`, `<button>` i.p.v. `<div>`
voor de legenda) en functioneel getest — mobiele layout zonder overflow (375px), tablet
ongewijzigd bruikbaar (768px), legenda-knop focusbaar en toggelt via `.click()`,
"niet gevonden"-statusmelding verschijnt bij een onbestaande plaatsnaam.

## v0.15.0 - eerste publieke release

Deze versie markeert de eerste publiek gedeelde versie van de interactieve kaart.

### Toegevoegd

- Documentatie voorbereid voor openbaar gebruik.
- Duidelijke toelichting op de live databronnen en externe afhankelijkheden.
- Expliciete waarschuwing dat de impactscore geen schade- of risicomodel is.

### Gewijzigd

- Verouderde verwijzingen naar de voormalige RCE-aardbevingsdataset verwijderd.
- Documentatie gelijkgetrokken met de rechtstreekse KNMI-koppeling.
- Beschrijving van categorieën, kleurgebruik en databronnen gecorrigeerd.
- Formuleringen en typfouten in README en changelog verbeterd.

### Bekende beperkingen

- De mobiele weergave is nog niet geschikt voor kleine schermen.
- De query voor gebouwde rijksmonumenten toont maximaal 400 resultaten.
- De werking is afhankelijk van de beschikbaarheid van KNMI, RCE, CARTO en
  unpkg.
- De impactscore is alleen bedoeld als verkennende visualisatie.

## v0.14 - functienamen ontdaan van codeachtervoegsel
- CEO-functienamen zoals "Boerderij (M1)" of "Gemaal(M3)" tonen nu zonder het interne
  codeachtervoegsel tussen haakjes ("Boerderij", "Gemaal") -- puur cosmetisch bij weergave via
  een regex (`stripParenSuffix`), de ruwe data blijft ongewijzigd. Werkt op zowel "naam (code)"
  als "naam(code)" (inconsistente spatiëring in de brondata).

## v0.13 - aardbevingen rechtstreeks bij het KNMI
- Aardbevingen komen niet langer via RCE's SPARQL-endpoint, maar rechtstreeks van het KNMI
  (`rdsa.knmi.nl/abcws/event/query`, CSV, induced + tectonic apart bevraagd). Gevonden via de
  `prov:wasDerivedFrom`-triples op RCE's eigen aardbevingen-graph, die naar exact deze twee
  KNMI-endpoints wijzen -- RCE's dataset bleek zelf een periodieke import hiervan.
- Dekking uitgebreid: 1911-heden (was beperkt tot wat RCE had geïmporteerd). CORS bevestigd open
  (reflecteert elke Origin). Payload kleiner dan de oude SPARQL-aanpak (~230KB vs. ~2,6MB).
- CSV-parser afgestemd op een echte edge case in de brondata: minstens één locatienaam bevat zelf
  een ongequote komma ("Oost-, West- en Middelbeers"), wat een naieve split-op-komma zou breken.
  Opgelost door de eerste 2 en laatste 5 velden als vast te behandelen en alles ertussen als
  locatienaam samen te voegen.
- Categorie "steengroeve explosie" vervallen: het KNMI kent alleen "induced" en "tectonic", RCE
  had kennelijk een verfijning die niet in deze brondata terugkomt. Legenda en kleurenschaal
  hierop aangepast (2 categorieën i.p.v. 4).
- Andere KNMI-bronnen afgewogen en verworpen: `dataplatform.knmi.nl/aardbevingen_nederland`
  (laatste 100 events, NetCDF) en `aardbevingen_cijfers` (aggregaat-tellingen, geen coördinaten).
- Rijksmonumenten blijven ongewijzigd via RCE lopen (andere databron, ander doel).

## v0.12 - tijd-animatie + legenda naar kaart-overlay
- Tijd-animatie toegevoegd: balk onder de kaart met jaar-slider (bereik automatisch op basis van
  de geladen data, 1911-heden) en afspeelknop. Toont aardbevingen cumulatief tot en met het
  gekozen jaar. Beïnvloedt alleen `renderEarthquakeMarkers`; straal-statistieken en impactscore
  blijven altijd op de volledige dataset gebaseerd (bewuste scheiding: animatie is presentatie,
  geen filter op de analyse).
- Plaatsnaam zoeken zet de animatie terug naar "toon alles" voordat er genavigeerd wordt, zodat
  een gezocht resultaat nooit onzichtbaar kan zijn door een actieve tijdfilter.
- Legenda verplaatst van een vast paneel in de zijbalk naar een inklapbare Leaflet-control
  linksonder op de kaart zelf (standaard ingeklapt). Zijbalk was met 6 panelen (zoek op plaats,
  straal, epicentrum, aardbeving-stats, monument-stats, legenda + footer) te vol geworden; dit
  scheelt het meeste omdat de legenda inmiddels 9 regels + hint-tekst besloeg. Maakt ook meteen
  ruimte voor de nieuwe tijdbalk zonder dat de zijbalk nog voller wordt.
- Layout omgezet naar geneste flexbox (`#mapPane` met `#map` + `#timebar` in kolom) om de
  tijdbalk onder de kaart te passen zonder de bestaande sidebar/map-verhouding te breken.

## v0.11 - iconen naar type: huisje vs. schop
- Rijksmonument-markers tonen nu een vorm naar `monumentaard`: huisje voor "onroerend gebouwd",
  schop voor "archeologisch" (o.a. scheepswrakken). Kleur (rood/oranje/groen) blijft de
  effectgebied-score aangeven -- vorm en kleur zijn onafhankelijke dimensies.
- Type wordt direct meegegeven vanuit de query-batch (gebouwd/archeologisch zijn al aparte
  queries sinds v0.9) in plaats van achteraf op de `aardLabel`-tekst te matchen.
- Legenda-iconen hergebruiken dezelfde SVG-functies als de kaart, zodat ze nooit kunnen
  afwijken van wat er daadwerkelijk getekend wordt.

## v0.10 - monument-markers onzichtbaar bij uitgezoomde weergave
- Tweede, onafhankelijke bug rond hetzelfde scheepswrak gevonden: nadat v0.9 het wrak wél in de
  resultaten kreeg (bij straal ≥57 km), bleef de marker onzichtbaar op de kaart zelf.
- Oorzaak: monumenten werden getekend met `L.rectangle` op een vaste breedte in graden (~90 m).
  Bij een breed uitgezoomde weergave (straal 60 km in beeld) krimpt dat tot onder de 1 pixel —
  bevestigd met 265 monument-elementen die een lege bounding box hadden. De aardbeving-markers
  hadden dit probleem niet, want die gebruiken `L.circleMarker` met een vaste pixel-straal.
- Fix: monumenten getekend als `L.marker` met een `divIcon` van vaste pixelgrootte (10×10px) —
  zoom-onafhankelijk, net als de aardbevingen. Geverifieerd: het scheepswrak (nr. 532450) is nu
  zichtbaar op 60 km straal.

## v0.9 - archeologische monumenten (scheepswrakken) waren onvindbaar
- Bug gevonden en gefixt: rijksmonumenten werden opgehaald met één query, `ORDER BY afstand
  LIMIT 400`. In monument-dichte gebieden verdrong "onroerend gebouwd" de veel schaarsere
  categorie "archeologisch" (o.a. scheepswrakken) volledig uit die top-400 — bevestigd voor
  "Scheepswrak aanloop Molengat" (nr. 532450, bij Den Helder): 792 gebouwde monumenten lagen
  dichter bij het dichtstbijzijnde epicentrum (Anna Paulowna) dan dit wrak, dat daardoor nooit
  verscheen, ongeacht de gekozen straal.
- Fix: twee aparte queries, één per monumentaard. "Onroerend gebouwd" behoudt de limiet van 400
  (praktisch nodig, te dicht bevolkt). "Archeologisch" krijgt een limiet van 3.000 (landelijk
  maar ~1.500 objecten, dus in de praktijk ongelimiteerd). Resultaten worden samengevoegd; de
  statusregel toont nu beide aantallen apart.

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
- Basisopzet met Leaflet + CARTO-kaart, sidebar met straal-slider, live rijksmonumenten-query
  met `geof:distance`, herbouwd op basis van een bewaard gebleven project-samenvatting nadat het
  originele HTML-bestand niet meer op schijf stond.
