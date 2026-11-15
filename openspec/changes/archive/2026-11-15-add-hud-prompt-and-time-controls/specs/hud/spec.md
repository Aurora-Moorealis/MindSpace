# Spec Delta

## ADDED Requirements

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
