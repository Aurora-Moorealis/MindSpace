# Design

## Context

Ver `proposal.md` para la motivación y `specs/lunar-map-rendering/spec.md` para
el contrato. El punto de partida es el que dejó `add-procedural-lunar-map`:

- `LunarMap` es la fuente de verdad (terreno, elevación, transitabilidad, spawn,
  POIs) y no sabe nada de render.
- `lunar_map_debug.tscn` dibuja la rejilla con `_draw()` y colores planos; sirve
  para ver el mapa completo, pero no usa el arte.
- `game/scenes/tiles_demo/tiles_demo.tscn` pinta a mano un trozo de mundo con
  los tres TileSets reales; es una referencia visual, no un mapa generado.
- Los TileSets `ground_tileset.tres`, `base_tileset.tres` y
  `props_tileset.tres` ya existen, con 32×32 px por loseta y datos
  personalizados `material`, `detail` y `solid`.
- El mapa por defecto es 64×64 celdas de 32 px (2048×2048 px). El diseño padre
  pide un exterior de ≤2 pantallas; esa tensión ya está registrada en el cambio
  del generador y no se resuelve aquí.

Restricciones que condicionan la implementación:

- GDScript 4.7 con tipado explícito obligatorio; prohibido `:=`.
- El pixel art se muestra a escala entera; una cámara con zoom 0.4 rompería la
  rejilla. La escena nueva se ve a escala 1:1 y el mapa completo sigue en la
  escena de depuración.
- No se toca el generador, el arte, `project.godot`, autoloads ni escenas
  compartidas.
- El trabajo vive en la rama `map-render`, en el worktree
  `../MindSpace-worktrees/map-render`, creado desde `features` (`b440f43`), y se
  integra por Pull Request.

## Goals / Non-Goals

**Goals:**

- Un puente reutilizable y verificable entre `LunarMap` y las tres capas de
  losetas, sin generar nada dentro del render.
- Una escena de mapa real que se pueda abrir y revisar a escala de juego.
- Un mapeo visual explícito y determinista para cada tipo de terreno.
- Verificación headless de cobertura, mapeo, determinismo, props y escena.

**Non-Goals:**

- Jugador, cámara que sigue al astronauta, colisiones o pathfinding.
- Minerales, depósitos o semántica de POIs.
- Salas interiores, airlock o mapa de la base.
- Cambiar el tamaño por defecto del mapa o el arte existente.
- Sustituir `tiles_demo` o `lunar_map_debug.tscn`.

## Decisions

### 1. Puente en dos piezas: mapper puro y renderer

**Decisión:** el render se separa en dos archivos bajo
`game/content/map/lunar/`:

| Archivo | Tipo | Responsabilidad |
| --- | --- | --- |
| `lunar_map_tile_mapper.gd` | `RefCounted` con `class_name LunarMapTileMapper` | Traducir terreno y coordenada a coordenadas de atlas de cada capa. Sin nodos ni estado. |
| `lunar_map_tile_renderer.gd` | `RefCounted` con `class_name LunarMapTileRenderer` | Limpiar las tres capas y volcar la rejilla usando el mapper. |
| `lunar_map_world.gd` | `Node2D` con `class_name LunarMapWorld` | Controlador de escena: genera, pinta y centra la cámara. |
| `lunar_map_world.tscn` | Escena | Tres `TileMapLayer` con los TileSets reales, cámara y script. |
| `lunar_map_render_smoke.gd` | `SceneTree` | Harness headless de la representación. |

El mapper no conoce `TileMapLayer`; el renderer no conoce la escena; el
controlador no conoce los detalles del mapeo. **Por qué:** el mapeo se puede
probar sin árbol de escenas y el renderer se puede reutilizar cuando el mapa se
genere desde el flujo de juego, sin arrastrar la escena de revisión.

**Alternativa descartada:** generar directamente sobre `TileMapLayer` dentro de
`LunarMapGenerator`. Acopla el algoritmo al arte, rompe la pureza headless y
obliga a regenerar el mapa para cambiar una loseta.

### 2. Tres capas, un TileSet por capa

La escena usa tres `TileMapLayer` —`Ground`, `Base`, `Props`— con
`ground_tileset.tres`, `base_tileset.tres` y `props_tileset.tres`. Todas las
losetas usan `source_id = 0` y `alternative_tile = 0`; el orden de dibujo es
suelo, base, props.

**Por qué no un solo TileMapLayer:** cada capa tiene su propio TileSet y su
propio z-order; unificarlas obligaría a fusionar los tres atlas y a cambiar el
contrato de `world-map`. **Alternativa descartada:** crear un cuarto TileSet
combinado solo para el mapa generado; duplica arte y datos sin aportar nada.

### 3. Mapeo de terreno a losetas

El suelo es siempre regolito, como exige `art-style`; la diferencia entre tipos
de terreno se expresa con la variante de detalle y con los props, nunca con un
suelo de otro material. La variante concreta se elige de forma determinista
(ver decisión 4).

| Terreno | Capa de suelo (atlas) | Capa base (atlas) | Capa de props (atlas) |
| --- | --- | --- | --- |
| `MARE` | `(0,0)`, `(1,0)`, `(2,0)` | — | — |
| `HIGHLAND` | `(2,0)`, `(3,0)`, `(0,1)` | — | — |
| `CRATER_FLOOR` | `(3,1)`, `(2,1)` | — | — |
| `CRATER_RIM` | `(3,1)` | — | — |
| `EJECTA` | `(2,0)`, `(3,0)` | — | — |
| `RIDGE` | `(3,1)` | — | `(0,0)`, `(1,0)`, `(0,1)` |
| `ROCK` | `(2,1)` | — | `(2,0)`, `(3,0)`, `(4,0)` |
| `LANDING_PAD` interior | `(2,1)` | `(0,0)`, `(1,0)` | — |
| `LANDING_PAD` borde | `(2,1)` | `(3,3)` | — |
| Desconocido | `(0,0)` | — | — |

Notas del mapeo:

- `CRATER_FLOOR` usa la variante `removido` (más oscura) y `compactado` para
  leerse como cuenca; `CRATER_RIM` usa `removido` para marcar el borde del
  cuenco, y `EJECTA` usa guijarros para leerse como material expulsado.
- `RIDGE` usa las rocas grandes y de basalto; `ROCK` usa las rocas medianas y
  pequeñas. Así una cresta continua no se confunde con una roca suelta.
- La zona de aterrizaje se pinta como plataforma metálica: plancha lisa y
  remaches en el interior, rejilla industrial en el anillo exterior. El suelo
  bajo la plataforma se pinta igualmente para que la capa de suelo nunca tenga
  huecos, aunque la plataforma lo tape.
- El atlas `props` tiene una fila 1 con una roca `(0,1)` y cuatro minerales
  `(1,1)`–`(4,1)`. El mapper puede usar `(0,1)` como roca, pero nunca las
  coordenadas de mineral. El harness lo verifica.

**Alternativa descartada para la plataforma:** pintar la zona de aterrizaje con
regolito compactado y dejar la capa base vacía. Es más conservador con
`art-style`, pero el spawn no tendría un punto de referencia construido y la
capa base quedaría sin usar. Se elige la plataforma metálica y se revisa a
tamaño de juego; si el resultado se lee como interior, se cambia a regolito
compactado sin tocar el generador ni la spec de terreno.

### 4. Variantes deterministas por hash de seed y celda

No se usa `RandomNumberGenerator` ni el reloj. Para cada celda se calcula un
hash entero estable a partir de `map.seed`, `tile.x`, `tile.y` y una sal por capa
o por grupo de variantes; el resultado se reduce al tamaño de la lista de
variantes. La misma `LunarMap` produce siempre las mismas losetas, y cambiar la
seed cambia los detalles sin alterar el terreno ni los props.

El renderer llama primero a `clear()` en las tres capas. Así, repintar un mapa
pequeño sobre uno grande no deja celdas fuera de los límites. **Por qué un hash
y no una RNG por celda:** una RNG por celda añade estado y coste; el hash es
puro, barato y trivial de verificar.

### 5. Props sólidos solo donde la rejilla no es transitable

El mapper devuelve un prop únicamente para `ROCK` y `RIDGE`; el resto devuelve
“sin prop”. Las rocas de `props_tileset.tres` tienen `solid = true`, así que la
capa de props coincide con la transitabilidad del mapa. La zona de aterrizaje no
recibe props. El renderer no añade colisiones: solo pinta la capa; la colisión
física pertenece al cambio de jugador/movimiento.

**Alternativa descartada:** derivar props de `LunarMap.walkable` en lugar del
tipo de terreno. Perdería la distinción entre roca y cresta y no permitiría
elegir la variante correcta.

### 6. Escena de mapa real a escala 1:1, no vista general

`lunar_map_world.tscn` tiene:

```text
LunarMapWorld (Node2D, lunar_map_world.gd)
├── Ground (TileMapLayer, ground_tileset.tres)
├── Base (TileMapLayer, base_tileset.tres)
├── Props (TileMapLayer, props_tileset.tres)
└── Camera2D
```

`LunarMapWorld` exporta `config: LunarMapConfig`; si es `null`, usa
`LunarMapConfig.new()`. En `_ready()` genera el mapa, llama al renderer y centra
la `Camera2D` en el centro de la celda de spawn con `zoom = Vector2(1, 1)`.

**Por qué no encuadrar el mapa completo:** 64×64 celdas de 32 px son
2048×2048 px; para caber en 850×480 haría falta un zoom de ~0.4, que reduce el
arte a un múltiplo no entero y rompe la regla de escala del pixel art. La escena
no es una vista general: el jugador tendrá su propia cámara y su propia
perspectiva; aquí la `Camera2D` solo sirve para abrir la escena en el spawn a la
escala real. La vista general sigue disponible en `lunar_map_debug.tscn`, que no
usa arte.

**Alternativa descartada:** una cámara que se aleja hasta encuadrar el mapa. Es
cómoda para revisar, pero muestra un arte que el jugador nunca verá y falsea la
lectura de las losetas.

### 7. Verificación headless

`lunar_map_render_smoke.gd` se ejecuta con:

```bash
godot --headless --path game --script res://content/map/lunar/lunar_map_render_smoke.gd
```

Comprueba, sobre mapas generados de 16×16 y 64×64:

1. La capa de suelo cubre todas las celdas, dentro de límites y con `TileData`
   válido.
2. Cada tipo de terreno produce una loseta; un valor desconocido cae en la
   variante segura.
3. La zona de aterrizaje tiene base en todas sus celdas, el spawn incluido, y
   ninguna roca dentro.
4. Solo `ROCK` y `RIDGE` tienen props; todos sus props son `solid = true`; las
   celdas transitables no tienen props sólidos; no aparece ninguna coordenada de
   mineral.
5. Dos representaciones de la misma seed coinciden celda a celda; una seed
   distinta cambia al menos una variante de suelo.
6. Repintar un mapa de 16×16 sobre uno de 64×64 no deja celdas fuera del mapa
   pequeño.
7. La escena `lunar_map_world.tscn` se instancia en headless, genera un mapa,
   tiene las tres capas con celdas y deja la cámara en el spawn con zoom 1:1.

Comandos de cierre:

```bash
bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict
godot --headless --path game --quit
```

### 8. Ubicación y rama

Los archivos nuevos viven en `game/content/map/lunar/`, junto al generador y a
la escena de depuración, porque son parte del contenido del mapa y no una
pantalla de flujo. No se crea una carpeta en `game/scenes/` hasta que exista la
composición del nivel (base + exterior + airlock), que es otro cambio.

El trabajo se hace en la rama `map-render` del worktree
`../MindSpace-worktrees/map-render`, creado desde `features` (`b440f43`). No se
tocan `main` ni `features` directamente; la integración es un Pull Request de
`map-render` a `features`.

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| La plataforma metálica se lee como interior y rompe la lectura del exterior | Se revisa a tamaño de juego; si chirría, se cambia a regolito compactado sin tocar el generador. |
| El arte tiene un solo material de suelo y los tipos de terreno pueden confundirse | La diferencia se apoya en variantes, props y la silueta de cráteres/crestas; el detalle fino queda para un cambio de arte si hace falta. |
| La cámara a escala 1:1 solo muestra una parte del mapa de 64×64 | Es la escala real del juego; `lunar_map_debug.tscn` sigue siendo la vista general. |
| 65 536 celdas × 3 capas pueden tardar en mapas de 256×256 | El caso normal es 64×64 (4096 celdas); se mide en el harness y no se optimiza antes de necesitarlo. |
| El renderer pinta props sólidos pero no añade colisión | La capa `solid` ya describe el bloqueo; las colisiones se añaden en el cambio de jugador/movimiento. |
| El mapa por defecto sigue por encima de las ≤2 pantallas del diseño padre | No se cambia aquí; la decisión de tamaño se toma con el mapa jugable y el tiempo de recorrido. |
| Repintar sin limpiar deja celdas huérfanas | El renderer siempre llama a `clear()` y el harness lo verifica. |

## Migration Plan

1. Implementar en el worktree `../MindSpace-worktrees/map-render`, rama
   `map-render`, sin tocar `features`.
2. Validar con el harness, el checker estricto y el arranque headless.
3. Revisar visualmente `lunar_map_world.tscn` y, si hace falta, ajustar el mapeo
   antes del commit.
4. Commit en `map-render`, push y Pull Request a `features`.
5. Tras el merge, eliminar el worktree y la rama de módulo.

Rollback: revertir el commit del módulo. No hay persistencia, migración de datos
ni cambios de configuración que deshacer.

## Open Questions

- **Tamaño definitivo del exterior:** el mapa por defecto es 64×64 y el diseño
  padre pide ≤2 pantallas. Se decide cuando exista el jugador y se pueda medir
  el recorrido; no cambia el mapeo ni la escena de este cambio.
- **Minerales y POIs:** su colocación y semántica pertenecen al cambio de
  misión. La capa de props deja el hueco preparado, sin calcas de mineral.
- **Colisiones:** el TileSet no tiene capa física; se añadirá con el movimiento
  del astronauta, reutilizando `solid` y `LunarMap.walkable`.
