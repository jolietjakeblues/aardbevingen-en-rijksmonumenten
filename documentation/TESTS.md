# Handmatige testchecklist

Geen build-stap, geen testframework - dit is een checklist om na een wijziging handmatig (of via
de browser-tools) te controleren of alles nog werkt zoals bedoeld. Open `docs/index.html` lokaal
(zie README, "Lokaal draaien") en loop de secties langs. Concrete voorbeeldwaarden (plaatsnamen,
monumentnummers) zijn al eerder tegen de live data geverifieerd, maar de exacte aantallen kunnen
licht verschuiven als de brondata verandert.

## 1. Aardbevingen laden (KNMI)

| # | Stap | Verwacht resultaat |
|---|---|---|
| 1.1 | Pagina laden, wachten tot "Selecteer een epicentrum om statistieken te zien" verschijnt | Geen foutmelding; geen "Let op: niet geladen"-waarschuwing |
| 1.2 | Tel markers op de kaart (bv. via `document.querySelectorAll('path.leaflet-interactive').length`) | ~3.750 markers (induced + tectonic samen), geen van beide categorieën ontbreekt |
| 1.3 | Herhaal 1.1-1.2 een paar keer kort na elkaar (test de KNMI-cold-start-fix) | Beide categorieën laden consistent, ook als het de eerste request in een tijdje is (timeout 35s + automatische herkansing) |
| 1.4 | Controleer de regel onder de subtitel na het laden | "Laatst geregistreerde beving: [datum] · M[magnitude] bij [plaatsnaam]" - datum moet de meest recente in de dataset zijn, ongeacht een eventueel actief tijdslider-venster |

## 2. Rijksmonumenten binnen straal

| # | Stap | Verwacht resultaat |
|---|---|---|
| 2.1 | Zoek op plaats "Loppersum", straal 25 km | Epicentrum bij Loppersum; "Rijksmonumenten binnen straal" toont een getal met opsplitsing "X onroerend gebouwd; Y archeologisch" |
| 2.2 | Vergroot de straal naar 200 km in een dichte regio (bv. rond Amsterdam) | Tekst "minstens 400 onroerend gebouwd; alleen de 400 dichtstbijzijnde getoond" verschijnt |
| 2.3 | Zoek een archeologisch monument (bv. "Scheepswrak aanloop Molengat", nr. 532450, bij Den Helder) op straal ≥60 km vanaf een naburig epicentrum | Het scheepswrak verschijnt als schop-icoon, ook bij ver uitgezoomde weergave |

## 3. Impactindicatie

| # | Stap | Verwacht resultaat |
|---|---|---|
| 3.1 | Klik een monument-popup open na epicentrum-selectie | "Impactindicatie ⓘ: X.X (binnen/buiten indicatief effectgebied)" - **1 decimaal**, geen 2 |
| 3.2 | Hover/focus het ⓘ-icoon | Tooltip "Verkennende indicatie, geen schadebeoordeling." |
| 3.3 | Selecteer een diepe (>5 km) beving, bv. via een plaatsnaam die een tektonische beving oplevert | Popup toont extra waarschuwing "let op: diepe beving, kalibratie minder betrouwbaar op afstand" |
| 3.4 | Vergelijk kleur met score: score ≥ 1 rood, 0 ≤ score < 1 oranje, score < 0 groen | Kleuren kloppen met de legenda |

## 4. Iconen en versterkingsprogramma-ring

| # | Stap | Verwacht resultaat |
|---|---|---|
| 4.1 | Zoek op rijksmonumentnummer 26265 (Loppersum, Petrus en Pauluskerk) | Huisje-icoon met een paarse stippelring; popup toont "● In het officiële RCE-versterkingsprogramma" |
| 4.2 | Zoek een willekeurig gebouwd monument dat NIET in de lijst van 140 nummers zit | Huisje-icoon zonder ring, geen versterkingsprogramma-regel in de popup |
| 4.3 | Open de legenda | Toont apart: huisje (onroerend gebouwd), schop (archeologisch), paarse stippelring (versterkingsprogramma) |

## 5. Tijdslider

| # | Stap | Verwacht resultaat |
|---|---|---|
| 5.1 | Sleep het linker- en rechterhandvat naar bv. 1986-2011 | `#timeYearLabel` toont "1986–2011"; alleen bevingen in dat venster zichtbaar op de kaart |
| 5.2 | Klik "Afspelen" | Rechterhandvat schuift op, linkerhandvat blijft vast, animatie stopt bij het laatste jaar |
| 5.3 | Klik "toon alles" | Beide handvatten terug naar de volledige range, alle bevingen weer zichtbaar |
| 5.4 | Zoek op plaats terwijl er een tijdvenster actief is | Tijdvenster wordt automatisch teruggezet naar "alles" zodat het zoekresultaat zichtbaar is |
| 5.5 | Selecteer een epicentrum terwijl er een tijdvenster actief is | Straal-statistieken en impactindicatie blijven op de volledige dataset gebaseerd (niet beperkt door het tijdvenster) |

## 6. Faden van niet-geselecteerde aardbevingen

| # | Stap | Verwacht resultaat |
|---|---|---|
| 6.1 | Klik een aardbeving-marker in een dichte cluster (bv. rond Loppersum) | Alle overige markers krijgen een lage dekking (fillOpacity 0,15); de geklikte marker blijft vol zichtbaar (0,85) en ligt bovenop |
| 6.2 | Klik daarna een andere beving | De eerder geselecteerde vervaagt mee, de nieuwe wordt vol zichtbaar |
| 6.3 | Vóór elke selectie (verse pagina) | Alle markers op volle dekking, geen fade-effect |
| 6.4 | Klik een aardbeving-marker | De popup (toponiem, datum/tijd, magnitude, diepte, categorie) opent en blijft staan (regressietest: eerder verdween de popup meteen weer omdat de klik-handler de hele laag opnieuw opbouwde) |
| 6.5 | Klik daarna een andere beving | De popup van de nieuw geklikte beving opent; fade-verdeling blijft kloppen |

## 7. Zoek op plaats

| # | Stap | Verwacht resultaat |
|---|---|---|
| 7.1 | Typ "Loppersum" en druk Enter (of verlaat het veld) | Springt naar de meest recente beving met dat toponiem; kaart zoomt naar niveau 12 |
| 7.2 | Typ een niet-bestaande plaatsnaam | "Geen aardbeving gevonden bij deze plaatsnaam." |
| 7.3 | Typ een gedeeltelijke naam | Valt terug op een prefix-match als er geen exacte match is |

## 8. Zoek op rijksmonumentnummer

| # | Stap | Verwacht resultaat |
|---|---|---|
| 8.1 | Voer "26265" in, klik Zoek | Kaart pant/zoomt naar Loppersum (Petrus en Pauluskerk), popup opent automatisch; resultaattekst toont dichtstbijzijnde beving "27-10-2007 · M2.0 · 0.1 km" (of actuelere data als de dataset ondertussen is bijgewerkt) |
| 8.2 | Klik "Selecteer deze aardbeving als epicentrum" | Epicentrum wordt Loppersum M2.0; straal-statistieken en monumentenlijst verschijnen zoals bij een normale klik-selectie |
| 8.3 | Voer "abc123" in | "Vul een rijksmonumentnummer in van alleen cijfers." - geen query wordt uitgevoerd |
| 8.4 | Voer een niet-bestaand nummer in, bv. "999999999" | "Geen geldig rijksmonument gevonden met nummer 999999999 (...)" |
| 8.5 | Wijzig daarna de straal-slider (met een epicentrum al actief) | De opgezochte monument-marker blijft staan (eigen laag, wordt niet gewist door `renderMonuments()`) |
| 8.6 | Zoek "26265" zonder dat er een epicentrum actief is (grijze marker), selecteer daarna een epicentrum ver weg (buiten bereik van dat monument) | De marker verdwijnt niet en wordt niet meer grijs - kleur wordt opnieuw berekend tov het nieuwe epicentrum (regressietest voor de "blijft grijs"-bug) |
| 8.7 | Zoek "26265", selecteer daarna (via plaatsnaam of klik) een epicentrum waarvan de straal dit monument wél bevat | Het monument verschijnt maar ÉÉN keer op de kaart (totaal aantal iconen = het aantal in "Rijksmonumenten binnen straal"), geen dubbele/verschoven marker |
| 8.8 | Klik "Wis" na een zoekopdracht | Invoerveld, resultaattekst en marker worden allemaal geleegd; als de marker een "extra" marker was (niet gededupliceerd), daalt het totaal aantal iconen met precies 1 |

## 9. Automatisch in-/uitzoomen

| # | Stap | Verwacht resultaat |
|---|---|---|
| 9.1 | Selecteer een epicentrum | Kaart zoomt automatisch naar de straal-cirkel (`fitBounds`) |
| 9.2 | Verander de straal-slider | Kaart past de zoom opnieuw aan; bij een straal van 1-2 km blijft de zoom begrensd op maxZoom 16 (niet absurd ver ingezoomd) |

## 10. Hulp / uitleg

| # | Stap | Verwacht resultaat |
|---|---|---|
| 10.1 | Verse pagina, nog geen epicentrum gekozen | "Geselecteerd epicentrum"-paneel toont de 3 gebruiksstappen i.p.v. een lege placeholder |
| 10.2 | Klik "Hoe werkt deze kaart?" | Uitklapblok met dezelfde 3 stappen opent; `aria-expanded` gaat naar `true` |
| 10.3 | Klik nogmaals | Uitklapblok sluit weer |

## 11. Achtergrondpagina

| # | Stap | Verwacht resultaat |
|---|---|---|
| 11.1 | Klik de footer-link "Achtergrond: waarom aardbevingen en rijksmonumenten?" | `docs/achtergrond.html` opent, geen console-errors |
| 11.2 | Klik "← Terug naar de kaart" | Terug naar `docs/index.html` |
| 11.3 | Controleer alle links onder "Meer lezen (RCE-bronnen)" | Elke link geeft HTTP 200 (steekproefsgewijs met curl of de browserconsole) |

## 12. Responsief / mobiel

| # | Stap | Verwacht resultaat |
|---|---|---|
| 12.1 | Resize naar 375px breed | Zijbalk stapelt boven de kaart (max 45dvh), geen horizontale overflow (`document.body.scrollWidth === window.innerWidth`) |
| 12.2 | Resize naar 768px breed | Zijbalk en kaart naast elkaar, beide bruikbaar, geen overflow |
| 12.3 | Selecteer op 375px breed een epicentrum, open de legenda | Legenda past binnen de kaartpane (`.legend-control-body` heeft `max-height: 35dvh` + scroll); de "Legenda"-knop blijft altijd binnen het klikbare kaartgebied en is opnieuw te sluiten (regressietest voor de v0.19.5-bug: de knop kon boven de kaartpane uitgroeien en werd dan onklikbaar) |
| 12.4 | Test in Chrome, Firefox en Safari | Alles werkt (bevestigd door de gebruiker, v0.19.5) |
| 12.5 | Test op een echt mobiel toestel | Nog niet expliciet gedaan buiten de resize-tool |

## 13. Kleurenblindheid

| # | Stap | Verwacht resultaat |
|---|---|---|
| 13.1 | Simuleer deuteranopie/protanopie/tritanopie (bv. via Chrome devtools "Emulate vision deficiencies", of een online simulator) op de legenda-kleurvlakjes | Rood, oranje en het (sinds v0.19.5) aangepaste groen (#009E73) blijven van elkaar te onderscheiden - rood en groen liggen niet meer nagenoeg op elkaar zoals bij het oorspronkelijke groen (#2e7d32) het geval was bij deuteranopie |
| 13.2 | Controleer de legenda-kleurvlakjes-hex via devtools | Groen-vlakje toont `rgb(0, 158, 115)` (#009E73), niet meer `rgb(46, 125, 50)` |

## 14. Download CSV

| # | Stap | Verwacht resultaat |
|---|---|---|
| 14.1 | Klik "Download CSV" zonder dat er een epicentrum geselecteerd is | Statustekst: "Nog geen rijksmonumenten om te downloaden - selecteer eerst een epicentrum." Geen download. |
| 14.2 | Selecteer een epicentrum (bv. Loppersum, 25 km), klik "Download CSV" | Bestand `rijksmonumenten_<plaats>_<straal>km.csv` wordt gedownload; regelaantal = 1 header + N monumentrijen (N gelijk aan het aantal in "Rijksmonumenten binnen straal") |
| 14.3 | Open het bestand in een spreadsheet-programma of teksteditor | Kolommen gescheiden door `\|`; aardbevinggegevens (plaats, datum, magnitude, diepte, straal) identiek op elke rij; per monument: nummer, naam, type, functies, afstand, impactindicatie, effectgebied, versterkingsprogramma (ja/nee), monumentenregister-link, linked-data URI |
| 14.4 | Controleer een monument dat in het versterkingsprogramma zit (bv. nr. 26265) | Kolom "Versterkingsprogramma" toont "ja" |
| 14.5 | Open het bestand in Excel | Accenten (bv. "Groningen") tonen correct dankzij de UTF-8 BOM |

## 15. Filter op monumentaard/functie

| # | Stap | Verwacht resultaat |
|---|---|---|
| 15.1 | Selecteer een epicentrum (bv. Loppersum, 25 km) | Paneel "Filter op type / functie" verschijnt met twee groepen: Monumentaard (2 chips) en Oorspronkelijke functie (tot 12 chips, gesorteerd op aantal, met "+ N andere functies" als er meer zijn) |
| 15.2 | Klik de chip "Archeologisch (214)" | Alleen schop-markers blijven op de kaart (huisjes verdwijnen); rij "Filter: Archeologisch (214 van 614) Wis" verschijnt boven de chips |
| 15.3 | Klik dezelfde chip nogmaals | Filter verdwijnt, alle 614 markers weer zichtbaar |
| 15.4 | Klik een functie-chip (bv. "Woonhuis") en download de CSV | CSV bevat alleen rijen met die functie in de kolom Functie_Oorspronkelijk (aantal rijen = aantal op de chip) |
| 15.5 | Klik "Wis" naast een actief filter | Filter wordt opgeheven, alle markers weer zichtbaar |
| 15.6 | Kies met een actief filter een nieuw, ander epicentrum | Filter wordt automatisch gewist (paneel toont weer de volledige, nieuwe telling zonder actieve chip) |
| 15.7 | Activeer een functie-filter, wijzig daarna de straal zodanig dat die functie niet meer voorkomt in de nieuwe straal | Filter wordt automatisch opgeheven i.p.v. een lege kaart zonder wis-mogelijkheid te tonen |

## 16. Robuustheid bij falende bronnen

| # | Stap | Verwacht resultaat |
|---|---|---|
| 13.1 | Simuleer een falende KNMI- of RCE-request (bv. offline zetten van één endpoint via devtools request-blocking) | De andere bron blijft werken; statusregel toont welk deel ontbreekt i.p.v. dat de hele pagina crasht |
| 13.2 | Blokkeer beide aardbevingsbronnen tegelijk | Duidelijke foutmelding "Kon aardbevingsdata niet laden: ..." i.p.v. een stille lege kaart |

## Niet-gedekt door deze checklist

- Een echt mobiel toestel (buiten de browser-resize-tool om).
- Geautomatiseerde tests (geen testframework in dit project - alles is handmatige/browser-tool-
  verificatie, zie ook de sessiegeschiedenis in CHANGELOG.md).
