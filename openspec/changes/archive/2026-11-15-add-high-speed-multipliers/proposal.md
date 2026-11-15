# Proposal

## Why

La misión dura 300 ticks y los multiplicadores actuales llegan solo a ×10.
Probar el final o recorrer la partida entera obliga a esperar minutos. El
usuario pide ×100, ×1000 y ×10000 para avanzar el reloj de forma agresiva sin
salir del juego.

## What Changes

- Añadir `Speed.X100`, `Speed.X1000` y `Speed.X10000` a `GameSim`, con su tasa
  correspondiente (100/1000/10000).
- Subir `MAX_TICKS_PER_FRAME` de 10 a 400 para que un frame pueda procesar los
  ~167 ticks que exige ×10000 a 60 fps.
- Extender los controles del HUD: el botón `+` recorre ×1 → ×5 → ×10 → ×100 →
  ×1000 → ×10000 y el `-` hace el camino inverso. El reloj y el marcador de
  velocidad muestran el valor nuevo.
- Ensanchar el reloj y el marcador de velocidad para que `x10000` no se recorte.
- Actualizar las specs `simulation-core` y `hud`.

## Capabilities

### Modified Capabilities

- `simulation-core`: multiplicadores de velocidad del reloj.
- `hud`: texto del reloj y límites de los controles de tiempo.

## Fuera de alcance

- Cambiar la duración del tick (sigue siendo 60 s reales a ×1).
- Añadir un desplegable de velocidades o botones directos.
- Cambiar el render, el HUD de recursos o la lógica de simulación.
- Añadir un fast-forward visual o saltar animaciones.

## Impact

- `game/scripts/autoloads/game_sim.gd` (enum, `get_rate`, cap de frame).
- `game/scenes/ui/hud.gd` (`_speed_text`, `_step_speed`).
- `game/scenes/ui/hud.tscn` (anchos de `ClockLabel`, `SpeedValue` y
  `TimeControls`).
- `game/tests/clock_check.gd` (prueba local ignorada, se actualiza para
  verificar las tasas y el cap).
