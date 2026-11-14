# Spec Delta

## MODIFIED Requirements

### Requirement: Creación de mundo

Un mundo nuevo SHALL tener un nombre no vacío, de 24 caracteres como máximo y
distinto de los existentes. Si no cumple, la creación SHALL rechazarse con un
mensaje que explique el motivo y no SHALL guardarse nada.

#### Scenario: Nombre vacío

- **WHEN** se intenta crear un mundo sin escribir nombre
- **THEN** aparece un mensaje de nombre obligatorio y no se crea nada

#### Scenario: Nombre repetido

- **WHEN** se intenta crear un mundo con un nombre que ya existe, sin distinguir mayúsculas
- **THEN** aparece un mensaje de nombre repetido y no se crea nada

#### Scenario: Nombre válido

- **WHEN** se crea un mundo con un nombre válido
- **THEN** el mundo se guarda y queda seleccionado para jugar

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

### Requirement: Vuelta al menú

La pantalla SHALL permitir volver al menú principal sin elegir ningún mundo.

#### Scenario: Volver

- **WHEN** el jugador pulsa la acción de volver o la tecla de cancelar
- **THEN** el juego regresa al menú principal
