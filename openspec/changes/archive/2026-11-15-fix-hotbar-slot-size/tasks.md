# Design

El tamaño de un espacio lo decidía el `.tscn` del propio espacio
(`custom_minimum_size = 48`), no la escena que lo instancia: los `offset` de
`hud.tscn` quedaban recortados al mínimo y cada espacio medía 48 px con un paso de
39, de ahí el solape.

Se baja el mínimo a 36 y se escalan por la misma proporción las dos piezas que
viven dentro del espacio: el marco de selección (48 → 36) y el icono (32 → 24, con
6 px de margen en vez de 8). El icono del objeto en la mano y la vista previa de
arrastre usan 24 px para mantener la proporción.

La geometría del marco (216x60) y el paso de los espacios (39 px) no cambian: solo
se corrige el tamaño efectivo de cada espacio.

# Tasks

## 1. Espacio de inventario

- [x] 1.1 Bajar el mínimo del espacio a 36x36 y ajustar marco de selección e icono
- [x] 1.2 Bajar la vista previa de arrastre a 24 px

## 2. Icono en la mano

- [x] 2.1 Ajustar el icono del objeto en la mano a 24 px en `hud.gd` y `hud.tscn`

## 3. Verificación

- [x] 3.1 Checker estricto sin errores
- [x] 3.2 Escena de prueba del HUD sin fallos y captura con tres objetos
- [x] 3.3 Captura de la partida con los cinco espacios alineados al marco
