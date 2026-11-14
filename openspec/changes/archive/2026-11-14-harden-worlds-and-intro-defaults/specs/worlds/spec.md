# Spec Delta

## MODIFIED Requirements

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
