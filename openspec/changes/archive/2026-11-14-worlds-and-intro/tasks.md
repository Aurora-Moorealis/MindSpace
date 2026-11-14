# Tasks

## 1. Mundos

- [x] 1.1 Persistir los mundos en `user://worlds.json` con `WorldStore` (`scenes/worlds/world_store.gd`)
- [x] 1.2 Validar nombre vacío, largo máximo y duplicado en `validate_name`
- [x] 1.3 Listar, crear y elegir mundos desde `scenes/worlds/worlds.gd`
- [x] 1.4 Borrar con confirmación de dos pulsaciones y reversión a los tres segundos
- [x] 1.5 Volver al menú con el botón y con la tecla de cancelar

## 2. Introducción

- [x] 2.1 Escena `scenes/intro/intro.tscn` con cielo, Tierra, Luna y los dos cohetes
- [x] 2.2 Animación de salida y travesía con tweens, más el botón Saltar
- [x] 2.3 Siete partes de historia con Continuar y sustitución del nombre del mundo
- [x] 2.4 Pantalla de aceptación con el nombre del mundo y vuelta a mundos
- [x] 2.5 Entrar en la intro desde la pantalla de mundos

## 3. TileSets

- [x] 3.1 Tres TileSets con rejilla de 32×32 (`ground`, `props`, `base`)
- [x] 3.2 Datos por loseta: material, variante y bloqueo de paso
- [x] 3.3 Cuatro orientaciones del muro como tiles alternativos
- [x] 3.4 Escena de muestra que pinta suelo, sala, rocas y minerales

## 4. Verificación

- [x] 4.1 `check-gdscript.sh -p game --strict` sin errores ni avisos
- [x] 4.2 `godot --headless --quit` sin `ERROR` ni `SCRIPT ERROR`
- [x] 4.3 `tests/_worlds_test.gd`, `tests/_intro_flow.gd` y `tests/_tileset_check.gd` en verde
- [x] 4.4 Capturas de la pantalla de mundos, la intro y el mapa de muestra
