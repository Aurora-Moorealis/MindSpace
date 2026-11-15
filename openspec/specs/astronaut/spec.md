# astronaut Specification

## Purpose
Movimiento del astronauta por la superficie lunar generada —aparición en el
spawn, desplazamiento con teclado, colisión con el terreno, orientación visual y
cámara de juego— y lectura del jugador por parte de la simulación: interacción
con máquinas cercanas, traje y radiación, zonas interior/exterior y vitales
expuestos para la interfaz.

## Requirements

### Requirement: Aparición en el spawn

La escena jugable SHALL colocar al astronauta en el centro del tile de spawn de
`LunarMap`, que SHALL ser una celda transitable de la zona de aterrizaje, y la
cámara SHALL empezar centrada en él.

#### Scenario: Spawn por defecto

- **WHEN** se carga la escena jugable con el mapa por defecto
- **THEN** el astronauta está en el centro del tile de spawn y ese tile es de plataforma de aterrizaje

#### Scenario: Cámara inicial

- **WHEN** la escena jugable termina de cargar
- **THEN** la cámara de juego está centrada en el astronauta

### Requirement: Movimiento en ocho direcciones

El astronauta SHALL moverse con las acciones `move_left`, `move_right`,
`move_up` y `move_down`, disponibles en WASD y en las flechas. El desplazamiento
diagonal SHALL estar normalizado para no ser más rápido que el recto. La
velocidad base SHALL proceder de la propiedad exportada de la escena y SHALL
multiplicarse por `player_move_speed_multiplier`. Sin entrada, con el reloj en
pausa o con la partida terminada, el astronauta SHALL NOT moverse.

#### Scenario: Movimiento recto

- **WHEN** el jugador mantiene la acción de movimiento a la derecha durante un segundo sin obstáculos
- **THEN** el astronauta avanza 160 píxeles a la derecha con el multiplicador por defecto

#### Scenario: Movimiento diagonal

- **WHEN** el jugador mantiene derecha y arriba a la vez
- **THEN** el astronauta se desplaza en diagonal a la misma velocidad que en recto

#### Scenario: Sin entrada

- **WHEN** el jugador no pulsa ninguna acción de movimiento
- **THEN** la posición del astronauta no cambia

#### Scenario: Reloj en pausa

- **WHEN** la simulación está en pausa
- **THEN** el astronauta no cambia de posición aunque se pulsen las acciones de movimiento

#### Scenario: Partida terminada

- **WHEN** la simulación declara el fin de la partida
- **THEN** el astronauta deja de aceptar movimiento

### Requirement: Colisión con el terreno

El astronauta SHALL NOT entrar en celdas no transitables (`ROCK` o `RIDGE`) ni
salir de los límites del mapa. Cuando un eje esté bloqueado, SHALL poder seguir
moviéndose por el otro eje.

#### Scenario: Roca

- **WHEN** el astronauta avanza contra una celda `ROCK` o `RIDGE`
- **THEN** su posición se detiene antes de entrar en esa celda

#### Scenario: Deslizamiento

- **WHEN** el astronauta avanza en diagonal contra un obstáculo que solo bloquea uno de los ejes
- **THEN** sigue moviéndose por el eje libre

#### Scenario: Borde del mapa

- **WHEN** el astronauta intenta salir por el borde del mapa
- **THEN** su posición se detiene dentro de los límites

### Requirement: Orientación visual

El sprite del astronauta SHALL usar el recurso existente `astronaut_4dir.png`
con cuatro frames de 32×32: abajo, arriba, izquierda y derecha. El frame SHALL
cambiar con la última dirección de movimiento y SHALL conservarse al quedarse
quieto.

#### Scenario: Cambio de dirección

- **WHEN** el astronauta se mueve hacia arriba
- **THEN** muestra el frame de espaldas

#### Scenario: Reposo

- **WHEN** el astronauta deja de moverse
- **THEN** conserva el frame de la última dirección

### Requirement: Cámara de juego

La cámara SHALL seguir al astronauta a escala 1:1, sin suavizado, y SHALL quedar
limitada a los bordes del mapa para no mostrar el vacío exterior. La cámara de
revisión de `lunar_map_camera_debug.tscn` SHALL seguir funcionando.

#### Scenario: Seguimiento

- **WHEN** el astronauta se desplaza por el mapa
- **THEN** la cámara se mantiene centrada en él

#### Scenario: Borde del mapa

- **WHEN** el astronauta se acerca al borde del mapa
- **THEN** la cámara se detiene en el límite y no muestra fuera del mapa

#### Scenario: Escena de revisión

- **WHEN** se abre la escena de revisión con su cámara libre
- **THEN** sigue cargando y desplazándose con W, A, S y D

### Requirement: Interacción por cercanía

El astronauta SHALL detectar los nodos del grupo `interactables` que estén dentro
de su área de interacción y SHALL elegir el más cercano como objetivo. Al pulsar
`interact` SHALL llamar a `interact(astronaut)` en el objetivo. Sin objetivo o
con el reloj en pausa, la pulsación SHALL NOT producir ninguna llamada.

#### Scenario: Objetivo cercano

- **WHEN** el astronauta está junto a una máquina y pulsa interactuar
- **THEN** la máquina recibe una llamada `interact` con el astronauta como argumento

#### Scenario: Varias máquinas

- **WHEN** hay más de una máquina dentro del área
- **THEN** el objetivo es la de menor distancia al astronauta

#### Scenario: Sin objetivo

- **WHEN** el astronauta pulsa interactuar sin ninguna máquina en el área
- **THEN** no se llama a ningún nodo

#### Scenario: Reloj en pausa

- **WHEN** el astronauta pulsa interactuar con una máquina en el área y la simulación está en pausa
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
- **THEN** la dosis sube según la fila de exterior multiplicada por la fila del traje reforzado

#### Scenario: Reinicio

- **WHEN** la partida se reinicia con el astronauta en escena
- **THEN** el traje vuelve a aplicarse al estado nuevo

### Requirement: Zona interior y exterior

El astronauta SHALL marcar el estado como exterior al entrar en un área del grupo
`exterior_zones` y como interior al salir. La simulación SHALL usar ese estado
para acumular o no dosis de radiación.

#### Scenario: Entrar al exterior

- **WHEN** el astronauta entra en una zona de exterior
- **THEN** el estado de simulación pasa a exterior y los ticks siguientes suman dosis

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
