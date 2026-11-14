# Sombra en el suelo de los cohetes

- **Estado:** pendiente
- **Prioridad:** baja
- **Depende de:** —

## Objetivo

El cohete de aterrizaje se ve flotando porque no proyecta nada. Una sombra
elíptica bajo las patas lo ancla al suelo.

## Alcance

- Elipse de ~64×12 px bajo las tres patas, alineada con la línea de apoyo
  (`y = 120` en el maestro).
- Dos tonos: un núcleo más oscuro y un borde difuminado **con dithering
  ordenado**, nunca con degradado suave.
- Color: multiplicar el gris del suelo por ~0,55 (no negro puro).
- Va en su propio sprite (`shadow.png`), no dentro del cohete, para poder
  escalarla o desvanecerla al aterrizar.

## Criterios de aceptación

- Se puede dibujar el cohete sin sombra (para la pantalla donde va solo, sobre
  cielo) y con sombra (cuando esté sobre la superficie lunar).
- No usa transparencia parcial: alfa 0 o 255.

## Notas

Si en algún momento el cohete se ve sobre el cielo estrellado, la sombra sobra.
Conviene decidir por escena, no por sprite.
