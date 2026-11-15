# Tasks

## 1. Modelo y objetos

- [x] 1.1 Crear `game/resources/items/item_data.gd` con `id`, `display_name`, `icon`, `description` y `is_valid()`
- [x] 1.2 Crear `game/scripts/inventory/inventory.gd` con 5 espacios, señales, `set_item`, `take_item`, `move_item`, `add_item`, `select` y `cycle_selection`
- [x] 1.3 Escribir los tres `.tres` de muestra en `game/resources/items/`

## 2. Iconos de muestra

- [x] 2.1 Escribir `art/sprites/items/build-items.lua` con los mapas de 16×16 y la paleta cerrada
- [x] 2.2 Generar los `.aseprite` y exportar `game/assets/images/items/*.png` a 2x
- [x] 2.3 Revisar los iconos a ×8 y a tamaño de juego; alfa binario, paleta y `lint_sprite`
- [x] 2.4 Escribir `art/ui/hud/build_stats.lua` y generar `hud_resources_strip` y los cuatro rellenos
- [x] 2.5 Revisar la tira y los rellenos a ×4–×8 y a tamaño de juego; alfa binario, paleta y `lint_sprite`

## 3. Escena y scripts de UI

- [x] 3.1 Crear `game/scenes/ui/inventory_slot.tscn` + `inventory_slot.gd` con marco de selección, icono, clic y arrastre
- [x] 3.2 Crear `game/scenes/ui/hud.tscn` + `hud.gd` con barra, hotbar, cinco espacios, objeto en la mano y entrada 1–5/rueda
- [x] 3.3 Añadir `get_health()` y `get_max_health()` a `game/scripts/autoloads/game_sim.gd` y conectar la barra a `tick_advanced`/`game_reset`
- [x] 3.4 Añadir a `game/scenes/ui/hud.tscn` la tira de recursos sin fondo, sus cuatro barras y porcentajes, y el texto del Sol arriba a la derecha
- [x] 3.5 Conectar en `hud.gd` los recursos y el Sol a `GameSim.state`/`EconomyData`, con refresco por tick, reinicio y velocidad

## 4. Verificación

- [x] 4.1 Crear `game/tests/hud_inventory_test.tscn` + `.gd` con objetos de muestra, aserciones de mover/intercambiar/seleccionar y una captura del HUD
- [x] 4.2 Validar scripts y escena con Godot headless sin errores
- [x] 4.3 Arrancar la escena de prueba, comprobar los logs y revisar la captura a 850×480
- [x] 4.4 Validar el cambio con `openspec validate add-hotbar-inventory --strict`
- [x] 4.5 Ampliar `hud_inventory_test.gd` con aserciones de recursos, Sol y multiplicador
- [x] 4.6 Volver a arrancar la prueba y revisar la captura del HUD completo a 850×480
