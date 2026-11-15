# Eventos

Registro de eventos data-driven y scheduler determinista del juego. Incluye las
clases `EventRow`/`EventData`, el registro `events.tres`, la validación headless
y la aplicación de eventos en `SimTick` (ventanas, cola, solape, retraso
determinista y efectos por arquetipo).

## Estructura

| Archivo | Contenido |
| --- | --- |
| `game/resources/events/event_row.gd` | `EventRow`: una fila de evento |
| `game/resources/events/event_data.gd` | `EventData`: registro, consultas y validación |
| `game/databases/events.tres` | Índice del registro |
| `game/databases/events_rows/*.tres` | Una fila por archivo |
| `game/scripts/simulation/active_event.gd` | Evento activo con su tick de inicio real |
| `game/scripts/simulation/pending_event.gd` | Evento en cola y su tick mínimo de inicio |
| `game/scripts/dev/events_check.gd` | Validador headless del registro |
| `game/scripts/dev/events_runtime_check.gd` | Validador headless del scheduler |

## Arquetipos

| Arquetipo | Target | Efecto del scheduler |
| --- | --- | --- |
| `MACHINE_BREAKDOWN` | Máquina | Delta negativo a la salud de la máquina |
| `PRODUCTION_DROP` | Recurso | Resta neta del recurso objetivo (delta negativo) |
| `CONSUMPTION_SPIKE` | Recurso | Resta neta del recurso objetivo (delta negativo) |
| `RADIATION_WINDOW` | `radiation` | Delta positivo a la dosis de radiación, solo en el exterior |
| `COMMS_BLACKOUT` | Ninguno | Solo marca `comms_blocked`; no bloquea informes |

`PRODUCTION_DROP` y `CONSUMPTION_SPIKE` apuntan a un recurso, no a una máquina.
Así la hidropónica (comida + oxígeno) no es ambigua: la fila dice exactamente
qué recurso baja.

## Campos de una fila

| Campo | Tipo | Regla |
| --- | --- | --- |
| `id` | `StringName` | Único, snake_case |
| `archetype` | enum | Uno de los cinco |
| `target_type` | enum | `MACHINE`, `RESOURCE` o `NONE` |
| `target_id` | `StringName` | Máquina, recurso o vacío según el arquetipo |
| `onset_tick` | `int` | Tick absoluto desde el inicio; `>= 0` |
| `duration_ticks` | `int` | `>= 1`; la ventana debe terminar dentro de los 300 ticks de misión |
| `intensity_start` | `float` | Delta del primer tick, con signo |
| `intensity_peak` | `float` | Delta máximo, con signo |
| `intensity_end` | `float` | Delta del último tick, con signo |
| `overlap_policy` | enum | `EXCLUSIVE`, `WHITELIST` o `ANY` |
| `overlap_with` | `Array[StringName]` | IDs permitidos si la política es `WHITELIST` |
| `delay_min_ticks` | `int` | Retraso mínimo al esperar en cola |
| `delay_max_ticks` | `int` | Retraso máximo; `>= delay_min_ticks` |
| `provenance` | `DataProvenance` | Obligatoria; `real_data: false` mientras sean placeholders |

### Intensidad

Los tres escalares se interpolan linealmente por tick:

- duración 1: se usa `intensity_peak`;
- duración 2: va de `start` a `end`, sin tick central;
- duración 3 o más: `start` en el primer tick, `peak` en `duration_ticks / 2` y
  `end` en el último.

Los deltas van **con signo**: negativo resta o daña, positivo suma. Una avería,
una caída de producción o un pico de consumo deben ser negativos; una ventana de
radiación, positiva; un corte de comunicaciones, cero.

## Solapamiento

`EventData.can_overlap(a, b)` exige **consentimiento mutuo**:

- si cualquiera de las dos filas es `EXCLUSIVE`, no se solapan;
- `ANY` significa “yo no pongo restricciones”, pero la otra fila todavía tiene
  que aceptar;
- `WHITELIST` solo acepta los IDs de `overlap_with`;
- dos `WHITELIST` se solapan solo si ambas se listan mutuamente.

El validador avisa si una lista apunta a un ID inexistente, a sí misma, a una
fila `EXCLUSIVE` o si el consentimiento es unilateral.

## Retraso en cola

Cuando un evento no puede solaparse y el anterior sigue activo, el scheduler
futuro lo dejará en cola. `delay_min_ticks`/`delay_max_ticks` definen el retraso,
que se sorteará con una semilla derivada de la partida y del `id` del evento.
Así parece aleatorio pero sigue siendo determinista y reproducible para los
presets de demo y los tests.

## Filas iniciales

| ID | Arquetipo | Target | Onset | Duración |
| --- | --- | --- | --- | --- |
| `radiation_window_01` | Ventana de radiación | `radiation` | 3 | 6 |
| `machine_breakdown_01` | Avería | `water_recycler` | 8 | 4 |
| `production_drop_01` | Caída de producción | `food` | 12 | 8 |
| `consumption_spike_01` | Pico de consumo | `water` | 16 | 4 |
| `comms_blackout_01` | Corte de comunicaciones | — | 20 | 6 |

Todas llevan `real_data: false` y valores placeholder. La primera ventana de
radiación empieza en el tick 3, como pide el diseño. El tuning y los datos NASA
reales llegan después.

## Añadir una fila

1. Crea `game/databases/events_rows/<id>.tres` copiando una fila existente.
2. Cambia el `uid` del header y el `id`; no copiar el `uid` de otra fila.
3. Añádela como `ExtResource` y al array `rows` de `game/databases/events.tres`.
4. Si usa `WHITELIST`, añade el ID recíproco a la otra fila.
5. Ejecuta el validador.

## Validar

```bash
godot --headless --path game --script res://scripts/dev/events_check.gd
```

El checker comprueba carga del registro, IDs únicos, targets, signos, ventanas,
solapamiento, interpolación y procedencia.

## Runtime y prueba visual

`GameSim` carga `events.tres` al arrancar y se lo pasa a
`SimTick.step(state, economy, machines, events)`. El scheduler vive en `SimTick`:
expira eventos, encola los que vencen, respeta el solape y el retraso
determinista, y aplica la intensidad de cada arquetipo. `GameSim` publica los
hechos `EVENT_STARTED`/`EVENT_ENDED` en `EventLog`.

Escena local de prueba (ignorada por Git):

```bash
godot --path game res://tests/events_live/live.tscn
```

Controles: `Play`/`Pause`, `×1`/`×5`/`×10`, `Step 1`, `Step 5`, `Next event`,
`Reset` y `EVA` para alternar interior/exterior. La línea temporal marca el tick
actual y el banner muestra los eventos activos con su intensidad.

Para arrancar ya avanzado:

```bash
godot --path game res://tests/events_live/live.tscn -- --ticks 9 --outside
```

Para generar una captura:

```bash
godot --path game res://tests/events_live/live.tscn -- --ticks 9 --outside --capture
```

El checker de runtime está en `game/scripts/dev/events_runtime_check.gd`:

```bash
godot --headless --path game --script res://scripts/dev/events_runtime_check.gd
```
