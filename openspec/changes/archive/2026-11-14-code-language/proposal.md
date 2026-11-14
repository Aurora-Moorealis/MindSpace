# Proposal

## Why

`AGENTS.md` ganó una regla nueva: **el código y los comentarios van en inglés**;
la documentación puede seguir en el idioma del usuario. La capability
`ui-language` que escribí dice lo contrario ("los comentarios siguen en
español"), así que la spec y la regla del repositorio se contradicen.

## What Changes

- El requisito "Idioma de la documentación" pasa a: la documentación en español,
  el código (comentarios, identificadores y mensajes de log) en inglés.
- Los comentarios de los scripts de este trabajo se traducen al inglés para
  cumplir la regla.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `ui-language`: cambia el requisito que repartía idiomas entre documentación,
  comentarios y archivos.

## Impact

- `openspec/specs/ui-language/spec.md`.
- `game/scenes/**/*.gd`: comentarios traducidos.

## Fuera de alcance

- Traducir comentarios de `tests/` (no se versiona).
- Cambiar identificadores: ya estaban en inglés.
