# game-session Specification

## Purpose
Ciclo de vida de una partida jugable: inicio limpio al entrar al mundo, reloj
activo solo durante el juego, exposición exterior en la superficie lunar y
congelación al terminar la partida.

## Requirements

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

### Requirement: Reloj activo solo durante la partida

El reloj de simulación SHALL permanecer pausado en el menú, la selección de
mundos y la introducción, sin producir ticks ni hechos. SHALL activarse al
entrar en la escena jugable y SHALL avanzar a la velocidad seleccionada
mientras la partida esté viva.

#### Scenario: Menús e introducción

- **WHEN** el jugador permanece 120 segundos reales en el menú o en la introducción
- **THEN** el contador de ticks no cambia y el ledger sigue vacío

#### Scenario: Partida en curso

- **WHEN** transcurren 60 segundos reales en la escena jugable con el reloj a ×1
- **THEN** el contador de ticks avanza exactamente 1

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

### Requirement: Fin de la escena jugable

Al salir de la escena jugable, el reloj SHALL pausarse y la exposición exterior
SHALL desactivarse, de modo que ninguna escena posterior siga consumiendo
recursos ni radiación.

#### Scenario: Volver a una escena no jugable

- **WHEN** la escena jugable se descarga
- **THEN** el reloj queda pausado y la marca de exterior queda desactivada

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
