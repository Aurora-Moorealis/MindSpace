# Proposal

## Why

Tres huecos detectados al revisar `worlds` e `intro`:

- `WorldStore.create_world()` no valida el nombre: la pantalla lo hace antes, pero
  cualquier otra escena que llame a la API puede crear mundos vacíos o repetidos.
- Cancelar con ESC mientras el formulario de creación está abierto vuelve al
  menú principal y descarta el nombre escrito, en vez de volver a la lista.
- Si la introducción se abre sin un mundo seleccionado, el nombre por defecto es
  `"astronauta"`, en español y visible en pantalla.

## What Changes

- `WorldStore.create_world()` aplica las mismas reglas que el formulario (nombre
  no vacío, 24 caracteres, sin duplicados) y devuelve `null` si no cumple.
- ESC en el formulario, cuando hay mundos guardados, cancela la creación y vuelve
  a la lista; en la lista (o sin mundos) sigue volviendo al menú.
- El nombre de reserva de la intro pasa a `"astronaut"`.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `worlds`: la creación valida también en la capa de persistencia y cancelar el
  formulario vuelve a la lista.
- `intro`: nombre de reserva neutro cuando no hay mundo seleccionado.

## Impact

- `game/scenes/worlds/world_store.gd`, `game/scenes/worlds/worlds.gd`
- `game/scenes/intro/intro.gd`
- `openspec/specs/worlds/spec.md`, `openspec/specs/intro/spec.md`

Fuera de alcance: el tamaño del mapa procedural y el resto de hallazgos menores.
