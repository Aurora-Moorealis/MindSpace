# Proposal

## Why

Los sistemas existen por separado: la selección de mundos lleva a la introducción, pero aceptar la misión solo cambia un texto; el mapa lunar se genera y se pinta, pero no hay astronauta que lo recorra; `GameSim` avanza ticks desde el arranque, también en menús, y nunca se reinicia al empezar una misión. El primer hito jugable necesita unirlos: aceptar la misión debe iniciar una partida limpia y abrir el mapa, el astronauta debe moverse con colisión y cámara, y el reloj debe correr solo durante la partida y detenerse al morir.

Este cambio nace del diseño `docs/designs/junior-astronauta-outpost-lunar.md` (CUJ 1, autoload `GameSim`, entrada 17 «astronauta» y entrada 22 «escena base») y del estado real del repositorio. No duplica el diseño: lo referencia.

## What Changes

- **Transición introducción → juego**: aceptar la misión abre `game/scenes/base/base.tscn`; la introducción deja de ser el final del flujo.
- **Escena jugable**: `base.tscn` compone `game/content/map/lunar/lunar_map_world.tscn` y `game/content/entities/astronaut/astronaut.tscn`, coloca al astronauta en el spawn y activa la cámara de juego.
- **Astronauta**: `CharacterBody2D` con el sprite existente `astronaut_4dir.png` (cuatro frames de 32×32), movimiento en ocho direcciones con WASD y flechas, colisión contra `LunarMap.is_walkable`, orientación de cuatro direcciones y velocidad base multiplicada por `player_move_speed_multiplier`.
- **Ciclo de partida**: `GameSim` arranca pausado; la escena jugable ejecuta `start_run()` (reinicio más reloj activo), marca `is_outside = true` y, al llegar la muerte, el reloj se pausa y la partida queda congelada. Al salir de la escena, el reloj se pausa y la marca de exterior se desactiva.
- **Input map**: acciones `move_up`, `move_down`, `move_left` y `move_right` con WASD y flechas en `game/project.godot`.
- **Verificación**: harness headless del mundo jugable y de la transición, además del checker estricto y el arranque sin errores.

## Capabilities

### New Capabilities

- `game-session`: inicio de partida nueva, reloj activo solo en la escena jugable, exposición exterior en la superficie y congelación al morir.
- `astronaut`: aparición en el spawn, movimiento en ocho direcciones, colisión con el terreno, orientación visual y cámara de juego.

### Modified Capabilities

- `intro`: añade el paso de aceptar la misión hacia la escena jugable.

## Impact

- **Código nuevo**: `game/scenes/base/base.gd`, `game/scenes/base/base.tscn`, `game/content/entities/astronaut/astronaut.gd` y `game/content/entities/astronaut/astronaut.tscn`.
- **Código modificado**: `game/scenes/intro/intro.gd` (transición) y `game/scripts/autoloads/game_sim.gd` (ciclo de partida).
- **Configuración**: `game/project.godot` (input map).
- **Pruebas**: `game/tests/playable_world_check.gd` y `game/tests/playable_flow_check.gd` (nuevas; `game/tests/` está ignorada por Git).
- **Sin impacto** en la simulación por ticks, la economía, las máquinas, el ledger, el generador y render del mapa, el arte ni la UI.
- **Rama**: `playable-world` desde `features`; se integra mediante Pull Request.

## Fuera de alcance

- HUD, barras, reloj visible, menú de pausa, multiplicadores ×5/×10 y pantalla de evaluación.
- Interiores, salas, airlock, máquinas interactuables, POIs, escaneo, informes y submisiones.
- Persistencia de partida y semilla distinta por mundo: el mapa usa la semilla por defecto.
- Arte nuevo: se usa el sprite existente `astronaut_4dir.png`.
- Cambios en la selección de mundos, el menú principal o la introducción más allá de la transición.
