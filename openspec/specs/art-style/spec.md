# art-style Specification

## Purpose
Reglas de producción del arte de MindSpace. Definen cómo debe ser cualquier
asset para encajar en el estilo y para poder auditarse sin depender del criterio
de quien lo dibujó.

## Requirements

### Requirement: Rejilla de dibujo

Todo asset gráfico SHALL dibujarse sobre una rejilla de 425×240 y mostrarse al
doble en un lienzo de 850×480, de modo que cada píxel artístico ocupe un bloque
de 2×2 píxeles de pantalla.

#### Scenario: Dimensiones de un asset nuevo

- **WHEN** se crea o exporta un asset
- **THEN** sus dimensiones respetan la rejilla de 425×240 y su escala de presentación es un múltiplo entero

#### Scenario: Ventana redimensionada

- **WHEN** la ventana cambia de tamaño
- **THEN** el arte se escala solo en enteros, sin interpolar

### Requirement: Paleta cerrada

Todo asset SHALL usar solo la paleta del juego: la paleta de identidad más la de
terreno. Identidad: cielo `#081542` `#0D1635` `#1F3152` `#14192B`; casco
`#DFE8F0` `#BCC9D6` `#92A1B2` `#7B8794` `#64707E` `#5F6B78`; metal `#A9B6C4`
`#6A7684`; teal `#57C8CC` `#4AA8B4` `#2F9FA6` `#2A7F8B` `#186269`; ámbar
`#FFE27A` `#F0A72A` `#9C5F0C`; navy `#3D5175` `#26334F` `#1B2540`; fuego
`#FFC93C` `#E2551B`; contorno `#0F171F`.

#### Scenario: Auditoría de colores

- **WHEN** se revisan los colores de un asset
- **THEN** todos pertenecen a la paleta y no hay tonos fuera de ella

#### Scenario: Hace falta un color nuevo

- **WHEN** un asset necesita un color que no está en la paleta
- **THEN** el color se añade a esta spec antes de usarse en cualquier asset

### Requirement: Contorno

Cada sprite SHALL tener un contorno continuo de 1 píxel en `#0F171F` que rodee
toda la silueta, sin tramos abiertos.

#### Scenario: Recorrido de la silueta

- **WHEN** se recorre el borde de un sprite
- **THEN** el contorno es continuo y mide un píxel en todo el recorrido

### Requirement: Luz y sombreado

El sombreado SHALL asumir una única fuente de luz desde arriba-izquierda, con
cuatro tonos como máximo por material y transiciones de un píxel.

#### Scenario: Volumen sombreado

- **WHEN** se sombrea un volumen
- **THEN** la cara iluminada está arriba-izquierda y la sombra abajo-derecha

#### Scenario: Cambio de tono en superficie amplia

- **WHEN** una superficie grande cambia de tono
- **THEN** el paso es una banda o un tramado ordenado, nunca un degradado suave

### Requirement: Alfa binario

Los PNG SHALL tener alfa binario: cada píxel es completamente opaco o
completamente transparente, sin valores intermedios.

#### Scenario: Medición del alfa

- **WHEN** se mide el canal alfa de un PNG exportado
- **THEN** solo aparecen los valores mínimo y máximo, sin píxeles semitransparentes

### Requirement: Sin antialias

Ningún asset SHALL contener antialias, píxeles de transición ni degradados
suaves; las diagonales SHALL avanzar en escalones regulares.

#### Scenario: Borde diagonal

- **WHEN** se revisa un borde diagonal
- **THEN** avanza en escalones regulares y no hay píxeles de transición entre el relleno y el contorno

### Requirement: Pieza única

Cada sprite SHALL ser una sola pieza conectada, sin píxeles aislados ni
fragmentos despegados de la silueta.

#### Scenario: Revisión de piezas

- **WHEN** se revisa un sprite
- **THEN** forma una sola pieza conectada, con cero píxeles aislados y cero fragmentos separados

### Requirement: Espaciado de interfaz

Los elementos de interfaz SHALL dimensionarse y separarse en múltiplos de 2
píxeles del lienzo de 850×480, para no romper la rejilla del arte.

#### Scenario: Revisión de un layout

- **WHEN** se revisa la disposición de una pantalla
- **THEN** márgenes, separaciones y tamaños son múltiplos de 2

### Requirement: Tipografía

El texto de interfaz SHALL usar la fuente Silkscreen en tamaños múltiplo de 8.
No se permite negrita ni cursiva sintética.

#### Scenario: Texto nuevo

- **WHEN** se añade un texto a la interfaz
- **THEN** usa Silkscreen con un tamaño múltiplo de 8 y el énfasis se resuelve con color o tamaño

### Requirement: Paneles de interfaz

Los paneles y botones SHALL usar la rampa de grises del casco con bisel de dos
tonos y tornillos en las esquinas, montados como nine-patch.

#### Scenario: Botón nuevo

- **WHEN** se añade un botón o un panel
- **THEN** reutiliza los estilos del tema compartido en lugar de definir un estilo propio

### Requirement: Criterio de terminado

Un asset SHALL darse por terminado solo después de pasar las comprobaciones de
paleta, alfa, contorno y píxeles sueltos, y de revisarse a ×4–×8 y a tamaño de
juego.

#### Scenario: Entrega de un asset

- **WHEN** se da por terminado un asset
- **THEN** las comprobaciones de paleta, alfa, contorno y píxeles sueltos pasan y se ha revisado a ×4–×8 y a tamaño de juego

### Requirement: Paleta de terreno

Los assets de terreno SHALL usar, además de la rampa de casco, estas rampas:
regolito `#8B8884` `#726F6B` `#585551` `#403E3B`; basalto `#44444E` `#2E2E36`
`#1E1E25`; ilmenita `#55607A` `#343A4C` `#1F2331`; silíceo `#DDD5BE` `#B8AE92`
`#8C846C`; hielo `#C4D8DF` `#8FAAB4` `#5C7680`.

#### Scenario: Auditoría de un tile de terreno

- **WHEN** se audita una loseta de terreno
- **THEN** sus colores pertenecen a la rampa del material que representa

### Requirement: Rejilla de mundo

El mundo SHALL construirse con losetas de 32×32 píxeles de pantalla, dibujadas a
16×16 píxeles de arte y exportadas al doble.

#### Scenario: Colocación de losetas

- **WHEN** se colocan dos losetas de suelo iguales en celdas contiguas
- **THEN** no aparece costura visible entre ellas

#### Scenario: Tileset nuevo

- **WHEN** se añade un tileset al mundo
- **THEN** su rejilla es de 16 px de arte y su exportación es múltiplo entero de esa rejilla

### Requirement: Materiales del terreno

El terreno SHALL ser un único suelo de regolito basáltico. Los otros tres
materiales lunares —hielo de agua (H₂O), ilmenita (FeTiO₃) y material silícico
(SiO₂)— SHALL aparecer como depósitos sueltos sobre ese suelo, nunca como
losetas de terreno.

#### Scenario: Lectura del suelo

- **WHEN** se recorre una zona de exterior
- **THEN** el suelo es siempre el mismo regolito, sin bloques de otro color

#### Scenario: Lectura de un depósito

- **WHEN** se coloca un depósito de mineral sobre el regolito
- **THEN** se distingue del suelo por color y textura, y su borde se funde sin formar un cuadrado

#### Scenario: Lectura a tamaño de juego

- **WHEN** se mira el terreno a tamaño de juego
- **THEN** cada depósito se distingue del regolito y de los demás sin ayuda de etiquetas

#### Scenario: Material nuevo

- **WHEN** se quiere añadir un material al terreno
- **THEN** se justifica que existe en la Luna y se documenta en este requisito antes de dibujarlo
