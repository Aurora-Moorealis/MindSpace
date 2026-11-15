# Tasks

## 1. Alcance documentado y datos de misión

- [x] 1.1 Escribir `docs/future/report-victory.md` con el aplazamiento de la victoria por 3 informes (consola de comunicaciones y POIs) y un enlace a `docs/designs/junior-astronauta-outpost-lunar.md` y a este cambio. Verificar que el archivo existe, está en español y no promete contenido ya implementado.
- [x] 1.2 Crear `game/databases/economy_rows/mission_length_ticks.tres` (id `mission_length_ticks`, valor 300, rango 1–1000, unidad `ticks`, procedencia simulada), registrarlo en `game/databases/economy.tres` y añadir a `game/scripts/dev/sim_smoke.gd` una aserción de que la economía real devuelve 300. Ejecutar `godot --headless --path game --script res://scripts/dev/sim_smoke.gd` y exigir exit 0.
- [x] 1.3 Añadir en `game/scripts/simulation/sim_state.gd` el enum `RunResult`, el campo `run_result`, `mission_length_ticks` leído de la economía con fallback 300 y `get_mission_ticks_left()`; reiniciar resultado y contador en `reset_from_economy()`. Ampliar `game/scripts/dev/sim_smoke.gd` con: partida nueva en `IN_PROGRESS`, 300 ticks restantes, avance manual del tick y reinicio que restaura ambos. Ejecutar `sim_smoke` y exigir 0 fallos.

## 2. Desenlace del tick

- [x] 2.1 Modificar `game/scripts/simulation/sim_tick.gd`: marcar `DEFEAT` en `_apply_death()`, añadir `result` al payload de `GAME_OVER` y crear `_apply_mission_end()` después de la muerte y antes de los hechos de sol, con victoria al alcanzar la duración de misión. Ejecutar `sim_smoke` y comprobar que el run de 300 ticks termina con `game_over` y sin errores de compilación.
- [x] 2.2 Ampliar `game/scripts/dev/sim_smoke.gd` con los casos de victoria a los 300 ticks, derrota por muerte antes del final, muerte en el último tick que gana la prioridad y un único hecho `GAME_OVER` con `result` correcto. Ejecutar `sim_smoke` y exigir 0 fallos.
- [x] 2.3 Ajustar `game/scripts/autoloads/game_sim.gd` para que `force_end_run()` marque `DEFEAT` y escriba `result` en el payload de `GAME_OVER`. Verificar con `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict` y una partida de prueba que el control de fin de depuración sigue abriendo la evaluación sin mostrar victoria.

## 3. Indicador del objetivo en el HUD

- [x] 3.1 Añadir `UiText.mission_objective_label(total: int, remaining: int)` en `game/scripts/ui/ui_text.gd` con el texto de objetivo y horas restantes. Verificar con el checker que el archivo compila y que no se reutilizan literales fuera de `UiText`.
- [x] 3.2 Añadir `ObjectiveLabel` bajo la barra de vida en `game/scenes/ui/hud.tscn` (centrado, fuente 8, outline de 1 px, sin panel) y rellenarlo desde `_refresh_stats()` en `game/scenes/ui/hud.gd`. Verificar con `check-gdscript.sh` y con una captura de la escena jugable a 850×480 que el texto no tapa la barra, los recursos ni el reloj.
- [x] 3.3 Comprobar en la captura de 3.2 que al arrancar la partida el indicador muestra la duración completa (300 h) y que tras un tick baja a 299 h. Verificar también que el indicador desaparece al terminar la partida, junto con el HUD.

## 4. Resultado en la evaluación

- [x] 4.1 Añadir `UiText.result_label(result: SimState.RunResult)` con los textos de victoria y derrota, y reconocer la causa `mission_complete` en `UiText.end_cause_label()` dentro de `game/scripts/ui/ui_text.gd`. Verificar con el checker y una llamada de prueba que los tres resultados devuelven textos distintos.
- [x] 4.2 Añadir `ResultLabel` entre el título y los contadores en `game/scenes/evaluation/evaluation.tscn` y rellenarlo desde `game/scenes/evaluation/evaluation.gd` con el `run_result` congelado. Verificar con `check-gdscript.sh` y abriendo la escena en una partida de prueba.
- [x] 4.3 Verificar los dos desenlaces con una escena temporal en `game/tests/` (ignorada por git): un run forzado a derrota y un run con el tick puesto a 299 que avanza un tick. Comprobar que la evaluación muestra el resultado correcto y la causa correcta; borrar la escena temporal al terminar.

## 5. Integración y cierre

- [x] 5.1 Ejecutar `sim_smoke`, `machines_smoke`, `events_check` y `events_runtime_check`; exigir exit 0 en los cuatro. Ejecutar `check-gdscript.sh -p game --strict` y el arranque `godot --headless --path game --quit` sin `ERROR` ni `SCRIPT ERROR`.
- [x] 5.2 Recorrer una partida completa de prueba: arranque, HUD con objetivo, avance de ticks, final forzado y evaluación de derrota; después, un run temporal que llegue al tick 300 y evaluación de victoria. Comprobar que el reloj queda pausado y la partida congelada en ambos finales.
- [x] 5.3 Ejecutar `openspec validate add-mission-victory --strict` y revisar `git status` para confirmar que no se cuela `game/tests/`, `.godot/` ni archivos temporales.

## Workflow follow-up

- Archivar el cambio con `openspec archive add-mission-victory --yes` en el commit que cierre el trabajo.
- Abrir el Pull Request de la rama `win-condition` contra `features` cuando la revisión esté aprobada.
