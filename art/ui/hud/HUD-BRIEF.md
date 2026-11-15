# HUD in-game: brief compartido (hotbar + barra de vida)

Documento de trabajo para los dos agentes de arte de la UI de partida. **No es una
spec**: las reglas normativas están en `openspec/specs/art-style/spec.md` y mandan
sobre este texto. Aquí solo se concreta la geometría y el reparto de ficheros para
que los dos assets parezcan dibujados por la misma mano.

## Objetivo

Interfaz de la partida, estilo Minecraft en la disposición:

- **Hotbar/hub del jugador:** 5 espacios, abajo y centrado, con un marco de panel
  y un indicador de espacio seleccionado aparte.
- **Barra de vida:** arriba y centrada, con corazón a la izquierda, pista hundida
  y relleno segmentado.

Estética: panel oscuro navy con borde metálico, bisel de dos tonos y tornillos en
las esquinas, la misma construcción que `art/ui/build-buttons.lua` pero en la
variante oscura de HUD para que se lea sobre la escena. Nada de grises fuera de la
paleta, nada de degradados ni antialias.

## Reglas que no se negocian

1. **Rejilla:** se dibuja a 1x art (lienzo 425×240). El PNG que consume Godot se
   exporta a **2x** con vecino más cercano (850×480). Cada píxel artístico = 2×2
   píxeles de pantalla.
2. **Paleta cerrada:** solo los colores de la tabla de abajo. Si hace falta otro,
   se para y se pide.
3. **Contorno:** 1 px continuo de `#0F171F` en toda la silueta exterior.
4. **Luz:** única, desde arriba-izquierda. Bisel claro arriba/izquierda, oscuro
   abajo/derecha. Sin *pillow shading*.
5. **Alfa binario:** 0 o 255. Fondo transparente de verdad, sin semitransparencias.
6. **Sin antialias** ni píxeles de transición; diagonales en escalones regulares.
7. **Interfaz:** medidas y separaciones en píxeles enteros del lienzo art (que ya
   son múltiplos de 2 en pantalla).
8. **Una sola pieza:** la silueta no puede tener fragmentos despegados ni píxeles
   sueltos. Los huecos interiores (pozos) van rodeados de opaco, no flotan.

## Paleta (solo estos)

| Uso | Hex |
| --- | --- |
| Contorno | `#0F171F` |
| Cuerpo del panel (navy) | `#26334F` |
| Bisel claro | `#3D5175` |
| Bisel oscuro | `#1B2540` |
| Borde metálico claro | `#92A1B2` |
| Borde metálico oscuro | `#6A7684` |
| Fondo de pozo | `#14192B` |
| Sombra interior de pozo | `#081542` |
| Borde interior de pozo | `#1F3152` |
| Tornillo: aro / cabeza / brillo / sombra | `#5F6B78` / `#A9B6C4` / `#DFE8F0` / `#6A7684` |
| Teal selección: claro / base / oscuro | `#57C8CC` / `#4AA8B4` / `#2A7F8B` |
| Fuego vida: claro / base / oscuro | `#FFC93C` / `#E2551B` / `#9C5F0C` |
| Ámbar aviso: claro / base / oscuro | `#FFE27A` / `#F0A72A` / `#9C5F0C` |
| Separador de segmento | `#1B2540` |

## Receta del panel (idéntica en los dos assets)

Usar `art/ui/hud/hud_common.lua` (`dofile`). `H.panel(img, w, h)` ya dibuja:

1. Contorno de 1 px `#0F171F`.
2. Borde metálico de 1 px: `#92A1B2` arriba/izquierda, `#6A7684` abajo/derecha.
3. Cuerpo `#26334F`.
4. Bisel interior de 1 px: `#3D5175` arriba/izquierda, `#1B2540` abajo/derecha.

Tornillos: `H.screw(img, ox, oy)` de 5×5 en las cuatro esquinas, a 3 px del borde
(ox/oy = 3 y w-8 / h-8).

Pozos: `H.well(img, x, y, w, h)` deja el borde `#0F171F`, el suelo `#14192B`,
sombra `#081542` arriba/izquierda y borde `#1F3152` abajo/derecha.

## Reparto y geometría exacta

### Agente A — hotbar (`hud_hotbar`, `hud_slot_selected`)

**`hud_hotbar` — 144×40 art (288×80 runtime)**

- Panel completo con `H.panel` + 4 tornillos en (3,3), (136,3), (3,32), (136,32).
- 5 pozos de 24×24 en `x = 8 + 26*i` (8, 34, 60, 86, 112), `y = 8`.
- Sin números ni iconos dentro: los espacios van vacíos.
- El pozo es opaco (no transparente): encima se dibujarán los objetos.

**`hud_slot_selected` — 24×24 art (48×48 runtime)**

- No es un overlay que sobresale: ocupa exactamente el mismo rectángulo que un
  pozo y se dibuja **detrás del objeto**, en lugar del pozo. Así no invade el
  panel ni tapa los tornillos de las esquinas.
- 1 px exterior `#0F171F`.
- 2 px de teal: `#57C8CC` arriba/izquierda, `#2A7F8B` abajo/derecha. El teal es el
  color de interacción del juego (hover de los botones), no usar ámbar aquí.
- Centro interior de 18×18 en `#14192B` (el objeto de 16×16 se dibuja encima y
  deja 1 px de margen).
- Sin esquinas redondeadas ni muescas: marco continuo de 1 pieza.

### Agente B — barra de vida (`hud_health_bar`, `hud_health_fill`)

**`hud_health_bar` — 164×24 art (328×48 runtime)**

- Panel completo con `H.panel` + 4 tornillos en (3,3), (156,3), (3,16), (156,16).
- Corazón de 12×12 centrado en la zona izquierda, en `x = 10..21`, `y = 6..17`.
  Fuego: cuerpo `#E2551B`, brillo `#FFC93C` arriba-izquierda, sombra `#9C5F0C`
  abajo-derecha, contorno `#0F171F`. Debe leerse a tamaño de juego.
- Pista hundida: rectángulo exterior `x = 32..153`, `y = 6..17` (122×12) con
  contorno de 1 px `#0F171F`; interior `x = 33..152`, `y = 7..16` (120×10) en
  `#14192B`. Sin bisel interior: el relleno cubre exactamente el interior.
- Sin texto: la etiqueta la pone Godot.

**`hud_health_fill` — 120×10 art (240×20 runtime)** y variante
**`hud_health_fill_low`** con la misma geometría:

- 8 segmentos de 15 px: 14 px de relleno + 1 px de separador `#1B2540`.
- `hud_health_fill`: fila superior `#FFC93C`, cuerpo `#E2551B`, fila inferior
  `#9C5F0C`.
- `hud_health_fill_low`: fila superior `#FFE27A`, cuerpo `#F0A72A`, fila inferior
  `#9C5F0C`.
- Debe encajar exacto en el interior de la pista (120×10) y verse segmentado.

### Tira minimal de recursos (`hud_resources_strip`)

**88×36 art (176×72 runtime), sin panel ni tornillos**

- Fondo transparente: solo se dibujan los iconos, las pistas y el texto que pone
  Godot. Nada de fondo azul.
- Cuatro filas en `y = 0, 9, 18, 27`: icono de 8×8 en `x = 0` y pista exterior
  `x = 10..69` (60×6) con contorno `#0F171F` e interior 58×4 en `#14192B`.
- Rellenos de 58×4: fila superior clara, dos de cuerpo y una inferior oscura.
  El relleno cubre exactamente el interior de la pista.
- Colores: O₂ teal (`#57C8CC/#4AA8B4/#2A7F8B`), agua en la rampa de hielo
  (`#C4D8DF/#8FAAB4/#5C7680`), comida ámbar (`#FFE27A/#F0A72A/#9C5F0C`) y
  energía en la rampa silícea (`#DDD5BE/#B8AE92/#8C846C`).
- El porcentaje de cada recurso va a la derecha de la pista, a 8 px, en el color
  claro de su rampa y con contorno de 1 px para leerse sobre el mundo.
- El Sol no tiene sprite: es una etiqueta de texto de 8 px arriba a la derecha.

## Ficheros (cada agente toca SOLO los suyos)

Patrón: maestro `.aseprite` + generador `.lua` en `art/ui/hud/`, preview 1x en
`art/ui/hud/`, PNG runtime 2x en `game/assets/images/ui/hud/`.

| Asset | Maestro | Generador | PNG 1x (preview) | PNG 2x (runtime) |
| --- | --- | --- | --- | --- |
| Hotbar | `art/ui/hud/hud_hotbar.aseprite` | `art/ui/hud/build_hotbar.lua` | `art/ui/hud/hud_hotbar_1x.png` | `game/assets/images/ui/hud/hud_hotbar.png` |
| Selección | `art/ui/hud/hud_slot_selected.aseprite` | `art/ui/hud/build_slot_selected.lua` | `art/ui/hud/hud_slot_selected_1x.png` | `game/assets/images/ui/hud/hud_slot_selected.png` |
| Barra | `art/ui/hud/hud_health_bar.aseprite` | `art/ui/hud/build_health_bar.lua` | `art/ui/hud/hud_health_bar_1x.png` | `game/assets/images/ui/hud/hud_health_bar.png` |
| Relleno | `art/ui/hud/hud_health_fill.aseprite` | `art/ui/hud/build_health_fill.lua` | `art/ui/hud/hud_health_fill_1x.png` | `game/assets/images/ui/hud/hud_health_fill.png` |
| Relleno bajo | `art/ui/hud/hud_health_fill_low.aseprite` | `art/ui/hud/build_health_fill.low.lua` | `art/ui/hud/hud_health_fill_low_1x.png` | `game/assets/images/ui/hud/hud_health_fill_low.png` |
| Tira de recursos | `art/ui/hud/hud_resources_strip.aseprite` | `art/ui/hud/build_stats.lua` | `art/ui/hud/hud_resources_strip_1x.png` | `game/assets/images/ui/hud/hud_resources_strip.png` |
| Relleno O₂ | `art/ui/hud/hud_stat_fill_oxygen.aseprite` | `art/ui/hud/build_stats.lua` | `art/ui/hud/hud_stat_fill_oxygen_1x.png` | `game/assets/images/ui/hud/hud_stat_fill_oxygen.png` |
| Relleno agua | `art/ui/hud/hud_stat_fill_water.aseprite` | `art/ui/hud/build_stats.lua` | `art/ui/hud/hud_stat_fill_water_1x.png` | `game/assets/images/ui/hud/hud_stat_fill_water.png` |
| Relleno comida | `art/ui/hud/hud_stat_fill_food.aseprite` | `art/ui/hud/build_stats.lua` | `art/ui/hud/hud_stat_fill_food_1x.png` | `game/assets/images/ui/hud/hud_stat_fill_food.png` |
| Relleno energía | `art/ui/hud/hud_stat_fill_energy.aseprite` | `art/ui/hud/build_stats.lua` | `art/ui/hud/hud_stat_fill_energy_1x.png` | `game/assets/images/ui/hud/hud_stat_fill_energy.png` |

`hud_common.lua` es compartido: **solo se lee**, no se edita.

## Colocación en pantalla (850×480)

Coordenadas en píxeles de pantalla (el PNG ya está a 2x). Todas son pares para
mantener la rejilla.

| Elemento | Posición | Tamaño |
| --- | --- | --- |
| Barra de vida (fondo) | `(260, 24)` | 328×48 |
| Relleno de vida | `(326, 38)` = barra + `(66, 14)` | 240×20, recortado por progreso |
| Tira de recursos | `(8, 8)` | 176×72 |
| Barra O₂ / agua / comida / energía | `(30, 12/30/48/66)` | 116×8 |
| Porcentaje de cada recurso | `(152, 8/26/44/62)` | 32×16, 8 px, alineado a la derecha |
| Texto del Sol | `(674, 8)` | 160×16, 8 px, alineado a la derecha |
| Hotbar | `(280, 372)` | 288×80 |
| Espacio `i` (0–4) | `(296 + 52·i, 388)` | 48×48 |
| Selección de espacio `i` | `(296 + 52·i, 388)` | 48×48, detrás del objeto |

Godot: `TextureRect` para los paneles y el hotbar; `TextureProgressBar` para cada
relleno (textura de progreso y valor 0–capacidad). La selección va debajo del
icono del objeto, en el mismo rectángulo que su pozo. El filtro Nearest ya es
global en `project.godot`.

## Proceso obligatorio

1. Escribir el generador `.lua` y ejecutarlo con Aseprite. Preferido:
   `tools.aseprite.run_lua_script({ script: 'dofile("C:/.../build_x.lua")' })`;
   alternativa por CLI: `& "C:\Program Files\Aseprite\Aseprite.exe" -b --script C:\...\build_x.lua`.
2. Guardar el maestro `.aseprite`, exportar el PNG 1x y generar el 2x con
   ImageMagick `-filter point -resize 200%`.
3. **Mirar el resultado** a ×8 (`view_sprite` o abrir el PNG) y corregir. Mínimo
   dos pasadas de revisión; no entregar la primera versión.
4. QA antes de terminar:
   - `get_color_stats`: todos los colores de la paleta.
   - alfa binario: `magick img.png -format "a-min=%[fx:minima.a] a-max=%[fx:maxima.a] colores=%k" info:`
     → `a-min=0 a-max=1`.
   - `lint_sprite`: sin piezas despegadas ni píxeles sueltos.
   - contorno continuo de 1 px recorriendo la silueta.
   - a tamaño de juego (2x) se lee bien sobre fondo oscuro.
5. Informar al terminar con: rutas creadas, tamaños, colores usados, resultado de
   QA y captura del preview.

## Prohibido

- Tocar ficheros del otro agente, `hud_common.lua`, el tema, escenas o código.
- Crear escenas, autoloads o assets fuera de las rutas de la tabla.
- Colores fuera de la paleta, degradados, antialias, semitransparencias, texto
  horneado en el sprite.
