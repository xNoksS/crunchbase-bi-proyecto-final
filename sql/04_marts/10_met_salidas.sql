CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- METRICAS: EXITO DE UNA STARTUP y TIEMPO A LA SALIDA
--           (Hugo - analista de startups e industrias)
-- Fichas completas en docs/diccionario_metricas.md
--
-- EXITO DE UNA STARTUP
--   Una empresa es exitosa si tuvo al menos una SALIDA con fecha <= 2013-12-31:
--   una adquisicion (aparece como empresa adquirida) o una IPO. Las dos cuentan.
--   NO se exige monto minimo: 7,085 de 9,561 adquisiciones no reportan precio en
--   USD y los montos de IPO estan casi vacios (bitacora, filas 12 y 13); exigir
--   monto borraria tres de cada cuatro salidas reales.
--   Version alternativa, para sensibilidad: exito_con_monto = la salida ademas
--   trae monto conocido en USD. Se publica como columna aparte, no reemplaza.
--
-- TIEMPO A LA SALIDA
--   Se mide desde la PRIMERA RONDA, no desde la fundacion: founded_at es NULL en
--   el 54% de las empresas (bitacora, fila 2), asi que medir desde fundacion
--   perderia mas de la mitad de los casos. Se publica tambien el tiempo desde
--   fundacion, para el subconjunto que si la tiene, como control.
--   Las empresas sin salida al 2013-12-31 estan CENSURADAS POR LA DERECHA:
--   no son fracasos, es que todavia no se observa el desenlace. Nunca entran al
--   promedio de tiempo a la salida; se cuentan aparte con censurada = TRUE.
-- =====================================================================

-- ---------------------------------------------------------------------
-- met_salida_empresa
-- Grano: una fila por empresa de dim_empresa (incluidas las que nunca
-- levantaron capital y las que nunca salieron).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.met_salida_empresa AS
WITH salidas AS (
    SELECT empresa_adquirida_id AS empresa_id,
           fecha,
           'adquisicion'        AS tipo,
           precio_usd           AS monto_usd
    FROM marts.fact_adquisiciones
    WHERE fecha IS NOT NULL
    UNION ALL
    SELECT empresa_id,
           fecha,
           'ipo'                AS tipo,
           monto_levantado_usd  AS monto_usd
    FROM marts.fact_ipos
    WHERE fecha IS NOT NULL
),
-- Se usa ROW_NUMBER y no arg_min(monto, fecha) a proposito: arg_min descarta las
-- filas con monto NULL, asi que devolveria el monto de una salida POSTERIOR
-- cuando la primera no reporta monto. Aqui la fila 1 es siempre la mas antigua.
ordenadas AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY empresa_id ORDER BY fecha, tipo) AS rn
    FROM salidas s
),
agregado AS (
    SELECT
        empresa_id,
        COUNT(*)                            AS n_salidas,
        COUNT(monto_usd)                    AS n_salidas_con_monto
    FROM salidas
    GROUP BY empresa_id
),
primera AS (
    SELECT
        o.empresa_id,
        o.fecha                             AS fecha_primera_salida,
        o.tipo                              AS tipo_primera_salida,
        o.monto_usd                         AS monto_primera_salida_usd,
        a.n_salidas,
        a.n_salidas_con_monto
    FROM ordenadas o
    JOIN agregado a ON a.empresa_id = o.empresa_id
    WHERE o.rn = 1
),
primera_ronda AS (
    SELECT empresa_id, MIN(fecha) AS fecha_primera_ronda
    FROM marts.fact_rondas
    WHERE fecha IS NOT NULL
    GROUP BY empresa_id
)
SELECT
    e.empresa_id,
    e.nombre,
    e.industria,
    e.pais,
    e.etapa,
    e.fecha_fundacion,
    pr.fecha_primera_ronda,
    year(pr.fecha_primera_ronda)                            AS cohorte_primera_ronda,
    s.fecha_primera_salida,
    s.tipo_primera_salida,
    s.monto_primera_salida_usd,
    COALESCE(s.n_salidas, 0)                                AS n_salidas,
    -- exito (definicion principal): hubo al menos una salida observada
    (s.fecha_primera_salida IS NOT NULL)                    AS tuvo_salida,
    -- exito (definicion alternativa, mas estricta): la salida trae monto en USD
    COALESCE(s.n_salidas_con_monto, 0) > 0                  AS tuvo_salida_con_monto,
    -- censura: sin salida observada al corte de los datos
    (s.fecha_primera_salida IS NULL)                        AS censurada,
    -- tiempo a la salida desde la primera ronda (metrica principal)
    CASE WHEN s.fecha_primera_salida IS NOT NULL
              AND pr.fecha_primera_ronda IS NOT NULL
         THEN date_diff('day', pr.fecha_primera_ronda, s.fecha_primera_salida)
    END                                                     AS dias_a_salida_desde_ronda,
    CASE WHEN s.fecha_primera_salida IS NOT NULL
              AND pr.fecha_primera_ronda IS NOT NULL
         THEN date_diff('day', pr.fecha_primera_ronda, s.fecha_primera_salida) / 365.25
    END                                                     AS anios_a_salida_desde_ronda,
    -- tiempo a la salida desde la fundacion (control, solo donde hay founded_at)
    CASE WHEN s.fecha_primera_salida IS NOT NULL
              AND e.fecha_fundacion IS NOT NULL
         THEN date_diff('day', e.fecha_fundacion, s.fecha_primera_salida) / 365.25
    END                                                     AS anios_a_salida_desde_fundacion,
    -- antiguedad observada de las censuradas: cuanto llevamos mirandolas sin salida
    CASE WHEN s.fecha_primera_salida IS NULL
              AND pr.fecha_primera_ronda IS NOT NULL
         THEN date_diff('day', pr.fecha_primera_ronda, DATE '2013-12-31') / 365.25
    END                                                     AS anios_observados_sin_salida,
    e.es_registro_faltante
FROM marts.dim_empresa e
LEFT JOIN primera_ronda pr ON pr.empresa_id = e.empresa_id
LEFT JOIN primera       s  ON s.empresa_id  = e.empresa_id;
