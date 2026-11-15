# Design

## Ocultar el HUD en vez de reordenar capas

El HUD vive en su propio `CanvasLayer` con `layer = 10`, por encima de la capa de
`run_ui` donde está la evaluación. Subir la evaluación a una capa mayor resolvería
el solape, pero dejaría el HUD visible y desactualizado detrás del resumen, y sus
atajos seguirían respondiendo.

Se oculta la propia capa del HUD al recibir `GameSim.game_over` y se vuelve a
mostrar con `GameSim.game_reset`. `hud.gd` ya escuchaba `game_reset` para vaciar el
inventario, así que solo hay que alternar `visible` en los dos manejadores que ya
existen. `_input` ya ignora los eventos cuando la capa no es visible, de modo que
los atajos de la hotbar dejan de responder sin código extra.

## Hotbar al 75 %

El marco y los espacios se reescalan en el `.tscn` manteniendo la proporción
(marco 216x60, espacios 36x36, paso 39 px) y la hotbar sigue centrada con 28 px de
margen inferior. No se genera arte nuevo ni se añade un nodo de escala: el
`TextureRect` ya usa `stretch`, y así el escenario de prueba y la partida comparten
la misma geometría.

La escala de la ventana es entera (`scale_mode="integer"`), así que a x2 el HUD
sigue viéndose nítido; el 75 % se aplica sobre el lienzo de 850x480, no sobre la
ventana.
