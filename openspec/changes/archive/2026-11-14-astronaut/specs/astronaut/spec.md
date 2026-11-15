# Spec Delta

## Purpose

Define el comportamiento del astronauta: cómo se mueve, cómo elige e interactúa
con una máquina cercana, cómo su traje y su zona modifican la radiación, y qué
vitales expone para la interfaz.

## ADDED Requirements

### Requirement: Movimiento en cuatro direcciones

El astronauta SHALL moverse sobre el plano con las acciones `move_left`,
`move_right`, `move_up` y `move_down`, que responden a WASD y a las flechas. La
velocidad SHALL ser constante y la diagonal SHALL normalizarse para no ser más
rápida que un eje. El sprite SHALL mostrar la dirección del último movimiento y
SHALL conservarla al detenerse.

#### Scenario: Movimiento horizontal

- **WHEN** se mantiene pulsada la acción de mover a la derecha
- **THEN** el astronauta avanza a velocidad constante y muestra su vista lateral
  derecha

#### Scenario: Diagonal

- **WHEN** se pulsan dos ejes a la vez
- **THEN** la velocidad resultante tiene la misma magnitud que la de un solo eje

#### Scenario: Detenerse

- **WHEN** se dejan de pulsar las acciones de movimiento
- **THEN** el astronauta se detiene y conserva la última dirección mostrada

#### Scenario: Partida terminada

- **WHEN** la simulación declara el fin de la partida
- **THEN** el astronauta deja de aceptar movimiento

### Requirement: Interacción por cercanía

El astronauta SHALL detectar los nodos del grupo `interactables` que estén dentro
de su área de interacción y SHALL elegir el más cercano como objetivo. Al pulsar
`interact` SHALL llamar a `interact(astronaut)` en el objetivo. Sin objetivo, la
pulsación SHALL NOT producir ninguna llamada.

#### Scenario: Objetivo cercano

- **WHEN** el astronauta está junto a una máquina y pulsa interactuar
- **THEN** la máquina recibe una llamada `interact` con el astronauta como
  argumento

#### Scenario: Varias máquinas

- **WHEN** hay más de una máquina dentro del área
- **THEN** el objetivo es la de menor distancia al astronauta

#### Scenario: Sin objetivo

- **WHEN** el astronauta pulsa interactuar sin ninguna máquina en el área
- **THEN** no se llama a ningún nodo

### Requirement: Traje y radiación

El astronauta SHALL tener dos tipos de traje: básico y reforzado. El tipo SHALL
aplicarse al estado de simulación al entrar en escena y al reiniciar la partida.
El traje reforzado SHALL multiplicar por la fila de economía la dosis que el
astronauta recibe en el exterior; el traje básico SHALL dejar la dosis sin
multiplicar.

#### Scenario: Traje básico

- **WHEN** el astronauta lleva el traje básico y pasa un tick en el exterior
- **THEN** la dosis sube según la fila de radiación de exterior sin reducción

#### Scenario: Traje reforzado

- **WHEN** el astronauta lleva el traje reforzado y pasa un tick en el exterior
- **THEN** la dosis sube según la fila de exterior multiplicada por la fila del
  traje reforzado

#### Scenario: Reinicio

- **WHEN** la partida se reinicia con el astronauta en escena
- **THEN** el traje vuelve a aplicarse al estado nuevo

### Requirement: Zona interior y exterior

El astronauta SHALL marcar el estado como exterior al entrar en un área del grupo
`exterior_zones` y como interior al salir. La simulación SHALL usar ese estado
para acumular o no dosis de radiación.

#### Scenario: Entrar al exterior

- **WHEN** el astronauta entra en una zona de exterior
- **THEN** el estado de simulación pasa a exterior y los ticks siguientes suman
  dosis

#### Scenario: Volver al interior

- **WHEN** el astronauta sale de la zona de exterior
- **THEN** el estado vuelve a interior y la dosis deja de crecer

### Requirement: Vitales expuestos

El astronauta SHALL exponer la salud, el oxígeno, el hambre y la sed del estado de
simulación, y SHALL emitir una señal `vitals_changed` en cada tick para que la
interfaz pueda refrescarse sin conocer `GameSim`.

#### Scenario: Lectura de vitales

- **WHEN** la interfaz pide los vitales del astronauta
- **THEN** recibe los valores actuales de salud, oxígeno, hambre y sed

#### Scenario: Tick

- **WHEN** la simulación avanza un tick
- **THEN** el astronauta emite `vitals_changed`

### Requirement: Dirección visible

La hoja del astronauta SHALL mostrar cuatro vistas —frontal, trasera, lateral
izquierda y lateral derecha— y la escena SHALL seleccionar la vista que
corresponda a la dirección de movimiento.

#### Scenario: Vista frontal

- **WHEN** el astronauta se mueve hacia abajo o está parado tras hacerlo
- **THEN** se muestra la vista frontal

#### Scenario: Vista trasera

- **WHEN** el astronauta se mueve hacia arriba
- **THEN** se muestra la vista trasera
