# Tasks

## 1. Audio base

- [x] 1.1 Mover `plant.ogg`, `harvest.ogg` y `remove.ogg` a `game/content/machines/hydroponics/sounds/` y dejar el resto en `game/assets/audio/sfx/`; verificar con `ffprobe` que todos son mono 44.1 kHz y que no queda ningún duplicado entre las dos carpetas.
- [x] 1.2 Crear `game/scripts/autoloads/audio_manager.gd` y `game/default_bus_layout.tres`, y registrar el autoload en `game/project.godot`; verificar que el bus `SFX` existe y que los 12 streams cargan.
- [x] 1.3 Actualizar `game/assets/audio/sfx/README.md` con la tabla de sonidos y su dueño; verificar que cada ruta del README existe en disco.

## 2. Menús y flujo

- [x] 2.1 Añadir clic/abrir/denegar en `game/scenes/welcome/welcome.gd` y `game/scenes/worlds/worlds.gd`; verificar que crear/entrar/borrar y volver producen el SFX correcto y que un error de validación suena a denegación.
- [x] 2.2 Añadir clic/abrir/cerrar en `game/scenes/intro/intro.gd`, `game/scenes/evaluation/evaluation.gd` y `game/scenes/ui/run_ui.gd`; verificar continuar, aceptar, reiniciar y volver al menú.

## 3. Máquinas

- [x] 3.1 Cablear `game/scenes/ui/machine_panel/machine_panel.gd`: abrir/cerrar, reparar y mejorar; verificar que `GameSim.start_repair()`/`apply_upgrade()` en `false` suenan a denegación y no a éxito.
- [x] 3.2 Cablear `game/content/machines/hydroponics/panel/hydroponics_panel.gd`: sembrar, recoger y quitar (incluido el menú de celda madura) con el `bool` de la estación; verificar que una máquina rota deniega y que el refresco por tick no suena.

## 4. HUD y alertas

- [x] 4.1 Añadir clic/selección/drag en `game/scenes/ui/hud.gd`; verificar hotbar con teclado, rueda, clic y drop.
- [x] 4.2 Añadir el aviso de radiación en `game/scenes/ui/hud.gd` usando `radiation_threshold_cap` de la economía; verificar que suena una vez al cruzar el umbral y se resetea con `game_reset`.
- [x] 4.3 Añadir clic de pausa/velocidad en `game/scenes/ui/hud.gd`; verificar que no hay doble sonido al pulsar botones y teclas.

## 5. Hechos del run

- [x] 5.1 Conectar `EventLog.fact_logged` en `game/scenes/ui/run_ui.gd`; verificar que `REPORT_SENT` suena a informe y `EVENT_STARTED` a evento, una vez por hecho.

## 6. Integración y QA

- [x] 6.1 Pasar `check-gdscript.ps1 -p game --strict` sobre los scripts tocados; verificar 0 errores de parseo y 0 avisos de estilo.
- [x] 6.2 Arrancar `game/scenes/welcome/welcome.tscn` y `game/scenes/base/base.tscn` con `godot --headless --quit-after 60`; verificar que no hay `ERROR`/`SCRIPT ERROR`.
- [x] 6.3 Probar la escena de audición local con los 12 sonidos, el mute con `M` y el solapamiento de alarma + clic; verificar que no se cortan.

## Workflow follow-up

- Ejecutar `openspec validate add-audio-feedback --strict` y archivarlo con `openspec archive add-audio-feedback --yes` antes del commit.
- Commit en la rama `audio`; no tocar `main` ni `features`.
