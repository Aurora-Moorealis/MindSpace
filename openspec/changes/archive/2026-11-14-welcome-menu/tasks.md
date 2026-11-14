# Tasks

## 1. Arte de interfaz

- [x] 1.1 Generar los tres paneles nine-patch con Aseprite desde `art/ui/build-buttons.lua` y exportarlos a `game/assets/images/ui/`
- [x] 1.2 Añadir Silkscreen y su licencia OFL en `game/assets/fonts/silkscreen/`
- [x] 1.3 Copiar el fondo elegido a `game/scenes/welcome/welcome_bg.png`

## 2. Tema y escena

- [x] 2.1 Crear `game/themes/pixel_theme.tres` con la fuente, los tamaños de texto y los estilos normal, hover y pulsado
- [x] 2.2 Crear `game/scenes/welcome/welcome.tscn` con el fondo, el título, el subtítulo y las dos acciones
- [x] 2.3 Implementar `game/scenes/welcome/welcome.gd` con el foco inicial, la navegación condicional y el aviso temporal

## 3. Configuración del proyecto

- [x] 3.1 Registrar `scenes/welcome/welcome.tscn` como escena principal en `game/project.godot`
- [x] 3.2 Fijar el filtro de textura Nearest en `game/project.godot`
- [x] 3.3 Pasar el stretch a `aspect = keep` y `scale_mode = integer` en `game/project.godot`

## 4. Verificación

- [x] 4.1 Ejecutar `check-gdscript.sh -p game --strict` sin errores de parseo ni avisos de estilo
- [x] 4.2 Arrancar con `godot --headless --quit` sin ERROR ni SCRIPT ERROR
- [x] 4.3 Probar las dos acciones con `game/tests/_welcome_test.gd` y comprobar que el aviso aparece
- [x] 4.4 Revisar la captura del menú a 850×480 y confirmar que ningún elemento del fondo queda cortado

## Workflow follow-up

- Mover los tres textos del menú a la tabla de strings cuando exista.
- Borrar el aviso temporal en cuanto existan las escenas de intro y de ajustes.
