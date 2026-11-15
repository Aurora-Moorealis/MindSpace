# Proposal

## Why

El diseño `docs/designs/junior-astronauta-outpost-lunar.md` exige un exterior lunar pequeño y peligroso (≤2 pantallas, panel solar y 3 POIs) dentro de `game/content/map/`, pero el repositorio todavía no tiene ninguna representación del terreno: `game/` solo contiene el proyecto Godot, el addon MCP y el núcleo de simulación en curso (`add-sim-core`, rama `sim-core`). Sin un generador desacoplado del render, el exterior habría que dibujarlo a mano y el tamaño, la variedad y la verificación quedarían acoplados a una escena concreta.

Este cambio crea un módulo de generación procedural de la superficie lunar, aislado del núcleo de simulación, con tamaño configurable, seed determinista, transitabilidad y POIs. El arte y la integración con el juego llegan después y consumen los mismos datos; por ahora no se crean sprites, imágenes ni TileSets.

## What Changes

- **Nuevo módulo aislado `game/content/map/lunar/`**: configuración, modelo de datos, generador y escena de depuración. No toca `GameSim`, `EventLog`, `project.godot`, autoloads, escenas existentes ni archivos de `add-sim-core`.
- **`LunarMapConfig` (Resource)**: ancho y alto en tiles (16–256), tamaño de tile (8–64 px), seed, densidades de cráteres/rocas/crestas, radio de la zona de aterrizaje, cantidad y distancias de POIs. Los valores fuera de rango se ajustan a un valor válido y se registran como warnings.
- **`LunarMap` (RefCounted)**: rejilla de terreno (`MARE`, `HIGHLAND`, `CRATER_FLOOR`, `CRATER_RIM`, `EJECTA`, `RIDGE`, `ROCK`, `LANDING_PAD`), elevación normalizada, transitabilidad, alcanzabilidad, spawn y lista de POIs; API de consulta y conversión tile↔mundo.
- **`LunarMapGenerator`**: generación determinista por seed con ruido para mares y tierras altas, cráteres con borde y eyección, crestas/grietas, rocas dispersas, zona de aterrizaje plana y colocación de 3 POIs. Garantiza que spawn y POIs son transitables y que todas las celdas transitables están conectadas; si la generación crea bolsas aisladas, abre pasillos transitables.
- **Escena de depuración**: `lunar_map_debug.tscn` + script que dibuja el mapa con rectángulos de colores planos mediante `_draw()` (sin PNG, sin TileSet, sin sprites), con cámara que encuadra el mapa y marcadores de spawn/POIs.
- **Verificación headless**: `lunar_map_smoke.gd` con comprobaciones de determinismo, tamaño, rasgos, conectividad, POIs, límites y mapa máximo 256×256; más el checker GDScript `--strict`.
- **Aislamiento de trabajo**: rama `map-gen` creada desde `features` en el worktree `../MindSpace-worktrees/map-gen`, siguiendo la convención de `AGENTS.md`. El cambio OpenSpec se copia a ese worktree antes de implementar.

## Capabilities

### New Capabilities

- `lunar-map-generation`: generación determinista de la superficie lunar 2D con tamaño configurable, rasgos de terreno, transitabilidad conectada, spawn y POIs; incluye la visualización de depuración sin assets.

### Modified Capabilities

- Ninguna (no hay specs previas en `openspec/specs/`).

## Impact

- **Código nuevo**: `game/content/map/lunar/lunar_map_config.gd`, `lunar_map.gd`, `lunar_map_generator.gd`, `lunar_map_debug.gd`, `lunar_map_smoke.gd` y `lunar_map_debug.tscn`.
- **Configuración**: ninguna. `game/project.godot` no se modifica; la escena de depuración se abre explícitamente.
- **Datos/arte**: ninguno. No se crean PNG, TileSet, `.tres` de arte ni assets.
- **Simulación**: ninguna integración en este cambio; `GameSim` y `EventLog` no se tocan. La API deja `spawn_tile`, `poi_tiles`, `is_walkable` e `is_reachable` listos para el cambio de integración.
- **Pruebas**: harness local en `game/tests/` para comprobaciones ad-hoc (ignorado por Git) y `lunar_map_smoke.gd` dentro del módulo como verificación repetible.
- **Rama**: `map-gen` desde `features`, en worktree separado; se integra por Pull Request.
