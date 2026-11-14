# Encargo: tileset de suelo lunar (campo continuo)

Agente de arte. Repositorio: `C:\Users\ramer\Documents\Proyects\MindSpace`.

Otro agente hace la base: **no toques `art/tiles/base/`** ni
`game/content/map/tiles/base_atlas.png`.

## Objetivo

Un **bloque de material** para el exterior: el suelo lunar tiene que leerse como
**una sola superficie continua**, no como un mosaico de cuadros de colores. Solo
arte de terreno; nada de objetos, máquinas ni escenas.

## Estilo obligatorio

- Pixel art "de 1993": planos de color, sin degradados, sin antialias, sin
  semitransparencia (alfa 0 o 255).
- **Vista cenital** (top-down). Luz desde arriba-izquierda.
- Inspiración: el suelo tileado de Mindustry, sin copiarlo.
- Sin texto, sin iconos.

## Paleta cerrada

| Rampa | Hex |
| --- | --- |
| contorno | `#0F171F` |
| casco | `#DFE8F0` `#BCC9D6` `#92A1B2` `#7B8794` `#64707E` `#5F6B78` |
| metal | `#A9B6C4` `#6A7684` |
| teal | `#57C8CC` `#4AA8B4` `#2F9FA6` `#2A7F8B` `#186269` |
| ámbar | `#FFE27A` `#F0A72A` `#9C5F0C` |
| navy | `#3D5175` `#26334F` `#1B2540` |
| regolito | `#CFCCC7` `#AAA7A2` `#85827E` `#67645F` |
| basalto | `#44444E` `#2E2E36` `#1E1E25` |
| ilmenita | `#55607A` `#343A4C` `#1F2331` |
| silíceo | `#DDD5BE` `#B8AE92` `#8C846C` |
| hielo | `#C4D8DF` `#8FAAB4` `#5C7680` |

## Rejilla

- Loseta de **16×16 px de arte**, exportada al doble (**32×32** en pantalla).
- El atlas se dibuja a la rejilla de 16 y se exporta con vecino más cercano.

## Regla clave: continuidad

- Las **8 variantes de regolito** comparten el mismo tono base (`#AAA7A2`) y solo
  cambian el detalle (guijarros, polvo, huellas). Cualquier mezcla de ellas debe
  leerse como una sola superficie: sin cambio de tono entre losetas.
- Los minerales **no son cuadros**: el depósito se disuelve en el regolito con
  borde tramado (dithering ordenado) en los cuatro lados del tile, de modo que
  dos losetas de mineral contiguas se fundan y una loseta de mineral junto a
  regolito no muestre un borde recto.
- Ningún borde de tile lleva contorno negro.

## Entregables

1. `art/tiles/ground/build-ground.lua` → genera
   - `art/tiles/ground/ground_atlas.aseprite` (**64×64 de arte**, 4×4 de 16×16)
   - `game/content/map/tiles/ground_atlas.png` (**128×128**, ×2)
2. `art/tiles/ground/build-rocks.lua` → genera
   - `art/tiles/ground/rocks.aseprite` (**96×48 de arte**)
   - `game/content/map/props/rocks.png` (**192×96**, ×2)

### Atlas (columna,fila)

Fila 0 — regolito, campo continuo:

- (0,0) liso
- (1,0) liso con motas finas
- (2,0) con guijarros pequeños
- (3,0) con guijarros dispersos

Fila 1 — regolito, más variantes del mismo campo:

- (0,1) con polvo acumulado suave
- (1,1) con huellas tenues
- (2,1) compactado (paso de rover)
- (3,1) removido (zona excavada, algo más oscuro pero del mismo material)

Fila 2 — depósitos con borde tramado:

- (0,2) ilmenita (FeTiO₃), depósito
- (1,2) ilmenita densa
- (2,2) material silícico (SiO₂), depósito
- (3,2) silícico veteado

Fila 3 — depósitos y borde de terreno:

- (0,3) hielo de agua (H₂O), vetas
- (1,3) regolito helado (hielo mezclado)
- (2,3) basalto (suelo más oscuro, borde tramado)
- (3,3) borde de cráter (transición suave, sin costura)

### Rocas (96×48 de arte)

Seis rocas sueltas, tamaños distintos (dos ~16×16, dos ~24×16, dos ~32×24), gris
lunar con alguna en basalto, sombra dura abajo-derecha y contorno de 1 px.
Vistas desde arriba, no montañas.

## Herramientas

MCP de Aseprite desde `execute`. Escribe el generador con `write` y ejecútalo:

```
tools.aseprite.run_lua_script({ script: 'dofile("C:/Users/ramer/Documents/Proyects/MindSpace/art/tiles/ground/build-ground.lua")' })
```

- Ver: `tools.aseprite.view_sprite({ filename, scale: 8, grid: true, rulers: true })`
- Colores: `get_color_stats`. Piezas: `lint_sprite`.

API: `Sprite(w,h,ColorMode.RGB)`, `spr:newLayer()`, `spr:newCel(layer,1,img,Point(0,0))`,
`spr:saveAs(p)`, `spr:saveCopyAs(p)`, `Image(w,h,ColorMode.RGB)`,
`img:putPixel(x,y,c)` (**no existe setPixel**), `app.pixelColor.rgba(r,g,b,255)`.
Para el PNG al doble, escribe cada píxel en un bloque de 2×2.

**OJO:** si hay otra instancia de Aseprite abierta, el proceso puede volver antes
de terminar. Comprueba con `Test-Path` que el archivo existe.

## QA obligatorio

1. Monta una prueba de **4×4 losetas de regolito mezcladas al azar** y comprueba
   que se ve una sola superficie (guarda la prueba como
   `art/tiles/ground/_qa-continuo.png` y mírala).
2. Monta una prueba de una loseta de ilmenita rodeada de regolito y comprueba que
   no hay borde recto.
3. `get_color_stats` dentro de la paleta; `lint_sprite` sin piezas sueltas; alfa
   binario.
4. Revisa a ×8 y a tamaño real.

## Prohibido

- Tocar archivos fuera de `art/tiles/ground/` y `game/content/map/tiles|props/`.
- Commitear, crear `.tscn` / `.tres`, o añadir objetos/máquinas.

Al terminar responde con: rutas creadas, contenido de cada celda y cómo
comprobaste la continuidad.
