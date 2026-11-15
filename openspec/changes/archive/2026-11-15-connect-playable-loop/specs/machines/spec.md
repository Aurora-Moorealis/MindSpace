# Spec Delta

## ADDED Requirements

### Requirement: Panel de máquina accesible

Al interactuar con una estación, el juego SHALL abrir el panel de esa máquina.
Solo SHALL haber un panel de máquina abierto a la vez y el panel SHALL cerrarse
con su control de cierre o con la tecla de cancelar.

#### Scenario: Abrir el panel

- **WHEN** el jugador pulsa interactuar junto a una estación
- **THEN** se abre el panel de esa máquina con su estado actual

#### Scenario: Cambiar de máquina

- **WHEN** el jugador interactúa con otra estación con un panel abierto
- **THEN** el panel pasa a mostrar la nueva máquina y no quedan dos paneles a la vez

#### Scenario: Cerrar

- **WHEN** el jugador usa el control de cierre o la tecla de cancelar
- **THEN** el panel se cierra y el juego vuelve a aceptar movimiento

### Requirement: Estado de la máquina en el panel

El panel SHALL mostrar el nombre en inglés de la máquina, su pista, su salud
sobre el máximo, si está encendida o apagada, si está averiada, el progreso de la
reparación en curso y las mejoras aplicadas. Los valores SHALL refrescarse en
cada tick.

#### Scenario: Estado sano

- **WHEN** el panel muestra una máquina sana y encendida
- **THEN** la salud aparece al máximo y no hay reparación en curso

#### Scenario: Avería

- **WHEN** la salud de la máquina llega a cero
- **THEN** el panel la muestra como averiada en el siguiente refresco

#### Scenario: Progreso de reparación

- **WHEN** hay una reparación en curso
- **THEN** el panel muestra un progreso entre 0 y 1 que aumenta con los ticks

### Requirement: Reparar desde el panel

El panel SHALL ofrecer la acción de reparar con su coste de energía. La acción
SHALL estar habilitada solo cuando la reparación pueda iniciarse y, al
activarla, SHALL iniciarla y actualizar el estado mostrado.

#### Scenario: Reparación iniciada

- **WHEN** el jugador activa reparar en una máquina dañada con energía suficiente
- **THEN** la reparación empieza, la energía baja el coste y el panel muestra el progreso

#### Scenario: Acción deshabilitada

- **WHEN** la reparación no puede iniciarse
- **THEN** la acción aparece deshabilitada y el panel explica el motivo

#### Scenario: Reparación ya en curso

- **WHEN** el jugador activa reparar de nuevo durante una reparación
- **THEN** no se cobra energía y el progreso no se reinicia

### Requirement: Mejoras desde el panel

El panel SHALL listar cada mejora disponible con la estadística que cambia, su
delta y su coste de energía. La acción de cada mejora SHALL estar habilitada solo
cuando la mejora pueda aplicarse y, tras aplicarla, SHALL mostrarla como
aplicada. Las mejoras que la máquina no puede expresar NO SHALL ofrecerse.

#### Scenario: Mejora aplicada

- **WHEN** el jugador aplica una mejora válida
- **THEN** la energía baja el coste y la mejora aparece como aplicada

#### Scenario: Mejora repetida

- **WHEN** una mejora ya está aplicada
- **THEN** su acción está deshabilitada y no se puede volver a cobrar

#### Scenario: Mejora incompatible

- **WHEN** la ficha declara una mejora que la máquina no puede expresar
- **THEN** esa mejora no aparece en el panel

### Requirement: Motivo de una acción deshabilitada

Toda acción deshabilitada del panel SHALL mostrar un motivo en inglés, elegido
entre salud completa, reparación en curso, energía insuficiente, máquina
averiada, mejora ya aplicada, datos no disponibles y partida terminada.

#### Scenario: Energía insuficiente

- **WHEN** la energía no cubre el coste de reparar o de una mejora
- **THEN** la acción está deshabilitada y el motivo indica que falta energía

#### Scenario: Máquina sana

- **WHEN** la máquina está a la salud máxima
- **THEN** reparar está deshabilitado y el motivo indica que no necesita reparación

#### Scenario: Datos no disponibles

- **WHEN** falta la ficha o el estado de la máquina
- **THEN** las acciones están deshabilitadas y el motivo indica que faltan datos

### Requirement: Panel y entrada del juego

Con el panel de máquina abierto, el movimiento y la interacción del astronauta
NO SHALL responder, y el reloj NO SHALL pausarse por abrir el panel. Al terminar
la partida o reiniciarla, el panel SHALL cerrarse.

#### Scenario: Movimiento bloqueado

- **WHEN** el jugador intenta mover al astronauta con el panel abierto
- **THEN** el astronauta no se desplaza y el panel sigue abierto

#### Scenario: Reloj en marcha

- **WHEN** el panel lleva abierto varios segundos con el reloj a ×1
- **THEN** los ticks siguen avanzando y el panel se refresca

#### Scenario: Fin de partida

- **WHEN** la partida termina con el panel abierto
- **THEN** el panel se cierra y no acepta más acciones
