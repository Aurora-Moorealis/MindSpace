# Proposal

## Why

El fin de misión forzado de depuración está en `F10`, una tecla de función
alejada de la zona de juego y fácil de pulsar sin querer en portátiles. La `;`
queda junto a la mano derecha y no compite con ningún control de la partida.

## What Changes

- La acción `debug_end_run` de `game/project.godot` pasa de `F10` a la tecla
  `;`, ligada por **keycode** (`KEY_SEMICOLON`) en lugar de por posición física,
  para que funcione igual en distribuciones donde `;` exige `Shift` (español y
  latinoamericano) y en la distribución US.
- Sin cambios en el resto del código: `run_ui.gd` sigue consultando la misma
  acción y el botón "End mission (debug)" sigue igual.
- La tecla sigue disponible solo en builds de depuración (`OS.is_debug_build()`).

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Es un remapeo de una entrada de depuración dentro de un requisito ya
cubierto, por eso el cambio va con `skip_specs: true`.

## Impact

- `game/project.godot`: único evento de la acción `debug_end_run`.
- Sin cambios en escenas, scripts, simulación ni textos de jugador.

## Fuera de alcance

- Cambiar el botón de fin de misión o su visibilidad.
- Añadir más atajos de depuración.
- Modificar la documentación archivada del cambio `connect-playable-loop`, que
  registra el valor histórico `F10`.
