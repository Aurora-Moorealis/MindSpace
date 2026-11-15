# Spec Delta

## Purpose

Define el pack de sprites estáticos que da identidad visual a la sala del
invernadero del outpost lunar y a su máquina hidropónica, con su paleta de
verdes, rejilla de 32 px, formato de entrega y criterios de QA.

## ADDED Requirements

### Requirement: Catálogo de sprites del invernadero

El pack SHALL incluir, como mínimo, los sprites estáticos de las cuatro
categorías elegidas: props grandes de sala, plantas y cultivos, equipo y luces,
y decoración pequeña. El arte propio de la máquina hidropónica SHALL vivir en la
carpeta de esa máquina.

#### Scenario: Las cuatro categorías están presentes

- **WHEN** se revisa el pack entregado
- **THEN** existen sprites de props grandes (bancal, tanque de agua, tubería,
  caja de semillas), de al menos cuatro cultivos distintos, de equipo y luces
  (lámpara de crecimiento, ventilador, aspersor, panel de medidores) y de al
  menos cuatro piezas de decoración pequeña

#### Scenario: Separación entre sala y máquina

- **WHEN** se localiza el arte de la consola y del rack hidropónico
- **THEN** está en `game/content/machines/hydroponics/art/`, y el resto del pack
  en `game/content/map/greenhouse/art/`, sin duplicar ningún PNG entre ambas
  carpetas

### Requirement: Rejilla, tamaños y anclas

Cada sprite SHALL ajustarse a la rejilla de 32 px de `docs/art-direction.md`:
1×1 para cultivos, equipo y props pequeños; 2×1 para bancales, lámparas y
consolas; el rack hidropónico podrá ocupar hasta 3×2. La decoración pequeña
podrá usar la sub-rejilla de 16 px.

#### Scenario: Tamaños declarados y respetados

- **WHEN** se compara el tamaño real de cada PNG con el manifiesto JSON
- **THEN** coinciden exactamente y cada dimensión es múltiplo de 16 px

#### Scenario: Ancla de colocación

- **WHEN** se coloca un prop sobre el suelo en Godot
- **THEN** su punto de apoyo coincide con el ancla declarada en el manifiesto
  (centro-abajo para props de suelo, centro-arriba para lámparas de techo)

### Requirement: Paleta de verdes del invernadero

El pack SHALL usar una rampa de cinco verdes desaturados para cultivos, musgo y
brotes, añadida como paleta local del invernadero. La paleta base de 17 colores
del astronauta y del toolkit SHALL permanecer sin cambios.

#### Scenario: Rampa verde completa

- **WHEN** se inspecciona `greenhouse_palette.gpl`
- **THEN** contiene los 17 colores base más cinco verdes con luminosidad
  creciente y ninguna saturación primaria

#### Scenario: Límite de valores por material

- **WHEN** se cuenta el número de valores usados en una planta
- **THEN** no supera cuatro pasos (sombra, base, luz y brillo) y ningún sprite
  introduce colores fuera de la paleta

### Requirement: Silueta y legibilidad a 1×

Cada sprite SHALL tener contorno cerrado de 1 px en `#111827`, formas legibles a
1× sobre el canvas de 850×480 y una separación de valor suficiente respecto al
suelo del invernadero.

#### Scenario: Lectura a tamaño real

- **WHEN** se revisa la captura de integración a 850×480
- **THEN** cada prop se distingue del suelo y del resto de props sin necesidad de
  ampliar la imagen

#### Scenario: Limpieza de píxeles

- **WHEN** se ejecuta la revisión de Aseprite sobre cada sprite
- **THEN** no hay píxeles sueltos, contornos abiertos, escalones dobles en líneas
  de 1 px ni colores ajenos a la paleta

### Requirement: Formato de entrega

Cada sprite SHALL entregarse como fuente `.aseprite` y PNG RGBA a 1× con alpha
real, acompañado de un manifiesto JSON con nombre, tamaño y ancla, un `README.md`
con las instrucciones de importación en Godot y una captura de revisión a
850×480.

#### Scenario: Artefactos por sprite

- **WHEN** se busca un sprite concreto por su nombre en el manifiesto
- **THEN** existen su `.aseprite` editable y su PNG exportado, y el manifiesto
  declara tamaño y ancla

#### Scenario: Importación reproducible

- **WHEN** otra persona sigue el `README.md` en un proyecto Godot limpio
- **THEN** obtiene filtrado nearest, sin mipmaps, y los sprites se ven a 1× sin
  interpolación

### Requirement: Pack solo de arte

El pack SHALL contener únicamente arte y metadatos. No SHALL añadir escenas,
scripts, colisiones, `.tres` ni lógica de crecimiento, cosecha o simulación, y no
SHALL modificar `project.godot` ni escenas compartidas.

#### Scenario: Sin código ni gameplay

- **WHEN** se revisa el diff del cambio
- **THEN** solo aparecen imágenes, paletas, JSON, README y `.import`, sin `.gd`,
  `.tscn`, `.tres` ni cambios en `project.godot`

#### Scenario: Estaticidad

- **WHEN** se inspeccionan los `.aseprite` entregados
- **THEN** cada sprite tiene un único frame y no contiene tags de animación

### Requirement: Fuera de alcance declarado

El pack SHALL NOT incluir el tileset de la sala (suelo, paredes, ventanal,
esclusa), animaciones ni cultivos con paleta propia. Su ausencia SHALL quedar
registrada para un cambio posterior.

#### Scenario: Huecos documentados

- **WHEN** se lee el `README.md` del pack
- **THEN** enumera explícitamente que el tileset, las animaciones y los cultivos
  alienígenas quedan pendientes y no forman parte de esta entrega
