# Design

## Context

Ver `proposal.md` para la motivación y `specs/simulation-core/spec.md` + `specs/event-ledger/spec.md` para el contrato de comportamiento. El repositorio todavía no tiene código de juego y `game/project.godot` solo registra el addon de MCP. El diseño de referencia es `docs/designs/junior-astronauta-outpost-lunar.md`.

Restricciones que condicionan esta implementación:

- GDScript 4.7 con tipado explícito en todas las variables, parámetros, retornos, constantes, arrays y diccionarios; prohibido `:=`.
- El núcleo debe ejecutarse sin escenas, sin UI y sin editor para poder verificarlo en headless.
- 1 tick = 1 hora de juego y 300 ticks por partida; a ×1 son 60 s reales por tick. El harness no puede esperar tiempo real.
- Nada de aleatoriedad, HTTP ni persistencia en disco.
- Los números de gameplay son datos (`economy.tres`), no constantes de código.

## Goals / Non-Goals

**Goals:**

- Un núcleo puro y determinista que pueda ejecutar cientos de ticks en un frame y producir siempre el mismo resultado.
- Separar el estado de simulación del autoload que lo orquesta, para que el test headless no dependa del árbol de escenas.
- Dejar puntos de extensión claros para eventos, submisiones y máquinas interactuables sin reescribir el pipeline.
- Un ledger que desde el primer tick alimente la evaluación sin trabajo de backfill.

**Non-Goals:**

- Scheduler de eventos y `events.tres`.
- Submisiones y su evaluación.
- Escenas, mapa, astronauta, interacción con máquinas, HUD y arte.
- Presets de demo y captura de estado.
- `DataAudit`, valores NASA reales y tuning de balance.
- Persistencia: reiniciar es empezar de cero.

## Decisions

### 1. Núcleo puro separado del autoload

**Decisión:** tres piezas con responsabilidades distintas:

| Pieza | Tipo | Responsabilidad |
| --- | --- | --- |
| `SimState` | `RefCounted` con `class_name` | Estado mutable de una partida: tick, recursos, salud, radiación, hambre/sed, reserva de traje, máquinas, fase día/noche, fin de partida. |
| `SimTick` | clase con métodos estáticos | Función de paso: recibe `SimState` + `EconomyData` y muta el estado aplicando el pipeline. Devuelve los `LogEntry` generados. No conoce autoloads ni escenas. |
| `GameSim` | autoload | Dueño de la instancia de `SimState`, acumulador de tiempo real, multiplicador, pausa, carga de la economía, reenvío de hechos a `EventLog` y señales para la UI. |

**Por qué:** el autoload es un singleton difícil de instanciar en un test `--script`; el paso puro se puede ejecutar 300 veces sin árbol de escenas ni reloj real. Además, obliga a que las reglas no lean `Input`, `Time` ni nodos.

**Alternativa descartada:** meter todo en `GameSim`. Menos archivos, pero el test headless tendría que simular el ciclo de vida del autoload y el núcleo quedaría acoplado a señales y al árbol.

### 2. Reloj por acumulador, nunca `Engine.time_scale`

**Decisión:** `GameSim._process(delta)` acumula `delta * multiplicador` y ejecuta un tick cada 60 s acumulados. ×1 → 60 s; ×5 → 12 s; ×10 → 6 s. La pausa deja de acumular. Se limita el número de ticks ejecutados por frame (por ejemplo, 10) para evitar una espiral si el frame se congela.

Para pruebas y depuración existe `advance_ticks(count: int)`, que ejecuta ticks sin esperar tiempo real. Es la vía que usa el harness.

**Por qué:** `Engine.time_scale` aceleraría también animaciones y UI, y el diseño lo prohíbe explícitamente. El acumulador permite cambiar la tasa sin tocar el paso de simulación.

### 3. Estado tipado, sin diccionarios anidados

`SimState` expone campos explícitos y diccionarios planos:

- `tick: int`, `phase: DayPhase`, `game_over: bool`, `death_cause: StringName`.
- Recursos en `Dictionary[StringName, float]` con claves `&"oxygen"`, `&"water"`, `&"food"`, `&"energy"`. Las capacidades se leen de `EconomyData`, no se duplican en el estado.
- `health: float`, `max_health: float`, `radiation_dose: float` (0–100), `hunger: float` (0–100), `thirst: float` (0–100), `suit_reserve_ticks: int`.
- `is_outside: bool`: lo pondrá el airlock en un cambio posterior; por defecto `false`.
- `machines: Dictionary[StringName, MachineState]` con las 8 máquinas del diseño.
- `blackout_active: bool` para no repetir el hecho de apagón cada tick.

GDScript 4.7 no soporta genéricos anidados (`Dictionary[StringName, Array[int]]`), así que las estructuras complejas son clases (`MachineState`, `LogEntry`, `EvaluationSummary`) y los diccionarios solo guardan valores planos.

### 4. Economía como filas con procedencia

`DataProvenance` (`Resource`) centraliza `source`, `source_url`, `date_archived`, `archived`, `real_data`. `EconomyRow` añade `id: StringName`, `value: float`, `min_value`, `max_value` y `unit`. `EconomyData` contiene `Array[EconomyRow]` y ofrece:

- `get_value(id: StringName, fallback: float) -> float`
- `get_provenance(id: StringName) -> DataProvenance`
- `validate_rows() -> Array[String]` con ids duplicados, rangos invertidos y `real_data: true` sin fuente.

`GameSim` carga `res://databases/economy.tres` al arrancar, valida y clampa. Si el archivo falta o una fila no existe, usa el fallback y emite `push_warning` en builds de desarrollo; nunca rompe el arranque.

**Layout de datos (una fila, un archivo):** cada `EconomyRow` vive en su propio archivo `game/databases/economy_rows/<id>.tres` (el nombre del archivo es el id) con su `DataProvenance` embebido, para editar un valor abriendo un archivo pequeño o con `grep` sobre el id. `game/databases/economy.tres` queda como **índice** delgado: un `Array[EconomyRow]` de referencias `ExtResource` a esas filas, sin sub-resources de filas. Se mantiene el índice (en vez de escanear la carpeta al arrancar) porque el export solo incluye recursos referenciados y porque el orden de carga queda determinista. Añadir una fila = crear su `.tres` y registrarla en el índice; borrarla = quitar la referencia y borrar el archivo. El split no cambia la API ni el punto de carga: consumidores y tests siguen leyendo solo `res://databases/economy.tres`. El generador es idempotente: si el archivo de la fila existe, lo carga, actualiza valores y conserva su `uid`.

Convención de ids para máquinas: `machine_<id>_initial_health` y `machine_<id>_degradation_per_tick`. El prefijo `machine_` permite validar el conjunto sin clases nuevas. Las 8 máquinas se inicializan con el id en minúsculas (`lights`, `hydroponics`, `water_recycler`, `o2_system`, `solar_array`, `comms_console`, `repair_bench`, `storm_shelter`).

**Por qué no campos fijos en `EconomyData`:** el diseño exige procedencia por constante y edición por no-programadores; una fila por número permite citar cada valor y añadir filas sin tocar el schema. `@export_range` se usa en `value` con un rango amplio y los límites semánticos viven en `min_value`/`max_value`, que el core aplica.

### 5. Pipeline del tick

Orden fijo, implementado como métodos privados de `SimTick` para que el orden sea legible en un solo sitio:

```text
step(state, economy) -> Array[LogEntry]:
  1. _produce(state, economy)
  2. _consume(state, economy)
  3. _degrade_machines(state, economy)
  4. _apply_events(state, economy)      # no-op en este cambio
  5. _apply_consequences(state, economy)
  6. _update_submissions(state, economy) # no-op en este cambio
  7. _emit_facts(state, economy)
  state.tick += 1
```

Detalles de las etapas implementadas:

- **Producción:** de día el panel solar carga energía; la hidropónica encendida produce comida y O₂; el reciclador encendido produce agua. Todo se suma y se clampa a capacidad.
- **Consumo:** O₂, agua y comida por tick; energía de cada máquina encendida. Si la energía no cubre la demanda, el stock queda en 0; la escalera de apagado se resuelve en consecuencias.
- **Degradación:** cada máquina pierde salud según su fila, con suelo 0. Una máquina a 0 queda averiada y apagada.
- **Consecuencias:** ver decisiones 6 y 7.
- **Hechos:** solo hitos, no ruido por tick: sol completado, pico de radiación, apagón, avería, muerte y fin de partida. El consumo no genera una entrada por tick.

### 6. Escalera de apagado

Cuando la energía llega a 0 al final del tick, se apaga **una máquina por tick** en el orden fijo `lights → hydroponics → water_recycler → o2_system`, saltando las que ya estén apagadas. `blackout_active` evita registrar el apagón más de una vez.

**Por qué una por tick:** da al jugador una ventana de reacción (y al diseño un trade-off visible) en lugar de apagar todo de golpe. El número de pasos por tick es una fila de economía (`blackout_steps_per_tick`, default 1) para poder tunearlo sin tocar el núcleo. Si una máquina se apaga, deja de consumir y de producir en los ticks siguientes.

**Alternativa descartada:** repartir energía proporcionalmente entre máquinas. Difumina la decisión y hace imposible verificar el orden fijo.

### 7. Escalera vital y radiación

- **O₂:** si el recurso está a 0, se descuenta 1 tick de `suit_reserve_ticks`. Al llegar a 0, la salud recibe `hypoxia_damage_per_tick`.
- **Hambre y sed:** bajan por tick; al llegar a 0, la salud recibe `starvation_damage_per_tick` o `dehydration_damage_per_tick`.
- **Radiación:** `is_outside == false` no suma dosis; `true` suma `radiation_per_tick_exterior`. La dosis nunca decrece. Por encima de 30, `max_health` baja al 30% de la salud base y se aplica daño por tick; al 100, muerte.
- **Muerte:** salud ≤ 0 o dosis ≥ 100. Se marca `game_over` y se emiten `DEATH` y `GAME_OVER` una sola vez; los ticks posteriores son no-op.

La muerte por radiación y la muerte por salud comparten el mismo cierre, pero el payload de `DEATH` incluye `cause` (`hypoxia`, `starvation`, `dehydration`, `radiation`, `health`) para la pantalla de evaluación.

### 8. EventLog como ledger de datos puros

- `LogEntry` (`RefCounted`) tiene `type: LogEntry.Type`, `tick: int` y `payload: Dictionary[StringName, Variant]`.
- El enum `LogEntry.Type` es el catálogo único: `REPAIR`, `UPGRADE`, `REPORT_SENT`, `RADIATION_PEAK`, `SHELTER_USED`, `SUBMISSION_COMPLETED`, `MACHINE_BREAKDOWN`, `BLACKOUT`, `SOL_COMPLETED`, `DEATH`, `GAME_OVER`.
- `EventLog` guarda `Array[LogEntry]`, valida que el payload sea plano (rechaza `Object`/`Callable`) y expone `log_entry`, `log_entries`, `get_entries`, `get_entries_by_type`, `get_count`, `get_summary` y `reset`.
- `get_entries()` devuelve `duplicate()` del array; las entradas se tratan como inmutables por convención y no se exponen setters públicos.
- `get_summary()` reconstruye un `EvaluationSummary` recorriendo el ledger; con 300 ticks es barato y evita contadores duplicados que se desincronicen.

**Por qué un `LogEntry` y no un `Dictionary` suelto:** el tipado del enum y del tick evita strings mágicos; el payload sigue siendo plano para render y depuración.

### 9. Autoloads y orden

En `project.godot`:

```ini
EventLog="*res://scripts/autoloads/event_log.gd"
GameSim="*res://scripts/autoloads/game_sim.gd"
```

`EventLog` va primero para que `GameSim` pueda llamar a `EventLog.reset()` al iniciar o reiniciar una partida. `GameSim` no depende de `GameState` (no existe en este cambio): la fase de partida queda fuera hasta el cambio de `GameState`.

### 10. Verificación headless

El harness `game/scripts/dev/sim_smoke.gd` se ejecuta con:

```bash
godot --headless --path game --script scripts/dev/sim_smoke.gd
```

Carga `economy.tres`, construye un `SimState` inicial y comprueba:

1. 300 ticks a ×1 (llamando a `advance_ticks`, sin esperar) terminan sin error y con valores finitos.
2. Dos ejecuciones desde el mismo estado producen los mismos recursos, salud, máquinas y tipos de hechos.
3. Bajar el O₂ a 0 consume la reserva y termina en muerte con `cause: hypoxia`.
4. Un apagón apaga las máquinas en el orden fijo.
5. La dosis sube en exterior, no baja al volver al interior y dispara muerte al 100.
6. `EventLog.get_summary()` coincide con los hechos registrados.

El checker obligatorio sigue siendo:

```bash
bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict
```

Las pruebas ad-hoc pueden vivir en `game/tests/` (ignorada por Git); el harness de humo se commitea porque es la verificación repetible del módulo.

### 11. Rama y migración

El trabajo va en la rama de módulo `sim-core`, creada desde `features` actualizado, y se integra por Pull Request. No toca escenas ni archivos de otros módulos. Rollback = revertir el commit del módulo; al no haber persistencia ni migración de datos, no hay estado que reparar.

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| El estado global del autoload se filtra entre pruebas | El núcleo puro se instancia por prueba; `GameSim.reset_game()` reinicia estado y ledger. |
| Determinismo de floats distinto entre Windows y HTML5 | No hay aleatoriedad ni tiempo real dentro del paso; la comparación exacta se hace en la misma plataforma y el harness usa epsilon cuando compara floats. |
| La economía placeholder produce un arranque inviable | El harness detecta muerte prematura y valores no finitos; los números se ajustan en `economy.tres`, no en código. |
| Apagar una máquina por tick puede ser demasiado lento o rápido | `blackout_steps_per_tick` es una fila de economía; el valor se tunea sin tocar el núcleo. |
| `Dictionary[StringName, Variant]` y clases `RefCounted` se mutan por referencia | Las entradas se tratan como inmutables; `get_entries()` devuelve una copia superficial y los consumidores no reciben setters. |
| El harness commiteado se exporta al build | Es un script de desarrollo sin `_ready`; se excluye del export en el cambio de build o se mueve a `tests/` si molesta. |

## Open Questions

- Si las luces tendrán un efecto mecánico (visibilidad, estado de ánimo) se decide al implementar las máquinas. Este cambio solo las modela como carga de energía y entrada de la escalera de apagado.
