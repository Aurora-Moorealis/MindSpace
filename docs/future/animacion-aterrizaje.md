# Animación de aterrizaje del cohete

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** los maestros `rocket-landing.aseprite` / `rocket-ascent.aseprite`

## Objetivo

Que el cohete de aterrizaje no sea una imagen fija: una animación corta que
cuente que está bajando y posándose.

## Alcance

Una animación de **6 frames a 10–12 fps** (≈0,5 s), en bucle, sobre el maestro
de aterrizaje:

| Frame | Qué cambia |
| --- | --- |
| 1 | Cohete alto, llama larga, sin contacto |
| 2 | Un píxel más abajo, llama algo más corta |
| 3 | Casi tocando, llama corta |
| 4 | Contacto: llama desaparece, añicos de polvo salen a los lados |
| 5 | Polvo abriéndose, patas comprimidas 1 px |
| 6 | Posado, polvo disipándose |

La misma animación sirve de base para el despegue invirtiéndola y sustituyendo
el polvo por la llama creciente.

## Requisitos técnicos

- **Una capa por pieza** en el `.aseprite`: `body`, `legs`, `flame`, `dust`. Las
  patas y la llama se animan por separado; el cuerpo solo se desplaza.
- Movimiento vertical en **múltiplos de 2 px** (la rejilla de pantalla es 2×2).
- Tags de Aseprite: `land` y `takeoff`.
- Salida: `export_tag` a GIF para revisión + `export_spritesheet` para Godot.
- En Godot: `SpriteFrames` (generado por el MCP de Aseprite o a mano) dentro de
  `content/entities/rocket/`.

## Criterios de aceptación

- `lint_sprite` sin píxeles sueltos en ningún frame.
- Sin colores nuevos fuera de la paleta de la spec `art-style`.
- El bucle no "salta" al pasar del frame 6 al 1.
- Revisada a 2× y a tamaño de juego.

## Notas

El polvo lunar se dibuja con 2–3 tonos de gris y dithering ordenado; nunca con
blur ni partículas suaves, que rompen el estilo.
