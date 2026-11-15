# Tasks

## 1. Preparación del pack

- [x] 1.1 Crear `game/content/map/greenhouse/art/{sprites,palette,previews}` y `game/content/machines/hydroponics/art/{sprites,palette,previews}`; verificar que las seis carpetas existen y están vacías antes de dibujar.
- [x] 1.2 Crear `palette/greenhouse_palette.gpl` con los 17 colores base + los 5 verdes de D3 y su swatch PNG; verificar en Aseprite que `get_palette` devuelve 22 colores con los hex exactos.
- [x] 1.3 Escribir el `README.md` esqueleto de cada carpeta (inventario, tamaños, anclas, import nearest, pendientes); verificar que el inventario coincide con la tabla D6 del diseño.
- [x] 1.4 Crear `sprites.json` vacío en cada carpeta con el esquema de D5; verificar que ambos parsean como JSON válido.

## 2. Props grandes de sala

- [x] 2.1 Dibujar `grow_bed` (64×32): verificar con `view_sprite` que se lee como bancal a 1× y con `lint_sprite` que no hay píxeles sueltos.
- [x] 2.2 Dibujar `water_tank` (64×64): verificar silueta, contorno cerrado y exportar PNG de 64×64 exactos.
- [x] 2.3 Dibujar `pipe_elbow` (32×32): verificar que el codo conecta en los bordes de la rejilla de 32 px.
- [x] 2.4 Dibujar `seed_crate` (32×32): verificar que la caja se distingue del bancal y del tanque por forma, no solo por color.
- [x] 2.5 Revisar el bloque con `get_color_stats`: verificar que no hay colores fuera de la paleta y que cada sprite usa como máximo 4 valores del material principal.

## 3. Cultivos

- [x] 3.1 Dibujar `crop_seedling` (32×32): verificar que se lee como brote y que no se confunde con `pot_small`.
- [x] 3.2 Dibujar `crop_leafy` (32×32): verificar la masa de hojas con luz desde arriba-izquierda y sombra bajo las hojas.
- [x] 3.3 Dibujar `crop_root` (32×32): verificar que la raíz visible asoma del sustrato y se distingue de `crop_leafy` en silueta.
- [x] 3.4 Dibujar `crop_vine` (32×64): verificar que la planta trepadora se apoya en una estructura y no flota.
- [x] 3.5 Exportar los cuatro PNG y verificar tamaños exactos y `lint_sprite` limpio en cada uno.

## 4. Equipo y luces

- [x] 4.1 Dibujar `grow_lamp` (64×32) con ancla superior: verificar que la luz se lee como foco encendido sin usar cian fuera de un glint de 2–3 px.
- [x] 4.2 Dibujar `fan_unit` (32×32): verificar aspas legibles a 1× en un solo frame.
- [x] 4.3 Dibujar `sprinkler` (32×32): verificar que la boquilla apunta hacia abajo y el cuerpo se apoya en la rejilla.
- [x] 4.4 Dibujar `gauge_panel` (32×32): verificar que las agujas y la pantalla usan cian solo como acento y el amarillo de aviso en ≤2 px.
- [x] 4.5 Dibujar `vent_grille` (32×32) con ancla superior: verificar que la rejilla repite el módulo y no genera escalones dobles.
- [x] 4.6 Revisar el bloque completo con `view_sprite` sobre un fondo `#1d2536`: verificar que lámpara, ventilador y rejilla no se leen como pantallas.

## 5. Decoración pequeña

- [x] 5.1 Dibujar `pot_small` (16×16): verificar que cabe en la sub-rejilla de 16 px y tiene contorno cerrado.
- [x] 5.2 Dibujar `watering_can` (16×16): verificar que el asa está unida al cuerpo y se lee a 1×.
- [x] 5.3 Dibujar `tool_rack` (32×32): verificar que las herramientas cuelgan del soporte y no flotan.
- [x] 5.4 Dibujar `hose_coil` (32×32): verificar que la manguera se enrolla sin píxeles sueltos y se apoya en el suelo.
- [x] 5.5 Dibujar `floor_drain` (32×32): verificar que se lee como rejilla de desagüe y no como baldosa decorativa.
- [x] 5.6 Dibujar `warning_sign` (16×16): verificar que el símbolo cabe en 12×12 y usa amarillo de aviso en ≤4 px.
- [x] 5.7 Exportar las seis piezas y verificar tamaños (16 o 32 px) y `lint_sprite` limpio.

## 6. Máquina hidropónica

- [x] 6.1 Dibujar `hydroponics_rack` (96×64): verificar que se lee como rack de 3×2 tiles con bandejas y plantas, y que su ancla bottom-center cae en `[48, 64]`.
- [x] 6.2 Dibujar `hydroponics_console` (64×32): verificar que la pantalla y los mandos usan cian y amarillo solo como acentos y que se distingue de `gauge_panel`.
- [x] 6.3 Dibujar `nutrient_tank` (32×64): verificar que el líquido se lee con el cian reservado y el depósito se apoya en el suelo.
- [x] 6.4 Exportar los tres PNG y verificar tamaños exactos, anclas declaradas y `lint_sprite` limpio.

## 7. Manifiestos y documentación

- [x] 7.1 Poblar `map/greenhouse/art/sprites.json` con los 19 sprites de sala; verificar con un script que `size` coincide con el PNG y que cada `anchor_rule` respeta D5.
- [x] 7.2 Poblar `machines/hydroponics/art/sprites.json` con los 3 sprites de máquina; verificar el mismo chequeo de tamaño y ancla.
- [x] 7.3 Completar los `README.md` con nombres, categorías, anclas, importación nearest/sin mipmaps y la lista de pendientes (tileset, animaciones, cultivos alienígenas); verificar que los pasos escritos funcionan en un proyecto Godot limpio.

## 8. Integración y QA visual

- [x] 8.1 Componer `map/greenhouse/art/previews/integration_850x480.png` a 1× sobre suelo `#1d2536`/`#33405a`; verificar visualmente que cada prop se distingue del suelo y entre sí.
- [x] 8.2 Abrir/importar el proyecto en Godot y verificar que los `.import` generados usan nearest y no mipmaps.
- [x] 8.3 Auditar el diff: verificar con `git status` que solo hay imágenes, `.aseprite`, JSON, README y `.import`, sin `.gd`, `.tscn`, `.tres` ni cambios en `project.godot`.
- [x] 8.4 Revisar que el inventario del manifiesto no duplica PNG entre `map/` y `machines/`; verificar con una búsqueda de nombres repetidos.

## Workflow follow-up

- Revisar los artefactos y el pack con el equipo antes de archivar el cambio.
- Archivar el cambio cuando el pack esté aprobado y las specs pasen a `openspec/specs/greenhouse-art/spec.md`.
