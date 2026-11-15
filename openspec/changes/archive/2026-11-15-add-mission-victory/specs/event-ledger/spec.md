# Spec Delta

## ADDED Requirements

### Requirement: Resultado en el hecho de fin de partida

El hecho de fin de partida SHALL incluir en su payload el resultado de la
partida, victoria o derrota, junto a la instantánea de recursos finales. El
resultado SHALL ser un valor plano y SHALL coincidir con el desenlace que
muestra la pantalla de evaluación.

#### Scenario: Victoria registrada

- **WHEN** la partida termina en victoria por agotarse el reloj de misión
- **THEN** el hecho de fin de partida incluye el resultado de victoria y los recursos finales

#### Scenario: Derrota registrada

- **WHEN** la partida termina por la muerte del astronauta
- **THEN** el hecho de fin de partida incluye el resultado de derrota y los recursos finales

#### Scenario: Un solo hecho de fin

- **WHEN** una partida termina
- **THEN** el ledger conserva un único hecho de fin de partida para ese run
