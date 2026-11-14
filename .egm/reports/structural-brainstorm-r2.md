# Structural Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Fuentes: input v2, brief, reporte 1ª pasada.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## Blocker

**B1 — La integración de `.tscn` en rama única no tiene dueño; la excepción de jam suspende las protecciones de AGENTS.md sin reemplazarlas.**
La excepción elimina worktrees, ramas de módulo y la prohibición de tocar escenas compartidas, mientras la matriz de propiedad asigna tipos de archivo, no escenas. Tres hotspots de colisión `.tscn` sin dueño: (1) **la escena principal de juego** (base + exterior + raíz HUD) no cae en `scenes/ui/`, así que por eliminación es de DevGreem — pero el HUD de Ramerlin necesita anclas in-scene: ambos editan el mismo archivo con commits directos; (2) **escenas de contenido** (8 máquinas, 3 POIs, exterior): Mijael toca `content/` por arte, donde también viven los `.tscn`/`.gd`; (3) **registros** (economy.tres, demo_states.tres) author de Mijael mientras DevGreem cambia las clases que referencian.
Las dos protecciones anti-crash de AGENTS.md (escena compartida → copia; nunca duplicar `.uid`) quedan suspendidas de facto sin reemplazo.
Requisito para el draft: regla de integración escrita antes de H0 — nombrar un integrador único de escenas (solo DevGreem edita `.tscn` fuera de `scenes/ui/`; el HUD es una escena instanciada bajo `scenes/ui/` adjunta por su dueño; Mijael nunca edita `.tscn`) y fijar dónde vive la escena principal (p. ej. `scenes/base/`).

## Major

**M1 — La lista de pantallas/estados sigue ausente en ambos documentos.** Existen solo como menciones narrativas: título/selector (3 slots, 2 grises), stills de intro, still de aterrizaje, escena principal con HUD permanente (6 stats visibles, reloj, multiplicador), tutorial con diálogo + indicación de destino, overlay de retrato Aurora + pistas, UI de consola comms (enviar informe, pedir reabastecimiento, "próximo evento en N h"), UI de escaneo (3 s simple), velo de fast-forward, selector de presets de demo, pantalla de evaluación (5 contadores), transición muerte/victoria→evaluación; la pausa/esc indefinida. Ninguna aparece como lista nombre → ruta `scenes/` → dueño → transiciones. La persona de UI sigue sin contrato ejecutable.

**M2 — El schema de eventos solo medio entregado: los campos de procedencia existen, el mapping por arquetipo y el destino de registro no.** Los campos están nombrados, pero ni las 5 arquetipos (avería, caída de producción, pico de consumo, ventana de radiación, corte de comunicaciones) se mapean a su fuente NASA, ni se nombra el archivo de filas de eventos. DONKI/CRaTER/NTRS aparecen en prosa libre, nunca como filas contra arquetipos; avería/corte/pico no tienen atribución escrita (ni siquiera un "none → real_data:false" explícito).
Requisito: tabla de 5 filas arquetipo → fuente NASA (o "none/simulado" explícito) + ruta de registro nombrada.

**M3 — La decisión `.tres` solo está medio mapeada a la estructura de carpetas de AGENTS.md.** Aterriza: economy → `databases/economy.tres`; demo-states → `databases/demo_states.tres`. Sin aterrizar: registro de **events**, filas de **submisión**, tablas de **máquinas** (hint_text, mejoras), tabla central de **strings**, y tablas de **feeds DONKI/RAD**. Tensión no reconciliada con AGENTS.md: la regla general "registros editables en `game/databases/*.tres`" empuja config por-máquina a un registro central que AGENTS.md exige contenido-local. Además: `.tres` editados por novatos dependen de clases tipadas de DevGreem y el checker no valida `.tres` — el beneficio de diff legible del JSON descartado se perdió sin mitigación.
Requisito: tabla de inventario (dataset → ruta → clase → dueño) + regla: `.tres` por-máquina usados solo por ese contenido viven en `content/machines/<nombre>/`; solo filas compartidas van a `databases/`; clases de schema congeladas a H4.

**M4 — "Puntos abiertos" sigue sin ser tabla: defaults 2/5, deadlines 2–3/5, dueños ~1/5, y un ítem stale contra el brief.**
(1) submisiones — el brief ya congeló las 4 filas concretas, pero el input aún las lista abiertas (solo textos/umbrales quedan); (2) economía — freeze hora 1 con defaults (deadline sí, dueño no); (3) rúbrica — completo; (4) pasos de escaneo — default 3 s solo en input, sin dueño/deadline, ausente del brief; (5) filas grises — default "(próximamente)", sin dueño/deadline. El requisito de 1ª pasada `{decisión, default, dueño, hora de freeze, ubicación de código}` nunca se adoptó como forma.
Requisito: plegar las 5 filas al draft como tabla de decisiones con esas columnas; refrescar (1) a "solo textos/umbrales".

## Nit

- **N1** — El modelo de recursos y día/noche es ahora estructuralmente coherente entre los dos documentos. Dos residuos: la **batería es una entidad sin nombre** (sin fila de almacenamiento ni capacidad, ausente de las 8 máquinas) y la tabla fuente→almacén→consumidor con unidades/tasas base no existe en ningún sitio (diferida a economy.tres — aceptable en concepto, obligatoria en draft).
- **N2** — Inventario de autoloads inconsistente: input 4 (`GameSim`, estado de partida, `EventLog`, `AudioManager`); brief item 3 añade "(uno solo registro de eventos y sim)" que parece fusionar estado + EventLog y contradice la lista.
- **N3** — Drift interno del brief en idioma UI: "Confirmar con el autor" vs "confirmado por el autor"; y el input mantiene "continuar" como tercer estado final que el brief corta silenciosamente; el default de escaneo 3 s solo vive en el input.
- **N4** — La tabla central de strings no tiene formato ni ruta (¿`.tres`? ¿CSV? ¿bloque const `.gd`?) aunque es entregable nombrado de Ramerlin.
- **N5** — Sin manejo de pausa/esc en ningún sitio; a ×5/×10 no hay forma documentada de pausar mientras se lee evaluación o tutorial.
- **N6** — Sin mapping sala→máquina: tres máquinas caen en dormitorio-almacén por eliminación; la jurisdicción del panel solar exterior vs "≤2 pantallas exteriores" sin declarar.

## Bottom line

Convertir el brief en draft solo después de tres artefactos estructurales escritos (cada uno pueden ser 5 líneas, pero deben existir): (1) la **regla de integrador de escenas** que reemplaza las protecciones que la excepción de jam suspende; (2) el **inventario completo de archivos de datos con rutas concretas** colocado dentro del split databases/ vs content/ de AGENTS.md; (3) la **lista de pantallas/estados con dueño y transiciones** — sigue ausente y es el único contrato ejecutable para la persona de UI. Lo demás (forma de tabla de puntos abiertos, filas de fuente por arquetipo, entidad batería, nombres de autoloads) es una tabla de diez líneas que el draft puede absorber sin re-decidir nada.
