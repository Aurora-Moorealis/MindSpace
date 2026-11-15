# Spec Delta

## Purpose

Define el comportamiento observable del núcleo que hace avanzar la partida: el reloj por ticks, la economía data-driven, los recursos, la radiación y la escalera de consecuencias que lleva a la muerte o al fin de la misión.

## MODIFIED Requirements

### Requirement: Producción y consumo de recursos

En cada tick el núcleo SHALL producir y consumir O₂, agua, comida y energía según la economía, las máquinas y sus mejoras. Los consumos de una máquina SHALL proceder de su ficha. Los recursos SHALL mantenerse en `[0, capacidad]` y el consumo SHALL aplicarse después de la producción. Los valores efectivos SHALL incluir los deltas de mejora y nunca ser negativos en consumo y degradación. La energía SHALL almacenarse en las baterías de la red eléctrica, no en un depósito global, y la energía total expuesta SHALL ser la suma de las cargas de las baterías.

#### Scenario: Producción solar de día

- **WHEN** el tick ocurre en fase de día, el panel solar está operativo y su red tiene una batería con hueco
- **THEN** la energía producida se suma a las baterías de esa red hasta su capacidad

#### Scenario: Consumo de soporte vital

- **WHEN** transcurre un tick con la tripulación viva
- **THEN** O₂, agua y comida disminuyen según las filas de consumo aplicables y la energía de cada red baja según la demanda de sus máquinas alimentadas

#### Scenario: Recursos acotados

- **WHEN** una producción excede la capacidad de un recurso
- **THEN** el recurso queda en su capacidad máxima
- **WHEN** un consumo excede el stock disponible
- **THEN** el recurso queda en 0, nunca en negativo

#### Scenario: Consumo propio de una máquina

- **WHEN** una máquina operativa declara consumos en su ficha
- **THEN** el tick descuenta esos consumos de la red de la máquina, y una máquina apagada o averiada no consume

#### Scenario: Mejora de producción o consumo

- **WHEN** una máquina operativa tiene una mejora que altera su producción, su consumo de energía o su degradación
- **THEN** el tick aplica el valor base más el delta de la mejora, con clamp a cero en consumo y degradación

#### Scenario: Panel sin almacenamiento

- **WHEN** el panel solar produce y su red no contiene ninguna batería
- **THEN** la producción se descarta y ninguna otra red recibe esa energía

### Requirement: Apagado por falta de energía

Si la carga disponible de una red es 0 y no recibe producción en ese tick, el núcleo SHALL apagar máquinas de esa red en orden fijo: luces → hidropónica → reciclador → sistema de O₂. Una máquina apagada SHALL dejar de consumir energía y de producir. El orden SHALL ser independiente del orden de inserción de las máquinas y el apagado de una red SHALL NOT afectar a las máquinas de otra red.

#### Scenario: Apagón

- **WHEN** la carga de una red llega a 0
- **THEN** las luces de esa red se apagan primero y su sistema de O₂ es el último en apagarse

#### Scenario: Máquina apagada

- **WHEN** una máquina está apagada por el apagón
- **THEN** no consume energía ni aporta producción en ese tick

#### Scenario: Redes separadas

- **WHEN** una red se queda sin carga mientras otra red conserva carga
- **THEN** las máquinas de la red con carga siguen funcionando
