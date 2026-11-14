# Tasks

## 1. Preparación del módulo aislado

- [x] 1.1 Crear el worktree `../MindSpace-worktrees/map-gen` con la rama `map-gen` desde `features` actualizado, sin tocar el worktree actual de `sim-core`: `git fetch origin`, `mkdir -p ../MindSpace-worktrees`, `git worktree add ../MindSpace-worktrees/map-gen -b map-gen origin/features`. Verificar con `git -C ../MindSpace-worktrees/map-gen status --short --branch` que la rama es `map-gen` y con `git -C ../MindSpace-worktrees/map-gen log -1 --oneline` que la base es la esperada.
- [x] 1.2 Copiar el plan OpenSpec al worktree: `mkdir -p ../MindSpace-worktrees/map-gen/openspec/changes` y `cp -r openspec/changes/add-procedural-lunar-map ../MindSpace-worktrees/map-gen/openspec/changes/`. Verificar desde el worktree con `openspec status --change add-procedural-lunar-map --json` que los cuatro artefactos están presentes.
- [x] 1.3 Crear la carpeta `game/content/map/lunar/` y verificar que existe con `ls -la game/content/map/lunar`.
- [x] 1.4 Pre-calentar el caché de importación del worktree con `godot --headless --path game --quit`; documentar el exit code. Es aceptable que salga distinto de 0 por «no main scene», pero no debe haber `SCRIPT ERROR` ni errores de recursos.

## 2. Configuración

- [x] 2.1 Implementar `game/content/map/lunar/lunar_map_config.gd` (`class_name LunarMapConfig`, `extends Resource`) con `width=64`, `height=64`, `tile_size=32`, `seed=1`, `crater_density=0.004`, `min_crater_radius=2.0`, `max_crater_radius=8.0`, `ejecta_radius_multiplier=1.5`, `rock_density=0.015`, `ridge_density=0.0008`, `landing_zone_radius=4`, `landing_zone_center=Vector2i(-1, -1)`, `poi_count=3`, `poi_min_distance=10.0`, `poi_min_separation=8.0`, los `@export_range` correspondientes y las constantes `MIN_MAP_SIZE=16`, `MAX_MAP_SIZE=256`, `MIN_TILE_SIZE=8`, `MAX_TILE_SIZE=64`, `MAX_POI_COUNT=8`. Incluir `validate() -> Array[String]` para valores fuera de rango y rangos invertidos. Verificar con el checker `--strict`.
- [x] 2.2 Probar la configuración con un script temporal en `game/tests/lunar_config_check.gd`: defaults correctos, valores negativos, ancho 1, alto 9999, tile 0, radios invertidos y `poi_count` fuera de rango; debe terminar con exit code 0 y sin errores.

## 3. Modelo de datos

- [x] 3.1 Implementar `game/content/map/lunar/lunar_map.gd` (`class_name LunarMap`, `extends RefCounted`) con el enum `Terrain` (`MARE`, `HIGHLAND`, `CRATER_FLOOR`, `CRATER_RIM`, `EJECTA`, `RIDGE`, `ROCK`, `LANDING_PAD`, `INVALID = -1`), `width`, `height`, `tile_size`, `seed`, `terrain: PackedByteArray`, `elevation: PackedFloat32Array`, `walkable: PackedByteArray`, `reachable: PackedByteArray`, `spawn_tile: Vector2i`, `poi_tiles: Array[Vector2i]`, `landing_zone_center: Vector2i` y `warnings: Array[String]`. Añadir `get_index`, `is_inside`, `get_terrain`, `set_terrain`, `is_walkable`, `is_reachable`, `tile_to_world`, `world_to_tile`, `get_world_size`, `get_poi_tiles` (copia) y `get_spawn_tile`. Verificar con el checker `--strict`.
- [x] 3.2 Probar el modelo con un script temporal en `game/tests/lunar_map_data_check.gd`: construir un mapa 3×3 a mano, comprobar índices, límites, terreno fuera de rango, conversiones tile↔mundo y que `get_poi_tiles()` devuelve una copia; exit code 0.

## 4. Generador: base y cráteres

- [x] 4.1 Implementar `game/content/map/lunar/lunar_map_generator.gd` (`class_name LunarMapGenerator`, `extends RefCounted`) con `static func generate(config: LunarMapConfig) -> LunarMap`, saneado de configuración, creación de arrays, ruido FBM con `FastNoiseLite` y clasificación base `MARE`/`HIGHLAND`. Verificar con el checker y con un script temporal en `game/tests/lunar_base_check.gd` que las dimensiones, la elevación `[0, 1]` y la presencia de ambos tipos son correctas.
- [x] 4.2 Implementar los cráteres: cantidad por densidad, radios, perfil de cuenco, borde y eyección, máscaras con prioridad `floor > rim > ejecta`, omisión de centros cercanos a la zona de aterrizaje y ajuste de elevación. Verificar con el checker y con `game/tests/lunar_crater_check.gd` que la configuración por defecto produce celdas de `CRATER_FLOOR`, `CRATER_RIM` y `EJECTA`, y que una densidad 0 no produce cráteres.

## 5. Generador: crestas, rocas y zona de aterrizaje

- [x] 5.1 Implementar crestas/grietas: cantidad por densidad, polilíneas deterministas de 6–18 tiles, rasterizado con Bresenham y marcado `RIDGE`. Verificar con el checker y un test temporal que `RIDGE` existe con la densidad por defecto y que `is_walkable` devuelve `false` en esas celdas.
- [x] 5.2 Implementar rocas dispersas: cantidad por densidad, selección determinista, exclusión de `RIDGE`, `ROCK` y zona de aterrizaje, marcado `ROCK`. Verificar que existen rocas con la densidad por defecto, que `ROCK` es no transitable y que una densidad 0 lo desactiva.
- [x] 5.3 Implementar la zona de aterrizaje y el spawn: centro automático o configurado, ajuste para que el círculo quepa, aplanado de elevación, limpieza de rocas/crestas, marcado `LANDING_PAD` y spawn en el centro. Verificar con un test temporal que el spawn está dentro, es transitable y que la zona no contiene `ROCK` ni `RIDGE`.

## 6. Transitabilidad y conectividad

- [x] 6.1 Implementar `compute_walkable()`: `false` solo para `ROCK` y `RIDGE`, `true` para el resto; calcular una primera componente conexa con BFS de 4 vecinos desde el spawn. Verificar con el checker y un test temporal que hay celdas transitables y que las rocas/crestas no lo son.
- [x] 6.2 Implementar `connect_components()`: BFS multi-fuente desde la componente principal sobre todas las celdas, selección del tile más cercano de cada componente aislada, tallado de pasillos con Bresenham y conversión de `ROCK`/`RIDGE` a `MARE`/`HIGHLAND` transitables; repetir hasta 3 pasadas. Verificar con el checker y con `game/tests/lunar_connectivity_check.gd` que un BFS desde el spawn alcanza todas las celdas transitables en la configuración por defecto, en al menos 3 seeds distintas y en un mapa de 256×256.

## 7. Puntos de interés

- [x] 7.1 Implementar `place_pois()`: candidatos transitables fuera de la zona de aterrizaje, a `poi_min_distance` del spawn; selección con la RNG de POIs y muestreo por rechazo con `poi_min_separation`; relajación de separación y distancia si no caben; fallback a los candidatos más lejanos; warning con la cantidad colocada. Verificar con el checker y un test temporal que la configuración por defecto produce exactamente 3 POIs, todos transitables, alcanzables, dentro de límites y separados.
- [x] 7.2 Probar `poi_count=1`, `poi_count=5` y un mapa de 16×16 con 3 POIs y `poi_min_distance=13.0` (restricción imposible); comprobar que no se coloca ningún POI en celda no transitable o fuera de límites y que el caso pequeño añade un warning. Con la configuración por defecto de 16×16 caben 3 esquinas sin relajar, así que el test debe forzar la restricción.

## 8. Escena de depuración

- [x] 8.1 Implementar `game/content/map/lunar/lunar_map_debug.gd` (`class_name LunarMapDebug`, `extends Node2D`) y `lunar_map_debug.tscn`: `@export var config: LunarMapConfig`, `@export var show_grid: bool = false`, `@export var show_pois: bool = true`; generar el mapa en `_ready`, dibujar tiles con `draw_rect` y colores planos, dibujar spawn y POIs, ajustar una `Camera2D` para encuadrar el mapa y mostrar una etiqueta con seed, tamaño y número de POIs. No crear PNG, TileSet ni texturas. Verificar con el checker `--strict`.
- [x] 8.2 Verificar la escena en headless con un script temporal `game/tests/lunar_debug_scene_check.gd` que cargue el `.tscn`, lo instancie, lo añada al árbol y lo libere sin errores; exit code 0.
- [x] 8.3 Verificar visualmente con `godot --path game res://content/map/lunar/lunar_map_debug.tscn`: colores distintos por terreno, spawn visible, 3 POIs visibles en la configuración por defecto y cámara encuadrando el mapa completo. Adjuntar captura o describir el resultado en el informe; no commitear la captura.

## 9. Verificación final

- [x] 9.1 Implementar `game/content/map/lunar/lunar_map_smoke.gd` (`extends SceneTree`) con las comprobaciones del diseño: defaults y clamps, determinismo, diferencia entre seeds, presencia de rasgos, desactivación por densidad 0, spawn/zona, conectividad total, POIs por defecto, fallback en mapa pequeño, mapa 256×256, conversiones y consultas fuera de límites. Ejecutarlo con `godot --headless --path game --script res://content/map/lunar/lunar_map_smoke.gd` y exigir exit code 0.
- [x] 9.2 Ejecutar `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict` y corregir todos los errores y warnings de tipado.
- [x] 9.3 Ejecutar la generación de 256×256 dentro del smoke y registrar el tiempo; debe quedar por debajo de 2 s en el entorno de desarrollo. Si se supera, optimizar antes de cerrar (por ejemplo, reducir pasadas de conectividad o evitar recorridos redundantes).
- [x] 9.4 Ejecutar `godot --headless --path game --quit` y verificar que no aparecen `SCRIPT ERROR`, errores de autoload, recursos faltantes ni clases duplicadas.
- [x] 9.5 Revisar `git status --short` y `git diff --name-only` en el worktree: solo deben aparecer `game/content/map/lunar/**` y `openspec/changes/add-procedural-lunar-map/**` (más pruebas locales ignoradas). Verificar que no cambian `game/project.godot`, `game/scripts/autoloads/**`, `game/scripts/simulation/**`, `game/resources/**`, `game/databases/**`, escenas existentes ni archivos de `sim-core`; y que no hay archivos PNG, TileSet ni imágenes.

## 10. Cierre

- [x] 10.1 Actualizar este `tasks.md` marcando solo las tareas verificadas y ejecutar `openspec validate add-procedural-lunar-map --strict` desde el worktree; debe decir «is valid».
- [x] 10.2 Abrir Pull Request de `map-gen` hacia `features` con el resumen del harness, el resultado del checker y el tiempo de generación de 256×256. No fusionar directamente en `main` ni en `features`.
- [ ] 10.3 Tras la revisión y el merge, eliminar el worktree `../MindSpace-worktrees/map-gen` y la rama `map-gen` según la convención del repositorio. No archivar el cambio OpenSpec hasta que esté integrado y revisado.
