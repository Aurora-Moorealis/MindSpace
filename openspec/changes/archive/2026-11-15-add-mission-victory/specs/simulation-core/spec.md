# Spec Delta

## ADDED Requirements

### Requirement: Reloj de misión y desenlace

El núcleo SHALL declarar el final de la partida cuando el contador de ticks
alcance la duración de misión configurada. Si el astronauta sigue vivo en ese
momento, la partida SHALL terminar en victoria; si la salud llegó a 0 antes,
SHALL terminar en derrota. El desenlace SHALL registrarse una sola vez y, tras
declarado, el reloj de partida SHALL quedar detenido y NO SHALL registrarse
hechos de juego nuevos.

#### Scenario: Supervivencia completa

- **WHEN** transcurre el tick que alcanza la duración de misión con la salud por encima de 0
- **THEN** la partida termina en victoria y el desenlace queda registrado una sola vez

#### Scenario: Muerte antes del final

- **WHEN** la salud llega a 0 antes de alcanzar la duración de misión
- **THEN** la partida termina en derrota y el resultado no cambia después

#### Scenario: Muerte en el último tick

- **WHEN** el tick que alcanza la duración de misión deja la salud en 0
- **THEN** la partida termina en derrota, porque la muerte tiene prioridad sobre la victoria

#### Scenario: Sin ticks posteriores

- **WHEN** la partida ya terminó por reloj de misión o por muerte
- **THEN** los ticks posteriores no consumen recursos ni registran hechos de juego
