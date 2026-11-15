# Proposal

## Why

La victoria a 300 ticks es inalcanzable con el balance actual. La base arranca
con 5/10 de energía, consume 1.9 por tick y el panel produce 1.5: en el tick 12
la batería llega a 0 y el blackout apaga luces → hidropónica → reciclador →
sistema de O₂. Las máquinas **no se vuelven a encender nunca**, aunque la
batería recupere carga, así que la base queda muerta. Un run pasivo muere en el
tick 210 por hipoxia. Bajar el reloj a 200 solo haría ganar en una base apagada.

## What Changes

- **Recuperación tras el apagón:** cuando una red vuelve a tener carga, las
  máquinas apagadas se encienden en orden inverso al apagado (O₂ → reciclador →
  hidropónica → luces), como máximo `blackout_steps_per_tick` por tick. Una
  máquina averiada espera a ser reparada.
- **Ajuste de energía data-driven:** subir `solar_output_per_tick` y
  `capacity_energy` para que un run pasivo llegue vivo al tick 300 con todas las
  máquinas encendidas. Los eventos siguen exigiendo reparaciones; no se toca el
  consumo por máquina.
- **Ajuste de hambre y sed:** bajar `hunger_drain_per_tick` y
  `thirst_drain_per_tick` de 0.5 a 0.3 para que los 100 puntos duren los 300
  ticks. Sin mecánica de comer/beber, el drenaje actual mata en el tick 249
  aunque la energía sea perfecta.
- **Tests:** `sim_smoke` prueba la recuperación y exige `VICTORY` en el run real
  de 300 ticks; `machines_smoke` sigue en verde.

## Capabilities

### Modified Capabilities

- `simulation-core`: nueva recuperación tras el apagón, sin cambiar la escalera
  de apagado existente.

## Fuera de alcance

- Toggle manual de energía en el panel de máquina.
- Cambiar el consumo de las máquinas o la producción de O₂/agua/comida.
- Mecánica de comer/beber: el hambre/sed se ajusta por datos, no con UI nueva.
- Presets de demo, consola/informes, freeplay.
- Bajar la duración de misión: sigue en 300 ticks.

## Impact

- `game/scripts/simulation/sim_tick.gd` (recuperación).
- `game/databases/economy_rows/solar_output_per_tick.tres` y
  `capacity_energy.tres` (energía).
- `game/databases/economy_rows/hunger_drain_per_tick.tres` y
  `thirst_drain_per_tick.tres` (hambre y sed).
- `game/scripts/dev/sim_smoke.gd` (recuperación y victoria real a 300 ticks).
- `game/scripts/dev/machines_smoke.gd` solo si la verificación detecta una
  expectativa de energía fija.
