# Proposal

## Why

El diseño formal describe al astronauta como el único avatar del juego
(`docs/designs/junior-astronauta-outpost-lunar.md`, punto 17), pero solo existe su
hoja de sprites: no hay escena, no se mueve, no interactúa con las máquinas y la
radiación de exterior nunca se activa porque nadie escribe `is_outside`. Sin este
cambio, la base lunar no se puede jugar.

## What Changes

- Nueva capability `astronaut`: movimiento en cuatro direcciones, interacción por
  cercanía, dos tipos de traje, zona interior/exterior y vitales expuestos.
- El astronauta escribe `is_outside` y el nivel de traje en `GameSim`, para que el
  tick aplique la dosis de radiación que ya modela.
- La radiación de exterior pasa a multiplicarse por el traje: el traje reforzado
  reduce la ganancia futura (fila nueva de economía).
- Nueva `airlock_zone` mínima para marcar el exterior; el mapa definitivo la
  usará como límite de reglas.
- Mapa de inputs del jugador en `project.godot` (`move_*`, `interact`).

## Capabilities

### New Capabilities

- `astronaut`: avatar jugable, interacción, traje, zona y vitales.

### Modified Capabilities

- `simulation-core`: el requisito de radiación incorpora el multiplicador del
  traje reforzado.

## Impact

- `game/content/entities/astronaut/astronaut.tscn` y `astronaut.gd`.
- `game/content/entities/astronaut/astronaut_4dir@2x.png` (export del arte).
- `game/content/map/airlock/airlock_zone.tscn` y `airlock_zone.gd`.
- `game/scripts/simulation/sim_state.gd` y `sim_tick.gd` (nivel de traje).
- `game/scripts/autoloads/game_sim.gd` (`set_outside`, `set_suit_level`).
- `game/databases/economy.tres` y `economy_rows/suit_v2_radiation_multiplier.tres`.
- `game/project.godot` (mapa de inputs).
- `game/scripts/dev/sim_smoke.gd` (prueba del multiplicador de traje).

## Fuera de alcance

- Animación de caminata: la hoja actual tiene un frame por dirección; el cambio
  usa esa hoja tal cual.
- Panel de interacción de máquinas, reparación y mejoras: el astronauta solo
  detecta el objetivo y llama a `interact()`.
- Inventario, recogida de objetos y crafteo.
- Airbag/oxígeno de traje independiente del recurso de la base: la reserva de
  traje ya vive en `SimState`.
- Mapa completo, puertas y salas: solo la zona de exterior mínima.
- Cámara, HUD y pantalla de pausa.
