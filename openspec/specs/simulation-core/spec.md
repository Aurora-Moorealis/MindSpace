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

En cada tick el núcleo SHALL producir y consumir O₂, agua, comida y energía según la economía, las máquinas y sus mejoras. Los consumos de una máquina SHALL proceder de su ficha. Los recursos SHALL mantenerse en `[0, capacidad]`, el consumo SHALL aplicarse después de la producción y los valores efectivos SHALL incluir los deltas de mejora, nunca negativos en consumo y degradación. La energía SHALL almacenarse en las baterías de la red eléctrica.

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

### Requirement: Radiación acumulativa irreversible

La dosis de radiación SHALL ser un acumulador que nunca decrece. Bajo techo SHALL permanecer constante; en el exterior SHALL crecer según distancia, duración y el multiplicador del traje equipado. Por encima del 30% SHALL limitar la salud máxima y causar daño progresivo; al 100% SHALL causar la muerte.

#### Scenario: Interior sin ganancia

- **WHEN** transcurre un tick con el astronauta bajo techo
- **THEN** la dosis de radiación no aumenta

#### Scenario: Exterior con ganancia

- **WHEN** el astronauta permanece en el exterior durante un tick
- **THEN** la dosis aumenta según la distancia y el tiempo configurados

#### Scenario: Traje reforzado

- **WHEN** el astronauta lleva el traje reforzado y pasa un tick en el exterior
- **THEN** la dosis aumenta según la fila de exterior multiplicada por la fila del traje reforzado

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

Cada máquina SHALL tener salud, encendido, nivel de mejora, reparación en curso y mejoras aplicadas. La salud SHALL decrecer por tick según su degradación efectiva (base más deltas) y mantenerse en `[0, 100]`. Con salud 0 SHALL estar averiada y dejar de producir. Una reparación SHALL acumular el trabajo del jugador por tick y restaurar la salud al máximo al alcanzar el total de divisiones.

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

### Requirement: Recuperación tras el apagón

Cuando una red vuelva a tener carga, el núcleo SHALL volver a encender las
máquinas que el apagón dejó apagadas, empezando por el sistema de O₂ y siguiendo
el orden inverso al apagado, como máximo `blackout_steps_per_tick` por tick. Una
máquina averiada NO SHALL encenderse hasta ser reparada.

#### Scenario: Recuperación gradual

- **WHEN** una red recupera carga después de un apagón
- **THEN** el sistema de O₂ se enciende primero, después el reciclador, la hidropónica y las luces, una máquina por tick

#### Scenario: Red sin carga

- **WHEN** la red sigue con carga 0
- **THEN** no se enciende ninguna máquina apagada

#### Scenario: Máquina averiada

- **WHEN** una máquina apagada está averiada
- **THEN** no se enciende hasta que se repare

#### Scenario: Determinismo

- **WHEN** dos partidas llegan al mismo estado de red y máquinas
- **THEN** la recuperación enciende las mismas máquinas en el mismo orden
