# Proposal

## Why

El repositorio aún no tiene código de juego: `game/` solo contiene `project.godot` y el addon MCP. Todo lo que viene después (máquinas, eventos, consola, HUD, pantalla de evaluación y presets de demo) consume un mismo núcleo de simulación determinista por ticks y un ledger de hechos. Sin ese núcleo no se puede codificar nada más sin cablearlo a números inventados.

Este cambio nace del diseño `docs/designs/junior-astronauta-outpost-lunar.md` (secciones «Autoloads», «Modelo de datos», «El loop de simulación» y las entradas 1–4, 5 y 11 del plan de implementación). No duplica ese documento: lo referencia.

## What Changes

- **Nuevo autoload `GameSim`**: reloj determinista por ticks (1 tick = 1 h de juego = 60 s reales a ×1; los multiplicadores ×1/×5/×10 cambian la tasa del tick, nunca `Engine.time_scale`), estado de partida en memoria (O₂, agua, comida, energía, salud, dosis de radiación, hambre, sed, reserva de traje, máquinas) y pipeline de tick en orden fijo: producción → consumos → degradación → escalera de consecuencias.
- **Nuevo autoload `EventLog`**: ledger append-only tipado, con tick y payload por hecho; fuente de los 5 contadores de la pantalla de evaluación y del overlay de debug. Se implementa desde el primer día para no tener que rellenarlo a posteriori.
- **Nuevo schema de economía**: `EconomyData`, `EconomyRow` y `DataProvenance` (campos `source`, `source_url`, `date_archived`, `archived`, `real_data`), más `game/databases/economy.tres` con filas placeholder marcadas `real_data: false`. Ningún número de gameplay queda hardcodeado en el código.
- **Registro de ambos autoloads** en `game/project.godot` y constantes del tick en la misma configuración.
- **Harness headless** de verificación: ejecuta N ticks sobre un estado puro y comprueba determinismo, consumo, escalera de apagado y contadores del ledger sin abrir escenas.
- **Fuera de alcance**: scheduler de eventos y `events.tres`, submisiones, escenas, mapa, astronauta, interacción con máquinas, UI, presets de demo, `DataAudit` y valores NASA reales. Esos cambios se apoyan en este y llegan después.

## Capabilities

### New Capabilities

- `simulation-core`: reloj y estado determinista, economía data-driven, pipeline de tick, reglas de consumo/producción, dosis de radiación irreversible y escalera de consecuencias.
- `event-ledger`: registro append-only de hechos tipados, consulta por tipo y derivación de los contadores de evaluación.

### Modified Capabilities

- Ninguna (no hay specs previas en `openspec/specs/`).

## Impact

- **Código nuevo**: `game/scripts/autoloads/game_sim.gd`, `game/scripts/autoloads/event_log.gd`, `game/scripts/simulation/sim_state.gd`, `game/scripts/simulation/sim_tick.gd`, `game/scripts/simulation/log_entry.gd`.
- **Resources nuevos**: `game/resources/economy/economy_data.gd`, `game/resources/economy/economy_row.gd`, `game/resources/common/data_provenance.gd`.
- **Datos**: `game/databases/economy.tres` (placeholders, `real_data: false`).
- **Configuración**: `game/project.godot` (autoloads).
- **Pruebas**: harness local en `game/tests/` (zona ignorada por Git según AGENTS.md).
- **Sin impacto** en escenas, arte, audio, red ni export; el juego sigue arrancando sin HUD y sin mapa.
- **Rama**: el trabajo se desarrolla en la rama de módulo `sim-core`, creada desde `features`; se integra por Pull Request.
