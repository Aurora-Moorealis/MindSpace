# Design

## Context

El código de las tres piezas ya existe en la rama `worlds`: `scenes/worlds`,
`scenes/intro` y los tres TileSet en `content/map`. Este cambio no lo toca, solo
escribe el contrato que ese código cumple para que el siguiente paso no lo rompa.

## Goals / Non-Goals

**Goals:**

- Que la persistencia, las validaciones y el flujo de la pantalla de mundos estén escritos.
- Que la introducción tenga sus partes, su orden y su final definidos.
- Que el contrato de los TileSets quede explícito: tres tilesets, datos por loseta y orientaciones del muro.

**Non-Goals:**

- Cambiar el comportamiento actual.
- Documentar la base jugable, que todavía no existe.
- Cubrir la estética: eso vive en `art-style`.

## Decisions

### 1. Tres capabilities, no una

`worlds`, `intro` y `world-map` son comportamientos independientes: se puede
cambiar la intro sin tocar los mundos y viceversa. Meterlos en una sola
capability obligaría a leer una spec enorme para cambiar una pantalla.

### 2. El borrado pide dos pulsaciones, no un diálogo

Un modal bloquea y añade una escena; el doble toque en el mismo botón resuelve lo
mismo con menos piezas y funciona igual con teclado o ratón. El precio es que hay
un estado intermedio ("¿Seguro?") que hay que revertir a los tres segundos, y eso
está escrito como escenario.

### 3. La persistencia no es un autoload

`WorldStore` es una clase estática con `user://worlds.json`. La regla del
proyecto es no añadir autoloads sin pedirlo, y este caso no lo necesita: nadie
escucha cambios de mundos desde otra escena.

### 4. La intro no bloquea el arranque

Es una escena, no una animación dentro del juego. Así se puede saltar, repetir o
quitar sin tocar la base, y su fallo no impide jugar.

### 5. `world-map` separa el contrato del arte

`art-style` dice cómo se ve una loseta; `world-map` dice qué declara y cómo se
orienta. Son responsabilidades distintas y cambian por motivos distintos.

## Risks / Trade-offs

- **La spec podría quedarse corta** si la base necesita más datos por loseta
  (por ejemplo, coste de excavado). Añadirlos será un cambio nuevo sobre `world-map`.
- **El número siete de partes** está fijado en la spec; añadir o quitar una parte
  de la historia obliga a modificar el requisito, que es lo deseable.
- **La confirmación de borrado** depende de un temporizador: si el jugador tarda
  más de tres segundos en confirmar, tiene que volver a empezar. Se acepta por
  seguridad ante clics accidentales.
