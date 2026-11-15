# Invernadero — arte de sala

Sprites estáticos del invernadero del outpost lunar. Son props de escenario:
no incluyen escenas, colisiones, lógica de crecimiento ni cosecha. El arte de
la máquina hidropónica vive en `game/content/machines/hydroponics/art/`.

## Estructura

```text
art/
├── *.aseprite          fuentes editables (una por sprite, 1 frame)
├── sprites/*.png       export 1× RGBA, recortado al tamaño del sprite
├── palette/            greenhouse_palette.gpl + swatch
├── previews/           captura de integración 850×480
├── sprites.json        manifiesto: tamaño, rejilla y ancla
└── README.md
```

## Inventario (19 sprites)

| Nombre | Categoría | Tamaño | Rejilla | Ancla |
| --- | --- | --- | --- | --- |
| `grow_bed` | prop | 64×32 | 2×1 | bottom-center `[32, 32]` |
| `water_tank` | prop | 64×64 | 2×2 | bottom-center `[32, 64]` |
| `pipe_elbow` | prop | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `seed_crate` | prop | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `crop_seedling` | crop | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `crop_leafy` | crop | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `crop_root` | crop | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `crop_vine` | crop | 32×64 | 1×2 | bottom-center `[16, 64]` |
| `grow_lamp` | equipment | 64×32 | 2×1 | top-center `[32, 0]` |
| `fan_unit` | equipment | 32×32 | 1×1 | top-center `[16, 1]` |
| `sprinkler` | equipment | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `gauge_panel` | equipment | 32×32 | 1×1 | top-center `[16, 5]` |
| `vent_grille` | equipment | 32×32 | 1×1 | top-center `[16, 0]` |
| `pot_small` | decor | 16×16 | 0.5×0.5 | bottom-center `[8, 16]` |
| `watering_can` | decor | 16×16 | 0.5×0.5 | bottom-center `[8, 16]` |
| `tool_rack` | decor | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `hose_coil` | decor | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `floor_drain` | decor | 32×32 | 1×1 | bottom-center `[16, 32]` |
| `warning_sign` | decor | 16×16 | 0.5×0.5 | bottom-center `[8, 16]` |

`sprites.json` es la fuente de verdad de tamaños y anclas. El ancla está en
píxeles desde la esquina superior izquierda del PNG; en los props de suelo el
valor `y` es la línea de contacto con el suelo.

## Paleta

`palette/greenhouse_palette.gpl` contiene los 17 colores base de MindSpace más
cinco verdes desaturados para cultivos y musgo:

| Paso | Hex |
| --- | --- |
| Verde profundo | `#1c2a20` |
| Verde oscuro | `#2f4a33` |
| Verde base | `#4a6b45` |
| Verde claro | `#6d9257` |
| Verde brillo | `#9cbf7e` |

Los 17 colores base no cambian respecto al astronauta y al toolkit. El cian
sigue reservado a pantallas, líquido y energía; el naranja y el rojo no superan
el 5 % de ningún sprite. `palette/greenhouse_palette.png` es el swatch de 22
muestras de 64 px.

## Importación en Godot

1. Copia los PNG dentro del proyecto y deja que Godot los importe.
2. Selecciona todos los PNG en el dock FileSystem → pestaña **Import**.
3. Preset **2D Pixel** o, manualmente: **Filter** desactivado, **Mipmaps**
   desactivados, **Compress → Lossless**, **Fix Alpha Border** activado.
4. Pulsa **Reimport**. A 1× no debe haber interpolación ni halos.
5. Coloca cada sprite con su ancla del manifiesto y `texture_filter` en
   `Nearest` (el proyecto usa nearest por defecto).

## QA

- Revisión a 1× en `previews/integration_850x480.png`, sobre suelo
  `#1d2536`/`#33405a`.
- `lint_sprite` de Aseprite: 0 piezas sueltas, 0 píxeles huérfanos de silueta.
- Todos los colores pertenecen a la paleta; no hay verdes fuera de la rampa.
- Contorno cerrado de 1 px `#111827` y como máximo cuatro valores por material.

## Crecimiento de cultivos

`growth/` contiene el ciclo de crecimiento de un cultivo, en cuatro etapas de
32×32 con la misma ancla bottom-center `[16, 32]` que los cultivos del pack:

| Etapa | Archivo suelto | Frame de animación |
| --- | --- | --- |
| Semilla | `growth/stages/crop_stage_1_seed.png` | `growth/frames/crop_growth_1.png` |
| Brote | `growth/stages/crop_stage_2_sprout.png` | `growth/frames/crop_growth_2.png` |
| Joven | `growth/stages/crop_stage_3_young.png` | `growth/frames/crop_growth_3.png` |
| Madura | `growth/stages/crop_stage_4_mature.png` | `growth/frames/crop_growth_4.png` |

- `growth/crop_growth.aseprite`: las cuatro etapas como animación con el tag
  `growth` (500 ms por frame, reproducción única; no es un loop).
- `growth/sprites.json`: metadatos de la animación (frames, duración, ancla).
- `growth/crop_growth_sheet.png` + `.json`: hoja horizontal de 128×32 y su
  metadata de frames.
- `growth/crop_growth_x4.gif`: preview animado a 4×.
- `growth/example_stages_x6.png`: las cuatro etapas a 6× con su nombre.
- `growth/example_scene_x2.gif`: ejemplo en escena (cultivo creciendo sobre el
  bancal, con el rack y la consola al lado), a 2×.
- `growth/example_scene_steps.png`: las cuatro etapas de ese ejemplo en una
  rejilla 2×2.

### Crecimiento por célula

`growth/cells/` contiene las mismas cuatro etapas en 16×16, pensadas para
mostrar el crecimiento **individual de cada semilla** en una vitrina dividida
en celdas. La vitrina de referencia es la primera versión, vaciada y dividida
en 3×3 celdas: `variants/rack_v1_shelf_empty.png`.

- `growth/cells/cell_stage_1..4.png` + `.aseprite`: una etapa por archivo, ancla
  bottom-center `[8, 16]`.
- `growth/cells/sprites.json`: inventario de las cuatro etapas.
- `growth/example_cells_grid.png`: la vitrina v1 con sus 9 celdas etiquetadas
  (A1–C3) y cada una en una etapa distinta.
- `growth/example_cells_x4.gif`: animación en la que cada celda empieza a crecer
  en un momento distinto, demostrando el crecimiento por semilla.
- `growth/example_cells_steps.png`: fotogramas 1, 3, 5, 7 y 9 de esa animación.

Cada etapa tiene además su propio `.aseprite` en `growth/stages/` para editarla
por separado. La etapa 4 coincide con `crop_leafy`, así que la animación puede
terminar en el sprite maduro ya colocado en la sala.

## Pendientes (fuera de este pack)

- Tileset de la sala: suelo, paredes, banda de pared, ventanal al espacio y
  esclusa.
- Animaciones: parpadeo de leds, ventiladores, plantas meciéndose y estados de
  crecimiento.
- Cultivos alienígenas con paleta propia.
- Escena y layout de `game/content/map/greenhouse/` (props, colisiones,
  interacción con la máquina hidropónica).
