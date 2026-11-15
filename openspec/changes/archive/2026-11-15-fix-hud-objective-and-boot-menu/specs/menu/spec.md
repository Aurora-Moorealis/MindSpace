# Spec Delta

## REMOVED Requirements

### Requirement: Arranque en la partida

**Reason**: El arranque directo al outpost se introdujo para conectar el loop
jugable, pero oculta el menú principal y el flujo de selección de mundo. La
prueba de la build confirma que el jugador debe empezar en la pantalla de
entrada.

**Migration**: `game/project.godot` vuelve a
`res://scenes/welcome/welcome.tscn`. El botón "Start game" del menú sigue
navegando a `res://scenes/worlds/worlds.tscn`, y desde ahí se elige mundo,
intro y outpost.

## ADDED Requirements

### Requirement: Arranque en el menú

El juego SHALL arrancar en la pantalla de entrada y NO SHALL entrar directamente
en el outpost. El menú SHALL ofrecer la acción de iniciar partida para entrar en
el flujo de selección de mundo.

#### Scenario: Arranque limpio

- **WHEN** el ejecutable del juego arranca
- **THEN** se muestra la pantalla de entrada con el título y las acciones, no el outpost

#### Scenario: Inicio del flujo

- **WHEN** el jugador activa "Start game" en el menú
- **THEN** se abre la pantalla de selección de mundo
