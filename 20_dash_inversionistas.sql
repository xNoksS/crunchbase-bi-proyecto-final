CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- TABLAS DEL DASHBOARD: FICHA DE INVERSIONISTAS (pagina 2)
--   (Jose - BI y storytelling)
--
-- Implementan en SQL las definiciones del diccionario de metricas
-- (docs/diccionario_metricas.md, fichas de Ximena), para que Power BI lea
-- tablas de Neon y no archivos sueltos:
--   * Inversionista activo : al menos una ronda entre 2011-01-01 y 2013-12-31.
--   * Exito V1             : la empresa tuvo una salida (adquisicion o IPO)
--                            DESPUES de la primera participacion del
--                            inversionista y antes del 2013-12-31.
--   * Exito V2             : la empresa levanto una ronda POSTERIOR a la
--                            primera participacion del inversionista.
--   * Benchmark            : tasa de exito de TODAS las empresas que levantaron
--                            una ronda del mismo tipo (etapa de entrada), en la
--                            misma industria y el mismo anio que la entrada del
--                            inversionista. Responde: "si hubiera invertido igual
--                            que el mercado en ese sector, etapa y anio, que tasa
--                            esperariamos".
--
-- Por que la etapa del benchmark es la ronda de ENTRADA y no dim_empresa.etapa:
--   dim_empresa.etapa es el tipo de la ULTIMA ronda de la empresa. Usarla para
--   comparar mete informacion del futuro: una empresa cuya ultima ronda es
--   series-c+ por definicion levanto rondas posteriores (exito V2). La ronda en
--   la que entro el inversionista es lo que el sabia al momento de invertir.
--
-- Por que el benchmark controla el plazo: comparar contra empresas del MISMO
--   anio de entrada hace que un inversionista que entro en 2012 (sin tiempo para
--   ver salidas) se compare con empresas que tampoco tuvieron tiempo.
--
-- Montos: ninguna tabla de este archivo suma montos (regla del puente).
-- =====================================================================

-- ---------------------------------------------------------------------
-- dash_portafolio
-- Grano: una fila por par (inversionista, empresa): la primera vez que el
-- inversionista entro a la empresa.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.dash_portafolio AS
WITH participaciones AS (
    SELECT p.inversionista_id, r.ronda_id, r.empresa_id, r.fecha, r.tipo_ronda
    FROM marts.puente_ronda_inversionista p
    JOIN marts.fact_rondas r ON r.ronda_id = p.ronda_id
    WHERE r.fecha IS NOT NULL                -- sin fecha no se puede ubicar la entrada
),
entrada AS (
    SELECT
        inversionista_id,
        empresa_id,
        MIN(fecha)                           AS fecha_entrada,
        arg_min(tipo_ronda, fecha)           AS etapa_entrada,
        COUNT(DISTINCT ronda_id)             AS rondas_en_empresa
    FROM participaciones
    GROUP BY inversionista_id, empresa_id
),
salidas AS (
    SELECT empresa_adquirida_id AS empresa_id, fecha FROM marts.fact_adquisiciones WHERE fecha IS NOT NULL
    UNION ALL
    SELECT empresa_id, fecha FROM marts.fact_ipos WHERE fecha IS NOT NULL
),
-- universo del benchmark: cada empresa la primera vez que levanto una ronda
-- de cierto tipo en cierto anio
universo AS (
    SELECT r.empresa_id, e.industria, r.tipo_ronda AS etapa, year(r.fecha) AS anio,
           MIN(r.fecha) AS fecha
    FROM marts.fact_rondas r
    JOIN marts.dim_empresa e ON e.empresa_id = r.empresa_id
    WHERE r.fecha IS NOT NULL
    GROUP BY 1, 2, 3, 4
),
universo_exito AS (
    SELECT
        u.*,
        EXISTS (SELECT 1 FROM salidas s
                WHERE s.empresa_id = u.empresa_id AND s.fecha > u.fecha)           AS v1,
        EXISTS (SELECT 1 FROM marts.fact_rondas r
                WHERE r.empresa_id = u.empresa_id AND r.fecha > u.fecha)           AS v2
    FROM universo u
),
celda AS (          -- industria x etapa x anio
    SELECT industria, etapa, anio, COUNT(*) AS n,
           AVG(CAST(v1 AS INTEGER)) AS bench_v1, AVG(CAST(v2 AS INTEGER)) AS bench_v2
    FROM universo_exito GROUP BY 1, 2, 3
),
respaldo AS (       -- etapa x anio, para celdas con menos de 10 empresas
    SELECT etapa, anio, COUNT(*) AS n,
           AVG(CAST(v1 AS INTEGER)) AS bench_v1, AVG(CAST(v2 AS INTEGER)) AS bench_v2
    FROM universo_exito GROUP BY 1, 2
)
SELECT
    en.inversionista_id,
    en.empresa_id,
    e.industria,
    e.pais,
    en.fecha_entrada,
    CAST(year(en.fecha_entrada) AS INTEGER)                              AS anio_entrada,
    en.etapa_entrada,
    CAST(en.rondas_en_empresa AS INTEGER)                                AS rondas_en_empresa,
    EXISTS (SELECT 1 FROM salidas s
            WHERE s.empresa_id = en.empresa_id AND s.fecha > en.fecha_entrada)      AS exito_v1,
    EXISTS (SELECT 1 FROM marts.fact_rondas r
            WHERE r.empresa_id = en.empresa_id AND r.fecha > en.fecha_entrada)      AS exito_v2,
    -- plazo observable de 3 anios dentro de los datos (para lecturas honestas)
    (en.fecha_entrada + INTERVAL 3 YEAR <= DATE '2013-12-31')                       AS observable_3a,
    CASE WHEN c.n >= 10 THEN c.bench_v1 ELSE rb.bench_v1 END                        AS bench_v1,
    CASE WHEN c.n >= 10 THEN c.bench_v2 ELSE rb.bench_v2 END                        AS bench_v2,
    CASE WHEN c.n >= 10 THEN 'industria-etapa-anio' ELSE 'etapa-anio' END           AS nivel_benchmark,
    CAST(CASE WHEN c.n >= 10 THEN c.n ELSE rb.n END AS INTEGER)                     AS n_benchmark
FROM entrada en
JOIN marts.dim_empresa e ON e.empresa_id = en.empresa_id
LEFT JOIN celda    c  ON c.industria = e.industria AND c.etapa = en.etapa_entrada
                     AND c.anio = year(en.fecha_entrada)
LEFT JOIN respaldo rb ON rb.etapa = en.etapa_entrada AND rb.anio = year(en.fecha_entrada);

-- ---------------------------------------------------------------------
-- dash_inversionista
-- Grano: una fila por inversionista con al menos una participacion fechada.
-- Las tasas aqui son las del portafolio completo; el dashboard recalcula con
-- DAX cuando se filtra por industria, anio o tamano minimo de portafolio.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.dash_inversionista AS
WITH act AS (
    SELECT p.inversionista_id,
           COUNT(DISTINCT r.ronda_id)                                        AS rondas_total,
           COUNT(DISTINCT r.ronda_id) FILTER (WHERE r.fecha BETWEEN DATE '2011-01-01'
                                                             AND DATE '2013-12-31') AS rondas_2011_2013
    FROM marts.puente_ronda_inversionista p
    JOIN marts.fact_rondas r ON r.ronda_id = p.ronda_id
    WHERE r.fecha IS NOT NULL
    GROUP BY 1
),
port AS (
    SELECT inversionista_id,
           COUNT(*)                                     AS n_empresas,
           SUM(CAST(exito_v1 AS INTEGER))               AS exitos_v1,
           SUM(CAST(exito_v2 AS INTEGER))               AS exitos_v2,
           AVG(bench_v1)                                AS bench_v1,
           AVG(bench_v2)                                AS bench_v2,
           MIN(anio_entrada)                            AS primer_anio,
           MAX(anio_entrada)                            AS ultimo_anio,
           mode(industria)                              AS industria_principal
    FROM marts.dash_portafolio
    GROUP BY 1
)
SELECT
    d.inversionista_id,
    COALESCE(d.nombre, d.inversionista_id)                               AS nombre,
    -- 150 nombres se repiten entre inversionistas distintos: etiqueta unica para
    -- las tablas y graficas del dashboard
    CASE WHEN COUNT(*) OVER (PARTITION BY COALESCE(d.nombre, d.inversionista_id)) > 1
         THEN COALESCE(d.nombre, d.inversionista_id) || ' (' || d.inversionista_id || ')'
         ELSE COALESCE(d.nombre, d.inversionista_id)
    END                                                                  AS etiqueta,
    d.tipo_inversionista,
    d.pais,
    p.industria_principal,
    CAST(p.primer_anio AS INTEGER)                                       AS primer_anio,
    CAST(p.ultimo_anio AS INTEGER)                                       AS ultimo_anio,
    CAST(a.rondas_total AS INTEGER)                                      AS rondas_total,
    CAST(a.rondas_2011_2013 AS INTEGER)                                  AS rondas_2011_2013,
    (a.rondas_2011_2013 >= 1)                                            AS es_activo,
    CAST(p.n_empresas AS INTEGER)                                        AS n_empresas,
    CAST(p.exitos_v1 AS INTEGER)                                         AS exitos_v1,
    CAST(p.exitos_v2 AS INTEGER)                                         AS exitos_v2,
    CAST(p.exitos_v1 AS DOUBLE) / p.n_empresas                           AS tasa_v1,
    CAST(p.exitos_v2 AS DOUBLE) / p.n_empresas                           AS tasa_v2,
    p.bench_v1,
    p.bench_v2,
    CAST(p.exitos_v1 AS DOUBLE) / p.n_empresas - p.bench_v1              AS exceso_v1,
    CAST(p.exitos_v2 AS DOUBLE) / p.n_empresas - p.bench_v2              AS exceso_v2
FROM port p
JOIN act a                    ON a.inversionista_id = p.inversionista_id
JOIN marts.dim_inversionista d ON d.inversionista_id = p.inversionista_id;

-- ---------------------------------------------------------------------
-- dash_sensibilidad_top10
-- Grano: una fila por tamano minimo de portafolio.
-- Cuantos inversionistas del top 10 por V1 siguen en el top 10 por V2, y
-- cuantos del top 10 por tasa V1 siguen en el top 10 por exceso sobre el
-- benchmark (quien rinde bien vs quien solo invirtio en sectores y anios buenos).
-- Desempate fijo: mas empresas primero, luego inversionista_id.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.dash_sensibilidad_top10 AS
WITH umbrales(minimo) AS (SELECT * FROM (VALUES (1), (5), (10), (20), (30), (50))),
rank_ AS (
    SELECT u.minimo, i.inversionista_id,
           ROW_NUMBER() OVER (PARTITION BY u.minimo ORDER BY i.tasa_v1   DESC, i.n_empresas DESC, i.inversionista_id) AS r_v1,
           ROW_NUMBER() OVER (PARTITION BY u.minimo ORDER BY i.tasa_v2   DESC, i.n_empresas DESC, i.inversionista_id) AS r_v2,
           ROW_NUMBER() OVER (PARTITION BY u.minimo ORDER BY i.exceso_v1 DESC, i.n_empresas DESC, i.inversionista_id) AS r_ex1
    FROM umbrales u
    JOIN marts.dash_inversionista i ON i.n_empresas >= u.minimo
)
SELECT
    CAST(minimo AS INTEGER)                                                   AS minimo_empresas,
    CAST(COUNT(*) AS INTEGER)                                                 AS elegibles,
    CAST(COUNT(*) FILTER (WHERE r_v1 <= 10 AND r_v2  <= 10) AS INTEGER)       AS top10_v1_tambien_en_v2,
    CAST(COUNT(*) FILTER (WHERE r_v1 <= 10 AND r_ex1 <= 10) AS INTEGER)       AS top10_v1_tambien_en_exceso
FROM rank_
GROUP BY minimo
ORDER BY minimo;
