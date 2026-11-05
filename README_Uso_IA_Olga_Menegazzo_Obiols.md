# Uso de inteligencia artificial (Olga Menegazzo Obiols)

**Rol en el equipo:** calidad de datos y documentación.  
**Herramienta:** Claude (Anthropic), en la app de chat.  
**Periodo:** semana de entrega del proyecto (finales de octubre y principios de noviembre de 2026).

## Para qué la usé

1. **Entender el enunciado y mi rol.** Le pedí que resumiera el PDF, que me explicara qué le tocaba a mi rol y que me propusiera un orden de trabajo según las fechas.
2. **Git y GitHub.** Me orientó para clonar el repositorio, crear el entorno virtual, trabajar en ramas, hacer commits, push y pull requests, y resolver errores de terminal en Windows y un conflicto de merge en la bitácora.
3. **Checks automatizados.** Me ayudó a escribir un borrador de `checks/run_checks.py` (llaves primarias, llaves foráneas huérfanas, conteos entre capas, montos negativos y fechas imposibles) y de los scripts de exploración (`perfil.py`, `explorar_fechas.py` y `datos_bitacora.py`).
4. **Limpieza de `people`, `degrees`, `relationships`, `milestones` y `offices`.** Me ayudó a redactar el SQL de esas cinco tablas siguiendo las reglas que dio Noel.
5. **Bitácora de calidad.** Me ayudó a redactar las filas, a decidir qué cifras medir y a ordenar el formato de la tabla.
6. **Revisión de pull requests.** Me explicó cómo revisar el PR de otro integrante: correr el pipeline, comparar conteos y leer los cambios.
7. **Redacción.** Me ayudó con borradores de mi sección de limitaciones (valores faltantes), de las descripciones de PR y de los mensajes al grupo.

## Qué hice yo

- Corrí todos los scripts sobre los datos reales en mi computadora y tomé las cifras de esas corridas, no de la IA.
- Comparé los resultados con el diccionario de datos y con la bitácora (por ejemplo, los conteos por capa y los 1,276 registros de reemplazo en `objects`).
- Decidí con el equipo qué hacer con cada problema: poner `NULL` en lugar de borrar filas, excluir las filas huérfanas de `degrees` y `relationships`, y conservar las rondas sin fecha fuera de las cohortes.
- Leí el código que me generó y probé cada script antes de subirlo.

## Cómo verifiqué su trabajo

- La IA no tuvo acceso al repositorio ni a la base de datos: solo vio lo que yo le mostré (capturas de la terminal, fragmentos de código y el archivo del curso).
- Se equivocó en dos estimaciones, y las corregí con mis datos reales: calculó 464,212 filas para `clean.objects` y en realidad son 463,927 (diferencia de 285 llaves que solo referencian filas excluidas de `relationships`), y dio un conteo de fallas distinto al que salió al correr `run_checks.py`.
- Probé los scripts primero con una base sintética de pocas filas y después contra los datos completos.

## Qué compartí con la herramienta

Compartí el enunciado del proyecto, el archivo del curso con el diccionario y los CSV de Crunchbase, capturas de mi terminal y texto de la bitácora. No compartí contraseñas ni credenciales de Neon.

## Responsabilidad

La corrección y la interpretación de los resultados son mías. Puedo explicar y defender cada archivo que subí, incluido el SQL.
