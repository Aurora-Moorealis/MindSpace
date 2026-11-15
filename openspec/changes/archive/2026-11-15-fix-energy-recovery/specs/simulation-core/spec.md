# Spec Delta

## ADDED Requirements

### Requirement: Recuperación tras el apagón

Cuando una red vuelva a tener carga, el núcleo SHALL volver a encender las
máquinas que el apagón dejó apagadas, empezando por el sistema de O₂ y siguiendo
el orden inverso al apagado, como máximo `blackout_steps_per_tick` por tick. Una
máquina averiada NO SHALL encenderse hasta ser reparada.

#### Scenario: Recuperación gradual

- **WHEN** una red recupera carga después de un apagón
- **THEN** el sistema de O₂ se enciende primero, después el reciclador, la hidropónica y las luces, una máquina por tick

#### Scenario: Red sin carga

- **WHEN** la red sigue con carga 0
- **THEN** no se enciende ninguna máquina apagada

#### Scenario: Máquina averiada

- **WHEN** una máquina apagada está averiada
- **THEN** no se enciende hasta que se repare

#### Scenario: Determinismo

- **WHEN** dos partidas llegan al mismo estado de red y máquinas
- **THEN** la recuperación enciende las mismas máquinas en el mismo orden
