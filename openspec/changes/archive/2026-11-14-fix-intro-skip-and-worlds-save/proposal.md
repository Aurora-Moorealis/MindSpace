# Proposal

## Why

Dos defectos detectados al revisar la integración de `features`:

- Saltar la animación de la intro y avanzar la historia hace que la parte actual
  vuelva a la primera en cuanto termina el tween que seguía en curso. Además,
  saltar durante un fundido a negro puede dejar la historia bajo el fundido.
- `WorldStore` escribe `user://worlds.json` en sitio. Si el juego se cierra a
  mitad de la escritura, el archivo queda truncado y la pantalla lo interpreta
  como «no hay mundos» sin avisar: el jugador pierde sus mundos en silencio.

## What Changes

- La intro cancela el tween activo al saltar y la secuencia no vuelve a mostrar
  la historia; la parte que el jugador esté viendo se conserva.
- El guardado de mundos escribe en un archivo temporal y lo renombra al final.
  Si el archivo existente no se puede interpretar, se conserva como `.bak` y la
  pantalla avisa en lugar de tratarlo como una lista vacía.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `intro`: el salto de la animación detiene el tween y conserva el progreso de
  la historia.
- `worlds`: la persistencia es atómica y un archivo dañado se conserva y se
  reporta.

## Impact

- `game/scenes/intro/intro.gd`
- `game/scenes/worlds/world_store.gd`, `game/scenes/worlds/worlds.gd`
- `openspec/specs/intro/spec.md`, `openspec/specs/worlds/spec.md`

Fuera de alcance: el tamaño por defecto del mapa procedural y cualquier otro
ajuste de la integración de `features` en `main`.
