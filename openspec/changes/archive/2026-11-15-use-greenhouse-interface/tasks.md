# Tasks

## 1. Interfaz de invernadero en partida

- [x] 1.1 Añadir `bind_station(station)` a `growth_interface.gd`: estado de la estación, sin ticks propios, acciones vía estación, señal `closed`.
- [x] 1.2 Traducir al inglés los textos de la interfaz (contadores, acciones, avisos).
- [x] 1.3 Ocultar el botón de demo en modo enganchado y añadir la acción de volver.
- [x] 1.4 Crear el envoltorio `panel/growth_panel.tscn` + `growth_panel.gd` (Control full-rect, `setup(station)`, `closed`, cierre con `ui_cancel`).
- [x] 1.5 Apuntar `extra_panel_scene` de `hydroponics_station.tscn` al envoltorio nuevo.
- [x] 1.6 Eliminar la rejilla antigua `panel/hydroponics_panel.*`.

## 2. Verificación

- [x] 2.1 `check-gdscript.sh -p game --strict` sin errores.
- [x] 2.2 `sim_smoke`, `machines_smoke`, `events_check`, `events_runtime_check` verdes.
- [x] 2.3 Arranque headless sin errores.
- [x] 2.4 Smoke de integración: abrir desde el panel de máquina, sembrar, cosechar, retirar, volver; estado real y contadores.
- [x] 2.5 Capturas a 850×480 y 1280×720 con la interfaz abierta.
- [x] 2.6 `openspec validate --specs --strict` y archivar el cambio.
