# Guía estética de MindSpace (manual)

Este documento es el **manual de procedimiento** del arte del juego: procesos,
herramientas y errores frecuentes.

Las **reglas** —rejilla, paleta, contorno, luz, alfa, tipografía— no están aquí:
viven como contrato en `openspec/specs/art-style/spec.md`. Si una regla y este
manual se contradicen, manda la spec.

Si algo de aquí choca con una petición directa del autor, manda el autor; pero
entonces hay que actualizar la spec y este manual.

---

## 1. La idea que hay detrás

**Pixel art de 1993, no un dibujo pixelado.**

La diferencia no es el tamaño, es el método:

| Un dibujo pixelado | Pixel art |
| --- | --- |
| Se hace grande y se reduce | Se dibuja a la rejilla final |
| Degradados suaves | Bandas de color planas |
| Antialias en los bordes | Contorno duro de 1 px |
| Cientos de colores | 12–20 colores con intención |
| Detalle fino y ruido | Formas grandes y legibles |

Cuando un asset "no se ve retro", casi siempre es por degradados, bordes suaves
o demasiados colores. Nunca por el tamaño.

Lo que esto implica en la práctica está en la spec; esta sección solo explica por
qué las reglas son las que son.

---

## 2. Proceso: crear un fondo (850×480)

Así se hizo el fondo del menú y así se hacen los *stills* de intro.

1. **Concepto** con el generador de imágenes, pidiendo explícitamente: pixel art
   retro, ~16 colores, contorno negro de 1 px, formas planas, dithering, **sin**
   degradados, sin textura fotográfica y sin antialias.
2. **Conversión a la rejilla real** con `art/pixelize.ps1`:

   ```powershell
   pwsh -File pixelize.ps1 -In raw.png -Out fondo.png -Width 425 -Height 240 -Colors 24 -Scale 2
   ```

   Genera 850×480 con píxel de 2×2 mediante vecino más cercano.
3. **Revisión a ojo** a ×3. Los fallos típicos del generador son ruido, colores
   embarrados y bordes suaves.
4. **Cierre de paleta**: cuantizar a un número bajo de colores (`-colors 24` a
   `-colors 96`) sin dither de Floyd-Steinberg, que ensucia.
5. **Zona de UI despejada**: deja un tercio de la imagen con poco detalle para
   título y botones, y comprueba que ningún elemento de fondo queda cortado por
   el hueco entre dos controles.

> Lo que arruina un fondo es el **degradado suave**. Si el cielo tiene bandas y
> el suelo tiene tramado, el resto perdona mucho.

---

## 3. Proceso: crear un sprite

1. **Fija el diseño antes de dibujar**: qué piezas tiene, de qué color cada una y
   qué comparten las distintas vistas. Sin esto, dos vistas del mismo objeto
   parecen dos objetos.
2. **Dibuja a la rejilla final.** Si el sprite medirá 64 px de alto, se dibuja a
   64. Reducir un sprite grande destruye el contorno: es el error más caro y el
   más frecuente.
3. **Silueta primero**: una forma plana, y compruébala a tamaño de juego.
4. **Planos de color** por material, con su rampa.
5. **Sombra con intención**: un lado oscuro, sombra bajo los voladizos.
6. **Detalle**: remaches, costuras, rejillas. Poco y con ritmo regular.
7. **Contorno** al final.
8. **QA** (sección 6) y revisión a ×4–×8.

### Limpiar un sprite que ya existe

Cuando el asset viene de una imagen generada (con ruido y colores sucios), **no
lo redibujes: remapea la paleta y conserva el dibujo**.

1. Convertir la imagen a modo RGB en Aseprite.
2. Clasificar cada píxel por su índice de color original y asignarle el color
   limpio equivalente de la paleta de la spec.
3. Forzar alfa binario.
4. Recalcular el contorno continuo.
5. Arreglar solo los defectos estructurales (piezas desalineadas, patas
   desiguales, elementos que flotan).

Rehacer el dibujo desde cero suele salir **peor**: se pierde el detalle que le
daba carácter. Remapear conserva el diseño y limpia la ejecución. El ejemplo real
está en `art/sprites/ase/` con su `README.md`.

---

## 4. Herramientas

### Aseprite por MCP

| Necesidad | Herramienta |
| --- | --- |
| Ver el sprite dentro del chat | `view_sprite` (`region` para zoom, `scale` 4–12) |
| Dibujar formas | `draw_ellipse_at`, `draw_polygon`, `fill_area_at`, `draw_rows` |
| Contorno de 1 px | `outline_cel` |
| Contar colores | `get_color_stats` |
| Píxeles sueltos y piezas despegadas | `lint_sprite` |
| Exportar para revisar | `export_frame` con `scale: 8` |
| Lote grande de operaciones | `run_lua_script` |

Guarda los generadores como `.lua` y ejecútalos con
`run_lua_script({ script: 'dofile("<ruta>.lua")' })`: así se iteran con un editor
de texto en vez de reenviar el script entero. Ejemplos reales en
`art/sprites/ase/` y `art/ui/`.

> Aseprite puede devolver el control antes de terminar si ya hay otra instancia
> abierta. Si encadenas pasos en PowerShell, deja un `Start-Sleep` corto o
> comprueba que el archivo existe antes de leerlo.

### ImageMagick

```powershell
$m = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
& $m sprite.png -filter point -resize 200% sprite@2x.png
& $m a.png b.png +append comparacion.png
```

`-filter point` es obligatorio al escalar: cualquier otro filtro interpola.

---

## 5. En Godot

- Filtro de textura **Nearest** global: ya está en `project.godot`.
- Nada de escalar sprites con `scale` arbitrario en el inspector: si un sprite
  necesita otro tamaño, se dibuja a ese tamaño.
- Los `TextureRect` de fondo van anclados a pantalla completa con la textura
  exacta de 850×480 y `stretch_mode = scale`.
- Los paneles y botones usan el tema compartido `themes/pixel_theme.tres`. Si
  hace falta un estilo nuevo, se añade al tema, no al nodo.

---

## 6. Comprobaciones antes de dar un asset por bueno

Los criterios están en la spec (requisito "Criterio de terminado"). Estos son los
comandos que los aplican:

```powershell
# alfa binario y número de colores
& $m asset.png -format "alfa-min=%[fx:minima.a] alfa-max=%[fx:maxima.a] colores=%k`n" info:

# píxeles sueltos / piezas despegadas (MCP de Aseprite)
tools.aseprite.lint_sprite({ filename })
tools.aseprite.get_color_stats({ filename })
```

`lint_sprite` debe devolver **una sola pieza** (`pieces: 1`), `detached_count: 0`
y `lone_pixel_count: 0`. Los `orphan_pixels` pueden ser legítimos (un remache a
propósito): revísalos, no los borres en masa.

---

## 7. Errores frecuentes y su arreglo

| Síntoma | Causa | Arreglo |
| --- | --- | --- |
| El sprite se ve sucio y sin contorno | Se redujo desde un tamaño mayor | Redibujar a la rejilla final |
| Halo claro alrededor de la silueta | Alfa parcial en los bordes | Forzar alfa binario |
| "Parece un dibujo pixelado, no retro" | Degradados suaves o demasiados colores | Bandas planas + cuantizar paleta |
| El sprite desaparece sobre el fondo | Tono demasiado cercano al fondo | Separar por luminosidad, no por tono |
| Las dos vistas del mismo objeto no parecen el mismo objeto | No se fijó el diseño antes | Fijar piezas y colores compartidos |
| El texto sale con píxeles irregulares | Tamaño de fuente no múltiplo de 8 | Usar 8/16/24/32/40/48 con Silkscreen |
| Manchas de color dentro de una zona plana | Ruido heredado de la imagen generada | Remapear paleta o repintar la zona |
| Un trozo del fondo asoma entre dos controles | El bloque de UI no dejó hueco | Recolocar el bloque antes de tocar el arte |

---

## 8. Dónde vive el arte

| Tipo | Ruta |
| --- | --- |
| Maestros editables y generadores | `art/` (fuera del proyecto Godot) |
| Fondo del menú | `game/scenes/welcome/` (solo lo usa esa escena) |
| Fuente | `game/assets/fonts/silkscreen/` |
| Texturas de UI compartidas | `game/assets/images/ui/` |
| Sprites de una entidad | `game/content/<tipo>/<nombre>/` |
| Tilesets | `game/content/map/` |

`AGENTS.md` manda sobre las carpetas; esta tabla solo concreta el caso del arte.

---

## 9. Referencias

- `openspec/specs/art-style/spec.md` — las reglas (fuente de verdad).
- `art/menu/` — fondos del menú; el elegido es `alt-C-sin-oscurecer.png`.
- `art/sprites/ase/` — maestros y generadores Lua de los dos cohetes.
- `art/ui/build-buttons.lua` — generador de los paneles de botón.
- `art/sprites/rockets-antes-despues.png` — ejemplo real de limpieza de paleta.
- `art/pixelize.ps1` — conversión a rejilla con píxel gordo.
- `docs/designs/junior-astronauta-outpost-lunar.md` — diseño formal del juego.
