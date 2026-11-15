# Proposal

## Why

El HUD ya tiene arte aprobado (`art/ui/hud/`), pero no existe ni el modelo de
inventario ni una escena que lo monte.

El diseño formal
(`docs/designs/junior-astronauta-outpost-lunar.md`) había dejado fuera el grid de
inventario para proteger el alcance de la demo. Este cambio no recupera ese grid:
añade solo lo que la hotbar necesita para ser jugable —5 espacios, un objeto por
espacio y movimiento de lugar por lugar— y monta la barra de vida que ya estaba
dibujada. Es una ampliación pequeña y explícita, no una vuelta al inventario
completo.

## What Changes

- Nueva capability `inventory`: un inventario de 5 espacios, un objeto por
  espacio, con recoger, colocar, intercambiar, arrastrar y soltar, y selección del
  espacio activo.
- Nueva capability `hud`: escena de HUD instanciable con la hotbar abajo, la
  barra de vida arriba, una tira minimal de recursos (O₂, agua, comida y energía,
  con sus capacidades) pegada arriba a la izquierda y el texto del Sol arriba a
  la derecha, todo leído de `GameSim`; ambos sin fondo para no tapar el mundo.
- Nuevo recurso `ItemData` (id, nombre, icono, descripción) y tres objetos de
  muestra con su icono pixel-art para poder probar el sistema.
- La hotbar reutiliza las texturas ya aprobadas; la barra de vida usa la variante
  ámbar cuando la salud baja del 30 %.

## Capabilities

### New Capabilities

- `inventory`: espacios, objetos, movimiento de lugar por lugar y selección.
- `hud`: composición de la hotbar, la barra de vida, la tira de recursos y el Sol
  en partida, y su lectura de la simulación.

### Modified Capabilities

Ninguna. `GameSim` solo gana dos getters de lectura; su comportamiento de tick no
cambia.

## Impact

- `game/scripts/inventory/inventory.gd` (modelo).
- `game/resources/items/item_data.gd` y `game/resources/items/*.tres` (objetos de
  muestra).
- `game/scenes/ui/hud.tscn`, `game/scenes/ui/hud.gd`,
  `game/scenes/ui/inventory_slot.tscn`, `game/scenes/ui/inventory_slot.gd`.
- `game/scripts/autoloads/game_sim.gd`: `get_health()` y `get_max_health()`.
- `game/assets/images/items/` (3 iconos de muestra) y
  `art/sprites/items/build-items.lua` (generador Aseprite).
- `game/assets/images/ui/hud/hud_resources_strip.png` y los cuatro rellenos
  (`hud_stat_fill_*`) con su generador `art/ui/hud/build_stats.lua`.
- `game/tests/hud_inventory_test.*`: escena local de prueba, no versionada.

## Fuera de alcance

- Apilar objetos o mostrar contadores: un objeto por espacio.
- Pantalla de inventario completa, grid mayor que la hotbar o varias mochilas.
- Crafteo, loot tables, recetas, rarezas o generación de objetos.
- Persistencia entre partidas o entre escenas.
- Usar, consumir, equipar o soltar objetos; la selección solo marca el espacio
  activo.
- Mover objetos entre inventarios distintos (cofres, máquinas, suelo).
- Controles de mando y un input map configurable: teclas 1–5 y rueda del ratón.
- Textos localizados: los nombres de muestra van en inglés.
- Sonido, animaciones de UI o feedback de partículas.
- Botones de pausa o velocidad: solo se muestra el multiplicador.
- Gráficos o tendencias históricas de los recursos.
- Radiación, hambre y sed en el HUD: se retiran de esta versión.
