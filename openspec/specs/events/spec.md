# events Specification

## Purpose

Define el contrato de datos y el comportamiento del scheduler de los eventos de la partida: arquetipos, targets, intensidades, ventanas, solapamiento, retraso, procedencia, ciclo de vida, cola y efectos por tick, para que la consola y la UI futuras consuman filas editables y hechos observables sin inventar reglas.

## Requirements

### Requirement: Registro de eventos con una fila por archivo

El registro SHALL exponer un índice de eventos y una fila por archivo. Cada fila MUST tener un `id` único en snake_case y MUST declarar su procedencia. Las filas con `real_data: false` MAY dejar `source` y `date_archived` vacíos; las filas con `real_data: true` MUST declarar una fuente y una fecha ISO-8601.

#### Scenario: Carga del registro inicial

- **WHEN** se carga el índice de eventos
- **THEN** contiene cinco filas y todos sus identificadores son únicos

#### Scenario: Fila sin procedencia

- **WHEN** una fila no declara procedencia
- **THEN** la validación la rechaza

#### Scenario: Fila placeholder

- **WHEN** una fila declara `real_data: false`
- **THEN** la validación acepta una fuente y una fecha vacías

### Requirement: Arquetipos y targets válidos

Cada fila SHALL declarar uno de los cinco arquetipos y un target compatible. Producción y consumo MUST apuntar a un recurso; avería MUST apuntar a una máquina; radiación MUST apuntar al pseudo-recurso `radiation`; corte de comunicaciones MUST no tener target.

#### Scenario: Caída de producción

- **WHEN** una fila es de tipo caída de producción
- **THEN** su target es `food`, `water`, `oxygen` o `energy`

#### Scenario: Avería de máquina

- **WHEN** una fila es de tipo avería
- **THEN** su target es una de las ocho máquinas del núcleo

#### Scenario: Ventana de radiación

- **WHEN** una fila es de tipo radiación
- **THEN** su target es `radiation`

#### Scenario: Target inválido

- **WHEN** una fila apunta a un target que no corresponde a su arquetipo
- **THEN** la validación la rechaza

### Requirement: Intensidad con signo e interpolación

Las intensidades SHALL almacenarse con signo: negativo para daño, consumo o caída; positivo para radiación. La fila MUST declarar `intensity_start`, `intensity_peak` e `intensity_end`. La intensidad SHALL interpolarse linealmente por tick: duración 1 usa el pico; duración 2 va de inicio a fin; duración 3 o más alcanza el pico en `duration_ticks / 2`.

#### Scenario: Ventana de varios ticks

- **WHEN** una ventana dura seis ticks con inicio 0.2, pico 0.8 y fin 0.2
- **THEN** el primer tick vale 0.2, el tick central vale 0.8 y el último vale 0.2

#### Scenario: Evento de un tick

- **WHEN** una fila dura un solo tick
- **THEN** su intensidad es el pico

#### Scenario: Signo incorrecto

- **WHEN** una avería, caída o pico de consumo declara una intensidad positiva
- **THEN** la validación la rechaza

### Requirement: Ventana temporal

Cada fila SHALL declarar `onset_tick` absoluto y `duration_ticks`. `onset_tick` MUST ser mayor o igual que 0 y `duration_ticks` MUST ser mayor o igual que 1. La ventana activa SHALL ser `[onset_tick, onset_tick + duration_ticks)`. La ventana MUST terminar dentro de los 300 ticks de misión.

#### Scenario: Límites de la ventana

- **WHEN** una ventana empieza en el tick 3 y dura 6
- **THEN** está activa en los ticks 3 a 8 y deja de estarlo en el 9

#### Scenario: Duración inválida

- **WHEN** una fila declara duración 0 o negativa
- **THEN** la validación la rechaza

#### Scenario: Fin fuera de misión

- **WHEN** una fila termina después del tick 300
- **THEN** la validación la rechaza

### Requirement: Solapamiento con consentimiento mutuo

Cada fila SHALL declarar `overlap_policy`: `EXCLUSIVE`, `WHITELIST` o `ANY`. `EXCLUSIVE` MUST impedir cualquier solapamiento. `WHITELIST` MUST listar los identificadores permitidos en `overlap_with`. `ANY` MUST no restringir por su parte. Dos eventos solo SHALL solaparse cuando ambas filas lo acepten.

#### Scenario: Whitelist mutua

- **WHEN** dos filas se listan mutuamente en `overlap_with`
- **THEN** pueden solaparse

#### Scenario: Whitelist unilateral

- **WHEN** una fila lista a otra pero la otra no la lista
- **THEN** no pueden solaparse y la validación lo advierte

#### Scenario: Veto exclusivo

- **WHEN** una fila es `EXCLUSIVE`
- **THEN** no puede solaparse con ninguna otra

#### Scenario: Referencia desconocida

- **WHEN** `overlap_with` referencia un id que no existe
- **THEN** la validación la rechaza

### Requirement: Retraso declarado por fila

Cada fila SHALL declarar `delay_min_ticks` y `delay_max_ticks` para el retraso de cola cuando no pueda solaparse. Ambos MUST ser mayores o iguales que 0 y `delay_max_ticks` MUST ser mayor o igual que `delay_min_ticks`.

#### Scenario: Rango de retraso válido

- **WHEN** una fila declara un mínimo de 1 y un máximo de 3
- **THEN** la validación acepta el rango

#### Scenario: Rango invertido

- **WHEN** una fila declara un mínimo mayor que el máximo
- **THEN** la validación la rechaza

### Requirement: Corte de comunicaciones sin efecto numérico

Una fila de corte de comunicaciones SHALL tener target vacío e intensidades cero. El corte MUST quedar como dato para que la consola lo consuma después y MUST NOT bloquear el envío de informes.

#### Scenario: Corte declarado

- **WHEN** una fila es de tipo corte de comunicaciones
- **THEN** no tiene target y sus tres intensidades son cero

#### Scenario: Corte con daño

- **WHEN** una fila de corte declara una intensidad distinta de cero
- **THEN** la validación la rechaza

### Requirement: Validación headless del registro

El proyecto SHALL incluir un validador ejecutable en headless que cargue el registro real y compruebe identificadores, targets, signos, ventanas, solapamiento, interpolación y procedencia. El validador SHALL salir con código 0 cuando todo es válido y distinto de 0 cuando hay errores.

#### Scenario: Registro válido

- **WHEN** se ejecuta el validador sobre el registro inicial
- **THEN** termina con código 0 y sin errores

#### Scenario: Registro inválido

- **WHEN** una fila incumple una regla del contrato
- **THEN** el validador reporta el problema y termina con código distinto de 0

### Requirement: Scheduler determinista de eventos

El tick SHALL procesar los eventos del registro en un orden estable y
determinista. Dos ejecuciones con el mismo estado, economía, máquinas, registro
y semilla MUST producir los mismos hechos y los mismos deltas de recursos. El
scheduler NO SHALL usar generadores de números aleatorios globales ni depender
del reloj real.

El orden de evaluación SHALL derivarse del tick de inicio y, para eventos con el
mismo inicio, del identificador del evento.

#### Scenario: Repetición determinista

- **WHEN** dos partidas idénticas avanzan los mismos ticks con el mismo registro
- **THEN** ambas producen la misma secuencia de hechos y los mismos recursos finales

#### Scenario: Orden estable

- **WHEN** dos eventos comparten el mismo tick de inicio
- **THEN** se evalúan siempre en el mismo orden, derivado de sus identificadores

### Requirement: Hechos de ciclo de vida

Cada evento SHALL emitir un hecho `EVENT_STARTED` en el primer tick en que su
ventana está activa y un hecho `EVENT_ENDED` en el primer tick posterior al
final. Cada hecho MUST incluir el identificador del evento y el tick real en que
ocurre. Un evento NO SHALL emitir más de un hecho de cada tipo por partida.

#### Scenario: Ventana de radiación

- **WHEN** la fila de radiación empieza en el tick 3 y dura 6 ticks
- **THEN** se emite `EVENT_STARTED` en el tick 3 y `EVENT_ENDED` en el tick 9

### Requirement: Ventana relativa al inicio real

Un evento que espera en cola MUST empezar en su tick real de inicio, no en el
tick declarado en la fila. Su duración SHALL contarse desde ese inicio real y su
intensidad SHALL muestrearse con el tiempo transcurrido desde él.

#### Scenario: Evento retrasado por la cola

- **WHEN** un evento no puede empezar en su tick declarado por un solape
- **THEN** su `EVENT_STARTED` usa el tick real en que empieza y su ventana dura lo declarado desde ese tick

### Requirement: Política de solape entre eventos

Dos eventos SHALL poder estar activos a la vez solo si ambos aceptan el solape.
La decisión SHALL respetar el consentimiento mutuo definido por los datos: un
evento solo puede empezar si todas las filas activas lo aceptan y él las acepta
a ellas. Un evento `EXCLUSIVE` NO SHALL coincidir con ningún otro.

#### Scenario: Whitelist mutua

- **WHEN** dos eventos se aceptan mutuamente en su lista de solape
- **THEN** pueden estar activos en el mismo tick y ambos aplican sus efectos

#### Scenario: Veto exclusivo

- **WHEN** un evento `EXCLUSIVE` está activo
- **THEN** ningún otro evento puede empezar hasta que su ventana termine

### Requirement: Cola y retraso determinista

Un evento que no pueda solaparse con otro evento activo SHALL esperar en cola.
El evento bloqueado MUST esperar al final de la ventana activa más un retraso
dentro del rango declarado por su fila. El retraso SHALL depender de la semilla
de la partida y del identificador del evento, de forma reproducible. Un evento
en cola NO SHALL aplicar efectos hasta que su ventana real empiece.

#### Scenario: Dos eventos exclusivos

- **WHEN** dos eventos `EXCLUSIVE` vencen en el mismo tick con un retraso mínimo de 1
- **THEN** el primero se activa, el segundo espera y empieza después del final del primero

#### Scenario: Evento en espera

- **WHEN** un evento está en cola porque no puede solaparse
- **THEN** no modifica recursos, salud, radiación ni comunicaciones hasta que empieza

### Requirement: Efectos de avería de máquina

Un evento de avería SHALL aplicar su intensidad como delta de salud de la
máquina objetivo. La salud MUST quedar acotada a `[0, MAX_HEALTH]`; un delta
positivo NO SHALL curar por encima del máximo. Si la salud cruza de positiva a
cero, la máquina SHALL quedar apagada y el tick MUST emitir un único hecho
`MACHINE_BREAKDOWN` con la máquina y el evento causante.

Un evento de avería cuya máquina objetivo no exista en la partida NO SHALL
provocar un error ni alterar otras máquinas.

#### Scenario: Avería que rompe la máquina

- **WHEN** un evento de avería reduce la salud de una máquina por debajo de cero
- **THEN** la salud queda en cero, la máquina se apaga y se emite un hecho de avería

#### Scenario: Avería sin máquina

- **WHEN** el registro contiene una avería contra una máquina ausente en el estado
- **THEN** el tick continúa sin error y sin cambios en las demás máquinas

### Requirement: Efectos de producción y consumo

Los eventos de caída de producción y de pico de consumo SHALL aplicar su
intensidad como resta neta del recurso objetivo: la cantidad restada MUST ser el
valor absoluto del delta negativo. El recurso NO SHALL quedar por debajo de cero
y el evento NO SHALL añadir recursos.

#### Scenario: Caída de producción de comida

- **WHEN** un evento de caída apunta a `food` con una intensidad negativa
- **THEN** la comida disminuye en la magnitud del delta y nunca queda negativa

#### Scenario: Pico de consumo de agua

- **WHEN** un evento de pico de consumo apunta a `water` con una intensidad negativa
- **THEN** el agua disminuye en la magnitud del delta y nunca queda negativa

### Requirement: Radiación y corte de comunicaciones

Una ventana de radiación SHALL sumar su intensidad a la dosis de radiación solo
cuando la partida está en el exterior. En el interior NO SHALL modificar la
dosis.

Un corte de comunicaciones SHALL mantener un flag observable activo mientras su
ventana esté vigente y NO SHALL aplicar ningún efecto numérico. El corte MUST NOT
bloquear el envío de informes ni otros hechos del ledger.

#### Scenario: Radiación en el exterior

- **WHEN** una ventana de radiación está activa y la partida está en el exterior
- **THEN** la dosis de radiación acumula la intensidad de cada tick

#### Scenario: Radiación en el interior

- **WHEN** una ventana de radiación está activa y la partida está en el interior
- **THEN** la dosis de radiación no cambia por ese evento

#### Scenario: Corte de comunicaciones

- **WHEN** un corte de comunicaciones está activo
- **THEN** el flag de comunicaciones bloqueadas está activo y los informes y hechos siguen registrándose

### Requirement: Carga, modo degradado y reinicio del scheduler

El juego SHALL cargar el registro de eventos al arrancar y pasarlo al tick. Si el
registro no existe, no se puede cargar o contiene filas inválidas, el juego MUST
arrancar igualmente, reportar el problema como advertencia de desarrollo y dejar
la partida sin eventos. En ese modo degradado NO SHALL emitirse hechos de evento
ni aplicarse efectos.

Un reinicio de partida SHALL limpiar el cursor, los eventos activos, la cola, el
flag de comunicaciones y la semilla de la partida.

#### Scenario: Registro ausente

- **WHEN** el registro de eventos falta o no es válido al arrancar
- **THEN** el juego arranca sin eventos, con advertencia, y el tick no emite hechos de evento

#### Scenario: Reinicio de partida

- **WHEN** se reinicia una partida con eventos activos y en cola
- **THEN** el estado de eventos vuelve al de una partida nueva y la semilla se restablece

### Requirement: Verificación headless del scheduler

El proyecto SHALL incluir un harness headless que cargue el registro real y
verifique el ciclo de vida, la cola, el solape, los efectos de los cinco
arquetipos, el determinismo y el reinicio. El harness MUST salir con código 0
cuando todas las comprobaciones pasan y distinto de 0 cuando falla alguna.

#### Scenario: Harness correcto

- **WHEN** se ejecuta el harness con el registro real
- **THEN** termina con código 0 y un resumen de comprobaciones correctas

#### Scenario: Harness con fallo

- **WHEN** una comprobación del scheduler falla
- **THEN** el harness reporta el fallo y termina con código distinto de 0
