# Guía estética de MindSpace

Cómo se dibuja el arte de este juego. Está escrita para que **otro agente o
persona pueda producir un asset nuevo sin preguntar**, y para que no se mezclen
estilos.

Si algo de aquí choca con una petición directa del autor, manda el autor; pero
entonces hay que actualizar esta guía.

---

## 1. Principio rector

**Pixel art de 1993, no un dibujo pixelado.**

La diferencia es la que decide todo lo demás:

| Un dibujo pixelado | Pixel art |
| --- | --- |
| Se hace grande y se reduce | Se dibuja a la rejilla final |
| Degradados suaves | Bandas de color planas |
| Antialias en los bordes | Contorno duro de 1 px |
| Cientos de colores | 12–20 colores con intención |
| Detalle fino y ruido | Formas grandes y legibles |

Cuando un asset "no se ve retro", casi siempre es porque tiene degradados,
bordes suaves o demasiados colores. **No es por el tamaño.**

---

## 2. Resolución y rejilla

| Cosa | Valor |
| --- | --- |
| Canvas del juego | **850 × 480** (`project.godot`) |
| Rejilla real del arte | **425 × 240** |
| Escala | **×2** (cada píxel artístico ocupa un bloque de 2×2 en pantalla) |

**Todo el arte se dibuja a 425×240 y se exporta a 850×480.** Un píxel de arte =
4 píxeles de pantalla. Ese "píxel gordo" es la señal visual más fuerte del
estilo: no lo rompas escalando a ×1,5 ni metiendo imágenes de otra resolución.

### Reglas derivadas

- Los desplazamientos, tamaños y espaciados de la UI van en **múltiplos de 2 px**
  (en el espacio de 850×480) para no romper la rejilla.
- Un borde "de 1 píxel" en el arte son **2 px** en pantalla. Si dibujas un borde
  de 1 px sobre el canvas de 850, parecerá medio píxel.
- En Godot el filtro de textura debe ser **Nearest** (ya está en `project.godot`).
  Con filtro lineal, todo el estilo se convierte en papilla.
- La ventana debe escalar en **enteros**. En 1920×1080 el múltiplo limpio es ×2
  (1700×960).

---

## 3. Paleta

Paleta cerrada. **No inventes colores nuevos**: si falta uno, se añade aquí
primero y se justifica.

### Cielo y fondos

| Uso | Hex |
| --- | --- |
| Cielo profundo (noche lunar) | `#081542` |
| Cielo medio | `#0D1635` |
| Cielo con luz de Tierra | `#1F3152` |
| Sombra de fondo | `#14192B` |

### Casco / metal (rampa de 6)

| Paso | Hex |
| --- | --- |
| Brillo | `#DFE8F0` |
| Claro | `#BCC9D6` |
| Medio | `#92A1B2` |
| Medio oscuro | `#7B8794` |
| Oscuro | `#64707E` |
| Muy oscuro | `#5F6B78` |

Metal secundario (patas, tuberías): `#A9B6C4` y `#6A7684`.

### Teal (identidad de la cúpula y la energía)

| Paso | Hex |
| --- | --- |
| Brillo | `#57C8CC` |
| Claro | `#4AA8B4` |
| Base | `#2F9FA6` |
| Oscuro | `#2A7F8B` |
| Muy oscuro | `#186269` |

### Ámbar (luces, ventanas, avisos)

| Paso | Hex |
| --- | --- |
| Brillo | `#FFE27A` |
| Base | `#F0A72A` |
| Sombra | `#9C5F0C` |

### Azul marino (aletas, ventana, estructura)

| Paso | Hex |
| --- | --- |
| Claro | `#3D5175` |
| Base | `#26334F` |
| Muy oscuro | `#1B2540` |

### Fuego

| Uso | Hex |
| --- | --- |
| Núcleo | `#FFC93C` |
| Borde | `#E2551B` |

### Contorno

| Uso | Hex |
| --- | --- |
| Contorno y texto | `#0F171F` |

### Reglas de paleta

- **Rampas de 3 a 6 pasos**, nunca un degradado continuo. Cada material tiene su
  propia rampa.
- Materiales vecinos se separan **por luminosidad**, no solo por tono: si dos
  colores tienen el mismo brillo, el ojo no distingue el borde.
- **Nada de alfa parcial.** Los píxeles son opacos o transparentes. Un PNG con
  alfa 96 o 177 produce halos sucios al escalar.

---

## 4. Las siete reglas de dibujo

1. **Contorno de 1 px** en `#0F171F` alrededor de toda la silueta. Continuo, sin
   huecos. Dentro del sprite, el contorno solo separa piezas que se tocan.
2. **Luz desde arriba-izquierda**, siempre, en todos los assets. La cara
   iluminada va arriba-izquierda; la sombra, abajo-derecha.
3. **Bandas duras, no degradados.** Tres o cuatro tonos por material, con
   transiciones de 1 px. Para pasar de un tono a otro en una superficie grande,
   usa **dithering ordenado**, nunca un degradado suave.
4. **Sin antialias.** Ningún píxel de transición. Los bordes diagonales van en
   escalones regulares (1-1-1 o 2-2-2), no en 1-3-1.
5. **Sin píxeles sueltos.** Nada de motas aisladas: o forman parte de una forma o
   no existen.
6. **La silueta manda.** Si a tamaño de juego no se reconoce qué es, el problema
   es la forma, no el detalle. Simplifica antes de añadir.
7. **Los objetos tocan su superficie.** Un cohete apoya sus tres patas en la
   misma línea; una tubería llega hasta la máquina. Nada flota.

---

## 5. Proceso: crear un fondo (850×480)

Así se hizo el fondo del menú y así se hacen los *stills* de intro.

1. **Concepto de imagen** con el generador de imágenes, pidiendo explícitamente:
   pixel art retro, paleta de ~16 colores, contorno negro de 1 px, formas
   planas, dithering, **sin** degradados, sin textura fotográfica, sin antialias.
2. **Conversión a la rejilla real** con `art/pixelize.ps1`:

   ```powershell
   pwsh -File pixelize.ps1 -In raw.png -Out fondo.png -Width 425 -Height 240 -Colors 24 -Scale 2
   ```

   Genera 850×480 con píxel de 2×2 mediante vecino más cercano.
3. **Revisión a ojo** del resultado a ×3. Los fallos típicos del generador son
   ruido, colores embarrados y bordes suaves.
4. **Limpieza de paleta**: cuantizar a un número cerrado de colores
   (`-colors 24` a `-colors 96`) sin dither de Floyd-Steinberg, que ensucia.
5. **Zona de UI despejada**: deja un tercio de la imagen con poco detalle donde
   irán título y botones. En el menú es la mitad izquierda del cielo.

> El detalle que arruina un fondo es el **degradado suave**. Si el cielo tiene
> bandas y el suelo tiene tramado, el resto perdona mucho.

---

## 6. Proceso: crear un sprite

Los cohetes se hicieron así y es el método a repetir.

1. **Fijar el diseño antes de dibujar**: qué piezas tiene, de qué color cada una
   y qué comparten las distintas vistas (mismo cuerpo, misma franja, misma
   ventana). Sin esto, dos vistas del mismo objeto parecen dos objetos.
2. **Dibujar a la rejilla final.** Si el sprite va a medir 64 px de alto, se
   dibuja a 64. Reducir un sprite grande "destruye el contorno": es el error más
   caro y el más frecuente.
3. **Silueta primero**: una sola forma plana, y compruébala a tamaño de juego.
4. **Planos de color** por material, con la rampa asignada.
5. **Sombra con intención**: un solo lado oscuro, sombra bajo los voladizos.
6. **Detalle**: remaches, costuras de panel, rejillas. Poco y con ritmo regular.
7. **Contorno** al final, 1 px, continuo.
8. **QA** (ver sección 8) y revisión a ×4–×8.

### Receta de limpieza de un sprite ya existente

Cuando el asset viene de una imagen generada (con ruido y colores sucios), **no
lo redibujes: remapea la paleta y conserva el dibujo**.

1. Convertir la imagen a modo RGB en Aseprite.
2. Clasificar cada píxel por su índice de color original y asignarle el color
   limpio equivalente de esta paleta.
3. Forzar alfa binario (≥128 → opaco, resto transparente).
4. Recalcular el contorno continuo.
5. Arreglar solo los defectos estructurales (piezas desalineadas, patas
   desiguales, elementos que flotan).

Rehacer el dibujo desde cero suele salir **peor**: se pierde el detalle que le
daba carácter. Remapear conserva el diseño y limpia la ejecución.

---

## 7. Herramientas

### Aseprite por MCP

Todo el trabajo de píxel se hace con el servidor `aseprite` (123 herramientas).
Lo esencial:

| Necesidad | Herramienta |
| --- | --- |
| Ver el sprite dentro del chat | `view_sprite` (`region` para zoom, `scale` 4–12) |
| Dibujar formas | `draw_ellipse_at`, `draw_polygon`, `fill_area_at`, `draw_rows` |
| Contorno de 1 px | `outline_cel` |
| Contar colores / detectar suciedad | `get_color_stats` |
| Detectar píxeles sueltos y piezas despegadas | `lint_sprite` |
| Exportar para revisar | `export_frame` con `scale: 8` |
| Lote grande de operaciones | `run_lua_script` |

**Guarda los generadores como `.lua`** y ejecútalos con
`run_lua_script({ script: 'dofile("<ruta>.lua")' })`. Así se iteran con un editor
de texto en vez de reenviar el script entero cada vez. Ver
`art/sprites/ase/README.md` como ejemplo real.

### ImageMagick

Para conversión de rejilla, escalado por vecino más cercano y montajes de
comparación:

```powershell
$m = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
& $m sprite.png -filter point -resize 200% sprite@2x.png
& $m a.png b.png +append comparacion.png
```

`-filter point` es obligatorio al escalar: cualquier otro filtro interpola.

---

## 8. Control de calidad antes de dar un asset por bueno

### Checklist

- [ ] Resolución exacta (425×240 el arte, 850×480 el fondo, sprite a su tamaño final).
- [ ] Alfa **binario**: 0 o 255. Cero píxeles semitransparentes.
- [ ] Contorno `#0F171F` de 1 px, continuo, sin huecos.
- [ ] Todos los colores están en la paleta de la sección 3.
- [ ] Ningún píxel suelto ni pieza flotando.
- [ ] Luz coherente arriba-izquierda.
- [ ] Revisado a ×4–×8 **y** a tamaño de juego.

### Comandos

```powershell
# alfa binario y número de colores
& $m asset.png -format "alfa-min=%[fx:minima.a] alfa-max=%[fx:maxima.a] colores=%k`n" info:

# píxeles sueltos / piezas despegadas (MCP de Aseprite)
tools.aseprite.lint_sprite({ filename })
tools.aseprite.get_color_stats({ filename })
```

`lint_sprite` debe devolver **una sola pieza** (`pieces: 1`), `detached_count: 0`
y `lone_pixel_count: 0`. Los `orphan_pixels` pueden ser legítimos (un remache a
propósito); revísalos, no los borres en masa.

---

## 9. Interfaz y Godot

### Fuente

**Silkscreen** (`assets/fonts/silkscreen/`), licencia OFL.

- Es una fuente de píxel diseñada a 8 px: **usa solo múltiplos de 8**
  (8, 16, 24, 32, 48). A otro tamaño los trazos salen irregulares.
- Título: 48. Subtítulo y texto de botón: 16. Texto pequeño: 8.

### Paneles y botones

- Placa metálica con la rampa de grises del casco: cuerpo `#BCC9D6`, bisel
  superior `#DFE8F0`, bisel inferior `#64707E`, contorno `#0F171F` de 2 px
  (1 px de arte).
- **Tornillos** en las cuatro esquinas, 8×8 px, con un punto de brillo.
- Hover: el contorno y el bisel pasan a teal (`#4AA8B4`).
- Pulsado: el cuerpo baja un paso (`#92A1B2`) y el bisel se invierte.
- Los paneles se hacen como **nine-patch** (bordes fijos, centro estirable) para
  que un mismo PNG sirva de 120 px de ancho o de 320.

### En Godot

- Filtro de textura **Nearest** global (ya configurado en `project.godot`).
- Nada de escalar *sprites* con `scale` arbitrario en el inspector: si un sprite
  necesita otro tamaño, se dibuja a ese tamaño.
- Los `TextureRect` de fondo van anclados a pantalla completa con
  `stretch_mode = keep` y la textura exacta de 850×480.

---

## 10. Errores frecuentes y su arreglo

| Síntoma | Causa | Arreglo |
| --- | --- | --- |
| El sprite se ve sucio y sin contorno | Se redujo desde un tamaño mayor | Redibujar a la rejilla final |
| Halo claro alrededor de la silueta | Alfa parcial en los bordes | Forzar alfa binario |
| "Parece un dibujo pixelado, no retro" | Degradados suaves o demasiados colores | Bandas planas + cuantizar paleta |
| El sprite desaparece sobre el fondo | Tono demasiado cercano al fondo | Separar por luminosidad, no por tono |
| Las dos vistas del mismo objeto no parecen el mismo objeto | No se fijó el diseño antes | Fijar piezas y colores compartidos |
| El texto sale con píxeles irregulares | Tamaño de fuente no múltiplo de 8 | Usar 8/16/24/32/48 con Silkscreen |
| Manchas de color dentro de una zona plana | Ruido heredado de la imagen generada | Remapear paleta o repintar la zona |

---

## 11. Dónde vive el arte

| Tipo | Ruta |
| --- | --- |
| Maestros editables y generadores | `art/` (fuera del proyecto Godot) |
| Fondo del menú | `game/scenes/welcome/` (solo lo usa esa escena) |
| Fuente | `game/assets/fonts/silkscreen/` |
| Texturas de UI compartidas (botones, paneles) | `game/assets/images/ui/` |
| Sprites de una entidad | `game/content/<tipo>/<nombre>/` |
| Tilesets | `game/content/map/` |

Ver `AGENTS.md` para las reglas de carpetas; esta tabla solo aclara dónde cae el
arte.

---

## 12. Referencias en el repositorio

- `art/menu/` — fondos del menú (el elegido es `alt-C-sin-oscurecer.png`).
- `art/sprites/ase/` — maestros y generadores Lua de los dos cohetes.
- `art/sprites/rockets-antes-despues.png` — ejemplo real de limpieza de paleta.
- `art/pixelize.ps1` — conversión a rejilla con píxel gordo.
- `docs/designs/junior-astronauta-outpost-lunar.md` — diseño formal del juego.
