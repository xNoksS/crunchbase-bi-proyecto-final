# Serie externa (FRED) — análisis (b) Financiamiento y ciclos de mercado

El PDF pide, para el análisis elegido, "una serie externa mensual de una fuente
pública, con fuente, frecuencia y periodo documentados, verificando que cubra el
periodo de los datos de Crunchbase (que terminan en diciembre de 2013)".

## Archivo

`fred_mensual.csv` — 288 filas, una por mes, de **1990-01** a **2013-12**.

| Columna | Serie FRED | Qué es | Frecuencia original | Agregación a mes |
|---|---|---|---|---|
| `anio_mes` | — | Primer día del mes (`DATE`). Une con `marts.dim_fecha.anio_mes`. | — | — |
| `nasdaqcom` | [`NASDAQCOM`](https://fred.stlouisfed.org/series/NASDAQCOM) | NASDAQ Composite Index, cierre | Diaria (días hábiles) | **Promedio** de los días del mes |
| `fedfunds` | [`FEDFUNDS`](https://fred.stlouisfed.org/series/FEDFUNDS) | Federal Funds Effective Rate, % anual | Mensual | Ninguna (ya es mensual) |
| `unrate` | [`UNRATE`](https://fred.stlouisfed.org/series/UNRATE) | Tasa de desempleo de EE. UU., % | Mensual | Ninguna (ya es mensual) |

- **Fuente:** Federal Reserve Bank of St. Louis (FRED), <https://fred.stlouisfed.org>.
- **Periodo:** 1990-01-01 a 2013-12-01. Cubre todo el periodo útil de Crunchbase
  (las rondas prácticamente empiezan a mediados de los noventa y los datos cortan
  en 2013-12-31), con 12 meses de margen al inicio para construir rezagos.
- **Fecha de descarga:** 2026-11-02.
- **Unidades:** índice (NASDAQCOM) y porcentaje anual (FEDFUNDS, UNRATE). Sin
  desestacionalizar NASDAQCOM; FEDFUNDS y UNRATE vienen como los publica FRED
  (UNRATE desestacionalizada en origen).
- **Valores faltantes:** ninguno en las 288 filas × 3 series.

## Por qué estas tres

- `NASDAQCOM` es la serie de "ciclo de mercado" que sugiere el PDF: el
  termómetro del apetito por riesgo en tecnología.
- `FEDFUNDS` es la otra que sugiere el PDF y entra como **control**: el costo del
  dinero mueve a la vez a la bolsa y al capital de riesgo, así que sin él una
  correlación entre NASDAQ y financiamiento puede ser pura liquidez.
- `UNRATE` entra como **segundo control macro**: el ciclo económico general.

## Cómo se reproduce

```bash
python data/external/descargar_fred.py
```

Vuelve a bajar las tres series de FRED y reescribe `fred_mensual.csv`. No
necesita API key: usa el endpoint público `fredgraph.csv`. El archivo se versiona
en Git (excepción explícita en `.gitignore`) para que el análisis corra aunque
no haya internet.

## Cómo entra al modelo

`sql/04_marts/08_serie_externa_mensual.sql` la carga como
`marts.serie_externa_mensual` (grano: un mes). Al estar en el esquema `marts`,
`publish/publish_to_neon.py` la sube a Neon junto con el resto del modelo.
