# Spec Delta

## ADDED Requirements

### Requirement: Resultado de la misión

La pantalla de evaluación SHALL mostrar el resultado de la partida con un texto
propio de la tabla de strings: uno para la victoria y otro para la derrota. El
resultado mostrado SHALL coincidir con el desenlace congelado de la partida y NO
SHALL cambiar mientras la pantalla permanezca abierta.

#### Scenario: Victoria

- **WHEN** la partida termina con el astronauta vivo al agotarse el reloj de misión
- **THEN** la pantalla muestra el texto de victoria de la tabla de strings

#### Scenario: Derrota

- **WHEN** la partida termina por la muerte del astronauta antes del final
- **THEN** la pantalla muestra el texto de derrota de la tabla de strings

#### Scenario: Resultado congelado

- **WHEN** la pantalla de evaluación permanece abierta tras una victoria
- **THEN** el resultado sigue siendo victoria y no cambia a derrota

## MODIFIED Requirements

### Requirement: Apertura al terminar la partida

La pantalla de evaluación SHALL abrirse cuando la partida termina, sea por
muerte del astronauta, por agotarse el reloj de misión o por un fin de misión
forzado, y NO SHALL abrirse mientras la partida siga viva.

#### Scenario: Muerte

- **WHEN** el último tick deja la salud en 0
- **THEN** la pantalla de evaluación se abre sobre la escena jugable congelada

#### Scenario: Victoria por reloj de misión

- **WHEN** el reloj de misión se agota con el astronauta vivo
- **THEN** la pantalla de evaluación se abre sobre la escena jugable congelada

#### Scenario: Fin forzado

- **WHEN** el jugador usa el control de depuración de fin de misión
- **THEN** la pantalla de evaluación se abre igual que en una muerte

#### Scenario: Partida viva

- **WHEN** la partida sigue en curso
- **THEN** la pantalla de evaluación no aparece

### Requirement: Causa del fin de la partida

La pantalla SHALL mostrar la causa que terminó la partida en texto legible para
el jugador. En una victoria, la causa SHALL indicar que se completó el reloj de
misión.

#### Scenario: Causa por muerte

- **WHEN** la partida termina por radiación, asfixia, deshidratación o inanición
- **THEN** la pantalla muestra la causa correspondiente en inglés

#### Scenario: Causa por victoria

- **WHEN** la partida termina por agotarse el reloj de misión con el astronauta vivo
- **THEN** la pantalla muestra que la misión se completó y no una causa de muerte

#### Scenario: Causa forzada

- **WHEN** la partida termina por el control de depuración
- **THEN** la pantalla muestra que el fin fue forzado
