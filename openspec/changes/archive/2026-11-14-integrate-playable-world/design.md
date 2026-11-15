# Design

## Context

El repositorio ya tiene las piezas, pero no están conectadas:

- `game/scenes/worlds/worlds.gd` elige un mundo y abre
  `game/scenes/intro/intro.tscn`.
- `game/scenes/intro/intro.gd` recorre la historia y, al aceptar, solo cambia
  un texto (`_on_accept_pressed`); no abre ninguna escena de juego.
- `game/content/map/lunar/lunar_map_world.tscn` genera un `LunarMap`, pinta las
  tres capas y centra su propia `Camera2D` en el spawn. No tiene jugador,
  colisión ni cámara de juego.
- `game/content/entities/astronaut/astronaut_4dir.png` existe: 128×32 px, cuatro
  frames de 32×32 (abajo, arriba, izquierda y derecha). No hay escena de
  astronauta.
- `game/scripts/autoloads/game_sim.gd` avanza ticks desde `_process` en cuanto
  arranca el juego, también en menús e introducción, y nunca se reinicia al
  empezar una misión.
- `game/project.godot` no tiene acciones de entrada para movimiento.
- `game/content/map/props/props_tileset.tres` declara el dato `solid`, pero no
  tiene capa de física: la transitabilidad real vive en `LunarMap.is_walkable`.

Restricciones que condicionan la implementación:

- GDScript 4.7 con tipado explícito obligatorio; prohibido `:=`.
- Pixel art a escala 1:1; nada de zoom fraccionario ni suavizado de cámara.
- La UI está en desarrollo: este cambio no crea HUD, overlays ni pantallas.
- No se toca el generador, el render del mapa, los TileSets, el arte existente,
  la economía ni las máquinas.
- El trabajo de `game/` va en un worktree y una rama de módulo (`playable-world`)
  creada desde `features`; se integra por Pull Request. Los artefactos OpenSpec
  se llevan al worktree y se commitean en esa rama antes de tocar el juego.

## Goals / Non-Goals

**Goals:**

- Cerrar el flujo jugable mínimo: mundo → introducción → aceptar → mapa con
  astronauta.
- Mover al astronauta con teclado, colisión contra el terreno y cámara de juego
  limitada al mapa.
- Hacer que el reloj de simulación viva solo durante la partida, arranque limpio y
  se congele al morir.
- Verificar todo con harness headless, checker estricto y playtest manual.

**Non-Goals:**

- HUD, barras, reloj visible, pausa, multiplicadores ×5/×10 y evaluación.
- Interiores, salas, airlock, máquinas interactuables, POIs, escaneo, informes y
  submisiones.
- Persistencia de partida, semilla por mundo y carga de mapas guardados.
- Arte nuevo o animación de caminata.
- Cambios en el menú, la selección de mundos o el generador del mapa.

## Decisions

### 1. Escena de integración `game/scenes/base/base.tscn`

**Decisión:** crear una escena `Node2D` con dos hijos instanciados:
`LunarMapWorld` (`game/content/map/lunar/lunar_map_world.tscn`) y `Astronaut`
(`game/content/entities/astronaut/astronaut.tscn`). El script
`game/scenes/base/base.gd` es el único que conoce a ambos:

1. obtiene el `LunarMap` de `LunarMapWorld.get_map()`;
2. llama a `astronaut.setup(map)`;
3. configura los límites de la cámara con `map.get_world_size()`;
4. hace current la cámara del astronauta;
5. llama a `GameSim.start_run()`;
6. marca `GameSim.state.is_outside = true`.

**Por qué:** `LunarMapWorld` sigue siendo un controlador de mapa reutilizable y
`Astronaut` una entidad independiente; la escena base es el único punto de
integración. Así la escena de revisión del mapa y sus tests no cambian.

**Alternativa descartada:** meter al astronauta dentro de `lunar_map_world.tscn`.
Acopla el mapa al gameplay y rompe la escena de revisión con cámara libre.

### 2. Movimiento con colisión por rejilla, sin física de TileSet

**Decisión:** el astronauta comprueba `LunarMap.is_walkable` para las cuatro
esquinas de una caja de colisión de 12×12 px. El movimiento se resuelve por ejes
(primero X, después Y) y en subpasos de 8 px como máximo para no atravesar una
loseta con un delta grande. Una posición es válida solo si las cuatro esquinas
caen dentro del mapa y en celdas transitables.

**Por qué:** el mapa generado ya es la fuente de verdad de transitabilidad y se
puede probar sin física. No hay que añadir una capa de física a los TileSets ni
duplicar la información de sólidos. Los subpasos evitan el tunneling en tests y
en framerates bajos.

**Alternativa descartada:** añadir una capa de física a
`props_tileset.tres` y usar `move_and_slide()`. Obliga a editar el TileSet y el
arte, duplica la regla de transitabilidad y puede desincronizarse del generador.

**Alternativa descartada:** movimiento libre sin colisión. El mapa tiene rocas y
crestas; atravesarlas rompe la lectura del terreno.

### 3. Entrada con InputMap y helper `move()`

**Decisión:** añadir a `game/project.godot` las acciones `move_left`,
`move_right`, `move_up` y `move_down`, con WASD y flechas. El astronauta lee
`Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")` en
`_physics_process` y delega en un método público
`move(direction: Vector2, delta: float) -> void`, que aplica velocidad, colisión
y orientación. El método se puede llamar desde un harness headless sin simular
teclado. Si `GameSim.is_paused()` es verdadero, el astronauta no se mueve.

**Por qué:** el InputMap permite reasignar teclas y no depende de la distribución
física del teclado. `move()` separa la lógica de movimiento de la lectura de
input y hace el comportamiento verificable.

**Alternativa descartada:** comprobar `KEY_W`/`KEY_A`/`KEY_S`/`KEY_D` como hace
`lunar_map_camera_debug.gd`. Es más corto, pero fija la distribución y no usa el
InputMap que el resto del juego necesitará para pausa y velocidad.

### 4. Sprite y orientación

**Decisión:** `Astronaut` es un `CharacterBody2D` con un `Sprite2D`
(`astronaut_4dir.png`, `hframes = 4`), un `CollisionShape2D` de 12×12 px y una
`Camera2D` hija. El frame 0 es abajo, el 1 arriba, el 2 izquierda y el 3 derecha.
No hay animación de caminata: cada dirección tiene un solo frame. Al quedarse
quieto se conserva el último frame.

**Por qué:** el arte ya existe y cubre las cuatro direcciones. `CharacterBody2D`
deja la puerta abierta a colisión física futura sin cambiar la entidad.

**Alternativa descartada:** `AnimatedSprite2D` con cuatro animaciones de un frame.
Añade complejidad sin mejorar el resultado con el arte actual.

### 5. Cámara de juego

**Decisión:** la `Camera2D` es hija del astronauta, con
`position_smoothing_enabled = false`, `zoom = Vector2(1.0, 1.0)` y los límites
`limit_left/top/right/bottom` fijados por `base.gd` a `0, 0, world_size.x,
world_size.y`. `base.gd` la hace current después de que
`LunarMapWorld._ready()` haya hecho current la suya.

**Por qué:** sigue al jugador sin script adicional, respeta el pixel art y no
muestra el vacío. La cámara del mapa se conserva para
`lunar_map_camera_debug.tscn`.

**Alternativa descartada:** mover la cámara del mapa con un script de seguimiento.
Acopla la escena de revisión al gameplay y duplica la lógica de límites que ya
resuelve `Camera2D`.

### 6. Ciclo de partida en `GameSim`

**Decisión:** `game/scripts/autoloads/game_sim.gd` cambia así:

- `paused` empieza en `true` (menús e introducción no avanzan ticks).
- `start_run()` ejecuta `new_game()` y después `paused = false`.
- `stop_run()` ejecuta `paused = true` y `state.is_outside = false`.
- `advance_tick()` pone `paused = true` al emitir `GAME_OVER`, después de emitir
  la señal.
- `new_game()` no cambia de semántica: sigue reiniciando estado, acumulador y
  ledger, y no altera el estado de pausa por sí solo.

`base.gd` llama a `start_run()` al entrar y `stop_run()` en `_exit_tree`.

**Por qué:** un solo dueño del reloj evita ticks en menús, garantiza partida
limpia en cada entrada y congela la partida al morir sin depender de la UI.

**Nota sobre tests:** `advance_tick()` y `advance_ticks()` son APIs de harness y
siguen avanzando el contador interno después de la muerte, como hoy. El reloj de
tiempo real, que es el que usa el juego, queda pausado. Esto conserva
`full_run_check` y `tick_check`.

**Alternativa descartada:** que la introducción active el reloj antes del cambio
de escena. Los ticks correrían durante el fundido y la generación del mapa.

**Alternativa descartada:** un temporizador propio de la escena base. Duplica el
reloj de `GameSim` y rompe el determinismo del núcleo.

### 7. Transición desde la introducción

**Decisión:** `game/scenes/intro/intro.gd` añade la constante
`GAME_SCENE = "res://scenes/base/base.tscn"` y un guard `_starting`. Al pulsar
aceptar: deshabilita el botón, mantiene el texto de confirmación existente,
espera 0.8 s y cambia de escena. Si la escena no existe, muestra un aviso y
vuelve a habilitar el botón. `_go_back()` y la tecla de cancelar se ignoran
mientras `_starting` es verdadero, y el temporizador comprueba que la intro sigue
en el árbol antes de cambiar. La intro llama a `GameSim.set_paused(true)` en
`_ready` como cinturón de seguridad.

**Por qué:** la confirmación se lee antes del cambio y no se puede lanzar dos
transiciones. No hay un scene manager en el proyecto; `change_scene_to_file` es
el patrón existente.

**Alternativa descartada:** cambiar de escena inmediatamente al pulsar aceptar.
La confirmación no se llega a ver y el texto actual quedaría muerto.

### 8. Semilla del mapa

**Decisión:** este cambio usa la configuración por defecto de `LunarMapWorld`
(semilla 1). La selección de mundo sigue afectando solo al nombre de la
introducción.

**Por qué:** variar la semilla por mundo exige instanciar el mapa desde código o
añadir plumbing de configuración; no es necesario para cerrar el primer flujo
jugable. Queda como mejora posterior.

**Alternativa descartada:** derivar la semilla del `World.id`. Es barato, pero
introduce una dependencia entre `WorldStore` y la escena del mapa que no aporta a
este hito.

## Risks / Trade-offs

- **Dos cámaras en la misma escena.** `LunarMapWorld` hace current su cámara en
  `_ready()`; `base.gd` debe hacer current la del astronauta después. Se verifica
  con el harness y con una captura del playtest.
- **Sintaxis del InputMap en `project.godot`.** Un bloque mal formado rompe el
  arranque. Se añade con el editor o el grupo `input_map` del MCP y se comprueba
  con `InputMap.has_action()` y `godot --headless --quit`.
- **Auto-pausa de `GameSim` en tests existentes.** `advance_ticks()` no consulta
  `paused`, así que los harnesses actuales siguen avanzando; se ejecutan todos
  para confirmarlo.
- **Muerte por radiación en ~55 ticks.** Es el comportamiento acordado con el
  usuario; sin HUD no se ve, y por eso la verificación de ticks es headless. Un
  playtest manual largo terminará la partida y la escena quedará congelada.
- **Transición headless.** `change_scene_to_file` dentro de un `SceneTree` de
  test puede ser inestable. Si lo es, el flujo se verifica en el playtest manual y
  el harness comprueba el estado de la intro y la existencia de la escena.
- **Colisión de esquinas.** La caja de 12×12 px puede dejar pasar visualmente el
  borde del sprite sobre una roca; es aceptable para el primer hito y evita
  bloquear pasillos estrechos del mapa generado.

## Migration / Rollout

- Crear el worktree `../MindSpace-worktrees/playable-world` desde `features` al
  día y la rama `playable-world`.
- Llevar `openspec/changes/integrate-playable-world/` al worktree y commitearlo
  en la rama del módulo antes de tocar `game/`.
- Implementar y validar en el worktree; no se toca `main` ni `features`
  directamente.
- Abrir Pull Request de `playable-world` a `features`; archivar el cambio
  OpenSpec después de la integración.
- No hay migración de datos ni cambios en formatos guardados.

## Open Questions

Ninguna. Las decisiones de alcance se cerraron con el usuario: solo superficie
lunar, ticks solo durante la partida, radiación exterior activa y congelación al
morir.
