# Proposal

## Why

El arte del juego (suelo, rocas y base) necesita colores que la paleta de
identidad no cubre: regolito, basalto, ilmenita, material silícico y hielo. La
spec `art-style` dice explícitamente que un color nuevo se añade a la spec antes
de usarse, así que ese es el paso previo a dibujar un solo píxel.

## What Changes

- La paleta del juego pasa a ser la unión de la **paleta de identidad** y una
  **paleta de terreno** nueva (cinco rampas, 16 colores).
- Se añade la convención de **rejilla de mundo**: losetas de 32×32 píxeles de
  pantalla (16×16 de arte) y suelos teselables.
- Se documenta qué cuatro materiales existen en el terreno y por qué son
  lunares, para que cualquier agente dibuje lo mismo.

## Capabilities

### New Capabilities

Ninguna. Es una modificación de `art-style`.

### Modified Capabilities

- `art-style`: el requisito "Paleta cerrada" pasa a definir la paleta del juego
  como identidad + terreno, y se añaden tres requisitos (paleta de terreno,
  rejilla de mundo, materiales del terreno).

## Impact

- `openspec/specs/art-style/spec.md`.
- `art/tiles/` y `game/content/map/` (arte nuevo, fuera de esta spec).
- Sin cambios de código.

## Fuera de alcance

- Los tilesets en sí: este cambio solo fija las reglas que deben cumplir.
- Añadir minerales nuevos: los cuatro elegidos van cerrados.
