# Dashboard (Parte 5)

**Responsable:** Jose (BI y storytelling) · **Herramienta:** Power BI Desktop · **Fuente:** Neon, esquema `marts`, rol de solo lectura `bi_lectura`.

El dashboard lee solo tablas de Neon, nunca CSV. Las tablas que alimentan cada vista se generan en `sql/04_marts/20_dash_inversionistas.sql`, `21_dash_industrias.sql` y `22_dash_dimensiones.sql`, más los resultados de Hugo (`res_*`). Las medidas DAX están en [`medidas_dax.md`](medidas_dax.md).

## Archivos

| Archivo | Qué es |
|---|---|
| `crunchbase_bi.pbix` | El dashboard (se sube al terminar; no guarda la contraseña) |
| `capturas/pagina_1.png` … `pagina_3.png` | Capturas de cada página para el memo y la entrega |
| `medidas_dax.md` | Todas las medidas, con la métrica del diccionario de la que sale cada una |

## Cómo conectarlo a Neon

1. Correr el pipeline en orden: `python run_all.py` → notebooks de Hugo → `python publish/publish_to_neon.py`.
2. En Power BI Desktop: **Obtener datos → Base de datos PostgreSQL**.
   - **Servidor:** el host de la cadena de `bi_lectura`, sin `-pooler` (por ejemplo `ep-xxxx.us-east-2.aws.neon.tech`).
   - **Base de datos:** el nombre que viene en la cadena (normalmente `neondb`).
   - **Modo:** *Importar*. Neon suspende el cómputo tras unos minutos; con *DirectQuery* cada clic esperaría a que despierte.
3. Credenciales: pestaña **Base de datos**, usuario `bi_lectura` y su contraseña. Nunca se escriben en el repo.
   - Si aparece un error de SNI o de *endpoint ID*, escribir la contraseña como `endpoint=<id_del_endpoint>;<contraseña>` (el id es la primera parte del host, `ep-xxxx`).
4. Seleccionar estas tablas del esquema `marts`:

| Tabla | Grano | Para qué página |
|---|---|---|
| `fact_rondas` | una ronda | 1 y 3 |
| `dim_empresa` | una empresa | 1 y 3 |
| `dim_fecha` | un día | 3 |
| `met_financiamiento_empresa` | una empresa con rondas | 1 y 3 |
| `dash_industria_etapa` | industria × país × etapa de entrada × cohorte | 1 y 3 |
| `dash_portafolio` | inversionista × empresa | 2 |
| `dash_inversionista` | un inversionista | 2 |
| `dash_sensibilidad_top10` | un tamaño mínimo de portafolio | 2 |
| `dash_dim_industria`, `dash_dim_etapa`, `dash_dim_pais`, `dash_dim_cohorte` | filtros compartidos | 1, 2 y 3 |
| `res_ciclos_mercado_panel`, `res_ciclos_mercado_coef` | un mes / un coeficiente | 1 y 3 |

## Modelo en Power BI

Relaciones, todas de uno a varios y en una sola dirección (de la dimensión al hecho):

```
dash_dim_industria[industria] ─┬─> dim_empresa[industria] ─┬─> fact_rondas[empresa_id]
                               │                           └─> met_financiamiento_empresa[empresa_id]
                               ├─> dash_industria_etapa[industria]
                               └─> dash_portafolio[industria]
dash_dim_etapa[etapa]  ────────┬─> dash_industria_etapa[etapa_entrada]
                               ├─> dash_portafolio[etapa_entrada]
                               └─> met_financiamiento_empresa[tipo_primera_ronda]
dash_dim_pais[pais]    ────────┬─> dim_empresa[pais]
                               └─> dash_industria_etapa[pais]
dash_dim_cohorte[cohorte] ─────┬─> dash_industria_etapa[cohorte]
                               └─> met_financiamiento_empresa[cohorte_primera_ronda]
dim_fecha[fecha]       ──────────> fact_rondas[fecha]
dash_inversionista[inversionista_id] ──> dash_portafolio[inversionista_id]
```

- `dash_portafolio` **no** se relaciona con `dim_empresa`: tendría dos caminos desde `dash_dim_industria` y Power BI marcaría la relación como ambigua.
- Ordenar `dash_dim_etapa[etapa]` por la columna `orden` (*Herramientas de columna → Ordenar por columna*).
- Ocultar en la vista de informe las columnas de llave (`*_id`) y los campos crudos que ya tienen medida.
- Crear dos tablas auxiliares: el parámetro **Portafolio mínimo** y la tabla **Horizonte** (en `medidas_dax.md`).

## Las tres páginas

Cada título enuncia la conclusión, no el tema. Las cifras entre corchetes son las de la versión actual de los datos: hay que verificarlas después de la última corrida del pipeline.

### Página 1 · Resumen ejecutivo (comité de inversión)

**Mensaje:** entrar en Serie A o B y sesgar hacia software e internet; elegir coinversionistas por su exceso sobre el benchmark.

| # | Visual | Campos / medidas | Título |
|---|---|---|---|
| 1 | Tarjeta de varias filas | `[Empresas]`, `[Tasa salida 5a]`, `[Financiamiento cohortes USD]`, `[Cobertura de monto]`, `[Efecto acumulado NASDAQ]` | Cifras clave, cohortes 2005–2013 |
| 2 | Barras horizontales | Eje `dash_dim_etapa[etapa]` · `[Tasa salida 5a (confiable)]` · tooltip `[Financiamiento mediano por empresa]` | Entrar en Serie A da más salidas que entrar como ángel [15.2 % vs 10.5 %] |
| 3 | Barras agrupadas | Eje `dash_dim_industria[grupo]` · `[Tasa salida 5a]` y `[Tasa salida 5a con monto]` · tooltip `[% del capital]` | Software e internet sale casi el doble [17.0 % vs 9.8 %], pero no con salidas más grandes |
| 4 | Cuadro de texto | Las 3 recomendaciones del memo, con la página que respalda cada una | Qué recomendamos |

Filtro de página: `dash_dim_cohorte[cohorte]` de 2005 a 2013 (fijo, no visible).

### Página 2 · Ficha de inversionistas (socios que evalúan con quién coinvertir)

**Mensaje:** el top 10 cambia casi por completo con la definición de éxito; lo estable es el exceso sobre el benchmark con portafolios grandes.

Segmentadores: `Portafolio mínimo` (predeterminado 50), `dash_inversionista[tipo_inversionista]`, `dash_dim_industria[industria]`, `dash_inversionista[es_activo]`.

| # | Visual | Campos / medidas | Título |
|---|---|---|---|
| 1 | Tarjetas | `[Inversionistas elegibles]`, `[% que supera su benchmark]` | [119 de 146] inversionistas grandes superan su benchmark |
| 2 | Dispersión | X `[Benchmark V1]` · Y `[Tasa éxito V1 (confiable)]` · tamaño `[Empresas en portafolio]` · detalle `dash_inversionista[etiqueta]` · línea de proporción 1:1 | Arriba de la diagonal: rinden más que el mercado en sus mismos sectores, etapas y años |
| 3 | Tabla | `etiqueta`, `[Empresas en portafolio]`, `[Tasa éxito V1]`, `[Benchmark V1]`, `[Exceso V1]`, `[Tasa éxito V2]`, `[Exceso V2]`, `[Ranking exceso V1]` · filtro: Ranking ≤ 15 | Los 15 con mayor exceso sobre su benchmark |
| 4 | Columnas agrupadas | Eje `dash_sensibilidad_top10[minimo_empresas]` · `top10_v1_tambien_en_v2`, `top10_v1_tambien_en_exceso` | Con otra definición de éxito el top 10 conserva [1] nombre de 10 |

### Página 3 · Explorador de startups e industrias (analistas del fondo)

**Mensaje:** dónde salen las startups, cuánto capital consumen y cómo se mueve el financiamiento con el mercado.

Segmentadores: `dash_dim_industria[industria]`, `dash_dim_pais[pais]`, `dash_dim_etapa[etapa]`, `dash_dim_cohorte[cohorte]`.

| # | Visual | Campos / medidas | Título |
|---|---|---|---|
| 1 | Matriz con formato condicional | Filas `industria` · columnas `etapa` · valor `[Tasa salida 5a (confiable)]` · tooltip `[Observables 5a]` | Web y mobile en Serie A tienen las tasas de salida más altas con muestra suficiente |
| 2 | Líneas (vista de cohortes) | Eje `dash_dim_cohorte[cohorte]` · valor `[Tasa salida (horizonte)]` · leyenda `Horizonte[Años]` | La tasa a 3 años es estable; la de 5 años cae de [17.6 % a 10.9 %] (cohortes sin plazo cumplido, en blanco) |
| 3 | Barras | Eje `dash_dim_industria[industria]` · `[Financiamiento cohortes USD]` · tooltip `[% del capital]`, `[Cobertura de monto]` | Biotech y cleantech concentran [30 %] del capital con [17 %] de las empresas |
| 4 | Líneas con dos ejes | Eje `res_ciclos_mercado_panel[anio_mes]` · `[Financiamiento mensual (miles de millones)]` y `[NASDAQ promedio]` | El financiamiento sigue al NASDAQ con un mes de rezago (efecto acumulado [1.84]) |

## Trazabilidad: de cada gráfica a su métrica

| Página · visual | Medida | Métrica del diccionario (`docs/diccionario_metricas.md`) |
|---|---|---|
| 1·1, 3·3 | `[Financiamiento cohortes USD]`, `[Cobertura de monto]` | 1. Financiamiento total |
| 1·2, 1·3, 3·1, 3·2 | `[Tasa salida Na]` | 2. Éxito de una startup, con plazo observable (Análisis 1) |
| 1·2 tooltip | `[Financiamiento mediano por empresa]` | 1. Financiamiento total |
| 2·1, 2·3 | `[Inversionistas elegibles]`, `es_activo` | 4. Inversionista activo |
| 2·2, 2·3 | `[Tasa éxito V1]`, `[Tasa éxito V2]` | 5. Éxito de un inversionista (dos versiones) |
| 2·2, 2·3 | `[Benchmark V1]`, `[Exceso V1]` | 6. Benchmark de inversionista |
| 2·4 | `dash_sensibilidad_top10` | Análisis 2: sensibilidad del ranking |
| 1·1, 3·4 | `[Efecto acumulado NASDAQ]` | Análisis (b): ciclos de mercado |

## Lista de revisión antes de entregar

- [ ] Refrescar con la última publicación en Neon y revisar que las cifras entre corchetes de los títulos coincidan.
- [ ] Cada página tiene entre 3 y 5 visuales y se entiende sin explicación oral.
- [ ] Los filtros funcionan entre páginas (sincronizar segmentadores de industria y cohorte).
- [ ] Probar con Neon "dormido": la primera actualización tarda unos segundos.
- [ ] Guardar el `.pbix` sin credenciales y exportar las tres capturas a `dashboard/capturas/`.
