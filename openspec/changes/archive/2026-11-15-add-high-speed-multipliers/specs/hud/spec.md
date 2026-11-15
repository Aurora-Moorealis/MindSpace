# Spec Delta

## MODIFIED Requirements

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

- **WHEN** la partida pasa a cualquiera de los multiplicadores x5, x10, x100, x1000 o x10000
- **THEN** el multiplicador del HUD cambia en el mismo momento

### Requirement: Límites de los controles de tiempo

Los botones de velocidad SHALL mover la velocidad un paso entre x1, x5, x10, x100,
x1000 y x10000 y NO SHALL salirse de ese rango. Los tres botones de tiempo SHALL
quedar deshabilitados con la partida terminada.

#### Scenario: Subir la velocidad

- **WHEN** el jugador pulsa el botón de subir velocidad en x1
- **THEN** la simulación pasa a x5 y el multiplicador del reloj lo refleja sin esperar a un tick

#### Scenario: Velocidad alta

- **WHEN** el jugador pulsa el botón de subir velocidad estando en x10
- **THEN** la simulación pasa a x100 y el multiplicador del reloj lo refleja sin esperar a un tick

#### Scenario: Velocidad al máximo

- **WHEN** el jugador pulsa el botón de subir velocidad estando en x10000
- **THEN** la velocidad sigue en x10000 y el HUD no muestra un valor fuera de rango

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** los tres botones de tiempo quedan deshabilitados
