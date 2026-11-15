# Tasks

## 1. HUD y panel de máquina

- [x] 1.1 Guardar en `hud.gd` las banderas de partida terminada e interfaz abierta
- [x] 1.2 Exponer `set_overlay_open()` y calcular la visibilidad en un solo sitio
- [x] 1.3 Conectar `visibility_changed` del panel en `run_ui.gd`
- [x] 1.4 Ocultar con el panel el botón de depuración de fin de misión

## 2. Tamaño

- [x] 2.1 Barra de vida a 164x24 con relleno de 120x10
- [x] 2.2 Hotbar a 144x40 con espacios de 24 px y paso 26
- [x] 2.3 Iconos de objeto a 16 px y en la mano a 16 px

## 3. Verificación

- [x] 3.1 Checker estricto sin errores
- [x] 3.2 Captura de la partida con la barra y la hotbar nuevas
- [x] 3.3 Captura con el panel de reparación abierto, sin HUD detrás
- [x] 3.4 Captura tras cerrar el panel, con el HUD de vuelta
- [x] 3.5 Escena de prueba del HUD sin fallos
- [x] 3.6 `openspec validate fix-hud-panel-and-size --strict`
