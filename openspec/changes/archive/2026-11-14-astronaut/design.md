# Design

## Context

Ver `proposal.md` y las specs `astronaut` + `simulation-core`. Ya existen
`SimState`, `SimTick`, `GameSim`, las máquinas de energía y la hoja de sprites
`astronaut_4dir.png` (128×32: cuatro vistas de 32×32 de arte). No existe escena
del jugador, ni mapa de inputs, ni forma de marcar el exterior.

Restricciones:

- GDScript 4.7 con tipado explícito; prohibido `:=`.
- El astronauta vive en `game/content/entities/astronaut/` con todo lo suyo.
- La presentación del arte es ×2 (cada píxel artístico ocupa 2×2 en pantalla).
- Las reglas de radiación viven en `SimTick`; el astronauta solo declara zona y
  traje.
- El proyecto no tiene escena base todavía: el astronauta debe poder instanciarse
  y probarse por separado.

## Goals / Non-Goals

**Goals:**

- Un avatar que se mueva, mire en cuatro direcciones y detecte la máquina más
  cercana sin que la lógica de interacción dependa de coordenadas del mapa.
- Que cruzar al exterior tenga consecuencia real en la dosis, y que el traje
  reforzado se note en el tick.
- Vitales legibles desde la UI sin acoplarla al autoload.

**Non-Goals:**

- Animación de caminata, inventario, mapa completo, cámara y HUD.
- Reparación y mejoras (solo se llama a `interact`).
- Cambiar la reserva de traje ni la escalera de O₂.

## Decisions

### 1. CharacterBody2D con colisión a los pies

`Astronaut` es un `CharacterBody2D` con una cápsula/rectángulo de 34×18 centrada
en los pies (origen del nodo). El sprite se dibuja con `offset = (-3, -28)` y la
hoja a ×2 para que los pies coincidan con el origen y el cuerpo quede por encima.
La velocidad es una exportación (`move_speed`, 120 px/s) y se normaliza la
dirección.

**Alternativa descartada:** mover un `Node2D` a mano con `position +=`. Evita la
colisión con muros, que es obligatoria en una base con pasillos.

### 2. Mapa de inputs propio, no `ui_*`

Se añaden a `project.godot` las acciones `move_left`, `move_right`, `move_up`,
`move_down` (WASD + flechas) e `interact` (E). `ui_*` ya está tomado por la UI y
no distingue WASD.

**Alternativa descartada:** leer `Input.is_key_pressed(KEY_W)` en el script. Menos
configuración, pero rompe el remapeo y el diseño pide un mapa de inputs.

### 3. Dirección como índice de frame

La hoja tiene cuatro vistas en orden frontal, trasera, izquierda, derecha. El
script guarda `_facing` como índice y lo usa para `Sprite2D.frame`; al moverse en
 diagonal gana el eje horizontal. No hay animación porque la hoja no la trae: el
cambio no inventa frames.

### 4. Interacción con sensor de área y grupo

Cada `MachineBase` crea un `Area2D` de interacción en la capa 3 y se registra en
el grupo `interactables`. El astronauta tiene un `Area2D` sensor (máscara 3) que
acumula las áreas solapadas y elige la de menor distancia al cuerpo. Al pulsar
interactuar llama a `interact(astronaut)` si el nodo lo implementa.

**Por qué un área y no solo distancia:** el área la dibuja y ajusta el diseñador
en la escena; la distancia elige el objetivo cuando hay solape (por ejemplo, dos
m áquinas juntas).

**Alternativa descartada:** raycast hacia delante. El astronauta es top-down y
la interacción debe funcionar de lado y por detrás.

### 5. Zona exterior como área marcada

`AirlockZone` es un `Area2D` de la capa 4 que se registra en `exterior_zones` y
representa la zona de exterior. El `ZoneSensor` del astronauta (máscara 4) avisa
al entrar y al salir. El astronauta escribe `GameSim.set_outside(...)`.

**Por qué una zona y no una propiedad del mapa:** el mapa definitivo puede tener
varias salidas; cada una coloca su `AirlockZone` sin tocar al jugador.

### 6. Traje en el estado de simulación

`SimState` gana `suit_level: int` (0 básico, 1 reforzado). `SimTick._apply_radiation`
multiplica la fila `radiation_per_tick_exterior` por
`suit_v2_radiation_multiplier` cuando el nivel es 1. El astronauta aplica su
`@export var suit` en `_ready` y en `game_reset`; el estado reinicia a 0.

**Alternativa descartada:** guardar el traje solo en el astronauta y pasar un
multiplicador a `SimTick`. Ataría el tick puro a un nodo de escena y rompería el
test headless.

### 7. Vitales como getters y señal

El astronauta expone `get_health()`, `get_oxygen()`, `get_hunger()`,
`get_thirst()` y emite `vitals_changed` en cada `tick_advanced`. No duplica los
valores: los lee de `GameSim.state`, que es la única fuente.

### 8. Arte a ×2 sin reescribir la hoja

La hoja original es de 32×32 por vista (arte). Se genera
`astronaut_4dir@2x.png` con vecino más cercano y se usa esa textura, para respetar
la presentación ×2 del proyecto sin tocar el dibujo.

## Files

| Archivo | Acción |
| --- | --- |
| `game/content/entities/astronaut/astronaut.tscn` | Crear: CharacterBody2D, sprite, colisión y sensores. |
| `game/content/entities/astronaut/astronaut.gd` | Crear: movimiento, dirección, interacción, traje, zona y vitales. |
| `game/content/entities/astronaut/astronaut_4dir@2x.png` | Crear: export ×2 de la hoja. |
| `game/content/map/airlock/airlock_zone.tscn` | Crear: área de exterior. |
| `game/content/map/airlock/airlock_zone.gd` | Crear: alta en `exterior_zones`. |
| `game/content/machines/machine_base.gd` | Modificar: área de interacción y `interact()`. |
| `game/scripts/simulation/sim_state.gd` | Modificar: `suit_level`. |
| `game/scripts/simulation/sim_tick.gd` | Modificar: multiplicador de traje. |
| `game/scripts/autoloads/game_sim.gd` | Modificar: `set_outside`, `set_suit_level`. |
| `game/databases/economy_rows/suit_v2_radiation_multiplier.tres` | Crear. |
| `game/databases/economy.tres` | Modificar: registrar la fila. |
| `game/project.godot` | Modificar: acciones de input. |
| `game/scripts/dev/sim_smoke.gd` | Modificar: prueba del traje. |

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| La hoja no tiene animación y el personaje parece estático | Se conserva la dirección y el cambio no inventa arte; una animación es otro cambio. |
| El sensor de interacción detecta áreas de otras capas | Máscara fija a la capa 3 y grupo `interactables`. |
| El astronauta se queda fuera al reiniciar | `game_reset` reaplica traje y vuelve a interior. |
| La fila nueva de economía se olvida en el índice | Se añade a `economy.tres` y `sim_smoke` la ejercita. |
| El jugador atraviesa muros si la escena no tiene colisión | La escena base define la capa 1; el astronauta ya colisiona con ella. |
| La zona exterior es un área rectangular y no un volumen del mapa | Suficiente para el vertical slice; el mapa definitivo puede colocar varias. |

## Open Questions

- Si el traje reforzado también cambia la reserva de O₂ o la velocidad se decide
  cuando exista el sistema de mejoras; este cambio solo toca la radiación.
