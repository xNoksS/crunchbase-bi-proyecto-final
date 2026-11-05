# Crunchbase: financiamiento de startups (BI Proyecto Final 2026)

Equipo de BI de un fondo de venture capital. Entrega: jueves 5 de noviembre de 2026, 11:59 PM.

## Equipo y roles

| Persona | Rol |
|---|---|
| Noel | Líder + Ingeniería de datos |
| Olga | Calidad de datos y documentación |
| Cristina | Modelado de datos |
| Ximena | Analista de inversionistas |
| Hugo | Analista de startups e industrias |
| Jose | BI y storytelling |

## Cómo reconstruir todo desde cero

1. `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
2. Colocar los CSV originales de Crunchbase en `data/raw/` (no se suben al repo).
3. `python run_all.py` ejecuta raw → staging → clean → marts y luego los checks.
4. Correr los notebooks de `notebooks/` **antes de publicar**: escriben sus tablas
   de resultados (`marts.res_*`) en la misma base DuckDB. `run_all.py` recrea la
   base desde cero, así que el orden siempre es
   `run_all.py` → notebooks → `publish_to_neon.py`.
5. Copiar `.env.example` a `.env`, llenar TU rol de Neon y correr `python publish/publish_to_neon.py`.

## Estructura

- `sql/01_raw` … `sql/04_marts`: una transformación por archivo, ejecutadas en orden.
- `checks/`: checks automatizados (fallan si hay PK duplicadas, FK huérfanas, etc.).
- `docs/`: bitácora de calidad, decisiones, diccionario del modelo y de métricas.
- `notebooks/`: análisis (curvas de salida, sensibilidad de inversionistas, ciclos de mercado).
- `dashboard/`: archivo del dashboard y capturas.
- `data/external/`: serie externa mensual de FRED para el análisis de ciclos de
  mercado. **Sí** se versiona (excepción en `.gitignore`); fuente, frecuencia y
  periodo documentados en `data/external/README.md`.

## Flujo de trabajo

- Una rama por tarea (`rol/tarea`, p. ej. `olga/checks-fk`) y pull request.
- Nada llega a `main` sin revisión de otra persona.
- Credenciales solo en `.env` (ignorado por Git). Si se expone una, se rota de inmediato.

## Uso de herramientas de IA

Todo el equipo usó asistentes de IA como **guía de trabajo**, no como sustituto de nuestro criterio. La declaración detallada de cada integrante está en su archivo individual (por ejemplo `README_Noel.md` y `README_uso_IA_Ximena.md`), con la herramienta que usó y para qué.

**Para qué se usó**
- Orientarnos paso a paso: en qué orden construir el pipeline, cómo trabajar con Git y cómo configurar Neon.
- Proponer borradores de SQL, código y documentación, que cada quien ejecutó, revisó y ajustó.
- Revisar el trabajo del equipo y preparar la defensa (resúmenes y preguntas de práctica).

**Cómo se tomaron las decisiones**
- Las decisiones de diseño y de calidad de datos las tomamos como equipo, a partir de lo que mostraban los datos y de lo que íbamos discutiendo. La IA presentaba opciones y nosotros elegíamos.
- El proceso fue iterativo: se ejecutaba cada paso, se revisaba el resultado y se corregía con ese feedback.
- Las cifras citadas en la documentación fueron comprobadas por nosotros en la base de datos y en el repositorio.

**Qué no hizo la IA:** no tuvo acceso a nuestras credenciales ni a la base de datos, y no fusionó cambios al repositorio.