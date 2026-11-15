# hud Specification

## Purpose
Define el HUD de partida: la barra de vida arriba, la tira de recursos y el Sol
en la parte superior, la hotbar de cinco espacios abajo, el objeto que el jugador
lleva en la mano y la forma de instanciar el conjunto en una escena de juego.

## Requirements

### Requirement: Composición del HUD de partida

El HUD SHALL mostrar la barra de vida centrada en la parte superior, la tira de
recursos pegada arriba a la izquierda y el texto del Sol arriba a la derecha,
sobre un lienzo de 850×480. La tira de recursos y el Sol SHALL dibujarse sin panel
de fondo. La hotbar SHALL quedar centrada en la parte inferior con cinco espacios
visibles y una separación uniforme. El HUD SHALL usar las texturas de interfaz
aprobadas, sin sustituirlas por formas dibujadas en tiempo de ejecución.

#### Scenario: Disposición en pantalla

- **WHEN** el HUD se muestra en una partida
- **THEN** la barra queda arriba y la hotbar abajo, ambas centradas, con los
  recursos a la izquierda y el Sol a la derecha, sin fondos que tapen el mundo

#### Scenario: Cinco espacios

- **WHEN** el jugador mira la hotbar
- **THEN** ve exactamente cinco espacios, con el mismo tamaño y separación

### Requirement: Barra de vida

La barra SHALL mostrar la salud actual y la salud máxima de la simulación. El
relleno SHALL ser proporcional a la salud y SHALL limitarse a los extremos cuando
el valor llegue a 0 o al máximo. La barra SHALL actualizarse al avanzar un tick y
al reiniciar la partida. Por debajo del 30 % de salud SHALL usar la variante de
aviso; por encima SHALL volver a la variante normal.

#### Scenario: Salud llena

- **WHEN** la salud está al máximo
- **THEN** la barra se ve completa y con la variante normal

#### Scenario: Salud baja

- **WHEN** la salud baja del 30 %
- **THEN** la barra usa la variante de aviso sin cambiar de tamaño ni de posición

#### Scenario: Salud a cero

- **WHEN** la salud llega a 0
- **THEN** la barra queda vacía y no muestra un relleno negativo

#### Scenario: Reinicio

- **WHEN** la partida se reinicia
- **THEN** la barra vuelve a mostrar la salud inicial de la nueva partida

### Requirement: Recursos de la base en el HUD

El HUD SHALL mostrar el oxígeno, el agua, la comida y la energía de la base como
cuatro barras compactas con su porcentaje visible, en una tira pegada arriba a la
izquierda y sin panel de fondo. El rango de cada barra SHALL ser la capacidad de
ese recurso en la economía de la partida. El relleno SHALL quedar entre vacío y
lleno aunque el valor real salga de ese rango. Las cuatro barras SHALL actualizarse
al avanzar un tick y al reiniciar la partida.

#### Scenario: Recurso a la mitad

- **WHEN** un recurso está al 50 % de su capacidad
- **THEN** su barra se ve a la mitad y el porcentaje muestra 50 %

#### Scenario: Recurso lleno

- **WHEN** un recurso alcanza su capacidad
- **THEN** la barra se ve completa y el porcentaje muestra 100 %

#### Scenario: Recurso por encima de la capacidad

- **WHEN** el valor de un recurso supera su capacidad
- **THEN** la barra no pasa del lleno y el porcentaje no supera 100 %

#### Scenario: Recurso vacío

- **WHEN** un recurso llega a 0
- **THEN** la barra se ve vacía y el porcentaje muestra 0 %

### Requirement: Reloj y velocidad

El HUD SHALL mostrar el sol actual, la fase de día o noche, la hora de juego y el
multiplicador de velocidad activo como una sola línea de texto fija en la parte
superior derecha, sin panel de fondo. El reloj SHALL actualizarse al avanzar un
tick y al cambiar la velocidad, sin esperar al siguiente tick.

#### Scenario: Primer sol

- **WHEN** empieza una partida nueva
- **THEN** el reloj muestra el sol 1, la fase de día y el multiplicador x1

#### Scenario: Cambio de fase

- **WHEN** el reloj cruza de día a noche
- **THEN** la fase del HUD cambia a noche y la hora sigue avanzando

#### Scenario: Cambio de velocidad

- **WHEN** la partida pasa a x5 o x10
- **THEN** el multiplicador del HUD cambia en el mismo momento

### Requirement: Hotbar enlazada al inventario

Cada espacio de la hotbar SHALL mostrar el objeto que el inventario tiene en ese
índice y SHALL quedar vacío cuando el inventario no tenga objeto. El espacio
activo SHALL distinguirse visualmente del resto sin tapar el icono del objeto ni
los tornillos del panel.

#### Scenario: Objeto en un espacio

- **WHEN** el inventario coloca un objeto en el espacio 2
- **THEN** la hotbar dibuja el icono de ese objeto en el espacio 2

#### Scenario: Espacio activo

- **WHEN** cambia el espacio activo
- **THEN** el marco de selección se mueve al nuevo espacio y el anterior vuelve a
  su aspecto normal

#### Scenario: Espacio vacío

- **WHEN** un espacio no tiene objeto
- **THEN** se ve el pozo vacío de la hotbar, sin icono

### Requirement: Objeto en la mano

Mientras el jugador lleva un objeto recogido, el HUD SHALL dibujar su icono junto
al puntero. El icono SHALL ocultarse al colocar o devolver el objeto y SHALL no
capturar clics ni bloquear la interacción con los espacios.

#### Scenario: Objeto recogido

- **WHEN** el jugador recoge un objeto de un espacio
- **THEN** el icono sigue al puntero hasta que se coloca o se devuelve

#### Scenario: Objeto colocado

- **WHEN** el jugador coloca el objeto en un espacio
- **THEN** el icono junto al puntero desaparece

### Requirement: Instanciación y entrada

El HUD SHALL poder añadirse como una sola sub-escena a cualquier escena de
partida sin cambiar su disposición. El HUD SHALL permanecer fijo aunque la cámara
del mundo se mueva y SHALL dejar pasar el ratón al mundo fuera de los cinco
espacios. Las teclas 1 a 5 y la rueda del ratón SHALL cambiar el espacio activo
sin requerir configuración adicional de entrada.

#### Scenario: HUD sobre una cámara en movimiento

- **WHEN** la cámara del mundo se desplaza
- **THEN** la barra y la hotbar siguen en la misma posición de pantalla

#### Scenario: Clic fuera de la hotbar

- **WHEN** el jugador hace clic en una zona del HUD que no es un espacio
- **THEN** el clic llega al mundo y no cambia el inventario

#### Scenario: Cambio de espacio con el teclado

- **WHEN** el HUD está en pantalla y el jugador pulsa una tecla del 1 al 5
- **THEN** el espacio correspondiente pasa a ser el activo

### Requirement: Indicador de interacción

El HUD SHALL mostrar un aviso cuando el astronauta tenga una máquina interactuable
en rango, con la tecla de interacción y el nombre de esa máquina. El aviso NO SHALL
mostrarse sin objetivo, con el input del astronauta bloqueado por un panel modal, ni
con la partida terminada. El aviso SHALL reevaluarse cada frame, porque el bloqueo de
input no emite señal.

#### Scenario: Máquina en rango

- **WHEN** el astronauta entra en el radio de interacción de una máquina
- **THEN** el HUD muestra el aviso con la tecla y el nombre de esa máquina

#### Scenario: Salir del rango

- **WHEN** el astronauta se aleja hasta perder el objetivo
- **THEN** el aviso desaparece sin dejar texto del objetivo anterior

#### Scenario: Panel abierto

- **WHEN** el jugador abre el panel de una máquina y el astronauta queda con el input bloqueado
- **THEN** el aviso de interacción se oculta aunque el objetivo siga en rango

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** el aviso no se muestra

### Requirement: Controles de tiempo

El HUD SHALL ofrecer un botón de pausa/reanudar y dos botones para bajar y subir la
velocidad de la simulación, además del multiplicador que ya muestra el reloj. El
botón de pausa SHALL alternar `GameSim.set_paused()` y su texto SHALL indicar la
acción disponible (`Pause` cuando corre, `Resume` cuando está pausada). Las acciones
de teclado `pause`, `speed_up` y `speed_down` SHALL seguir disponibles.

#### Scenario: Pausar desde el HUD

- **WHEN** el jugador pulsa el botón de pausa con la partida corriendo
- **THEN** la simulación se pausa y el botón pasa a mostrar `Resume` en el mismo frame

#### Scenario: Reanudar desde el HUD

- **WHEN** el jugador pulsa el botón de pausa con la partida pausada
- **THEN** la simulación se reanuda y el botón vuelve a mostrar `Pause`

#### Scenario: Estado inicial del botón

- **WHEN** la escena jugable termina de cargar
- **THEN** el botón de pausa muestra `Pause`, porque la simulación ya está corriendo

### Requirement: Límites de los controles de tiempo

Los botones de velocidad SHALL mover la velocidad un paso entre x1, x5 y x10 y NO
SHALL salirse de ese rango. Los tres botones de tiempo SHALL quedar deshabilitados
con la partida terminada.

#### Scenario: Subir la velocidad

- **WHEN** el jugador pulsa el botón de subir velocidad en x1
- **THEN** la simulación pasa a x5 y el multiplicador del reloj lo refleja sin esperar a un tick

#### Scenario: Velocidad al máximo

- **WHEN** el jugador pulsa el botón de subir velocidad estando en x10
- **THEN** la velocidad sigue en x10 y el HUD no muestra un valor fuera de rango

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** los tres botones de tiempo quedan deshabilitados

### Requirement: Indicador del objetivo de misión

El HUD SHALL mostrar, bajo la barra de vida y en la parte superior central, un
indicador con el objetivo de misión vigente y las horas de misión restantes. El
texto SHALL proceder de la tabla de strings y NO SHALL tapar la barra de vida,
la tira de recursos ni el reloj. El indicador SHALL actualizarse al avanzar un
tick y al reiniciar la partida, y NO SHALL mostrarse cuando la partida haya
terminado.

#### Scenario: Inicio de la misión

- **WHEN** empieza una partida nueva
- **THEN** el indicador muestra el objetivo de supervivencia y la duración completa de la misión

#### Scenario: Avance de un tick

- **WHEN** transcurre un tick de juego
- **THEN** las horas de misión restantes del indicador bajan en una

#### Scenario: Reinicio

- **WHEN** el jugador vuelve a jugar después de una partida terminada
- **THEN** el indicador vuelve a mostrar la duración completa de la misión

#### Scenario: Partida terminada

- **WHEN** la partida termina por muerte o por reloj de misión
- **THEN** el indicador se oculta junto con el resto del HUD
