# Design

## Por qué `keycode` y no `physical_keycode`

El resto de acciones del proyecto usan `physical_keycode` porque son teclas de
posición (WASD, flechas, espacio). La `;` no es una posición estable: en las
distribuciones española y latinoamericana se escribe con `Shift` + la tecla de la
coma, mientras que en la US es una tecla propia. Atarla por posición obligaría a
pulsar la tecla física que en US corresponde a `;`, que en español es la `ñ`.

Por eso el evento se declara con `keycode = 59` (`KEY_SEMICOLON`) y
`physical_keycode = 0`. Así coincide con el símbolo que produce la pulsación en
cualquier distribución, con o sin `Shift`, sin depender de la posición.

## Sin conflicto con otros controles

Se comprobó que ningún otro evento del input map usa `;`: las acciones de juego
son WASD, flechas, `E`, `=`, `-` y `Space`. La nueva tecla solo afecta a
`debug_end_run`, que además sigue oculta fuera de builds de depuración.

## Por qué no se toca el código

`run_ui.gd` consulta la acción por nombre (`is_action_pressed(&"debug_end_run")`)
y el botón llama a `GameSim.force_end_run()` directamente. Cambiar el evento del
input map basta; no hace falta tocar scripts, escenas ni la lógica de fin de
partida.
