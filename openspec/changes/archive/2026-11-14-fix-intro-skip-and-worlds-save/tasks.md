# Tasks

## 1. OpenSpec

- [x] 1.1 Crear el cambio `fix-intro-skip-and-worlds-save` con proposal, delta specs de `intro` y `worlds`, design y tasks.
- [x] 1.2 Ejecutar `openspec validate fix-intro-skip-and-worlds-save --strict` y dejarlo en verde.

## 2. Intro

- [x] 2.1 Guardar el tween activo en `_animation_tween` y matarlo al saltar; saltar una sola vez y mostrar la historia.
- [x] 2.2 Hacer que `_play_intro` salga sin volver a mostrar la historia cuando `_skipped` está activo, incluido el final de la travesía.
- [x] 2.3 Comprobar en headless que tras saltar, avanzar a la parte 3 y dejar terminar el tween, la historia sigue en la parte 3 y el fundido está a cero.

## 3. Persistencia de mundos

- [x] 3.1 Escribir `worlds.json.tmp`, cerrar y renombrar sobre `worlds.json`; si el rename falla, borrar el temporal y devolver `false` sin tocar el archivo anterior.
- [x] 3.2 Cuarentena del archivo dañado a `worlds.json.bak` y `WorldStore.last_load_error` con un mensaje legible.
- [x] 3.3 Mostrar `last_load_error` como toast al abrir la pantalla de mundos.
- [x] 3.4 Comprobar con un script local que crear y borrar deja el archivo válido y sin `.tmp`, y que un archivo corrupto se mueve a `.bak` sin sobrescribirlo con una lista vacía.

## 4. Verificación

- [x] 4.1 `check-gdscript.sh -p game --strict` sin errores ni avisos.
- [x] 4.2 `godot --headless --path game --quit` sin `ERROR` ni `SCRIPT ERROR`.
- [x] 4.3 `sim_smoke` sigue en verde (88 checks).
- [x] 4.4 Instanciar en headless las escenas `welcome`, `worlds` e `intro` sin errores.

## 5. Cierre

- [x] 5.1 Archivar el cambio con `openspec archive fix-intro-skip-and-worlds-save --yes` y validar `--all --strict`.
- [x] 5.2 Commit, push y PR a `features` con la verificación adjunta.
