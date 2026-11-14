# Proposal

## Why

Desde la spec del terreno se añadieron tres cosas sin pasar por OpenSpec: la
selección de mundos, la introducción narrativa y el contrato de los TileSets.
El código funciona, pero no hay contrato escrito y el siguiente agente no sabe
qué debe respetar.

Este cambio documenta lo que ya está implementado y lo deja en `openspec/specs/`.

## What Changes

- Nueva capability `worlds`: crear, listar, elegir y borrar mundos guardados.
- Nueva capability `intro`: animación de salida y travesía, historia por partes,
  sustitución del nombre y aceptación de la misión.
- Nueva capability `world-map`: los tres TileSets, los datos por loseta y las
  cuatro orientaciones del muro.

No cambia código: solo fija el contrato de lo que ya existe.

## Capabilities

### New Capabilities

- `worlds`: pantalla de mundos guardados y su persistencia.
- `intro`: introducción narrativa entre la elección de mundo y el juego.
- `world-map`: construcción del mundo con losetas y datos por loseta.

### Modified Capabilities

Ninguna. `menu` y `art-style` no cambian.

## Impact

- `openspec/specs/worlds/`, `openspec/specs/intro/` y `openspec/specs/world-map/`.
- Sin cambios en `game/`: el código ya está en la rama `worlds`.

## Fuera de alcance

- La pantalla de configuración y el selector de misión: siguen en `docs/future/`.
- La base jugable: es el siguiente bloque.
- Reescribir el código para que encaje mejor con la spec.
