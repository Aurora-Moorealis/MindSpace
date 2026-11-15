# Spec Delta

## MODIFIED Requirements

### Requirement: Exposición exterior en la superficie

Mientras la escena jugable esté activa, la dosis de radiación SHALL crecer solo
cuando el estado de la partida sea exterior. Cada tick exterior SHALL sumar la
dosis configurada y SHALL registrar el pico cuando la dosis crezca; los ticks
interiores NO SHALL sumar dosis.

#### Scenario: Dosis por tick

- **WHEN** transcurren cinco ticks exteriores partiendo de una dosis de 0
- **THEN** la dosis acumulada es la suma de cinco veces la fila `radiation_per_tick_exterior`

#### Scenario: Pico registrado

- **WHEN** la dosis exterior supera el pico anterior
- **THEN** el ledger registra un hecho de pico de radiación con el nuevo valor

#### Scenario: Tick interior

- **WHEN** el astronauta pasa un tick dentro del refugio
- **THEN** la dosis no crece

### Requirement: Congelación al terminar la partida

Cuando la salud llegue a 0 o el jugador fuerce el fin de misión, el reloj SHALL
pausarse, la partida SHALL congelarse y no SHALL producirse ticks ni hechos
nuevos. El astronauta SHALL dejar de responder al movimiento y la pantalla de
evaluación SHALL abrirse con el resultado de la partida.

#### Scenario: Muerte

- **WHEN** un tick deja la salud en 0
- **THEN** la partida queda marcada como terminada, el reloj queda pausado y se abre la evaluación

#### Scenario: Después de la muerte

- **WHEN** transcurren 120 segundos reales tras la muerte
- **THEN** el tick no cambia, no aparecen hechos nuevos y el astronauta no se mueve

#### Scenario: Fin de partida registrado

- **WHEN** la partida termina
- **THEN** el ledger conserva un hecho de fin de partida con la causa y el tick final

## ADDED Requirements

### Requirement: Fin de misión forzado de depuración

El juego SHALL ofrecer un control de depuración que termine la misión en el acto.
El control SHALL existir solo en compilaciones de depuración, NO SHALL mostrarse
al jugador final y al activarlo SHALL terminar la partida con una causa propia de
fin forzado, pausar el reloj y abrir la evaluación.

#### Scenario: Forzar el fin

- **WHEN** el jugador activa el control de depuración durante una partida viva
- **THEN** la partida termina de inmediato con causa forzada y se abre la evaluación

#### Scenario: Compilación de release

- **WHEN** el juego se ejecuta en una compilación de release
- **THEN** el control de fin forzado no aparece

#### Scenario: Partida ya terminada

- **WHEN** el control se activa con la partida ya terminada
- **THEN** no se registra un segundo fin ni cambia el resultado mostrado
