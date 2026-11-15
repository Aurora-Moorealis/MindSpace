# Interfaz ampliada de la vitrina

Arte para una pantalla de interacción con la vitrina hidropónica en modo zoom:
la cámara se acerca a la cámara de cultivo y cada celda se puede seleccionar.

## Archivos

| Archivo | Tamaño | Qué es |
| --- | --- | --- |
| `hydroponics_zoom_back.aseprite` / `.png` | 288×192 | Vitrina ampliada (3× la v4 de 96×64): chasis, 4 paneles × 3 pisos, plantas y consola inferior. Sin casquetes; deja un hueco oscuro a la izquierda y un borde de cierre a la derecha. |
| `hydroponics_zoom_front_cap.aseprite` / `.png` | 288×192 | **Tapa delantera ovalada** (extremo izquierdo, el más cercano). Va por encima del vidrio. |
| `hydroponics_zoom_rear_cap.aseprite` / `.png` | 288×192 | **Tapa trasera** (anillo fino del extremo derecho, el lejano). Va detrás de la vitrina. |
| `hydroponics_zoom_cover.aseprite` / `.png` | 288×192 | Tapas de vidrio: costillas, tinte translúcido y reflejos. Va **delante** de la vitrina. |
| `hydroponics_zoom_ui.png` | 850×480 | Mock completo de la pantalla: marco, título, vitrina, barras de estado, rejilla de celdas y botones. |
| `sprites.json` | — | Rectángulos de las 12 celdas (A1–C4) y datos de las capas. |

## Capas y orden sugerido en Godot

| Capa | `z_index` sugerido |
| --- | --- |
| `RearCap` (tapa trasera, derecha) | −6 |
| `Back` (vitrina) | −5 |
| `Cover` (vidrio frontal) | 1 |
| `FrontCap` (tapa delantera, izquierda) | 2 |
| Selección / hover | 3 |

Las dos tapas están en lienzos completos de 288×192; colocadas en `(0,0)`
coinciden con su posición original. Se pueden mover, ocultar o intercambiar de
orden sin tocar el `back`.

## Escena interactiva

`visual/growth_interface/growth_interface.tscn` monta esta interfaz en Godot:

- La vitrina usa `hydroponics_zoom_back_empty` + las celdas de
  `growth/cells_v4/` + `cover` + `front_cap`, con `rear_cap` detrás.
- **Clic en una celda vacía** de la vitrina: siembra una semilla ahí.
- **Clic en una planta en crecimiento**: abre una pestaña con **QUITAR**.
- **Clic en una planta madura**: pestaña con **RECOGER** (suma a `COSECHADAS`)
  o **QUITAR**.
- **X** de la pestaña o clic fuera: la cierra sin tocar la planta.
- Cada semilla crece por su cuenta: base 4 s por etapa y 50 % de probabilidad de
  tardar entre 3 y 6 s (se sortea al sembrar).
- **CERRAR** vuelve a la vitrina pequeña.
- Los contadores `SEMBRADAS` / `MADURAS` / `COSECHADAS` se actualizan en vivo.
- El estado de las 12 celdas vive en `HydroponicsState` (clase estática con
  tiempo real): al cerrar la interfaz el crecimiento sigue corriendo y, al
  volver a abrirla, cada planta aparece en la etapa que le corresponde. La
  vitrina pequeña también muestra ese progreso.

Captura: `art/previews/hydroponics_interface_850x480.png`.

## Celdas

La rejilla es 4 paneles × 3 pisos = 12 celdas. Sus rectángulos están en
`sprites.json`, en coordenadas del sprite de 288×192:

```text
A1 A2 A3 A4
B1 B2 B3 B4
C1 C2 C3 C4
```

Cada celda mide 36×34 px y las plantas del fondo están dibujadas en la capa
`back`. Para una versión interactiva, las plantas pueden sustituirse por los
sprites de crecimiento `growth/cells_v4/` (12×12 a 3× = 36×36) manteniendo las
posiciones de los rectángulos.

## Uso en Godot

1. `Back` (zoom back) como capa inferior.
2. Las plantas o la selección de celda en medio.
3. `Cover` (zoom cover) como última capa.
4. `texture_filter` en Nearest y usar los rects de `sprites.json` para el hit
   test de cada celda.

El mock `hydroponics_zoom_ui.png` sirve de referencia de composición; no es una
escena. La demo jugable actual sigue siendo
`visual/growth_demo/growth_demo.tscn` y no se ha tocado.
