# Proposal

## Why

El núcleo ya modela las ocho máquinas como salud, encendido y mejora, pero no puede repararlas ni mejorarlas, y su consumo de energía vive en filas globales de economía en vez de en la ficha de cada máquina. Tampoco existe un lugar explícito para las estadísticas del astronauta que las mejoras pueden alterar. Sin esa separación, la consola, el HUD, los eventos de avería y el bucle de recursos no tienen nada que accionar.

Este cambio nace del diseño `docs/designs/junior-astronauta-outpost-lunar.md` (entradas 8 y 18). Se limita a lógica, funcionamiento y resources; arte, escenas y paneles llegan después.

## What Changes

- **Ficha de máquina**: `MachineData` (id, nombre, pista, tiempo de reparación en divisiones, coste de reparación, lista única de consumos por tick y mejoras), `MachineConsumption` y `UpgradeData`, con índice `MachineDatabase`.
- **Consumo propio**: los consumos por tick salen de `economy.tres` y pasan a cada ficha como una única lista de recurso + cantidad; una máquina puede no consumir nada (por ejemplo, el panel solar) o consumir energía y otros recursos.
- **Jugador**: `PlayerStats` con velocidad de reparación, velocidad de movimiento, hambre máxima y sed máxima; viven en el jugador, no en las máquinas. La radiación queda para después.
- **Economía**: se eliminan 8 filas `power_*_per_tick` y se añaden 4 filas base de jugador; el índice queda en 52 filas.
- **Estado y tick**: `MachineState` gana trabajo de reparación, mejoras y deltas; `SimState` gana `player`; el tick recibe el registro de máquinas, consume según cada ficha y acumula la velocidad de reparación del jugador.
- **API**: `GameSim` inicia reparaciones, consulta progreso y aplica mejoras con rechazos; hechos `REPAIR` y `UPGRADE`.
- **Verificación**: `machines_smoke.gd` y `sim_smoke.gd` actualizado.

## Capabilities

### New Capabilities

- `machines`: fichas data-driven con consumo propio, reparación por divisiones, mejoras de un solo uso y efectos sobre el tick y las estadísticas del jugador.

### Modified Capabilities

- `simulation-core`: consumo por máquina desde su ficha, etapa de trabajos de máquina, valores efectivos y `PlayerStats` en el estado.

## Impact

- **Código nuevo**: `game/resources/machines/machine_consumption.gd`, `upgrade_data.gd`, `machine_data.gd`, `machine_database.gd`; `game/scripts/simulation/player_stats.gd`; `game/scripts/dev/machines_smoke.gd`.
- **Código modificado**: `machine_state.gd`, `sim_state.gd`, `sim_tick.gd`, `game_sim.gd`, `game/scripts/dev/sim_smoke.gd`.
- **Datos**: 8 fichas en `game/content/machines/<id>/<id>.tres`, `game/databases/machines.tres`, 4 filas `player_*` nuevas y 8 filas `power_*` eliminadas de `economy.tres`.
- **Sin impacto** en escenas, arte, audio, red ni export. El juego sigue arrancando sin HUD ni mapa.
- **Rama**: `machines`, creada desde `features`; se integra por Pull Request.

## Fuera de alcance

- Escenas `.tscn`, sprites, tiles y cualquier trabajo de arte.
- `machine_base.gd` de interacción, paneles de máquina, HUD, jugador y airlock.
- El contenido concreto de las mejoras (roster 8×2 indefinido): las fichas se entregan vacías y el schema queda listo.
- La radiación y su tolerancia: se añadirán más adelante, cuando exista traje o refugio que las consuma.
- Eventos (avería, polvo y limpieza del panel), submisiones, comunicaciones, traje, refugio, presets de demo y pantalla de evaluación.
- `strings.tres`, `DataAudit`, valores NASA, tuning, persistencia, audio y export.
