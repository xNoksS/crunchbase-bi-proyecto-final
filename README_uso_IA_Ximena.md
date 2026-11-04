# Uso de inteligencia artificial — Análisis de inversionistas

**Proyecto:** Business Intelligence — Crunchbase  
**Componente:** Analista de inversionistas  
**Herramienta de IA utilizada:** ChatGPT (OpenAI)

## 1. Propósito del uso

Se utilizó ChatGPT como herramienta de apoyo durante la elaboración, revisión y documentación del análisis de inversionistas. Su uso se concentró en facilitar la escritura y depuración de código, organizar las métricas solicitadas y explicar los resultados del notebook.

La IA se empleó como **asistente de desarrollo y análisis**, no como fuente primaria de datos ni como sustituto de las verificaciones del proyecto.

## 2. Actividades en las que se utilizó

| Actividad | Apoyo de ChatGPT |
|---|---|
| Estructuración del notebook | Organización de secciones, celdas explicativas, consultas y visualizaciones. |
| Python y SQL | Propuestas de código para consultar las tablas del esquema `marts` y calcular indicadores. |
| Métricas de inversionistas | Apoyo para definir actividad, éxito V1/V2, benchmark y ranking. |
| Análisis de sensibilidad | Propuestas para comparar resultados con distintos tamaños mínimos de portafolio. |
| Documentación | Redacción de definiciones, fórmulas, supuestos, limitaciones y conclusiones interpretativas. |
| Depuración técnica | Orientación para resolver errores de conexión con DuckDB, rutas locales y ejecución en JupyterLab. |
| Control de versiones | Asistencia para copiar el notebook al repositorio, crear commits y subir cambios a una rama de GitHub. |

## 3. Datos y metodología

Los cálculos se diseñaron para utilizar las tablas del proyecto en el esquema `marts`, en particular:

- `marts.puente_ronda_inversionista`
- `marts.fact_rondas`
- `marts.dim_inversionista`
- `marts.dim_empresa`
- `marts.met_salida_empresa`

La información proviene de la base de datos del proyecto. ChatGPT no generó los registros de Crunchbase ni debe considerarse una fuente de cifras observadas.

El análisis aborda:

1. **Actividad del inversionista:** participación en rondas de inversión dentro del periodo estudiado.
2. **Éxito V1:** proporción de empresas del portafolio con salida observada.
3. **Éxito V2:** proporción de empresas con salida dentro de una ventana de cinco años, considerando únicamente cohortes con seguimiento suficiente.
4. **Benchmark:** comparación descriptiva con pares de industria, etapa y cohorte.
5. **Sensibilidad:** comparación de rankings y tasas ante distintos umbrales de tamaño de portafolio.

Las definiciones operativas definitivas deben coincidir con las fórmulas efectivamente ejecutadas en el notebook.

## 4. Verificación y responsabilidad

El código sugerido por IA requiere revisión humana. Antes de presentar resultados como definitivos, corresponde:

- Ejecutar las celdas del notebook en el entorno del proyecto.
- Verificar que las consultas utilicen las tablas y columnas existentes en `marts`.
- Revisar denominadores, fechas, nulos y filtros de cada indicador.
- Confirmar que las gráficas reflejen los resultados calculados y no solamente salidas guardadas de versiones anteriores.
- Comprobar la creación y publicación de las tablas de resultados requeridas.
- Contrastar las conclusiones con las cifras obtenidas en la ejecución.

**Estado de validación:** la asistencia de ChatGPT y la subida del notebook a GitHub no constituyen, por sí solas, una validación integral de todos los resultados. Este documento no afirma que se hayan completado pruebas que no estén respaldadas por la ejecución del equipo.

## 5. Limitaciones del uso de IA

Las respuestas de IA pueden contener errores de código, supuestos no aplicables o interpretaciones incorrectas. En este trabajo fue necesario revisar especialmente la compatibilidad con el esquema `marts` y conservar el análisis y las visualizaciones desarrollados previamente. La interpretación final y la aceptación de los resultados corresponden al equipo del proyecto.

## 6. Declaración de transparencia

> Para el desarrollo del componente de análisis de inversionistas se utilizó ChatGPT, de OpenAI, como apoyo en la estructuración del notebook, formulación y corrección de consultas Python/SQL, documentación de métricas, interpretación preliminar y resolución de problemas técnicos. Los datos utilizados pertenecen a la base del proyecto. Las respuestas generadas por IA fueron tratadas como propuestas sujetas a revisión y validación por parte del equipo.

---

**Nota de integración:** este documento puede agregarse como `docs/README_uso_IA_Ximena.md` para no reemplazar el `README.md` principal del repositorio ni modificar documentación de otros integrantes.
