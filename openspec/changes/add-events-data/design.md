# Design

## Context

`sim-core` deja la etapa de eventos de `SimTick` como no-op y no existe un schema de filas. El diseño formal (`docs/designs/junior-astronauta-outpost-lunar.md`) ya fija cinco arquetipos, targets `máquina|recurso`, tres escalares de intensidad y procedencia NASA. Esta entrega solo añade el contrato de datos; el scheduler y los efectos quedan fuera. La rama `events` sale de `sim-core` porque necesita `DataProvenance`, `SimState` y la economía ya implementados.

## Goals / Non-Goals

**Goals:**

- Un registro editable con una fila por evento y validación ejecutable.
- Targets inequívocos para producción/consumo y averías.
- Reglas de solapamiento y retraso declaradas en los datos, no en código futuro.
- Cinco filas iniciales que cubran todos los arquetipos.

**Non-Goals:**

- Aplicar eventos en `SimTick`, emitir hechos o mostrar banners.
- Datos NASA reales, tuning de balance o presets de demo.
- Persistencia de eventos o serialización de estado.

## Decisions

### 1. Una fila por archivo más un índice

`events.tres` es un índice de `ExtResource` y cada fila vive en `events_rows/<id>.tres`, igual que `economy.tres`/`economy_rows`. Evita que dos personas editen el mismo archivo y reduce conflictos de `sub_resource` y `uid`. Alternativa descartada: un único `events.tres` con subresources, más simple pero frágil en una rama compartida.

### 2. Producción y consumo apuntan a un recurso

La hidropónica produce comida y oxígeno. Si una caída de producción apuntara a la máquina, habría que decidir si baja una salida, la otra o ambas. Apuntar a `food`, `water`, `oxygen` o `energy` hace que la fila diga exactamente qué recurso cambia. La avería sí apunta a la máquina porque su delta es salud. Alternativa descartada: `target_type` máquina + `output_resource` opcional, más expresivo pero con más campos y validaciones.

### 3. La radiación es un pseudo-recurso

La dosis vive en `SimState.radiation_dose`, no en `resources`. Para no añadir un campo específico al schema, las filas usan `target_type: RESOURCE` y `target_id: radiation`. El validador lo trata como target válido solo para el arquetipo de radiación. Alternativa descartada: `target_type: NONE` + lógica implícita por arquetipo, que oculta el target y complica la UI de fuente.

### 4. Deltas con signo

Las intensidades se guardan con signo: negativo resta o daña, positivo suma. Evita que cada consumidor tenga que recordar la dirección del efecto y permite validar el signo por arquetipo. Alternativa descartada: magnitud positiva más un booleano `is_penalty`, que duplica la información.

### 5. Política de solape con consentimiento mutuo

Cada fila declara `EXCLUSIVE`, `WHITELIST` o `ANY` y, si es whitelist, la lista `overlap_with`. `EventData.can_overlap()` exige que ambas filas acepten: un `EXCLUSIVE` veta el par y dos whitelists deben listarse mutuamente. Así una fila puede decir “no me solapes con nada” sin que otra la fuerce. Alternativas descartadas: whitelist unilateral (una fila puede imponerse) y lista global por arquetipo (pierde el caso concreto).

### 6. Retraso con semilla determinista

La fila declara `delay_min_ticks` y `delay_max_ticks`. El scheduler futuro sorteará el retraso con una semilla derivada de la partida y del `id` del evento, no con `randi()` global. Parece aleatorio pero mantiene el determinismo que exigen los presets y los tests. Esta entrega solo almacena el rango; no sortea nada todavía.

### 7. Corte de comunicaciones sin efecto numérico

El diseño prohíbe que un corte programado bloquee el envío de informes. Como previsión y pedidos aún no existen, la fila no tiene target ni intensidad; solo quedará el flag `comms_blocked` cuando exista la consola. Alternativa descartada: bloquear informes, que puede congelar la victoria.

### 8. Validación en un script de desarrollo

`game/scripts/dev/events_check.gd` sigue el patrón de `sim_smoke.gd` y se versiona. No se usa `DataAudit` porque ese autoload todavía no existe. El checker carga el registro real, valida filas y comprueba casos de solapamiento e interpolación.

### 9. Set inicial de cinco filas placeholder

Una fila por arquetipo, con la primera ventana de radiación en el tick 3, como pide el diseño. Todas llevan `real_data: false`; los valores concretos son tuning posterior. Esto permite que el scheduler y la UI se desarrollen contra filas reales desde el primer día.

## Risks / Trade-offs

- **Sin scheduler, los datos no tienen efecto visible** → el checker y este diseño fijan el contrato; la siguiente entrega debe consumirlo sin reinterpretarlo.
- **El consentimiento mutuo puede sorprender** → el README y los mensajes del validador explican que una whitelist unilateral no basta.
- **Muchos archivos pequeños** → se acepta a cambio de merges limpios; el índice debe actualizarse al añadir una fila.
- **La interpolación de duración 2 no alcanza el pico** → está documentada y probada; el pico es conceptual en eventos de dos ticks.
- **La semilla del retraso aún no existe** → queda como decisión de diseño para el scheduler; el dato solo declara el rango.
- **Valores placeholder** → `real_data: false` es obligatorio hasta el swap de datos NASA.

## Migration Plan

No hay migración de datos: el registro es nuevo y no se consume todavía. La rama se integra después de `sim-core`; no se tocan escenas, autoloads ni `project.godot`. Rollback: eliminar `events.tres`, `events_rows/` y `resources/events/`, y revertir el checker.

## Open Questions

- Qué algoritmo exacto de semilla usará el scheduler (`run_seed + event_id` es la propuesta).
- Qué valores definitivos tendrán las cinco filas tras el tuning y el swap de datos NASA.
- Cómo se renderizará la tarjeta de fuente en el banner de evento.
