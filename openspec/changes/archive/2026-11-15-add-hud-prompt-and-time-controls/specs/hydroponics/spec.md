# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
