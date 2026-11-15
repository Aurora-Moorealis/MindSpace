# Tasks

## 1. Núcleo de red

- [x] 1.1 Crear `game/scripts/simulation/power_link.gd` con dos ids de nodo y comparación no dirigida
- [x] 1.2 Crear `game/scripts/simulation/power_network.gd` con id, nodos, baterías y agregados (carga, capacidad, demanda)
- [x] 1.3 Crear `game/scripts/simulation/power_grid.gd` con componentes conexas y el default de red única
- [x] 1.4 Añadir a `game/scripts/simulation/sim_state.gd` las baterías, los enlaces y el apagón por red
- [x] 1.5 Exponer la energía total como espejo de las baterías en `get_resource`/`set_resource`

## 2. Tick

- [x] 2.1 Mover la producción solar a las baterías de su red en `sim_tick.gd`
- [x] 2.2 Repartir la demanda por red y descontar de las baterías de cada red
- [x] 2.3 Evaluar la escalera de apagado dentro de cada red y registrar un `BLACKOUT` por episodio
- [x] 2.4 Publicar los enlaces desde `game/scripts/autoloads/game_sim.gd` y emitir la señal de red
- [x] 2.5 Recalcular la red al colocar o retirar un cable, sin recargar la escena

## 3. Contenido jugable

- [x] 3.1 Crear `game/content/machines/machine_base.gd` con id, puerto, estado y refresco visual
- [x] 3.2 Crear `solar_array.tscn` + `solar_array.gd` con su Sprite2D y colisión
- [x] 3.3 Crear `battery.tscn` + `battery.gd` con su Sprite2D y colisión
- [x] 3.4 Crear `power_cable.tscn` + `power_cable.gd` con ruta en L y máscara de conexión
- [x] 3.5 Crear `power_cable_tileset.tres` con la rejilla de 32×32

## 4. Arte

- [x] 4.1 Escribir `art/sprites/machines/build-energy.lua` con la paleta cerrada y el generador de las tres piezas
- [x] 4.2 Generar y revisar `solar_array.aseprite`/`.png` a ×4–×8 y a tamaño de juego
- [x] 4.3 Generar y revisar `battery.aseprite`/`.png` a ×4–×8 y a tamaño de juego
- [x] 4.4 Generar y revisar `power_cable_atlas.aseprite`/`.png` con las 16 máscaras
- [x] 4.5 Exportar a `game/content/machines/` y comprobar alfa binario, paleta y `lint_sprite`

## 5. Verificación

- [x] 5.1 Ampliar `game/scripts/dev/sim_smoke.gd` con red cortada, panel sin batería y apagón aislado
- [x] 5.2 Ejecutar `sim_smoke.gd` en headless y dejar las comprobaciones existentes en verde
- [x] 5.3 Ejecutar `check-gdscript.sh -p game --strict`
- [x] 5.4 Arrancar `godot --headless --quit --path game` sin `ERROR` ni `SCRIPT ERROR`
- [x] 5.5 Validar el cambio con `openspec validate energy-grid --strict`
