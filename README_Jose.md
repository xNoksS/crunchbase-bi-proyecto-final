# Contribución individual y uso de IA — Jose Sierra

Proyecto Final 2026 · Financiamiento de Startups (Crunchbase) · Business Intelligence · Universidad del Istmo

## 1. Rol en el equipo

BI y *storytelling*. Me encargué de convertir los resultados del pipeline en algo que el comité de inversión pueda leer y usar: las tablas que alimentan el dashboard, el dashboard de tres páginas conectado a Neon, el memo ejecutivo y la coordinación de la presentación. También revisé el pull request de Hugo.

## 2. Qué hice

### Tablas que alimentan el dashboard (`sql/04_marts/`)
| Archivo | Tablas | Qué resuelven |
|---|---|---|
| `20_dash_inversionistas.sql` | `dash_portafolio`, `dash_inversionista`, `dash_sensibilidad_top10` | Portafolio de cada inversionista con sus dos definiciones de éxito (V1 salida, V2 ronda posterior) y un benchmark por industria × etapa de entrada × año (con respaldo a etapa × año si la celda tiene menos de 10 empresas). Etiqueta única por inversionista, porque hay 150 nombres repetidos. |
| `21_dash_industrias.sql` | `dash_industria_etapa` | Empresas, rondas, financiamiento y salidas a 1, 3 y 5 años por industria × país × etapa de entrada × cohorte (2005-2013), contando solo empresas con plazo observable y solo salidas en o después de la primera ronda. |
| `22_dash_dimensiones.sql` | `dash_dim_industria`, `dash_dim_etapa`, `dash_dim_pais`, `dash_dim_cohorte` | Dimensiones compartidas para que los filtros funcionen en todas las páginas (grupo de industria, orden de las etapas, plazos cumplidos por cohorte). |

Decisión clave: el benchmark usa la **etapa de la ronda de entrada** del inversionista, no `dim_empresa.etapa`, porque esa es la última ronda de la empresa e incluye información del futuro.

### Publicación en Neon
Extendí `publish/publish_to_neon.py` con las llaves primarias de las tablas `met_*`, `res_*` y `dash_*`, y con los tipos que no traducía (`HUGEINT`, `TIMESTAMP_NS`). Corregí el mensaje del límite de tamaño a 0.5 GB.

### Dashboard (Power BI, conectado a Neon con el rol `bi_lectura`)
- **Modelo:** 14 tablas del esquema `marts`, 14 relaciones de uno a varios en una sola dirección, el parámetro *Portafolio mínimo* y la tabla *Horizonte*.
- **Medidas DAX** (`dashboard/medidas_dax.md`): 39 medidas, cada una trazable a una métrica de `docs/diccionario_metricas.md`. Las tasas se calculan sumando numeradores y denominadores, nunca promediando tasas.
- **Páginas:** Resumen ejecutivo (comité), Ficha de inversionistas (socios) y Explorador de startups (analistas). Cada título enuncia la conclusión, no el tema.
- Capturas en `dashboard/capturas/` y exportación en PDF.

### Memo ejecutivo y presentación
- `docs/memo_ejecutivo.md` y su PDF de una página: tres recomendaciones con la vista del dashboard que respalda cada una y las limitaciones de los datos.
- Esqueleto de la presentación de 15 minutos y reparto de tiempos.

### Revisión del PR de Hugo (`hugo/fred`)
Corrí su rama desde cero y pedí cambios por tres puntos:
1. `publish_to_neon.py` no subía sus tablas (faltaban llaves y dos tipos).
2. 202 empresas tenían su primera salida **antes** de su primera ronda y daban tiempos negativos; inflaban las tasas a 1 año de las cohortes recientes (2010: 2.5 % → 1.6 %).
3. Un comentario del SQL y de `docs/limitaciones.md` decía lo contrario de lo que hacía el código.

También le sugerí reportar el error estándar del efecto acumulado del NASDAQ (1.84, IC 95 % 0.84 a 2.84).

## 3. Problemas que encontré y cómo se resolvieron

- **Conexión de DuckDB abierta en Colab:** daba `CatalogException` aunque la tabla existía. Se resolvió reiniciando la sesión y usando `with duckdb.connect(...) as con:`.
- **Relaciones ambiguas en Power BI:** relacionar `dash_portafolio` con `dim_empresa` creaba dos caminos desde la dimensión de industria. Se dejó sin esa relación.
- **Campos de tablas sin relación en un mismo visual:** la gráfica del NASDAQ salía plana porque el eje usaba la fecha de `dim_fecha` en vez de `res_ciclos_mercado_panel[anio_mes]`.
- **Informe sin guardar:** perdí la primera versión de las páginas por no guardarlas en Power BI web; las rehice y desde entonces guardé después de cada visual.

## 4. Cómo reproducir mi parte

```
python run_all.py                    # genera las tablas dash_* junto con el resto de marts
python publish/publish_to_neon.py    # publica marts en Neon (requiere DATABASE_URL en .env)
```

En Power BI: *Obtener datos → PostgreSQL*, servidor y base de la cadena de `bi_lectura`, modo *Importar*, y seguir `dashboard/README.md` para relaciones, medidas y páginas. La contraseña nunca se guarda en el repositorio.

## 5. Uso de IA

**Herramienta:** Claude (Anthropic).

**Para qué lo usé**
- **Como guía paso a paso** para trabajar solo desde el navegador: subir archivos y hacer commits en la interfaz web de GitHub, correr el pipeline en Google Colab y construir el modelo y las páginas en Power BI web.
- **Para proponer borradores** del SQL de las tablas `dash_*`, de las medidas DAX y de las llaves de `publish_to_neon.py`. Yo los ejecuté y comparé las cifras con los notebooks de Ximena y Hugo antes de usarlos.
- **Para revisar el PR de Hugo** y redactar los comentarios.
- **Para redactar borradores** del memo, de la documentación del dashboard y de este archivo.
- **Para resolver errores** a partir de capturas de pantalla (Colab, Power BI).

**Cómo verifiqué**
- Las cifras de los títulos del dashboard y del memo las comprobé en el propio dashboard conectado a Neon (por ejemplo, 30,844 empresas, 146 inversionistas elegibles, 81.5 % que supera su benchmark, efecto NASDAQ 1.84).
- Cuando un visual no coincidía con lo esperado, revisé el origen del campo y la relación en lugar de aceptar el número.

**Qué no hizo la IA:** no tuvo acceso a Neon ni a mis credenciales, no hizo commits ni `push` y no fusionó pull requests. Los commits de este repositorio con mi nombre los hice yo.

## 6. Límites de mi contribución

No construí la carga, la limpieza ni la publicación inicial (Noel), el modelo dimensional (Cristina), los checks y la bitácora (Olga), el análisis de inversionistas (Ximena) ni el de ciclos de mercado (Hugo). Mis tablas `dash_*` se construyen encima de su trabajo y puedo explicar cómo se conectan.
