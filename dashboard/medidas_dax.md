# Medidas DAX del dashboard

Todas las medidas viven en una tabla vacía llamada `_Medidas` (*Inicio → Especificar datos*, una columna, se oculta después). Cada bloque indica la métrica de `docs/diccionario_metricas.md` que implementa: el dashboard no define métricas nuevas, solo las calcula según los filtros.

Regla general: las tasas se calculan **sumando numeradores y denominadores**, nunca promediando tasas de celdas distintas.

## Tablas auxiliares

```dax
-- Parámetro numérico: Modelado → Nuevo parámetro → Rango numérico
-- Nombre: Portafolio mínimo · mínimo 1 · máximo 100 · incremento 1 · predeterminado 50
-- Power BI crea la tabla y esta medida:
Valor Portafolio mínimo = SELECTEDVALUE ( 'Portafolio mínimo'[Portafolio mínimo], 50 )

-- Tabla para la leyenda de las curvas de salida (Modelado → Nueva tabla)
Horizonte = DATATABLE ( "Años", INTEGER, { { 1 }, { 3 }, { 5 } } )
```

**Por qué 50 empresas como mínimo predeterminado.** Con una tasa de éxito cercana a 20 %, el error estándar de la tasa de un portafolio de *n* empresas es √(0.2·0.8/*n*): 18 puntos con 5 empresas, 9 con 20 y 5.7 con 50. Para distinguir a un inversionista que supera su benchmark por 10 puntos hace falta un error de unos 5 puntos, o sea unas 50 empresas. La página deja mover el mínimo para ver cómo cambia el ranking (Análisis 2).

## 1. Financiamiento total (diccionario §1)

```dax
Rondas = COUNTROWS ( fact_rondas )

Rondas con monto = COUNT ( fact_rondas[monto_usd] )

-- NULL = monto desconocido: SUM lo ignora, nunca se imputa cero
Financiamiento USD = SUM ( fact_rondas[monto_usd] )

Cobertura de monto =
DIVIDE (
    SUM ( dash_industria_etapa[rondas_con_monto] ),
    SUM ( dash_industria_etapa[rondas] )
)

-- financiamiento de las empresas de las cohortes 2005-2013 (responde a todos los filtros)
Financiamiento cohortes USD = SUM ( dash_industria_etapa[financiamiento_usd] )

% del capital =
DIVIDE (
    [Financiamiento cohortes USD],
    CALCULATE ( [Financiamiento cohortes USD], ALL ( dash_dim_industria ) )
)

Empresas = SUM ( dash_industria_etapa[empresas] )

% de las empresas =
DIVIDE ( [Empresas], CALCULATE ( [Empresas], ALL ( dash_dim_industria ) ) )

-- la cola es muy pesada: mediana, no promedio
Financiamiento mediano por empresa =
CALCULATE (
    MEDIAN ( met_financiamiento_empresa[financiamiento_total_usd] ),
    met_financiamiento_empresa[es_registro_faltante] = FALSE ()
)
```

## 2. Éxito de una startup con plazo observable (diccionario §2, Análisis 1)

Una empresa entra al denominador de un horizonte solo si su primera ronda más ese horizonte cae antes del 2013-12-31. La salida cuenta solo si ocurre en o después de la primera ronda.

```dax
Observables 1a = SUM ( dash_industria_etapa[observables_1a] )
Observables 3a = SUM ( dash_industria_etapa[observables_3a] )
Observables 5a = SUM ( dash_industria_etapa[observables_5a] )

Tasa salida 1a = DIVIDE ( SUM ( dash_industria_etapa[salidas_1a] ), [Observables 1a] )
Tasa salida 3a = DIVIDE ( SUM ( dash_industria_etapa[salidas_3a] ), [Observables 3a] )
Tasa salida 5a = DIVIDE ( SUM ( dash_industria_etapa[salidas_5a] ), [Observables 5a] )

-- definición alternativa (sensibilidad): la salida trae monto conocido en USD
Tasa salida 5a con monto =
DIVIDE ( SUM ( dash_industria_etapa[salidas_5a_con_monto] ), [Observables 5a] )

-- no se muestra una tasa calculada sobre menos de 100 empresas observables
Tasa salida 5a (confiable) = IF ( [Observables 5a] >= 100, [Tasa salida 5a] )

-- para la gráfica de curvas por cohorte, con Horizonte[Años] en la leyenda;
-- las cohortes sin plazo cumplido quedan en blanco (no cuentan como fracaso)
Tasa salida (horizonte) =
SWITCH (
    SELECTEDVALUE ( Horizonte[Años] ),
    1, IF ( [Observables 1a] >= 100, [Tasa salida 1a] ),
    3, IF ( [Observables 3a] >= 100, [Tasa salida 3a] ),
    5, IF ( [Observables 5a] >= 100, [Tasa salida 5a] )
)

Tasa de segunda ronda =
DIVIDE ( SUM ( dash_industria_etapa[con_segunda_ronda] ), [Empresas] )

Brecha vs promedio 5a =
[Tasa salida 5a] - CALCULATE ( [Tasa salida 5a], ALL ( dash_dim_industria ) )
```

## 3. Inversionistas (diccionario §4, §5 y §6, Análisis 2)

```dax
Empresas en portafolio = COUNTROWS ( dash_portafolio )

Salidas V1 =
CALCULATE ( COUNTROWS ( dash_portafolio ), dash_portafolio[exito_v1] = TRUE () )

Rondas posteriores V2 =
CALCULATE ( COUNTROWS ( dash_portafolio ), dash_portafolio[exito_v2] = TRUE () )

Tasa éxito V1 = DIVIDE ( [Salidas V1], [Empresas en portafolio] )
Tasa éxito V2 = DIVIDE ( [Rondas posteriores V2], [Empresas en portafolio] )

-- benchmark: misma industria, etapa de entrada y año de entrada
Benchmark V1 = AVERAGE ( dash_portafolio[bench_v1] )
Benchmark V2 = AVERAGE ( dash_portafolio[bench_v2] )

Exceso V1 = [Tasa éxito V1] - [Benchmark V1]
Exceso V2 = [Tasa éxito V2] - [Benchmark V2]

Cumple mínimo =
IF ( [Empresas en portafolio] >= [Valor Portafolio mínimo], 1, 0 )

Tasa éxito V1 (confiable) = IF ( [Cumple mínimo] = 1, [Tasa éxito V1] )
Exceso V1 (confiable)     = IF ( [Cumple mínimo] = 1, [Exceso V1] )

Inversionistas activos =
CALCULATE ( COUNTROWS ( dash_inversionista ), dash_inversionista[es_activo] = TRUE () )

Inversionistas elegibles =
COUNTROWS (
    FILTER (
        VALUES ( dash_inversionista[inversionista_id] ),
        [Empresas en portafolio] >= [Valor Portafolio mínimo]
    )
)

% que supera su benchmark =
VAR elegibles =
    FILTER (
        VALUES ( dash_inversionista[inversionista_id] ),
        [Empresas en portafolio] >= [Valor Portafolio mínimo]
    )
RETURN
    DIVIDE ( COUNTROWS ( FILTER ( elegibles, [Exceso V1] > 0 ) ), COUNTROWS ( elegibles ) )

Ranking exceso V1 =
IF (
    [Cumple mínimo] = 1,
    RANKX (
        FILTER (
            ALLSELECTED ( dash_inversionista ),
            [Empresas en portafolio] >= [Valor Portafolio mínimo]
        ),
        [Exceso V1], , DESC, SKIP
    )
)
```

Notas:

- Con el segmentador de industria, las tasas y el benchmark se recalculan solo con las empresas del portafolio en esa industria.
- La tabla de la página 2 usa `dash_inversionista[etiqueta]`, no `nombre`: hay 150 nombres repetidos entre inversionistas distintos.

## 4. Ciclos de mercado (Análisis b)

```dax
-- suma de los coeficientes de los rezagos del NASDAQ en el modelo B (cambios anuales)
Efecto acumulado NASDAQ =
CALCULATE (
    SUM ( res_ciclos_mercado_coef[coeficiente] ),
    res_ciclos_mercado_coef[modelo] = "B_cambios_monto",
    LEFT ( res_ciclos_mercado_coef[termino], 8 ) = "g_nasdaq"
)

Financiamiento mensual (miles de millones) =
DIVIDE ( SUM ( res_ciclos_mercado_panel[monto_total_usd] ), 1e9 )

NASDAQ promedio = AVERAGE ( res_ciclos_mercado_panel[nasdaqcom] )
```

## Formatos

| Medida | Formato |
|---|---|
| Tasas, `% del capital`, `Cobertura de monto`, `Exceso` | Porcentaje, 1 decimal |
| `Financiamiento ... USD` | Moneda, unidades automáticas (mil M) |
| `Efecto acumulado NASDAQ` | Decimal, 2 decimales |
| Conteos | Número entero con separador de miles |
