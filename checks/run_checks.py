"""Checks automatizados del pipeline (calidad de datos).

Uso:
    python checks/run_checks.py             # advierte en tablas aun sin capa clean
    python checks/run_checks.py --estricto  # toda advertencia cuenta como falla (entrega final)

Sale con codigo 1 si algun check falla. Escribe docs/resultados_checks.md en cada corrida.
Ruta de la base: variable de entorno DUCKDB_PATH (por defecto data/crunchbase.duckdb).
"""
import datetime
import os
import sys

import duckdb

DB = os.environ.get("DUCKDB_PATH", "data/crunchbase.duckdb")
SALIDA = "docs/resultados_checks.md"
FECHA_MIN = "1800-01-01"
FECHA_MAX = "2013-12-31"  # los datos de Crunchbase terminan en diciembre de 2013
ESTRICTO = "--estricto" in sys.argv

# tabla -> columna que debe ser llave primaria (segun el diccionario de datos)
PKS = {
    "objects": "id",
    "funding_rounds": "funding_round_id",
    "investments": "id",
    "acquisitions": "acquisition_id",
    "ipos": "ipo_id",
    "funds": "fund_id",
    "people": "object_id",
    "degrees": "id",
    "relationships": "relationship_id",
    "milestones": "id",
    "offices": "office_id",
}

# (hijo, columna FK, padre, columna PK)
FKS = [
    ("objects", "parent_id", "objects", "id"),
    ("funding_rounds", "object_id", "objects", "id"),
    ("investments", "funding_round_id", "funding_rounds", "funding_round_id"),
    ("investments", "funded_object_id", "objects", "id"),
    ("investments", "investor_object_id", "objects", "id"),
    ("acquisitions", "acquiring_object_id", "objects", "id"),
    ("acquisitions", "acquired_object_id", "objects", "id"),
    ("ipos", "object_id", "objects", "id"),
    ("funds", "object_id", "objects", "id"),
    ("people", "object_id", "objects", "id"),
    ("degrees", "object_id", "people", "object_id"),
    ("relationships", "person_object_id", "people", "object_id"),
    ("relationships", "relationship_object_id", "objects", "id"),
    ("milestones", "object_id", "objects", "id"),
    ("offices", "object_id", "objects", "id"),
]

# Diferencia esperada de filas clean vs staging, segun docs/bitacora_calidad.md
# (acquisitions: 1 fila sin FK; ipos: 5 filas sin FK). objects se calcula aparte.
DELTAS_CLEAN = {"acquisitions": -1, "ipos": -5}

# (tabla, FK a objects, columna de fecha del evento): el evento no puede ser anterior a founded_at
CRUCES_FECHA = [
    ("funding_rounds", "object_id", "funded_at"),
    ("acquisitions", "acquired_object_id", "acquired_at"),
    ("ipos", "object_id", "public_at"),
]

PALABRAS_MONTO = ("amount", "_usd", "valuation", "price", "total", "raised")
TIPOS_NUM = ("DECIMAL", "INTEGER", "BIGINT", "SMALLINT", "TINYINT", "HUGEINT", "DOUBLE", "FLOAT", "REAL")

resultados = []  # (check, estado, detalle)


def add(check, estado, detalle):
    resultados.append((check, estado, detalle))


def existe(con, esquema, tabla):
    return con.execute(
        "SELECT count(*) FROM information_schema.tables WHERE table_schema=? AND table_name=?",
        [esquema, tabla],
    ).fetchone()[0] == 1


def columnas(con, esquema, tabla):
    filas = con.execute(
        "SELECT column_name, data_type FROM information_schema.columns "
        "WHERE table_schema=? AND table_name=?",
        [esquema, tabla],
    ).fetchall()
    return {n: t for n, t in filas}


def capa(con, tabla):
    """clean si existe; si no, staging; si no, None."""
    if existe(con, "clean", tabla):
        return "clean"
    if existe(con, "staging", tabla):
        return "staging"
    return None


def check_pks(con):
    for tabla, pk in PKS.items():
        sch = capa(con, tabla)
        nombre = f"PK {tabla}.{pk}"
        if sch is None:
            add(nombre, "AVISO", "la tabla no existe en staging ni clean; omitido")
            continue
        if pk not in columnas(con, sch, tabla):
            add(nombre, "FALLA", f"la columna {pk} no existe en {sch}.{tabla}")
            continue
        filas, distintas, nulas = con.execute(
            f"SELECT count(*), count(DISTINCT {pk}), count(*) FILTER (WHERE {pk} IS NULL) "
            f"FROM {sch}.{tabla}"
        ).fetchone()
        repetidas = (filas - nulas) - distintas
        detalle = f"capa={sch}, filas={filas}, nulas={nulas}, repetidas={repetidas}"
        add(nombre, "OK" if nulas == 0 and repetidas == 0 else "FALLA", detalle)


def check_fks(con):
    for hijo, fk, padre, pk in FKS:
        nombre = f"FK {hijo}.{fk} -> {padre}.{pk}"
        sh, sp = capa(con, hijo), capa(con, padre)
        if sh is None or sp is None:
            add(nombre, "AVISO", "tabla hija o padre no existe; omitido")
            continue
        if fk not in columnas(con, sh, hijo) or pk not in columnas(con, sp, padre):
            add(nombre, "FALLA", "columna de la FK o de la PK no existe")
            continue
        huerfanos, distintas = con.execute(
            f"SELECT count(*), count(DISTINCT h.{fk}) FROM {sh}.{hijo} h "
            f"LEFT JOIN {sp}.{padre} p ON h.{fk} = p.{pk} "
            f"WHERE h.{fk} IS NOT NULL AND p.{pk} IS NULL"
        ).fetchone()
        nulas = con.execute(f"SELECT count(*) FROM {sh}.{hijo} WHERE {fk} IS NULL").fetchone()[0]
        detalle = f"hijo={sh}, padre={sp}, huerfanos={huerfanos} (llaves={distintas}), FK nulas={nulas}"
        if huerfanos == 0:
            add(nombre, "OK", detalle)
        elif sh == "staging":
            add(nombre, "AVISO", detalle + " | la tabla hija aun no tiene capa clean")
        else:
            add(nombre, "FALLA", detalle)


def check_reconciliacion(con):
    for tabla in PKS:
        nombre = f"Filas {tabla}"
        if not existe(con, "raw", tabla) or not existe(con, "staging", tabla):
            add(nombre, "AVISO", "falta raw o staging; omitido")
            continue
        n_raw = con.execute(f"SELECT count(*) FROM raw.{tabla}").fetchone()[0]
        n_stg = con.execute(f"SELECT count(*) FROM staging.{tabla}").fetchone()[0]
        if n_raw != n_stg:
            add(nombre, "FALLA", f"raw={n_raw} != staging={n_stg} sin explicacion documentada")
            continue
        if not existe(con, "clean", tabla):
            add(nombre, "AVISO", f"raw={n_raw}, staging={n_stg}; sin capa clean todavia")
            continue
        n_cln = con.execute(f"SELECT count(*) FROM clean.{tabla}").fetchone()[0]
        delta = DELTAS_CLEAN.get(tabla, 0)
        nota = "sin cambios" if delta == 0 else f"{delta:+d} filas segun bitacora"
        if tabla == "objects":
            if "es_registro_faltante" in columnas(con, "clean", "objects"):
                delta = con.execute(
                    "SELECT count(*) FROM clean.objects WHERE es_registro_faltante"
                ).fetchone()[0]
                nota = f"+{delta} registros de reemplazo (bitacora fila 9)"
            else:
                nota = "columna es_registro_faltante no existe"
        esperado = n_stg + delta
        detalle = f"raw={n_raw}, staging={n_stg}, clean={n_cln}, esperado={esperado} ({nota})"
        add(nombre, "OK" if n_cln == esperado else "FALLA", detalle)


def check_montos(con):
    for tabla in PKS:
        sch = capa(con, tabla)
        if sch is None:
            continue
        cols = [
            c for c, t in columnas(con, sch, tabla).items()
            if t.upper().startswith(TIPOS_NUM) and any(p in c.lower() for p in PALABRAS_MONTO)
        ]
        if not cols:
            continue
        exprs = ", ".join(f"count(*) FILTER (WHERE {c} < 0)" for c in cols)
        fila = con.execute(f"SELECT {exprs} FROM {sch}.{tabla}").fetchone()
        for c, n in zip(cols, fila):
            add(f"Monto negativo {tabla}.{c}", "OK" if n == 0 else "FALLA", f"capa={sch}, negativos={n}")


def check_fechas(con):
    for tabla in PKS:
        sch = capa(con, tabla)
        if sch is None:
            continue
        cols = [c for c, t in columnas(con, sch, tabla).items() if t.upper() == "DATE"]
        for c in cols:
            fuera = con.execute(
                f"SELECT count(*) FROM {sch}.{tabla} "
                f"WHERE {c} < DATE '{FECHA_MIN}' OR {c} > DATE '{FECHA_MAX}'"
            ).fetchone()[0]
            estado = "OK" if fuera == 0 else ("AVISO" if sch == "staging" else "FALLA")
            add(
                f"Fecha fuera de rango {tabla}.{c}",
                estado,
                f"capa={sch}, fuera de [{FECHA_MIN}, {FECHA_MAX}]={fuera}",
            )
    so = capa(con, "objects")
    for tabla, fk, fecha in CRUCES_FECHA:
        nombre = f"Evento anterior a fundacion {tabla}.{fecha}"
        st = capa(con, tabla)
        if so is None or st is None:
            add(nombre, "AVISO", "tabla no existe; omitido")
            continue
        ct, co = columnas(con, st, tabla), columnas(con, so, "objects")
        if fecha not in ct or fk not in ct or "founded_at" not in co:
            add(nombre, "AVISO", "falta una columna necesaria; omitido")
            continue
        n = con.execute(
            f"SELECT count(*) FROM {st}.{tabla} h JOIN {so}.objects o ON h.{fk} = o.id "
            f"WHERE h.{fecha} < o.founded_at"
        ).fetchone()[0]
        add(nombre, "OK" if n == 0 else "FALLA", f"capa={st}, filas con evento < founded_at={n}")


def escribir_reporte(estado_final):
    marca = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    lineas = [
        "# Resultados de checks automatizados",
        "",
        f"Corrida: {marca} | modo: {'estricto' if ESTRICTO else 'normal'} | resultado: **{estado_final}**",
        "",
        "| Check | Estado | Detalle |",
        "|---|---|---|",
    ]
    for check, estado, detalle in resultados:
        lineas.append(f"| {check} | {estado} | {detalle} |")
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write("\n".join(lineas) + "\n")


def main():
    if not os.path.exists(DB):
        print(f"No existe la base {DB}. Corre primero: python run_all.py --skip-checks")
        return 1
    con = duckdb.connect(DB, read_only=True)
    check_pks(con)
    check_fks(con)
    check_reconciliacion(con)
    check_montos(con)
    check_fechas(con)
    con.close()

    fallas = [r for r in resultados if r[1] == "FALLA" or (ESTRICTO and r[1] == "AVISO")]
    avisos = [r for r in resultados if r[1] == "AVISO"]
    for check, estado, detalle in resultados:
        print(f"[{estado:6}] {check}: {detalle}")
    estado_final = "FALLA" if fallas else "OK"
    print(f"\nResumen: {len(resultados)} checks, {len(fallas)} fallas, {len(avisos)} avisos -> {estado_final}")
    escribir_reporte(estado_final)
    return 1 if fallas else 0


if __name__ == "__main__":
    sys.exit(main())
