# Hidropónica — arte de la máquina

Arte propio de la máquina `hydroponics` del invernadero (produce comida y O₂ en
el diseño del juego). Es solo el visual estático: el `.tscn`, el `.gd` y el
`.tres` de la máquina se crean en su propio cambio, dentro de esta misma carpeta.

## Estructura

```text
art/
├── *.aseprite          fuentes editables (una por sprite, 1 frame)
├── sprites/*.png       export 1× RGBA, recortado al tamaño del sprite
├── palette/            greenhouse_palette.gpl (misma rampa que la sala)
├── previews/
├── variants/           las siete versiones del rack, cada una en su archivo
├── sprites.json        manifiesto: tamaño, rejilla y ancla
└── README.md
```

## Inventario (3 sprites)

| Nombre | Tamaño | Rejilla | Ancla |
| --- | --- | --- | --- |
| `hydroponics_rack` | 96×64 | 3×2 | bottom-center `[48, 64]` |
| `hydroponics_console` | 64×32 | 2×1 | bottom-center `[32, 32]` |
| `nutrient_tank` | 32×64 | 1×2 | bottom-center `[16, 64]` |

El rack es una cámara cilíndrica de vidrio con costillas metálicas y tres pisos
de cultivo, inspirada en los módulos de cultivo presurizados de la referencia:
96×64 px incluyen el casquete del extremo cercano y el extremo lejano en
perspectiva. La consola es el punto de interacción y el tanque de nutrientes
completa el conjunto. Los tres se colocan con el mismo ancla de suelo y comparten
la paleta del invernadero.

Las siete iteraciones del rack están guardadas por separado en `variants/`
(`rack_v1_shelf` … `rack_v7_current`), con una hoja de contactos
`variants_sheet_x3.png`; ver `variants/README.md` para comparar y activar otra.

## Paleta

`palette/greenhouse_palette.gpl` replica la rampa del invernadero: los 17
colores base más los cinco verdes (`#1c2a20`, `#2f4a33`, `#4a6b45`, `#6d9257`,
`#9cbf7e`). El swatch PNG vive en `../../../map/greenhouse/art/palette/`
para no duplicar imágenes entre ambas carpetas.

## Importación en Godot

Mismos pasos que la sala: **2D Pixel**, Filter off, Mipmaps off, Compress
Lossless, Fix Alpha Border, Reimport. Coloca el rack con su ancla
`[48, 64]`, la consola con `[32, 32]` y el tanque con `[16, 64]`.

## Capas de la vitrina (v4) para Godot

La vitrina v4 está separada en dos sprites para que las plantas queden **detrás
del vidrio**:

| Archivo | Contenido | Orden |
| --- | --- | --- |
| `variants/rack_v4_back.png` | Estructura y fondo: interior azul, pisos, casquetes, rail superior, plinto y compuerta. | Detrás (z −5) |
| `variants/rack_v4_cover.png` | Tapas de vidrio: costillas metálicas, tinte translúcido y reflejos, con alpha. | Delante (z 1) |

La escena `visual/rack_layers.tscn` las une con las plantas en medio:

```text
RackLayersDemo
└── Scaled
    ├── Back        (rack_v4_back.png)
    ├── Plants      (celdas cell_v4_stage_1..4)
    └── Cover       (rack_v4_cover.png)
```

`Back` se dibuja primero, después el nodo `Plants` y al final `Cover`; así el
vidrio tapa las plantas y los reflejos quedan por encima. Para la máquina real,
basta meter las celdas de crecimiento bajo un nodo `Plants` entre ambos sprites.

La captura del resultado está en `art/previews/rack_layers_850x480.png`.

## Interfaz ampliada

`art/interaction/` contiene el arte del modo zoom para interactuar con la
vitrina: `hydroponics_zoom_back` (288×192), `hydroponics_zoom_cover` (vidrio) y
un mock de pantalla completa de 850×480. Los rectángulos de las 12 celdas están
en `interaction/sprites.json`. Ver `interaction/README.md`.

## Demo en vivo

`visual/growth_demo/growth_demo.tscn` es la **escena principal actual** del
proyecto: pulsa **F5** y verás la vitrina pequeña. **Haz clic sobre ella** y se
abre la interfaz ampliada (`visual/growth_interface/growth_interface.tscn`),
donde se siembra y se recoge. `CERRAR` vuelve a la vitrina.

La interfaz usa las capas de la v4 ampliada: `RearCap` detrás, `Back`, celdas,
`Cover`, `FrontCap` y el hover de selección. El estado de las celdas y el
crecimiento viven en `content/machines/hydroponics/hydroponics_state.gd`
(`HydroponicsState`), así que siguen corriendo al cerrar la interfaz y la
vitrina pequeña también refleja las etapas actuales.

Cuando exista `scenes/base/base.tscn`, cambia `run/main_scene` en
`project.godot` a esa escena.

## Pendientes

- `hydroponics.tscn` + `hydroponics.gd` + su `.tres` local con `hint_text` y las
  dos mejoras de la máquina.
- Indicador de estado (encendida/apagada/averiada) sobre el rack: se resolverá
  con modulación o un sprite de overlay en el cambio de gameplay, no aquí.
- Animaciones de bandejas o leds.
