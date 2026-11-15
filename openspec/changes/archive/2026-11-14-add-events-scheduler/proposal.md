# Proposal

## Why

El registro de eventos ya existe como contrato de datos, pero el tick todavía no
lo consume: las cinco filas no afectan a la partida, no emiten hechos y no hay
cola, solape ni efectos. El diseño formal
`docs/designs/junior-astronauta-outpost-lunar.md` pide cinco arquetipos con
ventanas, intensidad, retraso y efectos observables. Sin scheduler, el contrato
de datos queda aislado y la consola, el HUD y el balance no tienen nada que
accionar.

Esta entrega completa el comportamiento que falta y lo especifica. El cambio
anterior (`add-events-data`) dejó el scheduler explícitamente fuera de alcance.

## What Changes

- **Scheduler determinista en el tick**: expira eventos activos, encola los que
  vencen, arranca los que pueden solaparse y aplica la intensidad de la ventana.
- **Ciclo de vida observable**: hechos `EVENT_STARTED` y `EVENT_ENDED` con el id
  del evento y el tick real de inicio o fin. La avería que cruza a salud cero
  mantiene su hecho `MACHINE_BREAKDOWN`.
- **Cola y solape**: se respeta la política de solape con consentimiento mutuo
  ya definida en los datos. Un evento bloqueado espera al final de la ventana
  activa más un retraso determinista derivado de la semilla de la partida y del
  id del evento, sin RNG global.
- **Efectos por arquetipo**: avería de máquina, caída de producción y pico de
  consumo como resta neta del recurso objetivo, ventana de radiación solo en el
  exterior y corte de comunicaciones como flag sin efecto numérico.
- **Integración**: `GameSim` carga el registro y lo pasa al tick; un registro
  ausente o inválido deja la partida sin eventos y no impide arrancar.
- **Reinicio**: una partida nueva limpia eventos activos, cola, cursor, flag de
  comunicaciones y semilla.
- **Validación y documentación**: se cierra la comprobación de que la ventana
  termina dentro de los 300 ticks de misión, se actualiza el README y se añade
  un checker de runtime.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `events`: añade el comportamiento del scheduler (ciclo de vida, cola, solape,
  retraso, efectos, modo degradado y reinicio) sobre el contrato de datos ya
  existente.

## Impact

- **Código**: `game/scripts/simulation/sim_tick.gd`, `sim_state.gd`,
  `active_event.gd`, `pending_event.gd`, `log_entry.gd` y
  `game/scripts/autoloads/game_sim.gd`.
- **Datos**: se mantienen las cinco filas existentes; no cambian valores,
  tuning ni procedencia (`real_data: false`).
- **Pruebas**: `game/scripts/dev/events_check.gd` y
  `game/scripts/dev/events_runtime_check.gd`.
- **Docs**: `game/resources/events/README.md`.
- **Sin impacto** en escenas, arte, audio, UI ni export.

## Fuera de alcance

- Banner de evento, tarjeta de fuente, consola de comunicaciones y cualquier UI.
- Bloqueo real del envío de informes durante un corte de comunicaciones.
- Datos NASA reales, tuning de balance y presets de demo.
- Persistencia o replay del estado de eventos entre sesiones.
- Arquetipos nuevos fuera de los cinco ya definidos.
