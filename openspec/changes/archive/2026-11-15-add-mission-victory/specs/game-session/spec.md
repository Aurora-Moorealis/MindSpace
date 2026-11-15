# Spec Delta

## MODIFIED Requirements

### Requirement: Inicio de partida nueva

Al abrirse la escena jugable, el juego SHALL reiniciar el estado de la
simulación y el ledger antes de activar el reloj, de modo que cada entrada al
mundo empiece en el tick 0, con el reloj de misión completo, el resultado de
misión en curso, los recursos iniciales de la economía, las máquinas en su
estado inicial y sin hechos anteriores.

#### Scenario: Primera entrada al mundo

- **WHEN** la escena jugable termina de cargar
- **THEN** el tick vale 0, el ledger está vacío, el reloj de misión está completo y los recursos y las máquinas tienen sus valores iniciales

#### Scenario: Entrada después de otra partida

- **WHEN** el jugador vuelve al mundo después de haber jugado antes
- **THEN** la partida empieza de nuevo en el tick 0 y el ledger no conserva hechos de la partida anterior

#### Scenario: Reinicio tras una victoria

- **WHEN** el jugador vuelve a jugar después de ganar
- **THEN** el reloj de misión vuelve a su duración completa y el resultado queda en curso

### Requirement: Congelación al terminar la partida

Cuando la salud llegue a 0, el reloj de misión se agote o el jugador fuerce el
fin de misión, el reloj SHALL pausarse, la partida SHALL congelarse y no SHALL
producirse ticks ni hechos nuevos. El astronauta SHALL dejar de responder al
movimiento y la pantalla de evaluación SHALL abrirse con el resultado de la
partida.

#### Scenario: Muerte

- **WHEN** un tick deja la salud en 0
- **THEN** la partida queda marcada como terminada, el reloj queda pausado y se abre la evaluación

#### Scenario: Victoria por reloj de misión

- **WHEN** el reloj de misión alcanza su duración con el astronauta vivo
- **THEN** el reloj queda pausado, la partida queda congelada, el astronauta deja de responder y la evaluación muestra la victoria

#### Scenario: Después de la muerte

- **WHEN** transcurren 120 segundos reales tras la muerte
- **THEN** el tick no cambia, no aparecen hechos nuevos y el astronauta no se mueve

#### Scenario: Fin de partida registrado

- **WHEN** la partida termina
- **THEN** el ledger conserva un hecho de fin de partida con la causa, el resultado y el tick final
