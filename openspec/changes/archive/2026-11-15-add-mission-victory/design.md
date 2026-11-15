# Design

## Context

Ver `proposal.md` para la motivación. El estado actual relevante:

- `SimState` ya tiene `game_over` y `death_cause`; el tick los escribe al morir
  y `GameSim` pausa el reloj y emite `game_over`.
- La duración de la partida no existe: `sim_smoke` ejecuta 300 ticks como
  número de prueba, no como regla de juego.
- La economía ya centraliza todos los números en filas (`EconomyRow`) y
  `SimState.reset_from_economy()` copia los valores que necesita.
- El HUD (`hud.gd`/`hud.tscn`) se actualiza en cada tick y en cada reinicio, y
  ya se oculta cuando `game_over` es cierto.
- La evaluación (`evaluation.gd`/`evaluation.tscn`) se abre con la señal
  `game_over` y lee el estado congelado y `EventLog`.
- `UiText` es la tabla de strings única del proyecto.

## Goals / Non-Goals

**Goals:**

- Un final de partida por reloj de misión, con victoria o derrota, decidido en
  el núcleo y visible en HUD y evaluación.
- Mantener el cambio pequeño: sin escenas nuevas, sin autoloads nuevos y sin
  dependencias de comunicaciones.

**Non-Goals:**

- Equilibrar la misión de 300 ticks más allá de comprobar que un run pasivo
  llega vivo al final.
- Freeplay, presets de demo, informes, POIs o escaneo.
- Cambiar el significado de `game_over` para otras partes del juego.

## Decisions

### 1. La duración de misión es una fila de economía

Se crea `game/databases/economy_rows/mission_length_ticks.tres` (valor 300,
rango 1–1000, unidad `ticks`, procedencia simulada) y se registra en
`game/databases/economy.tres`. `SimState.reset_from_economy()` la copia a un
campo `mission_length_ticks` con fallback 300.

**Alternativas descartadas:** constante en código (rompe la regla de que todos
los números de gameplay son datos); nuevo autoload `GameState` (el diseño lo
prevé, pero añadirlo solo para un contador amplía la arquitectura y el proyecto
funciona hoy con dos autoloads); duración por escena (la misión debe ser la
misma en cualquier entrada al mundo).

### 2. El desenlace vive en `SimState`, no solo en la causa

Se añade `SimState.RunResult { IN_PROGRESS, VICTORY, DEFEAT }` y
`run_result: RunResult`. `game_over` sigue siendo el único flag que congela el
run y dispara la evaluación; `death_cause` se conserva como "causa que terminó
el run" y vale `&"mission_complete"` en una victoria.

**Alternativas descartadas:** deducir la victoria de `death_cause` (frágil y
opaco para la UI); un booleano `victory` separado (permite estados imposibles
victoria + derrota); renombrar `death_cause` a `end_cause` (toca más archivos y
tests sin cambiar el comportamiento observable; se puede hacer en otro cambio).

### 3. El tick decide el final, con la muerte por delante

`game/scripts/simulation/sim_tick.gd` añade un paso `_apply_mission_end()` justo
después de `_apply_death()` y antes de `_apply_sol_facts()`:

1. Si `game_over` ya es cierto, no hace nada (la muerte del tick manda).
2. Si `tick + 1 >= mission_length_ticks`, marca `game_over`, pone
   `run_result = VICTORY`, `death_cause = &"mission_complete"` y añade un hecho
   `GAME_OVER` con `resources`, `result` y `cause`.

La muerte en `_apply_death()` pasa a poner `run_result = DEFEAT` y añade
`result` al payload de su `GAME_OVER`. Ambos caminos comparten el mismo hecho,
así que el ledger nunca registra dos finales.

**Alternativas descartadas:** comprobar el final en `GameSim` (el núcleo dejaría
de ser determinista por sí solo y el harness `sim_smoke` no lo vería);
comprobar `tick >= 300` antes de simular el último tick (el tick 300 dejaría de
consumir recursos y el reloj no cuadraría con el HUD).

### 4. El HUD muestra un indicador bajo la barra de vida

Se añade un `Label` `ObjectiveLabel` en `game/scenes/ui/hud.tscn` bajo la barra
de vida, centrado, con el estilo de texto del reloj (fuente 8, color claro,
outline de 1 px) y sin panel de fondo. `hud.gd` lo rellena en `_refresh_stats()`
con `UiText.mission_objective_label(total, remaining)`, llamado ya en cada tick,
en el reinicio y al arrancar.

**Alternativas descartadas:** añadir la información al reloj existente (el reloj
ya lleva sol, fase, hora y velocidad; añadir la misión lo hace ilegible);
indicador independiente en la esquina inferior (choca con la hotbar y el prompt).

### 5. La evaluación separa resultado y causa

`evaluation.tscn` añade un `ResultLabel` entre el título y los contadores.
`evaluation.gd` lo rellena con `UiText.result_label(GameSim.state.run_result)`.
La fila de causa existente sigue mostrando la causa; `UiText.end_cause_label()`
reconoce `&"mission_complete"`.

**Alternativas descartadas:** cambiar el título "Mission summary" por el
resultado (el título es fijo y el resultado necesita su propio énfasis);
mostrar solo la causa (una causa de victoria no comunica que se ha ganado).

### 6. Archivos afectados

| Archivo | Cambio |
| --- | --- |
| `game/scripts/simulation/sim_state.gd` | `RunResult`, `run_result`, `mission_length_ticks`, `get_mission_ticks_left()`, reset del resultado. |
| `game/scripts/simulation/sim_tick.gd` | Paso `_apply_mission_end()`, `result` en el payload de `GAME_OVER`, `DEFEAT` en la muerte. |
| `game/scripts/autoloads/game_sim.gd` | `force_end_run()` marca `DEFEAT` y añade `result` al payload. |
| `game/databases/economy_rows/mission_length_ticks.tres` | Fila nueva (300 ticks). |
| `game/databases/economy.tres` | Registro de la fila nueva. |
| `game/scenes/ui/hud.tscn` | `ObjectiveLabel` bajo la barra de vida. |
| `game/scenes/ui/hud.gd` | Relleno del indicador en `_refresh_stats()`. |
| `game/scenes/evaluation/evaluation.tscn` | `ResultLabel` y su separador. |
| `game/scenes/evaluation/evaluation.gd` | Relleno del resultado. |
| `game/scripts/ui/ui_text.gd` | `mission_objective_label()`, `result_label()` y causa `mission_complete`. |
| `game/scripts/dev/sim_smoke.gd` | Comprobaciones de victoria, derrota, prioridad de muerte y reinicio. |

## Risks / Trade-offs

- **El final por defecto puede ser inalcanzable con el balance actual** → el
  primer punto de `sim_smoke` simula 300 ticks sin intervención y exige
  victoria. Si falla, se ajusta solo la fila `mission_length_ticks`, nunca el
  código del tick; si eso rompiera la duración de 300 ticks del diseño, el
  equilibrado de recursos se abre como cambio aparte.
- **Tests existentes que asumen "vivo a los 300 ticks"** → `sim_smoke` es el
  único harness que corre 300 ticks; se amplía para esperar `VICTORY`. El resto
  de harnesses usan ventanas cortas.
- **El indicador del HUD puede tapar la barra de vida o el reloj** → se coloca
  debajo de la barra, con offsets verticales 62–76, fuente 8 y una línea corta;
  se comprueba en una captura a 850×480 antes de cerrar el cambio.
- **La fila nueva se olvida en el índice de economía** → `sim_smoke` falla si
  `mission_length_ticks` no vale 300 en el registro real.
- **`game_over` deja de significar "ha muerto"** → se documenta en el código y
  en la spec; las comprobaciones de UI existentes (`_run_over`, controles de
  tiempo) ya tratan `game_over` como "run terminado" y no necesitan cambios.

## Migration Plan

No hay persistencia ni datos guardados: el cambio entra en la rama del módulo y
se valida con `check-gdscript.sh -p game --strict`, `sim_smoke`, el resto de
harnesses y un arranque headless. Rollback = revertir el commit; no hay estado
en disco que migrar.
