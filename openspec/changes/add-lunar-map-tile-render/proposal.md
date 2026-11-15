# Proposal

## Why

El generador procedural produce una `LunarMap` determinista y el arte del mundo
existe en `game/content/map/tiles/` y `game/content/map/props/`, pero siguen
separados: la única vista es `lunar_map_debug.tscn`, con rectángulos planos, y la
única tilemap real es `tiles_demo`, pintada a mano. Sin un puente, el generador
no puede usarse en el mundo del juego.

Este cambio pinta una `LunarMap` en las capas reales y añade una escena de mapa y
otra de revisión con cámara libre. No introduce jugador, colisiones ni gameplay.

## What Changes

- **Puente de render en `game/content/map/lunar/`**: un mapper puro que traduce
  terreno y tile a losetas de los tres TileSets, y un renderer que vuelca la
  rejilla en `TileMapLayer`.
- **Capa de suelo**: todas las celdas se pintan con variantes de regolito,
  elegidas de forma determinista por seed y coordenada.
- **Capa de base**: la zona de aterrizaje (`LANDING_PAD`) se pinta como
  plataforma metálica, con plancha interior y rejilla de borde.
- **Capa de props**: `ROCK` y `RIDGE` reciben rocas sólidas; ninguna celda
  transitable recibe un prop sólido.
- **Escena `lunar_map_world.tscn`**: tres `TileMapLayer` con los TileSets reales,
  cámara en el spawn a escala de juego y generación desde una `LunarMapConfig`.
- **Escena de revisión**: `lunar_map_camera_debug.tscn` instancia el mundo y
  mueve la cámara con WASD a escala 1:1 para recorrer el mapa.
- **Verificación headless**: harness de cobertura, mapeo, determinismo, props,
  escena y cámara de revisión.
- **Sin cambios en el generador**: `LunarMap`, `LunarMapGenerator` y
  `LunarMapConfig` se consumen tal cual; `lunar_map_debug.tscn` se conserva.
- **Rama**: `map-render`, en el checkout principal, integrada por Pull Request a
  `features`.

## Capabilities

### New Capabilities

- `lunar-map-rendering`: representación de una `LunarMap` sobre las tres capas
  de tiles, con correspondencia terreno→loseta, plataforma, props de
  rocas/crestas, determinismo, escena de mapa real y escena de revisión con
  cámara libre.

### Modified Capabilities

- Ninguna. `lunar-map-generation` conserva su contrato y `world-map` sigue
  describiendo los TileSets; este cambio solo los conecta.

## Impact

- **Código nuevo**: mapper, renderer, escena de mundo, escena de revisión y
  harness en `game/content/map/lunar/`.
- **Recursos existentes**: se usan los tres TileSets de `content/map/`; no se
  modifican.
- **Configuración**: `project.godot`, autoloads y escenas compartidas no cambian.
  Las escenas nuevas se abren explícitamente.
- **Simulación y gameplay**: ninguna integración con `GameSim`, `EventLog`,
  astronauta, cámara de juego, colisiones ni misión.
- **Pruebas**: harness headless y checker GDScript `--strict`.

## Fuera de alcance

- Minerales, depósitos y sus calcas: quedan para el cambio de misión.
- Jugador, movimiento, colisiones, cámara de juego y pathfinding. La cámara
  libre es solo de revisión.
- Salas interiores, airlock y mapa de la base.
- Semántica de los POIs, escaneo, informes y UI.
- Cambiar el generador, sus defaults o el arte existente.
- Sustituir `tiles_demo` o `lunar_map_debug.tscn`; ambos se conservan.
