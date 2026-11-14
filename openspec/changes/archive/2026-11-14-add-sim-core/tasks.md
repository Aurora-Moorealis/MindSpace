# Tasks

## 1. Preparación del módulo

- [x] 1.1 Crear la rama `sim-core` desde `features` actualizado (`git fetch && git switch features && git pull && git switch -c sim-core`) y verificar con `git branch --show-current` que devuelve `sim-core`. (Verificado por agente git: `git branch --show-current` → `sim-core`, `merge-base --is-ancestor origin/features sim-core` exit 0, hash `3bbef69`.)
- [x] 1.2 Crear las carpetas `game/scripts/simulation/`, `game/resources/common/`, `game/resources/economy/`, `game/databases/` y `game/scripts/dev/`, y verificar que existen con `find game -maxdepth 3 -type d`. (Ejecutado por build-economy: 7 carpetas confirmadas con `ls -d`; el repositorio base no tenía `game/scripts/`.)

## 2. Schema de economía

- [x] 2.1 Implementar `game/resources/common/data_provenance.gd` (`class_name DataProvenance`, `extends Resource`) con `source`, `source_url`, `date_archived`, `archived` y `real_data` tipados; verificar con `check-gdscript.sh -p game --strict`. (Checker: parse_errors=0 style_issues=0.)
- [x] 2.2 Implementar `game/resources/economy/economy_row.gd` (`class_name EconomyRow`) con `id: StringName`, `value: float` con `@export_range`, `min_value`, `max_value`, `unit` y `provenance: DataProvenance`; verificar con el checker. (Idem.)
- [x] 2.3 Implementar `game/resources/economy/economy_data.gd` (`class_name EconomyData`) con `Array[EconomyRow]`, `get_value`, `get_provenance`, `validate_rows` y clamps por `min_value`/`max_value`; verificar con el checker. (Idem.)
- [x] 2.4 Crear `game/databases/economy.tres` con las filas placeholder del diseño (stocks, capacidades, consumos, producción solar/hidropónica/reciclador, energía por máquina, radiación, hambre/sed, salud, reserva de traje, apagado y degradación de las 8 máquinas), todas con `real_data: false`, y verificar que `validate_rows()` no reporta errores al cargarlo en headless. (56 filas exactas; `res://tests/economy_check.gd` exit 0, `validate_rows()` vacío; procedencia compartida default.)
- [x] 2.5 Dividir el registro en una fila por archivo: `game/databases/economy_rows/<id>.tres` (56 archivos autocontenidos, cada uno con su `DataProvenance` embebida) y `game/databases/economy.tres` como índice de `ExtResource` sin sub-resources de filas; generación idempotente que conserva los `uid` existentes. Verificar con `godot --headless --path game --script res://tests/economy_check.gd` que el índice tiene 56 referencias externas, `rows.size()==56`, ids/valores intactos y `validate_rows()` vacío; checker `--strict` limpio.

## 3. Estado de simulación

- [x] 3.1 Implementar `game/scripts/simulation/machine_state.gd` (`class_name MachineState`) con `id`, `health`, `powered` y `upgrade_level`; verificar con el checker. (Checker limpio; API congelada.)
- [x] 3.2 Implementar `game/scripts/simulation/sim_state.gd` (`class_name SimState`) con tick, recursos, salud, radiación, hambre/sed, reserva de traje, fase día/noche, `is_outside`, máquinas, `game_over` y `death_cause`; incluir `reset_from_economy(economy)` e `is_alive()`; verificar con el checker. (Checker limpio; 15 campos y helpers del contrato.)
- [x] 3.3 Verificar que `reset_from_economy` inicializa las 8 máquinas y los recursos desde `economy.tres` con un script headless temporal en `game/tests/` (ignorado por Git) que imprima los valores y falle si hay negativos o `NaN`. (`reset_check`: exit 0, 93 asserts.)

## 4. Pipeline del tick

- [x] 4.1 Implementar `game/scripts/simulation/sim_tick.gd` (`class_name SimTick`) con `step(state, economy) -> Array[LogEntry]` y el orden fijo producción → consumos → degradación → eventos (no-op) → consecuencias → submisiones (no-op) → hechos; verificar con el checker. (Checker limpio; pipeline 1→7 con helpers privados.)
- [x] 4.2 Implementar producción y consumo de O₂, agua, comida y energía con clamps `[0, capacidad]` y orden producción-antes-que-consumo; verificar en el harness que un tick de día sube energía y un tick de consumo baja los recursos sin negativos. (Solar aislada 5→6.5 de día; consumo de 20 steps sin negativos.)
- [x] 4.3 Implementar la degradación pasiva de máquinas con suelo 0 y el estado averiado; verificar que una máquina pierde salud por tick y que a 0 deja de producir. (100→99.98; 0.01→0 con `MACHINE_BREAKDOWN` y `powered=false`.)
- [x] 4.4 Implementar la escalera vital (O₂ → reserva de traje → hipoxia; hambre/sed → daño; salud 0 → muerte única); verificar en el harness que el O₂ a 0 consume la reserva y termina en muerte con `cause: hypoxia`. (60 steps de reserva; muerte única con 1 `DEATH` + 1 `GAME_OVER`.)
- [x] 4.5 Implementar la radiación acumulativa (interior sin ganancia, exterior con ganancia, dosis irreversible, tope del 30% y muerte al 100%); verificar en el harness los cuatro casos. (Interior 0; exterior 1.2/tick; irreversible; `max_health=30` a dosis 50; muerte a 100.2 con causa `radiation`.)
- [x] 4.6 Implementar la escalera de apagado por energía (`lights → hydroponics → water_recycler → o2_system`, una máquina por tick, `blackout_steps_per_tick` desde economía); verificar que el orden observado coincide y que una máquina apagada deja de consumir y producir. (Orden exacto en 4 steps; 1 solo `BLACKOUT`; apagada no consume.)
- [x] 4.7 Implementar la emisión de hechos solo en hitos (`SOL_COMPLETED`, `RADIATION_PEAK`, `BLACKOUT`, `MACHINE_BREAKDOWN`, `DEATH`, `GAME_OVER`) y verificar que 300 ticks no generan una entrada por tick. (11 entries en 300 ticks; sin facts tras la muerte; 12 soles verificados en un run mantenido vivo.)

## 5. EventLog

- [x] 5.1 Implementar `game/scripts/simulation/log_entry.gd` (`class_name LogEntry`) con el enum `Type` del catálogo, `tick`, `payload` y validación de payload plano que rechaza `Object` y `Callable`; verificar con el checker. (Checker limpio; `payload` como `Dictionary[Variant, Variant]` por limitación de Godot 4.7.)
- [x] 5.2 Implementar `game/scripts/autoloads/event_log.gd` con `log_entry`, `log_entries`, `get_entries` (copia), `get_entries_by_type`, `get_count` y `reset`; verificar con el checker. (Checker limpio; `get_entries` corregido a copia defensiva por entrada tras fallar el caso de mutación.)
- [x] 5.3 Implementar `game/scripts/simulation/evaluation_summary.gd` (`class_name EvaluationSummary`) y `EventLog.get_summary()` con los 5 contadores; verificar que el resumen coincide con los hechos registrados en el harness. (`res://tests/ledger_check.gd`: exit 0, 83 asserts; summary exacto.)
- [x] 5.4 Conectar `GameSim` con `EventLog` para reenviar los hechos de cada tick y limpiar el ledger al reiniciar; verificar que tras `reset_game()` el ledger queda vacío y los contadores a cero. (clock_check: 24 ticks → 1 `SOL_COMPLETED`; `reset_game()` deja tick 0, ledger vacío y summary a cero.)
- [x] 5.5 Quitar `class_name EventLog` de `game/scripts/autoloads/event_log.gd` (Godot rechaza un `class_name` que colisiona con el nombre del autoload) y adaptar `game/tests/ledger_check.gd` para instanciar el script por `preload`; verificar con `ledger_check` exit 0 y checker limpio. (Hecho: instancias tipadas con `EventLogScript`; 83 asserts exit 0; checker 9 archivos limpio.)

## 6. Autoload GameSim

- [x] 6.1 Implementar `game/scripts/autoloads/game_sim.gd` con acumulador de tiempo, multiplicadores ×1/×5/×10, pausa, límite de ticks por frame y `advance_ticks(count)`; verificar con un script headless que 60 s simulados a ×1 producen 1 tick y 12 s a ×5 producen 1 tick. (clock_check 32 asserts: 59+1 s → 1 tick, ×5 12 s → 1, ×10 6 s → 1, cap 10 ticks/frame, pausa congela.)
- [x] 6.2 Cargar `res://databases/economy.tres` al arrancar, validar filas, aplicar clamps y emitir `push_warning` ante filas ausentes o inválidas sin romper el arranque; verificar con una economía temporal sin una fila. (validate_rows + clamp al cargar; fallback con `EconomyData.new()` vacía: empty_economy_check 35 asserts exit 0, sin crash y valores finitos.)
- [x] 6.3 Añadir `new_game()` y `reset_game()` (estado + tick + ledger), señales `tick_advanced(tick)` y `game_over(cause)`; verificar que una partida nueva arranca en tick 0 y que el reinicio deja el estado inicial. (clock_check: `new_game`/`reset_game` en tick 0 con ledger vacío; señal `game_over` emitida con causa `health`.)
- [x] 6.4 Registrar `EventLog` y `GameSim` en `game/project.godot` (EventLog primero) y verificar que `godot --headless --path game --quit` arranca sin `ERROR` ni `SCRIPT ERROR`. (Autoloads en orden; boot exit 1 solo por «no main scene», sin `SCRIPT ERROR`; `clock_check.tscn` arranca con los autoloads reales.)

## 7. Harness de verificación

- [x] 7.1 Crear `game/scripts/dev/sim_smoke.gd` con las seis comprobaciones del diseño (300 ticks, determinismo, muerte por O₂, orden de apagado, radiación y contadores) y ejecutarlo con `godot --headless --path game --script scripts/dev/sim_smoke.gd`; debe terminar con exit code 0. (83 checks exit 0: 300 ticks, determinismo exacto, O₂, apagado, radiación y contadores.)
- [x] 7.2 Ejecutar `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict` y corregir todos los errores y warnings de tipado. (checked=11, parse_errors=0, style_issues=0.)
- [x] 7.3 Ejecutar el boot headless del proyecto y verificar que no aparecen errores de autoload, recursos faltantes ni clases duplicadas. (Boot: solo «no main scene»; 0 `SCRIPT ERROR`/`ERROR` de `game/scripts/**`; `clock_check.tscn` con autoloads exit 0.)

## 8. Integración y cierre

- [x] 8.1 Ejecutar una partida de 300 ticks desde `new_game()` con la economía placeholder y verificar que termina sin errores, con valores finitos y sin muerte en cascada en el primer tick. (full_run_check 18 asserts exit 0: tick 300, sin muerte en el primer tick, muerte esperada en 210 por hipoxia, entries=11, economy válida.)
- [x] 8.2 Revisar `git status` y `git diff` y verificar que solo cambian archivos de este módulo (`game/scripts/`, `game/resources/`, `game/databases/economy.tres`, `game/project.godot`), sin escenas, addons ni `game/tests/`. (`project.godot` único tracked modificado, solo `[autoload]`; untracked del módulo; `game/tests/` ignorado; 0 cambios en escenas/addons/docs. Nota: `openspec/changes/add-procedural-lunar-map/` es untracked ajeno, intacto.)

## Workflow follow-up

- Abrir Pull Request de `sim-core` hacia `features` con el resumen del harness y el resultado del checker.
- Archivar el cambio en OpenSpec una vez revisado e integrado.
