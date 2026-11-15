# Proposal

## Why

El diseño formal (`docs/designs/junior-astronauta-outpost-lunar.md`) define cinco arquetipos de evento data-driven, pero el núcleo actual deja la etapa de eventos como no-op y no existe un schema de filas. Sin ese contrato, el scheduler, el banner de evento y la procedencia NASA tendrían que inventar campos y reglas en cada consumidor. Esta entrega fija el contrato de datos antes de tocar `SimTick`.

## What Changes

- Nuevas clases Resource `EventRow` y `EventData` en `game/resources/events/`.
- `game/databases/events.tres` como índice y `game/databases/events_rows/*.tres` con una fila por archivo.
- Cinco filas iniciales, una por arquetipo: avería de máquina, caída de producción, pico de consumo, ventana de radiación y corte de comunicaciones.
- Reglas de target: recurso para producción/consumo, máquina para avería, pseudo-recurso `radiation` para dosis y sin target para comms.
- Deltas con signo e interpolación lineal `start → peak → end` por tick.
- Solapamiento por fila con `overlap_policy` (`EXCLUSIVE`, `WHITELIST`, `ANY`) y consentimiento mutuo mediante `overlap_with`.
- Retraso de cola con `delay_min_ticks`/`delay_max_ticks`; el scheduler futuro usará una semilla determinista derivada de la partida y del id.
- Validador headless `game/scripts/dev/events_check.gd` y documentación en `game/resources/events/README.md`.
- **No** se modifica `SimTick`, no se añaden autoloads ni escenas, y no se aplican efectos en tiempo de ejecución.

## Capabilities

### New Capabilities

- `events`: contrato de datos de los eventos de la partida, sus targets, intensidades, ventanas, solapamiento, retraso y procedencia.

### Modified Capabilities

- Ninguna. `simulation-core` mantiene la etapa de eventos como no-op; este cambio no altera su comportamiento observable.

## Impact

- **Código:** `game/resources/events/event_row.gd`, `game/resources/events/event_data.gd`, `game/scripts/dev/events_check.gd`.
- **Datos:** `game/databases/events.tres` y `game/databases/events_rows/*.tres`.
- **Dependencias:** `DataProvenance` y los identificadores de `SimState`; la rama `events` sale de `sim-core`.
- **Fuera de alcance:** scheduler, aplicación de efectos, banner/UI, datos NASA reales y tuning de valores. Las filas quedan con `real_data: false`.
