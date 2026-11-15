# game-session Specification

## Purpose
Ciclo de vida de una partida jugable: inicio limpio al entrar al mundo, reloj
activo solo durante el juego, exposición exterior en la superficie lunar y
congelación al terminar la partida.

## Requirements

### Requirement: Inicio de partida nueva

Al abrirse la escena jugable, el juego SHALL reiniciar el estado de la
simulación y el ledger antes de activar el reloj, de modo que cada entrada al
mundo empiece en el tick 0, con los recursos iniciales de la economía, las
máquinas en su estado inicial y sin hechos anteriores.

#### Scenario: Primera entrada al mundo

- **WHEN** la escena jugable termina de cargar
- **THEN** el tick vale 0, el ledger está vacío y los recursos y las máquinas tienen sus valores iniciales

#### Scenario: Entrada después de otra partida

- **WHEN** el jugador vuelve al mundo después de haber jugado antes
- **THEN** la partida empieza de nuevo en el tick 0 y el ledger no conserva hechos de la partida anterior

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

Mientras la escena jugable esté activa, el astronauta SHALL considerarse fuera
de la base: cada tick SHALL sumar la dosis de radiación exterior configurada y
SHALL registrar el pico cuando la dosis crezca.

#### Scenario: Dosis por tick

- **WHEN** transcurren cinco ticks en la escena jugable partiendo de una dosis de 0
- **THEN** la dosis acumulada es la suma de cinco veces la fila `radiation_per_tick_exterior`

#### Scenario: Pico registrado

- **WHEN** la dosis exterior supera el pico anterior
- **THEN** el ledger registra un hecho de pico de radiación con el nuevo valor

### Requirement: Congelación al terminar la partida

Cuando la salud llegue a 0, el reloj SHALL pausarse, la partida SHALL congelarse
y no SHALL producirse ticks ni hechos nuevos. El astronauta SHALL dejar de
responder al movimiento. Esta versión no SHALL mostrar una pantalla de
evaluación.

#### Scenario: Muerte

- **WHEN** un tick deja la salud en 0
- **THEN** la partida queda marcada como terminada y el reloj queda pausado

#### Scenario: Después de la muerte

- **WHEN** transcurren 120 segundos reales después de la muerte
- **THEN** el tick no cambia, no aparecen hechos nuevos y el astronauta no se mueve

### Requirement: Fin de la escena jugable

Al salir de la escena jugable, el reloj SHALL pausarse y la exposición exterior
SHALL desactivarse, de modo que ninguna escena posterior siga consumiendo
recursos ni radiación.

#### Scenario: Volver a una escena no jugable

- **WHEN** la escena jugable se descarga
- **THEN** el reloj queda pausado y la marca de exterior queda desactivada
