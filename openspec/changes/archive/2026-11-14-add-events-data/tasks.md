# Tasks

## 1. Schema y registro

- [x] 1.1 Crear `EventRow` con los enums `Archetype`, `TargetType` y `OverlapPolicy`, los campos tipados, `end_tick()`, `is_active_at()`, `intensity_at()` y `allows_overlap_with()`. Verificado con `check-gdscript.ps1 --strict` (0 errores, 0 avisos).
- [x] 1.2 Crear `EventData` con `get_row()`, `get_provenance()`, `get_rows_by_archetype()`, `can_overlap()` y `validate_rows()`. Verificado con `events_check` y con el caso de fila inválida.
- [x] 1.3 Crear `game/databases/events.tres` como índice y cinco filas en `game/databases/events_rows/`, una por arquetipo. Verificado en `events_check`: 5 filas, IDs únicos y targets existentes.

## 2. Reglas de datos

- [x] 2.1 Validar targets y signos por arquetipo: recurso para producción/consumo, máquina para avería, `radiation` para radiación y ninguno para comms. Verificado con la fila inválida de `events_check` (target y delta incorrectos se rechazan).
- [x] 2.2 Implementar la política de solape `EXCLUSIVE`/`WHITELIST`/`ANY` con consentimiento mutuo y validación de referencias, duplicados y listas unilaterales. Verificado con los casos sintéticos de `events_check`.
- [x] 2.3 Implementar la ventana `[onset_tick, onset_tick + duration_ticks)` y la interpolación `start → peak → end`, incluidos duración 1 y duración 2. Verificado con los límites de la ventana de radiación y las muestras de intensidad.
- [x] 2.4 Validar `delay_min_ticks`/`delay_max_ticks` y dejar el corte de comunicaciones sin target y con intensidad cero. Verificado en `events_check`.

## 3. Validación y documentación

- [x] 3.1 Crear `game/scripts/dev/events_check.gd` y ejecutarlo con `godot --headless --path game --script res://scripts/dev/events_check.gd`. Resultado: 120 checks, OK, exit 0.
- [x] 3.2 Documentar el contrato, las filas iniciales, el solape, el retraso y cómo añadir filas en `game/resources/events/README.md`. Verificado leyendo el README y ejecutando su comando de validación.
- [x] 3.3 Ejecutar el checker estricto de GDScript sobre el proyecto. Resultado: `checked=14 parse_errors=0 style_issues=0`.
- [x] 3.4 Confirmar que el cambio es solo de datos: no se modifica `SimTick`, `project.godot`, autoloads ni escenas. Verificado con `git diff --name-only` y revisión del commit.

## 4. Integración

- [x] 4.1 Crear la rama `events` desde `sim-core` en un worktree fuera del repositorio. Verificado con `git branch --show-current` (`events`) y `git merge-base --is-ancestor origin/sim-core events` (exit 0).
- [x] 4.2 Dejar las cinco filas con `real_data: false` y valores placeholder, incluida la primera ventana de radiación en el tick 3. Verificado en `events_check`.

## Workflow follow-up

- Commit de la rama `events` con el schema, el registro, el checker y los artefactos de OpenSpec.
- Subir la rama y abrir PR contra `sim-core`; el push está bloqueado hasta que las credenciales de Git tengan permiso en `Aurora-Moorealis/MindSpace`.
- Archivar este cambio y sincronizar `openspec/specs/events/spec.md` después de la revisión y el merge.
- Implementar el scheduler y los efectos en `SimTick` en un cambio posterior.
