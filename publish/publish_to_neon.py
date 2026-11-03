#!/usr/bin/env python3
"""Publica el esquema marts de DuckDB en Neon (Postgres).

Uso:
    python publish/publish_to_neon.py                       # todas las tablas de marts
    python publish/publish_to_neon.py marts.fact_rondas     # solo una

Credenciales en .env: DATABASE_URL (cadena DIRECTA, sin -pooler) y, opcional,
ROL_LECTURA (rol de solo lectura para dashboard/Power BI). Nunca subir .env.
"""
import os
import pathlib
import sys
import tempfile

import duckdb
import psycopg
from dotenv import load_dotenv

ROOT = pathlib.Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

# Llave primaria de cada tabla de marts (compuesta en el puente).
PKS = {
    "dim_fecha": ["fecha"],
    "dim_empresa": ["empresa_id"],
    "dim_inversionista": ["inversionista_id"],
    "fact_rondas": ["ronda_id"],
    "puente_ronda_inversionista": ["ronda_id", "inversionista_id"],
    "fact_adquisiciones": ["adquisicion_id"],
    "fact_ipos": ["ipo_id"],
}

# Indices para acelerar los JOIN y filtros del dashboard.
INDICES = {
    "fact_rondas": ["empresa_id", "fecha"],
    "puente_ronda_inversionista": ["inversionista_id"],
    "fact_adquisiciones": ["empresa_adquirida_id", "empresa_adquirente_id", "fecha"],
    "fact_ipos": ["empresa_id", "fecha"],
    "dim_empresa": ["industria", "pais"],
}

TIPOS = {
    "BIGINT": "bigint", "INTEGER": "integer", "SMALLINT": "smallint",
    "VARCHAR": "text", "DOUBLE": "double precision", "FLOAT": "real",
    "DATE": "date", "TIMESTAMP": "timestamp", "BOOLEAN": "boolean",
}


def cadena_conexion():
    url = os.environ.get("DATABASE_URL")
    if url:
        return url
    return (
        f"host={os.environ['NEON_HOST']} dbname={os.environ['NEON_DB']} "
        f"user={os.environ['NEON_USER']} password={os.environ['NEON_PASSWORD']} "
        f"sslmode={os.environ.get('NEON_SSLMODE', 'require')}"
    )


def tipo_postgres(tipo):
    t = tipo.upper()
    if t.startswith("DECIMAL"):
        return "numeric" + t[len("DECIMAL"):]
    if t in TIPOS:
        return TIPOS[t]
    sys.exit(f"Tipo sin traduccion: {tipo}. Conviertelo con un CAST en el SQL del mart.")


def publicar(origen, pg, schema, tabla, rol):
    if tabla not in PKS:
        sys.exit(f"Falta definir la llave primaria de {tabla} en PKS.")
    columnas = origen.execute(f"describe {schema}.{tabla}").fetchall()
    definicion = ", ".join(f'"{c[0]}" {tipo_postgres(c[1])}' for c in columnas)
    pk = ", ".join(f'"{c}"' for c in PKS[tabla])

    with tempfile.TemporaryDirectory() as tmp:
        archivo = pathlib.Path(tmp, "tabla.csv").as_posix()
        origen.execute(
            f"copy (select * from {schema}.{tabla}) to '{archivo}' (format csv, header false)"
        )
        with pg.cursor() as cur:
            cur.execute(f"create schema if not exists {schema}")
            cur.execute(f"drop table if exists {schema}.{tabla}")
            cur.execute(f"create table {schema}.{tabla} ({definicion})")
            with open(archivo, "rb") as f, cur.copy(
                f"copy {schema}.{tabla} from stdin with (format csv)"
            ) as copia:
                while bloque := f.read(1 << 16):
                    copia.write(bloque)
            cur.execute(f"alter table {schema}.{tabla} add primary key ({pk})")
            for col in INDICES.get(tabla, []):
                cur.execute(f'create index on {schema}.{tabla} ("{col}")')
            if rol:
                cur.execute(f'grant usage on schema {schema} to "{rol}"')
                cur.execute(f'grant select on {schema}.{tabla} to "{rol}"')
            cur.execute(f"select count(*) from {schema}.{tabla}")
            en_neon = cur.fetchone()[0]
    pg.commit()
    en_duckdb = origen.execute(f"select count(*) from {schema}.{tabla}").fetchone()[0]
    estado = "OK" if en_neon == en_duckdb else "NO COINCIDE"
    print(f"[{estado}] {schema}.{tabla}: DuckDB={en_duckdb:,}  Neon={en_neon:,}")
    return en_neon == en_duckdb


def main():
    origen = duckdb.connect(str(ROOT / "data" / "crunchbase.duckdb"), read_only=True)
    existentes = [r[0] for r in origen.execute(
        "select table_name from information_schema.tables where table_schema = 'marts'"
    ).fetchall()]
    pedidas = [a.split(".")[-1] for a in sys.argv[1:]]
    tablas = pedidas or existentes
    # dimensiones primero, luego hechos y puente
    tablas = sorted(tablas, key=lambda t: (not t.startswith("dim_"), t))
    rol = os.environ.get("ROL_LECTURA") or None

    todo_ok = True
    with psycopg.connect(cadena_conexion()) as pg:
        for tabla in tablas:
            todo_ok &= publicar(origen, pg, "marts", tabla, rol)
        with pg.cursor() as cur:
            cur.execute("select pg_size_pretty(pg_database_size(current_database()))")
            print("Tamano de la base en Neon:", cur.fetchone()[0], "(limite del plan gratuito: 1 GB)")
    if not todo_ok:
        sys.exit("Alguna tabla no coincide con DuckDB: revisar antes de entregar.")


if __name__ == "__main__":
    main()