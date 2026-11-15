# Spec Delta

## Purpose

Define el comportamiento observable del núcleo que hace avanzar la partida: el reloj por ticks, los datos editables, los recursos, la radiación y la escalera de consecuencias que lleva a la muerte o al fin de la misión.

## MODIFIED Requirements

### Requirement: Economía dirigida por datos

Todos los números de gameplay (consumos, producción, capacidades, stocks iniciales, umbrales y reservas) SHALL proceder de datos editables: filas de economía para los valores globales y fichas de máquina para los valores propios de cada máquina. Cada fila MUST declarar su procedencia mediante `source`, `source_url`, `date_archived`, `archived` y `real_data`. Un valor ausente o fuera de rango SHALL sustituirse por un default seguro y quedar registrado como advertencia de desarrollo.

#### Scenario: Cambio de una fila

- **WHEN** se edita el consumo de O₂ por tick en la economía
- **THEN** el núcleo consume el nuevo valor sin cambios de código

#### Scenario: Cambio de una ficha de máquina

- **WHEN** se edita el consumo de energía de una máquina en su ficha
- **THEN** el tick descuenta el nuevo valor sin cambios de código

#### Scenario: Fila no verificada

- **WHEN** una fila tiene `real_data: false`
- **THEN** el estado expone ese indicador para que la UI lo muestre como simulado

#### Scenario: Valor inválido

- **WHEN** una fila falta o contiene un valor fuera de su rango permitido
- **THEN** el núcleo usa el default seguro y no corrompe el estado de la partida

### Requirement: Pipeline de tick en orden fijo

Cada tick SHALL ejecutar, en este orden: producción, consumos, degradación pasiva, trabajos de máquina (reparaciones en curso) y escalera de consecuencias. Las etapas de eventos y submisiones SHALL existir como puntos de extensión inertes en este cambio. El resultado de un tick SHALL depender solo del estado de entrada, de las filas de economía y de las fichas de máquina.

#### Scenario: Mismo estado, mismo resultado

- **WHEN** se ejecuta un tick dos veces desde copias idénticas del estado
- **THEN** ambas ejecuciones producen los mismos valores y los mismos hechos

#### Scenario: Etapas inertes

- **WHEN** no hay eventos ni submisiones configuradas
- **THEN** el tick completa las etapas implementadas sin alterar recursos por eventos o submisiones

#### Scenario: Trabajo de máquina en curso

- **WHEN** una máquina tiene una reparación en curso y transcurre un tick
- **THEN** la reparación acumula el trabajo del jugador y, si alcanza el total, la máquina queda reparada y se registra el hecho en ese mismo tick

### Requirement: Producción y consumo de recursos

En cada tick el núcleo SHALL producir y consumir O₂, agua, comida y energía según la economía, el estado de las máquinas y las mejoras aplicadas. Los consumos declarados por una máquina SHALL proceder de su ficha. Los recursos SHALL mantenerse dentro de `[0, capacidad]`. El consumo SHALL aplicarse después de la producción. Los valores efectivos de producción, consumo y degradación SHALL incluir los deltas de las mejoras de cada máquina; el consumo y la degradación efectivos NO SHALL ser negativos.

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

#### Scenario: Consumo propio de una máquina

- **WHEN** una máquina operativa declara consumos en su ficha
- **THEN** el tick descuenta esos consumos, y una máquina apagada o averiada no consume

#### Scenario: Mejora de producción o consumo

- **WHEN** una máquina operativa tiene una mejora que altera su producción, su consumo de energía o su degradación
- **THEN** el tick aplica el valor base más el delta de la mejora, con clamp a cero en consumo y degradación

### Requirement: Estado y degradación de máquinas

Cada máquina SHALL tener en el estado de simulación una salud, un estado encendido, un nivel de mejora, un trabajo de reparación en curso y la lista de mejoras aplicadas. La salud SHALL decrecer por tick según su tasa efectiva de degradación, que incluye los deltas de las mejoras, y SHALL mantenerse dentro de `[0, 100]`. Una máquina con salud 0 SHALL considerarse averiada y SHALL dejar de producir. Una reparación en curso SHALL acumular el trabajo del jugador por tick y SHALL restaurar la salud al máximo al alcanzar el total de divisiones.

#### Scenario: Degradación pasiva

- **WHEN** transcurre un tick sin mejoras de degradación
- **THEN** cada máquina pierde salud según su tasa configurada

#### Scenario: Degradación mejorada

- **WHEN** una máquina tiene una mejora que reduce su degradación
- **THEN** pierde la tasa efectiva resultante, nunca un valor negativo

#### Scenario: Máquina averiada

- **WHEN** la salud de una máquina llega a 0
- **THEN** la máquina deja de producir y su estado se expone como averiada

#### Scenario: Reparación en curso

- **WHEN** una máquina averiada o dañada tiene una reparación en curso
- **THEN** el estado expone la reparación y el progreso, y al completarse la salud vuelve al máximo

### Requirement: Reinicio de partida

El núcleo SHALL inicializar una partida nueva desde los stocks y estados iniciales de la economía y SHALL exponer una operación de reinicio que deje el estado como una partida nueva. El reinicio SHALL limpiar el contador de ticks, los recursos, la radiación, las máquinas, las mejoras aplicadas, las reparaciones en curso, las estadísticas del jugador y el ledger de la partida.

#### Scenario: Nueva partida

- **WHEN** se inicia una partida nueva
- **THEN** los recursos y las máquinas toman los valores iniciales de la economía y el tick vuelve a 0

#### Scenario: Reinicio

- **WHEN** se reinicia una partida en curso
- **THEN** el estado y el ledger quedan como en una partida nueva, sin mejoras ni reparaciones pendientes y con las estadísticas del jugador en sus valores base
