# Spec Delta

## MODIFIED Requirements

### Requirement: HUD superpuesto sin bloquear el juego

El HUD SHALL ser una capa de solo lectura sobre la simulación: NO SHALL capturar el
movimiento ni la interacción del astronauta, y solo los espacios de la hotbar, el
objeto en la mano y los tres botones de tiempo SHALL consumir clics o pulsaciones.
El resto del HUD SHALL dejar pasar el ratón al mundo. Con la partida terminada el HUD
SHALL ocultarse y SHALL volver a mostrarse al empezar una partida nueva.

#### Scenario: Movimiento con el HUD visible

- **WHEN** el jugador mueve al astronauta con el HUD en pantalla
- **THEN** el movimiento y la interacción funcionan igual que sin HUD

#### Scenario: Clic fuera de un control

- **WHEN** el jugador hace clic en una zona del HUD que no es un espacio de la hotbar ni un botón de tiempo
- **THEN** el clic no cambia el estado de la partida

#### Scenario: Clic en un control de tiempo

- **WHEN** el jugador hace clic en un botón de pausa o de velocidad
- **THEN** la partida cambia ese ajuste y el clic no llega al mundo

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** el HUD se oculta y la evaluación queda visible sin nada encima

#### Scenario: Partida nueva

- **WHEN** el jugador reinicia la misión desde la evaluación
- **THEN** el HUD vuelve a mostrarse con los valores de la partida nueva
