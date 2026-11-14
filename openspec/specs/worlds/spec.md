# worlds Specification

## Purpose
Pantalla de selección de mundos guardados: crear, elegir y borrar, con la
persistencia necesaria para que los mundos sobrevivan entre sesiones.

## Requirements

### Requirement: Persistencia de mundos

Los mundos SHALL guardarse en el almacenamiento del usuario y SHALL leerse al
abrir la pantalla de selección, de modo que sobrevivan entre sesiones. Cada
guardado SHALL ser atómico: si la escritura se interrumpe a mitad, el archivo
anterior SHALL quedar intacto y legible. Si el archivo existente no se puede
interpretar, SHALL conservarse como copia de seguridad y la pantalla SHALL
avisar del problema en lugar de tratarlo como una lista vacía.

#### Scenario: Primera vez sin mundos

- **WHEN** se abre la pantalla y no hay ningún mundo guardado
- **THEN** no se muestra lista y se pide directamente un nombre

#### Scenario: Con mundos guardados

- **WHEN** se abre la pantalla y hay mundos guardados
- **THEN** se listan todos, cada uno con su nombre visible

#### Scenario: Escritura interrumpida

- **WHEN** la escritura de un mundo se interrumpe antes de terminar
- **THEN** el archivo anterior sigue siendo legible y conserva sus mundos

#### Scenario: Archivo dañado

- **WHEN** el archivo de mundos existe pero no se puede interpretar
- **THEN** se conserva como copia de seguridad, la pantalla avisa y no se
  sobrescribe con una lista vacía

### Requirement: Creación de mundo

Un mundo nuevo SHALL tener un nombre no vacío, de 24 caracteres como máximo y
distinto de los existentes. Si no cumple, la creación SHALL rechazarse con un
mensaje que explique el motivo y no SHALL guardarse nada. La validación SHALL
aplicarse en la capa de persistencia, no solo en el formulario, de modo que
ninguna llamada pueda crear un mundo inválido.

#### Scenario: Nombre vacío

- **WHEN** se intenta crear un mundo sin escribir nombre
- **THEN** aparece un mensaje de nombre obligatorio y no se crea nada

#### Scenario: Nombre repetido

- **WHEN** se intenta crear un mundo con un nombre que ya existe, sin distinguir mayúsculas
- **THEN** aparece un mensaje de nombre repetido y no se crea nada

#### Scenario: Nombre válido

- **WHEN** se crea un mundo con un nombre válido
- **THEN** el mundo se guarda y queda seleccionado para jugar

#### Scenario: Llamada directa

- **WHEN** se pide crear un mundo con un nombre vacío, demasiado largo o repetido sin pasar por el formulario
- **THEN** la creación se rechaza y no se guarda nada

### Requirement: Borrado con confirmación

Borrar un mundo SHALL exigir dos pulsaciones: la primera pide confirmación y la
segunda borra. Si no llega la segunda en tres segundos, el botón SHALL volver a
su estado normal sin borrar nada.

#### Scenario: Primera pulsación

- **WHEN** se pulsa la acción de borrar en un mundo
- **THEN** el botón pasa a pedir confirmación y el mundo sigue existiendo

#### Scenario: Segunda pulsación

- **WHEN** se vuelve a pulsar el botón en estado de confirmación
- **THEN** el mundo se borra de la lista y del almacenamiento

#### Scenario: Se arrepiente

- **WHEN** pasan tres segundos sin segunda pulsación
- **THEN** el botón vuelve a su estado normal y el mundo no se ha tocado

### Requirement: Entrada al mundo

Al elegir un mundo o crear uno nuevo, el juego SHALL continuar hacia la
introducción con ese mundo seleccionado.

#### Scenario: Elegir un mundo existente

- **WHEN** el jugador pulsa el nombre de un mundo
- **THEN** se abre la introducción y el nombre de ese mundo está disponible para ella

### Requirement: Vuelta al menú

La pantalla SHALL permitir volver al menú principal sin elegir ningún mundo.
Cuando el formulario de creación esté abierto y existan mundos guardados,
cancelar SHALL volver a la lista sin crear nada; cuando no existan, SHALL volver
al menú principal.

#### Scenario: Volver

- **WHEN** el jugador pulsa la acción de volver o la tecla de cancelar en la lista de mundos
- **THEN** el juego regresa al menú principal

#### Scenario: Cancelar el formulario

- **WHEN** el formulario está abierto, hay mundos guardados y el jugador pulsa la tecla de cancelar
- **THEN** se vuelve a la lista, el nombre escrito se descarta y no se crea nada

#### Scenario: Cancelar sin mundos

- **WHEN** el formulario está abierto, no hay mundos guardados y el jugador pulsa la tecla de cancelar
- **THEN** el juego regresa al menú principal
