# Codebase Details Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Repo re-verificado: `project.godot` sigue 850×480, avisos estrictos, autoload MCP, plugin SceneTime en `.godot/` gitignored; sin carpetas de datos aún; `.gitattributes` solo EOL (sin merge drivers); `.gd.uid` commiteados (addon).
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## Blocker

### B-R2-1 — El gate de calidad de v2 no valida el pipeline que hizo único
El único pre-commit es `check-gdscript.sh`, que no parsea ni valida `.tres`. Con economy/events/submissions/demo_states en manos de un no-programador: (a) una propiedad mal escrita se ignora silenciosamente al cargar y se pierde al siguiente save; (b) una edición estructural rota tumba la carga del registro entero (todas las escenas consumidoras fallan en boot); (c) un valor semánticamente erróneo (coste negativo, id de máquina colgante) llega directo al jurado. "El tipado del inspector evita errores de formato" protege solo ediciones de inspector y solo contra errores de tipo.
Requisito: validación de datos headless en el pre-commit — boot `godot --headless --quit` + autoload de desarrollo `DataAudit` que carga los 4 registros y aserta: ids únicos, ids de máquina/evento referenciados existentes, costes no-negativos, filas `real_data: true` con `source_url`/`date_archived` no vacíos, fechas ISO-8601. Dobla como superficie de debug.

## Major

### M-R2-1 — Los archivos fuente NASA crudos siguen sin hogar (cola residual de B3 de 1ª pasada)
DONKI JSON/XML, tablas CRaTER y PDFs NTRS no encajan en `databases/` (`.tres`), `resources/` (scripts) ni `assets/` (audio/fonts/images). Decidir ahora (p. ej. subcarpeta sancionada `databases/sources/` con excepción registrada, o fuera de `game/` citando por URL) antes de que aterricen los archivos en H12.

### M-R2-2 — `demo_states.tres` no tiene mecanismo de captura y se pudrirá (fallado por ambas pasadas)
Un preset de mitad de partida codifica docenas de campos interdependientes derivables solo del sim determinista real. v2 lista las filas como datos mantenidos por novatos, pero un estado manuscrito es inverificable y cada cambio de balance H12–32 lo invalida silenciosamente. Con golden congelado en H28, no hay paso de regeneración programado.
Requisito: acción de dump en `GameSim`/`EventLog` que captura el estado de tick vivo y escribe la fila (ResourceSaver) + ítem de checklist de golden "re-dump de presets antes de H28".

### M-R2-3 — Duplicación de `.uid` e higiene de `.gd.uid` en el workflow de registros de novatos (nuevo)
Los `.tres` nuevos llevan `uid="uid://…"`; copiar un registro para plantillar el siguiente (events.tres → submissions.tres) clona el uid. AGENTS.md ya avisa que dos recursos con el mismo uid rompen el proyecto.
Requisito: protocolo de copia (copiar desde el editor para uid fresco, o arrancar el header con uid), jamás borrar sidecars `.gd.uid`, prohibido copy-paste de bloques sub_resource con ids locales colisionantes.

### M-R2-4 — Excepción de jam + mapa de propiedad dejan sin enunciar la regla de escritor único de `.tscn` (gap de coherencia nuevo)
Escenas de contenido (mapa base, 8 máquinas, POIs) sin dueño; Ramerlin trabaja "sobre scaffolds", es decir, dos personas editando el MISMO `.tscn` plano en subárboles distintos — igualmente conflictivo. Con commits directos, el primer import de un novato puede reescribir muchos archivos en un commit sin revisión. economy.tres doble-dueño en la práctica.
Requisito: UI como archivos de escena separados propiedad completa de Ramerlin (instanciadas como sub-escenas, nunca las escenas base); "un editor por archivo `.tscn`/`.tres`"; commits solo de lo propio; RACI por registro (economy.tres: números DevGreem; Mijael solo puede añadir filas de procedencia).

### M-R2-5 — La premisa declarada de `.tres` contradice el perfil de habilidades del equipo (punto nuevo)
"Los novatos ya manejan Resources" choca con el propio perfil: Ramerlin "sin Godot (aprendiendo)", Mijael "sin programación". Crear filas sub-resource en el inspector es un baile multi-paso, no a prueba de typos. La decisión se mantiene como llamada del autor, pero el argumento de seguridad exige: onboarding de 15 min de edición de filas en H1, y la red `DataAudit` (B-R2-1).

### M-R2-6 — Sourcing de arte sin resolver (residual de M7 de 1ª pasada)
Un artista (2.5/5) que además posee vídeo, diapositivas y recolección NASA durante H12–24; sin decisión de sourcing CC0 (Kenney/OpenGameArt/AssetLib). Sigue siendo el asesino silencioso del cronograma; un compromiso CC0 de una línea debería entrar al brief antes de H0.

## Nit

- **N-R2-1** — Integración post-evento no declarada: PR de `features/jam-outpost-lunar` → `features` tras H36 (cumple reglas) o archivado. Sin decisión, el juego puede quedar varado en rama lateral.
- **N-R2-2** — Nombre de rama vs convención documentada (módulos con nombres planos); cosmético dada la excepción aprobada.
- **N-R2-3** — Formato de la tabla de strings sin decidir (`.tres` tipado en `databases/` o clase en `resources/localization/`); pin it — los strings son contenido donde una propiedad mal escrita suelta texto silenciosamente.
- **N-R2-4** — Drift de nombre de campo: input dice `real_data: false`, brief renderiza "datos_reales: no". El draft debe congelar un nombre de schema o el handoff navega con dos nombres para un campo.
- **N-R2-5** (contexto verificado) — El autoload MCP se auto-elimina fuera de runs de editor y el addon registra un export-strip: **no hay que hacer nada** para excluirlo del export; basta con no desactivarlo.
- **N-R2-6** (contexto) — `.gitattributes` no ofrece merge drivers; el fix correcto son las reglas de propiedad/serialización de M-R2-4, no drivers personalizados a mitad de jam.

## Bottom line

v2 convergió decisivamente en preguntas de proceso, y `.tres` es estructuralmente compatible con AGENTS.md; lo que la segunda pasada encuentra es que los guardarraíles del pipeline no se decidieron junto con el formato. El cluster de mayor riesgo es B-R2-1/M-R2-3/M-R2-5 juntos: un no-programador posee Resources basados en texto cuyo único chequeo automático (checker GDScript) no puede leerlos, bajo un workflow sin red de review, en un formato donde un uid copiado rompe referencias silenciosamente. El segundo es M-R2-2, presets que nadie puede author a mano y que ningún proceso regenera. El tercero es M-R2-4, la regla de escritor único para escenas bajo commits directos. Entregar al draft estos seis ítems como adiciones obligatorias de schema/proceso: DataAudit en el pre-commit, protocolo de copia `.tres`/uid, acción de captura de estado con re-dump pre-H28, propiedad por archivo `.tscn` con UI como escenas separadas, RACI por registro (economy.tres números = DevGreem), hogar nombrado para fuentes NASA crudas — más el compromiso CC0 de una línea que v2 nunca re-abrió.
