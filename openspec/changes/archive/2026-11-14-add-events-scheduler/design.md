# Design

## Context

El cambio `add-events-data` dejó un registro validado y cinco filas, pero el
tick seguía tratando los eventos como un no-op. Las máquinas ya tienen su propia
etapa de trabajo y el tick recibe su registro; el scheduler debe encajar en ese
orden sin romper el determinismo ni duplicar la lógica de recursos.

Este diseño completa el consumo del registro y cierra el hueco de validación que
dejó la entrega de datos.

## Goals / Non-Goals

**Goals:**

- Aplicar las cinco filas reales en el tick con un orden determinista.
- Explicar el ciclo de vida con hechos `EVENT_STARTED`/`EVENT_ENDED`.
- Resolver solapes y cola con el contrato de datos existente.
- Integrarse con el registro de máquinas sin acoplarse a la UI.
- Mantener el arranque tolerante a un registro ausente o inválido.

**Non-Goals:**

- UI, banner o consola de comunicaciones.
- Bloqueo real de informes durante un corte.
- Persistencia o replay del estado de eventos.
- Tuning de balance o datos NASA reales.

## Decisions

### 1. Los eventos van después del trabajo de máquina y antes de las consecuencias

**Decisión:** el orden del tick es producción → consumo → degradación → trabajos
de máquina → eventos → consecuencias → muerte → calendario.

**Por qué:** las reparaciones en curso deben avanzar aunque un evento dañe una
máquina en el mismo tick, y la radiación de un evento debe entrar en las
consecuencias de ese mismo tick. Aplicar eventos al principio retrasaría el daño
un tick y haría que la reparación compitiera con el evento en un orden
sorprendente.

**Alternativa descartada:** eventos antes de la degradación. Habría permitido
que una reparación completada en el mismo tick curara el daño del evento, lo que
hace el resultado dependiente de dos acciones simultáneas y dificulta explicarlo.

### 2. Los efectos de producción y consumo restan recurso neto

**Decisión:** `PRODUCTION_DROP` y `CONSUMPTION_SPIKE` aplican su delta como resta
directa del recurso objetivo, con clamp a cero. No crean un modificador temporal
de la producción ni del consumo.

**Por qué:** la fila apunta a un recurso, no a una máquina, y la hidropónica
produce dos recursos. Restar el recurso evita elegir una salida arbitraria y
mantiene el efecto acotado por la capacidad existente. Es una simplificación
explícita para la demo; el diseño formal puede evolucionar a modificadores de
tasa sin cambiar el contrato de datos.

**Alternativa descartada:** un modificador de producción por recurso. Requiere
que el estado guarde tasas temporales y que la etapa de producción sepa qué
evento las origina; más superficie y más casos límite para el mismo efecto
visible en una demo corta.

### 3. Inicio real y ventana relativa al inicio

**Decisión:** un evento activo guarda el tick en que realmente empezó. La
expiración se calcula como `tick_inicio + duration_ticks`, no como
`onset_tick + duration_ticks`.

**Por qué:** un evento bloqueado por solape puede empezar más tarde que su
`onset_tick`. Si la expiración usara el onset declarado, el evento podría nacer
caducado. La intensidad se muestrea con el tiempo transcurrido desde el inicio
real.

**Alternativa descartada:** conservar la ventana original y recortar la duración.
Pierde ticks de efecto y hace que dos partidas con distinto solape tengan
duraciones efectivas distintas sin que el dato lo diga.

### 4. Retraso determinista con semilla de partida e id

**Decisión:** cuando un evento no puede empezar, espera hasta el final de la
ventana activa más un retraso en `[delay_min_ticks, delay_max_ticks]` derivado de
la semilla de la partida y del id del evento. La semilla se guarda en el estado y
se restablece al reiniciar.

**Por qué:** el diseño pide que el retraso parezca variable entre partidas pero
sea reproducible para tests y presets. Una función estable (FNV-1a sobre semilla
e id) evita el RNG global y no depende del orden de llamadas.

**Alternativa descartada:** `randi()` global. Rompe la reproducibilidad y hace
que el resultado dependa de cuántos números aleatorios se hayan consumido antes.

### 5. Cola separada de eventos activos

**Decisión:** el estado mantiene una lista de activos y otra de pendientes. Los
activos aplican efectos cada tick; los pendientes solo esperan y no modifican
nada.

**Por qué:** separa claramente “vigente” de “en espera” y permite consultar el
ciclo de vida sin ambigüedad. La cola se evalúa después de expirar los activos,
de modo que un evento puede empezar en el mismo tick en que otro termina.

### 6. Modo degradado y reinicio

**Decisión:** `GameSim` carga `events.tres` una vez; si falta o no es válido,
usa un registro vacío y avisa. El reinicio limpia cursor, activos, pendientes,
flag de comunicaciones y semilla.

**Por qué:** un dato roto nunca debe impedir arrancar la demo. El reinicio debe
dejar una partida limpia aunque la anterior tuviera eventos a medias.

### 7. Validación de la ventana de misión

**Decisión:** la validación del registro rechaza cualquier ventana cuyo final
supere los 300 ticks de misión, además de las reglas ya existentes.

**Por qué:** la spec de datos ya lo exigía, pero solo el checker de desarrollo lo
comprobaba sobre las filas reales; el validador de runtime no lo aplicaba. Se
cierra el hueco con una comprobación sintética en `events_check`.

## Risks / Trade-offs

- **La resta neta no modela una caída de producción real** → se documenta y se
  deja como simplificación de demo; el contrato de datos permite cambiarlo luego.
- **La cola puede retrasar un evento más allá de su ventana útil** → el retraso
  está acotado por fila y el evento mantiene toda su duración desde el inicio
  real.
- **La semilla es fija por defecto** → el determinismo es prioritario; una
  futura pantalla de nueva partida puede elegir otra semilla sin cambiar el
  scheduler.
- **Sin UI, el jugador no ve los eventos** → el banner y la consola quedan fuera
  de alcance; el ledger y los flags ya exponen el estado para esa capa.

## Migration Plan

No hay migración de datos: las cinco filas ya existen. El cambio se integra
después de `add-machines` y `add-lunar-map-tile-render`; no toca escenas ni
autoloads nuevos. Rollback: revertir el commit del scheduler y dejar el registro
de datos, que seguiría siendo válido sin consumirse.

## Open Questions

- Ninguna bloqueante para esta entrega. El tuning de las cinco filas y los datos
  NASA reales quedan para un cambio posterior.
