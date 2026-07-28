# Impactindicatie

De impactindicatie (voorheen "impactscore" genoemd - hernoemd omdat "score" een preciezere
meting suggereert dan de methode kan waarmaken) is een **vereenvoudigde, illustratieve indicator**
- geen gevalideerd schade- of risicomodel. Doel: laten zien of een epicentrum-monument-combinatie
plausibel binnen een realistisch trillingsgebied valt, niet om schade te voorspellen. In de
interface wordt hij consequent aangeduid als *indicatief effectgebied* en *verkennende
impactindicatie* - nadrukkelijk **geen schadebeoordeling**, en getoond met maximaal 1 decimaal om
geen schijnprecisie te suggereren.

## Formule

```
Rh (hypocentrale afstand, km) = √(epicentrale_afstand² + diepte²)
score = magnitude − 1.646 · log₁₀(Rh) − 1.052
```

`score ≥ 0` betekent: binnen het indicatieve effectgebied. Stoplicht-kleurcodering in de kaart:

- **rood** (`score ≥ 1`): ruim binnen indicatie
- **oranje** (`0 ≤ score < 1`): net binnen indicatie
- **groen** (`score < 0`): buiten indicatie

Bewust geen grijs/gedimd voor "buiten indicatie" - dat was op een grijze of blauwe ondergrond
(bv. rijksmonumenten in zee, zoals scheepswrakken) nauwelijks te onderscheiden van de
kaartachtergrond. Aardbevingen gebruiken een aparte kleurenschaal (geel = geïnduceerd, blauw =
tektonisch) zodat er geen overlap is met de rood/oranje/groen van de monument-impact.

## Kalibratie (met bronnen)

De coëfficiënten (1.646 en 1.052) zijn gebaseerd op gepubliceerde gegevens - het zijn de
resultaten van een lineaire regressie op `log₁₀(Rh)` tegen magnitude, gefit op **drie echte,
gepubliceerde effectgebieden** van het Instituut Mijnbouwschade Groningen (IMG), allemaal op
basis van dezelfde methode (trillingssnelheidsdrempel 2 mm/s bij 1% overschrijdingskans, Bommer
et al.-methode):

| Beving | Magnitude | Effectgebied | Bron |
|---|---|---|---|
| generiek IMG-voorbeeld | M2.7 | 9,5 km | [schadedoormijnbouw.nl - Effectgebied na een nieuwe beving](https://www.schadedoormijnbouw.nl/nieuws/2022/11/effectgebied-na-een-nieuwe-beving) |
| Wirdum, 8 okt 2012 | M3.1 | 17,5 km | [schadedoormijnbouw.nl](https://www.schadedoormijnbouw.nl/nieuws/2022/11/effectgebied-na-een-nieuwe-beving) |
| Huizinge, 16 aug 2012 | M3.6 | >35 km | [KNMI - Magnitude beving Huizinge wordt 3,6](https://www.knmi.nl/over-het-knmi/nieuws/magnitude-beving-huizinge-wordt-3-6) / schadedoormijnbouw.nl |

Diepte is voor deze drie punten aangenomen op ~3 km (de gebruikelijke diepte van het
Groningenveld). De gefitte lijn benadert alle drie punten binnen ±0,01 magnitude.

## Belangrijke beperking

Deze kalibratie is **alleen valide voor ondiepe (≤5 km), geïnduceerde bevingen** zoals in
Groningen. Getest tegen de zwaarste natuurlijke Nederlandse beving (Roermond, 1992, M5,8, 18 km
diep - reëel schadegebied ~15-20 km rond Roermond/Maaseik/Heinsberg volgens
[Wikipedia](https://en.wikipedia.org/wiki/1992_Roermond_earthquake)) blijkt de score op grote
afstand veel te hoog te blijven: andere bodem, andere diepte, andere attenuatie-eigenschappen dan
het Groningenveld. Vandaar een expliciete waarschuwing in de popup ("kalibratie minder
betrouwbaar") zodra de diepte van de geselecteerde beving groter is dan 5 km.

**Dit is en blijft een vuistregel voor verkenning, geen schadebeoordeling.**
