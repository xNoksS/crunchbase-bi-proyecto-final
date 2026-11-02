\# Justificación del modelo dimensional



\## Decisión central

Esquema en estrella con \*\*tres tablas de hechos\*\* (`fact\_rondas`, `fact\_adquisiciones`,

`fact\_ipos`) que comparten \*\*dimensiones conformadas\*\* (`dim\_empresa`, `dim\_inversionista`,

`dim\_fecha`), definidas una sola vez. Así los análisis de cohortes, inversionistas y

ciclos de mercado usan las mismas empresas, fechas e inversionistas.



\## Granos declarados

| Tabla | Una fila es |

|---|---|

| fact\_rondas | una ronda de financiamiento |

| fact\_adquisiciones | una adquisición |

| fact\_ipos | una IPO |

| puente\_ronda\_inversionista | un par (ronda, inversionista) |



\## Cómo se evita el doble conteo

Una ronda tiene varios inversionistas (muchos a muchos). El monto \*\*solo vive en

`fact\_rondas`\*\*; el puente guarda `peso = 1 / n\_inversionistas`. El monto atribuido a un

inversionista es `monto\_usd × peso`, y la suma de una ronda devuelve exactamente su monto.

Verificado: US$306.4 mil millones por ambos caminos; sin peso saldrían US$938.5 mil

millones (3 veces inflado).



\## Otras decisiones

\- \*\*Llaves naturales de Crunchbase\*\* (`c:123`, `f:45`): son estables y únicas, y el prefijo

&#x20; indica el tipo de objeto. Evitan una tabla de mapeo extra.

\- \*\*Dimensión de rol:\*\* `dim\_empresa` se usa dos veces en `fact\_adquisiciones`

&#x20; (adquirida y adquirente), sin duplicar la dimensión.

\- \*\*Registros de reemplazo incluidos\*\* (`es\_registro\_faltante`): si se quitan, hay rondas

&#x20; y adquisiciones huérfanas. Se marcan para que cada análisis decida si filtrarlos.

\- \*\*Etapa = tipo de la última ronda\*\*, porque Crunchbase no reporta la etapa actual.

\- \*\*`dim\_fecha.anio\_mes`\*\* permite unir con series mensuales externas (FRED) para el

&#x20; análisis de ciclos de mercado.

\- \*\*Sin textos largos\*\* (descripciones, logos) para caber en el límite de 0.5 GB de Neon.



\## Alternativas descartadas

| Alternativa | Por qué se descartó |

|---|---|

| Una sola tabla ancha (ronda × inversionista con monto) | Repite el monto en cada inversionista y lo infla |

| Guardar el monto atribuido en el puente | Redundante; si cambia el monto hay que recalcular dos tablas |

| Repartir el monto según aportación real | Crunchbase no reporta cuánto puso cada inversionista |

| Una sola tabla de "salidas" (adquisición + IPO) | Tienen granos y atributos distintos; la definición de éxito las combina en el diccionario de métricas |

| Copo de nieve (dimensión de industria separada) | Más joins sin beneficio; la industria es un solo atributo |



\## Limitaciones del modelo

\- 84% de las empresas nunca levantó una ronda; las tasas de éxito usan solo empresas con rondas.

\- 11% de las rondas no tiene monto en USD; US$114 mil millones están en rondas sin inversionistas registrados.

\- Solo 26% de adquisiciones tiene precio; 47% de IPOs no tiene fecha.

\- 150 empresas fueron adquiridas más de una vez; el éxito usa la primera salida.

