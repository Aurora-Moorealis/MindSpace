# simulation-core Specification

## Purpose
Define el comportamiento observable del núcleo que hace avanzar la partida: el reloj por ticks, la economía data-driven, los recursos, la radiación y la escalera de consecuencias que lleva a la muerte o al fin de la misión.

## Requirements

### Requirement: Reloj determinista por ticks

El núcleo SHALL avanzar el estado del juego únicamente mediante ticks discretos. Un tick representa 1 hora de juego y ocurre cada 60 segundos reales a ×1. Los multiplicadores ×1/×5/×10 SHALL modificar solo la frecuencia del tick, nunca la escala temporal del motor. La pausa SHALL detener los ticks sin detener la interfaz.

#### Scenario: Avance a velocidad base

- **WHEN** transcurren 60 segundos reales con el reloj a ×1
- **THEN** el contador de ticks avanza exactamente 1 y la hora de juego avanza 1

#### Scenario: Multiplicadores de velocidad

- **WHEN** el reloj está a ×5 y transcurren 12 segundos reales
- **THEN** el contador de ticks avanza exactamente 1
- **WHEN** el reloj está a ×10 y transcurren 6 segundos reales
- **THEN** el contador de ticks avanza exactamente 1

#### Scenario: Pausa

- **WHEN** la partida está en pausa y transcurren 120 segundos reales
- **THEN** el contador de ticks no cambia
- **WHEN** se reanuda la partida
- **THEN** los ticks vuelven a avanzar a la velocidad seleccionada

#### Scenario: Determinismo

- **WHEN** dos partidas arrancan del mismo estado y aplican la misma secuencia de ticks
- **THEN** los recursos, la salud, la radiación, las máquinas y los hechos registrados son idénticos

### Requirement: Economía dirigida por datos

Todos los números de gameplay (consumos, producción, capacidades, stocks iniciales, umbrales y reservas) SHALL proceder de filas de economía editables, no de constantes del código. Cada fila MUST declarar su procedencia mediante `source`, `source_url`, `date_archived`, `archived` y `real_data`. Un valor ausente o fuera de rango SHALL sustituirse por un default seguro y quedar registrado como advertencia de desarrollo.

#### Scenario: Cambio de una fila

- **WHEN** se edita el consumo de O₂ por tick en la economía
- **THEN** el núcleo consume el nuevo valor sin cambios de código

#### Scenario: Fila no verificada

- **WHEN** una fila tiene `real_data: false`
- **THEN** el estado expone ese indicador para que la UI lo muestre como simulado

#### Scenario: Valor inválido

- **WHEN** una fila falta o contiene un valor fuera de su rango permitido
- **THEN** el núcleo usa el default seguro y no corrompe el estado de la partida

### Requirement: Pipeline de tick en orden fijo

Cada tick SHALL ejecutar, en este orden: producción, consumos, degradación pasiva y escalera de consecuencias. Las etapas de eventos y submisiones SHALL existir como puntos de extensión inertes en este cambio. El resultado de un tick SHALL depender solo del estado de entrada y de las filas de economía.

#### Scenario: Mismo estado, mismo resultado

- **WHEN** se ejecuta un tick dos veces desde copias idénticas del estado
- **THEN** ambas ejecuciones producen los mismos valores y los mismos hechos

#### Scenario: Etapas inertes

- **WHEN** no hay eventos ni submisiones configuradas
- **THEN** el tick completa las etapas implementadas sin alterar recursos por eventos o submisiones

### Requirement: Producción y consumo de recursos

En cada tick el núcleo SHALL producir y consumir O₂, agua, comida y energía según la economía y el estado de las máquinas. Los recursos SHALL mantenerse dentro de `[0, capacidad]`. El consumo SHALL aplicarse después de la producción.

#### Scenario: Producción solar de día

- **WHEN** el tick ocurre en fase de día y el panel solar está operativo
- **THEN** la energía producida se suma a la batería hasta su capacidad

#### Scenario: Consumo de soporte vital

- **WHEN** transcurre un tick con la tripulación viva
- **THEN** O₂, agua, comida y energía disminuyen según las filas de consumo aplicables

#### Scenario: Recursos acotados

- **WHEN** una producción excede la capacidad de un recurso
- **THEN** el recurso queda en su capacidad máxima
- **WHEN** un consumo excede el stock disponible
- **THEN** el recurso queda en 0, nunca en negativo

### Requirement: Escalera de consecuencias vitales

Cuando un recurso vital llega a cero, el núcleo SHALL aplicar la escalera fija: O₂ a cero consume primero la reserva de traje de 60 minutos y después mata; hambre o sed al 0% causan daño progresivo; salud a 0 termina la partida. La muerte SHALL registrarse una sola vez por partida.

#### Scenario: O₂ agotado

- **WHEN** el O₂ de la base llega a 0 y queda reserva de traje
- **THEN** la reserva de traje se consume antes de aplicar daño a la salud
- **WHEN** el O₂ y la reserva de traje llegan a 0
- **THEN** la salud cae hasta 0 y la partida termina

#### Scenario: Hambre o sed

- **WHEN** el hambre o la sed alcanzan 0%
- **THEN** la salud recibe daño progresivo por tick

#### Scenario: Muerte única

- **WHEN** la salud llega a 0
- **THEN** se registra el fin de partida una sola vez aunque sigan ejecutándose ticks

### Requirement: Apagado por falta de energía

Si la energía disponible es 0, el núcleo SHALL apagar máquinas en orden fijo: luces → hidropónica → reciclador → sistema de O₂. Una máquina apagada SHALL dejar de consumir energía y de producir. El orden SHALL ser independiente del orden de inserción de las máquinas.

#### Scenario: Apagón

- **WHEN** la energía llega a 0
- **THEN** las luces se apagan primero y el sistema de O₂ es el último en apagarse

#### Scenario: Máquina apagada

- **WHEN** una máquina está apagada por el apagón
- **THEN** no consume energía ni aporta producción en ese tick

### Requirement: Radiación acumulativa irreversible

La dosis de radiación SHALL ser un acumulador que nunca decrece. Bajo techo SHALL permanecer constante; en el exterior SHALL crecer según distancia y duración. Por encima del 30% SHALL limitar la salud máxima y causar daño progresivo; al 100% SHALL causar la muerte.

#### Scenario: Interior sin ganancia

- **WHEN** transcurre un tick con el astronauta bajo techo
- **THEN** la dosis de radiación no aumenta

#### Scenario: Exterior con ganancia

- **WHEN** el astronauta permanece en el exterior durante un tick
- **THEN** la dosis aumenta según la distancia y el tiempo configurados

#### Scenario: Dosis irreversible

- **WHEN** el astronauta vuelve al interior después de acumular dosis
- **THEN** la dosis acumulada se conserva y no decrece en ticks posteriores

#### Scenario: Umbral del 30%

- **WHEN** la dosis supera el 30%
- **THEN** la salud máxima se reduce a ese tope y la salud por encima del tope se pierde

#### Scenario: Dosis letal

- **WHEN** la dosis alcanza el 100%
- **THEN** la partida termina por muerte

### Requirement: Estado y degradación de máquinas

Cada máquina SHALL tener en el estado de simulación una salud, un estado encendido y un nivel de mejora. La salud SHALL decrecer por tick según su fila de economía y SHALL mantenerse dentro de `[0, 100]`. Una máquina con salud 0 SHALL considerarse averiada y SHALL dejar de producir.

#### Scenario: Degradación pasiva

- **WHEN** transcurre un tick
- **THEN** cada máquina pierde salud según su tasa configurada

#### Scenario: Máquina averiada

- **WHEN** la salud de una máquina llega a 0
- **THEN** la máquina deja de producir y su estado se expone como averiada

### Requirement: Reinicio de partida

El núcleo SHALL inicializar una partida nueva desde los stocks y estados iniciales de la economía y SHALL exponer una operación de reinicio que deje el estado como una partida nueva. El reinicio SHALL limpiar el contador de ticks, los recursos, la radiación, las máquinas y el ledger de la partida.

#### Scenario: Nueva partida

- **WHEN** se inicia una partida nueva
- **THEN** los recursos y las máquinas toman los valores iniciales de la economía y el tick vuelve a 0

#### Scenario: Reinicio

- **WHEN** se reinicia una partida en curso
- **THEN** el estado y el ledger quedan como en una partida nueva
