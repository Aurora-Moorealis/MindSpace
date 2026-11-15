# Spec Delta

## MODIFIED Requirements

### Requirement: Zona interior y exterior

El astronauta SHALL marcar el estado como exterior al entrar en un área del grupo
`exterior_zones`, como interior al entrar en un área del grupo `shelter_zones` y
como interior al salir de un área de exterior. La superficie NO cubierta por un
refugio SHALL contar como exterior aunque el astronauta no esté dentro de ninguna
zona de exterior, y un refugio SHALL prevalecer sobre una zona de exterior
solapada. La simulación SHALL usar ese estado para acumular o no dosis de
radiación.

#### Scenario: Entrar al exterior

- **WHEN** el astronauta entra en una zona de exterior sin refugio
- **THEN** el estado de simulación pasa a exterior y los ticks siguientes suman dosis

#### Scenario: Volver al interior

- **WHEN** el astronauta sale de la zona de exterior y no está en un refugio
- **THEN** el estado vuelve a interior y la dosis deja de crecer

#### Scenario: Superficie sin zonas

- **WHEN** el astronauta camina por la superficie fuera de toda zona de exterior y de todo refugio
- **THEN** el estado es exterior y la dosis sigue creciendo

#### Scenario: Entrar en el refugio

- **WHEN** el astronauta entra en un área de refugio
- **THEN** el estado pasa a interior y la dosis deja de crecer aunque el área esté dentro de una zona de exterior

#### Scenario: Refugio y exterior solapados

- **WHEN** el astronauta está a la vez dentro de un refugio y de una zona de exterior
- **THEN** prevalece el refugio y el estado es interior

#### Scenario: Reinicio

- **WHEN** la partida se reinicia con el astronauta dentro del refugio
- **THEN** el estado de la partida nueva pasa a interior en el primer tick y la dosis no crece
