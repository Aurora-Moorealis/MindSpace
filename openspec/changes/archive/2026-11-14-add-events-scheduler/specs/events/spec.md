# Spec Delta

## Purpose

Define el comportamiento observable del scheduler de eventos y de los efectos
que aplica en cada tick, sobre el contrato de datos ya existente en `events`.

## ADDED Requirements

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
