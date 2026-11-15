# Design

## Context

Ver `proposal.md` para la motivación y `specs/inventory/spec.md` +
`specs/hud/spec.md` para el contrato observable. El arte del HUD ya existe en
`game/assets/images/ui/hud/` (hotbar 288×80, selección 48×48, barra 328×48 y
relleno 240×20, todo a 2x). El proyecto no tiene escena de partida ni inventario;
el diseño formal dejó el grid fuera de alcance.

Restricciones que condicionan la implementación:

- GDScript 4.7 con tipado explícito obligatorio; prohibido `:=`.
- El layout se diseña para 850×480 exactos y se instancia en un `CanvasLayer`
  para que no lo mueva la cámara del mundo.
- El modelo debe poder probarse en headless, sin nodos de escena.
- La UI habla inglés; comentarios e identificadores, inglés.
- No se añaden autoloads sin pedirlo: el inventario vive en la escena del HUD.

## Goals / Non-Goals

**Goals:**

- Que el jugador pueda mover objetos de un espacio a otro, de uno en uno, y
  elegir el espacio activo.
- Que el modelo de inventario sea independiente de la escena y determinista.
- Que la barra de vida muestre la salud real de `GameSim` sin que el HUD conozca
  el resto de la simulación.
- Que la hotbar y la barra se puedan instanciar en cualquier escena de partida
  como una sola sub-escena.

**Non-Goals:**

- Apilar, contar, craftear, persistir o usar objetos.
- Un grid de inventario mayor o una pantalla dedicada.
- Controles de mando, input map configurable o localización.

## Decisions

### 1. El modelo es un `RefCounted` separado de la vista

`Inventory` (`game/scripts/inventory/inventory.gd`) guarda `Array[ItemData]` de
tamaño fijo 5, el índice seleccionado y las señales `slot_changed(index, item)` y
`selection_changed(index)`. La escena nunca escribe el array: llama a
`set_item`, `take_item`, `move_item`, `add_item` y `select`.

**Alternativa descartada:** un autoload `Inventory`. Daría estado global y
persistencia gratis, pero obliga a limpiarlo en `new_game`, complica las pruebas
de UI y permite que dos escenas compartan un inventario que no es suyo. El HUD es
dueño del inventario de la partida; el juego lo obtiene con
`hud.get_inventory()`.

### 2. Un objeto por espacio, sin contadores

Cada espacio contiene un `ItemData` o `null`. No hay pila ni cantidad: el
contrato es "un lugar, un objeto". Es lo que la hotbar de 5 espacios puede
mostrar sin añadir números y evita decidir ahora reglas de stack que el diseño
formal no tiene.

**Alternativa descartada:** `ItemStack` con cantidad y `max_stack`. Añade
interfaz, reglas de fusión y casos de prueba que no se piden.

### 3. El objeto en la mano es estado de la vista, no del modelo

Al hacer clic en un espacio con objeto, el HUD lo saca del modelo con
`take_item(index)` y lo guarda en `_held_item`; el espacio queda vacío. Al hacer
clic en otro espacio, coloca o intercambia (`set_item` + el objeto anterior pasa a
la mano). Clic derecho devuelve el objeto al primer hueco libre. Arrastrar y
soltar llama a `move_item(from, to)`, que intercambia.

Así el inventario siempre representa lo que hay en los espacios: si la escena se
libera con un objeto en la mano, no queda un objeto fantasma en el modelo.

**Alternativa descartada:** que el modelo guarde el objeto "en la mano". Mezcla
estado de UI con estado de juego y obliga a limpiarlo al cerrar el HUD.

### 4. Clic para mover y arrastrar como alternativa

El clic es el camino principal: un clic recoge, otro coloca o intercambia, y el
clic derecho cancela. Arrastrar y soltar reutiliza los mismos métodos del modelo
y ofrece el gesto directo. Mantener los dos no duplica reglas porque ambos
terminan en `move_item`/`set_item`.

**Alternativa descartada:** solo arrastrar. Es peor con teclado y más difícil de
probar con entrada simulada.

### 5. Selección del espacio activo

`Inventory.select(index)` emite `selection_changed` solo si cambia. El HUD
escucha las teclas 1–5 y la rueda; al colocar un objeto selecciona el espacio
destino, y al hacer clic en un espacio vacío lo selecciona. La selección no usa
el objeto: deja preparado el espacio activo para una acción futura.

**Alternativa descartada:** un `InputMap` nuevo para `hotbar_1..5`. No hay mapa de
entrada de partida todavía; las teclas directas evitan tocar `project.godot` y se
pueden migrar a acciones cuando exista el mapa.

### 6. Escena del HUD en `CanvasLayer`

`game/scenes/ui/hud.tscn` tiene raíz `CanvasLayer` (layer 10) con un `Control`
hijo de pantalla completa y `mouse_filter = IGNORE`. Los hijos van en posiciones
absolutas de 850×480: barra en `(260, 24)`, hotbar en `(280, 372)` y espacios en
`(296 + 52·i, 388)`. El `Control` raíz no bloquea el mundo; solo los cinco
espacios capturan ratón.

Cada espacio es `game/scenes/ui/inventory_slot.tscn` (Control 48×48) con el marco
de selección detrás y el icono 32×32 delante. El marco sustituye el pozo, no lo
rodea, para no tapar los tornillos del panel.

**Alternativa descartada:** dibujar la hotbar con `_draw` y formas. Duplicaría el
arte aprobado y perdería el bisel y los tornillos.

### 7. La barra de vida lee `GameSim` por dos getters

`GameSim` gana `get_health()` y `get_max_health()` (solo lectura). El HUD conecta
`tick_advanced` y `game_reset`, llama a `set_health(current, maximum)` y actualiza
un `TextureProgressBar`. Por debajo del 30 % cambia la textura de relleno a
`hud_health_fill_low.png`; por encima vuelve a la normal. El umbral es una
constante del script.

**Alternativa descartada:** un autoload `HealthUI` o una señal nueva por tick.
Dos getters y las señales existentes bastan y no amplían el contrato de la
simulación.

### 8. Objetos de muestra, no contenido definitivo

`ItemData` (`game/resources/items/item_data.gd`) expone `id`, `display_name`,
`icon` y `description`. Se crean tres `.tres` de muestra en
`game/resources/items/` con iconos de 16×16 de arte (32×32 en pantalla) en
`game/assets/images/items/`, generados por `art/sprites/items/build-items.lua`.
Son placeholders para probar la hotbar; el loot real llega con la misión.

### 9. Tira minimal de recursos y Sol sin panel

La barra de vida se queda centrada arriba. Los recursos van en una tira de 88×36
de arte (176×72 en pantalla) pegada arriba a la izquierda, en `(8, 8)`, sin panel
ni tornillos: cuatro filas con icono de 8×8, pista de 60×6, relleno de 58×4 y
porcentaje de 8 px a la derecha. El Sol va como una sola etiqueta de texto de
8 px alineada a la derecha en `(674, 8)`, sin fondo.

- La tira no bloquea el mundo: solo dibuja iconos, pistas y texto.
- La barra de vida sigue en `(260, 24)` y la hotbar en `(280, 372)`.
- La paleta no se amplía: O₂ en teal, agua en la rampa de hielo, comida en ámbar
  y energía en la rampa silícea.
- Los datos salen de `SimState`/`EconomyData` sin añadir autoloads:
  `capacity_oxygen|water|food|energy`, `get_energy_total()`, `tick`,
  `get_sol_length()` y `get_phase()`. El multiplicador se lee de `GameSim.speed`.
  Las barras se refrescan en `tick_advanced` y `game_reset`; el Sol también en
  `_process` para que un cambio de velocidad no espere 60 s.
- Radiación, hambre y sed se retiran del HUD en esta versión.

**Alternativas descartadas:** el panel de 120×56 con fondo navy (tapa demasiado
mundo y el autor lo quiere minimal); el panel de estado a la derecha (se
sustituye por solo el texto del Sol); texto a 16 px (no cabe en filas compactas);
solo números sin barras (peor lectura de un vistazo).

## Archivos

- `game/scripts/inventory/inventory.gd`
- `game/resources/items/item_data.gd`
- `game/resources/items/water_canister.tres`, `ration_pack.tres`,
  `oxygen_cartridge.tres`
- `game/scenes/ui/hud.tscn`, `game/scenes/ui/hud.gd`
- `game/scenes/ui/inventory_slot.tscn`, `game/scenes/ui/inventory_slot.gd`
- `game/scripts/autoloads/game_sim.gd` (dos getters)
- `game/assets/images/items/{water_canister,ration_pack,oxygen_cartridge}.png`
- `art/sprites/items/build-items.lua` y sus `.aseprite`
- `game/assets/images/ui/hud/hud_resources_strip.png` y
  `hud_stat_fill_{oxygen,water,food,energy}.png`
- `art/ui/hud/build_stats.lua` y sus `.aseprite`
- `game/tests/hud_inventory_test.tscn` y `.gd` (local, no versionado)
