# Proposal

## Why

La rampa de regolito elegida en `terrain-palette` (`#CFCCC7 #AAA7A2 #85827E
#67645F`) tenía demasiado beige: a tamaño de juego el suelo se leía como arena,
no como regolito lunar. La revisión del arte lo dejó claro.

Se corrige la rampa hacia un gris neutro, alineado con el gris del fondo del
menú, que es el look lunar ya establecido en el proyecto.

## What Changes

- La rampa de regolito pasa a `#C6C4C6` `#A9A7AB` `#8A888E` `#6B6970`.
- Nada más: basalto, ilmenita, silícico y hielo se quedan igual.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `art-style`: el requisito "Paleta de terreno" cambia los cuatro tonos de
  regolito.

## Impact

- `openspec/specs/art-style/spec.md`.
- `art/tiles/ground/build-ground.lua` y los PNG regenerados.

## Fuera de alcance

- El resto de rampas de terreno.
- La paleta de identidad.
