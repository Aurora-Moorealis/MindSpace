# Tasks

## 1. Entrada y escena

- [x] 1.1 Registrar `move_left/right/up/down` (WASD + flechas) e `interact` (E) en `game/project.godot`
- [x] 1.2 Generar `astronaut_4dir@2x.png` desde la hoja existente con vecino más cercano
- [x] 1.3 Crear `game/content/entities/astronaut/astronaut.tscn` con CharacterBody2D, Sprite2D, colisión de pies y sensores de interacción y zona
- [x] 1.4 Crear `astronaut.gd` con movimiento normalizado, dirección de sprite y parada en fin de partida

## 2. Interacción

- [x] 2.1 Añadir a `machine_base.gd` el área de interacción, el alta en `interactables` y el método `interact()`
- [x] 2.2 Implementar en `astronaut.gd` el sensor de áreas, la elección del objetivo más cercano y la llamada a `interact`
- [x] 2.3 Exponer el objetivo actual para que la UI pueda mostrar el aviso

## 3. Traje y zona

- [x] 3.1 Añadir `suit_level` a `sim_state.gd` y reiniciarlo a 0
- [x] 3.2 Añadir `suit_v2_radiation_multiplier.tres` y registrarlo en `economy.tres`
- [x] 3.3 Aplicar el multiplicador en `sim_tick.gd`
- [x] 3.4 Añadir `set_outside` y `set_suit_level` a `game_sim.gd`
- [x] 3.5 Implementar traje y zona en `astronaut.gd`, con reaplicación en `game_reset`
- [x] 3.6 Crear `airlock_zone.tscn` + `airlock_zone.gd` en `content/map/airlock/`

## 4. Vitales

- [x] 4.1 Exponer salud, oxígeno, hambre y sed en `astronaut.gd`
- [x] 4.2 Emitir `vitals_changed` en cada tick

## 5. Verificación

- [x] 5.1 Ampliar `sim_smoke.gd` con la dosis con y sin traje reforzado
- [x] 5.2 Probar la escena del astronauta: movimiento, dirección, interacción y zona
- [x] 5.3 Ejecutar `check-gdscript.sh -p game --strict`
- [x] 5.4 Arrancar `godot --headless --quit --path game` sin errores
- [x] 5.5 Capturar la escena y revisar el astronauta a tamaño de juego
- [x] 5.6 Validar con `openspec validate astronaut --strict`
