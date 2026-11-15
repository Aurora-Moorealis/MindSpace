# Tasks

## 1. Preparación del módulo

- [x] 1.1 Crear la rama `machines` desde `features` actualizado y verificar la rama. (Hecho por agente git: `git switch -c machines` desde `features`; ambas apuntan a `b440f43`; sin commit ni push; el trabajo pendiente del árbol quedó intacto.)
- [x] 1.2 Crear las carpetas `game/resources/machines/` y `game/content/machines/<id>/` para los ocho ids (`lights`, `hydroponics`, `water_recycler`, `o2_system`, `solar_array`, `comms_console`, `repair_bench`, `storm_shelter`) y verificar que existen con `find game -maxdepth 4 -type d -name machines -o -name <id>`. No tocar `game/content/rocks.png`, `game/content/map/props/`, `art/` ni los cambios pendientes del árbol. (Hecho por build-schema: 8 carpetas de máquina + `game/resources/machines/`; árbol ajeno intacto.)

## 2. Schema de máquinas y jugador

- [x] 2.1 Implementar `game/resources/machines/machine_consumption.gd` (`class_name MachineConsumption`, `extends Resource`) con `resource: StringName` (energía, O₂, agua o comida) y `amount_per_tick` con `@export_range`; añadir `validate() -> Array[String]`. Verificar con `check-gdscript.sh -p game --strict`. (Checker `checked=31 parse_errors=0 style_issues=0`; `machines_check` exit 0.)
- [x] 2.2 Implementar `game/resources/machines/upgrade_data.gd` (`class_name UpgradeData`) con `id`, `effect_stat` (enum de estadísticas de máquina y de jugador), `delta` con `@export_range`, `energy_cost` y `flavor_key`; añadir `validate()`. Verificar con el checker. (Idem; enum de 10 stats.)
- [x] 2.3 Implementar `game/resources/machines/machine_data.gd` (`class_name MachineData`) con `id`, `display_name_key`, `hint_text`, `repair_ticks`, `repair_energy_cost`, `consumption: Array[MachineConsumption]`, `upgrades: Array[UpgradeData]`, `get_upgrade()` y `validate()`. Verificar con el checker. (Idem; `validate()` vacío en las 8 fichas.)
- [x] 2.4 Implementar `game/resources/machines/machine_database.gd` (`class_name MachineDatabase`) con `machines: Array[MachineData]`, `get_machine(id)` y `validate()`. Verificar con el checker. (Idem; `machines_check` devuelve las 8 fichas.)
- [x] 2.5 Implementar `game/scripts/simulation/player_stats.gd` (`class_name PlayerStats`, `extends RefCounted`) con `repair_speed_multiplier`, `move_speed_multiplier`, `max_hunger`, `max_thirst` y `reset_from_economy(economy)` con clamps; verificar con el checker. (Idem; 4 campos y reset con clamps.)

## 3. Datos

- [x] 3.1 Crear las ocho filas `game/content/machines/<id>/<id>.tres` con `id` igual al nombre de la carpeta, `display_name_key` igual al id, `hint_text` vacío, `repair_ticks = 1`, `repair_energy_cost = 1.0`, `consumption` con una entrada de energía igual al valor actual de `power_<id>_per_tick` (lights 0.2, hydroponics 0.4, water_recycler 0.4, o2_system 0.5, comms_console 0.2, repair_bench 0.1, storm_shelter 0.1) o vacía en `solar_array`, y `upgrades = []`; cada fila con su `uid` propio. (8 fichas con `uid` propio; `solar_array` con `consumption=[]`; verificado por `machines_check`.)
- [x] 3.2 Crear `game/databases/machines.tres` como índice `MachineDatabase` con referencias `ExtResource` a las ocho filas; verificar que `get_machine()` devuelve las ocho y que `validate()` no reporta errores. (Índice con 8 refs en orden `MACHINE_IDS`; `validate()` vacío.)
- [x] 3.3 Migrar la economía: eliminar de `game/databases/economy.tres` las 8 referencias `power_<id>_per_tick` y borrar sus 8 archivos en `game/databases/economy_rows/`; añadir 4 filas nuevas (`player_repair_speed_multiplier` 1.0, `player_move_speed_multiplier` 1.0, `player_max_hunger` 100.0, `player_max_thirst` 100.0) con su `DataProvenance` embebida. El índice queda en 52 referencias externas, sin sub-resources de fila. Regenerar de forma idempotente conservando `uid`. Verificar con `economy_check` y `validate_rows()` vacío. (Índice con 52 refs, 0 sub-resources, 0 `power_*`; `economy_check` exit 0; generador idempotente y `uid` del índice conservado.)
- [x] 3.4 Verificar que ninguna fila `power_*` sigue referenciada en el repo (`grep -r "power_.*_per_tick" game/` solo puede devolver el propio historial o tests temporales que se actualizan en 5.3). (Datos y economía sin `power_*`; solo quedan menciones en `sim_tick.gd` y `sim_smoke.gd`, que son de la ola 2.)

## 4. Estado de simulación

- [x] 4.1 Ampliar `game/scripts/simulation/machine_state.gd` con `repair_ticks_total: int`, `repair_work_done: float`, `applied_upgrades: Array[StringName]`, `power_delta: float`, `degradation_delta: float`, `output_deltas: Dictionary[StringName, float]` e `is_repairing() -> bool`; verificar con el checker. (Checker `checked=31 parse_errors=0 style_issues=0`; `machines_sim_check` 109 checks exit 0.)
- [x] 4.2 Ampliar `game/scripts/simulation/sim_state.gd` con `player: PlayerStats = PlayerStats.new()`, inicializarlo en `reset_from_economy()`, clampear hambre/sed iniciales a `player.max_hunger`/`max_thirst` y limpiar en cada máquina la reparación, las mejoras y los deltas. Verificar con el checker y con un script headless temporal en `game/tests/` (ignorado por Git). (Reset con `PlayerStats` base y clamp probados en `machines_sim_check`; 31 archivos limpios.)

## 5. Tick

- [x] 5.1 Cambiar `game/scripts/simulation/sim_tick.gd` a `step(state: SimState, economy: EconomyData, machines: MachineDatabase) -> Array[LogEntry]`; actualizar el orden del pipeline y añadir `_apply_machine_jobs()` entre degradación y eventos. (Firma de 3 args y etapa `_apply_machine_work`; `sim_smoke` 88 checks exit 0.)
- [x] 5.2 Implementar el consumo por máquina: por cada máquina operativa, recorrer su lista `consumption` y restar cada `amount_per_tick` de su recurso; si el recurso es energía, sumar `machine.power_delta` antes de restar. Clamp a cero. Eliminar la lectura de `power_<id>_per_tick`. (Consumo de energía y recurso sintético probado en `machines_sim_check`; sin referencias `power_*` en `game/scripts/simulation/**`.)
- [x] 5.3 Implementar el trabajo de reparación: en cada tick, `repair_work_done += state.player.repair_speed_multiplier` para las máquinas en reparación; al alcanzar `repair_ticks_total`, restaurar salud y encendido, limpiar el trabajo y emitir `REPAIR` una sola vez. (Reparación x1 en 2 ticks y x2 en 1; `REPAIR` único verificado.)
- [x] 5.4 Mantener los valores efectivos de producción y degradación (`fila base + delta`) y actualizar `game/scripts/dev/sim_smoke.gd` a la nueva firma y a la ausencia de filas `power_*`, sin reescribir sus comprobaciones existentes. (Producción/degradación con deltas probadas; `sim_smoke` adaptado y 88 checks OK.)

## 6. API de máquinas en GameSim

- [x] 6.1 Cargar `res://databases/machines.tres` en `game/scripts/autoloads/game_sim.gd` y validar el registro (ids duplicados/desconocidos, filas inválidas, cobertura de los ocho ids) con `push_warning` sin romper el arranque; exponer `get_machine_data()` y `get_machine_state()`, y pasar `_machines` a `SimTick.step`. (Carga/validación/cobertura implementadas; boot headless sin avisos.)
- [x] 6.2 Implementar `can_start_repair()`, `start_repair()`, `is_repairing()` y `repair_progress()`: cobrar energía al iniciar, fijar `repair_ticks_total = maxi(1, data.repair_ticks)`, `repair_work_done = 0.0` y calcular el progreso como `done / total`; rechazar máquina sana/en reparación/sin energía. (`machines_api_check` 95 checks: coste 5→4, progreso 1/3 y 2/3, rechazos sin coste.)
- [x] 6.3 Implementar `can_apply_upgrade()` y `apply_upgrade()`: validar mejora existente, no repetida, máquina no averiada y energía suficiente; cobrar, aplicar el delta a la estadística de máquina o de jugador correspondiente y emitir `UPGRADE` con `{&"machine", &"upgrade"}`. (`machines_api_check`: deltas de máquina y jugador, `UPGRADE` por aplicación, rechazos sin coste.)

## 7. Verificación

- [x] 7.1 Crear `game/scripts/dev/machines_smoke.gd` con: carga y validación del registro; consumo declarado (energía y un recurso sintético) y máquina sin consumos; reparación completa (divisiones, coste, hecho único); velocidad de reparación del jugador; rechazos (sana, en curso, sin energía); mejoras sintéticas de máquina y de jugador; reinicio. Ejecutarlo con `godot --headless --path game --script scripts/dev/machines_smoke.gd` y exigir exit 0. (Harness de 288 checks: `288 checks, 0 failures, OK`; exit 0.)
- [x] 7.2 Ejecutar `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict` y corregir todos los errores y warnings de tipado. (`checked=32 parse_errors=0 style_issues=0`.)
- [x] 7.3 Ejecutar `godot --headless --path game --quit` y verificar que no aparecen `ERROR` ni `SCRIPT ERROR` de los scripts del módulo. (0 `ERROR`/`SCRIPT ERROR`.)
- [x] 7.4 Ejecutar `godot --headless --path game --script scripts/dev/sim_smoke.gd` como regresión y confirmar que el núcleo existente sigue pasando con la nueva firma. (`sim_smoke: 88 checks, OK`; exit 0.)

## 8. Cierre

- [ ] 8.1 Revisar `git status` y `git diff` y verificar que solo cambian archivos del módulo; no commitear `game/tests/` ni los cambios pendientes ajenos (`game/content/rocks.png`, `game/content/map/props/`, `art/`).
- [x] 8.2 Ejecutar `openspec validate add-machines --strict` y corregir lo que reporte. (`Change 'add-machines' is valid`.)
- [ ] 8.3 Actualizar este `tasks.md` con la evidencia de cada tarea y abrir Pull Request de `machines` hacia `features`; archivar el cambio tras la integración. (Pendiente: requiere mover el trabajo sin commitear a `machines` y commit; no se hizo sin confirmación.)

## Workflow follow-up

- El contenido de las mejoras queda pendiente: las ocho filas se entregan con `upgrades = []` hasta que el autor congele el roster 8×2.
- Definir qué máquina consume cada recurso y en qué cantidad (agua en hidropónica, etc.).
- Reconciliar el id `lights` del núcleo con el `power_distributor` del diseño antes de escribir las filas de mejoras.
- La radiación (tolerancia del jugador y/o mejoras) queda para un cambio posterior.
