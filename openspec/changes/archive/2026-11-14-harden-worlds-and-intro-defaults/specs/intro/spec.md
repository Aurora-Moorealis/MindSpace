# Spec Delta

## MODIFIED Requirements

### Requirement: Nombre del jugador

Los textos de la historia SHALL mostrar el nombre del mundo elegido allí donde
el guion lleve el marcador de nombre. Si no hay ningún mundo seleccionado, SHALL
usarse el nombre neutro `"astronaut"` en lugar del marcador, de un texto vacío o
de un nombre en otro idioma.

#### Scenario: Sustitución

- **WHEN** el mundo se llama "Ramer"
- **THEN** las partes que usan el marcador muestran "Ramer" en lugar del marcador

#### Scenario: Sin mundo seleccionado

- **WHEN** se abre la introducción sin un mundo seleccionado
- **THEN** los textos que usan el marcador muestran "astronaut"
