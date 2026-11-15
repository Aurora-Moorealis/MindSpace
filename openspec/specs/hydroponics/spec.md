# hydroponics Specification

## Purpose
Sistema de cultivo de la estación de hidroponía: doce celdas que crecen con los
ticks de la simulación, se pueden plantar, cosechar y retirar desde su panel, y
producen comida cuando la máquina está operativa.

## Requirements

### Requirement: Doce celdas con cuatro etapas

La hidroponía SHALL tener doce celdas de cultivo organizadas en tres filas de
cuatro. Cada celda SHALL estar vacía o en una de cuatro etapas de crecimiento, de
semilla a planta madura, y el panel SHALL mostrar la etapa de cada celda.

#### Scenario: Rejilla inicial

- **WHEN** empieza una partida nueva
- **THEN** las doce celdas están vacías y el panel las muestra como vacías

#### Scenario: Etapa visible

- **WHEN** una celda plantada avanza de etapa
- **THEN** el panel muestra la nueva etapa en el siguiente refresco

### Requirement: Crecimiento por tick determinista

El crecimiento SHALL medirse en ticks de simulación, nunca en tiempo real ni con
aleatoriedad global. Cada celda plantada SHALL avanzar de etapa al acumular los
ticks de su intervalo, y dos partidas con la misma semilla y las mismas acciones
SHALL producir las mismas etapas en el mismo tick.

#### Scenario: Avance por ticks

- **WHEN** una celda plantada acumula los ticks de su intervalo
- **THEN** sube exactamente una etapa

#### Scenario: Partida pausada

- **WHEN** la partida está pausada
- **THEN** ninguna celda cambia de etapa

#### Scenario: Misma semilla

- **WHEN** dos partidas con la misma semilla plantan las mismas celdas en los mismos ticks
- **THEN** las etapas coinciden tick a tick

### Requirement: Crecimiento detenido sin máquina operativa

Mientras la hidroponía esté averiada o sin energía, las celdas NO SHALL avanzar
de etapa ni acumular progreso. Al volver a estar operativa, el crecimiento SHALL
reanudarse desde el progreso que tenía.

#### Scenario: Máquina averiada

- **WHEN** la hidroponía se avería con celdas en crecimiento
- **THEN** las celdas conservan su etapa y no acumulan progreso mientras dure la avería

#### Scenario: Reanudación

- **WHEN** la hidroponía vuelve a estar operativa
- **THEN** las celdas siguen creciendo desde la etapa y el progreso que tenían

### Requirement: Plantar una celda

El panel SHALL permitir plantar en una celda vacía mientras la máquina esté
operativa. Plantar SHALL fijar la etapa de semilla y el intervalo de crecimiento
de esa celda sin alterar las demás ni consumir recursos.

#### Scenario: Plantar

- **WHEN** el jugador planta en una celda vacía con la máquina operativa
- **THEN** la celda pasa a etapa de semilla y empieza a acumular ticks

#### Scenario: Celda ocupada

- **WHEN** el jugador intenta plantar en una celda que ya tiene planta
- **THEN** la acción se rechaza sin cambiar la celda

#### Scenario: Máquina no operativa

- **WHEN** el jugador intenta plantar con la máquina averiada o sin energía
- **THEN** la acción se rechaza y la celda sigue vacía

### Requirement: Cosechar una celda madura

El panel SHALL permitir cosechar una celda en su etapa final mientras la máquina
esté operativa. La cosecha SHALL añadir a la reserva de comida la cantidad de la
fila `hydroponics_harvest_food`, acotada por la capacidad, SHALL dejar la celda
vacía y NO SHALL repetirse sobre la misma celda hasta volver a plantarla.

#### Scenario: Cosecha

- **WHEN** el jugador cosecha una celda madura
- **THEN** la comida sube la cantidad configurada sin superar la capacidad y la celda queda vacía

#### Scenario: Celda inmadura

- **WHEN** el jugador intenta cosechar una celda que no está en la etapa final
- **THEN** la acción se rechaza y la celda conserva su etapa

#### Scenario: Reserva llena

- **WHEN** el jugador cosecha con la comida en su capacidad máxima
- **THEN** la comida no supera la capacidad y la celda queda vacía igualmente

### Requirement: Retirar una celda

El panel SHALL permitir retirar cualquier celda plantada, incluida la que está en su
etapa final, dejando la celda vacía y sin producir comida. Retirar NO SHALL exigir
que la máquina esté operativa. Retirar una celda madura SHALL ser distinto de
cosecharla: la cosecha exige máquina operativa y añade comida, la retirada no.

#### Scenario: Retirar

- **WHEN** el jugador retira una celda plantada que no está madura
- **THEN** la celda queda vacía y no se añade comida

#### Scenario: Celda madura

- **WHEN** el jugador retira una celda que está en su etapa final
- **THEN** la celda queda vacía y no se añade comida

#### Scenario: Máquina averiada

- **WHEN** el jugador retira una celda con la máquina averiada o sin energía
- **THEN** la celda queda vacía y no se añade comida

### Requirement: Panel de cultivo

El panel de máquina de la hidroponía SHALL ofrecer la acción de abrir el panel de
cultivo. Ese panel SHALL mostrar las doce celdas con su etapa, permitir las
acciones válidas de cada celda y volver al panel de máquina. El panel de cultivo
NO SHALL abrirse con la máquina averiada.

#### Scenario: Abrir el cultivo

- **WHEN** el jugador usa la acción de cultivo desde el panel de la hidroponía sana
- **THEN** se abre el panel de cultivo con las doce celdas

#### Scenario: Volver

- **WHEN** el jugador cierra el panel de cultivo
- **THEN** vuelve al panel de máquina sin alterar ninguna celda

#### Scenario: Máquina averiada

- **WHEN** la hidroponía está averiada
- **THEN** la acción de cultivo está deshabilitada y explica el motivo

### Requirement: Reinicio del cultivo

Un reinicio de partida SHALL dejar las doce celdas vacías, el contador de
cosechas a cero y el panel de cultivo cerrado.

#### Scenario: Reinicio

- **WHEN** se reinicia la partida con celdas plantadas y cosechadas
- **THEN** todas las celdas vuelven a estar vacías y el contador de cosechas a cero

### Requirement: Aspecto de la estación en el mundo

La estación de hidroponía del outpost SHALL dibujarse con el sprite aprobado
`res://content/machines/hydroponics/art/sprites/hydroponics_rack.png`, sin sustituirlo
por la silueta genérica de `MachineStation`. La estación SHALL conservar su huella de
colisión y su puerto de cable, y NO SHALL cambiar de tamaño ni de posición por usar el
sprite.

#### Scenario: Estación en el outpost

- **WHEN** el jugador mira la estación de hidroponía en el outpost
- **THEN** ve el sprite del rack y no una caja dibujada por código

#### Scenario: Red de cables

- **WHEN** la estación se conecta a la red de cables
- **THEN** el cable llega al mismo puerto que antes de usar el sprite
