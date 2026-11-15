# Design

## Validación en la capa de persistencia

La pantalla ya llama a `WorldStore.validate_name()` antes de crear, pero la API
era pública y no comprobaba nada. Duplicar la comprobación en `create_world()`
tiene dos efectos:

- Cualquier escena futura (o una prueba) obtiene las mismas reglas sin repetir
  código.
- Una lista en memoria desactualizada no puede colar un duplicado.

`create_world()` sigue devolviendo `World` o `null`; el mensaje concreto lo sigue
dando `validate_name()`, que la pantalla ya usa para mostrarlo. No se cambia la
firma, así que no hay que tocar a los llamantes.

## Cancelar el formulario

El formulario es un estado de la misma pantalla, no una escena. Cancelar debe
deshacer ese estado, no salir de la pantalla. La regla queda:

- Formulario visible y hay mundos → volver a la lista (se descarta el nombre).
- Formulario visible y no hay mundos → no hay lista a la que volver, así que se
  mantiene el comportamiento actual: menú principal.
- Lista visible → menú principal.

No se pide confirmación: el formulario no ha guardado nada todavía.

## Nombre de reserva de la intro

`"astronauta"` era un texto en español visible en «Accept the mission, …?». El
nombre de reserva pasa a `"astronaut"`, en inglés como el resto de la UI. Solo
se usa si la escena se abre sin un mundo seleccionado (por ejemplo, al ejecutar
la intro directamente desde el editor); el flujo normal siempre tiene mundo.

## Riesgos

- `create_world()` ahora puede devolver `null` por un nombre inválido, no solo
  por fallo de escritura. La pantalla ya muestra «Could not save the world.» en
  ese caso, pero antes de llamarla valida y muestra el motivo exacto, así que el
  mensaje genérico solo aparece si la lista cambió entre ambas llamadas.
