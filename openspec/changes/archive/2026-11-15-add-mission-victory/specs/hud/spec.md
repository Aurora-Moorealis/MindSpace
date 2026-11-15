# Spec Delta

## ADDED Requirements

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
