# Design

## Context

El diseño formal pide textos de jugador en inglés y una tabla de strings
(`strings.tres`) que todavía no existe. Hoy las cadenas viven en las escenas
(`.tscn`), en el código (`_show_toast`) y en los mensajes de validación de
`WorldStore`.

Las specs citaban etiquetas literales, lo que las ata al idioma y a la redacción.

## Goals / Non-Goals

**Goals:**

- Que todo lo que lee el jugador esté en inglés.
- Que las specs no dependan de una etiqueta concreta.

**Non-Goals:**

- Crear la tabla de strings: se hará cuando haya localización de verdad.
- Traducir documentación o comentarios.

## Decisions

### 1. Se traduce el texto, no se introduce un sistema de localización

Añadir `strings.tres` y `tr()` ahora sería una capa nueva sin segundo idioma que
la justifique. Se traducen las cadenas en su sitio y la tabla queda como tarea
futura (`docs/future/`).

### 2. Las specs dejan de citar etiquetas

Un requisito que dice `al pulsar "Borrar"` se rompe al cambiar el idioma o el
texto. Pasan a decir `la acción de borrar`, que es lo que de verdad se está
especificando. El texto exacto es asunto de la interfaz, no del contrato.

### 3. El idioma se escribe como requisito propio

`ui-language` separa dos cosas que se confunden: qué ve el jugador (inglés) y qué
lee el equipo (español). Así una revisión futura sabe qué es un fallo.

### 4. La historia se traduce conservando el tono

Los textos de la intro se traducen, no se reescriben: mismas siete partes, mismo
orden y misma voz de Aurora. El marcador `{nombre}` pasa a `{name}` para que el
código no mezcle idiomas.

## Risks / Trade-offs

- **El texto sigue disperso**: al no haber tabla, cambiar una cadena obliga a
  tocar escenas. Se acepta hasta que haya localización.
- **Una traducción puede sonar rara** a quien escribió el guion en español; el
  contenido es el mismo y el original queda en el historial de git.
- **Las specs ya no verifican literales**: si alguien cambia un botón por otro
  texto, ninguna spec falla. Es el precio de no atar el contrato al idioma.
