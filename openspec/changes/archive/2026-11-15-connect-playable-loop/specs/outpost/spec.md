# Spec Delta

## Purpose

Estaciones de máquina que materializan el outpost jugable sobre la superficie
lunar, la zona de refugio que las cubre y la red eléctrica que las alimenta.

## ADDED Requirements

### Requirement: Ocho estaciones en el mundo

La escena jugable SHALL contener exactamente una estación por cada una de las
ocho máquinas del núcleo, cada una identificada con el id de simulación de su
máquina. Una estación duplicada o con un id desconocido SHALL reportarse como
advertencia de desarrollo y NO SHALL impedir el arranque.

#### Scenario: Partida nueva

- **WHEN** se carga la escena jugable
- **THEN** existen ocho estaciones y sus identificadores coinciden con los ocho ids del núcleo

#### Scenario: Id desconocido

- **WHEN** la escena contiene una estación con un id que no pertenece al núcleo
- **THEN** el arranque continúa y el problema queda como advertencia de desarrollo

### Requirement: Estación visible sin arte definitivo

Cada estación SHALL mostrarse con una textura de reemplazo visible y distinguible
mientras no exista su arte definitivo. Sustituir esa textura por el arte final NO
SHALL cambiar el comportamiento de la estación.

#### Scenario: Estación sin arte

- **WHEN** se recorre el outpost antes de que exista el arte de una máquina
- **THEN** la estación se ve en pantalla y se distingue de las demás

#### Scenario: Cambio de textura

- **WHEN** se sustituye la textura de reemplazo por el arte final
- **THEN** el panel, el área de interacción y el estado de la máquina siguen funcionando igual

### Requirement: Estado reflejado en la estación

La estación SHALL reflejar el estado de su máquina: sana, averiada o sin energía.
El estado SHALL refrescarse en cada tick y en cada reinicio de partida sin que la
estación escriba en el estado de simulación.

#### Scenario: Máquina averiada

- **WHEN** la salud de una máquina llega a cero
- **THEN** su estación se muestra como averiada en el siguiente refresco

#### Scenario: Máquina sin energía

- **WHEN** la red deja sin energía a una máquina
- **THEN** su estación se muestra apagada

### Requirement: Recinto de refugio

El outpost SHALL declarar un área de refugio que cubra todas sus estaciones y la
posición de aparición del astronauta. Esa área SHALL ser la única zona de refugio
de la escena y NO SHALL cubrir el resto de la superficie lunar.

#### Scenario: Dentro del recinto

- **WHEN** el astronauta está dentro del área de refugio
- **THEN** la partida cuenta como interior para la radiación

#### Scenario: Fuera del recinto

- **WHEN** el astronauta se aleja del outpost y sale del área de refugio
- **THEN** la partida pasa a exterior

### Requirement: Topología de la red eléctrica

La escena jugable SHALL instanciar el panel solar, una batería, las consumidoras y
los cables que los unen, de modo que cada consumidora tenga camino de cables hasta
la batería. Retirar el único cable entre dos nodos SHALL cambiar la partición de
la red en el siguiente tick.

#### Scenario: Red completa

- **WHEN** arranca la partida
- **THEN** cada consumidora comparte red con la batería y con el panel solar

#### Scenario: Corte de cable

- **WHEN** se retira el único cable que unía una consumidora con la batería
- **THEN** esa consumidora pasa a otra red y deja de disponer de la carga en el siguiente tick

### Requirement: Reinicio del outpost

Un reinicio de partida SHALL dejar las ocho estaciones presentes y en su estado
inicial, la batería registrada de nuevo con su carga inicial y el tendido de
cables intacto.

#### Scenario: Reinicio

- **WHEN** se reinicia una partida con máquinas averiadas y mejoras aplicadas
- **THEN** las estaciones vuelven al estado inicial y la red conserva su tendido

#### Scenario: Batería tras el reinicio

- **WHEN** se reinicia la partida
- **THEN** la batería vuelve a estar registrada y su carga es la inicial de la economía
