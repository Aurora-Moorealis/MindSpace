# intro Specification

## Purpose
Introducción narrativa entre la elección de mundo y el juego: la salida de la
Tierra, la travesía a la Luna y la presentación de la misión.

## Requirements

### Requirement: Animación de salida y travesía

La introducción SHALL mostrar primero la salida del cohete desde la Tierra y
después la travesía por el espacio con la Luna al fondo, antes de mostrar
cualquier texto de la historia.

#### Scenario: Salida

- **WHEN** empieza la introducción
- **THEN** se ve la Tierra y el cohete ascendiendo desde ella

#### Scenario: Travesía

- **WHEN** termina la salida
- **THEN** la Tierra queda atrás, aparece la Luna pequeña al fondo y el cohete avanza hacia ella

### Requirement: Historia por partes

La historia SHALL presentarse en siete partes, una por pantalla y en el orden
escrito, avanzando solo cuando el jugador pulse la acción de continuar.

#### Scenario: Avanzar

- **WHEN** el jugador pulsa la acción de continuar
- **THEN** aparece la siguiente parte de la historia

#### Scenario: Orden de las partes

- **WHEN** se recorre la historia completa
- **THEN** las partes aparecen en el orden: aviso, pregunta desde la Tierra, tu misión, preparativos, Aurora, llegada y primer paso

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

### Requirement: Saltar la animación

Durante la animación SHALL existir una acción para saltarla y pasar directamente
a la historia. Al saltar, la animación pendiente SHALL detenerse y la historia
SHALL permanecer en la parte que el jugador esté viendo: ni el final del tween
en curso ni el resto de la secuencia SHALL reiniciarla o retrocederla.

#### Scenario: Saltar

- **WHEN** el jugador pulsa la acción de saltar mientras se reproduce la animación
- **THEN** la animación termina y aparece la primera parte de la historia

#### Scenario: El progreso se conserva

- **WHEN** el jugador salta la animación, avanza a una parte posterior y el tween pendiente termina
- **THEN** la historia sigue en esa parte posterior y no vuelve a la primera

#### Scenario: Salto durante un fundido

- **WHEN** el jugador salta mientras la pantalla se está fundiendo a negro
- **THEN** el fundido se cancela y la historia se ve con claridad

### Requirement: Aceptar la misión

La última parte SHALL ofrecer la acción de aceptar la misión, y aceptarla SHALL
confirmar la misión del mundo elegido.

#### Scenario: Aceptar

- **WHEN** el jugador pulsa la acción de aceptar en la última parte
- **THEN** aparece una confirmación que nombra al mundo elegido

#### Scenario: Volver atrás

- **WHEN** el jugador cancela la introducción
- **THEN** el juego regresa a la pantalla de mundos
