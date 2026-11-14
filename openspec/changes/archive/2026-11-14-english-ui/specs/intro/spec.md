# Spec Delta

## MODIFIED Requirements

### Requirement: Historia por partes

La historia SHALL presentarse en siete partes, una por pantalla y en el orden
escrito, avanzando solo cuando el jugador pulse la acción de continuar.

#### Scenario: Avanzar

- **WHEN** el jugador pulsa la acción de continuar
- **THEN** aparece la siguiente parte de la historia

#### Scenario: Orden de las partes

- **WHEN** se recorre la historia completa
- **THEN** las partes aparecen en el orden: aviso, pregunta desde la Tierra, tu misión, preparativos, Aurora, llegada y primer paso

### Requirement: Saltar la animación

Durante la animación SHALL existir una acción para saltarla y pasar directamente
a la historia.

#### Scenario: Saltar

- **WHEN** el jugador pulsa la acción de saltar mientras se reproduce la animación
- **THEN** la animación termina y aparece la primera parte de la historia

### Requirement: Aceptar la misión

La última parte SHALL ofrecer la acción de aceptar la misión, y aceptarla SHALL
confirmar la misión del mundo elegido.

#### Scenario: Aceptar

- **WHEN** el jugador pulsa la acción de aceptar en la última parte
- **THEN** aparece una confirmación que nombra al mundo elegido

#### Scenario: Volver atrás

- **WHEN** el jugador cancela la introducción
- **THEN** el juego regresa a la pantalla de mundos
