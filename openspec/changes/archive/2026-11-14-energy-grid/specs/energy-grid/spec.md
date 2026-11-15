# Spec Delta

## Purpose

Define la red eléctrica de la base: qué es un nodo, cómo un cable lo une a otros,
cómo se almacena la carga en las baterías, cómo produce el panel solar y cómo se
reparte la energía entre las máquinas de una misma red.

## ADDED Requirements

### Requirement: Nodos de energía

Cada panel solar, cada batería y cada máquina consumidora SHALL ser un nodo de
energía con un identificador estable dentro de la partida. El identificador de una
máquina SHALL coincidir con su id de simulación y el de una batería SHALL ser
único aunque existan varias baterías.

#### Scenario: Identidad de un nodo

- **WHEN** se registra un panel, una batería o una máquina en la red
- **THEN** el nodo expone un identificador que no cambia mientras la partida siga
  viva

#### Scenario: Varias baterías

- **WHEN** la base tiene más de una batería
- **THEN** cada una se identifica por separado y conserva su propia carga

### Requirement: Cables y redes

Un cable SHALL unir exactamente dos nodos y la unión SHALL ser no dirigida. Un
conjunto de nodos unidos por cables SHALL formar una red; dos nodos sin camino de
cables entre ellos SHALL pertenecer a redes distintas. Un cable SHALL ocupar celdas
de la rejilla de mundo y SHALL dibujarse con las losetas de conexión que
correspondan a sus vecinos.

#### Scenario: Unión de dos nodos

- **WHEN** se coloca un cable entre el panel y la batería
- **THEN** ambos nodos pasan a la misma red

#### Scenario: Corte del cable

- **WHEN** se retira el único cable que unía una batería con el resto de la red
- **THEN** la batería queda en una red distinta y las máquinas de la otra red dejan
  de disponer de su carga

#### Scenario: Cables sin nodo

- **WHEN** un tramo de cable no toca ningún puerto de nodo
- **THEN** no aporta ninguna unión y no altera el reparto de energía

#### Scenario: Actualización en vivo

- **WHEN** un cable válido entra o sale de la escena
- **THEN** la red se recalcula sin recargar la escena y el cambio se aplica en el siguiente tick

### Requirement: Carga de baterías

Cada batería SHALL almacenar una carga entre 0 y su capacidad, leída de las filas
de economía. La carga SHALL conservarse cuando la batería queda aislada y SHALL
poder repartirse solo dentro de su propia red. La carga de una batería SHALL no ser
negativa ni superar su capacidad.

#### Scenario: Carga acotada

- **WHEN** la producción de un tick excede el hueco libre de una batería
- **THEN** la batería queda llena y el excedente se descarta

#### Scenario: Descarga acotada

- **WHEN** la demanda de una red excede la carga disponible
- **THEN** la carga de sus baterías queda en 0, nunca en negativo

#### Scenario: Batería aislada

- **WHEN** una batería cargada queda sin cables
- **THEN** conserva su carga y ninguna otra red puede gastarla

### Requirement: Producción solar

El panel solar SHALL producir energía solo de día, estando sano y encendido. La
producción SHALL entrar en las baterías de su propia red hasta llenarlas; si su red
no tiene ninguna batería, la producción SHALL descartarse.

#### Scenario: Día con batería conectada

- **WHEN** es de día, el panel está operativo y su red tiene una batería con hueco
- **THEN** la carga de esa batería sube según la fila de producción solar

#### Scenario: Noche

- **WHEN** es de noche
- **THEN** el panel no produce y la red vive solo de la carga almacenada

#### Scenario: Panel sin batería

- **WHEN** el panel produce pero su red no contiene ninguna batería
- **THEN** la energía no se almacena en ningún sitio y la red no gana carga

### Requirement: Reparto y apagado por red

Una máquina consumidora SHALL estar alimentada solo si su red contiene al menos una
batería con carga. Cada tick la red SHALL pagar la demanda de sus máquinas
alimentadas con la carga de sus baterías. Si una red se queda sin carga y sin
producción, SHALL apagar sus máquinas en el orden fijo luces → hidropónica →
reciclador → sistema de O₂, sin afectar a las máquinas de otras redes. El apagón
SHALL registrarse una sola vez por episodio y por red.

#### Scenario: Red sin batería

- **WHEN** una máquina está cableada solo a un panel, sin batería
- **THEN** la máquina no consume ni produce porque su red no tiene con qué pagar

#### Scenario: Apagón aislado

- **WHEN** la red A se queda sin carga y la red B conserva carga
- **THEN** solo se apagan máquinas de la red A

#### Scenario: Orden de apagado

- **WHEN** una red se queda sin carga
- **THEN** se apaga primero la luz y el sistema de O₂ es el último

### Requirement: Estado de energía expuesto

El núcleo SHALL exponer la energía total como la suma de las cargas de todas las
baterías, para que el HUD y la evaluación la lean sin conocer la red. Un cambio
directo sobre la energía total SHALL escribirse en las baterías de forma
determinista, empezando por la primera batería registrada.

#### Scenario: Lectura del HUD

- **WHEN** el HUD pide la energía disponible
- **THEN** recibe la suma de las cargas de todas las baterías

#### Scenario: Escritura para pruebas

- **WHEN** se fija la energía total de una partida con una sola batería
- **THEN** esa batería queda con el valor fijado y el resto de la red ve el mismo
  total
