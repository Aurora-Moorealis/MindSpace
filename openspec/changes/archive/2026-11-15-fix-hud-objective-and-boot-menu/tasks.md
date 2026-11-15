# Tasks

## 1. Arranque en el menú

- [x] 1.1 Cambiar `run/main_scene` en `game/project.godot` a `res://scenes/welcome/welcome.tscn`. Verificar con `grep` y con `godot --headless --path game --quit` que arranca sin `ERROR` ni `SCRIPT ERROR`.

## 2. Indicador de misión arriba a la derecha

- [x] 2.1 Mover `ObjectiveLabel` en `game/scenes/ui/hud.tscn` a `offset_left=638`, `offset_top=52`, `offset_right=838`, `offset_bottom=68` y `horizontal_alignment=2`. Verificar con una captura a 850×480 de `res://scenes/base/base.tscn` que queda debajo del reloj y de los controles de tiempo, sin tapar recursos ni barra de vida.

## 3. Verificación y cierre

- [x] 3.1 Ejecutar `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict`, `godot --headless --path game --quit` y una captura del menú de entrada; exigir exit 0 y ausencia de `ERROR`/`SCRIPT ERROR`.
- [x] 3.2 Ejecutar `openspec validate fix-hud-objective-and-boot-menu --strict`, archivar el cambio y revisar `git status` antes del commit.

## Workflow follow-up

- Commit en la rama `win-condition` con el código y el cambio archivado.
- Mantener el checkout principal en `win-condition` para la prueba del usuario.
