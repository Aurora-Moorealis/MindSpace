# Proposal

## Why

La partida actual no se puede ganar: solo termina al morir el astronauta, así que
la evaluación siempre presenta una derrota y la demo no tiene un arco cerrado.
Hace falta el primer objetivo funcional que defina la victoria, y que no dependa
de la consola de comunicaciones, todavía sin implementar.

## What Changes

- Añadir un **reloj de misión de 300 ticks**, configurable como fila de economía.
- Declarar la **victoria al llegar al tick 300 con el astronauta vivo**; morir
  antes es derrota. Al cerrarse el run, el reloj se congela y se abre la
  evaluación, igual que en una muerte.
- Mostrar en el HUD el objetivo ("Survive 300h") y las horas de misión restantes.
- Mostrar en la evaluación el **resultado de la misión** ("Mission accomplished"
  o "Mission failed") junto a la causa y los contadores existentes.
- Registrar el resultado en el hecho de fin de partida del ledger.
- Reiniciar el reloj y el resultado de misión con cada partida nueva.
- El fin forzado de depuración cuenta como derrota con causa `debug`.

La victoria por informes del diseño formal
(`docs/designs/junior-astronauta-outpost-lunar.md`) queda sustituida de forma
temporal por esta regla de supervivencia: el diseño ya contempla la consola sin
exterior como corte de emergencia, y aquí se recorta un paso más para entregar
una partida ganable ya. La victoria por informes se retomará cuando exista la
consola.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `simulation-core`: el tick evalúa el reloj de misión y declara victoria o
  derrota una sola vez.
- `game-session`: la congelación del run y el reinicio cubren el final por
  reloj, no solo la muerte.
- `evaluation`: la pantalla muestra el resultado de la misión y se abre también
  al ganar.
- `hud`: nuevo indicador persistente del objetivo de misión.
- `event-ledger`: el hecho de fin de partida incluye el resultado del run.

## Fuera de alcance

- Consola de comunicaciones, informes enviados, POIs exteriores y escaneo.
- Botón de "continuar jugando" (freeplay) tras la victoria.
- Presets de demo-jump y equilibrado fino de los 300 ticks.
- Finales alternativos (objetivos científicos, submisiones).

## Impact

- `game/scripts/simulation/sim_state.gd` y `game/scripts/simulation/sim_tick.gd`.
- `game/scripts/autoloads/game_sim.gd`.
- `game/databases/economy.tres` y nueva fila
  `game/databases/economy_rows/mission_length_ticks.tres`.
- `game/scenes/ui/hud.gd`, `game/scenes/ui/hud.tscn`,
  `game/scenes/evaluation/evaluation.gd`, `game/scenes/evaluation/evaluation.tscn`
  y `game/scripts/ui/ui_text.gd`.
- `game/scripts/dev/sim_smoke.gd` (regresión del final de misión).
- Sin cambios en `scenes/base`, el astronauta, las máquinas ni el arte.
