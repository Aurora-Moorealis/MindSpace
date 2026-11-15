# Spec Delta

## MODIFIED Requirements

### Requirement: Indicador del objetivo de misión

El HUD SHALL mostrar, en la parte superior derecha y debajo del reloj y de sus
controles de tiempo, un indicador alineado a la derecha con el objetivo de misión
vigente y las horas de misión restantes. El texto SHALL proceder de la tabla de
strings y NO SHALL tapar la barra de vida, la tira de recursos, el reloj ni los
controles de tiempo. El indicador SHALL actualizarse al avanzar un tick y al
reiniciar la partida, y NO SHALL mostrarse cuando la partida haya terminado.

#### Scenario: Inicio de la misión

- **WHEN** empieza una partida nueva
- **THEN** el indicador muestra el objetivo de supervivencia y la duración completa de la misión

#### Scenario: Avance de un tick

- **WHEN** transcurre un tick de juego
- **THEN** las horas de misión restantes del indicador bajan en una

#### Scenario: Reinicio

- **WHEN** el jugador vuelve a jugar después de una partida terminada
- **THEN** el indicador vuelve a mostrar la duración completa de la misión

#### Scenario: Posición en pantalla

- **WHEN** el HUD se muestra en una partida
- **THEN** el indicador queda en la esquina superior derecha, debajo del reloj y de los controles de tiempo, sin taparlos

#### Scenario: Partida terminada

- **WHEN** la partida termina por muerte o por reloj de misión
- **THEN** el indicador se oculta junto con el resto del HUD
