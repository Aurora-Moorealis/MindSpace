# Goldfish Review — Stage 6: Comprehension Test

**Target:** `docs/designs/junior-astronauta-outpost-lunar.md` — FeatureRange 1–288, DetailedRange 289–464
**Estándar:** ninguno (auto-contención; sin estándar de re-implementación).
**GoldfishContext:** ninguno.

## What this proposes

El documento propone un juego Godot 4.7 singleplayer para el NASA Space Apps Challenge 2026 (~36 horas, tres personas: programador fuerte + artista, programador novel de UI y un ayudante de datos): un astronauta junior en una base lunar fija de 5 salas que mantiene 4 recursos (O₂, agua, comida, energía) reparando/mejorando 8 máquinas, acumula radiación irreversible al salir al exterior, sobrevive eventos lunares data-driven (5 arquetipos dirigidos por filas) cuyos números muestran procedencia NASA (`source`, `source_url`, `date_archived`, `archived`, `real_data`; etiquetas "archived"/"simulated"), y cumple una misión científica (escanear 3 POIs → enviar 3 informes desde la consola de comunicaciones); toda partida, gane o pierda, termina en una pantalla de evaluación con 5 contadores derivados de un ledger `EventLog` append-only. Arquitectónicamente: un único bucle de ticks determinista (1 tick = 1 h de juego = 60 s reales; multiplicadores ×1/×5/×10 cambian la tasa) en un autoload `GameSim`, junto a `GameState`, `EventLog` y `AudioManager`; todo contenido variable (economía, eventos, submisiones, mejoras, presets de demo, strings) son filas `.tres` de Resources tipados, validadas pre-commit por un `DataAudit` headless; incluye presets de demo-jump capturados por el motor con validador de invariantes, guardarraíles de integración (un dueño por archivo, commits de datos atómicos, protocolo anti-uid) y un plan de implementación archivo-por-archivo en bloques H0–H28 con gates H8/H12/H24/H28.

## How the existing system works, per this document

No existe juego previo: el documento arranca de un repo de jam nuevo que debe seguir los contratos de carpetas del AGENTS.md del repositorio (`content/`, `scenes/`, `scripts/autoloads/`, `databases/`, `resources/`…), con una rama única de jam durante el evento e integración posterior a `features` por PR. El "sistema" de partida es el equipo y sus herramientas: DevGreem (autor: lógica, arte, `project.godot`, escena base), Ramerlin (UI y strings en inglés), el ayudante Mijael (filas de datos y archivos NASA), los artefactos de ideación previos (`.egm/concepts_brief.md`, 14 reportes de dos pasadas de revisión que recortaron un alcance 2–3× sobredimensionado) y utilidades locales (`check-gdscript.sh --strict`, Godot headless, dock FileSystem para el protocolo anti-uid). El contenido NASA aún no existe en el repo: los archivos archivados DONKI/CRaTER/NTRS se descargarán a `game/databases/sources/` entre H12–24; hasta entonces todas las filas son placeholders etiquetados "simulated".

## Prioritized Findings

### M1. La cadena escaneo → muestra → informe no está conectada — Severity: Major

- **Affected Scope:** "Misión, submisiones y tutorial" (153), `game_state.gd` (304, contadores "escaneos, muestras, informes"), `submissions.tres` (370, "3 muestras").
- **Discrepancy Description & Rationale:** la línea 153 dice que escanear produce "un resultado de escaneo", que las muestras se entregan en la consola y victoria = 3 informes. Nunca se dice de qué surge la muestra (¿del escaneo?), si entregar la muestra es prerrequisito del informe de ese POI, ni la relación entre los tres contadores de `GameState`. Quien implemente el loop de misión tendrá que inventar ese flujo.

### M2. "Lecturas de temperatura" sin sistema que las produzca — Severity: Major

- **Affected Scope:** CUJ 3 (71), enum de condiciones (154, `reading_before_event`), `submission_data.gd` (334), `submissions.tres` (370).
- **Discrepancy Description & Rationale:** la primera submisión exige "2 lecturas de temperatura antes de la tormenta" pero ninguna de las 8 máquinas ni otro sistema descrito produce "lecturas". No se dice de dónde se toma (¿consola? ¿exterior? ¿qué interacción?), si conlleva dosis EVA, ni qué contador la incrementa. Es una acción de gameplay completa que no existe en el documento.

### M3. "Pedidos" (pedido de recursos) referido 4 veces y nunca definido — Severity: Major

- **Affected Scope:** 145 ("bloquea previsión y pedidos"), 398 (`comms_console`: "pedido"), 433 (`comms_panel.tscn`: "pedido").
- **Discrepancy Description & Rationale:** qué se puede pedir, desde dónde, qué cuesta, qué latencia/llegada tiene y cómo se simula sin HTTP no están en ninguna frase. "Previsión" sí queda definida; "pedido" no. Quien implemente `comms_panel` debe diseñar el sistema entero desde cero.

### M4. Matriz de mejoras "8×2" indefinida y contradictoria; roster de hidden stats nunca enumerado — Severity: Major

- **Affected Scope:** Q6 (50, "la lista 8×2"), `machine_data.gd` (340), lista de máquinas (398), loop (141).
- **Discrepancy Description & Rationale:** "8×2" se infiere (8 máquinas × 2 mejoras) pero hidropónica está anotado "(2 mejoras)" y el refugio lista solo "cerrojo + mejora de blindaje" (1). No queda claro si todas tienen 2 (la anotación sobra) o no ("8×2" es falso). Tampoco se enumeran las hidden stats (se nombran reparación y movimiento condicional; no hay lista canónica). Como Q6 depende de esa matriz, quien escriba `machine_data`/`economy` debe adivinar conteos.

## Nits

1. **N1 — La notación de horas H1/H8/H12/H24/H27/H28/H34 nunca se define** (todo el documento; primer uso línea 26). Una línea: "H<n> = hora n del evento desde el inicio (H0)".
2. **N2 — La unidad "sol" y su relación con el tick no se explicita** (30, 364): 1 sol = 24 ticks se deduce; "12 soles" de contenido para una misión de 12,5 es aritmética que el lector repite solo.
3. **N3 — Acrónimos y datasets NASA sin expandir ni enlazar** (15, 145, 276): DONKI/NTRS/CRaTER/MSL-RAD con glosa funcional pero sin expansión ni URL; "EVA" jamás expandido; la línea 276 encarga descargar sin dar URL.
4. **N4 — Jolt aparece una vez como decisión implícita sin estar establecida** (NFR 266; `project.godot` ítem 26 no menciona backend de física).
5. **N5 — "Una pasada de ~300 ticks en segundos" no tiene consumidor descrito** (NFR 264): presets son constructores explícitos y ×10 corre en tiempo real; el requisito cuelga sin mecanismo.
6. **N6 — No hay mapeo máquina → sala; el refugio no encaja en las 5 salas** (11, 398): dónde viven o2_system, water_recycler y storm_shelter es adivinable pero no dicho; "storm_shelter" sugiere una sexta sala; "energía con panel solar" vs solar_array exterior.
7. **N7 — "Excepción de carpeta registrada" sin referencia verificable** (123, 387): no se dice dónde está registrada ni se enlaza.
8. **N8 — Recuperación de salud nunca descrita** (141, 322): solo vías de daño; ¿regeneración/descanso/curación? El lector tiene que suponerlo.
9. **N9 — Comportamiento de radiación interior redactado de dos formas** (11: "limitan" vs 149: "no crece"): dosis reducida vs dosis cero; el airlock corta la ganancia por completo o hay goteo.

## Bottom line

Ambos rangos son parafraseables y conectan entre sí — el documento sobrevive el test de que las partes conecten — sin blockers. Los 4 Majors son el loop de misión y sus objetos (cadena muestra/informe, lecturas de temperatura, pedidos) más la matriz 8×2 sin expandir: acciones de gameplay y datos que el implementador tendría que inventar. Los 9 nits son definiciones de una línea (H-notación, sol, acrónimos, mapeo sala→máquina, salud, radiación interior) que cierran el auto-contenimiento del documento.
