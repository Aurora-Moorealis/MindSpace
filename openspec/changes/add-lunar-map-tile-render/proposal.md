# Proposal

## Why

El generador procedural produce una `LunarMap` determinista y el arte del mundo
existe en `game/content/map/tiles/` y `game/content/map/props/`, pero ambos
sistemas siguen separados: la única vista del mapa es
`lunar_map_debug.tscn`, que dibuja rectángulos planos con `_draw()`, y la única
tilemap real es `game/scenes/tiles_demo/`, pintada a mano. Sin un puente entre
los datos y los TileSets, el generador no puede verse ni usarse en el mundo del
juego, y el mapa real no puede crecer más allá del demo.

Este cambio empieza esa unión: pinta una `LunarMap` generada en las capas de
tiles reales y añade una escena de mapa real para revisarla. No introduce
jugador, colisiones ni gameplay.

## What Changes

- **Nuevo puente de render en `game/content/map/lunar/`**: un mapper puro que
  traduce cada tipo de terreno y cada tile a una loseta de los tres TileSets, y
  un renderer que vuelca la rejilla en `TileMapLayer`s.
- **Capa de suelo**: todas las celdas de la rejilla se pintan con variantes de
  regolito, eligiendo la variante de forma determinista por seed y coordenada.
- **Capa de base**: la zona de aterrizaje (`LANDING_PAD`) se pinta como
  plataforma metálica construida, con plancha en el interior y una rejilla de
  borde que la separa del regolito.
- **Capa de props**: las celdas `ROCK` y `RIDGE` reciben rocas sólidas de
  `props_tileset.tres`; ninguna celda transitable recibe un prop sólido.
- **Escena `lunar_map_world.tscn`**: tres `TileMapLayer` con los TileSets
  reales, cámara centrada en el spawn a escala de juego y generación desde una
  `LunarMapConfig` exportada.
- **Verificación headless**: un harness que comprueba cobertura, mapeo,
  determinismo, props y carga de la escena sin errores.
- **Sin cambios en el generador**: `LunarMap`, `LunarMapGenerator` y
  `LunarMapConfig` se consumen tal cual; la escena de depuración se conserva.
- **Rama de módulo**: `map-render`, en el worktree
  `../MindSpace-worktrees/map-render`, integrada por Pull Request a `features`.

## Capabilities

### New Capabilities

- `lunar-map-rendering`: representación de una `LunarMap` generada sobre las
  tres capas de tiles del mundo, con correspondencia terreno→loseta, plataforma
  de aterrizaje, props de rocas/crestas, determinismo y escena de mapa real.

### Modified Capabilities

- Ninguna. `lunar-map-generation` conserva su contrato y `world-map` sigue
  describiendo los TileSets; este cambio solo los conecta.

## Impact

- **Código nuevo**: mapper, renderer, escena de mundo y harness dentro de
  `game/content/map/lunar/`.
- **Recursos existentes**: se usan `content/map/tiles/ground_tileset.tres`,
  `base_tileset.tres` y `content/map/props/props_tileset.tres`; no se modifican.
- **Configuración**: `game/project.godot`, autoloads y escenas compartidas no
  cambian. La escena nueva se abre explícitamente.
- **Simulación y gameplay**: ninguna integración con `GameSim`, `EventLog`,
  astronauta, cámara de juego, colisiones ni misión.
- **Pruebas**: harness headless dentro del módulo y checker GDScript `--strict`.

## Fuera de alcance

- Minerales, depósitos y sus calcas: quedan para el cambio de misión; esta
  primera unión solo pinta suelo, plataforma y rocas/crestas.
- Jugador, movimiento, colisiones, cámara que sigue al astronauta y pathfinding.
- Salas interiores, airlock y mapa de la base.
- Semántica de los POIs, escaneo, informes y UI.
- Cambiar el generador, sus defaults o el arte existente.
- Sustituir `tiles_demo` o `lunar_map_debug.tscn`; ambos se conservan.
