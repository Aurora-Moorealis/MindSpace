# Proposal

## Why

Los cinco espacios de la hotbar se solapan entre sí: `inventory_slot.tscn` declara
`custom_minimum_size = 48`, así que Godot mantiene cada espacio en 48 px aunque el
HUD los coloque con 36 px de paso. El marco de selección y los iconos tampoco
escalan con el espacio, así que sobresalen del marco de la hotbar.

## What Changes

- El espacio de inventario pasa a medir 36x36 con su marco de selección y su icono
  ajustados a ese tamaño, de modo que cinco espacios entran en el marco sin
  solaparse y con separación uniforme.
- El icono del objeto en la mano y la vista previa de arrastre bajan de 32 a 24 px
  para ir en proporción con el espacio.
- Sin cambios de comportamiento, de simulación ni de especificaciones: la spec
  `hud` ya exige cinco espacios visibles con separación uniforme y esto la cumple.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Es una corrección de geometría dentro de requisitos ya existentes, por eso
el cambio va con `skip_specs: true`.

## Impact

- `game/scenes/ui/inventory_slot.tscn`: tamaño mínimo, marco de selección e icono.
- `game/scenes/ui/inventory_slot.gd`: tamaño de la vista previa de arrastre.
- `game/scenes/ui/hud.gd` y `game/scenes/ui/hud.tscn`: icono en la mano.

## Fuera de alcance

- Rediseñar el arte de la hotbar o de los espacios.
- Cambiar posiciones de la barra de vida, los recursos o el Sol.
- Añadir o quitar espacios de la hotbar.
