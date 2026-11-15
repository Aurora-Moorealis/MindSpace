# Proposal

## Why

El invernadero es una de las cinco salas del outpost lunar y contiene la máquina
`hydroponics`, que produce comida y O₂ (ver
`docs/designs/junior-astronauta-outpost-lunar.md`). Hoy el proyecto solo tiene
arte del astronauta y de los iconos del toolkit: la sala no tiene ni un sprite,
así que en el juego se leería como una caja gris y el jugador no podría asociar
la máquina con el recurso que produce. Hace falta el set de props, cultivos y
equipo que dé identidad al invernadero y comunique de un vistazo "aquí se
cultiva comida y se genera oxígeno".

## What Changes

- Se crea un **pack de sprites estáticos** del invernadero sobre la rejilla de
  32 px de `docs/art-direction.md`, repartido en dos dueños de contenido:
  - `game/content/map/greenhouse/art/` — props de sala, plantas, equipo, luces
    y decoración pequeña.
  - `game/content/machines/hydroponics/art/` — el rack hidropónico y la consola
    de control, que son el arte propio de esa máquina.
- Se amplía la paleta con una **rampa de 5 verdes desaturados** para cultivos y
  musgo (`greenhouse_palette.gpl`), sin tocar los 17 colores base ni los sprites
  existentes del astronauta o del toolkit.
- Cada sprite se entrega como fuente `.aseprite`, PNG RGBA con alpha real a 1×,
  manifiesto JSON con nombre/tamaño/ancla, `README.md` con instrucciones de
  importación en Godot y una captura de revisión a 850×480.
- Se fija la regla de que el pack es **solo arte**: ni escenas, ni colisiones,
  ni lógica de crecimiento o cosecha. La sala jugable y las interacciones se
  planifican en su propio cambio.
- **Fuera de alcance:** tileset del invernadero (suelo, paredes, ventanal,
  esclusa), animaciones (crecimiento, viento, parpadeo), cultivos alienígenas
  con paleta propia y cualquier modificación de `project.godot` o de escenas
  compartidas.

## Capabilities

### New Capabilities

- `greenhouse-art`: catálogo y reglas de los sprites estáticos del invernadero
  (props de sala, cultivos, equipo, luces y decoración), su paleta de verdes,
  su rejilla y anclas, la estructura de archivos y la QA visual a 1×.

### Modified Capabilities

Ninguna. `openspec/specs/` está vacío y este cambio no altera requisitos
existentes.

## Impact

- **Archivos nuevos:** `game/content/map/greenhouse/` y
  `game/content/machines/hydroponics/` (arte, paleta, manifiesto, README,
  previews) más sus `.import` generados por Godot.
- **Paleta:** se añade una rampa verde local al invernadero; la paleta base de
  17 colores del astronauta y del toolkit no se modifica.
- **Sin impacto en código:** no se toca `project.godot`, autoloads, escenas
  compartidas ni `.tres`. El `hydroponics` de gameplay sigue sin existir.
- **Dependencias:** Aseprite vía MCP para dibujar y exportar; Godot solo para la
  captura de revisión.
