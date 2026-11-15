# Proposal

## Why

Dos ajustes de presentación pedidos al probar la build:

1. El indicador de misión está centrado bajo la barra de vida y compite con el
   resto del HUD. Se lee mejor en la esquina superior derecha, debajo del reloj y
   de los controles de tiempo.
2. El ejecutable arranca directamente en el outpost (`run/main_scene` apunta a
   `base.tscn`), así que el menú principal nunca aparece. El flujo de entrada
   debe volver a empezar en la pantalla de bienvenida.

## What Changes

- Mover `ObjectiveLabel` en `game/scenes/ui/hud.tscn` a la esquina superior
  derecha, debajo del reloj y de los controles de tiempo, alineado a la derecha.
- Cambiar `run/main_scene` en `game/project.godot` a
  `res://scenes/welcome/welcome.tscn`.
- Actualizar las specs `hud` y `menu` para reflejar la nueva posición y el
  arranque en el menú.

## Capabilities

### Modified Capabilities

- `hud`: la posición del indicador de misión.
- `menu`: el arranque del juego vuelve al menú; se retira el arranque directo al
  outpost.

## Fuera de alcance

- Cambiar el contenido del menú o del selector de mundos.
- Tocar el flujo worlds → intro → outpost.
- Reordenar el resto del HUD, la barra de vida, los recursos o la hotbar.
- Cambiar la lógica de victoria, el reloj o el balance.

## Impact

- `game/scenes/ui/hud.tscn` (offsets y alineación del `ObjectiveLabel`).
- `game/project.godot` (`run/main_scene`).
- `openspec/specs/hud/spec.md` y `openspec/specs/menu/spec.md` (delta).
