# Proposal

## Why

El proyecto arranca en el menú de entrada (`res://scenes/welcome/welcome.tscn`), así
que al ejecutar el juego —o al pulsar Play en el editor— no se ve nada del bucle
jugable: ni el outpost generado, ni el HUD, ni el astronauta. Para probar la partida
hay que atravesar menú, selector de mundos e intro, y durante el desarrollo eso hace
que la escena "real" parezca no estar conectada.

El bucle jugable ya está cerrado y verificado (`connect-playable-loop`, PR #17), así
que la escena que debe recibir al jugador al arrancar es la partida, no el menú.

## What Changes

- `game/project.godot`: `run/main_scene` pasa de `res://scenes/welcome/welcome.tscn`
  a `res://scenes/base/base.tscn`.
- El menú de entrada deja de ser la primera pantalla, pero sigue siendo accesible
  desde la evaluación de la misión ("Back to menu"), y desde ahí se mantiene el flujo
  menú → mundos → intro → partida.
- No se toca ninguna otra escena, ni el contenido, ni la simulación.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `menu`: el requisito de arranque deja de exigir el menú como primera pantalla y
  pasa a exigir la escena jugable, conservando el acceso al menú desde la evaluación.

## Impact

- `game/project.godot` (`run/main_scene`).
- `openspec/specs/menu/spec.md` (requisito de arranque).
- Sin cambios en escenas, assets, datos ni código de juego.

## Fuera de alcance

- Eliminar el menú, el selector de mundos o la intro: siguen existiendo y se alcanzan
  desde la evaluación.
- Cambiar el flujo menú → mundos → intro.
