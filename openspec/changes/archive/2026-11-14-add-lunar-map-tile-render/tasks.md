# Tasks

## 1. Mapeo de terreno a losetas

- [x] 1.1 Crear `game/content/map/lunar/lunar_map_tile_mapper.gd` con `class_name LunarMapTileMapper`, las constantes de coordenadas de atlas y las tablas de variantes por terreno del diseño; verificar que `check-gdscript.sh -p game --strict` lo acepta y que no referencia nodos, autoloads ni el árbol de escenas.
- [x] 1.2 Implementar en `lunar_map_tile_mapper.gd` la selección determinista por hash de seed y celda, y la variante segura para un terreno desconocido; verificar con un script temporal en `game/tests/` que la misma entrada devuelve siempre la misma coordenada y que un terreno con valor 99 no produce error.
- [x] 1.3 Implementar en `lunar_map_tile_mapper.gd` las consultas de suelo, base y props: plataforma de aterrizaje con interior y borde, rocas/crestas con sus variantes y ninguna coordenada de mineral; verificar con un script temporal que cada tipo de terreno devuelve la coordenada esperada de su atlas.

## 2. Renderer de la rejilla

- [x] 2.1 Crear `game/content/map/lunar/lunar_map_tile_renderer.gd` con `class_name LunarMapTileRenderer` y `paint(map, ground, base, props)`: comprobar nulos, limpiar las tres capas y recorrer la rejilla con `set_cell`; verificar con un script temporal que un mapa de 16×16 produce 256 celdas de suelo y que repintar 64×64 → 16×16 no deja celdas fuera del mapa pequeño.
- [x] 2.2 Añadir en `lunar_map_tile_renderer.gd` la garantía de que los props solo se pintan en celdas `ROCK` y `RIDGE` y que nunca se escribe una coordenada de mineral; verificar con un mapa generado que el número de props coincide con el de celdas no transitables y que la fila de minerales del atlas queda sin usar.

## 3. Escena de mapa real

- [x] 3.1 Crear `game/content/map/lunar/lunar_map_world.gd` (`LunarMapWorld`) con `config` exportada, generación en `_ready()`, llamada al renderer y `get_map()`; verificar que `godot --headless --path game --quit` no muestra errores y que una instancia de prueba devuelve un mapa no nulo.
- [x] 3.2 Crear `game/content/map/lunar/lunar_map_world.tscn` con los nodos `Ground`, `Base` y `Props` (`TileMapLayer`) y `Camera2D`, cableando `ground_tileset.tres`, `base_tileset.tres` y `props_tileset.tres`; verificar que la escena se instancia en headless sin errores y que las tres capas tienen su `tile_set` asignado.
- [x] 3.3 Centrar la `Camera2D` de `lunar_map_world.tscn` en el centro de la celda de spawn con `zoom = Vector2(1, 1)`; verificar que la posición coincide con `map.tile_to_world(spawn) + tile_size / 2` y que el zoom no reduce el arte.

## 4. Verificación headless

- [x] 4.1 Crear `game/content/map/lunar/lunar_map_render_smoke.gd` con las comprobaciones de cobertura, mapeo por terreno, plataforma de aterrizaje, props sólidos, determinismo y repintado; ejecutarlo con `godot --headless --path game --script res://content/map/lunar/lunar_map_render_smoke.gd` y exigir código de salida 0.
- [x] 4.2 Ampliar `lunar_map_render_smoke.gd` para cargar `lunar_map_world.tscn`, comprobar que las tres capas tienen celdas y que la cámara queda en el spawn; verificar que la ejecución headless termina con código 0.
- [x] 4.3 Ejecutar `check-gdscript.sh -p game --strict` y `godot --headless --path game --quit`; corregir cualquier error o warning de tipado antes de continuar.

## 5. Revisión visual y ajuste

- [x] 5.1 Abrir `game/content/map/lunar/lunar_map_world.tscn` en Godot y revisar el spawn y el borde de la plataforma a escala 1:1; ajustar solo las coordenadas de `lunar_map_tile_mapper.gd` si una variante no se lee.
- [x] 5.2 Revisar un mapa con cráteres, crestas y rocas y comprobar que se distinguen sin convertir el suelo en un mosaico de colores; guardar una captura de revisión en `game/tests/` (no versionada) y anotar el resultado en el commit.
- [x] 5.3 Repetir el harness de `lunar_map_render_smoke.gd` y el checker estricto tras los ajustes y dejar ambos en verde.

## 6. Escena de revisión con cámara WASD

- [x] 6.1 Crear `game/content/map/lunar/lunar_map_camera_debug.gd` y `lunar_map_render_debug.tscn`: instanciar `lunar_map_world.tscn`, mover la `Camera2D` con W/A/S/D y limitarla a los bordes del mapa; verificar con un script temporal en `game/tests/` que la escena carga, `pan_camera()` mueve y el clamp detiene.
- [x] 6.2 Ampliar `game/content/map/lunar/lunar_map_render_smoke.gd` para cargar `lunar_map_render_debug.tscn` y comprobar movimiento y clamp; ejecutar el harness con código de salida 0.
- [x] 6.3 Ejecutar `check-gdscript.sh -p game --strict` y `godot --headless --path game --quit`; abrir la escena en Godot y confirmar manualmente W, A, S y D.

## Workflow follow-up

- Ejecutar `openspec validate add-lunar-map-tile-render --strict` antes de commitear.
- Archivar el cambio con `openspec archive add-lunar-map-tile-render --yes` en el commit que cierra el trabajo.
- Abrir el Pull Request de `map-render` a `features` y eliminar el worktree después del merge.
