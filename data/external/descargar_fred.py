#!/usr/bin/env python3
"""Descarga la serie externa mensual de FRED y reescribe data/external/fred_mensual.csv.

Series: NASDAQCOM (diaria -> promedio mensual), FEDFUNDS (mensual), UNRATE (mensual).
Periodo: 1990-01 a 2013-12 (los datos de Crunchbase terminan en 2013-12-31).

No necesita API key: usa el endpoint público fredgraph.csv.
Uso:  python data/external/descargar_fred.py
"""
import pathlib
import sys
import urllib.request

import pandas as pd

SERIES = ["NASDAQCOM", "FEDFUNDS", "UNRATE"]
INICIO, FIN = "1990-01-01", "2013-12-31"
DESTINO = pathlib.Path(__file__).resolve().parent / "fred_mensual.csv"
URL = ("https://fred.stlouisfed.org/graph/fredgraph.csv"
       "?id={serie}&cosd={inicio}&coed={fin}")


def bajar_mensual(serie: str) -> pd.Series:
    """Devuelve la serie indexada por primer día del mes, promediando si es diaria."""
    url = URL.format(serie=serie, inicio=INICIO, fin=FIN)
    with urllib.request.urlopen(url, timeout=60) as r:
        df = pd.read_csv(r)
    # FRED nombra la primera columna observation_date (o DATE en versiones viejas)
    fecha_col = df.columns[0]
    df[fecha_col] = pd.to_datetime(df[fecha_col])
    df[serie] = pd.to_numeric(df[serie], errors="coerce")  # '.' = sin dato
    df = df.dropna(subset=[serie])
    mensual = (df.set_index(fecha_col)[serie]
                 .resample("MS").mean()
                 .rename(serie.lower()))
    return mensual


def main() -> int:
    partes = []
    for s in SERIES:
        print(f"Bajando {s} ...", flush=True)
        partes.append(bajar_mensual(s))
    df = pd.concat(partes, axis=1).sort_index()
    df.index.name = "anio_mes"
    df = df.loc[INICIO:FIN]

    faltantes = int(df.isna().sum().sum())
    print(f"Filas: {len(df)}  |  rango: {df.index.min():%Y-%m} a {df.index.max():%Y-%m}"
          f"  |  celdas vacías: {faltantes}")
    if len(df) != 288 or faltantes:
        print("AVISO: el archivo no quedó como el versionado (288 filas, 0 vacías). "
              "Revisa antes de commitear.", file=sys.stderr)

    df.round(4).to_csv(DESTINO, date_format="%Y-%m-%d")
    print("Escrito:", DESTINO)
    return 0


if __name__ == "__main__":
    sys.exit(main())
