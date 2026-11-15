# Design

## Context

Ver `proposal.md` para la motivación y `specs/machines/spec.md` + `specs/simulation-core/spec.md` para el comportamiento. El diseño de referencia es `docs/designs/junior-astronauta-outpost-lunar.md` (entradas 8 y 18) y el contrato vigente del núcleo está en `.ai/composer/add-sim-core/contracts.md`.

Restricciones que condicionan la implementación:

- GDScript 4.7 con tipado explícito total; prohibido `:=`. Un `class_name` por script.
- El núcleo debe poder verificarse en headless, sin escenas ni UI.
- Los números de gameplay son datos editables; el contenido por máquina vive junto a la máquina (AGENTS.md).
- Cuatro autoloads y solo cuatro: este cambio no añade ninguno.
- No hay jugador, escena principal, airlock ni paneles: la lógica se entrega como estado + API + datos.

## Goals / Non-Goals

**Goals:**

- Separar con claridad lo que pertenece a la máquina (tiempo de reparación, consumo, producción, degradación) de lo que pertenece al jugador (velocidad de reparación, movimiento, hambre y sed máximas).
- Poder reparar cualquier máquina dañada con un coste real (energía + divisiones de trabajo) y registrar el hecho.
- Poder aplicar mejoras de un solo uso que alteren números del tick o estadísticas del jugador, sin tocar código.
- Dejar el catálogo de máquinas editable por datos y validado al arrancar.
- Verificar todo en headless y no romper el núcleo existente.

**Non-Goals:**

- Escenas, arte, paneles, interacción con el jugador y `machine_base.gd`.
- Contenido concreto de las mejoras (el roster 8×2 sigue sin definir).
- Radiación: ni tolerancia, ni mejoras, ni cambios en sus umbrales.
- Eventos, submisiones, comunicaciones, traje, refugio y presets.
- UI de strings, `DataAudit`, valores NASA y tuning.

## Decisions

### 1. Una fila por máquina + índice, igual que la economía

**Decisión:** cada `MachineData` vive en `game/content/machines/<id>/<id>.tres` (autocontenido, junto a la futura escena de esa máquina) y `game/databases/machines.tres` es un índice `MachineDatabase` con referencias externas a las ocho filas.

**Por qué:** AGENTS.md exige que la configuración usada por una sola máquina viva en `content/<tipo>/<nombre>/`; el diseño (línea 123) lo repite. El índice evita escanear carpetas al arrancar, mantiene el orden determinista y garantiza que el export incluya los recursos referenciados.

**Alternativa descartada:** un único `machines.tres` central con las ocho filas. Menos archivos, pero rompe la autocontención del contenido y concentra en un archivo compartido lo que editarán manos distintas.

### 2. Reparación: divisiones de la máquina, velocidad del jugador

**Decisión:** `MachineData.repair_ticks` es el trabajo total de la máquina, expresado en divisiones (a velocidad 1, una división por tick). `start_repair(id)` cobra la energía configurada al iniciar y deja la máquina con `repair_ticks_total = maxi(1, repair_ticks)` y `repair_work_done = 0.0`. En cada tick, `SimTick` suma `state.player.repair_speed_multiplier` al trabajo hecho; al alcanzar el total, la salud vuelve a `MachineState.MAX_HEALTH`, la máquina queda encendida y se emite un único hecho `REPAIR`. No hay cancelación ni reembolso.

**Por qué:** el tiempo de reparación es una propiedad de la máquina (cuánto trabajo requiere) y la velocidad es una estadística del jugador. Separarlas permite que una mejora del jugador acelere la barra sin cambiar el número de divisiones de la máquina. Las divisiones son la representación del progreso; no son una mecánica de skill checks en tiempo real.

**Alternativa descartada:** reparación instantánea o duración fija ignorando al jugador. La primera elimina el trade-off temporal; la segunda deja la velocidad de reparación sin consumidor.

### 3. Consumo de la máquina en su propia ficha

**Decisión:** `MachineData` declara una única lista `consumption: Array[MachineConsumption]` con pares recurso + cantidad por tick; el recurso puede ser energía, O₂, agua o comida. Una lista vacía significa que la máquina no consume. `SimTick` recibe el registro de máquinas y, por cada máquina operativa (encendida y sana), resta cada entrada; si el recurso es energía, suma `power_delta` a la cantidad. Las máquinas apagadas o averiadas no consumen. Las 8 filas `power_<id>_per_tick` se eliminan de `economy.tres`.

**Por qué:** el usuario quiere que cada máquina tenga su consumo. Una lista única permite que una máquina no consuma nada (el panel solar) sin un campo de energía a 0, y evita dos caminos para declarar el mismo dato. El registro se pasa al tick como dato inmutable; el estado no copia configuración.

**Saneo de datos (v1.1):** como el flujo del cambio es editar `.tres` a mano, el tick no confía en la ficha: ignora entradas nulas, recursos desconocidos y duplicados; un `amount_per_tick` negativo cuenta como 0; y si no hay entrada de energía, el consumo efectivo es `maxf(0.0, power_delta)`. Así un typo no regala recursos ni corrompe el estado, que es lo que exige la spec de economía.

**Alternativa descartada:** `energy_per_tick` + `extra_consumption`. Obliga a que toda máquina tenga una entrada de energía aunque no consuma y separa en dos sitios lo que es una sola lista de consumos.

**Alternativa descartada:** copiar el consumo a `MachineState` al reiniciar. Mantiene la firma del tick, pero mete configuración estática en el estado y obliga a repoblar cada partida.

### 4. Mejoras: un solo uso, coste de energía, efecto aditivo

**Decisión:** cada `UpgradeData` se aplica una vez por máquina, cuesta energía y muta un modificador del estado. Los efectos de máquina van a `power_delta`, `degradation_delta` u `output_deltas`; los efectos de jugador van a `SimState.player`. Se registra `UPGRADE` con `{machine, upgrade}`. Se rechaza si la máquina está averiada, la mejora ya está aplicada, no hay energía o la máquina no puede expresar ese efecto (por ejemplo, `SOLAR_OUTPUT` en el sistema de O₂).

**Por qué:** el estado es puro y determinista; guardar deltas en el estado (en vez de reescribir filas de datos) mantiene las fichas inmutables y el resultado reproducible.

**Alternativa descartada:** escribir el efecto en el `.tres` al aplicar la mejora. Rompe la inmutabilidad de los datos y mezcla contenido con estado de partida.

### 5. Estadísticas del jugador en `PlayerStats`, no en la máquina

**Decisión:** `PlayerStats` (RefCounted) contiene `repair_speed_multiplier`, `move_speed_multiplier`, `max_hunger` y `max_thirst`. `SimState` lo expone como `player`. Sus valores base salen de cuatro filas nuevas de economía (`player_repair_speed_multiplier`, `player_move_speed_multiplier`, `player_max_hunger`, `player_max_thirst`). Hambre y sed iniciales se clampean al máximo correspondiente.

Consumidores:

- `repair_speed_multiplier`: acelera el trabajo de reparación por tick.
- `max_hunger` / `max_thirst`: al aumentarse, el máximo y la reserva actual suben en la misma cantidad.
- `move_speed_multiplier`: almacenada; la consumirá el astronauta cuando exista.

La radiación queda fuera de este cambio: ni campo, ni fila, ni efecto.

**Por qué:** el usuario ha separado explícitamente jugador y máquina. Un `PlayerStats` propio hace la propiedad evidente y evita que `MachineData` cargue estadísticas que no le corresponden.

**Alternativa descartada:** meter las cuatro stats como campos sueltos de `SimState`. Funciona, pero diluye la separación que este cambio quiere dejar clara.

### 6. Estadísticas de efecto y unidades nativas

**Decisión:** `UpgradeData.EffectStat` distingue estadísticas de máquina y de jugador:

| Valor | Destino | Unidad del `delta` |
| --- | --- | --- |
| `POWER_DRAW` | Máquina | energía/tick (modifica la entrada de energía de la ficha; 0 si no existe) |
| `SOLAR_OUTPUT` | Máquina | energía/tick |
| `FOOD_OUTPUT` | Máquina | comida/tick |
| `OXYGEN_OUTPUT` | Máquina | O₂/tick |
| `WATER_OUTPUT` | Máquina | agua/tick |
| `DEGRADATION` | Máquina | salud/tick |
| `REPAIR_SPEED` | Jugador | multiplicador (`+0.25` = +25 %) |
| `MOVE_SPEED` | Jugador | multiplicador |
| `HUNGER_MAX` | Jugador | puntos |
| `THIRST_MAX` | Jugador | puntos |

`delta` es siempre aditivo. Los consumos y la degradación efectivos se clampean a `>= 0`. Los consumos de O₂, agua y comida no tienen modificador de mejora en v1; solo la entrada de energía recibe `power_delta`.

### 7. Valores efectivos dentro de `SimTick`

**Decisión:** la producción, el consumo y la degradación leen `fila base + delta`. Los deltas se suman (varias mejoras pueden tocar la misma estadística) y se clampean a cero donde un valor negativo no tiene sentido. La producción sigue acotada por la capacidad del recurso. Los consumos declarados se restan tal cual, con clamp a cero; solo la entrada de energía recibe `power_delta`.

**Por qué:** concentra todos los efectos en el único escritor del estado y mantiene el determinismo. El orden de las mejoras no altera el resultado porque solo se suman deltas.

### 8. Orden del pipeline y firma del tick

**Decisión:** `SimTick.step(state, economy, machines)` ejecuta: producción → consumos → degradación → trabajos de máquina (reparaciones en curso) → eventos (no-op) → consecuencias → muerte → hechos.

La reparación se completa después de la degradación, de modo que una máquina reparada no vuelve a romperse en el mismo tick. El apagón por energía sigue ejecutándose en consecuencias y puede apagar en el mismo tick una máquina recién reparada; es el comportamiento esperado.

**Por qué la firma nueva:** el consumo por máquina vive en el registro; pasarlo como tercer argumento mantiene el estado puro y evita copiar configuración. `GameSim.advance_tick()` y `sim_smoke.gd` se actualizan.

### 9. API en `GameSim`, sin autoload nuevo

**Decisión:** `GameSim` carga `res://databases/machines.tres` en `_ready` (además de la economía), valida el registro y expone:

```gdscript
func get_machine_data(id: StringName) -> MachineData
func get_machine_state(id: StringName) -> MachineState
func can_start_repair(id: StringName) -> bool
func start_repair(id: StringName) -> bool
func is_repairing(id: StringName) -> bool
func repair_progress(id: StringName) -> float   # 0.0 .. 1.0
func can_apply_upgrade(id: StringName, upgrade_id: StringName) -> bool
func apply_upgrade(id: StringName, upgrade_id: StringName) -> bool
```

Un registro ausente o inválido produce `push_warning` y un `MachineDatabase` vacío; nunca rompe el arranque, igual que la economía.

**Por qué no un `MachineSystem` autoload:** el diseño limita los autoloads a cuatro y `GameSim` ya es el dueño del estado y del tick. Un singleton extra duplicaría el ciclo de vida y el reset.

### 10. Sin escenas ni interacción en este cambio

**Decisión:** no se crea `machine_base.gd`, ni `.tscn`, ni paneles. La API de `GameSim` es el contrato que consumirán las escenas futuras; `repair_progress` existe para que el panel de interacción pinte la barra sin recalcular nada.

**Por qué:** el usuario pidió expresamente no hacer diseño de máquinas. Además, sin escena base, jugador ni UI, una escena de máquina no se podría probar de extremo a extremo.

### 11. Verificación

**Decisión:** harness committed `game/scripts/dev/machines_smoke.gd` que carga los datos reales, usa datos sintéticos para las mejoras (las filas están vacías) y comprueba reparación, consumos, rechazos, efectos en el tick, estadísticas del jugador y reinicio. Además: `check-gdscript.sh -p game --strict`, boot headless y `sim_smoke.gd` actualizado como regresión.

## Risks / Trade-offs

| Riesgo | Mitigación |
| --- | --- |
| Migrar el consumo de economía a las fichas rompe tests existentes | Actualizar `sim_smoke.gd` y los tests temporales; `economy_check` y `sim_smoke` como regresión. |
| Las ocho filas nacen sin mejoras y el roster sigue indefinido | El schema y la API quedan listos; el harness prueba los efectos con datos sintéticos. |
| Una mejora con delta negativo grande deja consumo o degradación negativos | Clamp a `>= 0` en los valores efectivos. |
| Un `.tres` editado a mano puede traer un amount negativo, un recurso desconocido o un duplicado | El tick sanea en lectura (0, ignorar, ignorar duplicado); la validación lo reporta al arrancar. |
| `MOVE_SPEED` no tiene consumidor hasta que exista el jugador | Es una estadística del jugador explícitamente pedida; se almacena y se consumirá en el cambio del astronauta. |
| La máquina `lights` del núcleo no coincide con el `power_distributor` del diseño | Este cambio respeta los ocho ids ya congelados por `simulation-core`; la reconciliación queda como decisión de diseño posterior. |
| La reparación puede completarse durante un apagón | Orden documentado: consecuencias se ejecuta después y puede volver a apagarla; no hay estado incoherente. |

## Open Questions

- Roster definitivo de mejoras (8 máquinas × 2), sus ids, deltas y costes.
- Qué máquina consume cada recurso y en qué cantidad (agua en hidropónica, etc.).
- Si `lights` tendrá efecto mecánico o seguirá siendo solo carga y paso de apagado.
- Si el `power_distributor` será una máquina interactuable adicional o quedará representado por la batería y las filas de energía.
- Cuándo entra la radiación (tolerancia del jugador y/o mejoras) y con qué consumidor.
- Si la reparación debe poder cancelarse; v1 no lo permite.
- Si las divisiones tendrán skill checks en tiempo real (estilo Dead by Daylight); v1 solo usa las divisiones como progreso.
