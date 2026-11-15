# Design

## Context

Ver `proposal.md` para la motivación y `specs/energy-grid/spec.md` +
`specs/simulation-core/spec.md` para el contrato observable. El núcleo actual
(`SimTick` + `SimState`) trata la energía como un único depósito global: el panel
suma y las máquinas restan sin mirar si hay batería o cable. El diseño formal pide
un panel solar exterior y una batería, y este cambio les da una red que los une.

Restricciones que condicionan la implementación:

- GDScript 4.7 con tipado explícito obligatorio; prohibido `:=`.
- El núcleo debe seguir siendo determinista y verificable en headless.
- La base arranca **pre-cableada**: una batería y todas las máquinas en la misma
  red. Sin ese default, el primer tick de cualquier partida moriría por falta de
  energía y las pruebas existentes dejarían de tener sentido.
- El arte sigue la spec `art-style` y el manual `docs/guia-estetica.md`.
- Las escenas y scripts nuevos de una máquina viven en
  `game/content/machines/<nombre>/`.

## Goals / Non-Goals

**Goals:**

- Que quitar el cable entre el panel y la batería tenga una consecuencia visible.
- Que el estado de energía siga siendo un número que el HUD y la evaluación leen
  sin conocer la topología.
- Que la red se calcule desde datos puros (enlaces + estado) y no desde nodos de
  escena, para poder probarla en headless.
- Panel, batería y cable jugables y legibles en el mapa.

**Non-Goals:**

- Construcción libre de la base, tendido automático y rutas que esquiven muros.
- Prioridades manuales de reparto y panel de red.
- Varias políticas de carga o baterías con química distinta.
- Animaciones de carga, chispas o estados de avería del cable.

## Decisions

### 1. La batería es la fuente de verdad y la energía global es un espejo

`SimState` gana `batteries: Dictionary[StringName, float]` (id → carga). La energía
total que ya consumían el HUD y las pruebas se mantiene en
`resources[ENERGY]` como **espejo** que `SimTick` recalcula al final de la
producción/consumo. `get_resource(ENERGY)` lee el espejo y `set_resource(ENERGY, v)`
reparte el valor de forma determinista entre las baterías (la primera se lleva todo
lo que quepa y el resto continúa). Así ninguna API existente cambia y una partida
con una sola batería se comporta igual que antes.

**Alternativa descartada:** quitar `resources[ENERGY]` y reescribir HUD,
evaluación y pruebas. Más limpio, pero rompe consumidores que no forman parte de
este cambio y añade riesgo sin beneficio visible para el jugador.

### 2. Redes como componentes conexas, calculadas por tick

`PowerGrid.build(state) -> Array[PowerNetwork]` recorre los enlaces y devuelve
las componentes conexas. Cada `PowerNetwork` guarda su id (el id de nodo
lexicográficamente menor, para que sea estable y determinista), sus nodos y sus
baterías. Los enlaces son `PowerLink(a, b)` no dirigidos; un id repetido no crea
nodos duplicados.

**Default sin enlaces:** si `power_links` está vacío, se devuelve **una sola red**
con todas las máquinas y todas las baterías. Es la base pre-cableada. En cuanto el
jugador coloca un cable, los enlaces pasan a mandar y el default desaparece.

**Alternativa descartada:** reconstruir la red desde los TileMapLayer de la escena.
Ataría la simulación a nodos y haría imposible el test headless; la escena ya
declara los enlaces que la simulación necesita.

### 3. El panel necesita batería; sin almacenamiento no hay red

La producción solar entra en las baterías de la misma red. Si no hay batería, se
descarta. El motivo es de diseño: el par panel + batería + cable es la lección; un
panel que alimenta máquinas por sí solo convierte la batería en decoración.

**Alternativa descartada:** permitir consumo directo de la generación del tick.
Físicamente razonable, pero deja la batería sin función hasta que el jugador se
queda a oscuras, y el tutorial no puede enseñarlo.

### 4. Apagado por red, con el mismo orden

La escalera `lights → hydroponics → water_recycler → o2_system` se evalúa **dentro
de cada red**. `SimState` pasa de `blackout_active: bool` a
`blackout_networks: Dictionary[StringName, bool]` para registrar un `BLACKOUT` por
episodio y red. El hecho incluye el id de red en el payload para poder depurarlo.

**Alternativa descartada:** un único estado de apagón global. Simple, pero apagar
la red del invernadero apagaría también la del sistema de O₂ aunque estuvieran
separadas, y el jugador perdería la lectura de qué cable ha cortado.

### 5. El cable es un TileMapLayer con ruta en L

`PowerCable` es un `Node2D` con dos `NodePath` exportados (`endpoint_a`,
`endpoint_b`) y un `TileMapLayer` hijo. En `_ready()`:

1. Resuelve ambos extremos y pide su posición de puerto a `MachineBase`.
2. Convierte las posiciones a celdas de 32 px y pinta una ruta en L (primero
   horizontal, luego vertical) en el `TileMapLayer`.
3. Recalcula la máscara de cada celda (N=1, E=2, S=4, W=8), elige la loseta del
   atlas y la pinta.
4. Registra el `PowerLink` en el controlador de red.

Los cables avisan al grupo `power_controllers` al entrar y salir del árbol, y
`PowerGridController` se registra en ese grupo, de modo que colocar o retirar un
cable recalcula la red sin recargar la escena.

Si un extremo falta o no es un nodo válido, el cable no pinta ni registra nada. La
ruta en L es suficiente para una base de cinco salas y evita un buscador de
caminos; no esquiva muros (fuera de alcance, documentado).

**Alternativa descartada:** `Line2D` con textura repetida. Más barato, pero no
produce esquinas limpias ni encaja en la rejilla de 32 px.

### 6. Escenas mínimas, sin sistema de interacción nuevo

`MachineBase` expone `machine_id`, `power_node_id()`, `port_position()` y un
método `refresh_from_state()` que refleja `powered`/`health` en un `modulate` y en
una etiqueta de estado. No implementa reparación ni mejoras: eso pertenece al
cambio de máquinas interactuables. El objetivo aquí es que panel, batería y cable
existan, se puedan instanciar y se lean en el mapa.

### 7. Arte: tres piezas, misma luz y paleta

- **Panel solar** (`solar_array.png`): 80×56 de arte → 160×112 de pantalla (5×3.5
  losetas). Referencia real: marco de aluminio, 24 celdas monocristalinas azul
  marino con dedos y busbars plateados, viga y patas de aluminio, etiqueta de
  serie y caja de conexión con puerto teal. Luz arriba-izquierda y contorno
  `#0F171F`.
- **Batería** (`battery.png`): 32×48 de arte → 64×96 de pantalla (2×3 losetas).
  Cuerpo de casco, indicador ámbar de carga, bornes teal y remaches.
- **Cable** (`power_cable_atlas.png`): atlas de 4×4 losetas de 16×16 de arte →
  128×128 de pantalla. Máscara N=1, E=2, S=4, W=8; los 16 índices cubren extremos,
  rectas, esquinas, T y cruz. Se pinta en un `TileSet` de 32×32.

Los maestros `.aseprite` y el generador Lua viven en `art/sprites/machines/`, como
el resto del arte del repositorio. Los PNG exportados viven en la carpeta de cada
máquina, porque solo los usa ese contenido.

## Files

| Archivo | Acción |
| --- | --- |
| `game/scripts/simulation/power_link.gd` | Crear: enlace no dirigido entre dos ids. |
| `game/scripts/simulation/power_network.gd` | Crear: nodos, baterías y agregados de una red. |
| `game/scripts/simulation/power_grid.gd` | Crear: construcción de redes desde enlaces. |
| `game/scripts/simulation/power_grid_controller.gd` | Crear: recoge los cables de la escena y publica sus enlaces. |
| `game/scripts/simulation/sim_state.gd` | Modificar: baterías, enlaces, apagón por red. |
| `game/scripts/simulation/sim_tick.gd` | Modificar: producción/consumo por red. |
| `game/scripts/autoloads/game_sim.gd` | Modificar: `set_power_links()` y señal de red. |
| `game/scripts/dev/sim_smoke.gd` | Modificar: pruebas de red y batería. |
| `game/content/machines/machine_base.gd` | Crear: nodo de energía e interfaz común. |
| `game/content/machines/solar_array/solar_array.tscn` | Crear. |
| `game/content/machines/solar_array/solar_array.gd` | Crear. |
| `game/content/machines/battery/battery.tscn` | Crear. |
| `game/content/machines/battery/battery.gd` | Crear. |
| `game/content/machines/power_cable/power_cable.tscn` | Crear. |
| `game/content/machines/power_cable/power_cable.gd` | Crear. |
| `game/content/machines/power_cable/power_cable_tileset.tres` | Crear. |
| `art/sprites/machines/build-energy.lua` | Crear: generador de los tres assets. |

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| El default de red única oculta errores de topología | Las pruebas construyen redes explícitas con dos baterías y cables cortados. |
| Iterar diccionarios en orden distinto rompe el determinismo | Las redes ordenan sus ids con `Array.sort()` antes de recorrerlos. |
| El cable en L atraviesa muros | Documentado como fuera de alcance; el jugador coloca los nodos en la misma sala o en salas contiguas. |
| Dos baterías en la misma red no reparten la carga "a medias" | Se descarga en orden de id, determinista; el total es correcto y la diferencia no es observable en el HUD. |
| Cambiar `resources[ENERGY]` por baterías rompe consumidores | El espejo mantiene `resources[ENERGY]` como única lectura externa. |
| Un panel aislado con batería sigue cargando aunque no haya consumidores | Es correcto: la energía se almacena y el excedente se descarta. |
| El arte del cable no cubre cruces con otros cables | El atlas incluye la cruz (máscara 15); el repintado recalcula la máscara de las celdas vecinas. |

## Open Questions

- Si la batería tendrá una segunda mejora de capacidad o de rendimiento se decide
  cuando exista el sistema de mejoras; este cambio deja la capacidad como fila de
  economía por batería.
