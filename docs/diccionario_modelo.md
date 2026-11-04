# Diccionario del modelo dimensional (esquema `marts`)

Modelo en estrella con 3 tablas de hechos que comparten dimensiones conformadas
(empresa, inversionista, fecha), una tabla puente para la relación ronda–inversionista
y una serie externa mensual para el análisis (b) de ciclos de mercado.
Origen: esquema `clean` en DuckDB. Código: `sql/04_marts/`.

Convenciones:
- Montos `*_usd`: solo tienen valor si la moneda original era USD. `NULL` = desconocido, no cero.
- Fechas posteriores a 2013-12-31 son `NULL` (corte de Crunchbase).
- `sin_dato` reemplaza nulos en atributos de segmentación para que los filtros del dashboard no pierdan filas.

---

## dim_empresa
**Grano:** una fila por empresa (`objects` con `entity_type = 'Company'`). **Filas:** 197,560
**PK:** `empresa_id`

| Columna | Tipo | Descripción |
|---|---|---|
| empresa_id | VARCHAR | Id de Crunchbase con prefijo `c:` |
| nombre | VARCHAR | Nombre de la empresa |
| industria | VARCHAR | `category_code` de Crunchbase; `sin_dato` si falta |
| pais | VARCHAR | Código de país ISO-3; `sin_dato` si falta |
| region | VARCHAR | Región o ciudad principal reportada |
| estatus | VARCHAR | operating, acquired, ipo, closed |
| fecha_fundacion | DATE | Fecha de fundación |
| anio_fundacion | BIGINT | Año de fundación (cohorte por fundación) |
| fecha_primera_ronda | DATE | Fecha mínima en `fact_rondas`; `NULL` si nunca levantó capital |
| anio_primera_ronda | BIGINT | Año de primera ronda (cohorte de las curvas de salida) |
| etapa | VARCHAR | Tipo de la última ronda; `sin_rondas` si nunca levantó capital |
| es_registro_faltante | BOOLEAN | `TRUE` si es un registro de reemplazo creado en limpieza para evitar FK huérfanas |

Nota: el 84% (165,825) nunca levantó una ronda. Para tasas de éxito, el universo son las empresas con `fecha_primera_ronda` no nula.

---

## dim_inversionista
**Grano:** una fila por inversionista que participa en al menos una ronda. **Filas:** 17,152
**PK:** `inversionista_id`

| Columna | Tipo | Descripción |
|---|---|---|
| inversionista_id | VARCHAR | Id con prefijo `f:` (organización financiera), `c:` (empresa) o `p:` (persona) |
| nombre | VARCHAR | Nombre del inversionista |
| tipo_inversionista | VARCHAR | organizacion_financiera (44%), persona (40%), corporativo (15%) |
| pais | VARCHAR | País del inversionista; `sin_dato` si falta |
| industria | VARCHAR | `category_code` del inversionista; `sin_dato` si falta |
| es_registro_faltante | BOOLEAN | `TRUE` si es registro de reemplazo |

Solo atributos descriptivos. Actividad y éxito se calculan según `docs/diccionario_metricas.md`.

---

## dim_fecha
**Grano:** una fila por día calendario, de 1901-01-01 a 2013-12-31. **Filas:** 41,273
**PK:** `fecha`

| Columna | Tipo | Descripción |
|---|---|---|
| fecha | DATE | Día calendario |
| anio | SMALLINT | Año |
| trimestre | SMALLINT | 1 a 4 |
| mes | SMALLINT | 1 a 12 |
| anio_mes | DATE | Primer día del mes; llave para unir con `serie_externa_mensual` |
| etiqueta_mes | VARCHAR | Texto `YYYY-MM` para ejes del dashboard |

---

## fact_rondas
**Grano:** una fila por ronda de financiamiento. **Filas:** 52,928
**PK:** `ronda_id` · **FK:** `empresa_id` → dim_empresa, `fecha` → dim_fecha

| Columna | Tipo | Descripción |
|---|---|---|
| ronda_id | INTEGER | `funding_round_id` de Crunchbase |
| empresa_id | VARCHAR | Empresa que levantó la ronda |
| fecha | DATE | Fecha de la ronda |
| tipo_ronda | VARCHAR | angel, venture, series-a, series-b, series-c+, private-equity, crowdfunding, post-ipo, other |
| codigo_ronda | VARCHAR | Código detallado (a, b, c, seed…) |
| monto_usd | DECIMAL(18,2) | Monto levantado en USD; `NULL` en 11% de rondas |
| valuacion_pre_usd | DECIMAL(18,2) | Valuación pre-money en USD |
| valuacion_post_usd | DECIMAL(18,2) | Valuación post-money en USD |
| participantes_reportados | INTEGER | Participantes según Crunchbase |
| n_inversionistas | BIGINT | Inversionistas registrados en `investments` para la ronda (0 si ninguno) |
| es_primera_ronda | BOOLEAN | Primera ronda de la empresa |
| es_ultima_ronda | BOOLEAN | Última ronda registrada de la empresa |

**Única tabla donde vive el monto de la ronda.** Total: US$420.6 mil millones.

---

## puente_ronda_inversionista
**Grano:** una fila por par (ronda, inversionista). **Filas:** 80,800
**PK:** (`ronda_id`, `inversionista_id`) · **FK:** `ronda_id` → fact_rondas, `inversionista_id` → dim_inversionista

| Columna | Tipo | Descripción |
|---|---|---|
| ronda_id | INTEGER | Ronda |
| inversionista_id | VARCHAR | Inversionista que participó |
| peso | DOUBLE | 1 / número de inversionistas de la ronda; los pesos de cada ronda suman 1 |

**Uso correcto:**
- Monto atribuido a un inversionista = `fact_rondas.monto_usd * peso`.
- Participación (en cuántas rondas entró) = `COUNT(DISTINCT ronda_id)`, sin peso.

**Verificación:** total desde fact_rondas (rondas con inversionistas) = US$306.4 mil millones; total por el puente con peso = US$306.4 mil millones; sin peso = US$938.5 mil millones (inflado 3 veces).

---

## fact_adquisiciones
**Grano:** una fila por adquisición. **Filas:** 9,561
**PK:** `adquisicion_id` · **FK:** `empresa_adquirida_id` y `empresa_adquirente_id` → dim_empresa (dimensión de rol), `fecha` → dim_fecha

| Columna | Tipo | Descripción |
|---|---|---|
| adquisicion_id | INTEGER | `acquisition_id` de Crunchbase |
| empresa_adquirida_id | VARCHAR | Empresa comprada |
| empresa_adquirente_id | VARCHAR | Empresa compradora |
| fecha | DATE | Fecha de la adquisición (`NULL` en 29 casos) |
| forma_pago | VARCHAR | cash, stock, cash_and_stock |
| precio_usd | DECIMAL(18,2) | Precio en USD; solo 26% lo tiene |

Nota: 150 empresas aparecen adquiridas más de una vez; las métricas de éxito usan la primera salida.

---

## fact_ipos
**Grano:** una fila por IPO. **Filas:** 1,254
**PK:** `ipo_id` · **FK:** `empresa_id` → dim_empresa, `fecha` → dim_fecha

| Columna | Tipo | Descripción |
|---|---|---|
| ipo_id | INTEGER | `ipo_id` de Crunchbase |
| empresa_id | VARCHAR | Empresa que salió a bolsa |
| fecha | DATE | Fecha de la IPO; `NULL` en 47% de casos |
| simbolo_bursatil | VARCHAR | Ticker |
| monto_levantado_usd | DECIMAL(18,2) | Casi vacío (132 filas); no usar para montos |
| valuacion_usd | DECIMAL(18,2) | Casi vacío; no usar para montos |

Usar para conteo de salidas y fecha, no para montos.

---

## serie_externa_mensual
**Grano:** una fila por mes calendario. **Filas:** 288 (1990-01 a 2013-12)
**PK:** `anio_mes` · **Une con:** `dim_fecha.anio_mes`
**Fuente:** FRED (Federal Reserve Bank of St. Louis), descargada el 2026-11-02. Detalle en `data/external/README.md`. SQL: `sql/04_marts/08_serie_externa_mensual.sql`.

| Columna | Tipo | Descripción |
|---|---|---|
| anio_mes | DATE | Primer día del mes |
| nasdaqcom | DOUBLE | NASDAQ Composite (NASDAQCOM); serie diaria promediada al mes; índice |
| fedfunds | DOUBLE | Tasa de fondos federales (FEDFUNDS); mensual; % anual |
| unrate | DOUBLE | Tasa de desempleo de EE. UU. (UNRATE); mensual; % |

Cubre todo el periodo de Crunchbase (corte 2013-12-31), con 12 meses de margen al inicio para construir rezagos. Sin valores faltantes. Sostiene el análisis (b), financiamiento y ciclos de mercado.
