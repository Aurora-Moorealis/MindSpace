# Spec Delta

## Purpose

Pantalla de selección de mundos guardados: crear, elegir y borrar, con la
persistencia necesaria para que los mundos sobrevivan entre sesiones.

## ADDED Requirements

### Requirement: Persistencia de mundos

Los mundos SHALL guardarse en el almacenamiento del usuario y SHALL leerse al
abrir la pantalla de selección, de modo que sobrevivan entre sesiones.

#### Scenario: Primera vez sin mundos

- **WHEN** se abre la pantalla y no hay ningún mundo guardado
- **THEN** no se muestra lista y se pide directamente un nombre

#### Scenario: Con mundos guardados

- **WHEN** se abre la pantalla y hay mundos guardados
- **THEN** se listan todos, cada uno con su nombre visible

### Requirement: Creación de mundo

Un mundo nuevo SHALL tener un nombre no vacío, de 24 caracteres como máximo y
distinto de los existentes. Si no cumple, la creación SHALL rechazarse con un
mensaje y no SHALL guardarse nada.

#### Scenario: Nombre vacío

- **WHEN** se intenta crear un mundo sin escribir nombre
- **THEN** aparece el mensaje "Escribe un nombre" y no se crea nada

#### Scenario: Nombre repetido

- **WHEN** se intenta crear un mundo con un nombre que ya existe, sin distinguir mayúsculas
- **THEN** aparece el mensaje de nombre repetido y no se crea nada

#### Scenario: Nombre válido

- **WHEN** se crea un mundo con un nombre válido
- **THEN** el mundo se guarda y queda seleccionado para jugar

### Requirement: Borrado con confirmación

Borrar un mundo SHALL exigir dos pulsaciones: la primera pide confirmación y la
segunda borra. Si no llega la segunda en tres segundos, el botón SHALL volver a
su estado normal sin borrar nada.

#### Scenario: Primera pulsación

- **WHEN** se pulsa "Borrar" en un mundo
- **THEN** el botón cambia a "¿Seguro?" y el mundo sigue existiendo

#### Scenario: Segunda pulsación

- **WHEN** se vuelve a pulsar el botón en estado de confirmación
- **THEN** el mundo se borra de la lista y del almacenamiento

#### Scenario: Se arrepiente

- **WHEN** pasan tres segundos sin segunda pulsación
- **THEN** el botón vuelve a "Borrar" y el mundo no se ha tocado

### Requirement: Entrada al mundo

Al elegir un mundo o crear uno nuevo, el juego SHALL continuar hacia la
introducción con ese mundo seleccionado.

#### Scenario: Elegir un mundo existente

- **WHEN** el jugador pulsa el nombre de un mundo
- **THEN** se abre la introducción y el nombre de ese mundo está disponible para ella

### Requirement: Vuelta al menú

La pantalla SHALL permitir volver al menú principal sin elegir ningún mundo.

#### Scenario: Volver

- **WHEN** el jugador pulsa "Volver" o la tecla de cancelar
- **THEN** el juego regresa al menú principal
