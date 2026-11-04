# Justificación del modelo dimensional

## Decisión central
Esquema en estrella con **tres tablas de hechos** (`fact_rondas`, `fact_adquisiciones`,
`fact_ipos`) que comparten **dimensiones conformadas** (`dim_empresa`, `dim_inversionista`,
`dim_fecha`), definidas una sola vez. Así los análisis de cohortes, inversionistas y
ciclos de mercado usan las mismas empresas, fechas e inversionistas.

## Granos declarados
| Tabla | Una fila es |
|---|---|
| fact_rondas | una ronda de financiamiento |
| fact_adquisiciones | una adquisición |
| fact_ipos | una IPO |
| puente_ronda_inversionista | un par (ronda, inversionista) |
| serie_externa_mensual | un mes calendario |

## Cómo se evita el doble conteo
Una ronda tiene varios inversionistas (muchos a muchos). El monto **solo vive en
`fact_rondas`**; el puente guarda `peso = 1 / n_inversionistas`. El monto atribuido a un
inversionista es `monto_usd × peso`, y la suma de una ronda devuelve exactamente su monto.
Verificado: US$306.4 mil millones por ambos caminos; sin peso saldrían US$938.5 mil
millones (3 veces inflado).

## Otras decisiones
- **Llaves naturales de Crunchbase** (`c:123`, `f:45`): son estables y únicas, y el prefijo
  indica el tipo de objeto. Evitan una tabla de mapeo extra.
- **Dimensión de rol:** `dim_empresa` se usa dos veces en `fact_adquisiciones`
  (adquirida y adquirente), sin duplicar la dimensión.
- **Registros de reemplazo incluidos** (`es_registro_faltante`): si se quitan, hay rondas
  y adquisiciones huérfanas. Se marcan para que cada análisis decida si filtrarlos.
- **Etapa = tipo de la última ronda**, porque Crunchbase no reporta la etapa actual.
- **Sin textos largos** (descripciones, logos) para caber en el límite de 0.5 GB de Neon.

## Soporte al análisis elegido: (b) ciclos de mercado
La serie externa (`serie_externa_mensual`, FRED: NASDAQCOM, FEDFUNDS y UNRATE) tiene
grano mensual y se une con `dim_fecha.anio_mes`. El financiamiento mensual se agrega
desde `fact_rondas` por `anio_mes`, sin pasar por el puente, así que el monto no se
cuenta doble. La serie cubre 1990-01 a 2013-12: todo el periodo de Crunchbase más
12 meses para rezagos. Se descartó el análisis (a) de fundadores, que habría requerido
una dimensión de personas y un puente empresa-persona.

## Alternativas descartadas
| Alternativa | Por qué se descartó |
|---|---|
| Una sola tabla ancha (ronda × inversionista con monto) | Repite el monto en cada inversionista y lo infla |
| Guardar el monto atribuido en el puente | Redundante; si cambia el monto hay que recalcular dos tablas |
| Repartir el monto según aportación real | Crunchbase no reporta cuánto puso cada inversionista |
| Una sola tabla de "salidas" (adquisición + IPO) | Tienen granos y atributos distintos; la definición de éxito las combina en el diccionario de métricas |
| Copo de nieve (dimensión de industria separada) | Más joins sin beneficio; la industria es un solo atributo |
| Serie FRED diaria | El financiamiento se analiza por mes; una serie diaria no aporta y complica los rezagos |

## Limitaciones del modelo
- 84% de las empresas nunca levantó una ronda; las tasas de éxito usan solo empresas con rondas.
- 11% de las rondas no tiene monto en USD; US$114 mil millones están en rondas sin inversionistas registrados.
- Solo 26% de adquisiciones tiene precio; 47% de IPOs no tiene fecha.
- 150 empresas fueron adquiridas más de una vez; el éxito usa la primera salida.
