# Uso de herramientas de IA — Cristina Pineda (Modelado de datos)

## Herramienta
**Claude (Anthropic)**, en modo conversación, del 2 al 5 de noviembre de 2026. No se conectó al
repositorio ni a la base de datos: trabajó solo con lo que yo le compartí (el enunciado del
proyecto, capturas de la terminal y la lista de columnas del esquema `clean`).

## Para qué la usé

| Tarea | Qué hizo la IA | Qué hice yo |
|---|---|---|
| Configuración y Git | Me guio en los comandos: clonar, crear la rama `cristina/modelo` desde `noel/staging`, el entorno virtual, cargar los CSV y abrir pull requests | Ejecuté cada comando y le compartí el resultado para decidir el siguiente paso |
| Diseño del modelo | Propuso la estructura en estrella (3 hechos, 3 dimensiones y un puente) a partir de los requisitos de la Parte 2 del enunciado | Revisé que cubriera los análisis del equipo y la acepté |
| SQL de `sql/04_marts` | Redactó los 7 archivos `.sql` con base en las columnas reales de `clean`, siguiendo el formato de los SQL de Noel | Corrí cada archivo en DuckDB y validé sus resultados antes de subirlo |
| Pruebas | Escribió las consultas de verificación (conteos, llaves duplicadas, llaves huérfanas y conciliación de montos) | Las ejecuté e interpreté los resultados |
| Documentación | Redactó `diccionario_modelo.md`, `diagrama_modelo.md` (Mermaid) y `justificacion_modelo.md` con las cifras que obtuve en las pruebas | Revisé el contenido y lo subí al repositorio |
| Revisión de trabajo ajeno | Me ayudó a revisar el PR #11 de Olga y a contrastar los campos del `diccionario_metricas.md` de Hugo con el modelo | Corrí `datos_bitacora.py`, comparé las cifras y aprobé el PR |

## Cómo verifiqué lo que propuso
No subí ninguna tabla sin probarla. Para cada una comprobé lo siguiente:

- **Unicidad de la llave:** filas = ids distintos en las 7 tablas (por ejemplo, 197,560 empresas y 52,928 rondas).
- **Cero llaves huérfanas:** cada hecho apunta a empresas, fechas e inversionistas que existen.
- **Sin doble conteo en el puente:** el monto total por `fact_rondas` y por el puente con `peso`
  da lo mismo, US$306.4 mil millones. Sin el peso saldría US$938.5 mil millones, 3 veces inflado.
- **Pipeline completo:** `python run_all.py` termina con 71 checks y 0 fallas, ya con mis tablas.

## Problemas detectados durante el uso
- **Formato dañado:** al editar los `.md` con el Bloc de notas de Windows, el Markdown se guardó
  con caracteres escapados (`\_`, `\*\*`) y las tablas dejaron de verse en GitHub. Lo detectamos
  al revisar el archivo y reemplacé los tres documentos por versiones corregidas (rama
  `cristina/serie-externa`).
- **Archivos que no se suben:** la IA me advirtió no incluir `docs/resultados_checks.md`, que
  `run_all.py` regenera y que pertenece a otra persona. Lo restauré antes de cada commit.

## Lo que no delegué
- La decisión de aceptar el diseño y cada supuesto: reparto igualitario del monto en el puente,
  etapa = última ronda, conservar los registros de reemplazo.
- La ejecución y validación de todo el código.
- La coordinación con el equipo y las aprobaciones de pull requests.

La IA fue un apoyo para redactar y para guiarme en las herramientas. La responsabilidad por la
corrección del modelo y su defensa en la presentación es mía.
