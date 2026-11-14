# Implementation Readiness Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Repo verificado: lienzo en blanco (solo `project.godot`, `icon.svg`, addon MCP). Sin migración de datos. El proceso git sí es la "schema" que romperá el rollout.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## Migration & compatibility notes

- **No persistent data exists** → no schema migration risk. Declare "no save system" as a v1 non-goal. Internal state only.
- **The repo's git process is the one schema that will break rollout** (ver Blocker 2).
- **`project.godot` is a frozen schema**: viewport 850×480 (no divisible por tiles 32), avisos estrictos a nivel error, autoload MCP. Cambiar en la hora 1 o nunca.
- **Rollback safety**: en rama única de jam, rollback = `git revert` del último commit. El único daño irreversible es duplicar `.uid` al copiar escenas — prohibirlo.

## BLOCKERS

### B1 — The 8-category rubric is an open point nobody owns
Owner por defecto: Mijael la consigue, Ramerlin la destila a lista de prioridades de corte, DevGreem la firma. Sin esto, ningún punto abierto se puede cortar ni conservar con seguridad.

### B2 — The repo's git/PR/worktree process will eat the deadline
Congelar hora 1: **una rama de jam** desde `features` (`features/jam-outpost-lunar`), commits directos, sin worktrees, sin PRs. DevGreem como única autoridad de integración. Re-adoptar el flujo normal después del evento. La decisión más barata y de mayor impacto de la hora 1.

### B3 — Judges will never see a 5-hour mission arc
Convertir en feature de alcance, no en idea: (a) multiplicador de tiempo 1×/5×/10× con tecla; (b) "Demo mode" en el menú que salta a dos estados deterministas (mitad de tormenta, hora final) como presets JSON aplicados al cargar (~2 h de coste). Congelar hora 1; verificar en el gate de H12.

### B4 — Video/presentation ownership is unassigned
A hora 30, quien sea dueño del vídeo roba horas de juego en el peor momento. Congelar hora 1: Mijael es dueño de captura + vídeo + diapositivas; Ramerlin entrega la UI hacia H28–30 y pasa a apoyo visual; DevGreem hace cero diapositivas. "Golden build" congelado (tag) a H28; toda captura sale de ahí.

### B5 — The machine/upgrade surface is unbounded and dev-only
"Each plant has its own machine" + lista de máquinas sin definir = explosión del sistema más caro. Default hora 1: **8 interactuables**: O₂ scrubber, water recycler, energy distributor, solar array (exterior), hydroponics unit (agregado ≤4 plantas, una estadística compartida + una mejora de calidad de agua), workbench, comms console, storm shelter/puerta. Dos mejoras por máquina, costes escalares desde `economy.json`. Más allá = stretch post-H24, aprobado solo por DevGreem.

### B6 — All logic sits on one dev with zero cross-training plan
La solución ya existe: sim **data-driven desde la hora 1** (extender a todo: `economy.json`, `events.json`, `submissions.json`, `demo_states.json`). Equilibrado y contenido = edición de datos que Ramerlin/Mijael pueden hacer bajo revisión. Scripts = territorio de DevGreem, JSON = territorio del equipo. Programar sueño explícito: DevGreem off ~H18–22 mientras lanes de arte/UI continúan; nadie trabaja H30–36 sin descanso.

## MAJORS

### M1 — Main mission has no step-by-step objectives or tools
Default hora 1: una zona exterior (1–2 pantallas), 3 tiles POI (estación de temperatura, campo de rocas, depósito mineral), una herramienta de escaneo, 3 informes enviados por comms = misión completa. DevGreem diseña + codifica; Mijael dibuja los POI. No dejar crecer a open-world.

### M2 — The 4 submissions are undefined and the author rejected the only proposal set without replacing it
Default hora 1: runner de submisiones por plantilla JSON (condición de trigger, contador, recompensa, dos líneas de texto), 4 entradas: (1) aviso de tormenta → tomar 2 lecturas de temperatura en el exterior antes del evento DONKI; (2) entregar 3 muestras de roca en comms; (3) reparar el water recycler cuando el almacén baja del umbral; (4) enviar 5 informes en total. Mitad evento-respuesta, mitad progreso de misión. Ramerlin escribe los strings.

### M3 — Economy numbers are entirely undefined
Default: constantes placeholder en `economy.json` (consumo/día O₂/agua/comida, curva solar, costes, conversión financiación→recurso 1:1:1 inicial). Números NASA = swap, no rediseño; tuning H26–30 mediante playtests de 30 min de los novatos. Owner del schema: DevGreem; owner del tuning: Ramerlin/Mijael.

### M4 — Beginner programmer + strict typed GDScript on the same branch as the only logic dev risks constant conflict
Mitigación hora 1: (a) mapa de propiedad de archivos — Ramerlin: `scenes/ui/*`, `themes/*`; Mijael: `assets/*`, arte de `content/*`; DevGreem: el resto; (b) scaffolds tipados (p. ej. `hud.gd` con `@onready var oxygen_label: Label = $OxygenLabel`) para que Ramerlin edite diseño visual, no firmas; (c) checker estricto antes de cada commit, revisión de diffs de novatos en checkpoints fijos (una vez por bloque de 12 h), no bajo demanda. Sin esto: 4–6 h de merge/retype.

### M5 — The NASA-data swap is scheduled "at the end", which is where it dies
Fix: campos de procedencia en el schema JSON desde la hora 1 (`source: "NTRS 197X-XXXXX, archived; DONKI entry YYYY-MM-DD"`), placeholders con flag `real_data: false`. Mijael recoge citas + entradas DONKI durante H12–24 (leyendo, no programando). DevGreem cambia números H28–32 — antes de la captura, no durante. El criterio de "visibilidad de datos reales" queda garantizado aunque el swap se atrase.

### M6 — Evaluation metrics are undefined
Default congelado por H12 (antes del Bloque B): progreso de misión (informes/muestras), submisiones completadas/intentadas, recursos supervivientes al final, picos de radiación sobrevividos/uso correcto de refugio, soles transcurridos. Cinco contadores fijos; pantalla construida H26.

### M7 — No platform/export decision exists
Default hora 1: Windows desktop + HTML5 Web, ambos smoke-export a H8 (descargar templates temprano; Web es el medio por defecto ante jueces). Jolt + Web funciona. Si Web falla, desktop-only es el fallback y el vídeo lleva el peso ante el jurado.

## NITS

- N1 — Viewport 850×480 no divide por 32 (26.56 tiles). Sin arte aún: cambiar a **832×480** en la hora 1, o aceptar columna irregular permanente.
- N2 — Audio sin dueño. Default: 10–12 SFX procedurales (jsfxr/bfxr) + 2–3 loops cc0; DevGreem cablea un `AudioManager` en una hora. Sin composición original.
- N3 — Idioma de la UI no definido. Default hora 1: **inglés** (jueces + audiencia NASA); strings centralizados en un diccionario.
- N4 — "Research speed" sin sistema de research. v1: la estadística existe en la tabla sin uso. No inventar research loop.
- N5 — Hidden stats + random astronaut stats. Para un astronauta, "random" no sirve: tabla base fija modificada por mejoras; RNG diferido al futuro multi-astronauta.
- N6 — Selector "3 al azar, 1 implementada": renderizar 2 opciones como filas "(coming soon)", cero código extra.
- N7 — Almacenar objetos en el dormitorio implica inventario. Default: los objetos se aplican al recogerlos; sin UI de almacenamiento.

## Open-decision register (hour-1 defaults)

| Punto abierto | Default | Owner |
|---|---|---|
| Rúbrica | Fetch H1, destilada a cortes | Mijael/Ramerlin |
| Git workflow | Rama única de jam, sin PRs/worktrees | DevGreem |
| Demo visibility | Multiplicador + presets de salto JSON (en alcance) | DevGreem |
| Vídeo/diapos | Mijael; golden build H28 | Mijael |
| Máquinas/mejoras | 8 interactuables, 2 mejoras c/u, costes `economy.json` | DevGreem |
| Misión principal | 1 zona exterior, 3 POI, herramienta de escaneo, 3 informes | DevGreem |
| Submisiones | Plantilla JSON + 4 entradas | DevGreem (código) / Ramerlin (strings) |
| Economía | JSON placeholder, swap NASA H28–32 | DevGreem (schema) / Ramerlin+Mijael (tune) |
| Métricas de evaluación | 5 contadores congelados H12 | DevGreem |
| Datos NASA | Campos de procedencia en schema desde H1; citas H12–24 | DevGreem (schema) / Mijael (recoger) |
| Plataforma/export | Windows + HTML5, smoke test H8 | DevGreem |
| Audio | 10–12 SFX procedurales + cc0, un AudioManager | DevGreem |
| Idioma UI | Inglés, tabla de strings central | Ramerlin |

Todo lo que no esté en la tabla puede quedar abierto pasada la hora 1 — siempre que no genere sistemas nuevos.

## Addon / MCP / tooling harvest

- **No añadir addons durante el jam.** Solo godot_mcp_toolkit; sin LimboAI ni Dialogic (diálogo de Aurora: hand-roll ~40 líneas tipadas).
- **MCP toolkit**: (a) LSP diagnostics por archivo para atrapar violaciones de tipado mientras Ramerlin trabaja; (b) screenshots mid-playtest para vídeo/diapos; (c) lecturas de estado de nodos en runtime para depurar el trabajo de los novatos. **No** para autoría primaria de escenas ni para mutaciones de novatos (revisar cada write con `git status`/`git diff`).
- **Gates reales**: `check-gdscript.sh --strict -p game` antes de cada commit. Nada más automatizado.
- **Assets gratis**: packs cc0 (Kenney et al.) como placeholders la primera mañana de Mijael; imágenes NASA en dominio público para las diapositivas. Citar fuentes cc0.
- **IA**: boilerplate para DevGreem (autoloads, loaders JSON), wrappers `.gd` tipados para escenas UI de Ramerlin. Zona de riesgo: game-feel; el checker lo atrapa todo igualmente.

## Proposed 12-hour-block plan

**Bloque A — Horas 0–12: congelar, esqueleto, núcleo caminable.**
- H0–1 (todos, sin código): rúbrica; lista de cortes firmada en `.egm/`; rama jam; mapa de propiedad; schema JSON (economy/events/submissions/demo-states, con procedencia) congelado; plataforma elegida; templates export descargando en background.
- H1–4 Dev: esqueleto de carpetas; autoloads tipados (`GameState`, `ResourceSim`, `EventBus`, `AudioManager` stubs); jugador `CharacterBody2D`; escena principal contigua con 5 shells de salas + zona exterior; clase base de máquina.
- H2–8 Arte/UI: Mijael produce tileset placeholder + sprite del jugador; Ramerlin diseña HUD/menús sobre la rúbrica (mockups, sin código).
- H4–8 Dev: loop de recursos con tick (1 min = 1 h de juego, multiplicadores); rutas O₂ + solar + energía; dispatcher de eventos con una tormenta de números falsos + UI de procedencia; **smoke export H8**.
- H8–12 Dev: zona exterior con 3 POI; herramienta de escaneo → informe 1/3; runner de submisiones + submisión #1; tecla de demo-jump.
- H10–12 Ramerlin: HUD sobre scaffold tipado.
- **Gate H12**: demo caminable de principio a fin de una tormenta con etiqueta de fuente, una submisión completada, un informe. Fallo → ejecutar la lista de cortes v2 pre-acordada (escrita en H1, no improvisada).

**Bloque B — Horas 12–24: completar el loop.**
- H12–16 Dev: tutorial Aurora (seguir + 5 beats de diálogo); intro + aterrizaje como stills skippeables; selector de misión con 2 opciones stub.
- H16–20 Dev: 3 submisiones restantes como datos de plantilla; máquinas restantes; árbol de mejoras (2 por máquina); funciones comms; curva de radiación (umbral 30% daño + tope de salud máxima); 2 tipos de traje.
- H20–24 Dev: contadores de evaluación bloqueados; presets de demo-jump en JSON. **DevGreem duerme ~4 h en esta ventana.**
- H12–24 Ramerlin: caja de diálogo, menús, banners de eventos con etiqueta "archived source", layout de evaluación — strings en inglés en tabla.
- H12–20 Mijael: pass de arte. H20–24 Mijael: recopila citas NTRS + entradas DONKI.
- **Gate H24**: camino completo start→tutorial→tormenta→2 submisiones→informes→demo-jump→evaluación→continuar, exportado. Fallo → tutorial a 3 beats, submisiones a 3, trajes a 1.

**Bloque C — Horas 24–36: presentable, empaquetado, entregado.**
- H24–28 Dev: solo bugfixes; tuning por edición de datos con playtests de 30 min de los novatos. **H28: golden build taggeado; la captura empieza desde él.**
- H28–32 Dev: swap de datos NASA (citas → strings de procedencia, placeholders reemplazados). Solo contenido, no código.
- H28–34 Mijael: captura, vídeo 2–3 min, diapositivas, página de envío. Ramerlin H28–30: pass final de UI; H30+: apoyo visual de presentación.
- H34–36: export fresco desde golden build, subida, ensayo de demo 5 min (DevGreem), parada dura.
- Regla de bloque: **ninguna mecánica o escena nueva después de H24**. Cualquier cambio post-H28 fuerza re-exportar y re-capturar — solo para blockers.

## Bottom line

Build jugable y presentable en 36 h es viable con ~70% de confianza **solo si** las ambiciones se cortan contra la rúbrica en la hora 1, la ceremonia git/PR/worktree se suspende, el demo-jump + control de velocidad entra en alcance, y cada punto abierto recibe los defaults de arriba — sobre todo hacer todo el contenido tunable vía JSON para que los novatos posean datos y el dev posea solo código. Si cada subsección del concepto se trata como requisito literal, la confianza cae a ~30% y el equipo entrega una demo rota. Gates H12 y H24 con listas de corte pre-acordadas; golden build a H28; la historia de 4 jams del equipo sugiere que la mitad del alcance del jam anterior es el objetivo de calibración honesto.
