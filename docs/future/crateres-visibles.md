# Cráteres visibles en el mapa renderizado

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** `add-lunar-map-tile-render`, arte de cráteres

## Objetivo

Que un cráter se lea como cráter en el mundo renderizado, no solo como una
variante de suelo. Hoy `lunar_map_debug.tscn` muestra `CRATER_FLOOR`,
`CRATER_RIM` y `EJECTA` con colores planos, pero la escena de tiles solo los
insinúa con variantes de regolito y rocas. A tamaño de juego el borde del cráter
es demasiado sutil.

## Alcance

- Decidir la representación: calca/loseta de borde de cráter, prop de roca
  alrededor del rim, o una capa de detalle específica.
- Respetar `art-style`: un solo regolito, sin suelos de otro material, sin
  degradados ni antialias; el cráter se marca con forma, sombra y detalle.
- Mantener el determinismo actual: la forma sale del generador y el render no
  introduce aleatoriedad nueva.
- El cráter debe funcionar con los tamaños y densidades configurables de
  `LunarMapConfig`.

## Criterios de aceptación

- A escala 1:1, un cráter generado se distingue del mare/highland por su cuenco
  y su borde, sin depender de una etiqueta.
- Dos cráteres contiguos no forman un mosaico de colores ni un borde cuadrado.
- El cambio se especifica con OpenSpec antes de tocar código y actualiza el
  mapeo de `LunarMapTileMapper` o el arte, no el generador.

## Notas

El mapeo actual está en
`game/content/map/lunar/lunar_map_tile_mapper.gd` y el contrato visual en
`openspec/changes/add-lunar-map-tile-render/`. El diseño padre
(`docs/designs/junior-astronauta-outpost-lunar.md`) pide un exterior pequeño y
legible; no conviene añadir un sistema de cráteres decorativos si no aporta a esa
lectura.
