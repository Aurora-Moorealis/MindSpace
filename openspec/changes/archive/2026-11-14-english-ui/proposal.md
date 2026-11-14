# Proposal

## Why

El diseño formal pide que los textos que ve el jugador estén en inglés: la tabla
de strings, las misiones y la interfaz van en inglés mientras la documentación y
los comentarios siguen en español. Hoy el juego mezcla los dos idiomas: botones,
avisos, mensajes de error y toda la historia están en español.

Además, las specs citan etiquetas literales ("Iniciar juego", "Borrar"), así que
traducir la interfaz las dejaría mintiendo.

## What Changes

- Todo el texto visible al jugador pasa a **inglés**: menú, pantalla de mundos,
  mensajes de validación, avisos e historia de la introducción.
- Las specs dejan de citar etiquetas literales y hablan de la **acción**
  (iniciar partida, borrar, continuar, saltar, aceptar). Así se puede cambiar el
  idioma o la redacción sin tocar el contrato.
- Nueva capability `ui-language` que fija el idioma de la interfaz y aclara qué
  sigue en español.

## Capabilities

### New Capabilities

- `ui-language`: en qué idioma se escribe lo que ve el jugador y qué queda fuera.

### Modified Capabilities

- `menu`: los requisitos dejan de nombrar las etiquetas y hablan de las acciones.
- `worlds`: igual en creación, borrado y vuelta al menú.
- `intro`: igual en historia, saltar y aceptar.

## Impact

- `game/scenes/welcome/`, `game/scenes/worlds/` y `game/scenes/intro/`.
- `openspec/specs/menu`, `worlds`, `intro` y la nueva `ui-language`.

## Fuera de alcance

- La tabla de strings (`strings.tres`): los textos siguen en las escenas y en el
  código, solo cambian de idioma.
- Traducir la documentación, los comentarios o los nombres de archivo.
