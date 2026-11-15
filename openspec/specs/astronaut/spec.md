# astronaut Specification

## Purpose
Movimiento del astronauta por la superficie lunar generada: aparición en el
spawn, desplazamiento con teclado, colisión con el terreno, orientación visual y
cámara de juego.

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
velocidad base SHALL proceder de la propiedad exportada de la escena (160
píxeles por segundo por defecto) y SHALL multiplicarse por
`player_move_speed_multiplier`. Sin entrada, el astronauta SHALL quedarse
quieto.

#### Scenario: Movimiento recto

- **WHEN** el jugador mantiene la acción de movimiento a la derecha durante un segundo sin obstáculos
- **THEN** el astronauta avanza 160 píxeles a la derecha con el multiplicador por defecto

#### Scenario: Movimiento diagonal

- **WHEN** el jugador mantiene derecha y arriba a la vez
- **THEN** el astronauta se desplaza en diagonal a la misma velocidad que en recto

#### Scenario: Sin entrada

- **WHEN** el jugador no pulsa ninguna acción de movimiento
- **THEN** la posición del astronauta no cambia

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
