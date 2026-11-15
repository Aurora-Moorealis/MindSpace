# Design

## Una sola fuente de verdad para la visibilidad

Antes `hud.gd` decidía su visibilidad solo con `game_over` y `game_reset`. Con una
segunda interfaz modal (el panel de máquina) hacía falta que dos condiciones no se
pisaran: cerrar el panel después de terminar la partida no debe resucitar el HUD.

La capa guarda dos banderas, `_run_over` y `_overlay_open`, y una sola función
`_update_visibility()` calcula `visible = not _run_over and not _overlay_open`. Los
manejadores solo cambian su bandera y llaman a esa función, así que el orden de los
eventos da igual.

`run_ui` observa `visibility_changed` del panel: no hay señal de «abierto» aparte,
y el panel ya alterna `visible` al abrir y cerrar. En el mismo manejador oculta el
botón de depuración de fin de misión, que si no se cuela sobre la esquina del
panel en compilaciones de debug.

## Arte del HUD al 1x

La barra de vida (328x48) y la hotbar (288x80) se dibujan a la mitad, que es
exactamente su arte de 1x, de modo que no hay remuestreo: 164x24 con relleno de
120x10, y 144x40 con espacios de 24 px, paso 26 y selección de 24. Los iconos de
objeto (32x32) se muestran a 16 px dentro del espacio, con 4 px de margen.

Es la única forma de reducir estos dos elementos sin romper la rejilla de píxeles:
cualquier escala intermedia deja líneas de 1 px con anchos desiguales.
