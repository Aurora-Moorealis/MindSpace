# Proposal

## Why

El suelo seguía sin convencer: la rampa anterior era demasiado clara y el
terreno se dividía en losetas de materiales distintos, que a tamaño de juego se
leen como cuadros de color y rompen la sensación de una sola superficie lunar.

Se corrige el tono hacia un regolito oscuro y se separa el material del depósito:
el suelo es uno, y los minerales se colocan encima como calcas.

## What Changes

- La rampa de regolito pasa a `#8B8884` `#726F6B` `#585551` `#403E3B` (oscura).
- El terreno deja de tener losetas de ilmenita, silícico, hielo y basalto: esos
  cuatro materiales pasan a ser **depósitos sueltos** sobre el suelo.
- El atlas de suelo baja de 4×4 a 4×2 variantes de regolito.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `art-style`: cambian "Paleta de terreno" (rampa de regolito) y "Materiales del
  terreno" (un solo suelo + depósitos).

## Impact

- `openspec/specs/art-style/spec.md`.
- `art/tiles/ground/` y `game/content/map/tiles|props/`.
- `ground_tileset.tres` pasa de 16 a 8 losetas.

## Fuera de alcance

- La base: no cambia.
- El resto de rampas de mineral.
