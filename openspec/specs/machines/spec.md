# machines Specification

## Purpose
Define el catálogo data-driven de las ocho máquinas, su consumo propio de energía y recursos, la reparación por divisiones con velocidad del jugador, las mejoras de un solo uso y los efectos de estas sobre el tick y las estadísticas del astronauta.

## Requirements

### Requirement: Catálogo de máquinas dirigido por datos

Cada una de las ocho máquinas SHALL declararse como una fila editable con id, clave de nombre, pista, tiempo de reparación, coste de reparación, lista de consumos por tick y lista de mejoras. Las filas SHALL vivir junto al contenido de su máquina y un índice SHALL reunirlas. Los ids SHALL coincidir con los ocho ids de máquina del núcleo. Una fila ausente, duplicada o inválida SHALL reportarse como problema de datos y NO SHALL impedir el arranque.

#### Scenario: Fila editada sin código

- **WHEN** se cambia el tiempo de reparación, el consumo o una mejora de una máquina en su fila
- **THEN** el juego usa el nuevo valor sin cambios de código

#### Scenario: Id desconocido o duplicado

- **WHEN** el registro contiene un id que no pertenece a las ocho máquinas o un id repetido
- **THEN** el problema se reporta como advertencia de desarrollo y la partida arranca con el resto de filas válidas

#### Scenario: Registro ausente

- **WHEN** el índice de máquinas no existe o no se puede cargar
- **THEN** el arranque continúa sin datos de máquina, con advertencia, y ninguna operación de reparación o mejora se ejecuta

### Requirement: Consumo propio de la máquina

Cada máquina operativa SHALL consumir los recursos declarados en su lista de consumos. Una lista vacía significa que no consume nada. Una máquina apagada o averiada NO SHALL consumir. Los consumos SHALL aplicarse después de la producción y NO SHALL dejar ningún recurso por debajo de cero. Una cantidad negativa, un recurso desconocido o una entrada repetida NO SHALL alterar el estado: se tratan como cero o se ignoran.

#### Scenario: Consumo declarado

- **WHEN** una máquina está encendida y sana durante un tick
- **THEN** cada recurso de su lista de consumos se descuenta en la cantidad configurada

#### Scenario: Dato inválido en la ficha

- **WHEN** una entrada de consumo tiene cantidad negativa, un recurso desconocido o está repetida
- **THEN** el tick la sanea sin regalar ni corromper recursos y la validación lo reporta al arrancar

#### Scenario: Máquina sin consumos

- **WHEN** una máquina operativa tiene la lista de consumos vacía
- **THEN** no consume ningún recurso en ese tick

#### Scenario: Máquina apagada o averiada

- **WHEN** una máquina está apagada o averiada
- **THEN** no consume ningún recurso en ese tick

#### Scenario: Consumo de otro recurso

- **WHEN** una máquina declara un consumo de O₂, agua o comida y está operativa
- **THEN** ese recurso se descuenta en la cantidad configurada, sin quedar negativo

### Requirement: Reparación por divisiones

El juego SHALL permitir iniciar la reparación de una máquina dañada desde esa misma máquina. La reparación SHALL cobrar su coste de energía al iniciarse, SHALL requerir las divisiones de trabajo declaradas en la fila y SHALL restaurar la salud al máximo al completarse, registrando un único hecho de reparación. La velocidad de reparación del jugador SHALL acumular trabajo por tick. Las solicitudes inválidas SHALL rechazarse sin coste y una reparación iniciada NO SHALL cancelarse ni reembolsarse.

#### Scenario: Reparación completada

- **WHEN** una máquina dañada inicia una reparación con energía suficiente
- **THEN** la energía se descuenta al iniciar, el trabajo avanza cada tick y al completarse la salud vuelve al máximo y se registra un solo hecho

#### Scenario: Velocidad de reparación del jugador

- **WHEN** el jugador tiene una velocidad de reparación mayor que 1
- **THEN** cada tick acumula más de una división de trabajo y la reparación termina antes

#### Scenario: Energía insuficiente

- **WHEN** se intenta reparar una máquina sin energía suficiente para el coste
- **THEN** la reparación no se inicia, no se descuenta energía y la máquina conserva su estado

#### Scenario: Máquina sana o ya en reparación

- **WHEN** se intenta reparar una máquina con la salud al máximo o con una reparación en curso
- **THEN** la operación se rechaza sin coste y sin alterar el estado

#### Scenario: Progreso consultable

- **WHEN** una reparación está en curso
- **THEN** el estado expone que hay reparación y un progreso entre 0 y 1 que aumenta al avanzar los ticks

### Requirement: Mejoras de máquina

Cada mejora SHALL aplicarse como máximo una vez por máquina, SHALL cobrar su coste de energía y SHALL alterar la estadística que declara, sea de la máquina o del jugador. La aplicación SHALL rechazarse sin coste si la mejora ya está aplicada, si la máquina está averiada, si la energía no cubre el coste o si la máquina no puede expresar ese efecto. Cada aplicación SHALL registrar un hecho de mejora con la máquina y la mejora aplicada.

#### Scenario: Mejora aplicada

- **WHEN** se aplica una mejora válida sobre una máquina sana con energía suficiente
- **THEN** la energía se descuenta, la mejora queda registrada en la máquina y se anota un hecho de mejora

#### Scenario: Mejora incompatible

- **WHEN** una mejora declara un efecto que la máquina no puede expresar (por ejemplo, producción solar en el sistema de O₂)
- **THEN** la operación se rechaza sin coste y la validación de la ficha lo reporta

#### Scenario: Mejora repetida

- **WHEN** se intenta aplicar por segunda vez la misma mejora
- **THEN** la operación se rechaza sin coste y el estado no cambia

#### Scenario: Máquina averiada o sin energía

- **WHEN** se intenta aplicar una mejora sobre una máquina averiada o sin energía suficiente
- **THEN** la operación se rechaza sin coste y la mejora no queda aplicada

#### Scenario: Mejora de una estadística del jugador

- **WHEN** se aplica una mejora cuyo efecto pertenece al jugador
- **THEN** la estadística del jugador cambia y la máquina no recibe un campo de esa estadística

### Requirement: Efectos de las mejoras sobre el tick

Los deltas de las mejoras SHALL sumarse a los valores base de producción, consumo de energía y degradación de la máquina. El consumo y la degradación efectivos NO SHALL ser negativos. La producción efectiva SHALL seguir acotada por la capacidad del recurso. Varias mejoras que afecten a la misma estadística SHALL acumularse de forma aditiva. Si la máquina no declara consumo de energía, el consumo efectivo de una mejora `POWER_DRAW` SHALL calcularse desde una base de cero.

#### Scenario: Producción aumentada

- **WHEN** una mejora incrementa la producción de una máquina operativa
- **THEN** el tick añade la producción base más el delta de la mejora, sin superar la capacidad

#### Scenario: Consumo reducido

- **WHEN** una mejora reduce el consumo de energía de una máquina operativa
- **THEN** el tick descuenta el consumo efectivo, nunca por debajo de cero

#### Scenario: Consumo desde cero

- **WHEN** una mejora `POWER_DRAW` se aplica a una máquina sin entrada de energía
- **THEN** el consumo efectivo parte de cero y nunca es negativo

#### Scenario: Degradación reducida

- **WHEN** una mejora reduce la degradación de una máquina
- **THEN** la máquina pierde la degradación efectiva por tick, nunca un valor negativo

### Requirement: Estadísticas del jugador

El jugador SHALL tener velocidad de reparación, velocidad de movimiento, hambre máxima y sed máxima, con valores base procedentes de la economía. Las mejoras SHALL modificarlas de forma aditiva. La velocidad de reparación SHALL acelerar el trabajo de reparación por tick; hambre y sed máximas SHALL ampliar la reserva actual en la misma cantidad. La velocidad de movimiento SHALL quedar almacenada hasta que exista el astronauta. La radiación queda fuera de esta versión.

#### Scenario: Reparación más rápida

- **WHEN** una mejora aumenta la velocidad de reparación del jugador
- **THEN** la misma reparación requiere menos ticks que con el valor base

#### Scenario: Reserva ampliada

- **WHEN** una mejora aumenta el hambre o la sed máxima
- **THEN** el máximo y la reserva actual suben en la misma cantidad, sin superar el nuevo máximo

#### Scenario: Velocidad de movimiento almacenada

- **WHEN** una mejora aumenta la velocidad de movimiento
- **THEN** el valor queda en las estadísticas del jugador y no altera ninguna máquina

#### Scenario: Valores base desde economía

- **WHEN** se edita una fila base de las estadísticas del jugador
- **THEN** una partida nueva arranca con el nuevo valor sin cambios de código

### Requirement: Reinicio de máquinas y jugador

Un reinicio de partida SHALL dejar las ocho máquinas sanas, encendidas, sin reparación en curso y sin mejoras aplicadas, y SHALL devolver las estadísticas del jugador a sus valores base.

#### Scenario: Reinicio

- **WHEN** se reinicia una partida con reparaciones y mejoras aplicadas
- **THEN** las máquinas y las estadísticas del jugador quedan como en una partida nueva

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
