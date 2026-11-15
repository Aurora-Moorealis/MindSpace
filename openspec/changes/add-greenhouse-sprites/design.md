# Design

## Context

Ver `proposal.md` — Why. Restricciones que mandan:

- `docs/art-direction.md` fija rejilla de 32 px, contorno de 1 px `#111827`,
  3–4 valores por material, escala de props (plantas 1×1, consolas 2×1) y la
  regla de que el suelo se mueve entre `#1d2536` y `#33405a`.
- `AGENTS.md` obliga a que cada contenido viva en `content/<tipo>/<nombre>/` y
  a que la máquina `hydroponics` tenga su propio arte en su carpeta.
- La paleta base de 17 colores no tiene ningún verde; el astronauta y los 12
  iconos del toolkit ya se dibujaron con ella y no deben cambiar.
- Solo hay Aseprite (MCP) para dibujar y Godot para revisar; el equipo no tiene
  animador (ver `docs/designs/junior-astronauta-outpost-lunar.md`, alternativa 4).

## Goals / Non-Goals

**Goals:**

- Un pack coherente y autocontenido de 22 sprites estáticos del invernadero.
- Una paleta local de verdes que no contamine el resto del arte.
- Entrega reproducible: fuente, PNG, manifiesto, README y captura de QA.
- Que cualquier sprite se pueda colocar en la rejilla sin adivinar su ancla.

**Non-Goals:**

- Tileset de sala, animaciones, escenas, colisiones y lógica de `hydroponics`.
- Cambiar la paleta base, el astronauta o los iconos del toolkit.
- Definir el layout final de la sala (lo hará `content/map/` cuando exista).

## Decisions

### D1 — Dos dueños de contenido: sala y máquina

El arte de sala (props, cultivos, equipo, decoración) va a
`game/content/map/greenhouse/art/`; el rack, la consola y el tanque de nutrientes
de la máquina van a `game/content/machines/hydroponics/art/`.

- **Por qué:** `hydroponics` es una de las 8 máquinas del diseño y su arte debe
  viajar con ella; el resto es mobiliario de sala. Evita que la máquina dependa
  de archivos fuera de su carpeta.
- **Alternativa descartada:** un único `content/greenhouse/` con todo. Rompe la
  regla de autocontención y obliga a mover archivos cuando se cree la máquina.

### D2 — Un `.aseprite` por sprite, canvas ajustado

Cada sprite tiene su propio `.aseprite` con el canvas exactamente de su tamaño
(16, 32, 64 o 96 px de ancho; 16, 32 o 64 px de alto), una capa `art` y la
paleta del invernadero. Los PNG se exportan a 1× sin escalar.

- **Por qué:** los props tienen tamaños distintos; un lienzo por categoría
  exportaría PNGs del tamaño del lienzo y obligaría a recortar. Con un archivo
  por sprite, el PNG sale ya recortado y la iteración es independiente.
- **Alternativa descartada:** una hoja por categoría con una capa por sprite y
  cortes por slice. Ahorra archivos pero complica el export y la revisión.
- **Coste aceptado:** ~22 fuentes pequeñas en vez de 5 grandes.

### D3 — Rampa de verdes local, cinco pasos

`palette/greenhouse_palette.gpl` contiene los 17 colores base + estos cinco
verdes desaturados:

| Paso | Hex | Uso |
| --- | --- | --- |
| Verde sombra profunda | `#1c2a20` | huecos, sombra bajo hojas, musgo |
| Verde oscuro | `#2f4a33` | sombra de hoja y tallo |
| Verde base | `#4a6b45` | masa principal de la planta |
| Verde claro | `#6d9257` | luz superior de la hoja |
| Verde brillo | `#9cbf7e` | glint de hoja y brote |

- **Por qué:** la rampa cubre el rango de valor del suelo oscuro sin competir
  con el traje blanco; son verdes de baja saturación (≤35 %), no primarios.
- **Regla de contraste:** ningún prop usa el verde base como único valor; el
  contorno `#111827` y al menos un paso de sombra lo separan del suelo.
- **Alternativa descartada:** reutilizar cian para "cultivos bioluminiscentes".
  El cian está reservado a pantallas, líquido y energía (art-direction §8), y
  haría ilegible la diferencia entre comida y tecnología.

### D4 — Estático, un solo frame

Cada `.aseprite` tiene un frame y ningún tag. Las lámparas, ventiladores y
medidores se dibujan "encendidos" de forma fija.

- **Por qué:** decisión del usuario y del diseño (no hay animador); el arte
  estático entra ya en el juego y las animaciones se pueden añadir después sin
  redibujar la silueta.
- **Alternativa descartada:** estados de crecimiento y loops de LED. Añaden
  frames que hoy nadie consume y multiplican la QA.

### D5 — Anclas declaradas en el manifiesto

El punto de apoyo se mide en píxeles desde la esquina superior izquierda del PNG:

| Tipo | Regla | Ancla |
| --- | --- | --- |
| Props de suelo, cultivos, máquina, decoración | bottom-center | `[w/2, h]` |
| Elementos de pared/techo (`grow_lamp`, `fan_unit`, `gauge_panel`, `vent_grille`) | top-center | `[w/2, primera fila opaca]` |

Los elementos de pared se anclan a su borde superior visible (`0` en la lámpara
y la rejilla, `1` en el ventilador, `5` en el panel), no al borde del canvas,
para que cuelguen de la pared sin dejar hueco.

`sprites.json` (un manifiesto por carpeta de contenido) declara
`name`, `file`, `size`, `grid`, `anchor`, `anchor_rule` y `category`. El
manifiesto es la fuente de verdad para quien monte la sala.

### D6 — Catálogo cerrado

| Categoría | Sprite | Tamaño |
| --- | --- | --- |
| Prop | `grow_bed` | 64×32 |
| Prop | `water_tank` | 64×64 |
| Prop | `pipe_elbow` | 32×32 |
| Prop | `seed_crate` | 32×32 |
| Cultivo | `crop_seedling` | 32×32 |
| Cultivo | `crop_leafy` | 32×32 |
| Cultivo | `crop_root` | 32×32 |
| Cultivo | `crop_vine` | 32×64 |
| Equipo | `grow_lamp` | 64×32 |
| Equipo | `fan_unit` | 32×32 |
| Equipo | `sprinkler` | 32×32 |
| Equipo | `gauge_panel` | 32×32 |
| Equipo | `vent_grille` | 32×32 |
| Decoración | `pot_small` | 16×16 |
| Decoración | `watering_can` | 16×16 |
| Decoración | `tool_rack` | 32×32 |
| Decoración | `hose_coil` | 32×32 |
| Decoración | `floor_drain` | 32×32 |
| Decoración | `warning_sign` | 16×16 |
| Máquina | `hydroponics_rack` | 96×64 |
| Máquina | `hydroponics_console` | 64×32 |
| Máquina | `nutrient_tank` | 32×64 |

La lista es el mínimo del spec; si al dibujar falta una pieza imprescindible se
añade con la misma nomenclatura, nunca se sustituye una existente.

### D7 — QA sin escena comprometida

La revisión visual se hace en tres pasos: `view_sprite` por sprite,
`lint_sprite` + `get_color_stats` para píxeles sueltos y colores fuera de
paleta, y una captura compuesta a 850×480 generada con Pillow sobre un fondo de
suelo `#1d2536`/`#33405a` de referencia. Esa composición vive en
`art/previews/integration_850x480.png`; no se crea ni se commitea ninguna escena
`.tscn` de prueba.

Los `.import` se generan abriendo el proyecto en Godot (o con un arranque
headless de importación); nunca se escriben a mano.

## Risks / Trade-offs

- **[Los 22 sprites no caben en una sesión de dibujo]** → el catálogo está
  ordenado por bloques (props → cultivos → equipo → decoración → máquina) y cada
  bloque termina con su revisión; si se corta, el pack sigue siendo utilizable.
- **[El verde se confunde con el suelo azul-gris]** → la rampa empieza dos pasos
  por debajo del verde base y todo prop lleva contorno; la captura a 1× es el
  juez, no el zoom.
- **[El glint verde se lee como cian y roba protagonismo al visor]** → el verde
  brillo está limitado a 2–3 píxeles por hoja y nunca se usa en superficies
  grandes ni en pantallas.
- **[Godot importa con filtrado lineal por defecto]** → el README fija nearest y
  sin mipmaps, y la QA a 1× detecta cualquier interpolación.
- **[Nombres de props que no encajan con el layout futuro]** → los ids son
  descriptivos y estables; el layout puede ignorar piezas, pero no renombrarlas.

## Migration Plan

No hay migración: son archivos nuevos. Rollback = borrar
`game/content/map/greenhouse/` y `game/content/machines/hydroponics/` y sus
`.import`; ningún otro sistema referencia estas rutas todavía.

## Open Questions

Ninguna que afecte al alcance. El orden exacto de los props en el layout de la
sala se decidirá en el cambio que monte `content/map/greenhouse/greenhouse.tscn`.
