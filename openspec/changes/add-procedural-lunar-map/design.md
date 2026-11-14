# Design

## Context

Ver `proposal.md` para la motivación y `specs/lunar-map-generation/spec.md` para el contrato de comportamiento. El repositorio es un proyecto Godot 4.7 con el proyecto en `game/` y el diseño de referencia en `docs/designs/junior-astronauta-outpost-lunar.md`. El cambio `add-sim-core` está en curso en la rama `sim-core`; este cambio no depende de él y no lo modifica.

Restricciones que condicionan esta implementación:

- GDScript 4.7 con tipado explícito en todas las variables, parámetros, retornos, constantes, arrays y diccionarios; prohibido `:=`.
- El generador debe poder ejecutarse en headless, sin escenas ni editor, para verificarlo con un script.
- No hay sprites, TileSet ni arte: la primera visualización es una escena de depuración con colores planos.
- El trabajo vive en `game/content/map/lunar/` y en la rama `map-gen` dentro del worktree `../MindSpace-worktrees/map-gen`, para no mezclarse con `sim-core`.
- El mapa es 2D cenital, coherente con tiles de 32 px y la ventana 850×480 del proyecto.

## Goals / Non-Goals

**Goals:**

- Un generador puro y determinista que produzca un mapa lunar con tamaño y seed configurables.
- Un modelo de datos (`LunarMap`) independiente del render, consumible por una escena de depuración hoy y por un TileMapLayer mañana.
- Terreno legible: mares, tierras altas, cráteres con borde y eyección, crestas/grietas, rocas y una zona de aterrizaje plana.
- Transitabilidad conectada: todas las celdas caminables en una sola componente; spawn y POIs alcanzables.
- Verificación headless de determinismo, tamaño, rasgos, conectividad, POIs y límites.
- API estable para que el cambio de integración conecte spawn, POIs y zonas sin regenerar el mapa.

**Non-Goals:**

- Sprites, TileSet, PNG, animaciones, audio o cualquier asset.
- Integración con `GameSim`, radiación, astronauta, colisiones físicas o pathfinding.
- Semántica de los POIs (tipos, escaneo, informes) y UI.
- Salas interiores, airlock o mapa de la base: este generador es solo para la superficie exterior.
- Chunking, streaming o mapas mayores de 256×256.
- Persistencia o save/load del mapa.

## Decisions

### 1. Módulo aislado y datos antes que render

**Decisión:** el cambio crea un módulo autocontenido bajo `game/content/map/lunar/`:

| Archivo | Tipo | Responsabilidad |
| --- | --- | --- |
| `lunar_map_config.gd` | `Resource` con `class_name LunarMapConfig` | Parámetros editables y validación. |
| `lunar_map.gd` | `RefCounted` con `class_name LunarMap` | Rejilla, elevación, transitabilidad, spawn y POIs; consultas y conversiones. |
| `lunar_map_generator.gd` | `RefCounted` con `class_name LunarMapGenerator` | Algoritmo determinista `generate(config) -> LunarMap`. |
| `lunar_map_debug.gd` + `lunar_map_debug.tscn` | `Node2D` | Visualización de depuración con `_draw()`; no es gameplay. |
| `lunar_map_smoke.gd` | `SceneTree` | Harness headless de verificación. |

`LunarMap` es la fuente de verdad. La escena de depuración solo lee; un futuro `TileMapLayer` podrá leer la misma rejilla sin tocar el generador. **Por qué:** no existe TileSet todavía y el generador no debe depender de un render concreto; además, los tests headless no necesitan instanciar una escena.

**Alternativa descartada:** generar directamente sobre un `TileMapLayer`. Acopla el algoritmo a un TileSet inexistente, obliga a crear texturas placeholder y hace que la verificación dependa del árbol de escenas.

### 2. Configuración con clamps y warnings

`LunarMapConfig` expone:

| Parámetro | Default | Rango / notas |
| --- | --- | --- |
| `width`, `height` | 64, 48 | 16–256 tiles. |
| `tile_size` | 32 | 8–64 px. |
| `seed` | 1 | Entero; misma seed + misma config = mismo mapa. |
| `crater_density` | 0.004 | Cráteres por tile. |
| `min_crater_radius`, `max_crater_radius` | 2.0, 8.0 | Tiles. |
| `ejecta_radius_multiplier` | 1.5 | Multiplicador del radio del cráter. |
| `rock_density` | 0.015 | Rocas por tile. |
| `ridge_density` | 0.0008 | Crestas por tile. |
| `landing_zone_radius` | 4 | Tiles; se limita a lo que cabe en el mapa. |
| `landing_zone_center` | `(-1, -1)` | `(-1, -1)` = centro automático. |
| `poi_count` | 3 | 1–8. |
| `poi_min_distance` | 10.0 | Tiles desde el spawn. |
| `poi_min_separation` | 8.0 | Tiles entre POIs. |

`validate() -> Array[String]` informa de valores fuera de rango. El generador duplica la configuración, la ajusta y añade los avisos a `LunarMap.warnings`; nunca aborta por una configuración inválida. **Por qué:** un mapa siempre debe poder generarse para depurar, y el usuario necesita saber qué se cambió.

### 3. Determinismo por seed y corrientes aleatorias separadas

- `FastNoiseLite` se configura con `seed = config.seed`, tipo `TYPE_SIMPLEX_SMOOTH`, fractal FBM de 3 octavas, frecuencia 0.035 y ganancia 0.5.
- Cada etapa usa su propio `RandomNumberGenerator` derivado de la seed con una sal distinta (cráteres, crestas, rocas, POIs). Así, cambiar la densidad de cráteres no desplaza las rocas ni los POIs.
- No se usan `randi()`, `randf()`, `Array.shuffle()` ni el reloj.
- El mapa guarda la seed efectiva. **Por qué:** el determinismo es requisito de verificación y de depuración; las corrientes separadas hacen que el tuning sea predecible.

Los tests comparan la rejilla de terreno, la transitabilidad y los POIs de forma exacta en la misma plataforma; la elevación se compara con `is_equal_approx` si aparece ruido de float entre ejecuciones.

### 4. Pipeline de generación en orden fijo

```text
generate(config) -> LunarMap:
  1. sanitize(config)                 # clamps + warnings
  2. allocate map arrays              # terrain, elevation, walkable, reachable
  3. base_elevation(noise)            # mares / tierras altas
  4. place_craters(masks, elevation)  # floor, rim, ejecta
  5. place_ridges()                   # RIDGE no transitable
  6. place_rocks()                    # ROCK no transitable
  7. flatten_landing_zone()           # LANDING_PAD + spawn
  8. classify_terrain()               # prioridad: pad > rock > ridge > cráter > base
  9. compute_walkable()
 10. connect_components()             # pasillos hasta una sola componente
 11. place_pois()                     # 3 POIs deterministas y alcanzables
 12. compute_reachable()              # BFS final desde el spawn
```

**Por qué:** cada etapa tiene una responsabilidad y un efecto observable; el orden evita que una etapa borre lo que otra necesita. La zona de aterrizaje se aplana al final para garantizar un inicio limpio aunque un cráter o una cresta la intersecte.

### 5. Cráteres con máscaras de prioridad

- Cantidad = `roundi(width * height * crater_density)`; si la densidad es 0, no hay cráteres.
- Cada cráter elige centro y radio con la RNG de cráteres. Se omiten los centros a menos de `landing_zone_radius + 2` del centro de aterrizaje para no arruinar la zona plana.
- Perfil: depresión de cuenco dentro del radio, borde elevado en `[r, 1.15r]` y eyección hasta `ejecta_radius_multiplier * r`. La elevación se ajusta de forma aditiva y se clampa a `[0, 1]`.
- Se mantienen tres máscaras (`crater_floor`, `crater_rim`, `ejecta`) y se aplican con prioridad `floor > rim > ejecta`. Así los cráteres solapados no borran el suelo de uno anterior con la eyección de otro.

**Alternativa descartada:** escribir el terreno directamente en el orden de los cráteres. Es más simple, pero produce artefactos visibles cuando dos cráteres se solapan.

### 6. Mares, tierras altas y clasificación base

La elevación base sale del ruido FBM normalizado a `[0, 1]`. Por debajo de `0.48` se clasifica `MARE`; por encima, `HIGHLAND`. Los cráteres, crestas y rocas se superponen después con su propia prioridad. **Por qué un umbral fijo:** es un parámetro de legibilidad del mapa, no una constante de gameplay; se puede convertir en `@export` si el tuning lo pide, sin cambiar el contrato del generador.

### 7. Crestas y grietas

- Cantidad = `roundi(width * height * ridge_density)`.
- Cada cresta es una polilínea de 6–18 tiles que empieza en un punto aleatorio y avanza con cambios suaves de ángulo; se rasteriza con Bresenham y se marca `RIDGE` (no transitable).
- Las crestas pueden cruzar la zona de aterrizaje; el aplanado posterior las elimina dentro de la zona.

**Por qué polilíneas:** son deterministas, baratas y se leen como grietas; un campo de ruido ridged adicional sería más caro y difícil de testear.

### 8. Rocas dispersas

- Cantidad = `roundi(width * height * rock_density)`.
- Se eligen tiles aleatorios que no sean ya `RIDGE`, `ROCK` ni parte de la zona de aterrizaje; se marca `ROCK` (no transitable).
- No hay agrupación ni distribución por tamaño en esta versión; la densidad es el único control.

### 9. Zona de aterrizaje y spawn

- El centro es `landing_zone_center` o el centro del mapa si es `(-1, -1)`.
- El centro se ajusta para que el círculo completo quepa dentro del mapa; el radio se limita a `min(width, height) / 4` como máximo.
- Se marca todo el círculo como `LANDING_PAD`, se aplana la elevación al promedio local (o `0.5` si no hay muestra), se eliminan `ROCK` y `RIDGE` y se marca transitable.
- El spawn es el centro de la zona. **Por qué:** el jugador siempre empieza en un área segura, plana y visible, y los POIs se distribuyen alrededor.

### 10. Transitabilidad y conectividad total

- `walkable` es `false` solo para `ROCK` y `RIDGE`; el resto es transitable, incluidos los cráteres y la zona de aterrizaje.
- Se calculan componentes conexas con BFS de 4 vecinos. Si hay más de una, se hace un BFS multi-fuente desde la componente del spawn sobre **todas** las celdas (transitables o no) para obtener, para cada tile, la distancia y el tile más cercano de la componente principal.
- Para cada componente aislada se elige su tile con menor distancia a la principal y se cava una línea de tiles hasta el tile principal más cercano; las celdas `ROCK`/`RIDGE` del pasillo pasan a `MARE` (o `HIGHLAND` según la elevación) y a transitables. Se repite hasta 3 pasadas.
- El resultado es una sola componente transitable; `reachable` se recalcula con un BFS final desde el spawn.

**Por qué conectar todo y no solo los POIs:** deja un mapa sin bolsas muertas, hace que cualquier POI futuro sea alcanzable y permite verificar la propiedad con un único BFS. **Alternativa descartada:** reintentar con otra seed hasta que el mapa salga conectado; cambia el mapa solicitado de forma impredecible. **Coste:** O(tiles) por pasada; 65 536 tiles es despreciable.

### 11. POIs deterministas y alcanzables

- Candidatos: tiles transitables, fuera de `LANDING_PAD`, dentro de los límites y a `poi_min_distance` o más del spawn.
- Se eligen con la RNG de POIs y muestreo por rechazo: cada candidato debe estar a `poi_min_separation` de los ya elegidos.
- Si no se alcanza `poi_count`, se relaja la separación al 75 % y luego la distancia mínima; si aun así no caben, se eligen los candidatos más lejanos disponibles y se añade un warning con la cantidad colocada.
- Los POIs son `Array[Vector2i]`. Su tipo, nombre, orden de escaneo y recompensa pertenecen al cambio de misión.

**Por qué posiciones solamente:** mantiene el generador pequeño y estable; la semántica de POIs se añade sin regenerar el terreno.

### 12. Visualización de depuración con `_draw()`

`lunar_map_debug.tscn` es una escena `Node2D` con cámara. El script:

- Genera un `LunarMap` desde su `LunarMapConfig` exportada (o una configuración por defecto si es `null`).
- Dibuja cada tile como un `Rect2` de color plano según el terreno; no crea texturas ni TileSet.
- Dibuja el spawn y los POIs con círculos de colores distintos.
- Ajusta la cámara para encuadrar el mapa completo y muestra una etiqueta con seed, tamaño y número de POIs.
- Permite ocultar la rejilla con `show_grid`; la rejilla se dibuja como contorno semitransparente.

Tabla de colores (solo depuración):

| Terreno | Color |
| --- | --- |
| `MARE` | gris oscuro |
| `HIGHLAND` | gris claro |
| `CRATER_FLOOR` | gris muy oscuro |
| `CRATER_RIM` | gris casi blanco |
| `EJECTA` | gris medio |
| `RIDGE` | marrón oscuro |
| `ROCK` | casi negro |
| `LANDING_PAD` | azul verdoso |

**Por qué `_draw()`:** no hay arte, no se crean assets y la escena sirve para verificar visualmente el generador. **Alternativa descartada:** TileSet placeholder generado por código; crea un pipeline de texturas falso que habrá que tirar cuando llegue el arte real.

**Rendimiento:** 256×256 tiles son 65 536 `draw_rect` por redibujado. Es aceptable para una escena de depuración; si molesta, se desactiva la rejilla y se baja el zoom. Un TileMapLayer sustituirá este render en el cambio de arte.

### 13. Verificación

Comandos:

```bash
# Checker obligatorio del proyecto
bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict

# Harness de la generación
godot --headless --path game --script res://content/map/lunar/lunar_map_smoke.gd

# Arranque headless sin errores de autoload/recursos
godot --headless --path game --quit

# Escena visual (con editor o ventana)
godot --path game res://content/map/lunar/lunar_map_debug.tscn
```

El harness comprueba:

1. Configuración por defecto (64×48, 32 px) y clamps de tamaño, tile y densidades.
2. Determinismo con la misma seed (terreno, elevación, spawn y POIs).
3. Diferencia entre seeds distintas.
4. Presencia de mares, tierras altas, cráteres, rocas y crestas con la configuración por defecto.
5. Desactivación de un rasgo con densidad 0.
6. Spawn dentro de la zona de aterrizaje y zona sin obstáculos.
7. Conectividad total: BFS desde el spawn alcanza todas las celdas transitables.
8. POIs por defecto: 3, transitables, alcanzables, dentro de límites y separados.
9. Mapa de 16×16 con 3 POIs y `poi_min_distance=13.0`: relajación/fallback con warning. Con la configuración por defecto caben 3 esquinas, así que el escenario debe forzar la restricción para ejercitar la relajación.
10. Mapa de 256×256: termina sin errores y la conectividad se mantiene.
11. Conversión tile↔mundo y consultas fuera de límites.
12. Tiempo de generación de 256×256 por debajo de 2 s en el entorno de desarrollo (se imprime; no es un fallo duro si la máquina es lenta, pero se registra).

Además, la escena de depuración se instancia en headless y se comprueba que no produce errores.

### 14. Rama, aislamiento y migración

- Worktree: `../MindSpace-worktrees/map-gen`, rama `map-gen` creada desde `features` actualizado (`origin/features`).
- Antes de implementar, se copia `openspec/changes/add-procedural-lunar-map/` al worktree para que el apply workflow tenga el plan.
- No se modifica `game/project.godot`, no se registran autoloads y no se toca ningún archivo de `sim-core`.
- La escena de depuración no es la escena principal; se abre explícitamente.
- Integración: Pull Request de `map-gen` a `features`; al mergear, se elimina el worktree. Rollback = revertir el commit del módulo; no hay persistencia ni migración de datos.

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| `_draw` con 65 536 rectángulos puede ser lento en mapas grandes | Es solo una escena de depuración; `show_grid` desactivado por defecto y zoom de cámara. El render final será un TileMapLayer. |
| Los pasillos de conectividad de 1 tile pueden verse antinaturales | Aceptable para v1; se documenta y se puede añadir `corridor_width` sin cambiar el contrato. |
| Densidad de cráteres alta en mapas grandes cubre demasiado terreno | La densidad es por tile y se ajusta en config; el harness verifica que el mapa sigue siendo válido y conectado. |
| Los POIs no caben en mapas muy pequeños | Se relajan separación y distancia, se coloca lo que cabe y se emite warning; el tamaño por defecto no tiene ese problema. |
| Diferencias de float entre plataformas | No hay aleatoriedad global ni tiempo; los tests comparan en la misma plataforma y usan `is_equal_approx` para elevación. |
| El cambio OpenSpec se queda en el worktree de `sim-core` | La tarea 1.2 copia explícitamente `openspec/changes/add-procedural-lunar-map/` al worktree `map-gen`. |
| `game/tests/` está ignorado por Git | Las pruebas ad-hoc viven ahí; el harness repetible se commitea en `game/content/map/lunar/lunar_map_smoke.gd`. |
| Un cambio futuro de arte necesita otra representación | `LunarMap` es data-first; el TileSet/TileMapLayer se añade como consumidor sin reescribir el generador. |

## Open Questions

- **Tamaño por defecto frente al diseño padre:** 64×48 tiles de 32 px son 2048×1536 px, más de las «≤2 pantallas» que pide `docs/designs/junior-astronauta-outpost-lunar.md` para el exterior. La spec delta fija 64×48 y el generador lo cumple; antes del PR hay que decidir si se reduce el default (por ejemplo 40×24 o 48×30) y se actualizan spec/tests, o si se actualiza el diseño padre. No se cambia sin aprobación.
- En mapas de 16×16, la densidad por defecto de crestas (`roundi(16*16*0.0008) = 0`) no produce ninguna; si se quiere garantizar al menos una cuando la densidad es > 0, habría que usar `maxi(1, roundi(...))` y aceptar el cambio de determinismo.
- Tipos y semántica de los POIs (ciencia, recurso, relé) y su orden de escaneo se deciden en el cambio de misión.
- El TileSet y los sprites de 32 px se deciden en el cambio de arte; este módulo no los crea.
- El ancho de los pasillos de conectividad y el pathfinding real pertenecen al cambio de movimiento/colisiones.
- La generación de interiores (5 salas y airlock) no está cubierta; este generador es solo superficie lunar.
- Chunking o mapas mayores de 256×256 quedan fuera hasta que el rendimiento lo exija.
