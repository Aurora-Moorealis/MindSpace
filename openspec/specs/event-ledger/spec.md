# event-ledger Specification

## Purpose
Define el ledger append-only que conserva los hechos de una partida y los convierte en los contadores que alimentan la pantalla de evaluación y el overlay de depuración.

## Requirements

### Requirement: Registro append-only

El ledger SHALL registrar cada hecho de partida como una entrada inmutable con tipo, tick y payload. Las entradas SHALL conservar el orden de inserción y no SHALL modificarse ni eliminarse durante la partida. Solo un reinicio de partida SHALL vaciarlo.

#### Scenario: Orden de inserción

- **WHEN** se registran varios hechos en una partida
- **THEN** las entradas se devuelven en el mismo orden en que se registraron

#### Scenario: Entrada inmutable

- **WHEN** un consumidor consulta las entradas del ledger
- **THEN** modificar la colección devuelta no altera el ledger interno

#### Scenario: Sin borrado durante la partida

- **WHEN** transcurren ticks y se registran hechos nuevos
- **THEN** las entradas anteriores siguen disponibles con su tipo, tick y payload originales

### Requirement: Catálogo de hechos tipados

El ledger SHALL aceptar al menos estos tipos de hecho: reparación, mejora, informe enviado, pico de radiación, uso de refugio, submisión completada, avería, apagón, sol completado, muerte y fin de partida. Un tipo desconocido SHALL rechazarse sin corromper el ledger existente.

#### Scenario: Hecho tipado

- **WHEN** se registra un informe enviado en el tick 42
- **THEN** la entrada conserva el tipo «informe enviado» y el tick 42

#### Scenario: Tipo desconocido

- **WHEN** se intenta registrar un tipo que no pertenece al catálogo
- **THEN** la entrada se rechaza y el ledger conserva sus entradas previas intactas

### Requirement: Payload de datos planos

El payload de cada entrada SHALL contener solo datos planos: números, strings, booleanos y colecciones de estos. No SHALL contener referencias a nodos, escenas, recursos cargados ni callables, para que pueda renderizarse en debug y derivar contadores.

#### Scenario: Payload válido

- **WHEN** se registra un hecho con números y strings
- **THEN** la entrada se guarda con el payload completo

#### Scenario: Payload inválido

- **WHEN** se intenta registrar un payload con una referencia a un nodo
- **THEN** la entrada se rechaza y el ledger no queda modificado

### Requirement: Contadores de evaluación

El ledger SHALL derivar cinco contadores de evaluación: informes enviados, submisiones completadas, recursos finales, pico de radiación y usos de refugio, y soles transcurridos. Los contadores SHALL recalcularse a partir de las entradas y coincidir con los hechos registrados.

#### Scenario: Informes y submisiones

- **WHEN** se han registrado tres informes enviados y una submisión completada
- **THEN** el resumen reporta 3 informes y 1 submisión

#### Scenario: Pico de radiación

- **WHEN** se registran varios picos de radiación
- **THEN** el resumen reporta el mayor valor registrado y cuenta los usos de refugio

#### Scenario: Recursos finales

- **WHEN** se registra el fin de partida con una instantánea de recursos
- **THEN** el resumen reporta esos recursos como los finales

#### Scenario: Soles transcurridos

- **WHEN** se han registrado dos hechos de sol completado
- **THEN** el resumen reporta 2 soles transcurridos

### Requirement: Consulta y depuración

El ledger SHALL permitir consultar todas las entradas, filtrarlas por tipo y contar entradas por tipo. La consulta SHALL ser de solo lectura y no SHALL alterar el estado del ledger.

#### Scenario: Filtro por tipo

- **WHEN** se consultan las entradas de tipo «informe enviado»
- **THEN** solo se devuelven las entradas de ese tipo

#### Scenario: Conteo por tipo

- **WHEN** se consulta el número de entradas de un tipo
- **THEN** el resultado coincide con las entradas registradas de ese tipo

### Requirement: Reinicio del ledger

El ledger SHALL exponer una operación de reinicio que vacíe todas las entradas y devuelva los contadores a cero. El reinicio SHALL ser la única operación que descarte hechos de una partida.

#### Scenario: Reinicio

- **WHEN** se reinicia el ledger con entradas previas
- **THEN** no quedan entradas y todos los contadores valen cero
