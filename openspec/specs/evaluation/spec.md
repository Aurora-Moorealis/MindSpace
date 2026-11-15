# evaluation Specification

## Purpose
Pantalla de fin de partida: presenta el resultado de la misión con los contadores
del ledger, la causa del fin y las acciones para volver a jugar o salir al menú.

## Requirements

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

### Requirement: Contadores del ledger

La pantalla SHALL mostrar cinco contadores tomados del ledger de la partida:
informes enviados, submisiones completadas, pico de radiación, usos del refugio
y soles transcurridos. Cada contador SHALL reflejar el valor del ledger en el
momento del fin y NO SHALL modificarlo.

#### Scenario: Contadores con actividad

- **WHEN** la partida termina tras acumular hechos de refugio, radiación y soles
- **THEN** los cinco contadores muestran los totales del ledger de esa partida

#### Scenario: Partida sin actividad

- **WHEN** la partida termina en el primer tick sin hechos de informe ni de refugio
- **THEN** los contadores correspondientes muestran cero y los soles muestran el valor real

#### Scenario: Solo lectura

- **WHEN** la pantalla muestra los contadores
- **THEN** el ledger conserva exactamente los mismos hechos que antes de abrirla

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

### Requirement: Recursos finales

La pantalla SHALL mostrar la reserva final de energía, oxígeno, agua y comida de
la partida terminada, leída del estado congelado.

#### Scenario: Recursos congelados

- **WHEN** la partida termina con unas reservas concretas
- **THEN** la pantalla muestra esas reservas y no cambian mientras permanezca abierta

### Requirement: Acciones de la evaluación

La pantalla SHALL ofrecer volver a jugar y volver al menú. Volver a jugar SHALL
empezar una partida nueva en el tick 0 y volver al menú SHALL cargar la pantalla
de entrada.

#### Scenario: Volver a jugar

- **WHEN** el jugador elige volver a jugar
- **THEN** la escena jugable arranca de nuevo en el tick 0 con el ledger vacío

#### Scenario: Volver al menú

- **WHEN** el jugador elige volver al menú
- **THEN** se carga la pantalla de entrada y el reloj queda pausado

### Requirement: Evaluación sin controles de partida

Con la pantalla de evaluación abierta, los controles de movimiento, interacción,
velocidad y pausa NO SHALL responder.

#### Scenario: Entrada bloqueada

- **WHEN** el jugador pulsa movimiento, interacción o velocidad con la evaluación abierta
- **THEN** el estado de la partida terminada no cambia

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
