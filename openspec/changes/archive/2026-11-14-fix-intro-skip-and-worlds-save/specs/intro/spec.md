# Spec Delta

## MODIFIED Requirements

### Requirement: Saltar la animación

Durante la animación SHALL existir una acción para saltarla y pasar directamente
a la historia. Al saltar, la animación pendiente SHALL detenerse y la historia
SHALL permanecer en la parte que el jugador esté viendo: ni el final del tween
en curso ni el resto de la secuencia SHALL reiniciarla o retrocederla.

#### Scenario: Saltar

- **WHEN** el jugador pulsa la acción de saltar mientras se reproduce la animación
- **THEN** la animación termina y aparece la primera parte de la historia

#### Scenario: El progreso se conserva

- **WHEN** el jugador salta la animación, avanza a una parte posterior y el tween pendiente termina
- **THEN** la historia sigue en esa parte posterior y no vuelve a la primera

#### Scenario: Salto durante un fundido

- **WHEN** el jugador salta mientras la pantalla se está fundiendo a negro
- **THEN** el fundido se cancela y la historia se ve con claridad
