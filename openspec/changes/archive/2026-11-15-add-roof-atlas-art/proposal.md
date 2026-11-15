# Proposal

## Why

El outpost necesita techo: las salas del diseño formal se ven a cielo abierto y el
arte de cubierta no existía. Además hacía falta una lámina de composición para
comprobar cómo encajan las 19x14 losetas de la base con las máquinas, la esclusa y
el panel solar exterior antes de construir el mapa.

## What Changes

- Nuevo atlas de techo (`roof_atlas.png`, 4x5 losetas de 16x16) con sus variantes
  de borde y esquina, generado desde `roof_atlas.aseprite`.
- Nueva lámina de diseño de la base (`base_plan.aseprite`, tres frames: corte
  interior, cerrada y techo transparente) y sus tres capturas a 850x480 para
  revisión.
- Nuevo generador `art/tiles/base/build-plan.lua`, que compone la lámina a partir
  del arte real del proyecto y exporta el atlas.
- Sin cambios de comportamiento: el atlas todavía no se usa en ninguna escena ni
  tileset.

## Capabilities

### New Capabilities

Ninguna: es arte y material de diseño, no comportamiento.

### Modified Capabilities

Ninguna. El cambio va con `skip_specs: true` por ese motivo.

## Impact

- `art/tiles/base/`: `base_plan.aseprite`, `roof_atlas.aseprite`, `build-plan.lua`
  y las tres capturas `_plan-*.png`.
- `game/content/map/tiles/roof_atlas.png` y su `.import`.

## Fuera de alcance

- Crear el `TileSet` de techo, pintar el techo en el mapa lunar o alternar salas
  cubiertas y descubiertas.
- Colocar la esclusa 2x2 o cambiar el mapa generado.
- Sustituir el arte de suelo, muros o props existentes.
