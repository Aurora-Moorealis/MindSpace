# Spec Delta

## REMOVED Requirements

### Requirement: Arranque en el menú

El juego SHALL arrancar en la pantalla de entrada sin intervención del jugador.

#### Scenario: Arranque limpio

- **WHEN** el ejecutable del juego arranca
- **THEN** se muestra la pantalla de entrada con su fondo y su título, sin pasar por ninguna otra escena

## ADDED Requirements

### Requirement: Arranque en la partida

El juego SHALL arrancar en la escena jugable del outpost sin intervención del
jugador. El menú de entrada NO SHALL ser la primera pantalla y SHALL seguir siendo
accesible desde la evaluación de la misión.

#### Scenario: Arranque limpio

- **WHEN** el ejecutable del juego arranca
- **THEN** se muestra la escena jugable con el outpost y el HUD, sin pasar por el menú

#### Scenario: Vuelta al menú

- **WHEN** el jugador elige volver al menú desde la evaluación de la misión
- **THEN** se muestra la pantalla de entrada y desde ella se puede iniciar el flujo de mundos
