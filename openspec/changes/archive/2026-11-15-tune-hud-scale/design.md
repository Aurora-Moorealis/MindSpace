# Design

## Por qué 1,5x y no 1x

El arte del HUD está exportado a 2x sobre el lienzo de 850x480. Bajarlo a 1x dejaba
la barra de vida (164x24) y la hotbar (144x40) a la mitad que la tira de recursos
(176x72), y las etiquetas de porcentaje tenían que bajar a 6 px, ilegibles.

1,5x deja las tres piezas en la misma proporción y permite mantener las etiquetas
y el reloj a 8 px. El arte se remuestrea a 0,75; en líneas de 1 px eso deja algún
grosor desigual, pero a 850x480 se nota menos que el desequilibrio de escalas.

## Los rellenos no aceptan `size`

`TextureProgressBar` dibuja su textura a tamaño de textura: reducir el control no
reduce el relleno, y el de la vida (240x20) se salía 60 px del marco. La solución
es dejar el control con el tamaño nativo de la textura y aplicarle
`scale = (0.75, 0.75)`: el relleno se dibuja a 180x15 y 87x6, exactamente el hueco
del marco escalado. Se probó primero bajando solo los `offset` y el relleno se
salía del marco en las capturas.

## Texto

Las etiquetas se quedan a `font_size = 8` y ganan ancho (24 → 34 px) para que el
símbolo `%` no se recorte; el reloj también a 8 px con la caja más alta. A 6 px el
texto se veía borroso e incompleto en la captura ampliada.
