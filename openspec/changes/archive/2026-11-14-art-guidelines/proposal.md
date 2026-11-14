# Proposal

## Why

`docs/guia-estetica.md` mezcla dos cosas de naturaleza distinta: reglas que se
pueden auditar (paleta, alfa, contorno) y un manual de procedimiento. Al vivir
todo en un documento suelto, ningún agente las aplica como contrato y no hay
forma de comprobar si un asset las cumple.

Pasar las reglas a una spec las convierte en el mismo tipo de artefacto que el
resto del proyecto: verificable, versionado y citado desde los cambios.

## What Changes

- Nueva capability `art-style` con las reglas del arte como requisitos
  normativos: rejilla, paleta cerrada, contorno, luz, alfa binario, antialias,
  píxeles sueltos, espaciado de UI, tipografía, paneles y criterio de terminado.
- `docs/guia-estetica.md` se reduce a **manual**: procesos paso a paso,
  herramientas y errores frecuentes. Las reglas dejan de estar ahí y se enlazan
  a la spec, para que cada cosa viva en un solo sitio.

## Capabilities

### New Capabilities

- `art-style`: reglas de producción de arte del juego. Cubre cómo debe ser
  cualquier asset para encajar en el estilo, de forma que se pueda comprobar.

### Modified Capabilities

- Ninguna. `menu` no cambia: describe la pantalla, no cómo se dibuja su arte.

## Impact

- `openspec/specs/art-style/spec.md` (tras archivar).
- `docs/guia-estetica.md`: pierde las secciones normativas y gana un enlace a la
  spec.
- `openspec/config.yaml`: el `context` ya apunta a la guía; pasa a apuntar a la
  spec.
- Sin cambios de código ni de assets.

## Fuera de alcance

- Reescribir los assets existentes: la spec describe el estado actual, no
  introduce estilo nuevo.
- Cambiar `docs/future/`: sus tareas siguen igual.
- Automatizar la auditoría de arte: la spec deja los criterios listos para
  script, pero no se escribe el script.
