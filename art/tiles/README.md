# Tilesets del mundo

Arte del terreno y de la base. Las reglas (paleta, rejilla, alfa) están en la
spec `art-style`; aquí solo se documenta el contenido de cada atlas.

## Rejilla

- Loseta de **16×16 px de arte**, exportada al doble: **32×32 px** en pantalla.
- Los maestros viven en `art/tiles/<set>/` y los PNG que usa Godot en
  `game/content/map/`.
- Los fondos de terreno repiten el color base en el borde: al colocar dos losetas
  iguales no debe verse costura.

## `ground_atlas.png` — 4×2 (128×64)

**Un solo suelo.** Las ocho losetas son regolito basáltico con el mismo tono base
(`#726F6B`); solo cambia el detalle, así que cualquier mezcla se lee como una
superficie continua. El suelo es oscuro: el exterior se ve bajo y el interior de
la base, iluminado, contrasta.

| Fila | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| **0** | liso | motas finas | guijarros | guijarros dispersos |
| **1** | parche de polvo | huellas | compactado por el rover | removido |

## `minerals.png` — 4 calcas (128×32)

Los minerales **no son suelo**: son **motas** que se colocan encima. Cada mota es
una pepita de 2×2 px de arte con el brillo en la esquina superior izquierda y la
sombra en la inferior derecha, de modo que resalta sobre el regolito oscuro sin
taparlo con un bloque de color. Al colocar varias losetas seguidas se forma una
veta.

| Índice | Material | Brillo |
| --- | --- | --- |
| 0 | ilmenita (FeTiO₃) | metal `#A9B6C4` |
| 1 | material silícico (SiO₂) | blanco `#DFE8F0` |
| 2 | hielo de agua (H₂O) | blanco `#DFE8F0` |
| 3 | basalto (grano volcánico) | apagado `#6A7684` |

## `rocks.png` — 6 props (192×96)

Rocas sueltas para poblar el terreno, en dos tonos (regolito y basalto). Se
colocan como decoración encima del suelo, no como losetas.

## `base_atlas.png` — 4×4 (128×128)

Interior de la base (vista cenital). Solo suelo, muros y pasillos; el equipo de
cada sala se añadirá después.

| Fila | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| **0** | plancha lisa | plancha con remaches | rejilla de ventilación | plancha con junta diagonal |
| **1** | muro recto | esquina de muro | muro con ventana | marco de puerta |
| **2** | pasillo recto | pasillo en esquina | cruce de pasillos | airlock |
| **3** | muro en T | muro extremo / tapa | transición plancha→muro | rejilla industrial |

### Los muros se giran en el mapa

La loseta de muro está dibujada con el canto iluminado al **norte y oeste** y la
línea de apoyo al **sur y este**. Para formar un anillo continuo, el mapa la
**rota** (90°/180°/270°) en los tramos verticales y en las esquinas. No están
dibujadas las cuatro orientaciones: se giran.

## TileSet de Godot

| Archivo | Losetas | Atlas | Rejilla |
| --- | --- | --- | --- |
| `tiles/ground_tileset.tres` | 8 | `tiles/ground_atlas.png` | 32×32 |
| `tiles/base_tileset.tres` | 16 | `tiles/base_atlas.png` | 32×32 |
| `props/props_tileset.tres` | 10 | `props/props_atlas.png` | 32×32 |

### Datos por loseta

Los tres TileSet llevan las mismas capas de datos personalizados, para que el
código consulte la loseta en vez de recordar coordenadas:

| Capa | Tipo | Para qué |
| --- | --- | --- |
| `material` | String | `regolito`, `muro`, `pasillo`, `roca`, `ilmenita`… |
| `detail` | String | variante concreta (`liso`, `esquina`, `deposito`…) |
| `solid` | Bool | si bloquea el paso |

Ejemplo: `TileData.get_custom_data("solid")` en una loseta de muro devuelve
`true`; en una de pasillo, `false`.

### Orden de las losetas

| TileSet | Fila 0 | Fila 1 | Fila 2 | Fila 3 |
| --- | --- | --- | --- | --- |
| `ground` | liso, motas, guijarros, guijarros dispersos | polvo, huellas, compactado, removido | — | — |
| `props` | 5 rocas | roca + ilmenita, silícico, hielo, basalto | — | — |
| `base` | plancha lisa, remaches, rejilla, junta | muro, esquina, ventana, puerta | pasillo, esquina, cruce, airlock | muro T, extremo, transición, rejilla industrial |

### Verificación

`game/tests/_tileset_check.gd` carga los tres, cuenta las losetas y comprueba que
cada una tiene datos:

```powershell
godot --headless --path game -s tests/_tileset_check.gd
```

## Regenerar

```powershell
& "C:\Program Files\Aseprite\Aseprite.exe" -b --script "...\art\tiles\ground\_run.lua"
& "C:\Program Files\Aseprite\Aseprite.exe" -b --script "...\art\tiles\base\_run.lua"
```

Los `_run.lua` solo hacen `dofile` del generador, para poder iterar el `.lua`
grande sin reescribirlo.

## Pruebas visuales

| Archivo | Qué comprueba |
| --- | --- |
| `resultado.png` | resumen de todo: atlas, campo, calcas y rocas |
| `ground/_qa-campo.png` | 8×6 losetas mezcladas: se lee una sola superficie |
| `base/_qa-sala.png` | dos salas con pasillo, muros, ventana, airlock y escotilla |

## Pendiente

- El equipo de sala (invernadero, taller, paneles): bloque siguiente.
- Colocar las calcas de mineral en una línea base de pruebas en Godot.
