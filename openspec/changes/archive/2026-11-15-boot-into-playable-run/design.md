# Design

## Contexto

`game/project.godot` declara `run/main_scene="res://scenes/welcome/welcome.tscn"` y
la spec `menu` lo exige ("Arranque en el menú"). El bucle jugable vive en
`res://scenes/base/base.tscn` y se alcanza con menú → mundos → intro, un recorrido de
tres pantallas que no aporta nada cuando lo que se quiere es probar la partida.

## Decisión

Cambiar la escena principal a `res://scenes/base/base.tscn` y actualizar la spec
`menu` para que el arranque sea la partida.

Motivos:

- Es la escena que contiene el juego real (outpost, astronauta, HUD, simulación).
- Los menús siguen disponibles: la evaluación de la misión ofrece "Back to menu", y
  desde el menú se mantiene el flujo de mundos e intro.
- No hay estado global que dependa de haber pasado por el menú: `GameSim` arranca
  congelado y es `base.gd` quien llama a `start_run()`.

## Alternativas descartadas

- **Dejar el menú como escena principal y añadir un botón "jugar ya"**: mantiene la
  spec, pero sigue sin resolverse el problema de que Play no enseñe la partida.
- **Bandera de línea de comandos (`--play`)**: útil para desarrollo, pero no cambia
  lo que ve quien ejecuta el juego ni lo que dice la spec.
- **Duplicar `base.tscn` en una escena de arranque**: dos escenas con el mismo
  contenido y dos sitios donde tocar el outpost.

## Riesgos

- Quien espere el menú al abrir el juego verá directamente la partida; el menú queda
  a una acción de distancia (evaluación → "Back to menu").
- `welcome.tscn` sigue siendo el destino de "Back to menu", así que no queda código
  muerto ni una pantalla inalcanzable.
