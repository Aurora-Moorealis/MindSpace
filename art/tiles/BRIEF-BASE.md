# Encargo: tileset de la base (muros y pasillos)

Agente de arte. Repositorio: `C:\Users\ramer\Documents\Proyects\MindSpace`.

Otro agente hace el suelo exterior: **no toques `art/tiles/ground/`**,
`game/content/map/tiles/ground_atlas.png` ni `game/content/map/props/`.

## Objetivo

Un **bloque de material** para el interior: suelo de plancha, **muros** y
**pasillos**. Nada más por ahora: sin invernadero, sin taller, sin paneles
solares, sin escotillas, sin máquinas. Eso vendrá después.

## Estilo obligatorio

- Pixel art "de 1993": planos de color, sin degradados, sin antialias, sin
  semitransparencia (alfa 0 o 255).
- **Vista cenital** (top-down). Luz desde arriba-izquierda.
- Base científica nueva: metal limpio y funcional, no oxidado ni sucio.
- Inspiración: el look tileado de Mindustry, sin copiarlo.
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

## Rejilla

- Loseta de **16×16 px de arte**, exportada al doble (**32×32** en pantalla).

## Entregable

`art/tiles/base/build-base.lua` → genera

- `art/tiles/base/base_atlas.aseprite` (**64×64 de arte**, 4×4 de 16×16)
- `game/content/map/tiles/base_atlas.png` (**128×128**, ×2)

### Atlas (columna,fila)

Fila 0 — **suelo interior** (plancha metálica de laboratorio):

- (0,0) plancha lisa, con junta en el borde para que al teselar salga una rejilla
- (1,0) plancha con remaches en las esquinas
- (2,0) rejilla de ventilación
- (3,0) plancha con junta diagonal

Fila 1 — **muros** (vistos desde arriba: cuerpo oscuro y canto iluminado):

- (0,1) muro recto
- (1,1) esquina de muro
- (2,1) muro con ventana al exterior
- (3,1) marco de puerta

Fila 2 — **pasillos**:

- (0,2) pasillo recto, con banda central y luces ámbar a los lados
- (1,2) pasillo en esquina
- (2,2) cruce de pasillos
- (3,2) airlock (umbral con franja de peligro)

Fila 3 — **cierres y transición**:

- (0,3) muro en T
- (1,3) muro extremo (tapa de pasillo)
- (2,3) transición suelo-muro (plancha que muere en el muro)
- (3,3) rejilla de suelo industrial (variante más oscura)

## Reglas

- Los muros tienen que leerse como **muros vistos desde arriba**: cuerpo oscuro
  (`#5F6B78`/`#64707E`) con un canto iluminado de 2 px arriba y una línea negra
  de separación. No son paredes de alzado.
- El suelo interior es **teselable**: la junta va en el borde del tile para que
  al repetirlo se forme una rejilla, sin costuras raras.
- El pasillo debe distinguirse del suelo de sala por **luminosidad**, no solo por
  detalle.
- Los muros no llevan contorno exterior negro en los cuatro lados (se vería una
  cuadrícula): la separación se hace con tono y con la línea interior.

## Herramientas

MCP de Aseprite desde `execute`. Escribe el generador con `write` y ejecútalo:

```
tools.aseprite.run_lua_script({ script: 'dofile("C:/Users/ramer/Documents/Proyects/MindSpace/art/tiles/base/build-base.lua")' })
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

1. Monta una prueba con un pasillo rodeado de muros y una sala de planchas, a
   tamaño real, y guárdala como `art/tiles/base/_qa-sala.png`. Mírala: tiene que
   leerse como una habitación, no como cuadros sueltos.
2. `get_color_stats` dentro de la paleta; `lint_sprite` sin piezas sueltas; alfa
   binario.
3. Revisa a ×8 y a tamaño real.

## Prohibido

- Tocar archivos fuera de `art/tiles/base/` y
  `game/content/map/tiles/base_atlas.png`.
- Commitear, crear `.tscn` / `.tres`, o añadir objetos/máquinas (invernadero,
  taller, paneles, escotillas).

Al terminar responde con: rutas creadas, contenido de cada celda y cómo
comprobaste que se lee como habitación.
